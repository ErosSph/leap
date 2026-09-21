import Foundation

set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace zipcoreVerification
open zipcore

theorem l1_assign_clear_pipeline_clear_pipeline_semantic : ∀ (s : zipcoreState) (i : zipcoreInputs), (assign_clear_pipeline s i).clear_pipeline = s.new_pc := by intro s i; rfl

theorem l1_assign_clear_pipeline_BUSLOCK__r_bus_lock_preserved : ∀ (s : zipcoreState) (i : zipcoreInputs), (assign_clear_pipeline s i).BUSLOCK__r_bus_lock = s.BUSLOCK__r_bus_lock := by intro s i; rfl

theorem l1_assign_div_ce_div_ce_semantic : ∀ (s : zipcoreState) (i : zipcoreInputs), (assign_div_ce s i).div_ce = ((s.op_valid_div && s.adf_ce_unconditional) && s.set_cond) := by intro s i; rfl

theorem l1_assign_div_ce_BUSLOCK__r_bus_lock_preserved : ∀ (s : zipcoreState) (i : zipcoreInputs), (assign_div_ce s i).BUSLOCK__r_bus_lock = s.BUSLOCK__r_bus_lock := by intro s i; rfl

theorem l1_assign_fpu_ce_fpu_ce_semantic : ∀ (s : zipcoreState) (i : zipcoreInputs), (assign_fpu_ce s i).fpu_ce = (((false && s.op_valid_fpu) && s.adf_ce_unconditional) && s.set_cond) := by intro s i; rfl

theorem l1_assign_fpu_ce_BUSLOCK__r_bus_lock_preserved : ∀ (s : zipcoreState) (i : zipcoreInputs), (assign_fpu_ce s i).BUSLOCK__r_bus_lock = s.BUSLOCK__r_bus_lock := by intro s i; rfl

theorem l1_assign_master_ce_master_ce_semantic : ∀ (s : zipcoreState) (i : zipcoreInputs), (assign_master_ce s i).master_ce = ((((!(i.i_halt) || s.alu_phase) && !(s.cc_write_hold)) && !(s.o_break)) && !(s.sleep)) := by intro s i; rfl

theorem l1_assign_master_ce_BUSLOCK__r_bus_lock_preserved : ∀ (s : zipcoreState) (i : zipcoreInputs), (assign_master_ce s i).BUSLOCK__r_bus_lock = s.BUSLOCK__r_bus_lock := by intro s i; rfl

theorem l1_assign_cc_invalid_for_dcd_cc_invalid_for_dcd_semantic : ∀ (s : zipcoreState) (i : zipcoreInputs), (assign_cc_invalid_for_dcd s i).cc_invalid_for_dcd = s.GEN_OP_STALL__r_cc_invalid_for_dcd := by intro s i; rfl

theorem l1_assign_cc_invalid_for_dcd_BUSLOCK__r_bus_lock_preserved : ∀ (s : zipcoreState) (i : zipcoreInputs), (assign_cc_invalid_for_dcd s i).BUSLOCK__r_bus_lock = s.BUSLOCK__r_bus_lock := by intro s i; rfl

theorem l1_assign_pending_sreg_write_pending_sreg_write_semantic : ∀ (s : zipcoreState) (i : zipcoreInputs), (assign_pending_sreg_write s i).pending_sreg_write = s.GEN_OP_STALL__r_pending_sreg_write := by intro s i; rfl

theorem l1_assign_pending_sreg_write_BUSLOCK__r_bus_lock_preserved : ∀ (s : zipcoreState) (i : zipcoreInputs), (assign_pending_sreg_write s i).BUSLOCK__r_bus_lock = s.BUSLOCK__r_bus_lock := by intro s i; rfl

theorem l2_proc_alwaysff_GEN_OP_STALL__r_cc_invalid_for_dcd_update : ∀ (s : zipcoreState) (i : zipcoreInputs), (proc_alwaysff s i).GEN_OP_STALL__r_cc_invalid_for_dcd = (if s.clear_pipeline then false else (if ((((s.alu_ce || s.mem_ce) && s.set_cond) && s.op_valid) && (s.op_wF || (s.op_wR && decide ((BitVec.extractLsb 4 0 (s.op_R)).toNat = (BitVec.append (n := 1) (m := 4) (boolToBitVec (s.op_gie)) (BitVec.ofNat 4 14)).toNat)))) then true else (if s.GEN_OP_STALL__r_cc_invalid_for_dcd then (((s.alu_busy || i.i_mem_rdbusy) || s.div_busy) || s.fpu_busy) else false))) := by intro s i; rfl

theorem l2_proc_alwaysff_BUSLOCK__r_bus_lock_hold : ∀ (s : zipcoreState) (i : zipcoreInputs), (proc_alwaysff s i).BUSLOCK__r_bus_lock = s.BUSLOCK__r_bus_lock := by intro s i; rfl

