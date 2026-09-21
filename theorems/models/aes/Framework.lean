import Foundation

set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace aes_coreVerification
open aes_core

theorem l1_assign_enc_block__clk_enc_block__clk_semantic : ∀ (s : aes_coreState) (i : aes_coreInputs), (assign_enc_block__clk s i).enc_block__clk = i.clk := by intro s i; rfl

theorem l1_assign_enc_block__clk_aes_core_ctrl_reg_preserved : ∀ (s : aes_coreState) (i : aes_coreInputs), (assign_enc_block__clk s i).aes_core_ctrl_reg = s.aes_core_ctrl_reg := by intro s i; rfl

theorem l1_assign_enc_block__reset_n_enc_block__reset_n_semantic : ∀ (s : aes_coreState) (i : aes_coreInputs), (assign_enc_block__reset_n s i).enc_block__reset_n = i.reset_n := by intro s i; rfl

theorem l1_assign_enc_block__reset_n_aes_core_ctrl_reg_preserved : ∀ (s : aes_coreState) (i : aes_coreInputs), (assign_enc_block__reset_n s i).aes_core_ctrl_reg = s.aes_core_ctrl_reg := by intro s i; rfl

theorem l1_assign_enc_block__next_enc_block__next_semantic : ∀ (s : aes_coreState) (i : aes_coreInputs), (assign_enc_block__next s i).enc_block__next = s.enc_next := by intro s i; rfl

theorem l1_assign_enc_block__next_aes_core_ctrl_reg_preserved : ∀ (s : aes_coreState) (i : aes_coreInputs), (assign_enc_block__next s i).aes_core_ctrl_reg = s.aes_core_ctrl_reg := by intro s i; rfl

theorem l1_assign_enc_block__keylen_enc_block__keylen_semantic : ∀ (s : aes_coreState) (i : aes_coreInputs), (assign_enc_block__keylen s i).enc_block__keylen = i.keylen := by intro s i; rfl

theorem l1_assign_enc_block__keylen_aes_core_ctrl_reg_preserved : ∀ (s : aes_coreState) (i : aes_coreInputs), (assign_enc_block__keylen s i).aes_core_ctrl_reg = s.aes_core_ctrl_reg := by intro s i; rfl

theorem l1_assign_enc_round_nr_enc_round_nr_semantic : ∀ (s : aes_coreState) (i : aes_coreInputs), (assign_enc_round_nr s i).enc_round_nr = s.enc_block__round := by intro s i; rfl

theorem l1_assign_enc_round_nr_aes_core_ctrl_reg_preserved : ∀ (s : aes_coreState) (i : aes_coreInputs), (assign_enc_round_nr s i).aes_core_ctrl_reg = s.aes_core_ctrl_reg := by intro s i; rfl

theorem l1_assign_enc_block__round_key_enc_block__round_key_semantic : ∀ (s : aes_coreState) (i : aes_coreInputs), (assign_enc_block__round_key s i).enc_block__round_key = s.round_key := by intro s i; rfl

theorem l1_assign_enc_block__round_key_aes_core_ctrl_reg_preserved : ∀ (s : aes_coreState) (i : aes_coreInputs), (assign_enc_block__round_key s i).aes_core_ctrl_reg = s.aes_core_ctrl_reg := by intro s i; rfl

theorem l2_proc_alwaysff_enc_block__block_w0_reg_update : ∀ (s : aes_coreState) (i : aes_coreInputs), (proc_alwaysff s i).enc_block__block_w0_reg = (if !(s.enc_block__reset_n) then BitVec.ofNat 32 0 else (if s.enc_block__block_w0_we then BitVec.extractLsb 127 96 (s.enc_block__block_new) else s.enc_block__block_w0_reg)) := by intro s i; rfl

theorem l2_proc_alwaysff_aes_core_ctrl_reg_hold : ∀ (s : aes_coreState) (i : aes_coreInputs), (proc_alwaysff s i).aes_core_ctrl_reg = s.aes_core_ctrl_reg := by intro s i; rfl

theorem l2_proc_alwaysff_1_dec_block__block_w0_reg_update : ∀ (s : aes_coreState) (i : aes_coreInputs), (proc_alwaysff_1 s i).dec_block__block_w0_reg = (if !(s.dec_block__reset_n) then BitVec.ofNat 32 0 else (if s.dec_block__block_w0_we then BitVec.extractLsb 127 96 (s.dec_block__block_new) else s.dec_block__block_w0_reg)) := by intro s i; rfl

theorem l2_proc_alwaysff_1_aes_core_ctrl_reg_hold : ∀ (s : aes_coreState) (i : aes_coreInputs), (proc_alwaysff_1 s i).aes_core_ctrl_reg = s.aes_core_ctrl_reg := by intro s i; rfl

