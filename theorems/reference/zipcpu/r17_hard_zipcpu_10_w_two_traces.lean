import R17Support
namespace zipcoreVerification
open zipcore
theorem r16_bridge_01 : ∀ s i, r16Pred01 s i := by
  intro s i
  simpa [r16Pred01] using l1_assign_clear_pipeline_clear_pipeline_semantic s i
theorem r16_bridge_02 : ∀ s i, r16Pred02 s i := by
  intro s i
  simpa [r16Pred02] using l1_assign_clear_pipeline_BUSLOCK__r_bus_lock_preserved s i
theorem r16_bridge_03 : ∀ s i, r16Pred03 s i := by
  intro s i
  simpa [r16Pred03] using l1_assign_div_ce_div_ce_semantic s i
theorem r16_bridge_04 : ∀ s i, r16Pred04 s i := by
  intro s i
  simpa [r16Pred04] using l1_assign_div_ce_BUSLOCK__r_bus_lock_preserved s i
theorem r17_reference_core : ∀ s i, R17All s i := by
  intro s i
  change (r16Pred01 s i ∧ r16Pred02 s i) ∧ (r16Pred03 s i ∧ r16Pred04 s i)
  exact ⟨⟨r16_bridge_01 s i, r16_bridge_02 s i⟩, ⟨r16_bridge_03 s i, r16_bridge_04 s i⟩⟩
theorem r17_hard_zipcpu_10_w_two_traces : ∀ s xs i j, ∃ ys zs, ys = xs ++ [i] ∧ zs = ys ++ [j] ∧ R17All (R16Run assign_clear_pipeline s xs) i ∧ R17All (R16Run assign_clear_pipeline s ys) j := by
  intro s xs i j
  refine ⟨xs ++ [i], (xs ++ [i]) ++ [j], rfl, rfl, r17_reference_core _ i, ?_⟩
  exact r17_reference_core (R16Run assign_clear_pipeline s (xs ++ [i])) j
end zipcoreVerification
