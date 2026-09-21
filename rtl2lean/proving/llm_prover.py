"""Fail-closed LLM proving loop with Lean-kernel-verified lemma reuse.

The module is provider-agnostic: an external LLM can be connected through a
JSON command, while tests and offline runs can supply an in-process provider.
No candidate is reusable until Lean has compiled it successfully.
"""
from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import time
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable, Protocol, Sequence


@dataclass(frozen=True)
class ProofTarget:
    name: str
    statement: str


@dataclass(frozen=True)
class CandidateLemma:
    name: str
    statement: str
    proof: str
    origin: str = "llm"


class CandidateProvider(Protocol):
    def propose(self, context: dict[str, Any]) -> Sequence[CandidateLemma]: ...


@dataclass
class ProofAttempt:
    kind: str
    proof: str
    success: bool
    stdout: str = ""
    stderr: str = ""
    candidate: str | None = None


@dataclass
class ProofResult:
    target: ProofTarget
    success: bool
    proof: str | None
    attempts: list[ProofAttempt] = field(default_factory=list)
    verified_candidates: list[str] = field(default_factory=list)
    reused_lemma: str | None = None


class VerifiedLemmaPool:
    """Persistent pool containing only candidates accepted by Lean."""

    def __init__(self, path: Path):
        self.path = path
        self.lemmas: list[CandidateLemma] = []
        if path.exists():
            payload = json.loads(path.read_text(encoding="utf-8"))
            self.lemmas = [CandidateLemma(**item) for item in payload.get("lemmas", [])]

    def add_verified(self, lemma: CandidateLemma) -> None:
        self.lemmas = [item for item in self.lemmas if item.name != lemma.name]
        self.lemmas.append(lemma)
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.path.write_text(json.dumps({
            "schema": "rtl2lean-verified-lemma-pool-v1",
            "lemmas": [asdict(item) for item in self.lemmas],
        }, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    def matching(self, statement: str) -> list[CandidateLemma]:
        normalized = " ".join(statement.split())
        return [
            lemma for lemma in self.lemmas
            if " ".join(lemma.statement.split()) == normalized
        ]


class CommandLLMProvider:
    """Invoke an external LLM adapter using JSON on stdin/stdout.

    The command must return ``{"candidates": [{name, statement, proof}]}``.
    Process failure or malformed output is fail-closed and yields no candidate.
    """

    def __init__(self, command: Sequence[str], timeout: int = 120):
        if not command:
            raise ValueError("LLM provider command must not be empty")
        self.command = list(command)
        self.timeout = timeout

    def propose(self, context: dict[str, Any]) -> Sequence[CandidateLemma]:
        try:
            completed = subprocess.run(
                self.command,
                input=json.dumps(context, ensure_ascii=False),
                capture_output=True,
                text=True,
                check=False,
                timeout=self.timeout,
            )
            if completed.returncode != 0:
                return []
            payload = json.loads(completed.stdout)
            return [
                CandidateLemma(
                    name=item["name"],
                    statement=item["statement"],
                    proof=item["proof"],
                    origin="llm-command",
                )
                for item in payload.get("candidates", [])
            ]
        except (OSError, subprocess.TimeoutExpired, json.JSONDecodeError, KeyError, TypeError):
            return []


def _write_module(
    path: Path,
    context_import: str,
    open_namespaces: Sequence[str],
    declaration: str,
) -> None:
    lines = [f"import {context_import}", ""]
    lines.extend(f"open {namespace}" for namespace in open_namespaces)
    lines.extend(["", declaration, ""])
    path.write_text("\n".join(lines), encoding="utf-8")


def _kernel_check(
    path: Path, lean: str, lean_path: Path, timeout_s: int = 600,
) -> tuple[bool, str, str]:
    env = os.environ.copy()
    env["LEAN_PATH"] = str(lean_path) + (
        ":" + env["LEAN_PATH"] if env.get("LEAN_PATH") else ""
    )
    try:
        completed = subprocess.run(
            [lean, "-s", "65536", str(path)],
            cwd=path.parent,
            env=env,
            capture_output=True,
            text=True,
            check=False,
            timeout=timeout_s,
        )
        return completed.returncode == 0, completed.stdout, completed.stderr
    except subprocess.TimeoutExpired as error:
        stdout = error.stdout.decode() if isinstance(error.stdout, bytes) else (error.stdout or "")
        stderr = error.stderr.decode() if isinstance(error.stderr, bytes) else (error.stderr or "")
        return False, stdout, stderr + f"\nLean kernel check timed out after {timeout_s}s"


def _try_target(
    target: ProofTarget,
    proof: str,
    kind: str,
    context_import: str,
    open_namespaces: Sequence[str],
    output_dir: Path,
    lean: str,
    lean_path: Path,
    index: int,
    candidate: str | None = None,
    supporting_lemmas: Sequence[CandidateLemma] = (),
) -> ProofAttempt:
    path = output_dir / f"TargetAttempt{index}.lean"
    _write_module(
        path,
        context_import,
        open_namespaces,
        "\n\n".join([
            *(
                f"theorem {lemma.name} : {lemma.statement} := {lemma.proof}"
                for lemma in supporting_lemmas
            ),
            f"theorem {target.name} : {target.statement} := {proof}",
        ]),
    )
    success, stdout, stderr = _kernel_check(path, lean, lean_path)
    return ProofAttempt(kind, proof, success, stdout, stderr, candidate)


def prove_with_feedback(
    target: ProofTarget,
    context_import: str,
    open_namespaces: Sequence[str],
    lean_path: Path,
    output_dir: Path,
    lemma_pool: VerifiedLemmaPool,
    provider: CandidateProvider | None = None,
    existing_proofs: Sequence[str] = ("by rfl", "by simp"),
    max_rounds: int = 2,
    model_context: str = "",
    base_lemmas: Sequence[str] = (),
) -> ProofResult:
    """Try existing proofs, verified reuse, then provider candidates and repair."""
    lean = shutil.which("lean")
    output_dir = output_dir.resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    result = ProofResult(target, False, None)
    if not lean:
        result.attempts.append(ProofAttempt("backend", "", False, stderr="lean not found"))
        return result

    for proof in existing_proofs:
        attempt = _try_target(
            target, proof, "existing", context_import, open_namespaces,
            output_dir, lean, lean_path, len(result.attempts),
        )
        result.attempts.append(attempt)
        if attempt.success:
            result.success, result.proof = True, proof
            break

    if not result.success:
        for lemma in lemma_pool.matching(target.statement):
            proof = f"by exact {lemma.name}"
            attempt = _try_target(
                target, proof, "lemma-reuse", context_import, open_namespaces,
                output_dir, lean, lean_path, len(result.attempts), lemma.name,
                [lemma],
            )
            result.attempts.append(attempt)
            if attempt.success:
                result.success, result.proof = True, proof
                result.reused_lemma = lemma.name
                break

    feedback = "\n".join(
        attempt.stdout + attempt.stderr for attempt in result.attempts if not attempt.success
    )
    for round_index in range(max_rounds if provider and not result.success else 0):
        context = {
            "target": asdict(target),
            "context_import": context_import,
            "open_namespaces": list(open_namespaces),
            "lean_model": model_context,
            "base_lemmas": list(base_lemmas),
            "verified_lemma_pool": [asdict(item) for item in lemma_pool.lemmas],
            "lean_feedback": feedback,
            "round": round_index,
        }
        candidates = list(provider.propose(context))
        if not candidates:
            break
        for candidate_index, candidate in enumerate(candidates):
            candidate_path = output_dir / f"Candidate{round_index}_{candidate_index}.lean"
            _write_module(
                candidate_path,
                context_import,
                open_namespaces,
                f"theorem {candidate.name} : {candidate.statement} := {candidate.proof}",
            )
            verified, stdout, stderr = _kernel_check(
                candidate_path, lean, lean_path
            )
            result.attempts.append(ProofAttempt(
                "candidate-kernel-check", candidate.proof, verified,
                stdout, stderr, candidate.name,
            ))
            if not verified:
                feedback = stdout + stderr
                continue
            lemma_pool.add_verified(candidate)
            result.verified_candidates.append(candidate.name)
            proof = f"by exact {candidate.name}"
            attempt = _try_target(
                target, proof, "candidate-reuse", context_import, open_namespaces,
                output_dir, lean, lean_path, len(result.attempts), candidate.name,
                [candidate],
            )
            result.attempts.append(attempt)
            if attempt.success:
                result.success, result.proof = True, proof
                result.reused_lemma = candidate.name
                break
            feedback = attempt.stdout + attempt.stderr
        if result.success:
            break

    (output_dir / "proof_result.json").write_text(json.dumps({
        **asdict(result),
        "attempts": [asdict(attempt) for attempt in result.attempts],
    }, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return result


# ---------------------------------------------------------------------------
# Requirement-5 autonomous, budgeted prover
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class StructuredCandidate:
    action: str
    lemma_name: str
    lemma_statement: str
    proof_body: str
    rationale: str
    used_lemmas: list[str]
    previous_candidate: str = ""
    previous_lean_error: str = ""
    previous_strategy: str = ""
    new_strategy: str = ""


@dataclass(frozen=True)
class ProvingBudget:
    max_generation_rounds: int = 5
    max_repair_rounds_per_candidate: int = 3
    max_intermediate_lemmas: int = 8
    max_llm_calls: int = 20
    max_total_tokens: int | None = None


@dataclass(frozen=True)
class AutonomousProofTask:
    dut: str
    target_name: str
    target_statement: str
    property_type: str
    state_type: str
    required_state_fields: list[str]
    required_input_fields: list[str]
    assumptions: list[str]
    context_import: str
    context_snippets: list[str]
    relevant_foundational_lemmas: list[str]
    base_lean_error: str
    future_targets: list[dict[str, str]] = field(default_factory=list)


@dataclass
class VerifiedLemmaRecord:
    name: str
    proposition: str
    proof_body: str
    source_target: str
    generation_round: int
    kernel_result: str
    created_time: str
    origin: str
    property_category: str
    state_type: str
    involved_functions: list[str]
    used_lemmas: list[str]
    reuse_count: int = 0
    reused_by: list[str] = field(default_factory=list)
    dut: str = ""
    module: str = ""
    statement: str = ""
    proof: str = ""
    kernel_verified: bool = True
    dependencies: list[str] = field(default_factory=list)
    tags: list[str] = field(default_factory=list)


class StructuredRuntimeProvider(Protocol):
    last_call: dict[str, Any]

    def generate(self, context: dict[str, Any], artifact_dir: Path) -> StructuredCandidate | None: ...


def _json_dump(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def _normalized_proposition(value: str) -> str:
    return " ".join(value.split())


def _tokens(value: str) -> set[str]:
    return {
        token.lower() for token in re.findall(r"[A-Za-z_][A-Za-z0-9_']*", value)
        if len(token) >= 3
    }


class PersistentLocalLemmaPool:
    """DUT-local, kernel-gated pool with relevance retrieval and reuse audit."""

    SCHEMA = "rtl2lean-dut-local-verified-lemma-pool-v2"

    def __init__(self, path: Path, dut: str):
        self.path = path
        self.dut = dut
        self.lemmas: list[VerifiedLemmaRecord] = []
        if path.exists():
            payload = json.loads(path.read_text(encoding="utf-8"))
            if payload.get("schema") != self.SCHEMA or payload.get("dut") != dut:
                raise ValueError(f"invalid local lemma pool: {path}")
            self.lemmas = [VerifiedLemmaRecord(**item) for item in payload.get("lemmas", [])]
            if any(item.kernel_result != "PASS" for item in self.lemmas):
                raise ValueError("non-kernel-verified entry found in local lemma pool")

    def _save(self) -> None:
        _json_dump(self.path, {
            "schema": self.SCHEMA,
            "dut": self.dut,
            "lemmas": [asdict(item) for item in self.lemmas],
            "metrics": {
                "verified_lemmas": len(self.lemmas),
                "actual_reused_lemmas": sum(item.reuse_count > 0 for item in self.lemmas),
                "actual_reuse_hits": sum(item.reuse_count for item in self.lemmas),
            },
        })

    def add_verified(self, lemma: VerifiedLemmaRecord) -> None:
        if lemma.kernel_result != "PASS" or not lemma.kernel_verified:
            raise ValueError("only Lean-kernel-PASS lemmas may enter the verified pool")
        forbidden = ("sorry", "admit", "native_decide", "axiom ")
        if any(token in f"{lemma.proposition}\n{lemma.proof_body}" for token in forbidden):
            raise ValueError("unchecked/forbidden content cannot enter verified lemma pool")
        lemma.dut = lemma.dut or self.dut
        lemma.module = lemma.module or lemma.state_type.removesuffix("State")
        lemma.statement = lemma.statement or lemma.proposition
        lemma.proof = lemma.proof or lemma.proof_body
        lemma.dependencies = lemma.dependencies or list(lemma.used_lemmas)
        lemma.tags = lemma.tags or [lemma.property_category, lemma.origin]
        if lemma.dut != self.dut:
            raise ValueError("cross-DUT lemma insertion is forbidden in the local pool")
        existing = next((item for item in self.lemmas if item.name == lemma.name), None)
        if existing:
            if _normalized_proposition(existing.proposition) != _normalized_proposition(lemma.proposition):
                raise ValueError(f"lemma name collision with different proposition: {lemma.name}")
            return
        self.lemmas.append(lemma)
        self._save()

    def retrieve(self, task: AutonomousProofTask, limit: int = 8) -> list[dict[str, Any]]:
        target_tokens = _tokens(
            " ".join([
                task.target_name, task.target_statement, task.property_type,
                *task.required_state_fields, *task.required_input_fields,
            ])
        )
        ranked: list[tuple[int, int, VerifiedLemmaRecord]] = []
        for index, lemma in enumerate(self.lemmas):
            if lemma.source_target == task.target_name:
                continue
            lemma_tokens = _tokens(
                f"{lemma.name} {lemma.proposition} {lemma.property_category} "
                + " ".join(lemma.involved_functions)
            )
            overlap = sorted(target_tokens & lemma_tokens)
            score = len(overlap)
            if lemma.state_type == task.state_type:
                score += 20
            if lemma.property_category == task.property_type:
                score += 8
            if _normalized_proposition(lemma.proposition) == _normalized_proposition(task.target_statement):
                score += 100
            if score > 0:
                ranked.append((score, -index, lemma))
        ranked.sort(reverse=True, key=lambda item: (item[0], item[1]))
        return [
            {**asdict(lemma), "relevance_score": score,
             "overlap_tokens": sorted(target_tokens & _tokens(f"{lemma.name} {lemma.proposition}"))}
            for score, _, lemma in ranked[:limit]
        ]

    def mark_reused(self, lemma_name: str, target_name: str) -> None:
        lemma = next((item for item in self.lemmas if item.name == lemma_name), None)
        if not lemma:
            raise ValueError(f"cannot mark missing lemma as reused: {lemma_name}")
        if target_name not in lemma.reused_by:
            lemma.reused_by.append(target_name)
            lemma.reuse_count += 1
            self._save()


class CodexCLIProvider:
    """Real structured runtime provider backed by a non-interactive Codex CLI."""

    def __init__(
        self,
        schema_path: Path | None = None,
        model: str = "gpt-5.6-sol",
        reasoning_effort: str = "medium",
        timeout_s: int = 300,
        executable: str | None = None,
        workdir: Path | None = None,
    ):
        self.executable = executable or shutil.which("codex") or ""
        self.schema_path = schema_path or Path(__file__).with_name("structured_candidate.schema.json")
        self.model = model
        self.reasoning_effort = reasoning_effort
        self.timeout_s = timeout_s
        self.workdir = (workdir or Path.cwd()).resolve()
        self.call_count = 0
        self.last_call: dict[str, Any] = {}

    @property
    def available(self) -> bool:
        return bool(self.executable and self.schema_path.is_file())

    def _prompt(self, context: dict[str, Any]) -> str:
        mode = context["mode"]
        task = context["proof_task"]
        instructions = f"""You are the runtime Lean 4 proving component in an audited RTL2Lean experiment.
Return exactly one JSON object conforming to the supplied schema. Do not use tools and do not edit files.

Hard constraints:
- Never use sorry, admit, native_decide, axiom, unsafe, or alter the target proposition.
- proof_body must be a complete Lean term/tactic beginning with `by`.
- Use only definitions/theorems present in the supplied context or verified local pool.
- TARGET_PROOF must use the exact target name and exact target statement.
- INTERMEDIATE_LEMMA must be genuinely useful and strictly different from the complete target.
- In REPAIR mode keep the candidate proposition/name fixed and return action PROOF_REPAIR.
- In REPLAN mode return action PROOF_REPLAN and state a genuinely different strategy.
- Empty non-applicable string fields are allowed, but every schema field must be present.

Current mode: {mode}
Target name: {task['target_name']}
Target statement:
{task['target_statement']}
Property category: {task['property_type']}
Assumptions: {json.dumps(task['assumptions'], ensure_ascii=False)}

Actual current Lean goal/error:
{context.get('lean_feedback', '')[-12000:]}

Relevant Lean context snippets:
{chr(10).join(task['context_snippets'])}

Relevant foundational lemma names/statements:
{chr(10).join(task['relevant_foundational_lemmas'])}

Lean induction-pattern note: inspect the supplied inductive constructor order.
For a constructor like `next {{s}} : Reachable s → (i : Inputs) → Reachable ...`,
an explicit robust branch pattern is `| @next s hs i ih =>`; the induction
hypothesis comes after the constructor's non-recursive input argument. Do not
guess a pattern that binds the input record as the induction hypothesis.
For event-driven models, bind every non-recursive argument before the induction
hypothesis, for example `| @next s hs i event ih =>`.

Large-model performance note: `step` may contain thousands of state updates.
For an append-to-`run` lemma, avoid list induction whose `rfl` can unfold that
entire transition.  Expose `run` as `List.foldl`, rewrite with
`List.foldl_append`, and close only the resulting one-element fold by `rfl`.

Kernel-verified DUT-local lemmas available for reuse:
{json.dumps(context.get('retrieved_lemmas', []), ensure_ascii=False, indent=2)}

Previous attempt history:
{json.dumps(context.get('attempt_history', []), ensure_ascii=False, indent=2)[-16000:]}

Potential later targets for the same DUT (prefer a reusable intermediate lemma when naturally helpful):
{json.dumps(task.get('future_targets', []), ensure_ascii=False, indent=2)}
"""
        if mode == "GENERATE":
            instructions += """

This is the intermediate-lemma-first round. You MUST return action
INTERMEDIATE_LEMMA. Its proposition must differ from the target and expose a
genuinely useful induction/rewrite step for the target. It will be compiled
independently before any target proof is requested.
"""
        elif mode == "TARGET_AFTER_LEMMA":
            instructions += """

At least one intermediate lemma from an earlier round is now kernel verified.
Return TARGET_PROOF for the exact target and use the verified intermediate
lemma where it is useful.
"""
        elif mode == "TARGET_WITH_REUSE":
            instructions += """

This is the shared-pool reuse arm. Return TARGET_PROOF for the exact target and
use an already kernel-verified lemma from the listed DUT-local pool when it is
helpful. Do not generate a new intermediate lemma in this call.
"""
        elif mode == "DIRECT_TARGET":
            instructions += """

This is the no-new-intermediate ablation arm. Return TARGET_PROOF for the exact
target.  You may use only the imported foundational lemmas and the explicitly
listed initial pool; do not propose or assume a new intermediate lemma.
"""
        if mode == "REPAIR":
            previous = context["previous_candidate"]
            instructions += f"""

Repair this exact rejected candidate without changing its name or proposition:
{json.dumps(previous, ensure_ascii=False, indent=2)}
The previous Lean error fields in your JSON must identify this candidate/error.
"""
        elif mode == "REPLAN":
            instructions += "\nThe prior strategy exhausted its repair budget. Choose a different proof strategy.\n"
        elif mode not in {"GENERATE", "TARGET_AFTER_LEMMA", "TARGET_WITH_REUSE"}:
            instructions += "\nChoose either a direct TARGET_PROOF or a useful INTERMEDIATE_LEMMA.\n"
        return instructions

    def generate(self, context: dict[str, Any], artifact_dir: Path) -> StructuredCandidate | None:
        self.call_count += 1
        artifact_dir.mkdir(parents=True, exist_ok=True)
        call_id = f"call_{self.call_count:03d}"
        prompt_path = artifact_dir / f"{call_id}_prompt.txt"
        response_path = artifact_dir / f"{call_id}_response.json"
        prompt = self._prompt(context)
        prompt_path.write_text(prompt, encoding="utf-8")
        command = [
            self.executable, "exec", "--skip-git-repo-check", "--ephemeral",
            "--sandbox", "workspace-write", "-m", self.model,
            "-c", f'model_reasoning_effort="{self.reasoning_effort}"',
            "--output-schema", str(self.schema_path),
            "--output-last-message", str(response_path), "-",
        ]
        started = time.perf_counter()
        try:
            child_env = os.environ.copy()
            # A nested non-interactive provider must not inherit the parent
            # Codex app-server/session identity; those handles are owned by the
            # current orchestration process and are read-only to the child.
            for key in (
                "CODEX_SESSION_ID", "CODEX_THREAD_ID", "CODEX_PERMISSION_PROFILE", "CODEX_CI",
                "CODEX_SANDBOX_NETWORK_DISABLED", "CODEX_MANAGED_BY_NPM",
                "CODEX_MANAGED_PACKAGE_ROOT", "OPENAI_BASE_URL", "OPENAI_API_KEY",
            ):
                child_env.pop(key, None)
            completed = subprocess.run(
                command, input=prompt, cwd=self.workdir, capture_output=True,
                text=True, check=False, timeout=self.timeout_s, env=child_env,
            )
            elapsed = time.perf_counter() - started
            raw_response = response_path.read_text(encoding="utf-8") if response_path.is_file() else ""
            payload = json.loads(raw_response) if completed.returncode == 0 and raw_response else None
            candidate = StructuredCandidate(**payload) if isinstance(payload, dict) else None
            token_match = re.search(r"tokens used\s*\n\s*([0-9,]+)", completed.stdout + completed.stderr)
            self.last_call = {
                "provider": "codex-cli",
                "model": self.model,
                "reasoning_effort": self.reasoning_effort,
                "command": command,
                "returncode": completed.returncode,
                "success": candidate is not None,
                "elapsed_s": elapsed,
                "tokens": int(token_match.group(1).replace(",", "")) if token_match else None,
                "prompt": str(prompt_path),
                "response": str(response_path),
                "stdout": completed.stdout,
                "stderr": completed.stderr,
                "error": None if candidate else "provider returned no valid structured candidate",
            }
            _json_dump(artifact_dir / f"{call_id}_metadata.json", self.last_call)
            return candidate
        except (OSError, subprocess.TimeoutExpired, json.JSONDecodeError, TypeError) as error:
            self.last_call = {
                "provider": "codex-cli", "model": self.model,
                "reasoning_effort": self.reasoning_effort,
                "command": command, "returncode": 124 if isinstance(error, subprocess.TimeoutExpired) else None,
                "success": False, "elapsed_s": time.perf_counter() - started,
                "tokens": None, "prompt": str(prompt_path), "response": str(response_path),
                "stdout": "", "stderr": "", "error": repr(error),
            }
            _json_dump(artifact_dir / f"{call_id}_metadata.json", self.last_call)
            return None


def _candidate_is_target(candidate: StructuredCandidate, task: AutonomousProofTask) -> bool:
    return _normalized_proposition(candidate.lemma_statement) == _normalized_proposition(task.target_statement)


def _validate_structured_candidate(
    candidate: StructuredCandidate,
    task: AutonomousProofTask,
    mode: str,
    previous: StructuredCandidate | None,
) -> None:
    allowed = {"INTERMEDIATE_LEMMA", "TARGET_PROOF", "PROOF_REPAIR", "PROOF_REPLAN"}
    if candidate.action not in allowed:
        raise ValueError(f"unknown candidate action: {candidate.action}")
    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_']*", candidate.lemma_name):
        raise ValueError("candidate lemma name is not a safe Lean identifier")
    if not candidate.proof_body.lstrip().startswith("by"):
        raise ValueError("candidate proof_body must start with `by`")
    text = f"{candidate.lemma_statement}\n{candidate.proof_body}".lower()
    if any(token in text for token in ("sorry", "admit", "native_decide", "axiom ", "unsafe")):
        raise ValueError("candidate contains forbidden unchecked construct")
    is_target = _candidate_is_target(candidate, task)
    if candidate.action == "TARGET_PROOF":
        if not is_target or candidate.lemma_name != task.target_name:
            raise ValueError("TARGET_PROOF changed the target name or statement")
    if candidate.action == "INTERMEDIATE_LEMMA" and is_target:
        raise ValueError("INTERMEDIATE_LEMMA may not duplicate the complete target")
    if mode == "GENERATE" and candidate.action != "INTERMEDIATE_LEMMA":
        raise ValueError("first proving round must produce an intermediate lemma")
    if mode == "TARGET_AFTER_LEMMA" and candidate.action != "TARGET_PROOF":
        raise ValueError("post-intermediate round must produce the exact target proof")
    if mode == "TARGET_WITH_REUSE" and candidate.action != "TARGET_PROOF":
        raise ValueError("shared-pool reuse round must produce the exact target proof")
    if mode == "DIRECT_TARGET" and candidate.action != "TARGET_PROOF":
        raise ValueError("direct ablation round must produce the exact target proof")
    if mode == "REPAIR":
        if candidate.action != "PROOF_REPAIR" or not previous:
            raise ValueError("repair call must return PROOF_REPAIR")
        if (
            candidate.lemma_name != previous.lemma_name
            or _normalized_proposition(candidate.lemma_statement)
            != _normalized_proposition(previous.lemma_statement)
        ):
            raise ValueError("repair changed candidate name or proposition")
    if mode == "REPLAN" and candidate.action != "PROOF_REPLAN":
        raise ValueError("replan call must return PROOF_REPLAN")


def _pool_declarations(pool: PersistentLocalLemmaPool) -> str:
    return "\n\n".join(
        f"theorem {lemma.name} : {lemma.proposition} := {lemma.proof_body}"
        for lemma in pool.lemmas
    )


def _autonomous_kernel_check(
    candidate: StructuredCandidate,
    task: AutonomousProofTask,
    pool: PersistentLocalLemmaPool,
    lean_path: Path,
    output_path: Path,
    lean: str,
    omitted_pool_lemma: str | None = None,
) -> dict[str, Any]:
    declarations = "\n\n".join(
        f"theorem {lemma.name} : {lemma.proposition} := {lemma.proof_body}"
        for lemma in pool.lemmas if lemma.name != omitted_pool_lemma
    )
    theorem = f"theorem {candidate.lemma_name} : {candidate.lemma_statement} := {candidate.proof_body}"
    output_path.parent.mkdir(parents=True, exist_ok=True)
    module = task.state_type.removesuffix("State")
    body = "\n\n".join(filter(None, [
        "set_option maxHeartbeats 4000000\nset_option maxRecDepth 100000",
        f"namespace {module}Verification\nopen {module}",
        declarations,
        theorem,
        f"end {module}Verification",
    ]))
    _write_module(output_path, task.context_import, [], body)
    started = time.perf_counter()
    success, stdout, stderr = _kernel_check(output_path, lean, lean_path)
    return {
        "success": success,
        "stdout": stdout,
        "stderr": stderr,
        "elapsed_s": time.perf_counter() - started,
        "source": str(output_path),
        "omitted_pool_lemma": omitted_pool_lemma,
    }


def run_budgeted_proof_search(
    task: AutonomousProofTask,
    provider: StructuredRuntimeProvider,
    pool: PersistentLocalLemmaPool,
    lean_path: Path,
    output_dir: Path,
    budget: ProvingBudget = ProvingBudget(),
    allow_pool_first: bool = False,
    candidate_policy: Callable[[StructuredCandidate], None] | None = None,
) -> dict[str, Any]:
    """Run generate/check/repair/replan until target PASS or budget exhaustion."""
    from rtl2lean.pipeline.compiler import find_lean
    lean = find_lean()
    output_dir = output_dir.resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    _json_dump(output_dir / "proof_task.json", asdict(task))
    history: list[dict[str, Any]] = []
    accepted_intermediate: list[str] = []
    rejected_candidates: list[str] = []
    actual_reuse: list[dict[str, Any]] = []
    intermediate_usage: list[dict[str, Any]] = []
    llm_calls = 0
    repair_rounds = 0
    lean_time = 0.0
    llm_time = 0.0
    llm_tokens = 0
    solved_candidate: StructuredCandidate | None = None
    last_error = task.base_lean_error
    generation_rounds_used = 0
    reuse_first_attempted = False

    def call_provider(mode: str, generation: int, repair: int,
                      previous: StructuredCandidate | None) -> StructuredCandidate | None:
        nonlocal llm_calls, llm_time, llm_tokens
        if llm_calls >= budget.max_llm_calls:
            return None
        if budget.max_total_tokens is not None and llm_tokens >= budget.max_total_tokens:
            return None
        retrieved = pool.retrieve(task)
        context = {
            "mode": mode,
            "generation_round": generation,
            "repair_round": repair,
            "proof_task": asdict(task),
            "lean_feedback": last_error,
            "retrieved_lemmas": retrieved,
            "attempt_history": history,
            "previous_candidate": asdict(previous) if previous else None,
        }
        call_dir = output_dir / "llm_calls" / f"generation_{generation:02d}_repair_{repair:02d}"
        candidate = provider.generate(context, call_dir)
        llm_calls += 1
        llm_time += float(provider.last_call.get("elapsed_s", 0.0))
        if isinstance(provider.last_call.get("tokens"), int):
            llm_tokens += provider.last_call["tokens"]
        history.append({
            "event": "LLM_RESPONSE" if candidate else "LLM_PROVIDER_FAILURE",
            "mode": mode,
            "generation_round": generation,
            "repair_round": repair,
            "provider_call": provider.last_call,
            "candidate": asdict(candidate) if candidate else None,
        })
        return candidate

    for generation in range(1, budget.max_generation_rounds + 1):
        if solved_candidate or llm_calls >= budget.max_llm_calls:
            break
        generation_rounds_used = generation
        reusable_prior = any(
            lemma.origin == "llm" and lemma.source_target != task.target_name
            for lemma in pool.lemmas
        )
        if accepted_intermediate:
            mode = "TARGET_AFTER_LEMMA"
        elif allow_pool_first and reusable_prior and not reuse_first_attempted:
            mode = "TARGET_WITH_REUSE"
            reuse_first_attempted = True
        else:
            mode = "GENERATE"
        candidate = call_provider(mode, generation, 0, None)
        if not candidate:
            break
        try:
            _validate_structured_candidate(candidate, task, mode, None)
            if candidate_policy is not None:
                candidate_policy(candidate)
        except ValueError as error:
            last_error = f"Structured candidate validation failed: {error}"
            rejected_candidates.append(candidate.lemma_name)
            history.append({
                "event": "CANDIDATE_REJECTED", "reason": "STRUCTURE",
                "generation_round": generation, "repair_round": 0,
                "candidate": asdict(candidate), "lean_error": last_error,
            })
        else:
            check = _autonomous_kernel_check(
                candidate, task, pool, lean_path,
                output_dir / "lean_checks" / f"generation_{generation:02d}_candidate.lean", lean,
            )
            lean_time += check["elapsed_s"]
            history.append({
                "event": "CANDIDATE_ACCEPTED" if check["success"] else "CANDIDATE_REJECTED",
                "generation_round": generation, "repair_round": 0,
                "candidate": asdict(candidate), "kernel_check": check,
            })
            if check["success"]:
                if _candidate_is_target(candidate, task):
                    solved_candidate = candidate
                else:
                    record = VerifiedLemmaRecord(
                        candidate.lemma_name, candidate.lemma_statement, candidate.proof_body,
                        task.target_name, generation, "PASS", datetime.now(timezone.utc).isoformat(),
                        "llm", task.property_type, task.state_type,
                        sorted(_tokens(candidate.lemma_statement) & {"step", "run", "reachable", "proc_alwaysff", "proc_alwayscomb"}),
                        candidate.used_lemmas,
                    )
                    try:
                        pool.add_verified(record)
                    except ValueError as error:
                        last_error = f"Verified pool rejected candidate: {error}"
                        rejected_candidates.append(candidate.lemma_name)
                        history.append({
                            "event": "CANDIDATE_REJECTED", "reason": "POOL_COLLISION",
                            "generation_round": generation, "repair_round": 0,
                            "candidate": asdict(candidate), "lean_error": last_error,
                        })
                        continue
                    accepted_intermediate.append(candidate.lemma_name)
                    if len(accepted_intermediate) >= budget.max_intermediate_lemmas:
                        last_error = "maximum intermediate lemma budget reached"
                if solved_candidate:
                    break
                continue
            last_error = check["stdout"] + check["stderr"]
            rejected_candidates.append(candidate.lemma_name)

        current = candidate
        accepted_repair = False
        repairs_this_strategy = 0
        for repair in range(1, budget.max_repair_rounds_per_candidate + 1):
            if llm_calls >= budget.max_llm_calls:
                break
            repair_rounds += 1
            repairs_this_strategy += 1
            repaired = call_provider("REPAIR", generation, repair, current)
            if not repaired:
                break
            try:
                _validate_structured_candidate(repaired, task, "REPAIR", current)
                if candidate_policy is not None:
                    candidate_policy(repaired)
            except ValueError as error:
                last_error = f"Structured repair validation failed: {error}"
                rejected_candidates.append(repaired.lemma_name)
                history.append({
                    "event": "CANDIDATE_REJECTED", "reason": "STRUCTURE",
                    "generation_round": generation, "repair_round": repair,
                    "candidate": asdict(repaired), "lean_error": last_error,
                })
                current = repaired
                continue
            check = _autonomous_kernel_check(
                repaired, task, pool, lean_path,
                output_dir / "lean_checks" / f"generation_{generation:02d}_repair_{repair:02d}.lean", lean,
            )
            lean_time += check["elapsed_s"]
            history.append({
                "event": "CANDIDATE_ACCEPTED" if check["success"] else "CANDIDATE_REJECTED",
                "generation_round": generation, "repair_round": repair,
                "candidate": asdict(repaired), "kernel_check": check,
            })
            current = repaired
            if not check["success"]:
                last_error = check["stdout"] + check["stderr"]
                rejected_candidates.append(repaired.lemma_name)
                continue
            if _candidate_is_target(repaired, task):
                solved_candidate = repaired
            else:
                record = VerifiedLemmaRecord(
                    repaired.lemma_name, repaired.lemma_statement, repaired.proof_body,
                    task.target_name, generation, "PASS", datetime.now(timezone.utc).isoformat(),
                    "llm", task.property_type, task.state_type,
                    sorted(_tokens(repaired.lemma_statement) & {"step", "run", "reachable", "proc_alwaysff", "proc_alwayscomb"}),
                    repaired.used_lemmas,
                )
                try:
                    pool.add_verified(record)
                except ValueError as error:
                    last_error = f"Verified pool rejected repaired candidate: {error}"
                    rejected_candidates.append(repaired.lemma_name)
                    history.append({
                        "event": "CANDIDATE_REJECTED", "reason": "POOL_COLLISION",
                        "generation_round": generation, "repair_round": repair,
                        "candidate": asdict(repaired), "lean_error": last_error,
                    })
                    continue
                accepted_intermediate.append(repaired.lemma_name)
            accepted_repair = True
            break
        if solved_candidate:
            break
        if accepted_repair:
            continue
        history.append({
            "event": "CURRENT_STRATEGY_FAILED",
            "generation_round": generation,
            "repair_budget_used": repairs_this_strategy,
            "last_lean_error": last_error,
        })

    if solved_candidate:
        # A syntactic reference plus Lean PASS proves use; ablation additionally
        # distinguishes a causally necessary pool dependency from a redundant mention.
        for lemma in pool.lemmas:
            if not re.search(rf"\b{re.escape(lemma.name)}\b", solved_candidate.proof_body):
                continue
            ablation = _autonomous_kernel_check(
                solved_candidate, task, pool, lean_path,
                output_dir / "reuse_ablation" / f"without_{lemma.name}.lean", lean,
                omitted_pool_lemma=lemma.name,
            )
            lean_time += ablation["elapsed_s"]
            necessary = not ablation["success"]
            use_record = {
                "lemma": lemma.name,
                "source_target": lemma.source_target,
                "reused_by": task.target_name,
                "syntactically_referenced": True,
                "kernel_ablation_without_lemma_pass": ablation["success"],
                "causally_necessary": necessary,
                "ablation_check": ablation,
            }
            if lemma.source_target == task.target_name and lemma.name in accepted_intermediate:
                intermediate_usage.append(use_record)
            elif lemma.source_target != task.target_name:
                actual_reuse.append(use_record)
            if necessary and lemma.source_target != task.target_name:
                pool.mark_reused(lemma.name, task.target_name)
        pool.add_verified(VerifiedLemmaRecord(
            task.target_name, task.target_statement, solved_candidate.proof_body,
            task.target_name, generation_rounds_used, "PASS",
            datetime.now(timezone.utc).isoformat(), "llm-target", task.property_type,
            task.state_type,
            sorted(_tokens(task.target_statement) & {"step", "run", "reachable", "proc_alwaysff", "proc_alwayscomb"}),
            solved_candidate.used_lemmas,
        ))

    result = {
        "schema": "rtl2lean-budgeted-autonomous-proof-result-v1",
        "dut": task.dut,
        "target": task.target_name,
        "status": "LLM_SOLVED" if solved_candidate else "LLM_UNSOLVED",
        "target_kernel_pass": solved_candidate is not None,
        "final_proof": solved_candidate.proof_body if solved_candidate else None,
        "final_candidate": asdict(solved_candidate) if solved_candidate else None,
        "budget": asdict(budget),
        "generation_rounds_used": generation_rounds_used,
        "repair_rounds_used": repair_rounds,
        "total_llm_calls": llm_calls,
        "total_llm_tokens": llm_tokens,
        "token_budget_exhausted": (
            budget.max_total_tokens is not None and llm_tokens >= budget.max_total_tokens
        ),
        "accepted_intermediate_lemmas": accepted_intermediate,
        "rejected_candidates": rejected_candidates,
        "attempted_proof_strategies": [
            item["candidate"]["rationale"] for item in history
            if item.get("candidate") and item["event"] in {"CANDIDATE_ACCEPTED", "CANDIDATE_REJECTED"}
        ],
        "last_lean_goal": last_error,
        "last_lean_error": last_error,
        "remaining_unsolved_goals": None if solved_candidate else last_error,
        "actual_reuse": actual_reuse,
        "actual_reuse_hits": sum(item["causally_necessary"] for item in actual_reuse),
        "intermediate_lemma_usage": intermediate_usage,
        "causally_used_intermediate_lemmas": sum(
            item["causally_necessary"] for item in intermediate_usage
        ),
        "lean_time_s": lean_time,
        "llm_time_s": llm_time,
        "attempt_history": history,
    }
    _json_dump(output_dir / "proof_result.json", result)
    return result
