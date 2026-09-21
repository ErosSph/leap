import R17Support
namespace serv_rf_topVerification
open serv_rf_top
theorem r16_bridge_01 : ∀ s i, r16Pred01 s i := by
  intro s i
  simpa [r16Pred01] using l1_assign_rf_ram_if__i_clk_rf_ram_if__i_clk_semantic s i
theorem r16_bridge_02 : ∀ s i, r16Pred02 s i := by
  intro s i
  simpa [r16Pred02] using l1_assign_rf_ram_if__i_clk_cpu__alu__add_cy_r_preserved s i
theorem r16_bridge_03 : ∀ s i, r16Pred03 s i := by
  intro s i
  simpa [r16Pred03] using l1_assign_rf_ram_if__i_rst_rf_ram_if__i_rst_semantic s i
theorem r16_bridge_04 : ∀ s i, r16Pred04 s i := by
  intro s i
  simpa [r16Pred04] using l1_assign_rf_ram_if__i_rst_cpu__alu__add_cy_r_preserved s i
theorem r17_reference_core : ∀ s i, R17All s i := by
  intro s i
  change (r16Pred01 s i ∧ r16Pred02 s i) ∧ (r16Pred03 s i ∧ r16Pred04 s i)
  exact ⟨⟨r16_bridge_01 s i, r16_bridge_02 s i⟩, ⟨r16_bridge_03 s i, r16_bridge_04 s i⟩⟩
theorem r17_hard_serv_03_t_always : ∀ s xs, R16Always assign_rf_ram_if__i_rst R17All s xs := by
  have ha : ∀ t ys, R16Always assign_rf_ram_if__i_rst R17All t ys := by
    intro t ys
    induction ys generalizing t with
    | nil => trivial
    | cons k ks ih =>
        exact ⟨r17_reference_core t k, ih (assign_rf_ram_if__i_rst t k)⟩
  exact ha
end serv_rf_topVerification
