# LEAP

RTL-to-Lean translation and **Hypergraph-Guided Lemma Discovery (HGLD)**,
with Lean-checked intermediate lemmas and same-design reuse.
This repository contains the framework source and the fixed **177-theorem,
seven-design** research corpus. The Python translator package retains the name
`rtl2lean`; experimental modules have descriptive names rather than numbered
requirement names.

Release checks: **177/177 reference proofs**, **91 Python tests passed**;
33 archived-output tests are explicitly skipped. See
[validation details](docs/VALIDATION.md).

## Install

Use Python 3.10+ and Lean **4.26.0** on Linux. Install Lean with
[elan](https://github.com/leanprover/elan); `lean-toolchain` pins the version.

```bash
git clone git@github.com:ErosSph/leap.git
cd leap
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pip install -e .
lean --version
```

Alternatively, set `RTL2LEAN_LEAN` to your Lean 4.26.0 executable.
`requirement.txt` is an alias for `requirements.txt`.
Use an editable installation from this checkout: the RTL and Lean artifacts
are repository data, not files distributed inside a Python wheel.

## Quick start (no API key required)

```bash
# Verify the corpus size, statement hashes, and source hashes.
leap-check --manifest-only

# Rebuild one design and check its 30 reference proofs.
leap-check --dut aes

# Rebuild all seven models and check all 177 reference proofs.
leap-check --fresh --workers 2

# Translate new RTL; this also checks the generated model with Lean.
leap-translate --rtl tests/fixtures/two_clock.v --top two_clock \
  --translate-only --no-llm --output results/translation

# Python regression tests.
python -m pytest
```

`leap-check` builds the released models from Lean **source**, not shipped
`.olean` caches. Generated files and the check report go to `.build/`.
Large models can take several minutes to compile; `--timeout` controls the
per-process limit. The seven-design reference check is separate from rerunning
LLM proof discovery.

## Run LLM-assisted proof discovery

The API adapter accepts an OpenAI-compatible HTTPS chat-completions endpoint.
Credentials come **only from environment variables**. No key is included,
and no private instruction file is read. Choose a model actually available
on your account; `.env.example` documents the variables but is not auto-loaded.

```bash
export LLM_BASE_URL="https://dashscope.aliyuncs.com/compatible-mode/v1"
export LLM_MODEL="YOUR_MODEL_ID"
read -rsp 'API key: ' LLM_API_KEY
export LLM_API_KEY

# Small paid-API smoke run; remove --dut and --limit for the entire corpus.
leap-benchmark --arm full --dut aes --limit 2 --output results/smoke

# Optional direct-target comparison, with an independent same-design pool.
leap-benchmark --arm both --workers 2 --output results/comparison
```

Use `--disable-thinking` only if your provider supports `enable_thinking=false`.
The default budget is at most five attempts per requested proof. The `full`
protocol generates a design-local aggregate lemma from the dependency graph,
checks it in Lean, and instantiates fixed composition templates for the target
properties. Later properties can reuse that verified lemma. Therefore **177
targets do not imply 177 API calls**. `direct` generates target proofs without
the graph/templates and maintains its own chronological pool.

The frozen protocol does not read `theorems/reference/` when constructing LLM
prompts. It does use the explicit target-composition templates in `tasks.json`
in the full arm; these are part of the protocol, not discovered by the model.
Failed attempts receive deterministic Lean diagnostics. Reports record proof
outcomes, API calls, tokens, API/Lean time, and actual elaborated dependencies
on earlier same-design declarations. Results are local and ignored by Git.
An API failure is reported separately from an unproved theorem. No benchmark
request is made unless this command is explicitly invoked with credentials.

## Released theorem corpus

| Design | Theorems |
| --- | ---: |
| AES | 30 |
| PicoRV32 | 27 |
| Modexp | 24 |
| SERV | 21 |
| EthMAC | 29 |
| ZipCPU | 26 |
| DMA-AXI | 20 |
| **Total** | **177** |

`theorems/tasks.json` contains each statement, category, dependencies and
statement hash. `theorems/models/` contains its frozen Lean import context;
`theorems/reference/` contains one checkable reference proof per target.
Original theorem IDs and Lean declaration names are intentionally retained
for traceability. `config/benchmarks.json` pins the upstream RTL repositories,
commits, source lists and selected top modules. Source hashes are recorded in
`theorems/source_hashes.json`.

These are **model-level proof tasks**, not 177 independent end-to-end hardware
correctness claims. Many share intermediate facts. Some trace properties use
the local transition functions stated in their definitions, not the complete
DUT step function. Lean acceptance checks a proof against that model; it does
not independently establish RTL/model equivalence, IEEE-wide RTL support, or
functional correctness of the complete CPU, AES, DMA or Ethernet design.
The translator targets a supported, two-state RTL subset. New translations
and the frozen corpus are separate artifacts; this release does not silently
regenerate or strengthen the published theorem statements.

## Code layout

```text
rtl2lean/
  frontend/                 RTL parsing and elaboration
  middle_end/               IR, type checking and normalization
  backend/                  Lean model emission
  pipeline/                 Translation and model checking
  proving/                  Proof construction and verified lemma pools
experiments/
  hypergraph_guidance/      Dependency hypergraph, frontier and utility checks
  bridge_discovery/         Candidate bridges and proof repair
  adaptive_proving/         API adapter, Lean diagnostics and strategies
  design_suite/             Seven-design corpus construction
  challenge_suite/          Challenge tasks and graph ablation
  benchmark.py              Portable frozen-corpus LLM runner
  corpus_check.py           Offline model/reference proof checker
benchmarks/                 Pinned RTL source subsets (upstream licenses)
theorems/                   177 tasks, models and reference proofs
tests/                      Unit tests and RTL fixtures
configs/                    Development experiment configurations
```

Other descriptively named modules retain supporting evaluation and audit
logic. Development harnesses in `configs/` can require intermediate artifacts
from preceding stages; they are not substitutes for the self-contained release
commands above. No historical run directories, provider credentials, private
notes, compiler binaries, or third-party tool installations are included.
Tests that inspect those historical outputs are explicitly marked
`legacy_artifacts` and skipped by default; `pytest --run-legacy` requires you
to supply the corresponding snapshots. Release tests, translation tests and
the offline 177-proof check do not require those private run directories.

## Security and licenses

Do not commit credentials or API responses. Generated Lean is executable
metaprogramming input: proof filters and kernel checks are **not an OS sandbox**.
Run untrusted generated code in an isolated account/container without private
files or credentials. API calls send the selected public model context and
proof diagnostics to your configured provider and may incur charges.

Framework code is MIT-licensed; third-party RTL and derived benchmark model
artifacts retain their upstream terms. See [LICENSE](LICENSE) and
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
