from pathlib import Path

from experiments.challenge_suite.config import DUTS, load_config
from experiments.challenge_suite.corpus import CATEGORIES, GROUPS


PROJECT = Path(__file__).resolve().parents[1]


def test_challenge_suite_config_and_hard_plan():
    config = load_config(PROJECT / "configs/challenge_suite.yaml")
    assert config["duts"] == DUTS
    assert sum(config["properties_per_dut"].values()) == 177
    assert len(GROUPS) == len(CATEGORIES) == 5
    assert all(len(group) == 6 for group in GROUPS)


def test_no_graph_ablation_is_not_direct():
    text = (PROJECT / "experiments/challenge_suite/ablation.py").read_text()
    assert '"lemma_first": True' in text
    assert '"same_dut_pool": True' in text
    assert '"no_graph_is_not_direct": True' in text
