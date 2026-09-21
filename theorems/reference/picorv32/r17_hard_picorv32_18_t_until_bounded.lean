import R17Support
namespace picorv32Verification
open picorv32
theorem r16_bridge_01 : ∀ s i, r16Pred01 s i := by
  intro s i
  simpa [r16Pred01] using l1_assign_dbg_mem_valid_dbg_mem_valid_semantic s i
theorem r16_bridge_02 : ∀ s i, r16Pred02 s i := by
  intro s i
  simpa [r16Pred02] using l1_assign_dbg_mem_valid_alu_out_0_q_preserved s i
theorem r16_bridge_03 : ∀ s i, r16Pred03 s i := by
  intro s i
  simpa [r16Pred03] using l1_assign_dbg_mem_instr_dbg_mem_instr_semantic s i
theorem r16_bridge_04 : ∀ s i, r16Pred04 s i := by
  intro s i
  simpa [r16Pred04] using l1_assign_dbg_mem_instr_alu_out_0_q_preserved s i
theorem r17_reference_core : ∀ s i, R17All s i := by
  intro s i
  change (r16Pred01 s i ∧ r16Pred02 s i) ∧ (r16Pred03 s i ∧ r16Pred04 s i)
  exact ⟨⟨r16_bridge_01 s i, r16_bridge_02 s i⟩, ⟨r16_bridge_03 s i, r16_bridge_04 s i⟩⟩
theorem r17_hard_picorv32_18_t_until_bounded : ∀ s i xs, R16Until assign_dbg_mem_valid R17All R17Pair23 s (i :: xs) ∧ R16BoundedUntil assign_dbg_mem_valid R17All R17Pair14 3 s (i :: xs) := by
  intro s i xs
  exact ⟨Or.inl (⟨(r17_reference_core s i).1.2, (r17_reference_core s i).2.1⟩), Or.inl (⟨(r17_reference_core s i).1.1, (r17_reference_core s i).2.2⟩)⟩
end picorv32Verification
