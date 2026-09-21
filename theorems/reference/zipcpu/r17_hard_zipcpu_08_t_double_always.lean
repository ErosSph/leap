import R17Support
namespace zipcoreVerification
open zipcore
theorem r16_bridge_01 : ∀ s i, r16Pred01 s i := by
  intro s i
  simpa [r16Pred01] using l1_assign_clear_pipeline_clear_pipeline_semantic s i
theorem r16_bridge_02 : ∀ s i, r16Pred02 s i := by
  intro s i
  simpa [r16Pred02] using l1_assign_clear_pipeline_BUSLOCK__r_bus_lock_preserved s i
theorem r16_bridge_03 : ∀ s i, r16Pred03 s i := by
  intro s i
  simpa [r16Pred03] using l1_assign_div_ce_div_ce_semantic s i
theorem r16_bridge_04 : ∀ s i, r16Pred04 s i := by
  intro s i
  simpa [r16Pred04] using l1_assign_div_ce_BUSLOCK__r_bus_lock_preserved s i
theorem r17_reference_core : ∀ s i, R17All s i := by
  intro s i
  change (r16Pred01 s i ∧ r16Pred02 s i) ∧ (r16Pred03 s i ∧ r16Pred04 s i)
  exact ⟨⟨r16_bridge_01 s i, r16_bridge_02 s i⟩, ⟨r16_bridge_03 s i, r16_bridge_04 s i⟩⟩
theorem r17_hard_zipcpu_08_t_double_always : ∀ s xs, R16Always assign_div_ce R17Pair12 s xs ∧ R16Always assign_div_ce R17Pair34 s xs := by
  have ha : ∀ t ys, R16Always assign_div_ce R17Pair12 t ys := by
    intro t ys
    induction ys generalizing t with
    | nil => trivial
    | cons k ks ih =>
        exact ⟨(r17_reference_core t k).1, ih (assign_div_ce t k)⟩
  have hb : ∀ t ys, R16Always assign_div_ce R17Pair34 t ys := by
    intro t ys
    induction ys generalizing t with
    | nil => trivial
    | cons k ks ih =>
        exact ⟨(r17_reference_core t k).2, ih (assign_div_ce t k)⟩
  intro s xs
  exact ⟨ha s xs, hb s xs⟩
end zipcoreVerification
