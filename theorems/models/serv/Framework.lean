import Foundation

set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace serv_rf_topVerification
open serv_rf_top

theorem l1_assign_rf_ram_if__i_clk_rf_ram_if__i_clk_semantic : ∀ (s : serv_rf_topState) (i : serv_rf_topInputs), (assign_rf_ram_if__i_clk s i).rf_ram_if__i_clk = i.clk := by intro s i; rfl

theorem l1_assign_rf_ram_if__i_clk_cpu__alu__add_cy_r_preserved : ∀ (s : serv_rf_topState) (i : serv_rf_topInputs), (assign_rf_ram_if__i_clk s i).cpu__alu__add_cy_r = s.cpu__alu__add_cy_r := by intro s i; rfl

theorem l1_assign_rf_ram_if__i_rst_rf_ram_if__i_rst_semantic : ∀ (s : serv_rf_topState) (i : serv_rf_topInputs), (assign_rf_ram_if__i_rst s i).rf_ram_if__i_rst = i.i_rst := by intro s i; rfl

theorem l1_assign_rf_ram_if__i_rst_cpu__alu__add_cy_r_preserved : ∀ (s : serv_rf_topState) (i : serv_rf_topInputs), (assign_rf_ram_if__i_rst s i).cpu__alu__add_cy_r = s.cpu__alu__add_cy_r := by intro s i; rfl

theorem l1_assign_rf_ram_if__i_wreq_rf_ram_if__i_wreq_semantic : ∀ (s : serv_rf_topState) (i : serv_rf_topInputs), (assign_rf_ram_if__i_wreq s i).rf_ram_if__i_wreq = s.rf_wreq := by intro s i; rfl

theorem l1_assign_rf_ram_if__i_wreq_cpu__alu__add_cy_r_preserved : ∀ (s : serv_rf_topState) (i : serv_rf_topInputs), (assign_rf_ram_if__i_wreq s i).cpu__alu__add_cy_r = s.cpu__alu__add_cy_r := by intro s i; rfl

theorem l1_assign_rf_ram_if__i_rreq_rf_ram_if__i_rreq_semantic : ∀ (s : serv_rf_topState) (i : serv_rf_topInputs), (assign_rf_ram_if__i_rreq s i).rf_ram_if__i_rreq = s.rf_rreq := by intro s i; rfl

theorem l1_assign_rf_ram_if__i_rreq_cpu__alu__add_cy_r_preserved : ∀ (s : serv_rf_topState) (i : serv_rf_topInputs), (assign_rf_ram_if__i_rreq s i).cpu__alu__add_cy_r = s.cpu__alu__add_cy_r := by intro s i; rfl

theorem l1_assign_rf_ready_rf_ready_semantic : ∀ (s : serv_rf_topState) (i : serv_rf_topInputs), (assign_rf_ready s i).rf_ready = s.rf_ram_if__o_ready := by intro s i; rfl

theorem l1_assign_rf_ready_cpu__alu__add_cy_r_preserved : ∀ (s : serv_rf_topState) (i : serv_rf_topInputs), (assign_rf_ready s i).cpu__alu__add_cy_r = s.cpu__alu__add_cy_r := by intro s i; rfl

theorem l1_assign_rf_ram_if__i_wreg0_rf_ram_if__i_wreg0_semantic : ∀ (s : serv_rf_topState) (i : serv_rf_topInputs), (assign_rf_ram_if__i_wreg0 s i).rf_ram_if__i_wreg0 = s.wreg0 := by intro s i; rfl

theorem l1_assign_rf_ram_if__i_wreg0_cpu__alu__add_cy_r_preserved : ∀ (s : serv_rf_topState) (i : serv_rf_topInputs), (assign_rf_ram_if__i_wreg0 s i).cpu__alu__add_cy_r = s.cpu__alu__add_cy_r := by intro s i; rfl

theorem l2_proc_alwaysff_rf_ram_if__wdata0_r_update : ∀ (s : serv_rf_topState) (i : serv_rf_topInputs), (proc_alwaysff s i).rf_ram_if__wdata0_r = BitVec.append (n := 1) (m := 1) (boolToBitVec (s.rf_ram_if__i_wdata0)) (BitVec.extractLsb 1 1 (s.rf_ram_if__wdata0_r)) := by intro s i; rfl