theorem l2_proc_alwaysff_2_keymem__key_mem_update : ∀ (s : aes_coreState) (i : aes_coreInputs), (proc_alwaysff_2 s i).keymem__key_mem = (if !(s.keymem__reset_n) then bvArrayWrite 128 15 0 14 (bvArrayWrite 128 15 0 14 (bvArrayWrite 128 15 0 14 (bvArrayWrite 128 15 0 14 (bvArrayWrite 128 15 0 14 (bvArrayWrite 128 15 0 14 (bvArrayWrite 128 15 0 14 (bvArrayWrite 128 15 0 14 (bvArrayWrite 128 15 0 14 (bvArrayWrite 128 15 0 14 (bvArrayWrite 128 15 0 14 (bvArrayWrite 128 15 0 14 (bvArrayWrite 128 15 0 14 (bvArrayWrite 128 15 0 14 (bvArrayWrite 128 15 0 14 (s.keymem__key_mem) ((BitVec.ofNat 32 0).toNat) (BitVec.ofNat 128 0)) ((BitVec.ofNat 32 1).toNat) (BitVec.ofNat 128 0)) ((BitVec.ofNat 32 2).toNat) (BitVec.ofNat 128 0)) ((BitVec.ofNat 32 3).toNat) (BitVec.ofNat 128 0)) ((BitVec.ofNat 32 4).toNat) (BitVec.ofNat 128 0)) ((BitVec.ofNat 32 5).toNat) (BitVec.ofNat 128 0)) ((BitVec.ofNat 32 6).toNat) (BitVec.ofNat 128 0)) ((BitVec.ofNat 32 7).toNat) (BitVec.ofNat 128 0)) ((BitVec.ofNat 32 8).toNat) (BitVec.ofNat 128 0)) ((BitVec.ofNat 32 9).toNat) (BitVec.ofNat 128 0)) ((BitVec.ofNat 32 10).toNat) (BitVec.ofNat 128 0)) ((BitVec.ofNat 32 11).toNat) (BitVec.ofNat 128 0)) ((BitVec.ofNat 32 12).toNat) (BitVec.ofNat 128 0)) ((BitVec.ofNat 32 13).toNat) (BitVec.ofNat 128 0)) ((BitVec.ofNat 32 14).toNat) (BitVec.ofNat 128 0) else (if s.keymem__key_mem_we then bvArrayWrite 128 15 0 14 (s.keymem__key_mem) ((s.keymem__round_ctr_reg).toNat) (s.keymem__key_mem_new) else s.keymem__key_mem)) := by intro s i; rfl

theorem l2_proc_alwaysff_2_aes_core_ctrl_reg_hold : ∀ (s : aes_coreState) (i : aes_coreInputs), (proc_alwaysff_2 s i).aes_core_ctrl_reg = s.aes_core_ctrl_reg := by intro s i; rfl

theorem l2_proc_alwaysff_3_aes_core_ctrl_reg_update : ∀ (s : aes_coreState) (i : aes_coreInputs), (proc_alwaysff_3 s i).aes_core_ctrl_reg = (if !(i.reset_n) then BitVec.ofNat 2 0 else (if s.aes_core_ctrl_we then s.aes_core_ctrl_new else s.aes_core_ctrl_reg)) := by intro s i; rfl

theorem l2_proc_alwaysff_3_dec_block__block_w0_reg_hold : ∀ (s : aes_coreState) (i : aes_coreInputs), (proc_alwaysff_3 s i).dec_block__block_w0_reg = s.dec_block__block_w0_reg := by intro s i; rfl

theorem l2_proc_alwaysff_deterministic : ∀ (s1 s2 : aes_coreState) (i : aes_coreInputs), s1 = s2 → proc_alwaysff s1 i = proc_alwaysff s2 i := by intro s1 s2 i h; cases h; rfl

theorem l3_step_definition : ∀ (s : aes_coreState) (i : aes_coreInputs), step s i = comb (commit (comb s i) i) i := by intro s i; rfl

theorem l3_step_deterministic : ∀ (s1 s2 : aes_coreState) (i : aes_coreInputs), s1 = s2 → step s1 i = step s2 i := by intro s1 s2 i h; cases h; rfl

theorem l3_ready_output_reflection : ∀ (s : aes_coreState) (i : aes_coreInputs) , (outputs (step s i)).ready = (step s i).ready := by intro s i ; rfl

theorem l4_run_nil : ∀ s : aes_coreState, run s [] = s := by intro s; rfl

theorem l4_run_cons : ∀ (s : aes_coreState) (i : aes_coreInputs) (xs : List aes_coreInputs), run s (i :: xs) = run (step s i) xs := by intro s i xs; rfl

theorem l4_reachable_init : Reachable init := by exact Reachable.init

theorem l4_reachable_step : ∀ (s : aes_coreState), Reachable s → (i : aes_coreInputs) → Reachable (step s i) := by intro s h i; exact Reachable.next h i

end aes_coreVerification
