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
theorem r17_hard_aes_10_w_two_traces : ∀ s xs i j, ∃ ys zs, ys = xs ++ [i] ∧ zs = ys ++ [j] ∧ R17All (R16Run assign_enc_block__clk s xs) i ∧ R17All (R16Run assign_enc_block__clk s ys) j := by
  intro s xs i j
  refine ⟨xs ++ [i], (xs ++ [i]) ++ [j], rfl, rfl, r17_reference_core _ i, ?_⟩
  exact r17_reference_core (R16Run assign_enc_block__clk s (xs ++ [i])) j
end aes_coreVerification
