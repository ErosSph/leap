import R17Support
namespace modexp_coreVerification
open modexp_core
theorem r16_bridge_01 : ∀ s i, r16Pred01 s i := by
  intro s i
  simpa [r16Pred01] using l1_assign_ready_ready_semantic s i
theorem r16_bridge_02 : ∀ s i, r16Pred02 s i := by
  intro s i
  simpa [r16Pred02] using l1_assign_ready_b_one_reg_preserved s i
theorem r16_bridge_03 : ∀ s i, r16Pred03 s i := by
  intro s i
  simpa [r16Pred03] using l1_assign_cycles_cycles_semantic s i
theorem r16_bridge_04 : ∀ s i, r16Pred04 s i := by
  intro s i
  simpa [r16Pred04] using l1_assign_cycles_b_one_reg_preserved s i
theorem r17_reference_core : ∀ s i, R17All s i := by
  intro s i
  change (r16Pred01 s i ∧ r16Pred02 s i) ∧ (r16Pred03 s i ∧ r16Pred04 s i)
  exact ⟨⟨r16_bridge_01 s i, r16_bridge_02 s i⟩, ⟨r16_bridge_03 s i, r16_bridge_04 s i⟩⟩
theorem r17_hard_modexp_14_r_dual : ∀ s xs ys i, R16Reachable assign_ready s (R16Run assign_ready s xs) ∧ R16Reachable assign_cycles s (R16Run assign_cycles s ys) ∧ R17All s i := by
  intro s xs ys i
  exact ⟨⟨xs, rfl⟩, ⟨ys, rfl⟩, r17_reference_core s i⟩
end modexp_coreVerification
