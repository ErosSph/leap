import Foundation

set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace ethmacVerification
open ethmac

theorem l1_assign_miim1__Clk_miim1__Clk_semantic : ∀ (s : ethmacState) (i : ethmacInputs), (assign_miim1__Clk s i).miim1__Clk = i.wb_clk_i := by intro s i; rfl

theorem l1_assign_miim1__Clk_CarrierSense_Tx1_preserved : ∀ (s : ethmacState) (i : ethmacInputs), (assign_miim1__Clk s i).CarrierSense_Tx1 = s.CarrierSense_Tx1 := by intro s i; rfl

theorem l1_assign_miim1__Reset_miim1__Reset_semantic : ∀ (s : ethmacState) (i : ethmacInputs), (assign_miim1__Reset s i).miim1__Reset = i.wb_rst_i := by intro s i; rfl

theorem l1_assign_miim1__Reset_CarrierSense_Tx1_preserved : ∀ (s : ethmacState) (i : ethmacInputs), (assign_miim1__Reset s i).CarrierSense_Tx1 = s.CarrierSense_Tx1 := by intro s i; rfl

theorem l1_assign_miim1__Divider_miim1__Divider_semantic : ∀ (s : ethmacState) (i : ethmacInputs), (assign_miim1__Divider s i).miim1__Divider = s.r_ClkDiv := by intro s i; rfl

theorem l1_assign_miim1__Divider_CarrierSense_Tx1_preserved : ∀ (s : ethmacState) (i : ethmacInputs), (assign_miim1__Divider s i).CarrierSense_Tx1 = s.CarrierSense_Tx1 := by intro s i; rfl

theorem l1_assign_miim1__NoPre_miim1__NoPre_semantic : ∀ (s : ethmacState) (i : ethmacInputs), (assign_miim1__NoPre s i).miim1__NoPre = s.r_MiiNoPre := by intro s i; rfl

theorem l1_assign_miim1__NoPre_CarrierSense_Tx1_preserved : ∀ (s : ethmacState) (i : ethmacInputs), (assign_miim1__NoPre s i).CarrierSense_Tx1 = s.CarrierSense_Tx1 := by intro s i; rfl

theorem l1_assign_miim1__CtrlData_miim1__CtrlData_semantic : ∀ (s : ethmacState) (i : ethmacInputs), (assign_miim1__CtrlData s i).miim1__CtrlData = s.r_CtrlData := by intro s i; rfl

theorem l1_assign_miim1__CtrlData_CarrierSense_Tx1_preserved : ∀ (s : ethmacState) (i : ethmacInputs), (assign_miim1__CtrlData s i).CarrierSense_Tx1 = s.CarrierSense_Tx1 := by intro s i; rfl

theorem l1_assign_miim1__Rgad_miim1__Rgad_semantic : ∀ (s : ethmacState) (i : ethmacInputs), (assign_miim1__Rgad s i).miim1__Rgad = s.r_RGAD := by intro s i; rfl

theorem l1_assign_miim1__Rgad_CarrierSense_Tx1_preserved : ∀ (s : ethmacState) (i : ethmacInputs), (assign_miim1__Rgad s i).CarrierSense_Tx1 = s.CarrierSense_Tx1 := by intro s i; rfl

theorem l2_proc_alwaysff_miim1__EndBusy_update : ∀ (s : ethmacState) (i : ethmacInputs), (proc_alwaysff s i).miim1__EndBusy = (if s.miim1__Reset then false else s.miim1__EndBusy_d) := by intro s i; rfl

theorem l2_proc_alwaysff_CarrierSense_Tx1_hold : ∀ (s : ethmacState) (i : ethmacInputs), (proc_alwaysff s i).CarrierSense_Tx1 = s.CarrierSense_Tx1 := by intro s i; rfl

theorem l2_proc_alwaysff_1_miim1__UpdateMIIRX_DATAReg_update : ∀ (s : ethmacState) (i : ethmacInputs), (proc_alwaysff_1 s i).miim1__UpdateMIIRX_DATAReg = (if s.miim1__Reset then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if (s.miim1__EndBusy && !(s.miim1__WCtrlDataStart_q)) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else BitVec.getLsbD (BitVec.ofNat 32 0) 0)) := by intro s i; rfl

theorem l2_proc_alwaysff_1_CarrierSense_Tx1_hold : ∀ (s : ethmacState) (i : ethmacInputs), (proc_alwaysff_1 s i).CarrierSense_Tx1 = s.CarrierSense_Tx1 := by intro s i; rfl

theorem l2_proc_alwaysff_2_miim1__RStat_q1_update : ∀ (s : ethmacState) (i : ethmacInputs), (proc_alwaysff_2 s i).miim1__RStat_q1 = (if s.miim1__Reset then false else s.miim1__RStat) := by intro s i; rfl

theorem l2_proc_alwaysff_2_CarrierSense_Tx1_hold : ∀ (s : ethmacState) (i : ethmacInputs), (proc_alwaysff_2 s i).CarrierSense_Tx1 = s.CarrierSense_Tx1 := by intro s i; rfl

theorem l2_proc_alwaysff_3_miim1__RStatStart_update : ∀ (s : ethmacState) (i : ethmacInputs), (proc_alwaysff_3 s i).miim1__RStatStart = (if s.miim1__Reset then false else (if s.miim1__EndBusy then false else (if (s.miim1__RStat_q2 && !(s.miim1__RStat_q3)) then true else s.miim1__RStatStart))) := by intro s i; rfl

