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
theorem r17_hard_serv_05_w_two_step : ∀ s xs i j, ∃ ys, ys = xs ++ [i, j] ∧ ys ≠ [] ∧ R16Run assign_rf_ram_if__i_clk s ys = assign_rf_ram_if__i_clk (assign_rf_ram_if__i_clk (R16Run assign_rf_ram_if__i_clk s xs) i) j ∧ R17All (R16Run assign_rf_ram_if__i_clk s xs) i := by
  intro s xs i j
  refine ⟨xs ++ [i, j], rfl, by simp, ?_, r17_reference_core _ i⟩
  simp [R16Run, List.foldl_append]
end serv_rf_topVerification
