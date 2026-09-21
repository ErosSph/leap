# Source release validation

Validation of framework source commit `8d624f4` (before adding this record):

- Fresh Python virtual environment: installation using `requirement.txt` and
  `pip install -e .` succeeded.
- Environment: Python 3.13.12, pyslang 11.0.0, pytest 9.1.1, Lean 4.26.0.
- Python tests: **91 passed, 33 explicitly skipped**. The skipped tests require
  archived experiment output snapshots that are not part of this release.
- Corpus: 177 distinct statement IDs and statement hashes verified; all
  included RTL/model/reference-source hashes matched the release inventory.
  The two support-module hashes also matched the original corpus manifest.
- Fresh Lean rebuild: all five context modules for each of seven designs
  compiled from source; no original `.olean` files were copied.
- Reference proofs: **177/177 accepted by Lean** with no `sorryAx` acceptance.
- Translation smoke test: the included dual-clock/asynchronous-reset RTL
  fixture translated and its generated Lean model compiled successfully.
- A deterministic fake model exercised the real Lean gate and subsequent
  same-design reuse path: two AES targets passed with one fake generation
  call, and the second target's elaborated proof referenced the pooled lemma.
- A separate clean Git clone and virtual environment repeated installation,
  the 91-pass test suite, and a fresh **30/30 AES reference-proof** check.
- The Git-visible release scan found no provider-key/private-key patterns,
  private workspace paths, or numbered `requirementXX.py` filenames. A separate
  comparison against credentials from the private source notes found no match.

| Design | Accepted reference proofs |
| --- | ---: |
| AES | 30/30 |
| PicoRV32 | 27/27 |
| Modexp | 24/24 |
| SERV | 21/21 |
| EthMAC | 29/29 |
| ZipCPU | 26/26 |
| DMA-AXI | 20/20 |
| **Total** | **177/177** |

Main validation commands:

```bash
leap-check --fresh --workers 3
python -m pytest
python tools/audit_release.py
leap-translate --rtl tests/fixtures/two_clock.v --top two_clock \
  --translate-only --no-llm --output results/translation
```

No paid LLM API was called during release validation. These checks validate
packaging, reference proofs, and software paths; they are **not** a new model
ablation or a claim of newly measured LLM success rates. The original
experiment directory and its results were not modified.
