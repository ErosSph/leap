# Artifact and protocol boundaries

The release separates three things that should not be conflated:

1. **Translation:** `leap-translate` reads RTL, elaborates a supported subset,
   emits Lean, and checks the model. Its source is under `rtl2lean/`.
2. **Frozen proof corpus:** `theorems/tasks.json`, `models/`, and `reference/`
   preserve the selected 177 statements and their checkable source context.
   `leap-check` validates hashes, compiles five context modules per design,
   and independently checks each reference theorem. Reference proof replay
   does not evaluate LLM success rates.
3. **Proof discovery:** `leap-benchmark` runs the frozen graph-guided aggregate
   lemma protocol or the direct-target comparison. It does not use the
   released reference proof bodies in prompts. Its full arm does use fixed
   composition templates from the manifest. It measures provider-dependent
   outcomes rather than promising the archived experiment's success rates.

## HGLD implementation

`experiments/hypergraph_guidance/hypergraph.py` implements premise-set
reachability, backward endpoint dependencies, and candidate missing edges.
`utility.py` and `experiments/bridge_discovery/` separate target usefulness
from Lean validity; `schemas.py` supplies proof skeletons and bindings.
The newer `boundary_evaluation/`, `scale_evaluation/`, and `design_suite/`
modules retain the corresponding extended patterns and corpus generators.

`experiments/challenge_suite/ablation.py` supplies the explicit dependency
graph for the fixed challenge corpus. `experiments/benchmark.py` preserves
the frozen runner's shared-core/full versus direct protocol. These are
different experimental configurations of the code, not a claim that every
target exercises every repair pattern.

Graph reachability is **not** itself a proof. A hypothetical edge can advance
the graph without being valid. Only a successful Lean check allows a
generated lemma into the reusable pool. The release runner inspects the
elaborated target proof's referenced constants to distinguish actual reuse
from merely retrieving or mentioning a lemma.

## Naming and reproducibility

Python modules are named by function. Historical Lean declaration names
(`R16Support`, `R17Support`, `r17_hard_*`, etc.) remain stable so statements,
reference proofs, and content hashes can be compared to the original corpus.
Those names are identifiers, not independently supported proof layers.

The source release deliberately excludes API request histories, manuscript
files, private notes, `.olean` files, installed toolchains and old output
trees. Some archived-run integration tests therefore have an explicit
`legacy_artifacts` marker. Their skip is not reported as a successful test.
Public release entry points are tested separately. RTL source copyrights
and public upstream author contacts are retained as license notices.
