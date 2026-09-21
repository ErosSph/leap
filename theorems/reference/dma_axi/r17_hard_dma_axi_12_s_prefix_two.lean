import R17Support
namespace dma_axi32_core0_chVerification
open dma_axi32_core0_ch
theorem r16_bridge_01 : ∀ s i, r16Pred01 s i := by
  intro s i
  simpa [r16Pred01] using l1_assign_ch_active_ch_active_semantic s i
theorem r16_bridge_02 : ∀ s i, r16Pred02 s i := by
  intro s i
  simpa [r16Pred02] using l1_assign_ch_active_delay_idle__shift_reg_preserved s i
theorem r16_bridge_03 : ∀ s i, r16Pred03 s i := by
  intro s i
  simpa [r16Pred03] using l1_assign_outs_empty_outs_empty_semantic s i
theorem r16_bridge_04 : ∀ s i, r16Pred04 s i := by
  intro s i
  simpa [r16Pred04] using l1_assign_outs_empty_delay_idle__shift_reg_preserved s i
theorem r17_reference_core : ∀ s i, R17All s i := by
  intro s i
  change (r16Pred01 s i ∧ r16Pred02 s i) ∧ (r16Pred03 s i ∧ r16Pred04 s i)
  exact ⟨⟨r16_bridge_01 s i, r16_bridge_02 s i⟩, ⟨r16_bridge_03 s i, r16_bridge_04 s i⟩⟩
theorem r17_hard_dma_axi_12_s_prefix_two : ∀ s xs i j, R17All (R16Run assign_outs_empty s xs) i ∧ R17All (assign_outs_empty (R16Run assign_outs_empty s xs) i) j ∧ R16Run assign_outs_empty s (xs ++ [i, j]) = assign_outs_empty (assign_outs_empty (R16Run assign_outs_empty s xs) i) j := by
  intro s xs i j
  refine ⟨r17_reference_core _ i, r17_reference_core _ j, ?_⟩
  simp [R16Run, List.foldl_append]
end dma_axi32_core0_chVerification
