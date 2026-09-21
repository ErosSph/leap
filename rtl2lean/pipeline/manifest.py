"""Benchmark metadata is the only DUT-specific layer in the framework."""
from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_MANIFEST = PROJECT_ROOT / "config" / "benchmarks.json"


@dataclass(frozen=True)
class Benchmark:
    design_id: str
    top_module: str
    repository: str
    commit: str
    source_files: tuple[Path, ...]
    categories: tuple[str, ...]
    unified_compilation_unit: bool = False

    @property
    def slug(self) -> str:
        aliases = {
            "secworks_aes_core": "aes",
            "secworks_modexp_core": "modexp",
            "olofk_serv_rf_top": "serv",
            "yosys_picorv32": "picorv32",
            "freecores_ethmac": "ethmac",
            "zipcpu_core": "zipcpu",
            "freecores_dma_axi32": "dma_axi",
        }
        return aliases.get(self.design_id, self.design_id)


def load_benchmarks(path: Path = DEFAULT_MANIFEST) -> list[Benchmark]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    source_root = PROJECT_ROOT / "benchmarks"
    result = []
    for item in payload["designs"]:
        sources = tuple((source_root / rel).resolve() for rel in item["rtl_files"])
        missing = [str(source) for source in sources if not source.is_file()]
        if missing:
            raise FileNotFoundError("benchmark sources missing: " + ", ".join(missing))
        result.append(Benchmark(
            design_id=item["design_id"],
            top_module=item["top_module"],
            repository=item["repository"],
            commit=item["commit"],
            source_files=sources,
            categories=tuple(item.get("categories", ())),
            unified_compilation_unit=bool(item.get("unified_compilation_unit", False)),
        ))
    return result


def select_benchmarks(name: str, path: Path = DEFAULT_MANIFEST) -> list[Benchmark]:
    benchmarks = load_benchmarks(path)
    if name == "all":
        return benchmarks
    selected = [item for item in benchmarks if name in {item.slug, item.design_id, item.top_module}]
    if not selected:
        choices = ", ".join(item.slug for item in benchmarks)
        raise ValueError(f"unknown benchmark {name!r}; choose one of: {choices}, all")
    return selected
