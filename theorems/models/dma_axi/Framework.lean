import Foundation

set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace dma_axi32_core0_chVerification
open dma_axi32_core0_ch

theorem l1_assign_ch_active_ch_active_semantic : ∀ (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs), (assign_ch_active s i).ch_active = (s.ch_in_prog || s.load_in_prog) := by intro s i; rfl

theorem l1_assign_ch_active_delay_idle__shift_reg_preserved : ∀ (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs), (assign_ch_active s i).delay_idle__shift_reg = s.delay_idle__shift_reg := by intro s i; rfl

theorem l1_assign_outs_empty_outs_empty_semantic : ∀ (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs), (assign_outs_empty s i).outs_empty = (s.rd_outs_empty && s.wr_outs_empty) := by intro s i; rfl

theorem l1_assign_outs_empty_delay_idle__shift_reg_preserved : ∀ (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs), (assign_outs_empty s i).delay_idle__shift_reg = s.delay_idle__shift_reg := by intro s i; rfl

theorem l1_assign_rd_clr_outs_d_pre_rd_clr_outs_d_pre_semantic : ∀ (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs), (assign_rd_clr_outs_d_pre s i).rd_clr_outs_d_pre = (s.rd_clr_outs && !(i.rd_burst_start)) := by intro s i; rfl

theorem l1_assign_rd_clr_outs_d_pre_delay_idle__shift_reg_preserved : ∀ (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs), (assign_rd_clr_outs_d_pre s i).delay_idle__shift_reg = s.delay_idle__shift_reg := by intro s i; rfl

theorem l1_assign_wr_clr_outs_d_pre_wr_clr_outs_d_pre_semantic : ∀ (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs), (assign_wr_clr_outs_d_pre s i).wr_clr_outs_d_pre = (s.wr_clr_outs && !(i.wr_burst_start)) := by intro s i; rfl

theorem l1_assign_wr_clr_outs_d_pre_delay_idle__shift_reg_preserved : ∀ (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs), (assign_wr_clr_outs_d_pre s i).delay_idle__shift_reg = s.delay_idle__shift_reg := by intro s i; rfl

theorem l1_assign_delay_rd_clr_outs__clk_delay_rd_clr_outs__clk_semantic : ∀ (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs), (assign_delay_rd_clr_outs__clk s i).delay_rd_clr_outs__clk = i.clk := by intro s i; rfl

theorem l1_assign_delay_rd_clr_outs__clk_delay_idle__shift_reg_preserved : ∀ (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs), (assign_delay_rd_clr_outs__clk s i).delay_idle__shift_reg = s.delay_idle__shift_reg := by intro s i; rfl

theorem l1_assign_delay_rd_clr_outs__reset_delay_rd_clr_outs__reset_semantic : ∀ (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs), (assign_delay_rd_clr_outs__reset s i).delay_rd_clr_outs__reset = i.reset := by intro s i; rfl

theorem l1_assign_delay_rd_clr_outs__reset_delay_idle__shift_reg_preserved : ∀ (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs), (assign_delay_rd_clr_outs__reset s i).delay_idle__shift_reg = s.delay_idle__shift_reg := by intro s i; rfl

theorem l2_proc_alwaysff_delay_rd_clr_outs__shift_reg_update : ∀ (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs), (proc_alwaysff s i).delay_rd_clr_outs__shift_reg = (if s.delay_rd_clr_outs__reset then BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false)) else BitVec.append (n := 1) (m := 1) (BitVec.extractLsb 0 0 (s.delay_rd_clr_outs__shift_reg)) (boolToBitVec (s.delay_rd_clr_outs__din))) := by intro s i; rfl

theorem l2_proc_alwaysff_delay_idle__shift_reg_hold : ∀ (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs), (proc_alwaysff s i).delay_idle__shift_reg = s.delay_idle__shift_reg := by intro s i; rfl

theorem l2_proc_alwaysff_1_delay_wr_clr_outs__shift_reg_update : ∀ (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs), (proc_alwaysff_1 s i).delay_wr_clr_outs__shift_reg = (if s.delay_wr_clr_outs__reset then BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false)) else BitVec.append (n := 1) (m := 1) (BitVec.extractLsb 0 0 (s.delay_wr_clr_outs__shift_reg)) (boolToBitVec (s.delay_wr_clr_outs__din))) := by intro s i; rfl

theorem l2_proc_alwaysff_1_delay_idle__shift_reg_hold : ∀ (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs), (proc_alwaysff_1 s i).delay_idle__shift_reg = s.delay_idle__shift_reg := by intro s i; rfl

theorem l2_proc_alwaysff_2_delay_rd_clr__shift_reg_update : ∀ (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs), (proc_alwaysff_2 s i).delay_rd_clr__shift_reg = (if s.delay_rd_clr__reset then BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false)) else BitVec.append (n := 1) (m := 1) (BitVec.extractLsb 0 0 (s.delay_rd_clr__shift_reg)) (boolToBitVec (s.delay_rd_clr__din))) := by intro s i; rfl

