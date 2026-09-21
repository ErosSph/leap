import Foundation

set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace modexp_coreVerification
open modexp_core

theorem l1_assign_ready_ready_semantic : ∀ (s : modexp_coreState) (i : modexp_coreInputs), (assign_ready s i).ready = s.ready_reg := by intro s i; rfl

theorem l1_assign_ready_b_one_reg_preserved : ∀ (s : modexp_coreState) (i : modexp_coreInputs), (assign_ready s i).b_one_reg = s.b_one_reg := by intro s i; rfl

theorem l1_assign_cycles_cycles_semantic : ∀ (s : modexp_coreState) (i : modexp_coreInputs), (assign_cycles s i).cycles = BitVec.append (n := 32) (m := 32) (s.cycle_ctr_high_reg) (s.cycle_ctr_low_reg) := by intro s i; rfl

theorem l1_assign_cycles_b_one_reg_preserved : ∀ (s : modexp_coreState) (i : modexp_coreInputs), (assign_cycles s i).b_one_reg = s.b_one_reg := by intro s i; rfl

theorem l1_assign_length_m1_length_m1_semantic : ∀ (s : modexp_coreState) (i : modexp_coreInputs), (assign_length_m1 s i).length_m1 = (i.modulus_length - BitVec.ofNat 8 1) := by intro s i; rfl

theorem l1_assign_length_m1_b_one_reg_preserved : ∀ (s : modexp_coreState) (i : modexp_coreInputs), (assign_length_m1 s i).b_one_reg = s.b_one_reg := by intro s i; rfl

theorem l1_assign_montprod_inst__clk_montprod_inst__clk_semantic : ∀ (s : modexp_coreState) (i : modexp_coreInputs), (assign_montprod_inst__clk s i).montprod_inst__clk = i.clk := by intro s i; rfl

theorem l1_assign_montprod_inst__clk_b_one_reg_preserved : ∀ (s : modexp_coreState) (i : modexp_coreInputs), (assign_montprod_inst__clk s i).b_one_reg = s.b_one_reg := by intro s i; rfl

theorem l1_assign_montprod_inst__reset_n_montprod_inst__reset_n_semantic : ∀ (s : modexp_coreState) (i : modexp_coreInputs), (assign_montprod_inst__reset_n s i).montprod_inst__reset_n = i.reset_n := by intro s i; rfl

theorem l1_assign_montprod_inst__reset_n_b_one_reg_preserved : ∀ (s : modexp_coreState) (i : modexp_coreInputs), (assign_montprod_inst__reset_n s i).b_one_reg = s.b_one_reg := by intro s i; rfl

theorem l1_assign_montprod_inst__calculate_montprod_inst__calculate_semantic : ∀ (s : modexp_coreState) (i : modexp_coreInputs), (assign_montprod_inst__calculate s i).montprod_inst__calculate = s.montprod_calc := by intro s i; rfl

theorem l1_assign_montprod_inst__calculate_b_one_reg_preserved : ∀ (s : modexp_coreState) (i : modexp_coreInputs), (assign_montprod_inst__calculate s i).b_one_reg = s.b_one_reg := by intro s i; rfl

theorem l2_proc_alwaysff_montprod_inst__s_mem__mem_update : ∀ (s : modexp_coreState) (i : modexp_coreInputs), (proc_alwaysff s i).montprod_inst__s_mem__mem = (if s.montprod_inst__s_mem__wr then bvArrayWrite 32 256 0 255 (s.montprod_inst__s_mem__mem) ((s.montprod_inst__s_mem__write_addr).toNat) (s.montprod_inst__s_mem__write_data) else s.montprod_inst__s_mem__mem) := by intro s i; rfl

theorem l2_proc_alwaysff_b_one_reg_hold : ∀ (s : modexp_coreState) (i : modexp_coreInputs), (proc_alwaysff s i).b_one_reg = s.b_one_reg := by intro s i; rfl

theorem l2_proc_alwaysff_1_montprod_inst__B_bit_index_reg_update : ∀ (s : modexp_coreState) (i : modexp_coreInputs), (proc_alwaysff_1 s i).montprod_inst__B_bit_index_reg = (if !(s.montprod_inst__reset_n) then BitVec.ofNat 5 0 else s.montprod_inst__B_bit_index) := by intro s i; rfl

theorem l2_proc_alwaysff_1_b_one_reg_hold : ∀ (s : modexp_coreState) (i : modexp_coreInputs), (proc_alwaysff_1 s i).b_one_reg = s.b_one_reg := by intro s i; rfl

theorem l2_proc_alwaysff_2_residue_inst__length_m1_reg_update : ∀ (s : modexp_coreState) (i : modexp_coreInputs), (proc_alwaysff_2 s i).residue_inst__length_m1_reg = (if !(s.residue_inst__reset_n) then BitVec.ofNat 8 0 else (if s.residue_inst__length_m1_we then s.residue_inst__length_m1_new else s.residue_inst__length_m1_reg)) := by intro s i; rfl