theorem l2_proc_alwaysff_1_GEN_OP_STALL__r_pending_sreg_write_update : ∀ (s : zipcoreState) (i : zipcoreInputs), (proc_alwaysff_1 s i).GEN_OP_STALL__r_pending_sreg_write = (if s.clear_pipeline then false else (if ((((((s.adf_ce_unconditional || s.mem_ce) && s.set_cond) && !(s.op_illegal)) && s.op_wR) && decide ((BitVec.extractLsb 3 1 (s.op_R)).toNat = (BitVec.ofNat 3 7).toNat)) && decide ((BitVec.extractLsb 4 0 (s.op_R)).toNat ≠ (BitVec.append (n := 1) (m := 4) (boolToBitVec (s.gie)) (BitVec.ofNat 4 15)).toNat)) then true else (if (!(i.i_mem_rdbusy) && !(s.alu_busy)) then false else s.GEN_OP_STALL__r_pending_sreg_write))) := by intro s i; rfl

theorem l2_proc_alwaysff_1_BUSLOCK__r_bus_lock_hold : ∀ (s : zipcoreState) (i : zipcoreInputs), (proc_alwaysff_1 s i).BUSLOCK__r_bus_lock = s.BUSLOCK__r_bus_lock := by intro s i; rfl

theorem l2_proc_alwaysff_2_instruction_decoder__GEN_CIS_PHASE__r_phase_update : ∀ (s : zipcoreState) (i : zipcoreInputs), (proc_alwaysff_2 s i).instruction_decoder__GEN_CIS_PHASE__r_phase = (if (s.instruction_decoder__i_reset || s.instruction_decoder__w_ljmp_dly) then false else (if (s.instruction_decoder__i_ce && s.instruction_decoder__pf_valid) then (if s.instruction_decoder__o_phase then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (BitVec.getLsbD (s.instruction_decoder__i_instruction) 31 && !(s.instruction_decoder__i_illegal))) else (if s.instruction_decoder__i_ce then false else s.instruction_decoder__GEN_CIS_PHASE__r_phase))) := by intro s i; rfl

theorem l2_proc_alwaysff_2_BUSLOCK__r_bus_lock_hold : ∀ (s : zipcoreState) (i : zipcoreInputs), (proc_alwaysff_2 s i).BUSLOCK__r_bus_lock = s.BUSLOCK__r_bus_lock := by intro s i; rfl

theorem l2_proc_alwaysff_3_instruction_decoder__o_illegal_update : ∀ (s : zipcoreState) (i : zipcoreInputs), (proc_alwaysff_3 s i).instruction_decoder__o_illegal = (if s.instruction_decoder__i_reset then false else (if (s.instruction_decoder__i_ce && s.instruction_decoder__o_phase) then s.instruction_decoder__o_illegal else (if (s.instruction_decoder__i_ce && s.instruction_decoder__i_pf_valid) then (if s.instruction_decoder__i_illegal then true else (if (decide ((BitVec.extractLsb 3 1 (s.instruction_decoder__w_dcdR)).toNat = (BitVec.ofNat 3 7).toNat) && decide ((BitVec.extractLsb 4 1 (s.instruction_decoder__w_cis_op)).toNat = (BitVec.ofNat 4 13).toNat)) then true else (if (!(false) && s.instruction_decoder__w_sim) then true else (if (!(false) && s.instruction_decoder__w_fpu) then true else (if ((true && s.instruction_decoder__w_div) && decide ((BitVec.extractLsb 3 1 (s.instruction_decoder__w_dcdR)).toNat = (BitVec.ofNat 3 7).toNat)) then true else (if (!(false) && s.instruction_decoder__w_mpy) then true else (if s.instruction_decoder__illegal_shift then true else false))))))) else s.instruction_decoder__o_illegal))) := by intro s i; rfl

theorem l2_proc_alwaysff_3_BUSLOCK__r_bus_lock_hold : ∀ (s : zipcoreState) (i : zipcoreInputs), (proc_alwaysff_3 s i).BUSLOCK__r_bus_lock = s.BUSLOCK__r_bus_lock := by intro s i; rfl

theorem l2_proc_alwaysff_4_instruction_decoder__o_pc_update : ∀ (s : zipcoreState) (i : zipcoreInputs), (proc_alwaysff_4 s i).instruction_decoder__o_pc = (if (s.instruction_decoder__i_ce && (s.instruction_decoder__o_phase || s.instruction_decoder__i_pf_valid)) then (if BitVec.getLsbD (s.instruction_decoder__iword) 31 then (if s.instruction_decoder__o_phase then bvRangeWrite 32 31 1 (bvBitWrite 32 (s.instruction_decoder__o_pc) ((BitVec.ofNat 32 0).toNat) (false)) ((BitVec.extractLsb 31 1 (s.instruction_decoder__o_pc) + BitVec.ofNat 31 1)) else BitVec.append (n := 30) (m := 2) (BitVec.extractLsb 31 2 (s.instruction_decoder__i_pc)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (true)) (boolToBitVec (false)))) else BitVec.append (n := 30) (m := 2) ((BitVec.extractLsb 31 2 (s.instruction_decoder__i_pc) + BitVec.ofNat 30 1)) (BitVec.ofNat 2 0)) else s.instruction_decoder__o_pc) := by intro s i; rfl

