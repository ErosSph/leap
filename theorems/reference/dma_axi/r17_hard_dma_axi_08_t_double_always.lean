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
theorem r17_hard_dma_axi_08_t_double_always : ∀ s xs, R16Always assign_outs_empty R17Pair12 s xs ∧ R16Always assign_outs_empty R17Pair34 s xs := by
  have ha : ∀ t ys, R16Always assign_outs_empty R17Pair12 t ys := by
    intro t ys
    induction ys generalizing t with
    | nil => trivial
    | cons k ks ih =>
        exact ⟨(r17_reference_core t k).1, ih (assign_outs_empty t k)⟩
  have hb : ∀ t ys, R16Always assign_outs_empty R17Pair34 t ys := by
    intro t ys
    induction ys generalizing t with
    | nil => trivial
    | cons k ks ih =>
        exact ⟨(r17_reference_core t k).2, ih (assign_outs_empty t k)⟩
  intro s xs
  exact ⟨ha s xs, hb s xs⟩
end dma_axi32_core0_chVerification