theorem l2_proc_alwaysff_3_CarrierSense_Tx1_hold : ∀ (s : ethmacState) (i : ethmacInputs), (proc_alwaysff_3 s i).CarrierSense_Tx1 = s.CarrierSense_Tx1 := by intro s i; rfl

theorem l2_proc_alwaysff_4_miim1__Nvalid_update : ∀ (s : ethmacState) (i : ethmacInputs), (proc_alwaysff_4 s i).miim1__Nvalid = (if s.miim1__Reset then false else (if (!(s.miim1__InProgress_q2) && s.miim1__InProgress_q3) then false else (if (s.miim1__ScanStat_q2 && !(s.miim1__SyncStatMdcEn)) then true else s.miim1__Nvalid))) := by intro s i; rfl

theorem l2_proc_alwaysff_4_CarrierSense_Tx1_hold : ∀ (s : ethmacState) (i : ethmacInputs), (proc_alwaysff_4 s i).CarrierSense_Tx1 = s.CarrierSense_Tx1 := by intro s i; rfl

theorem l2_proc_alwaysff_5_miim1__InProgress_q1_update : ∀ (s : ethmacState) (i : ethmacInputs), (proc_alwaysff_5 s i).miim1__InProgress_q1 = (if s.miim1__Reset then false else (if s.miim1__MdcEn then s.miim1__InProgress else s.miim1__InProgress_q1)) := by intro s i; rfl

theorem l2_proc_alwaysff_5_CarrierSense_Tx1_hold : ∀ (s : ethmacState) (i : ethmacInputs), (proc_alwaysff_5 s i).CarrierSense_Tx1 = s.CarrierSense_Tx1 := by intro s i; rfl

theorem l2_proc_alwaysff_6_miim1__InProgress_update : ∀ (s : ethmacState) (i : ethmacInputs), (proc_alwaysff_6 s i).miim1__InProgress = (if s.miim1__Reset then false else (if s.miim1__MdcEn then (if s.miim1__StartOp then true else (if s.miim1__EndOp then false else s.miim1__InProgress)) else s.miim1__InProgress)) := by intro s i; rfl

theorem l2_proc_alwaysff_6_CarrierSense_Tx1_hold : ∀ (s : ethmacState) (i : ethmacInputs), (proc_alwaysff_6 s i).CarrierSense_Tx1 = s.CarrierSense_Tx1 := by intro s i; rfl

theorem l2_proc_alwaysff_7_miim1__BitCounter_update : ∀ (s : ethmacState) (i : ethmacInputs), (proc_alwaysff_7 s i).miim1__BitCounter = (if s.miim1__Reset then bvRangeWrite 7 6 0 (s.miim1__BitCounter) (BitVec.ofNat 7 0) else (if s.miim1__MdcEn then (if s.miim1__InProgress then (if (s.miim1__NoPre && decide ((s.miim1__BitCounter).toNat = (BitVec.ofNat 7 0).toNat)) then bvRangeWrite 7 6 0 (s.miim1__BitCounter) (BitVec.ofNat 7 33) else bvRangeWrite 7 6 0 (s.miim1__BitCounter) ((BitVec.extractLsb 6 0 (s.miim1__BitCounter) + BitVec.ofNat 7 1))) else bvRangeWrite 7 6 0 (s.miim1__BitCounter) (BitVec.ofNat 7 0)) else s.miim1__BitCounter)) := by intro s i; rfl

theorem l2_proc_alwaysff_7_CarrierSense_Tx1_hold : ∀ (s : ethmacState) (i : ethmacInputs), (proc_alwaysff_7 s i).CarrierSense_Tx1 = s.CarrierSense_Tx1 := by intro s i; rfl

theorem l2_proc_alwaysff_deterministic : ∀ (s1 s2 : ethmacState) (i : ethmacInputs), s1 = s2 → proc_alwaysff s1 i = proc_alwaysff s2 i := by intro s1 s2 i h; cases h; rfl

theorem l3_step_event_definition : ∀ (s : ethmacState) (i : ethmacInputs) (e : ClockEvent), step s i e = stepEvent s i e := by intro s i e; rfl

theorem l3_step_event_deterministic : ∀ (s1 s2 : ethmacState) (i : ethmacInputs) (e : ClockEvent), s1 = s2 → step s1 i e = step s2 i e := by intro s1 s2 i e h; cases h; rfl

theorem l3_wb_dat_o_output_reflection : ∀ (s : ethmacState) (i : ethmacInputs) (e : ClockEvent) , (outputs (step s i e)).wb_dat_o = (step s i e).wb_dat_o := by intro s i e; rfl

theorem l4_run_nil : ∀ s : ethmacState, run s [] = s := by intro s; rfl

theorem l4_run_cons : ∀ (s : ethmacState) (x : EventInput) (xs : List EventInput), run s (x :: xs) = run (step s x.1 x.2) xs := by intro s x xs; rfl

theorem l4_reachable_init : Reachable init := by exact Reachable.init

theorem l4_reachable_step : ∀ (s : ethmacState), Reachable s → (i : ethmacInputs) → (e : ClockEvent) → Reachable (step s i e) := by intro s h i e; exact Reachable.next h i e

end ethmacVerification
