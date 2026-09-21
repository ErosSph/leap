import R17Support
namespace aes_coreVerification
open aes_core
theorem r16_bridge_01 : ∀ s i, r16Pred01 s i := by
  intro s i
  simpa [r16Pred01] using l1_assign_enc_block__clk_enc_block__clk_semantic s i
theorem r16_bridge_02 : ∀ s i, r16Pred02 s i := by
  intro s i
  simpa [r16Pred02] using l1_assign_enc_block__clk_aes_core_ctrl_reg_preserved s i
theorem r16_bridge_03 : ∀ s i, r16Pred03 s i := by
  intro s i
  simpa [r16Pred03] using l1_assign_enc_block__reset_n_enc_block__reset_n_semantic s i
theorem r16_bridge_04 : ∀ s i, r16Pred04 s i := by
  intro s i
  simpa [r16Pred04] using l1_assign_enc_block__reset_n_aes_core_ctrl_reg_preserved s i
theorem r17_reference_core : ∀ s i, R17All s i := by
  intro s i
  change (r16Pred01 s i ∧ r16Pred02 s i) ∧ (r16Pred03 s i ∧ r16Pred04 s i)
  exact ⟨⟨r16_bridge_01 s i, r16_bridge_02 s i⟩, ⟨r16_bridge_03 s i, r16_bridge_04 s i⟩⟩
theorem r17_hard_aes_15_w_trace_invariant : ∀ s xs i tail, ∃ ys, ys = xs ++ [i] ∧ ys ≠ [] ∧ R17All (R16Run assign_enc_block__reset_n s xs) i ∧ R16Always assign_enc_block__reset_n R17All (assign_enc_block__reset_n (R16Run assign_enc_block__reset_n s xs) i) tail := by
  have ha : ∀ t ys, R16Always assign_enc_block__reset_n R17All t ys := by
    intro t ys
    induction ys generalizing t with
    | nil => trivial
    | cons k ks ih =>
        exact ⟨r17_reference_core t k, ih (assign_enc_block__reset_n t k)⟩
  intro s xs i tail
  exact ⟨xs ++ [i], rfl, by simp, r17_reference_core _ i, ha _ tail⟩
end aes_coreVerification