theorem l2_proc_alwaysff_2_b_one_reg_hold : ∀ (s : modexp_coreState) (i : modexp_coreInputs), (proc_alwaysff_2 s i).b_one_reg = s.b_one_reg := by intro s i; rfl

theorem l2_proc_alwaysff_3_residue_mem__mem_update : ∀ (s : modexp_coreState) (i : modexp_coreInputs), (proc_alwaysff_3 s i).residue_mem__mem = (if s.residue_mem__wr then bvArrayWrite 32 256 0 255 (s.residue_mem__mem) ((s.residue_mem__write_addr).toNat) (s.residue_mem__write_data) else s.residue_mem__mem) := by intro s i; rfl

theorem l2_proc_alwaysff_3_b_one_reg_hold : ∀ (s : modexp_coreState) (i : modexp_coreInputs), (proc_alwaysff_3 s i).b_one_reg = s.b_one_reg := by intro s i; rfl

theorem l2_proc_alwaysff_4_p_mem__mem_update : ∀ (s : modexp_coreState) (i : modexp_coreInputs), (proc_alwaysff_4 s i).p_mem__mem = (if s.p_mem__wr then bvArrayWrite 32 256 0 255 (s.p_mem__mem) ((s.p_mem__write_addr).toNat) (s.p_mem__write_data) else s.p_mem__mem) := by intro s i; rfl

theorem l2_proc_alwaysff_4_b_one_reg_hold : ∀ (s : modexp_coreState) (i : modexp_coreInputs), (proc_alwaysff_4 s i).b_one_reg = s.b_one_reg := by intro s i; rfl

theorem l2_proc_alwaysff_5_exponent_mem__mem_update : ∀ (s : modexp_coreState) (i : modexp_coreInputs), (proc_alwaysff_5 s i).exponent_mem__mem = (if s.exponent_mem__wr then bvArrayWrite 32 256 0 255 (s.exponent_mem__mem) ((s.exponent_mem__ptr_reg).toNat) (s.exponent_mem__write_data) else s.exponent_mem__mem) := by intro s i; rfl

theorem l2_proc_alwaysff_5_b_one_reg_hold : ∀ (s : modexp_coreState) (i : modexp_coreInputs), (proc_alwaysff_5 s i).b_one_reg = s.b_one_reg := by intro s i; rfl

theorem l2_proc_alwaysff_6_exponent_mem__ptr_reg_update : ∀ (s : modexp_coreState) (i : modexp_coreInputs), (proc_alwaysff_6 s i).exponent_mem__ptr_reg = (if !(s.exponent_mem__reset_n) then BitVec.ofNat 8 0 else (if s.exponent_mem__ptr_we then s.exponent_mem__ptr_new else s.exponent_mem__ptr_reg)) := by intro s i; rfl

theorem l2_proc_alwaysff_6_b_one_reg_hold : ∀ (s : modexp_coreState) (i : modexp_coreInputs), (proc_alwaysff_6 s i).b_one_reg = s.b_one_reg := by intro s i; rfl

theorem l2_proc_alwaysff_7_modulus_mem__mem_update : ∀ (s : modexp_coreState) (i : modexp_coreInputs), (proc_alwaysff_7 s i).modulus_mem__mem = (if s.modulus_mem__wr then bvArrayWrite 32 256 0 255 (s.modulus_mem__mem) ((s.modulus_mem__ptr_reg).toNat) (s.modulus_mem__write_data) else s.modulus_mem__mem) := by intro s i; rfl

theorem l2_proc_alwaysff_7_b_one_reg_hold : ∀ (s : modexp_coreState) (i : modexp_coreInputs), (proc_alwaysff_7 s i).b_one_reg = s.b_one_reg := by intro s i; rfl

theorem l2_proc_alwaysff_deterministic : ∀ (s1 s2 : modexp_coreState) (i : modexp_coreInputs), s1 = s2 → proc_alwaysff s1 i = proc_alwaysff s2 i := by intro s1 s2 i h; cases h; rfl

theorem l3_step_definition : ∀ (s : modexp_coreState) (i : modexp_coreInputs), step s i = comb (commit (comb s i) i) i := by intro s i; rfl

theorem l3_step_deterministic : ∀ (s1 s2 : modexp_coreState) (i : modexp_coreInputs), s1 = s2 → step s1 i = step s2 i := by intro s1 s2 i h; cases h; rfl

theorem l3_ready_output_reflection : ∀ (s : modexp_coreState) (i : modexp_coreInputs) , (outputs (step s i)).ready = (step s i).ready := by intro s i ; rfl

theorem l4_run_nil : ∀ s : modexp_coreState, run s [] = s := by intro s; rfl

theorem l4_run_cons : ∀ (s : modexp_coreState) (i : modexp_coreInputs) (xs : List modexp_coreInputs), run s (i :: xs) = run (step s i) xs := by intro s i xs; rfl

theorem l4_reachable_init : Reachable init := by exact Reachable.init

theorem l4_reachable_step : ∀ (s : modexp_coreState), Reachable s → (i : modexp_coreInputs) → Reachable (step s i) := by intro s h i; exact Reachable.next h i

end modexp_coreVerification
