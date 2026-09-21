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
theorem r17_hard_picorv32_20_w_states : ∀ s i j, ∃ mid fin, mid = assign_dbg_mem_instr s i ∧ fin = assign_dbg_mem_instr mid j ∧ R17All s i ∧ R17All mid j := by
  intro s i j
  exact ⟨assign_dbg_mem_instr s i, assign_dbg_mem_instr (assign_dbg_mem_instr s i) j, rfl, rfl, r17_reference_core s i, r17_reference_core _ j⟩
end picorv32Verification