theorem l2_proc_alwaysff_cpu__alu__add_cy_r_hold : ∀ (s : serv_rf_topState) (i : serv_rf_topInputs), (proc_alwaysff s i).cpu__alu__add_cy_r = s.cpu__alu__add_cy_r := by intro s i; rfl

theorem l2_proc_alwaysff_1_rf_ram_if__rdata1_update : ∀ (s : serv_rf_topState) (i : serv_rf_topInputs), (proc_alwaysff_1 s i).rf_ram_if__rdata1 = (if s.rf_ram_if__rtrig1 then bitVecToBool (BitVec.extractLsb 1 1 (s.rf_ram_if__i_rdata)) else s.rf_ram_if__rdata1) := by intro s i; rfl

theorem l2_proc_alwaysff_1_cpu__alu__add_cy_r_hold : ∀ (s : serv_rf_topState) (i : serv_rf_topInputs), (proc_alwaysff_1 s i).cpu__alu__add_cy_r = s.cpu__alu__add_cy_r := by intro s i; rfl

theorem l2_proc_alwaysff_2_rf_ram_if__rcnt_update : ∀ (s : serv_rf_topState) (i : serv_rf_topInputs), (proc_alwaysff_2 s i).rf_ram_if__rcnt = (if s.rf_ram_if__i_rst then BitVec.append (n := 2) (m := 3) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))) (BitVec.append (n := 1) (m := 2) (boolToBitVec (false)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false)))) else (if (s.rf_ram_if__i_rreq || s.rf_ram_if__i_wreq) then BitVec.append (n := 3) (m := 2) (BitVec.append (n := 1) (m := 2) (boolToBitVec (false)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false)))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.rf_ram_if__i_wreq)) (boolToBitVec (false))) else (s.rf_ram_if__rcnt + BitVec.append (n := 4) (m := 1) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false)))) (boolToBitVec (true))))) := by intro s i; rfl

theorem l2_proc_alwaysff_2_cpu__alu__add_cy_r_hold : ∀ (s : serv_rf_topState) (i : serv_rf_topInputs), (proc_alwaysff_2 s i).cpu__alu__add_cy_r = s.cpu__alu__add_cy_r := by intro s i; rfl

theorem l2_proc_alwaysff_3_rf_ram__memory_update : ∀ (s : serv_rf_topState) (i : serv_rf_topInputs), (proc_alwaysff_3 s i).rf_ram__memory = (if s.rf_ram__i_wen then bvArrayWrite 2 576 0 575 (s.rf_ram__memory) ((s.rf_ram__i_waddr).toNat) (s.rf_ram__i_wdata) else s.rf_ram__memory) := by intro s i; rfl

theorem l2_proc_alwaysff_3_cpu__alu__add_cy_r_hold : ∀ (s : serv_rf_topState) (i : serv_rf_topInputs), (proc_alwaysff_3 s i).cpu__alu__add_cy_r = s.cpu__alu__add_cy_r := by intro s i; rfl

theorem l2_proc_alwaysff_4_rf_ram__regzero_update : ∀ (s : serv_rf_topState) (i : serv_rf_topInputs), (proc_alwaysff_4 s i).rf_ram__regzero = BitVec.getLsbD (BitVec.extractLsb 5 0 (BitVec.extractLsb 5 0 (boolToBitVec (!(bvNonzero (BitVec.extractLsb 9 4 (s.rf_ram__i_raddr))))))) 0 := by intro s i; rfl

theorem l2_proc_alwaysff_4_cpu__alu__add_cy_r_hold : ∀ (s : serv_rf_topState) (i : serv_rf_topInputs), (proc_alwaysff_4 s i).cpu__alu__add_cy_r = s.cpu__alu__add_cy_r := by intro s i; rfl

theorem l2_proc_alwaysff_5_cpu__state__ibus_cyc_update : ∀ (s : serv_rf_topState) (i : serv_rf_topInputs), (proc_alwaysff_5 s i).cpu__state__ibus_cyc = (if ((s.cpu__state__i_ibus_ack || s.cpu__state__o_cnt_done) || s.cpu__state__i_rst) then (s.cpu__state__o_ctrl_pc_en || s.cpu__state__i_rst) else s.cpu__state__ibus_cyc) := by intro s i; rfl

