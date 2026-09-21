import R17Support
namespace ethmacVerification
open ethmac
theorem r16_bridge_01 : ∀ s i, r16Pred01 s i := by
  intro s i
  simpa [r16Pred01] using l1_assign_miim1__Clk_miim1__Clk_semantic s i
theorem r16_bridge_02 : ∀ s i, r16Pred02 s i := by
  intro s i
  simpa [r16Pred02] using l1_assign_miim1__Clk_CarrierSense_Tx1_preserved s i
theorem r16_bridge_03 : ∀ s i, r16Pred03 s i := by
  intro s i
  simpa [r16Pred03] using l1_assign_miim1__Reset_miim1__Reset_semantic s i
theorem r16_bridge_04 : ∀ s i, r16Pred04 s i := by
  intro s i
  simpa [r16Pred04] using l1_assign_miim1__Reset_CarrierSense_Tx1_preserved s i
theorem r17_reference_core : ∀ s i, R17All s i := by
  intro s i
  change (r16Pred01 s i ∧ r16Pred02 s i) ∧ (r16Pred03 s i ∧ r16Pred04 s i)
  exact ⟨⟨r16_bridge_01 s i, r16_bridge_02 s i⟩, ⟨r16_bridge_03 s i, r16_bridge_04 s i⟩⟩
theorem r17_hard_ethmac_25_w_split : ∀ s xs i j, ∃ pre suf, pre = xs ∧ suf = [i, j] ∧ R16Run assign_miim1__Clk s (pre ++ suf) = assign_miim1__Clk (assign_miim1__Clk (R16Run assign_miim1__Clk s xs) i) j ∧ R17All (R16Run assign_miim1__Clk s xs) i := by
  intro s xs i j
  refine ⟨xs, [i, j], rfl, rfl, ?_, r17_reference_core _ i⟩
  simp [R16Run, List.foldl_append]
end ethmacVerification
