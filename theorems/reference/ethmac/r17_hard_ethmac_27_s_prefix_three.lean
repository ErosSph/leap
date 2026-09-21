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
theorem r17_hard_ethmac_27_s_prefix_three : ∀ s xs i j k, R17All (R16Run assign_miim1__Reset s xs) i ∧ R17All (assign_miim1__Reset (R16Run assign_miim1__Reset s xs) i) j ∧ R17All (assign_miim1__Reset (assign_miim1__Reset (R16Run assign_miim1__Reset s xs) i) j) k ∧ R16Run assign_miim1__Reset s (xs ++ [i, j, k]) = assign_miim1__Reset (assign_miim1__Reset (assign_miim1__Reset (R16Run assign_miim1__Reset s xs) i) j) k := by
  intro s xs i j k
  refine ⟨r17_reference_core _ i, r17_reference_core _ j, r17_reference_core _ k, ?_⟩
  simp [R16Run, List.foldl_append]
end ethmacVerification
