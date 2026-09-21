import Foundation

set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace picorv32Verification
open picorv32

theorem l1_assign_dbg_mem_valid_dbg_mem_valid_semantic : ∀ (s : picorv32State) (i : picorv32Inputs), (assign_dbg_mem_valid s i).dbg_mem_valid = s.mem_valid := by intro s i; rfl

theorem l1_assign_dbg_mem_valid_alu_out_0_q_preserved : ∀ (s : picorv32State) (i : picorv32Inputs), (assign_dbg_mem_valid s i).alu_out_0_q = s.alu_out_0_q := by intro s i; rfl

theorem l1_assign_dbg_mem_instr_dbg_mem_instr_semantic : ∀ (s : picorv32State) (i : picorv32Inputs), (assign_dbg_mem_instr s i).dbg_mem_instr = s.mem_instr := by intro s i; rfl

theorem l1_assign_dbg_mem_instr_alu_out_0_q_preserved : ∀ (s : picorv32State) (i : picorv32Inputs), (assign_dbg_mem_instr s i).alu_out_0_q = s.alu_out_0_q := by intro s i; rfl

theorem l1_assign_dbg_mem_ready_dbg_mem_ready_semantic : ∀ (s : picorv32State) (i : picorv32Inputs), (assign_dbg_mem_ready s i).dbg_mem_ready = i.mem_ready := by intro s i; rfl

theorem l1_assign_dbg_mem_ready_alu_out_0_q_preserved : ∀ (s : picorv32State) (i : picorv32Inputs), (assign_dbg_mem_ready s i).alu_out_0_q = s.alu_out_0_q := by intro s i; rfl

theorem l1_assign_dbg_mem_addr_dbg_mem_addr_semantic : ∀ (s : picorv32State) (i : picorv32Inputs), (assign_dbg_mem_addr s i).dbg_mem_addr = s.mem_addr := by intro s i; rfl

theorem l1_assign_dbg_mem_addr_alu_out_0_q_preserved : ∀ (s : picorv32State) (i : picorv32Inputs), (assign_dbg_mem_addr s i).alu_out_0_q = s.alu_out_0_q := by intro s i; rfl

theorem l1_assign_dbg_mem_wdata_dbg_mem_wdata_semantic : ∀ (s : picorv32State) (i : picorv32Inputs), (assign_dbg_mem_wdata s i).dbg_mem_wdata = s.mem_wdata := by intro s i; rfl

theorem l1_assign_dbg_mem_wdata_alu_out_0_q_preserved : ∀ (s : picorv32State) (i : picorv32Inputs), (assign_dbg_mem_wdata s i).alu_out_0_q = s.alu_out_0_q := by intro s i; rfl

theorem l1_assign_dbg_mem_wstrb_dbg_mem_wstrb_semantic : ∀ (s : picorv32State) (i : picorv32Inputs), (assign_dbg_mem_wstrb s i).dbg_mem_wstrb = s.mem_wstrb := by intro s i; rfl

theorem l1_assign_dbg_mem_wstrb_alu_out_0_q_preserved : ∀ (s : picorv32State) (i : picorv32Inputs), (assign_dbg_mem_wstrb s i).alu_out_0_q = s.alu_out_0_q := by intro s i; rfl

theorem l2_proc_alwaysff_last_mem_valid_update : ∀ (s : picorv32State) (i : picorv32Inputs), (proc_alwaysff s i).last_mem_valid = (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (s.mem_valid && !(i.mem_ready))) := by intro s i; rfl

theorem l2_proc_alwaysff_alu_out_0_q_hold : ∀ (s : picorv32State) (i : picorv32Inputs), (proc_alwaysff s i).alu_out_0_q = s.alu_out_0_q := by intro s i; rfl

theorem l2_proc_alwaysff_1_mem_rdata_q_update : ∀ (s : picorv32State) (i : picorv32Inputs), (proc_alwaysff_1 s i).mem_rdata_q = (if s.mem_xfer then (if false then s.mem_rdata_latched else i.mem_rdata) else s.mem_rdata_q) := by intro s i; rfl

theorem l2_proc_alwaysff_1_alu_out_0_q_hold : ∀ (s : picorv32State) (i : picorv32Inputs), (proc_alwaysff_1 s i).alu_out_0_q = s.alu_out_0_q := by intro s i; rfl

theorem l2_proc_alwaysff_2_alu_out_0_q_hold : ∀ (s : picorv32State) (i : picorv32Inputs), (proc_alwaysff_2 s i).alu_out_0_q = s.alu_out_0_q := by intro s i; rfl

