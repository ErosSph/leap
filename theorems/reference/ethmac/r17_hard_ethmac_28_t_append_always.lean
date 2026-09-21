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
theorem r17_hard_ethmac_28_t_append_always : ∀ s xs ys, R16Always assign_miim1__Reset R17All s (xs ++ ys) := by
  have ha : ∀ t ys, R16Always assign_miim1__Reset R17All t ys := by
    intro t ys
    induction ys generalizing t with
    | nil => trivial
    | cons k ks ih =>
        exact ⟨r17_reference_core t k, ih (assign_miim1__Reset t k)⟩
  intro s xs ys
  exact ha s (xs ++ ys)
end ethmacVerification
