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
theorem r17_hard_modexp_11_d_cross : ∀ s i, R17Pair23 s i ∧ R17Pair14 s i := by
  intro s i
  exact ⟨⟨(r17_reference_core s i).1.2, (r17_reference_core s i).2.1⟩, ⟨(r17_reference_core s i).1.1, (r17_reference_core s i).2.2⟩⟩
end modexp_coreVerification
