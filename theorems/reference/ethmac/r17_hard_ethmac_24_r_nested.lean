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
theorem r17_hard_ethmac_24_r_nested : ∀ s xs ys i, ∃ mid, mid = R16Run assign_miim1__Reset s xs ∧ R16Reachable assign_miim1__Reset s mid ∧ R16Reachable assign_miim1__Reset mid (R16Run assign_miim1__Reset mid ys) ∧ R17All mid i := by
  intro s xs ys i
  refine ⟨R16Run assign_miim1__Reset s xs, rfl, ⟨xs, rfl⟩, ⟨ys, rfl⟩, r17_reference_core _ i⟩
end ethmacVerification
