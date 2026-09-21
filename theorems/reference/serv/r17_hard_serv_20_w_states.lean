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
theorem r17_hard_serv_20_w_states : ∀ s i j, ∃ mid fin, mid = assign_rf_ram_if__i_rst s i ∧ fin = assign_rf_ram_if__i_rst mid j ∧ R17All s i ∧ R17All mid j := by
  intro s i j
  exact ⟨assign_rf_ram_if__i_rst s i, assign_rf_ram_if__i_rst (assign_rf_ram_if__i_rst s i) j, rfl, rfl, r17_reference_core s i, r17_reference_core _ j⟩
end serv_rf_topVerification