theorem l2_proc_alwaysff_3_mem_addr_update : ∀ (s : picorv32State) (i : picorv32Inputs), (proc_alwaysff_3 s i).mem_addr = (if (!(i.resetn) || s.trap) then s.mem_addr else (if (s.mem_la_read || s.mem_la_write) then s.mem_la_addr else s.mem_addr)) := by intro s i; rfl

theorem l2_proc_alwaysff_3_alu_out_0_q_hold : ∀ (s : picorv32State) (i : picorv32Inputs), (proc_alwaysff_3 s i).alu_out_0_q = s.alu_out_0_q := by intro s i; rfl

theorem l2_proc_alwaysff_4_cached_ascii_instr_update : ∀ (s : picorv32State) (i : picorv32Inputs), (proc_alwaysff_4 s i).cached_ascii_instr = (if s.decoder_trigger_q then s.new_ascii_instr else s.cached_ascii_instr) := by intro s i; rfl

theorem l2_proc_alwaysff_4_alu_out_0_q_hold : ∀ (s : picorv32State) (i : picorv32Inputs), (proc_alwaysff_4 s i).alu_out_0_q = s.alu_out_0_q := by intro s i; rfl

theorem l2_proc_alwaysff_5_compressed_instr_update : ∀ (s : picorv32State) (i : picorv32Inputs), (proc_alwaysff_5 s i).compressed_instr = (if (s.mem_do_rinst && s.mem_done) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.compressed_instr) := by intro s i; rfl

theorem l2_proc_alwaysff_5_alu_out_0_q_hold : ∀ (s : picorv32State) (i : picorv32Inputs), (proc_alwaysff_5 s i).alu_out_0_q = s.alu_out_0_q := by intro s i; rfl

theorem l2_proc_alwaysff_6_clear_prefetched_high_word_q_update : ∀ (s : picorv32State) (i : picorv32Inputs), (proc_alwaysff_6 s i).clear_prefetched_high_word_q = s.clear_prefetched_high_word := by intro s i; rfl

theorem l2_proc_alwaysff_6_alu_out_0_q_hold : ∀ (s : picorv32State) (i : picorv32Inputs), (proc_alwaysff_6 s i).alu_out_0_q = s.alu_out_0_q := by intro s i; rfl

theorem l2_proc_alwaysff_7_cpuregs_update : ∀ (s : picorv32State) (i : picorv32Inputs), (proc_alwaysff_7 s i).cpuregs = (if ((i.resetn && s.cpuregs_write) && bvNonzero (s.latched_rd)) then bvArrayWrite 32 32 0 31 (s.cpuregs) ((s.latched_rd).toNat) (s.cpuregs_wrdata) else s.cpuregs) := by intro s i; rfl

theorem l2_proc_alwaysff_7_alu_out_0_q_hold : ∀ (s : picorv32State) (i : picorv32Inputs), (proc_alwaysff_7 s i).alu_out_0_q = s.alu_out_0_q := by intro s i; rfl

theorem l2_proc_alwaysff_8_alu_out_0_q_update : ∀ (s : picorv32State) (i : picorv32Inputs), (proc_alwaysff_8 s i).alu_out_0_q = s.alu_out_0 := by intro s i; rfl

theorem l2_proc_alwaysff_8_cached_ascii_instr_hold : ∀ (s : picorv32State) (i : picorv32Inputs), (proc_alwaysff_8 s i).cached_ascii_instr = s.cached_ascii_instr := by intro s i; rfl

theorem l2_proc_alwaysff_deterministic : ∀ (s1 s2 : picorv32State) (i : picorv32Inputs), s1 = s2 → proc_alwaysff s1 i = proc_alwaysff s2 i := by intro s1 s2 i h; cases h; rfl

theorem l3_step_definition : ∀ (s : picorv32State) (i : picorv32Inputs), step s i = comb (commit (comb s i) i) i := by intro s i; rfl

theorem l3_step_deterministic : ∀ (s1 s2 : picorv32State) (i : picorv32Inputs), s1 = s2 → step s1 i = step s2 i := by intro s1 s2 i h; cases h; rfl

theorem l3_trap_output_reflection : ∀ (s : picorv32State) (i : picorv32Inputs) , (outputs (step s i)).trap = (step s i).trap := by intro s i ; rfl

theorem l4_run_nil : ∀ s : picorv32State, run s [] = s := by intro s; rfl

theorem l4_run_cons : ∀ (s : picorv32State) (i : picorv32Inputs) (xs : List picorv32Inputs), run s (i :: xs) = run (step s i) xs := by intro s i xs; rfl

theorem l4_reachable_init : Reachable init := by exact Reachable.init

theorem l4_reachable_step : ∀ (s : picorv32State), Reachable s → (i : picorv32Inputs) → Reachable (step s i) := by intro s h i; exact Reachable.next h i

end picorv32Verification