theorem l2_proc_alwaysff_5_cpu__alu__add_cy_r_hold : ∀ (s : serv_rf_topState) (i : serv_rf_topInputs), (proc_alwaysff_5 s i).cpu__alu__add_cy_r = s.cpu__alu__add_cy_r := by intro s i; rfl

theorem l2_proc_alwaysff_6_cpu__state__gen_cnt_w_eq_1__cnt_lsb_update : ∀ (s : serv_rf_topState) (i : serv_rf_topInputs), (proc_alwaysff_6 s i).cpu__state__gen_cnt_w_eq_1__cnt_lsb = (if (s.cpu__state__i_rst && decide ((BitVec.ofNat 32 1296649801).toNat ≠ (BitVec.ofNat 32 1313820229).toNat)) then BitVec.ofNat 4 0 else BitVec.append (n := 3) (m := 1) (BitVec.extractLsb 2 0 (s.cpu__state__gen_cnt_w_eq_1__cnt_lsb)) (boolToBitVec (((BitVec.getLsbD (s.cpu__state__gen_cnt_w_eq_1__cnt_lsb) 3 && !(s.cpu__state__o_cnt_done)) || s.cpu__state__i_rf_ready)))) := by intro s i; rfl

theorem l2_proc_alwaysff_6_cpu__alu__add_cy_r_hold : ∀ (s : serv_rf_topState) (i : serv_rf_topInputs), (proc_alwaysff_6 s i).cpu__alu__add_cy_r = s.cpu__alu__add_cy_r := by intro s i; rfl

theorem l2_proc_alwaysff_7_cpu__state__gen_csr__misalign_trap_sync_r_update : ∀ (s : serv_rf_topState) (i : serv_rf_topInputs), (proc_alwaysff_7 s i).cpu__state__gen_csr__misalign_trap_sync_r = (if ((s.cpu__state__i_ibus_ack || s.cpu__state__o_cnt_done) || s.cpu__state__i_rst) then (!((s.cpu__state__i_ibus_ack || s.cpu__state__i_rst)) && ((s.cpu__state__trap_pending && s.cpu__state__o_init) || s.cpu__state__gen_csr__misalign_trap_sync_r)) else s.cpu__state__gen_csr__misalign_trap_sync_r) := by intro s i; rfl

theorem l2_proc_alwaysff_7_cpu__alu__add_cy_r_hold : ∀ (s : serv_rf_topState) (i : serv_rf_topInputs), (proc_alwaysff_7 s i).cpu__alu__add_cy_r = s.cpu__alu__add_cy_r := by intro s i; rfl

theorem l2_proc_alwaysff_deterministic : ∀ (s1 s2 : serv_rf_topState) (i : serv_rf_topInputs), s1 = s2 → proc_alwaysff s1 i = proc_alwaysff s2 i := by intro s1 s2 i h; cases h; rfl

theorem l3_step_definition : ∀ (s : serv_rf_topState) (i : serv_rf_topInputs), step s i = comb (commit (comb s i) i) i := by intro s i; rfl

theorem l3_step_deterministic : ∀ (s1 s2 : serv_rf_topState) (i : serv_rf_topInputs), s1 = s2 → step s1 i = step s2 i := by intro s1 s2 i h; cases h; rfl

theorem l3_o_ibus_adr_output_reflection : ∀ (s : serv_rf_topState) (i : serv_rf_topInputs) , (outputs (step s i)).o_ibus_adr = (step s i).o_ibus_adr := by intro s i ; rfl

theorem l4_run_nil : ∀ s : serv_rf_topState, run s [] = s := by intro s; rfl

theorem l4_run_cons : ∀ (s : serv_rf_topState) (i : serv_rf_topInputs) (xs : List serv_rf_topInputs), run s (i :: xs) = run (step s i) xs := by intro s i xs; rfl

theorem l4_reachable_init : Reachable init := by exact Reachable.init

theorem l4_reachable_step : ∀ (s : serv_rf_topState), Reachable s → (i : serv_rf_topInputs) → Reachable (step s i) := by intro s h i; exact Reachable.next h i

end serv_rf_topVerification