theorem l2_proc_alwaysff_4_BUSLOCK__r_bus_lock_hold : ∀ (s : zipcoreState) (i : zipcoreInputs), (proc_alwaysff_4 s i).BUSLOCK__r_bus_lock = s.BUSLOCK__r_bus_lock := by intro s i; rfl

theorem l2_proc_alwaysff_5_instruction_decoder__o_ALU_update : ∀ (s : zipcoreState) (i : zipcoreInputs), (proc_alwaysff_5 s i).instruction_decoder__o_ALU = (if s.instruction_decoder__i_ce then ((((s.instruction_decoder__w_ALU || s.instruction_decoder__w_ldi) || s.instruction_decoder__w_cmptst) || s.instruction_decoder__w_noop) || (!(true) && s.instruction_decoder__w_lock)) else s.instruction_decoder__o_ALU) := by intro s i; rfl

theorem l2_proc_alwaysff_5_BUSLOCK__r_bus_lock_hold : ∀ (s : zipcoreState) (i : zipcoreInputs), (proc_alwaysff_5 s i).BUSLOCK__r_bus_lock = s.BUSLOCK__r_bus_lock := by intro s i; rfl

theorem l2_proc_alwaysff_6_instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_ljmp_update : ∀ (s : zipcoreState) (i : zipcoreInputs), (proc_alwaysff_6 s i).instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_ljmp = (if s.instruction_decoder__i_reset then false else (if s.instruction_decoder__i_ce then (if (s.instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_ljmp && s.instruction_decoder__pf_valid) then false else (if s.instruction_decoder__o_early_branch_stb then false else (if s.instruction_decoder__pf_valid then (if (true && BitVec.getLsbD (s.instruction_decoder__iword) 31) then s.instruction_decoder__w_cis_ljmp else s.instruction_decoder__w_ljmp) else (if ((true && s.instruction_decoder__o_phase) && BitVec.getLsbD (s.instruction_decoder__iword) 31) then s.instruction_decoder__w_cis_ljmp else s.instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_ljmp)))) else s.instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_ljmp)) := by intro s i; rfl

theorem l2_proc_alwaysff_6_BUSLOCK__r_bus_lock_hold : ∀ (s : zipcoreState) (i : zipcoreInputs), (proc_alwaysff_6 s i).BUSLOCK__r_bus_lock = s.BUSLOCK__r_bus_lock := by intro s i; rfl

theorem l2_proc_alwaysff_7_instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_early_branch_update : ∀ (s : zipcoreState) (i : zipcoreInputs), (proc_alwaysff_7 s i).instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_early_branch = (if s.instruction_decoder__i_reset then false else (if (s.instruction_decoder__i_ce && s.instruction_decoder__pf_valid) then (if s.instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_ljmp then true else (if s.instruction_decoder__GEN_EARLY_BRANCH_LOGIC__w_add_to_pc then true else false)) else (if s.instruction_decoder__i_ce then false else s.instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_early_branch))) := by intro s i; rfl

theorem l2_proc_alwaysff_7_BUSLOCK__r_bus_lock_hold : ∀ (s : zipcoreState) (i : zipcoreInputs), (proc_alwaysff_7 s i).BUSLOCK__r_bus_lock = s.BUSLOCK__r_bus_lock := by intro s i; rfl

theorem l2_proc_alwaysff_deterministic : ∀ (s1 s2 : zipcoreState) (i : zipcoreInputs), s1 = s2 → proc_alwaysff s1 i = proc_alwaysff s2 i := by intro s1 s2 i h; cases h; rfl

theorem l3_step_definition : ∀ (s : zipcoreState) (i : zipcoreInputs), step s i = comb (commit (comb s i) i) i := by intro s i; rfl

theorem l3_step_deterministic : ∀ (s1 s2 : zipcoreState) (i : zipcoreInputs), s1 = s2 → step s1 i = step s2 i := by intro s1 s2 i h; cases h; rfl

theorem l3_o_clken_output_reflection : ∀ (s : zipcoreState) (i : zipcoreInputs) , (outputs (step s i)).o_clken = (step s i).o_clken := by intro s i ; rfl

theorem l4_run_nil : ∀ s : zipcoreState, run s [] = s := by intro s; rfl

theorem l4_run_cons : ∀ (s : zipcoreState) (i : zipcoreInputs) (xs : List zipcoreInputs), run s (i :: xs) = run (step s i) xs := by intro s i xs; rfl

theorem l4_reachable_init : Reachable init := by exact Reachable.init

theorem l4_reachable_step : ∀ (s : zipcoreState), Reachable s → (i : zipcoreInputs) → Reachable (step s i) := by intro s h i; exact Reachable.next h i

end zipcoreVerification