theorem l2_proc_alwaysff_2_delay_idle__shift_reg_hold : ∀ (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs), (proc_alwaysff_2 s i).delay_idle__shift_reg = s.delay_idle__shift_reg := by intro s i; rfl

theorem l2_proc_alwaysff_3_delay_wr_clr__shift_reg_update : ∀ (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs), (proc_alwaysff_3 s i).delay_wr_clr__shift_reg = (if s.delay_wr_clr__reset then BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false)) else BitVec.append (n := 1) (m := 1) (BitVec.extractLsb 0 0 (s.delay_wr_clr__shift_reg)) (boolToBitVec (s.delay_wr_clr__din))) := by intro s i; rfl

theorem l2_proc_alwaysff_3_delay_idle__shift_reg_hold : ∀ (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs), (proc_alwaysff_3 s i).delay_idle__shift_reg = s.delay_idle__shift_reg := by intro s i; rfl

theorem l2_proc_alwaysff_4_rd_joint_not_in_prog_update : ∀ (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs), (proc_alwaysff_4 s i).rd_joint_not_in_prog = (if i.reset then false else (if s.ch_update then false else (if i.rd_burst_start then !(s.joint_req) else (if (s.rd_outs_empty && s.rd_clr_outs_d) then false else s.rd_joint_not_in_prog)))) := by intro s i; rfl

theorem l2_proc_alwaysff_4_delay_idle__shift_reg_hold : ∀ (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs), (proc_alwaysff_4 s i).delay_idle__shift_reg = s.delay_idle__shift_reg := by intro s i; rfl

theorem l2_proc_alwaysff_5_wr_joint_not_in_prog_update : ∀ (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs), (proc_alwaysff_5 s i).wr_joint_not_in_prog = (if i.reset then false else (if s.ch_update then false else (if i.wr_burst_start then !(s.joint_req) else (if (s.wr_outs_empty && s.wr_clr_outs_d) then false else s.wr_joint_not_in_prog)))) := by intro s i; rfl

theorem l2_proc_alwaysff_5_delay_idle__shift_reg_hold : ∀ (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs), (proc_alwaysff_5 s i).delay_idle__shift_reg = s.delay_idle__shift_reg := by intro s i; rfl

theorem l2_proc_alwaysff_6_rd_joint_in_prog_update : ∀ (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs), (proc_alwaysff_6 s i).rd_joint_in_prog = (if i.reset then false else (if s.ch_update then false else (if i.rd_burst_start then s.joint_req else (if (s.rd_outs_empty && s.rd_clr_outs_d) then false else s.rd_joint_in_prog)))) := by intro s i; rfl

theorem l2_proc_alwaysff_6_delay_idle__shift_reg_hold : ∀ (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs), (proc_alwaysff_6 s i).delay_idle__shift_reg = s.delay_idle__shift_reg := by intro s i; rfl

theorem l2_proc_alwaysff_7_wr_joint_in_prog_update : ∀ (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs), (proc_alwaysff_7 s i).wr_joint_in_prog = (if i.reset then false else (if s.ch_update then false else (if i.wr_burst_start then s.joint_req else (if (s.wr_outs_empty && s.wr_clr_outs_d) then false else s.wr_joint_in_prog)))) := by intro s i; rfl

theorem l2_proc_alwaysff_7_delay_idle__shift_reg_hold : ∀ (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs), (proc_alwaysff_7 s i).delay_idle__shift_reg = s.delay_idle__shift_reg := by intro s i; rfl

theorem l2_proc_alwaysff_deterministic : ∀ (s1 s2 : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs), s1 = s2 → proc_alwaysff s1 i = proc_alwaysff s2 i := by intro s1 s2 i h; cases h; rfl

theorem l3_step_event_definition : ∀ (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs) (e : ClockEvent), step s i e = stepEvent s i e := by intro s i e; rfl

theorem l3_step_event_deterministic : ∀ (s1 s2 : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs) (e : ClockEvent), s1 = s2 → step s1 i e = step s2 i e := by intro s1 s2 i e h; cases h; rfl

theorem l3_prdata_output_reflection : ∀ (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs) (e : ClockEvent) , (outputs (step s i e)).prdata = (step s i e).prdata := by intro s i e; rfl

theorem l4_run_nil : ∀ s : dma_axi32_core0_chState, run s [] = s := by intro s; rfl

theorem l4_run_cons : ∀ (s : dma_axi32_core0_chState) (x : EventInput) (xs : List EventInput), run s (x :: xs) = run (step s x.1 x.2) xs := by intro s x xs; rfl

theorem l4_reachable_init : Reachable init := by exact Reachable.init

theorem l4_reachable_step : ∀ (s : dma_axi32_core0_chState), Reachable s → (i : dma_axi32_core0_chInputs) → (e : ClockEvent) → Reachable (step s i e) := by intro s h i e; exact Reachable.next h i e

end dma_axi32_core0_chVerification
