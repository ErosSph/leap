/-
自动生成的 Lean 4 代码
源模块：zipcore
生成时间：Lean 4 RTL 编译器
-/

import Std
set_option linter.unusedVariables false
set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace zipcore

-- 类型定义与 SystemVerilog 位向量辅助函数
def boolToNat (value : Bool) : Nat := if value then 1 else 0
def boolToBitVec (value : Bool) : BitVec 1 := BitVec.ofNat 1 (boolToNat value)
def bitVecToBool (value : BitVec 1) : Bool := BitVec.getLsbD value 0
def bvNonzero {width : Nat} (value : BitVec width) : Bool := value != 0
def bvReduceAnd {width : Nat} (value : BitVec width) : Bool := value == ~~~(0 : BitVec width)
def bvReduceXor {width : Nat} (value : BitVec width) : Bool :=
  (List.range width).foldl (fun acc index => Bool.xor acc (BitVec.getLsbD value index)) false
def arrayOffset (left right index : Nat) : Nat :=
  if left <= right then index - left else left - index
def bvArrayRead (elementWidth depth left right : Nat)
  (memory : BitVec (elementWidth * depth)) (index : Nat) : BitVec elementWidth :=
    BitVec.extractLsb' (arrayOffset left right index * elementWidth) elementWidth memory
def bvArrayWrite (elementWidth depth left right : Nat)
  (memory : BitVec (elementWidth * depth)) (index : Nat)
  (value : BitVec elementWidth) : BitVec (elementWidth * depth) :=
    let shift := arrayOffset left right index * elementWidth
    let wideValue := BitVec.setWidth (elementWidth * depth) value
    let elementMask : BitVec elementWidth := ~~~(0 : BitVec elementWidth)
    let wideMask := BitVec.setWidth (elementWidth * depth) elementMask
    (memory &&& ~~~(BitVec.shiftLeft wideMask shift)) |||
      BitVec.shiftLeft wideValue shift
def bvBitWrite (width : Nat) (base : BitVec width) (index : Nat)
  (value : Bool) : BitVec width :=
    let mask := BitVec.shiftLeft (BitVec.ofNat width 1) index
    if value then base ||| mask else base &&& ~~~mask
def bvRangeWrite (width hi lo : Nat) (base : BitVec width)
  (value : BitVec (hi - lo + 1)) : BitVec width :=
    let wideValue := BitVec.setWidth width value
    let sliceMask : BitVec (hi - lo + 1) := ~~~(0 : BitVec (hi - lo + 1))
    let wideMask := BitVec.setWidth width sliceMask
    (base &&& ~~~(BitVec.shiftLeft wideMask lo)) |||
      BitVec.shiftLeft wideValue lo

structure zipcoreStateBlock0 where
  BUSLOCK__r_bus_lock : BitVec 2
  BUSLOCK__r_lock_pc : BitVec 32
  BUSLOCK__r_prelock_stall : Bool
  CLEAR_DCACHE__r_clear_dcache : Bool
  DIVERR__USER_DIVERR__r_udiv_err_flag : Bool
  DIVERR__r_idiv_err_flag : Bool
  DIVIDE__thedivide__last_bit : Bool
  DIVIDE__thedivide__o_busy : Bool
  DIVIDE__thedivide__o_err : Bool
  DIVIDE__thedivide__o_quotient : BitVec 32
  DIVIDE__thedivide__o_valid : Bool
  DIVIDE__thedivide__pre_sign : Bool
  DIVIDE__thedivide__r_bit : BitVec 5
  DIVIDE__thedivide__r_busy : Bool
  DIVIDE__thedivide__r_c : Bool
  DIVIDE__thedivide__r_dividend : BitVec 63
  DIVIDE__thedivide__r_divisor : BitVec 32
  DIVIDE__thedivide__r_sign : Bool
  DIVIDE__thedivide__r_z : Bool
  DIVIDE__thedivide__zero_divisor : Bool
  FWD_OPERATION__r_op_opn : BitVec 4
  GEN_ALU_PC__r_alu_pc : BitVec 32
  GEN_ALU_PHASE__r_alu_phase : Bool
  GEN_CLOCK_GATE__r_clken : Bool
  GEN_IHALT_PHASE__r_ihalt_phase : Bool
  GEN_OPLOCK__r_op_lock : Bool
  GEN_OP_PIPE__r_op_pipe : Bool
  GEN_OP_STALL__r_cc_invalid_for_dcd : Bool
  GEN_OP_STALL__r_pending_sreg_write : Bool
  GEN_OP_WR__r_op_wR : Bool
  GEN_PENDING_BREAK__r_break_pending : Bool
  GEN_PENDING_INTERRUPT__r_pending_interrupt : Bool
  GEN_PENDING_INTERRUPT__r_user_stepped : Bool
  GEN_UHALT_PHASE__r_uhalt_phase : Bool
  OPT_CIS_OP_PHASE__r_op_phase : Bool
  OP_REG_ADVANEC__r_op_Aid : BitVec 5
  OP_REG_ADVANEC__r_op_Bid : BitVec 5
  OP_REG_ADVANEC__r_op_R : BitVec 5
  OP_REG_ADVANEC__r_op_rA : Bool
  OP_REG_ADVANEC__r_op_rB : Bool
  SETDBG__r_dbg_reg : BitVec 32
  SET_ALU_ILLEGAL__r_alu_illegal : Bool
  SET_GIE__r_gie : Bool
  SET_OP_PC__r_op_pc : BitVec 32
  SET_TRAP_N_UBREAK__r_trap : Bool
  SET_TRAP_N_UBREAK__r_ubreak : Bool
  SET_USER_BUSERR__r_ubus_err_flag : Bool
  SET_USER_ILLEGAL_INSN__r_ill_err_u : Bool
  SET_USER_PC__r_upc : BitVec 32
  alu_reg : BitVec 5
  alu_wF : Bool
  alu_wR : Bool
  break_en : Bool
  dbg_clear_pipe : Bool
  dbg_val : BitVec 32
  dbgv : Bool
  doalu__c : Bool
  doalu__keep_sgn_on_ovfl : Bool
  doalu__o_c : BitVec 32
  doalu__o_valid : Bool
  doalu__pre_sign : Bool
  doalu__r_busy : Bool
  doalu__set_ovfl : Bool
  flags : BitVec 4

structure zipcoreStateBlock1 where
  ibus_err_flag : Bool
  iflags : BitVec 4
  ill_err_i : Bool
  instruction_decoder__GEN_CIS_PHASE__r_phase : Bool
  instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_branch_pc : BitVec 32
  instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_early_branch : Bool
  instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_early_branch_stb : Bool
  instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_ljmp : Bool
  instruction_decoder__GEN_OPIPE__r_insn_is_pipeable : Bool
  instruction_decoder__GEN_OPIPE__r_pipe : Bool
  instruction_decoder__o_ALU : Bool
  instruction_decoder__o_DV : Bool
  instruction_decoder__o_FP : Bool
  instruction_decoder__o_M : Bool
  instruction_decoder__o_break : Bool
  instruction_decoder__o_cond : BitVec 4
  instruction_decoder__o_dcdA : BitVec 7
  instruction_decoder__o_dcdB : BitVec 7
  instruction_decoder__o_dcdR : BitVec 7
  instruction_decoder__o_illegal : Bool
  instruction_decoder__o_lock : Bool
  instruction_decoder__o_op : BitVec 4
  instruction_decoder__o_pc : BitVec 32
  instruction_decoder__o_rA : Bool
  instruction_decoder__o_rB : Bool
  instruction_decoder__o_sim : Bool
  instruction_decoder__o_sim_immv : BitVec 23
  instruction_decoder__o_wF : Bool
  instruction_decoder__o_wR : Bool
  instruction_decoder__o_zI : Bool
  instruction_decoder__r_I : BitVec 23
  instruction_decoder__r_nxt_half : BitVec 15
  instruction_decoder__r_valid : Bool
  ipc : BitVec 32
  last_write_to_cc : Bool
  mem_pc_valid : Bool
  new_pc : Bool
  o_dbg_cc : BitVec 3
  op_Rcc : Bool
  op_illegal : Bool
  op_valid : Bool
  op_valid_alu : Bool
  op_valid_div : Bool
  op_valid_fpu : Bool
  op_valid_mem : Bool
  op_wF : Bool
  pf_pc : BitVec 32
  r_alu_pc_valid : Bool
  r_clear_icache : Bool
  r_dbg_stall : Bool
  r_halted : Bool
  r_op_Av : BitVec 32
  r_op_Bv : BitVec 32
  r_op_F : BitVec 7
  r_op_break : Bool
  regset : BitVec 1024
  sleep : Bool
  user_step : Bool
  wr_index : BitVec 3
  w_uflags : BitVec 16
  w_iflags : BitVec 16
  break_pending : Bool
  trap : Bool
  gie : Bool

structure zipcoreStateBlock2 where
  ubreak : Bool
  pending_interrupt : Bool
  stepped : Bool
  step : Bool
  ill_err_u : Bool
  ubus_err_flag : Bool
  idiv_err_flag : Bool
  udiv_err_flag : Bool
  ifpu_err_flag : Bool
  ufpu_err_flag : Bool
  ihalt_phase : Bool
  uhalt_phase : Bool
  master_ce : Bool
  master_stall : Bool
  clear_pipeline : Bool
  pf_gie : Bool
  dcd_opn : BitVec 4
  dcd_ce : Bool
  dcd_phase : Bool
  dcd_A : BitVec 5
  dcd_B : BitVec 5
  dcd_R : BitVec 5
  dcd_preA : BitVec 5
  dcd_preB : BitVec 5
  dcd_Acc : Bool
  dcd_Bcc : Bool
  dcd_Apc : Bool
  dcd_Bpc : Bool
  dcd_Rcc : Bool
  dcd_Rpc : Bool
  dcd_F : BitVec 4
  dcd_wR : Bool
  dcd_rA : Bool
  dcd_rB : Bool
  dcd_ALU : Bool
  dcd_M : Bool
  dcd_DIV : Bool
  dcd_FP : Bool
  dcd_wF : Bool
  dcd_gie : Bool
  dcd_break : Bool
  dcd_lock : Bool
  dcd_pipe : Bool
  dcd_ljmp : Bool
  dcd_valid : Bool
  dcd_pc : BitVec 32
  dcd_I : BitVec 32
  dcd_zI : Bool
  dcd_A_stall : Bool
  dcd_B_stall : Bool
  dcd_F_stall : Bool
  dcd_illegal : Bool
  dcd_early_branch : Bool
  dcd_early_branch_stb : Bool
  dcd_branch_pc : BitVec 32
  dcd_sim : Bool
  dcd_sim_immv : BitVec 23
  prelock_stall : Bool
  last_lock_insn : Bool
  cc_invalid_for_dcd : Bool
  pending_sreg_write : Bool
  op_stall : Bool
  op_opn : BitVec 4
  op_R : BitVec 5

structure zipcoreStateBlock3 where
  op_Aid : BitVec 5
  op_Bid : BitVec 5
  op_rA : Bool
  op_rB : Bool
  op_pc : BitVec 32
  w_op_Av : BitVec 32
  w_op_Bv : BitVec 32
  op_Av : BitVec 32
  op_Bv : BitVec 32
  op_wR : Bool
  op_gie : Bool
  op_Fl : BitVec 4
  op_F : BitVec 8
  op_ce : Bool
  op_phase : Bool
  op_pipe : Bool
  w_op_valid : Bool
  op_lowpower_clear : Bool
  w_cpu_info : BitVec 9
  op_break : Bool
  op_lock : Bool
  op_sim : Bool
  op_sim_immv : BitVec 23
  alu_sim : Bool
  alu_sim_immv : BitVec 23
  alu_pc : BitVec 32
  alu_pc_valid : Bool
  alu_phase : Bool
  alu_ce : Bool
  alu_stall : Bool
  alu_result : BitVec 32
  alu_flags : BitVec 4
  alu_valid : Bool
  alu_busy : Bool
  set_cond : Bool
  alu_gie : Bool
  alu_illegal : Bool
  mem_ce : Bool
  mem_stalled : Bool
  div_ce : Bool
  div_error : Bool
  div_busy : Bool
  div_valid : Bool
  div_result : BitVec 32
  div_flags : BitVec 4
  fpu_ce : Bool
  fpu_error : Bool
  fpu_busy : Bool
  fpu_valid : Bool
  fpu_result : BitVec 32
  fpu_flags : BitVec 4
  wr_write_pc : Bool
  wr_write_cc : Bool
  wr_write_scc : Bool
  wr_write_ucc : Bool
  wr_reg_id : BitVec 5
  w_switch_to_interrupt : Bool
  w_release_from_interrupt : Bool
  upc : BitVec 32
  cc_write_hold : Bool
  w_clken : Bool
  GEN_ALU_STALL__unused_alu_stall : Bool
  dcd_full_R : BitVec 7
  dcd_full_A : BitVec 7

structure zipcoreStateBlock4 where
  dcd_full_B : BitVec 7
  instruction_decoder__i_clk : Bool
  instruction_decoder__i_reset : Bool
  instruction_decoder__i_ce : Bool
  instruction_decoder__i_stalled : Bool
  instruction_decoder__i_instruction : BitVec 32
  instruction_decoder__i_gie : Bool
  instruction_decoder__i_pc : BitVec 32
  instruction_decoder__i_pf_valid : Bool
  instruction_decoder__i_illegal : Bool
  instruction_decoder__o_valid : Bool
  instruction_decoder__o_phase : Bool
  instruction_decoder__o_preA : BitVec 5
  instruction_decoder__o_preB : BitVec 5
  instruction_decoder__o_I : BitVec 32
  instruction_decoder__o_early_branch : Bool
  instruction_decoder__o_early_branch_stb : Bool
  instruction_decoder__o_branch_pc : BitVec 32
  instruction_decoder__o_ljmp : Bool
  instruction_decoder__o_pipe : Bool
  instruction_decoder__w_op : BitVec 5
  instruction_decoder__w_ldi : Bool
  instruction_decoder__w_mov : Bool
  instruction_decoder__w_cmptst : Bool
  instruction_decoder__w_ldilo : Bool
  instruction_decoder__w_ALU : Bool
  instruction_decoder__w_brev : Bool
  instruction_decoder__w_noop : Bool
  instruction_decoder__w_lock : Bool
  instruction_decoder__w_sim : Bool
  instruction_decoder__w_break : Bool
  instruction_decoder__w_special : Bool
  instruction_decoder__w_add : Bool
  instruction_decoder__w_mpy : Bool
  instruction_decoder__w_dcdR : BitVec 5
  instruction_decoder__w_dcdB : BitVec 5
  instruction_decoder__w_dcdA : BitVec 5
  instruction_decoder__w_dcdR_pc : Bool
  instruction_decoder__w_dcdR_cc : Bool
  instruction_decoder__w_dcdA_pc : Bool
  instruction_decoder__w_dcdA_cc : Bool
  instruction_decoder__w_dcdB_pc : Bool
  instruction_decoder__w_dcdB_cc : Bool
  instruction_decoder__w_cond : BitVec 4
  instruction_decoder__w_wF : Bool
  instruction_decoder__w_mem : Bool
  instruction_decoder__w_sto : Bool
  instruction_decoder__w_div : Bool
  instruction_decoder__w_fpu : Bool
  instruction_decoder__w_wR : Bool
  instruction_decoder__w_rA : Bool
  instruction_decoder__w_rB : Bool
  instruction_decoder__w_wR_n : Bool
  instruction_decoder__w_ljmp : Bool
  instruction_decoder__w_ljmp_dly : Bool
  instruction_decoder__w_cis_ljmp : Bool
  instruction_decoder__iword : BitVec 32
  instruction_decoder__pf_valid : Bool
  instruction_decoder__w_I : BitVec 23
  instruction_decoder__w_Iz : Bool
  instruction_decoder__insn_is_pipeable : Bool
  instruction_decoder__illegal_shift : Bool
  instruction_decoder__GEN_CIS_IMMEDIATE__w_halfI : BitVec 8
  instruction_decoder__GEN_CIS_IMMEDIATE__w_halfbits : BitVec 8

structure zipcoreStateBlock5 where
  instruction_decoder__GEN_EARLY_BRANCH_LOGIC__w_add_to_pc : Bool
  instruction_decoder__possibly_unused : Bool
  GEN_DISTRIBUTED_REGS__unused_prereg_addrs : Bool
  NO_OP_SIM__op_sim_unused : Bool
  doalu__i_clk : Bool
  doalu__i_reset : Bool
  doalu__i_stb : Bool
  doalu__i_op : BitVec 4
  doalu__i_a : BitVec 32
  doalu__i_b : BitVec 32
  doalu__o_f : BitVec 4
  doalu__o_busy : Bool
  doalu__w_brev_result : BitVec 32
  doalu__z : Bool
  doalu__n : Bool
  doalu__v : Bool
  doalu__vx : Bool
  doalu__w_lsr_result : BitVec 33
  doalu__w_asr_result : BitVec 33
  doalu__w_lsl_result : BitVec 33
  doalu__mpy_result : BitVec 64
  doalu__mpyhi : Bool
  doalu__mpybusy : Bool
  doalu__mpydone : Bool
  doalu__this_is_a_multiply_op : Bool
  doalu__IMPLEMENT_SHIFTS__w_pre_asr_input : BitVec 33
  doalu__IMPLEMENT_SHIFTS__w_pre_asr_shifted : BitVec 33
  doalu__thempy__i_clk : Bool
  doalu__thempy__i_reset : Bool
  doalu__thempy__i_stb : Bool
  doalu__thempy__i_op : BitVec 2
  doalu__thempy__i_a : BitVec 32
  doalu__thempy__i_b : BitVec 32
  doalu__thempy__o_valid : Bool
  doalu__thempy__o_busy : Bool
  doalu__thempy__o_result : BitVec 64
  doalu__thempy__o_hi : Bool
  DIVIDE__thedivide__i_clk : Bool
  DIVIDE__thedivide__i_reset : Bool
  DIVIDE__thedivide__i_wr : Bool
  DIVIDE__thedivide__i_signed : Bool
  DIVIDE__thedivide__i_numerator : BitVec 32
  DIVIDE__thedivide__i_denominator : BitVec 32
  DIVIDE__thedivide__o_flags : BitVec 4
  DIVIDE__thedivide__diff : BitVec 33
  DIVIDE__thedivide__w_n : Bool
  cpu_sim : Bool
  unused : Bool
  o_clken : Bool
  o_dbg_stall : Bool
  o_dbg_reg : BitVec 32
  o_break : Bool
  o_pf_new_pc : Bool
  o_clear_icache : Bool
  o_pf_ready : Bool
  o_pf_request_address : BitVec 32
  o_clear_dcache : Bool
  o_mem_ce : Bool
  o_bus_lock : Bool
  o_mem_op : BitVec 3
  o_mem_addr : BitVec 32
  o_mem_data : BitVec 32
  o_mem_lock_pc : BitVec 32
  o_mem_reg : BitVec 5

structure zipcoreStateBlock6 where
  o_op_stall : Bool
  o_pf_stall : Bool
  o_i_count : Bool
  o_debug : BitVec 32
  o_prof_stb : Bool
  o_prof_addr : BitVec 32
  o_prof_ticks : BitVec 32
  SETDBG__pre_dbg_reg : BitVec 32
  adf_ce_unconditional : Bool
  avsrc : BitVec 3
  bisrc : BitVec 2
  bvsrc : BitVec 3
  dcd_stalled : Bool
  debug_pc : BitVec 32
  instruction_decoder__w_cis_op : BitVec 5
  instruction_decoder__w_fullI : BitVec 23
  instruction_decoder__w_immsrc : BitVec 2
  pfpcset : Bool
  pfpcsrc : BitVec 3
  w_op_BnI : BitVec 32
  w_pcA_v : BitVec 32
  w_pcB_v : BitVec 32
  wr_flags : BitVec 4
  wr_flags_ce : Bool
  wr_gpreg_vl : BitVec 32
  wr_reg_ce : Bool
  wr_spreg_vl : BitVec 32

/-- zipcore 状态结构（保留全部字段的嵌套具体记录） -/
structure zipcoreState extends zipcoreStateBlock0, zipcoreStateBlock1, zipcoreStateBlock2, zipcoreStateBlock3, zipcoreStateBlock4, zipcoreStateBlock5, zipcoreStateBlock6 where

/-- zipcore 输入信号 -/
structure zipcoreInputs where
  i_clk : Bool
  i_reset : Bool
  i_interrupt : Bool
  i_halt : Bool
  i_clear_cache : Bool
  i_dbg_wreg : BitVec 5
  i_dbg_we : Bool
  i_dbg_data : BitVec 32
  i_dbg_rreg : BitVec 5
  i_pf_valid : Bool
  i_pf_illegal : Bool
  i_pf_instruction : BitVec 32
  i_pf_instruction_pc : BitVec 32
  i_mem_busy : Bool
  i_mem_rdbusy : Bool
  i_mem_pipe_stalled : Bool
  i_mem_valid : Bool
  i_bus_err : Bool
  i_mem_wreg : BitVec 5
  i_mem_result : BitVec 32
  __rtl_nondet_0000 : BitVec 2
  __rtl_nondet_0001 : BitVec 3
  __rtl_nondet_0002 : BitVec 3

/-- zipcore 输出信号 -/
structure zipcoreOutputs where
  o_clken : Bool
  o_dbg_stall : Bool
  o_dbg_reg : BitVec 32
  o_dbg_cc : BitVec 3
  o_break : Bool
  o_pf_new_pc : Bool
  o_clear_icache : Bool
  o_pf_ready : Bool
  o_pf_request_address : BitVec 32
  o_clear_dcache : Bool
  o_mem_ce : Bool
  o_bus_lock : Bool
  o_mem_op : BitVec 3
  o_mem_addr : BitVec 32
  o_mem_data : BitVec 32
  o_mem_lock_pc : BitVec 32
  o_mem_reg : BitVec 5
  o_op_stall : Bool
  o_pf_stall : Bool
  o_i_count : Bool
  o_debug : BitVec 32
  o_prof_stb : Bool
  o_prof_addr : BitVec 32
  o_prof_ticks : BitVec 32

/-- zipcore 初始状态 -/
def init : zipcoreState where
  BUSLOCK__r_bus_lock := BitVec.ofNat 2 0
  BUSLOCK__r_lock_pc := BitVec.ofNat 32 0
  BUSLOCK__r_prelock_stall := false
  CLEAR_DCACHE__r_clear_dcache := true
  DIVERR__USER_DIVERR__r_udiv_err_flag := false
  DIVERR__r_idiv_err_flag := false
  DIVIDE__thedivide__last_bit := false
  DIVIDE__thedivide__o_busy := false
  DIVIDE__thedivide__o_err := false
  DIVIDE__thedivide__o_quotient := BitVec.ofNat 32 0
  DIVIDE__thedivide__o_valid := false
  DIVIDE__thedivide__pre_sign := false
  DIVIDE__thedivide__r_bit := BitVec.extractLsb 4 0 (BitVec.ofNat 32 0)
  DIVIDE__thedivide__r_busy := false
  DIVIDE__thedivide__r_c := false
  DIVIDE__thedivide__r_dividend := BitVec.ofNat 63 0
  DIVIDE__thedivide__r_divisor := BitVec.ofNat 32 0
  DIVIDE__thedivide__r_sign := false
  DIVIDE__thedivide__r_z := false
  DIVIDE__thedivide__zero_divisor := false
  FWD_OPERATION__r_op_opn := BitVec.ofNat 4 0
  GEN_ALU_PC__r_alu_pc := BitVec.ofNat 32 0
  GEN_ALU_PHASE__r_alu_phase := false
  GEN_CLOCK_GATE__r_clken := !(true)
  GEN_IHALT_PHASE__r_ihalt_phase := BitVec.getLsbD (BitVec.ofNat 32 0) 0
  GEN_OPLOCK__r_op_lock := false
  GEN_OP_PIPE__r_op_pipe := false
  GEN_OP_STALL__r_cc_invalid_for_dcd := false
  GEN_OP_STALL__r_pending_sreg_write := false
  GEN_OP_WR__r_op_wR := false
  GEN_PENDING_BREAK__r_break_pending := false
  GEN_PENDING_INTERRUPT__r_pending_interrupt := false
  GEN_PENDING_INTERRUPT__r_user_stepped := false
  GEN_UHALT_PHASE__r_uhalt_phase := false
  OPT_CIS_OP_PHASE__r_op_phase := false
  OP_REG_ADVANEC__r_op_Aid := BitVec.extractLsb 4 0 (BitVec.ofNat 32 0)
  OP_REG_ADVANEC__r_op_Bid := BitVec.extractLsb 4 0 (BitVec.ofNat 32 0)
  OP_REG_ADVANEC__r_op_R := BitVec.extractLsb 4 0 (BitVec.ofNat 32 0)
  OP_REG_ADVANEC__r_op_rA := BitVec.getLsbD (BitVec.ofNat 32 0) 0
  OP_REG_ADVANEC__r_op_rB := BitVec.getLsbD (BitVec.ofNat 32 0) 0
  SETDBG__r_dbg_reg := BitVec.ofNat 32 0
  SET_ALU_ILLEGAL__r_alu_illegal := BitVec.getLsbD (BitVec.ofNat 32 0) 0
  SET_GIE__r_gie := false
  SET_OP_PC__r_op_pc := bvBitWrite 32 (BitVec.ofNat 32 0) ((BitVec.ofNat 32 0).toNat) (false)
  SET_TRAP_N_UBREAK__r_trap := false
  SET_TRAP_N_UBREAK__r_ubreak := false
  SET_USER_BUSERR__r_ubus_err_flag := false
  SET_USER_ILLEGAL_INSN__r_ill_err_u := false
  SET_USER_PC__r_upc := BitVec.ofNat 32 0
  alu_reg := BitVec.ofNat 5 0
  alu_wF := false
  alu_wR := false
  break_en := false
  dbg_clear_pipe := false
  dbg_val := BitVec.ofNat 32 0
  dbgv := false
  doalu__c := false
  doalu__keep_sgn_on_ovfl := false
  doalu__o_c := BitVec.ofNat 32 0
  doalu__o_valid := false
  doalu__pre_sign := false
  doalu__r_busy := false
  doalu__set_ovfl := false
  flags := BitVec.ofNat 4 0
  ibus_err_flag := false
  iflags := BitVec.ofNat 4 0
  ill_err_i := false
  instruction_decoder__GEN_CIS_PHASE__r_phase := false
  instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_branch_pc := BitVec.ofNat 32 0
  instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_early_branch := false
  instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_early_branch_stb := false
  instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_ljmp := false
  instruction_decoder__GEN_OPIPE__r_insn_is_pipeable := false
  instruction_decoder__GEN_OPIPE__r_pipe := false
  instruction_decoder__o_ALU := false
  instruction_decoder__o_DV := BitVec.getLsbD (BitVec.ofNat 32 0) 0
  instruction_decoder__o_FP := BitVec.getLsbD (BitVec.ofNat 32 0) 0
  instruction_decoder__o_M := false
  instruction_decoder__o_break := false
  instruction_decoder__o_cond := BitVec.ofNat 4 0
  instruction_decoder__o_dcdA := BitVec.extractLsb 6 0 (BitVec.ofNat 32 0)
  instruction_decoder__o_dcdB := BitVec.extractLsb 6 0 (BitVec.ofNat 32 0)
  instruction_decoder__o_dcdR := BitVec.extractLsb 6 0 (BitVec.ofNat 32 0)
  instruction_decoder__o_illegal := false
  instruction_decoder__o_lock := BitVec.getLsbD (BitVec.ofNat 32 0) 0
  instruction_decoder__o_op := BitVec.ofNat 4 0
  instruction_decoder__o_pc := BitVec.ofNat 32 0
  instruction_decoder__o_rA := false
  instruction_decoder__o_rB := false
  instruction_decoder__o_sim := false
  instruction_decoder__o_sim_immv := BitVec.extractLsb 22 0 (BitVec.ofNat 32 0)
  instruction_decoder__o_wF := false
  instruction_decoder__o_wR := false
  instruction_decoder__o_zI := false
  instruction_decoder__r_I := BitVec.ofNat 23 0
  instruction_decoder__r_nxt_half := BitVec.ofNat 15 0
  instruction_decoder__r_valid := false
  ipc := BitVec.append (n := 30) (m := 2) (BitVec.ofNat 30 262144) (BitVec.ofNat 2 0)
  last_write_to_cc := false
  mem_pc_valid := false
  new_pc := true
  o_dbg_cc := BitVec.ofNat 3 0
  op_Rcc := BitVec.getLsbD (BitVec.ofNat 32 0) 0
  op_illegal := false
  op_valid := false
  op_valid_alu := false
  op_valid_div := false
  op_valid_fpu := false
  op_valid_mem := false
  op_wF := false
  pf_pc := BitVec.append (n := 30) (m := 2) (BitVec.ofNat 30 262144) (BitVec.ofNat 2 0)
  r_alu_pc_valid := false
  r_clear_icache := true
  r_dbg_stall := true
  r_halted := true
  r_op_Av := BitVec.ofNat 32 0
  r_op_Bv := BitVec.ofNat 32 0
  r_op_F := BitVec.ofNat 7 0
  r_op_break := false
  regset := BitVec.ofNat 1024 0
  sleep := false
  user_step := false
  wr_index := BitVec.extractLsb 2 0 (BitVec.ofNat 32 0)
  w_uflags := BitVec.ofNat 16 0
  w_iflags := BitVec.ofNat 16 0
  break_pending := false
  trap := false
  gie := false
  ubreak := false
  pending_interrupt := false
  stepped := false
  step := false
  ill_err_u := false
  ubus_err_flag := false
  idiv_err_flag := false
  udiv_err_flag := false
  ifpu_err_flag := false
  ufpu_err_flag := false
  ihalt_phase := false
  uhalt_phase := false
  master_ce := false
  master_stall := false
  clear_pipeline := false
  pf_gie := false
  dcd_opn := BitVec.ofNat 4 0
  dcd_ce := false
  dcd_phase := false
  dcd_A := BitVec.ofNat 5 0
  dcd_B := BitVec.ofNat 5 0
  dcd_R := BitVec.ofNat 5 0
  dcd_preA := BitVec.ofNat 5 0
  dcd_preB := BitVec.ofNat 5 0
  dcd_Acc := false
  dcd_Bcc := false
  dcd_Apc := false
  dcd_Bpc := false
  dcd_Rcc := false
  dcd_Rpc := false
  dcd_F := BitVec.ofNat 4 0
  dcd_wR := false
  dcd_rA := false
  dcd_rB := false
  dcd_ALU := false
  dcd_M := false
  dcd_DIV := false
  dcd_FP := false
  dcd_wF := false
  dcd_gie := false
  dcd_break := false
  dcd_lock := false
  dcd_pipe := false
  dcd_ljmp := false
  dcd_valid := false
  dcd_pc := BitVec.ofNat 32 0
  dcd_I := BitVec.ofNat 32 0
  dcd_zI := false
  dcd_A_stall := false
  dcd_B_stall := false
  dcd_F_stall := false
  dcd_illegal := false
  dcd_early_branch := false
  dcd_early_branch_stb := false
  dcd_branch_pc := BitVec.ofNat 32 0
  dcd_sim := false
  dcd_sim_immv := BitVec.ofNat 23 0
  prelock_stall := false
  last_lock_insn := false
  cc_invalid_for_dcd := false
  pending_sreg_write := false
  op_stall := false
  op_opn := BitVec.ofNat 4 0
  op_R := BitVec.ofNat 5 0
  op_Aid := BitVec.ofNat 5 0
  op_Bid := BitVec.ofNat 5 0
  op_rA := false
  op_rB := false
  op_pc := BitVec.ofNat 32 0
  w_op_Av := BitVec.ofNat 32 0
  w_op_Bv := BitVec.ofNat 32 0
  op_Av := BitVec.ofNat 32 0
  op_Bv := BitVec.ofNat 32 0
  op_wR := false
  op_gie := false
  op_Fl := BitVec.ofNat 4 0
  op_F := BitVec.ofNat 8 0
  op_ce := false
  op_phase := false
  op_pipe := false
  w_op_valid := false
  op_lowpower_clear := false
  w_cpu_info := BitVec.ofNat 9 0
  op_break := false
  op_lock := false
  op_sim := false
  op_sim_immv := BitVec.ofNat 23 0
  alu_sim := false
  alu_sim_immv := BitVec.ofNat 23 0
  alu_pc := BitVec.ofNat 32 0
  alu_pc_valid := false
  alu_phase := false
  alu_ce := false
  alu_stall := false
  alu_result := BitVec.ofNat 32 0
  alu_flags := BitVec.ofNat 4 0
  alu_valid := false
  alu_busy := false
  set_cond := false
  alu_gie := false
  alu_illegal := false
  mem_ce := false
  mem_stalled := false
  div_ce := false
  div_error := false
  div_busy := false
  div_valid := false
  div_result := BitVec.ofNat 32 0
  div_flags := BitVec.ofNat 4 0
  fpu_ce := false
  fpu_error := false
  fpu_busy := false
  fpu_valid := false
  fpu_result := BitVec.ofNat 32 0
  fpu_flags := BitVec.ofNat 4 0
  wr_write_pc := false
  wr_write_cc := false
  wr_write_scc := false
  wr_write_ucc := false
  wr_reg_id := BitVec.ofNat 5 0
  w_switch_to_interrupt := false
  w_release_from_interrupt := false
  upc := BitVec.ofNat 32 0
  cc_write_hold := false
  w_clken := false
  GEN_ALU_STALL__unused_alu_stall := false
  dcd_full_R := BitVec.ofNat 7 0
  dcd_full_A := BitVec.ofNat 7 0
  dcd_full_B := BitVec.ofNat 7 0
  instruction_decoder__i_clk := false
  instruction_decoder__i_reset := false
  instruction_decoder__i_ce := false
  instruction_decoder__i_stalled := false
  instruction_decoder__i_instruction := BitVec.ofNat 32 0
  instruction_decoder__i_gie := false
  instruction_decoder__i_pc := BitVec.ofNat 32 0
  instruction_decoder__i_pf_valid := false
  instruction_decoder__i_illegal := false
  instruction_decoder__o_valid := false
  instruction_decoder__o_phase := false
  instruction_decoder__o_preA := BitVec.ofNat 5 0
  instruction_decoder__o_preB := BitVec.ofNat 5 0
  instruction_decoder__o_I := BitVec.ofNat 32 0
  instruction_decoder__o_early_branch := false
  instruction_decoder__o_early_branch_stb := false
  instruction_decoder__o_branch_pc := BitVec.ofNat 32 0
  instruction_decoder__o_ljmp := false
  instruction_decoder__o_pipe := false
  instruction_decoder__w_op := BitVec.ofNat 5 0
  instruction_decoder__w_ldi := false
  instruction_decoder__w_mov := false
  instruction_decoder__w_cmptst := false
  instruction_decoder__w_ldilo := false
  instruction_decoder__w_ALU := false
  instruction_decoder__w_brev := false
  instruction_decoder__w_noop := false
  instruction_decoder__w_lock := false
  instruction_decoder__w_sim := false
  instruction_decoder__w_break := false
  instruction_decoder__w_special := false
  instruction_decoder__w_add := false
  instruction_decoder__w_mpy := false
  instruction_decoder__w_dcdR := BitVec.ofNat 5 0
  instruction_decoder__w_dcdB := BitVec.ofNat 5 0
  instruction_decoder__w_dcdA := BitVec.ofNat 5 0
  instruction_decoder__w_dcdR_pc := false
  instruction_decoder__w_dcdR_cc := false
  instruction_decoder__w_dcdA_pc := false
  instruction_decoder__w_dcdA_cc := false
  instruction_decoder__w_dcdB_pc := false
  instruction_decoder__w_dcdB_cc := false
  instruction_decoder__w_cond := BitVec.ofNat 4 0
  instruction_decoder__w_wF := false
  instruction_decoder__w_mem := false
  instruction_decoder__w_sto := false
  instruction_decoder__w_div := false
  instruction_decoder__w_fpu := false
  instruction_decoder__w_wR := false
  instruction_decoder__w_rA := false
  instruction_decoder__w_rB := false
  instruction_decoder__w_wR_n := false
  instruction_decoder__w_ljmp := false
  instruction_decoder__w_ljmp_dly := false
  instruction_decoder__w_cis_ljmp := false
  instruction_decoder__iword := BitVec.ofNat 32 0
  instruction_decoder__pf_valid := false
  instruction_decoder__w_I := BitVec.ofNat 23 0
  instruction_decoder__w_Iz := false
  instruction_decoder__insn_is_pipeable := false
  instruction_decoder__illegal_shift := false
  instruction_decoder__GEN_CIS_IMMEDIATE__w_halfI := BitVec.ofNat 8 0
  instruction_decoder__GEN_CIS_IMMEDIATE__w_halfbits := BitVec.ofNat 8 0
  instruction_decoder__GEN_EARLY_BRANCH_LOGIC__w_add_to_pc := false
  instruction_decoder__possibly_unused := false
  GEN_DISTRIBUTED_REGS__unused_prereg_addrs := false
  NO_OP_SIM__op_sim_unused := false
  doalu__i_clk := false
  doalu__i_reset := false
  doalu__i_stb := false
  doalu__i_op := BitVec.ofNat 4 0
  doalu__i_a := BitVec.ofNat 32 0
  doalu__i_b := BitVec.ofNat 32 0
  doalu__o_f := BitVec.ofNat 4 0
  doalu__o_busy := false
  doalu__w_brev_result := BitVec.ofNat 32 0
  doalu__z := false
  doalu__n := false
  doalu__v := false
  doalu__vx := false
  doalu__w_lsr_result := BitVec.ofNat 33 0
  doalu__w_asr_result := BitVec.ofNat 33 0
  doalu__w_lsl_result := BitVec.ofNat 33 0
  doalu__mpy_result := BitVec.ofNat 64 0
  doalu__mpyhi := false
  doalu__mpybusy := false
  doalu__mpydone := false
  doalu__this_is_a_multiply_op := false
  doalu__IMPLEMENT_SHIFTS__w_pre_asr_input := BitVec.ofNat 33 0
  doalu__IMPLEMENT_SHIFTS__w_pre_asr_shifted := BitVec.ofNat 33 0
  doalu__thempy__i_clk := false
  doalu__thempy__i_reset := false
  doalu__thempy__i_stb := false
  doalu__thempy__i_op := BitVec.ofNat 2 0
  doalu__thempy__i_a := BitVec.ofNat 32 0
  doalu__thempy__i_b := BitVec.ofNat 32 0
  doalu__thempy__o_valid := false
  doalu__thempy__o_busy := false
  doalu__thempy__o_result := BitVec.ofNat 64 0
  doalu__thempy__o_hi := false
  DIVIDE__thedivide__i_clk := false
  DIVIDE__thedivide__i_reset := false
  DIVIDE__thedivide__i_wr := false
  DIVIDE__thedivide__i_signed := false
  DIVIDE__thedivide__i_numerator := BitVec.ofNat 32 0
  DIVIDE__thedivide__i_denominator := BitVec.ofNat 32 0
  DIVIDE__thedivide__o_flags := BitVec.ofNat 4 0
  DIVIDE__thedivide__diff := BitVec.ofNat 33 0
  DIVIDE__thedivide__w_n := false
  cpu_sim := false
  unused := false
  o_clken := false
  o_dbg_stall := false
  o_dbg_reg := BitVec.ofNat 32 0
  o_break := false
  o_pf_new_pc := false
  o_clear_icache := false
  o_pf_ready := false
  o_pf_request_address := BitVec.ofNat 32 0
  o_clear_dcache := false
  o_mem_ce := false
  o_bus_lock := false
  o_mem_op := BitVec.ofNat 3 0
  o_mem_addr := BitVec.ofNat 32 0
  o_mem_data := BitVec.ofNat 32 0
  o_mem_lock_pc := BitVec.ofNat 32 0
  o_mem_reg := BitVec.ofNat 5 0
  o_op_stall := false
  o_pf_stall := false
  o_i_count := false
  o_debug := BitVec.ofNat 32 0
  o_prof_stb := false
  o_prof_addr := BitVec.ofNat 32 0
  o_prof_ticks := BitVec.ofNat 32 0
  SETDBG__pre_dbg_reg := BitVec.ofNat 32 0
  adf_ce_unconditional := false
  avsrc := BitVec.ofNat 3 0
  bisrc := BitVec.ofNat 2 0
  bvsrc := BitVec.ofNat 3 0
  dcd_stalled := false
  debug_pc := BitVec.ofNat 32 0
  instruction_decoder__w_cis_op := BitVec.ofNat 5 0
  instruction_decoder__w_fullI := BitVec.ofNat 23 0
  instruction_decoder__w_immsrc := BitVec.ofNat 2 0
  pfpcset := false
  pfpcsrc := BitVec.ofNat 3 0
  w_op_BnI := BitVec.ofNat 32 0
  w_pcA_v := BitVec.ofNat 32 0
  w_pcB_v := BitVec.ofNat 32 0
  wr_flags := BitVec.ofNat 4 0
  wr_flags_ce := false
  wr_gpreg_vl := BitVec.ofNat 32 0
  wr_reg_ce := false
  wr_spreg_vl := BitVec.ofNat 32 0

/-- zipcore 默认输入值 -/
def defaultInputs : zipcoreInputs where
  i_clk := false
  i_reset := true
  i_interrupt := false
  i_halt := false
  i_clear_cache := false
  i_dbg_wreg := BitVec.ofNat 5 0
  i_dbg_we := false
  i_dbg_data := BitVec.ofNat 32 0
  i_dbg_rreg := BitVec.ofNat 5 0
  i_pf_valid := false
  i_pf_illegal := false
  i_pf_instruction := BitVec.ofNat 32 0
  i_pf_instruction_pc := BitVec.ofNat 32 0
  i_mem_busy := false
  i_mem_rdbusy := false
  i_mem_pipe_stalled := false
  i_mem_valid := false
  i_bus_err := false
  i_mem_wreg := BitVec.ofNat 5 0
  i_mem_result := BitVec.ofNat 32 0
  __rtl_nondet_0000 := BitVec.ofNat 2 0
  __rtl_nondet_0001 := BitVec.ofNat 3 0
  __rtl_nondet_0002 := BitVec.ofNat 3 0

/-- 组合逻辑：assign_clear_pipeline -/
def assign_clear_pipeline (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let clear_pipeline := s.new_pc
  { s with
    clear_pipeline := clear_pipeline
  }

/-- 组合逻辑：assign_div_ce -/
def assign_div_ce (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let div_ce := ((s.op_valid_div && s.adf_ce_unconditional) && s.set_cond)
  { s with
    div_ce := div_ce
  }

/-- 组合逻辑：assign_fpu_ce -/
def assign_fpu_ce (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let fpu_ce := (((false && s.op_valid_fpu) && s.adf_ce_unconditional) && s.set_cond)
  { s with
    fpu_ce := fpu_ce
  }

/-- 组合逻辑：assign_master_ce -/
def assign_master_ce (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let master_ce := ((((!(i.i_halt) || s.alu_phase) && !(s.cc_write_hold)) && !(s.o_break)) && !(s.sleep))
  { s with
    master_ce := master_ce
  }

/-- 组合逻辑：assign_cc_invalid_for_dcd -/
def assign_cc_invalid_for_dcd (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let cc_invalid_for_dcd := s.GEN_OP_STALL__r_cc_invalid_for_dcd
  { s with
    cc_invalid_for_dcd := cc_invalid_for_dcd
  }

/-- 组合逻辑：assign_pending_sreg_write -/
def assign_pending_sreg_write (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let pending_sreg_write := s.GEN_OP_STALL__r_pending_sreg_write
  { s with
    pending_sreg_write := pending_sreg_write
  }

/-- 组合逻辑：assign_op_stall -/
def assign_op_stall (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let op_stall := ((s.op_valid && (!(s.adf_ce_unconditional) && !(s.mem_ce))) || (s.dcd_valid && (((i.i_halt || s.dcd_A_stall) || s.dcd_B_stall) || s.dcd_F_stall)))
  { s with
    op_stall := op_stall
  }

/-- 组合逻辑：assign_op_ce -/
def assign_op_ce (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let op_ce := (((s.dcd_valid || s.dcd_illegal) || s.dcd_early_branch) && !(s.op_stall))
  { s with
    op_ce := op_ce
  }

/-- 组合逻辑：assign_alu_stall -/
def assign_alu_stall (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let alu_stall := (((s.master_stall || i.i_mem_rdbusy) && s.op_valid_alu) || (s.wr_reg_ce && s.wr_write_cc))
  { s with
    alu_stall := alu_stall
  }

/-- 组合逻辑：assign_alu_ce -/
def assign_alu_ce (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let alu_ce := (s.adf_ce_unconditional && s.op_valid_alu)
  { s with
    alu_ce := alu_ce
  }

/-- 组合逻辑：assign_GEN_ALU_STALL__unused_alu_stall -/
def assign_GEN_ALU_STALL__unused_alu_stall (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let GEN_ALU_STALL__unused_alu_stall := BitVec.getLsbD (BitVec.extractLsb 1 0 (BitVec.extractLsb 1 0 (boolToBitVec (bvReduceAnd (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (s.alu_stall))))))) 0
  { s with
    GEN_ALU_STALL__unused_alu_stall := GEN_ALU_STALL__unused_alu_stall
  }

/-- 组合逻辑：assign_mem_ce -/
def assign_mem_ce (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let mem_ce := (((s.master_ce && s.op_valid_mem) && !(s.mem_stalled)) && !(s.clear_pipeline))
  { s with
    mem_ce := mem_ce
  }

/-- 组合逻辑：assign_mem_stalled -/
def assign_mem_stalled (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let mem_stalled := (s.master_stall || (s.op_valid_mem && ((((i.i_mem_pipe_stalled || i.i_bus_err) || s.div_error) || (!(s.op_pipe) && i.i_mem_busy)) || (s.wr_reg_ce && (s.wr_write_pc || s.wr_write_cc)))))
  { s with
    mem_stalled := mem_stalled
  }

/-- 组合逻辑：assign_master_stall -/
def assign_master_stall (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let master_stall := (((((((((((!(s.master_ce) || !(s.op_valid)) || s.ill_err_i) || (s.step && s.stepped)) || s.ibus_err_flag) || s.idiv_err_flag) || ((s.pending_interrupt && !(s.o_bus_lock)) && !(s.alu_phase))) || s.alu_busy) || s.div_busy) || s.fpu_busy) || s.op_break) || (true && ((((s.prelock_stall || (i.i_mem_busy && s.op_illegal)) || (i.i_mem_busy && s.op_valid_div)) || s.alu_illegal) || s.o_break)))
  { s with
    master_stall := master_stall
  }

/-- 组合逻辑：assign_o_pf_ready -/
def assign_o_pf_ready (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let o_pf_ready := (!(s.dcd_stalled) && !(s.dcd_phase))
  { s with
    o_pf_ready := o_pf_ready
  }

/-- 组合逻辑：assign_o_pf_new_pc -/
def assign_o_pf_new_pc (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let o_pf_new_pc := (s.new_pc || (s.dcd_early_branch_stb && !(s.clear_pipeline)))
  { s with
    o_pf_new_pc := o_pf_new_pc
  }

/-- 组合逻辑：assign_o_pf_request_address -/
def assign_o_pf_request_address (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let o_pf_request_address := (if (s.dcd_early_branch_stb && !(s.clear_pipeline)) then s.dcd_branch_pc else s.pf_pc)
  { s with
    o_pf_request_address := o_pf_request_address
  }

/-- 组合逻辑：assign_pf_gie -/
def assign_pf_gie (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let pf_gie := s.gie
  { s with
    pf_gie := pf_gie
  }

/-- 组合逻辑：assign_dcd_ce -/
def assign_dcd_ce (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_ce := ((true && !(s.dcd_valid)) || !(s.dcd_stalled))
  { s with
    dcd_ce := dcd_ce
  }

/-- 组合逻辑：assign_instruction_decoder__i_clk -/
def assign_instruction_decoder__i_clk (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__i_clk := i.i_clk
  { s with
    instruction_decoder__i_clk := instruction_decoder__i_clk
  }

/-- 组合逻辑：assign_instruction_decoder__i_reset -/
def assign_instruction_decoder__i_reset (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__i_reset := ((i.i_reset || s.clear_pipeline) || s.o_clear_icache)
  { s with
    instruction_decoder__i_reset := instruction_decoder__i_reset
  }

/-- 组合逻辑：assign_instruction_decoder__i_ce -/
def assign_instruction_decoder__i_ce (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__i_ce := s.dcd_ce
  { s with
    instruction_decoder__i_ce := instruction_decoder__i_ce
  }

/-- 组合逻辑：assign_instruction_decoder__i_stalled -/
def assign_instruction_decoder__i_stalled (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__i_stalled := s.dcd_stalled
  { s with
    instruction_decoder__i_stalled := instruction_decoder__i_stalled
  }

/-- 组合逻辑：assign_instruction_decoder__i_instruction -/
def assign_instruction_decoder__i_instruction (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__i_instruction := i.i_pf_instruction
  { s with
    instruction_decoder__i_instruction := instruction_decoder__i_instruction
  }

/-- 组合逻辑：assign_instruction_decoder__i_gie -/
def assign_instruction_decoder__i_gie (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__i_gie := s.pf_gie
  { s with
    instruction_decoder__i_gie := instruction_decoder__i_gie
  }

/-- 组合逻辑：assign_instruction_decoder__i_pc -/
def assign_instruction_decoder__i_pc (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__i_pc := i.i_pf_instruction_pc
  { s with
    instruction_decoder__i_pc := instruction_decoder__i_pc
  }

/-- 组合逻辑：assign_instruction_decoder__i_pf_valid -/
def assign_instruction_decoder__i_pf_valid (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__i_pf_valid := i.i_pf_valid
  { s with
    instruction_decoder__i_pf_valid := instruction_decoder__i_pf_valid
  }

/-- 组合逻辑：assign_instruction_decoder__i_illegal -/
def assign_instruction_decoder__i_illegal (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__i_illegal := i.i_pf_illegal
  { s with
    instruction_decoder__i_illegal := instruction_decoder__i_illegal
  }

/-- 组合逻辑：assign_dcd_valid -/
def assign_dcd_valid (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_valid := s.instruction_decoder__o_valid
  { s with
    dcd_valid := dcd_valid
  }

/-- 组合逻辑：assign_dcd_phase -/
def assign_dcd_phase (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_phase := s.instruction_decoder__o_phase
  { s with
    dcd_phase := dcd_phase
  }

/-- 组合逻辑：assign_dcd_illegal -/
def assign_dcd_illegal (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_illegal := s.instruction_decoder__o_illegal
  { s with
    dcd_illegal := dcd_illegal
  }

/-- 组合逻辑：assign_dcd_pc -/
def assign_dcd_pc (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_pc := s.instruction_decoder__o_pc
  { s with
    dcd_pc := dcd_pc
  }

/-- 组合逻辑：assign_dcd_full_R -/
def assign_dcd_full_R (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_full_R := s.instruction_decoder__o_dcdR
  { s with
    dcd_full_R := dcd_full_R
  }

/-- 组合逻辑：assign_dcd_full_A -/
def assign_dcd_full_A (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_full_A := s.instruction_decoder__o_dcdA
  { s with
    dcd_full_A := dcd_full_A
  }

/-- 组合逻辑：assign_dcd_full_B -/
def assign_dcd_full_B (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_full_B := s.instruction_decoder__o_dcdB
  { s with
    dcd_full_B := dcd_full_B
  }

/-- 组合逻辑：assign_dcd_preA -/
def assign_dcd_preA (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_preA := s.instruction_decoder__o_preA
  { s with
    dcd_preA := dcd_preA
  }

/-- 组合逻辑：assign_dcd_preB -/
def assign_dcd_preB (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_preB := s.instruction_decoder__o_preB
  { s with
    dcd_preB := dcd_preB
  }

/-- 组合逻辑：assign_dcd_I -/
def assign_dcd_I (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_I := s.instruction_decoder__o_I
  { s with
    dcd_I := dcd_I
  }

/-- 组合逻辑：assign_dcd_zI -/
def assign_dcd_zI (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_zI := s.instruction_decoder__o_zI
  { s with
    dcd_zI := dcd_zI
  }

/-- 组合逻辑：assign_dcd_F -/
def assign_dcd_F (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_F := s.instruction_decoder__o_cond
  { s with
    dcd_F := dcd_F
  }

/-- 组合逻辑：assign_dcd_wF -/
def assign_dcd_wF (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_wF := s.instruction_decoder__o_wF
  { s with
    dcd_wF := dcd_wF
  }

/-- 组合逻辑：assign_dcd_opn -/
def assign_dcd_opn (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_opn := s.instruction_decoder__o_op
  { s with
    dcd_opn := dcd_opn
  }

/-- 组合逻辑：assign_dcd_ALU -/
def assign_dcd_ALU (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_ALU := s.instruction_decoder__o_ALU
  { s with
    dcd_ALU := dcd_ALU
  }

/-- 组合逻辑：assign_dcd_M -/
def assign_dcd_M (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_M := s.instruction_decoder__o_M
  { s with
    dcd_M := dcd_M
  }

/-- 组合逻辑：assign_dcd_DIV -/
def assign_dcd_DIV (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_DIV := s.instruction_decoder__o_DV
  { s with
    dcd_DIV := dcd_DIV
  }

/-- 组合逻辑：assign_dcd_FP -/
def assign_dcd_FP (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_FP := s.instruction_decoder__o_FP
  { s with
    dcd_FP := dcd_FP
  }

/-- 组合逻辑：assign_dcd_break -/
def assign_dcd_break (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_break := s.instruction_decoder__o_break
  { s with
    dcd_break := dcd_break
  }

/-- 组合逻辑：assign_dcd_lock -/
def assign_dcd_lock (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_lock := s.instruction_decoder__o_lock
  { s with
    dcd_lock := dcd_lock
  }

/-- 组合逻辑：assign_dcd_wR -/
def assign_dcd_wR (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_wR := s.instruction_decoder__o_wR
  { s with
    dcd_wR := dcd_wR
  }

/-- 组合逻辑：assign_dcd_rA -/
def assign_dcd_rA (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_rA := s.instruction_decoder__o_rA
  { s with
    dcd_rA := dcd_rA
  }

/-- 组合逻辑：assign_dcd_rB -/
def assign_dcd_rB (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_rB := s.instruction_decoder__o_rB
  { s with
    dcd_rB := dcd_rB
  }

/-- 组合逻辑：assign_dcd_early_branch -/
def assign_dcd_early_branch (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_early_branch := s.instruction_decoder__o_early_branch
  { s with
    dcd_early_branch := dcd_early_branch
  }

/-- 组合逻辑：assign_dcd_early_branch_stb -/
def assign_dcd_early_branch_stb (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_early_branch_stb := s.instruction_decoder__o_early_branch_stb
  { s with
    dcd_early_branch_stb := dcd_early_branch_stb
  }

/-- 组合逻辑：assign_dcd_branch_pc -/
def assign_dcd_branch_pc (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_branch_pc := s.instruction_decoder__o_branch_pc
  { s with
    dcd_branch_pc := dcd_branch_pc
  }

/-- 组合逻辑：assign_dcd_ljmp -/
def assign_dcd_ljmp (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_ljmp := s.instruction_decoder__o_ljmp
  { s with
    dcd_ljmp := dcd_ljmp
  }

/-- 组合逻辑：assign_dcd_pipe -/
def assign_dcd_pipe (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_pipe := s.instruction_decoder__o_pipe
  { s with
    dcd_pipe := dcd_pipe
  }

/-- 组合逻辑：assign_dcd_sim -/
def assign_dcd_sim (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_sim := s.instruction_decoder__o_sim
  { s with
    dcd_sim := dcd_sim
  }

/-- 组合逻辑：assign_dcd_sim_immv -/
def assign_dcd_sim_immv (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_sim_immv := s.instruction_decoder__o_sim_immv
  { s with
    dcd_sim_immv := dcd_sim_immv
  }

/-- 组合逻辑：assign_instruction_decoder__pf_valid -/
def assign_instruction_decoder__pf_valid (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__pf_valid := (s.instruction_decoder__i_pf_valid && !(s.instruction_decoder__o_early_branch_stb))
  { s with
    instruction_decoder__pf_valid := instruction_decoder__pf_valid
  }

/-- 组合逻辑：assign_instruction_decoder__iword -/
def assign_instruction_decoder__iword (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__iword := (if s.instruction_decoder__o_phase then BitVec.append (n := 1) (m := 31) (boolToBitVec (true)) (BitVec.append (n := 15) (m := 16) (BitVec.extractLsb 14 0 (s.instruction_decoder__r_nxt_half)) (BitVec.extractLsb 15 0 (s.instruction_decoder__i_instruction))) else s.instruction_decoder__i_instruction)
  { s with
    instruction_decoder__iword := instruction_decoder__iword
  }

/-- 组合逻辑：assign_instruction_decoder__w_cis_ljmp -/
def assign_instruction_decoder__w_cis_ljmp (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_cis_ljmp := (s.instruction_decoder__o_phase && decide ((BitVec.extractLsb 31 16 (s.instruction_decoder__iword)).toNat = (BitVec.ofNat 16 64760).toNat))
  { s with
    instruction_decoder__w_cis_ljmp := instruction_decoder__w_cis_ljmp
  }

/-- 组合逻辑：assign_instruction_decoder__w_ljmp -/
def assign_instruction_decoder__w_ljmp (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_ljmp := decide ((s.instruction_decoder__iword).toNat = (BitVec.ofNat 32 2089271296).toNat)
  { s with
    instruction_decoder__w_ljmp := instruction_decoder__w_ljmp
  }

/-- 组合逻辑：assign_instruction_decoder__w_op -/
def assign_instruction_decoder__w_op (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_op := BitVec.extractLsb 26 22 (s.instruction_decoder__iword)
  { s with
    instruction_decoder__w_op := instruction_decoder__w_op
  }

/-- 组合逻辑：assign_instruction_decoder__w_mov -/
def assign_instruction_decoder__w_mov (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_mov := decide ((s.instruction_decoder__w_cis_op).toNat = (BitVec.ofNat 5 13).toNat)
  { s with
    instruction_decoder__w_mov := instruction_decoder__w_mov
  }

/-- 组合逻辑：assign_instruction_decoder__w_ldi -/
def assign_instruction_decoder__w_ldi (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_ldi := decide ((BitVec.extractLsb 4 1 (s.instruction_decoder__w_cis_op)).toNat = (BitVec.ofNat 4 12).toNat)
  { s with
    instruction_decoder__w_ldi := instruction_decoder__w_ldi
  }

/-- 组合逻辑：assign_instruction_decoder__w_brev -/
def assign_instruction_decoder__w_brev (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_brev := decide ((s.instruction_decoder__w_cis_op).toNat = (BitVec.ofNat 5 8).toNat)
  { s with
    instruction_decoder__w_brev := instruction_decoder__w_brev
  }

/-- 组合逻辑：assign_instruction_decoder__w_mpy -/
def assign_instruction_decoder__w_mpy (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_mpy := (decide ((BitVec.extractLsb 4 1 (s.instruction_decoder__w_cis_op)).toNat = (BitVec.ofNat 4 5).toNat) || decide ((BitVec.extractLsb 4 0 (s.instruction_decoder__w_cis_op)).toNat = (BitVec.ofNat 5 12).toNat))
  { s with
    instruction_decoder__w_mpy := instruction_decoder__w_mpy
  }

/-- 组合逻辑：assign_instruction_decoder__w_cmptst -/
def assign_instruction_decoder__w_cmptst (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_cmptst := decide ((BitVec.extractLsb 4 1 (s.instruction_decoder__w_cis_op)).toNat = (BitVec.ofNat 4 8).toNat)
  { s with
    instruction_decoder__w_cmptst := instruction_decoder__w_cmptst
  }

/-- 组合逻辑：assign_instruction_decoder__w_ldilo -/
def assign_instruction_decoder__w_ldilo (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_ldilo := decide ((BitVec.extractLsb 4 0 (s.instruction_decoder__w_cis_op)).toNat = (BitVec.ofNat 5 9).toNat)
  { s with
    instruction_decoder__w_ldilo := instruction_decoder__w_ldilo
  }

/-- 组合逻辑：assign_instruction_decoder__w_ALU -/
def assign_instruction_decoder__w_ALU (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_ALU := (!(BitVec.getLsbD (s.instruction_decoder__w_cis_op) 4) && decide ((BitVec.extractLsb 3 1 (s.instruction_decoder__w_cis_op)).toNat ≠ (BitVec.ofNat 3 7).toNat))
  { s with
    instruction_decoder__w_ALU := instruction_decoder__w_ALU
  }

/-- 组合逻辑：assign_instruction_decoder__w_add -/
def assign_instruction_decoder__w_add (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_add := decide ((BitVec.extractLsb 4 0 (s.instruction_decoder__w_cis_op)).toNat = (BitVec.ofNat 5 2).toNat)
  { s with
    instruction_decoder__w_add := instruction_decoder__w_add
  }

/-- 组合逻辑：assign_instruction_decoder__w_mem -/
def assign_instruction_decoder__w_mem (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_mem := (decide ((BitVec.extractLsb 4 3 (s.instruction_decoder__w_cis_op)).toNat = (BitVec.ofNat 2 2).toNat) && decide ((BitVec.extractLsb 2 1 (s.instruction_decoder__w_cis_op)).toNat ≠ (BitVec.ofNat 2 0).toNat))
  { s with
    instruction_decoder__w_mem := instruction_decoder__w_mem
  }

/-- 组合逻辑：assign_instruction_decoder__w_sto -/
def assign_instruction_decoder__w_sto (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_sto := (s.instruction_decoder__w_mem && BitVec.getLsbD (s.instruction_decoder__w_cis_op) 0)
  { s with
    instruction_decoder__w_sto := instruction_decoder__w_sto
  }

/-- 组合逻辑：assign_instruction_decoder__w_div -/
def assign_instruction_decoder__w_div (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_div := (!(BitVec.getLsbD (s.instruction_decoder__iword) 31) && decide ((BitVec.extractLsb 4 1 (s.instruction_decoder__w_op)).toNat = (BitVec.ofNat 4 7).toNat))
  { s with
    instruction_decoder__w_div := instruction_decoder__w_div
  }

/-- 组合逻辑：assign_instruction_decoder__w_fpu -/
def assign_instruction_decoder__w_fpu (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_fpu := (((!(BitVec.getLsbD (s.instruction_decoder__iword) 31) && decide ((BitVec.extractLsb 4 3 (s.instruction_decoder__w_op)).toNat = (BitVec.ofNat 2 3).toNat)) && decide ((BitVec.extractLsb 3 1 (s.instruction_decoder__w_dcdR)).toNat ≠ (BitVec.ofNat 3 7).toNat)) && decide ((BitVec.extractLsb 2 1 (s.instruction_decoder__w_op)).toNat ≠ (BitVec.ofNat 2 0).toNat))
  { s with
    instruction_decoder__w_fpu := instruction_decoder__w_fpu
  }

/-- 组合逻辑：assign_instruction_decoder__w_special -/
def assign_instruction_decoder__w_special (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_special := ((!(BitVec.getLsbD (s.instruction_decoder__iword) 31) && decide ((BitVec.extractLsb 3 1 (s.instruction_decoder__w_dcdR)).toNat = (BitVec.ofNat 3 7).toNat)) && decide ((BitVec.extractLsb 4 2 (s.instruction_decoder__w_op)).toNat = (BitVec.ofNat 3 7).toNat))
  { s with
    instruction_decoder__w_special := instruction_decoder__w_special
  }

/-- 组合逻辑：assign_instruction_decoder__w_break -/
def assign_instruction_decoder__w_break (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_break := (s.instruction_decoder__w_special && decide ((BitVec.extractLsb 4 0 (s.instruction_decoder__w_op)).toNat = (BitVec.ofNat 5 28).toNat))
  { s with
    instruction_decoder__w_break := instruction_decoder__w_break
  }

/-- 组合逻辑：assign_instruction_decoder__w_lock -/
def assign_instruction_decoder__w_lock (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_lock := (s.instruction_decoder__w_special && decide ((BitVec.extractLsb 4 0 (s.instruction_decoder__w_op)).toNat = (BitVec.ofNat 5 29).toNat))
  { s with
    instruction_decoder__w_lock := instruction_decoder__w_lock
  }

/-- 组合逻辑：assign_instruction_decoder__w_sim -/
def assign_instruction_decoder__w_sim (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_sim := (s.instruction_decoder__w_special && decide ((BitVec.extractLsb 4 0 (s.instruction_decoder__w_op)).toNat = (BitVec.ofNat 5 30).toNat))
  { s with
    instruction_decoder__w_sim := instruction_decoder__w_sim
  }

/-- 组合逻辑：assign_instruction_decoder__w_noop -/
def assign_instruction_decoder__w_noop (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_noop := (s.instruction_decoder__w_special && decide ((BitVec.extractLsb 4 1 (s.instruction_decoder__w_op)).toNat = (BitVec.ofNat 4 15).toNat))
  { s with
    instruction_decoder__w_noop := instruction_decoder__w_noop
  }

/-- 组合逻辑：assign_instruction_decoder__w_dcdR -/
def assign_instruction_decoder__w_dcdR (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_dcdR := BitVec.append (n := 1) (m := 4) (boolToBitVec ((if (((!(BitVec.getLsbD (s.instruction_decoder__iword) 31) && true) && s.instruction_decoder__w_mov) && !(s.instruction_decoder__i_gie)) then BitVec.getLsbD (s.instruction_decoder__iword) 18 else s.instruction_decoder__i_gie))) (BitVec.extractLsb 30 27 (s.instruction_decoder__iword))
  { s with
    instruction_decoder__w_dcdR := instruction_decoder__w_dcdR
  }

/-- 组合逻辑：assign_instruction_decoder__w_dcdA -/
def assign_instruction_decoder__w_dcdA (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_dcdA := s.instruction_decoder__w_dcdR
  { s with
    instruction_decoder__w_dcdA := instruction_decoder__w_dcdA
  }

/-- 组合逻辑：assign_instruction_decoder__w_dcdA_pc -/
def assign_instruction_decoder__w_dcdA_pc (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_dcdA_pc := s.instruction_decoder__w_dcdR_pc
  { s with
    instruction_decoder__w_dcdA_pc := instruction_decoder__w_dcdA_pc
  }

/-- 组合逻辑：assign_instruction_decoder__w_dcdA_cc -/
def assign_instruction_decoder__w_dcdA_cc (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_dcdA_cc := s.instruction_decoder__w_dcdR_cc
  { s with
    instruction_decoder__w_dcdA_cc := instruction_decoder__w_dcdA_cc
  }

/-- 组合逻辑：assign_instruction_decoder__w_dcdR_pc -/
def assign_instruction_decoder__w_dcdR_pc (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_dcdR_pc := decide ((s.instruction_decoder__w_dcdR).toNat = (BitVec.append (n := 1) (m := 4) (boolToBitVec (s.instruction_decoder__i_gie)) (BitVec.ofNat 4 15)).toNat)
  { s with
    instruction_decoder__w_dcdR_pc := instruction_decoder__w_dcdR_pc
  }

/-- 组合逻辑：assign_instruction_decoder__w_dcdR_cc -/
def assign_instruction_decoder__w_dcdR_cc (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_dcdR_cc := decide ((s.instruction_decoder__w_dcdR).toNat = (BitVec.append (n := 1) (m := 4) (boolToBitVec (s.instruction_decoder__i_gie)) (BitVec.ofNat 4 14)).toNat)
  { s with
    instruction_decoder__w_dcdR_cc := instruction_decoder__w_dcdR_cc
  }

/-- 组合逻辑：assign_instruction_decoder__w_dcdB -/
def assign_instruction_decoder__w_dcdB (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_dcdB := BitVec.append (n := 1) (m := 4) (boolToBitVec ((if (((!(BitVec.getLsbD (s.instruction_decoder__iword) 31) && s.instruction_decoder__w_mov) && true) && !(s.instruction_decoder__i_gie)) then BitVec.getLsbD (s.instruction_decoder__iword) 13 else s.instruction_decoder__i_gie))) ((if BitVec.getLsbD (s.instruction_decoder__iword) 31 then (if (!(BitVec.getLsbD (s.instruction_decoder__iword) 23) && decide ((BitVec.extractLsb 26 25 (s.instruction_decoder__iword)).toNat = (BitVec.ofNat 2 2).toNat)) then BitVec.ofNat 4 13 else BitVec.extractLsb 22 19 (s.instruction_decoder__iword)) else BitVec.extractLsb 17 14 (s.instruction_decoder__iword)))
  { s with
    instruction_decoder__w_dcdB := instruction_decoder__w_dcdB
  }

/-- 组合逻辑：assign_instruction_decoder__w_dcdB_pc -/
def assign_instruction_decoder__w_dcdB_pc (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_dcdB_pc := (s.instruction_decoder__w_rB && decide ((BitVec.extractLsb 3 0 (s.instruction_decoder__w_dcdB)).toNat = (BitVec.ofNat 4 15).toNat))
  { s with
    instruction_decoder__w_dcdB_pc := instruction_decoder__w_dcdB_pc
  }

/-- 组合逻辑：assign_instruction_decoder__w_dcdB_cc -/
def assign_instruction_decoder__w_dcdB_cc (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_dcdB_cc := (s.instruction_decoder__w_rB && decide ((BitVec.extractLsb 3 0 (s.instruction_decoder__w_dcdB)).toNat = (BitVec.ofNat 4 14).toNat))
  { s with
    instruction_decoder__w_dcdB_cc := instruction_decoder__w_dcdB_cc
  }

/-- 组合逻辑：assign_instruction_decoder__w_cond -/
def assign_instruction_decoder__w_cond (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_cond := (if ((s.instruction_decoder__w_ldi || s.instruction_decoder__w_special) || BitVec.getLsbD (s.instruction_decoder__iword) 31) then BitVec.ofNat 4 8 else BitVec.append (n := 1) (m := 3) (boolToBitVec (decide ((BitVec.extractLsb 21 19 (s.instruction_decoder__iword)).toNat = (BitVec.ofNat 3 0).toNat))) (BitVec.extractLsb 21 19 (s.instruction_decoder__iword)))
  { s with
    instruction_decoder__w_cond := instruction_decoder__w_cond
  }

/-- 组合逻辑：assign_instruction_decoder__w_rA -/
def assign_instruction_decoder__w_rA (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_rA := ((((s.instruction_decoder__w_fpu || s.instruction_decoder__w_div) || ((s.instruction_decoder__w_ALU && !(s.instruction_decoder__w_brev)) && !(s.instruction_decoder__w_mov))) || s.instruction_decoder__w_sto) || s.instruction_decoder__w_cmptst)
  { s with
    instruction_decoder__w_rA := instruction_decoder__w_rA
  }

/-- 组合逻辑：assign_instruction_decoder__w_rB -/
def assign_instruction_decoder__w_rB (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_rB := (((s.instruction_decoder__w_mov || (((!(BitVec.getLsbD (s.instruction_decoder__iword) 31) && BitVec.getLsbD (s.instruction_decoder__iword) 18) && !(s.instruction_decoder__w_ldi)) && !(s.instruction_decoder__w_special))) || ((BitVec.getLsbD (s.instruction_decoder__iword) 31 && BitVec.getLsbD (s.instruction_decoder__iword) 23) && !(s.instruction_decoder__w_ldi))) || (BitVec.getLsbD (s.instruction_decoder__iword) 31 && s.instruction_decoder__w_mem))
  { s with
    instruction_decoder__w_rB := instruction_decoder__w_rB
  }

/-- 组合逻辑：assign_instruction_decoder__w_wR_n -/
def assign_instruction_decoder__w_wR_n (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_wR_n := ((s.instruction_decoder__w_sto || s.instruction_decoder__w_special) || s.instruction_decoder__w_cmptst)
  { s with
    instruction_decoder__w_wR_n := instruction_decoder__w_wR_n
  }

/-- 组合逻辑：assign_instruction_decoder__w_wR -/
def assign_instruction_decoder__w_wR (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_wR := !(s.instruction_decoder__w_wR_n)
  { s with
    instruction_decoder__w_wR := instruction_decoder__w_wR
  }

/-- 组合逻辑：assign_instruction_decoder__w_wF -/
def assign_instruction_decoder__w_wF (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_wF := (s.instruction_decoder__w_cmptst || (BitVec.getLsbD (s.instruction_decoder__w_cond) 3 && ((s.instruction_decoder__w_fpu || s.instruction_decoder__w_div) || ((((s.instruction_decoder__w_ALU && !(s.instruction_decoder__w_mov)) && !(s.instruction_decoder__w_ldilo)) && !(s.instruction_decoder__w_brev)) && decide ((BitVec.extractLsb 3 1 (s.instruction_decoder__w_dcdR)).toNat ≠ (BitVec.ofNat 3 7).toNat)))))
  { s with
    instruction_decoder__w_wF := instruction_decoder__w_wF
  }

/-- 组合逻辑：assign_instruction_decoder__GEN_CIS_IMMEDIATE__w_halfbits -/
def assign_instruction_decoder__GEN_CIS_IMMEDIATE__w_halfbits (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__GEN_CIS_IMMEDIATE__w_halfbits := BitVec.extractLsb 23 16 (s.instruction_decoder__iword)
  { s with
    instruction_decoder__GEN_CIS_IMMEDIATE__w_halfbits := instruction_decoder__GEN_CIS_IMMEDIATE__w_halfbits
  }

/-- 组合逻辑：assign_instruction_decoder__GEN_CIS_IMMEDIATE__w_halfI -/
def assign_instruction_decoder__GEN_CIS_IMMEDIATE__w_halfI (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__GEN_CIS_IMMEDIATE__w_halfI := (if decide ((BitVec.extractLsb 26 24 (s.instruction_decoder__iword)).toNat = (BitVec.ofNat 3 6).toNat) then BitVec.extractLsb 7 0 (s.instruction_decoder__GEN_CIS_IMMEDIATE__w_halfbits) else (if BitVec.getLsbD (s.instruction_decoder__GEN_CIS_IMMEDIATE__w_halfbits) 7 then BitVec.append (n := 6) (m := 2) (BitVec.append (n := 3) (m := 3) (BitVec.append (n := 1) (m := 2) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__GEN_CIS_IMMEDIATE__w_halfbits) 2)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__GEN_CIS_IMMEDIATE__w_halfbits) 2)) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__GEN_CIS_IMMEDIATE__w_halfbits) 2)))) (BitVec.append (n := 1) (m := 2) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__GEN_CIS_IMMEDIATE__w_halfbits) 2)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__GEN_CIS_IMMEDIATE__w_halfbits) 2)) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__GEN_CIS_IMMEDIATE__w_halfbits) 2))))) (BitVec.extractLsb 1 0 (s.instruction_decoder__GEN_CIS_IMMEDIATE__w_halfbits)) else BitVec.append (n := 1) (m := 7) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__GEN_CIS_IMMEDIATE__w_halfbits) 6)) (BitVec.extractLsb 6 0 (s.instruction_decoder__GEN_CIS_IMMEDIATE__w_halfbits))))
  { s with
    instruction_decoder__GEN_CIS_IMMEDIATE__w_halfI := instruction_decoder__GEN_CIS_IMMEDIATE__w_halfI
  }

/-- 组合逻辑：assign_instruction_decoder__w_I -/
def assign_instruction_decoder__w_I (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_I := (if BitVec.getLsbD (s.instruction_decoder__iword) 31 then BitVec.append (n := 15) (m := 8) (BitVec.append (n := 7) (m := 8) (BitVec.append (n := 3) (m := 4) (BitVec.append (n := 1) (m := 2) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__GEN_CIS_IMMEDIATE__w_halfI) 7)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__GEN_CIS_IMMEDIATE__w_halfI) 7)) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__GEN_CIS_IMMEDIATE__w_halfI) 7)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__GEN_CIS_IMMEDIATE__w_halfI) 7)) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__GEN_CIS_IMMEDIATE__w_halfI) 7))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__GEN_CIS_IMMEDIATE__w_halfI) 7)) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__GEN_CIS_IMMEDIATE__w_halfI) 7))))) (BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__GEN_CIS_IMMEDIATE__w_halfI) 7)) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__GEN_CIS_IMMEDIATE__w_halfI) 7))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__GEN_CIS_IMMEDIATE__w_halfI) 7)) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__GEN_CIS_IMMEDIATE__w_halfI) 7)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__GEN_CIS_IMMEDIATE__w_halfI) 7)) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__GEN_CIS_IMMEDIATE__w_halfI) 7))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__GEN_CIS_IMMEDIATE__w_halfI) 7)) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__GEN_CIS_IMMEDIATE__w_halfI) 7)))))) (s.instruction_decoder__GEN_CIS_IMMEDIATE__w_halfI) else s.instruction_decoder__w_fullI)
  { s with
    instruction_decoder__w_I := instruction_decoder__w_I
  }

/-- 组合逻辑：assign_instruction_decoder__w_Iz -/
def assign_instruction_decoder__w_Iz (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_Iz := decide ((s.instruction_decoder__w_I).toNat = (BitVec.ofNat 32 0).toNat)
  { s with
    instruction_decoder__w_Iz := instruction_decoder__w_Iz
  }

/-- 组合逻辑：assign_instruction_decoder__o_phase -/
def assign_instruction_decoder__o_phase (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__o_phase := s.instruction_decoder__GEN_CIS_PHASE__r_phase
  { s with
    instruction_decoder__o_phase := instruction_decoder__o_phase
  }

/-- 组合逻辑：assign_instruction_decoder__illegal_shift -/
def assign_instruction_decoder__illegal_shift (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__illegal_shift := false
  { s with
    instruction_decoder__illegal_shift := instruction_decoder__illegal_shift
  }

/-- 组合逻辑：assign_instruction_decoder__o_preA -/
def assign_instruction_decoder__o_preA (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__o_preA := s.instruction_decoder__w_dcdA
  { s with
    instruction_decoder__o_preA := instruction_decoder__o_preA
  }

/-- 组合逻辑：assign_instruction_decoder__o_preB -/
def assign_instruction_decoder__o_preB (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__o_preB := s.instruction_decoder__w_dcdB
  { s with
    instruction_decoder__o_preB := instruction_decoder__o_preB
  }

/-- 组合逻辑：assign_instruction_decoder__o_ljmp -/
def assign_instruction_decoder__o_ljmp (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__o_ljmp := s.instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_ljmp
  { s with
    instruction_decoder__o_ljmp := instruction_decoder__o_ljmp
  }

/-- 组合逻辑：assign_instruction_decoder__GEN_EARLY_BRANCH_LOGIC__w_add_to_pc -/
def assign_instruction_decoder__GEN_EARLY_BRANCH_LOGIC__w_add_to_pc (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__GEN_EARLY_BRANCH_LOGIC__w_add_to_pc := (((((!(s.instruction_decoder__o_phase) && (false || !(BitVec.getLsbD (s.instruction_decoder__i_instruction) 31))) && decide ((BitVec.extractLsb 30 27 (s.instruction_decoder__i_instruction)).toNat = (BitVec.ofNat 4 15).toNat)) && decide ((BitVec.extractLsb 26 22 (s.instruction_decoder__i_instruction)).toNat = (BitVec.ofNat 5 2).toNat)) && decide ((BitVec.extractLsb 21 19 (s.instruction_decoder__i_instruction)).toNat = (BitVec.ofNat 3 0).toNat)) && !(BitVec.getLsbD (s.instruction_decoder__i_instruction) 18))
  { s with
    instruction_decoder__GEN_EARLY_BRANCH_LOGIC__w_add_to_pc := instruction_decoder__GEN_EARLY_BRANCH_LOGIC__w_add_to_pc
  }

/-- 组合逻辑：assign_instruction_decoder__w_ljmp_dly -/
def assign_instruction_decoder__w_ljmp_dly (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_ljmp_dly := s.instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_ljmp
  { s with
    instruction_decoder__w_ljmp_dly := instruction_decoder__w_ljmp_dly
  }

/-- 组合逻辑：assign_instruction_decoder__o_early_branch -/
def assign_instruction_decoder__o_early_branch (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__o_early_branch := s.instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_early_branch
  { s with
    instruction_decoder__o_early_branch := instruction_decoder__o_early_branch
  }

/-- 组合逻辑：assign_instruction_decoder__o_early_branch_stb -/
def assign_instruction_decoder__o_early_branch_stb (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__o_early_branch_stb := s.instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_early_branch_stb
  { s with
    instruction_decoder__o_early_branch_stb := instruction_decoder__o_early_branch_stb
  }

/-- 组合逻辑：assign_instruction_decoder__o_branch_pc -/
def assign_instruction_decoder__o_branch_pc (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__o_branch_pc := s.instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_branch_pc
  { s with
    instruction_decoder__o_branch_pc := instruction_decoder__o_branch_pc
  }

/-- 组合逻辑：assign_instruction_decoder__insn_is_pipeable -/
def assign_instruction_decoder__insn_is_pipeable (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__insn_is_pipeable := s.instruction_decoder__GEN_OPIPE__r_insn_is_pipeable
  { s with
    instruction_decoder__insn_is_pipeable := instruction_decoder__insn_is_pipeable
  }

/-- 组合逻辑：assign_instruction_decoder__o_pipe -/
def assign_instruction_decoder__o_pipe (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__o_pipe := s.instruction_decoder__GEN_OPIPE__r_pipe
  { s with
    instruction_decoder__o_pipe := instruction_decoder__o_pipe
  }

/-- 组合逻辑：assign_instruction_decoder__o_valid -/
def assign_instruction_decoder__o_valid (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__o_valid := s.instruction_decoder__r_valid
  { s with
    instruction_decoder__o_valid := instruction_decoder__o_valid
  }

/-- 组合逻辑：assign_instruction_decoder__o_I -/
def assign_instruction_decoder__o_I (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__o_I := BitVec.append (n := 10) (m := 22) (BitVec.append (n := 5) (m := 5) (BitVec.append (n := 2) (m := 3) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__r_I) 22)) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__r_I) 22))) (BitVec.append (n := 1) (m := 2) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__r_I) 22)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__r_I) 22)) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__r_I) 22))))) (BitVec.append (n := 2) (m := 3) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__r_I) 22)) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__r_I) 22))) (BitVec.append (n := 1) (m := 2) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__r_I) 22)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__r_I) 22)) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__r_I) 22)))))) (BitVec.extractLsb 21 0 (s.instruction_decoder__r_I))
  { s with
    instruction_decoder__o_I := instruction_decoder__o_I
  }

/-- 组合逻辑：assign_instruction_decoder__possibly_unused -/
def assign_instruction_decoder__possibly_unused (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__possibly_unused := BitVec.getLsbD (BitVec.extractLsb 8 0 (BitVec.extractLsb 8 0 (boolToBitVec (bvReduceAnd (BitVec.append (n := 4) (m := 5) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (s.instruction_decoder__w_lock))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instruction_decoder__w_ljmp)) (boolToBitVec (s.instruction_decoder__w_ljmp_dly)))) (BitVec.append (n := 2) (m := 3) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instruction_decoder__insn_is_pipeable)) (boolToBitVec (s.instruction_decoder__w_cis_ljmp))) (BitVec.append (n := 2) (m := 1) (BitVec.extractLsb 1 0 (s.instruction_decoder__i_pc)) (boolToBitVec (s.instruction_decoder__w_add))))))))) 0
  { s with
    instruction_decoder__possibly_unused := instruction_decoder__possibly_unused
  }

/-- 组合逻辑：assign_dcd_Rcc -/
def assign_dcd_Rcc (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_Rcc := BitVec.getLsbD (BitVec.extractLsb 6 0 ((if ((!(false) || s.dcd_valid) || !(true)) then BitVec.extractLsb 6 0 (BitVec.extractLsb 6 0 (BitVec.extractLsb 6 0 (s.dcd_full_R))) else BitVec.extractLsb 6 0 (BitVec.ofNat 7 0)))) 6
  { s with
    dcd_Rcc := dcd_Rcc
  }

/-- 组合逻辑：assign_dcd_Rpc -/
def assign_dcd_Rpc (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_Rpc := BitVec.getLsbD (BitVec.extractLsb 6 0 ((if ((!(false) || s.dcd_valid) || !(true)) then BitVec.extractLsb 6 0 (BitVec.extractLsb 6 0 (BitVec.extractLsb 6 0 (s.dcd_full_R))) else BitVec.extractLsb 6 0 (BitVec.ofNat 7 0)))) 5
  { s with
    dcd_Rpc := dcd_Rpc
  }

/-- 组合逻辑：assign_dcd_R -/
def assign_dcd_R (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_R := BitVec.extractLsb 4 0 (BitVec.extractLsb 6 0 ((if ((!(false) || s.dcd_valid) || !(true)) then BitVec.extractLsb 6 0 (BitVec.extractLsb 6 0 (BitVec.extractLsb 6 0 (s.dcd_full_R))) else BitVec.extractLsb 6 0 (BitVec.ofNat 7 0))))
  { s with
    dcd_R := dcd_R
  }

/-- 组合逻辑：assign_dcd_Acc -/
def assign_dcd_Acc (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_Acc := BitVec.getLsbD (BitVec.extractLsb 6 0 ((if ((!(false) || s.dcd_valid) || !(true)) then BitVec.extractLsb 6 0 (BitVec.extractLsb 6 0 (BitVec.extractLsb 6 0 (s.dcd_full_A))) else BitVec.extractLsb 6 0 (BitVec.ofNat 7 0)))) 6
  { s with
    dcd_Acc := dcd_Acc
  }

/-- 组合逻辑：assign_dcd_Apc -/
def assign_dcd_Apc (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_Apc := BitVec.getLsbD (BitVec.extractLsb 6 0 ((if ((!(false) || s.dcd_valid) || !(true)) then BitVec.extractLsb 6 0 (BitVec.extractLsb 6 0 (BitVec.extractLsb 6 0 (s.dcd_full_A))) else BitVec.extractLsb 6 0 (BitVec.ofNat 7 0)))) 5
  { s with
    dcd_Apc := dcd_Apc
  }

/-- 组合逻辑：assign_dcd_A -/
def assign_dcd_A (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_A := BitVec.extractLsb 4 0 (BitVec.extractLsb 6 0 ((if ((!(false) || s.dcd_valid) || !(true)) then BitVec.extractLsb 6 0 (BitVec.extractLsb 6 0 (BitVec.extractLsb 6 0 (s.dcd_full_A))) else BitVec.extractLsb 6 0 (BitVec.ofNat 7 0))))
  { s with
    dcd_A := dcd_A
  }

/-- 组合逻辑：assign_dcd_Bcc -/
def assign_dcd_Bcc (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_Bcc := BitVec.getLsbD (BitVec.extractLsb 6 0 ((if ((!(false) || s.dcd_valid) || !(true)) then BitVec.extractLsb 6 0 (BitVec.extractLsb 6 0 (BitVec.extractLsb 6 0 (s.dcd_full_B))) else BitVec.extractLsb 6 0 (BitVec.ofNat 7 0)))) 6
  { s with
    dcd_Bcc := dcd_Bcc
  }

/-- 组合逻辑：assign_dcd_Bpc -/
def assign_dcd_Bpc (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_Bpc := BitVec.getLsbD (BitVec.extractLsb 6 0 ((if ((!(false) || s.dcd_valid) || !(true)) then BitVec.extractLsb 6 0 (BitVec.extractLsb 6 0 (BitVec.extractLsb 6 0 (s.dcd_full_B))) else BitVec.extractLsb 6 0 (BitVec.ofNat 7 0)))) 5
  { s with
    dcd_Bpc := dcd_Bpc
  }

/-- 组合逻辑：assign_dcd_B -/
def assign_dcd_B (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_B := BitVec.extractLsb 4 0 (BitVec.extractLsb 6 0 ((if ((!(false) || s.dcd_valid) || !(true)) then BitVec.extractLsb 6 0 (BitVec.extractLsb 6 0 (BitVec.extractLsb 6 0 (s.dcd_full_B))) else BitVec.extractLsb 6 0 (BitVec.ofNat 7 0))))
  { s with
    dcd_B := dcd_B
  }

/-- 组合逻辑：assign_dcd_gie -/
def assign_dcd_gie (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_gie := s.pf_gie
  { s with
    dcd_gie := dcd_gie
  }

/-- 组合逻辑：assign_op_pipe -/
def assign_op_pipe (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let op_pipe := s.GEN_OP_PIPE__r_op_pipe
  { s with
    op_pipe := op_pipe
  }

/-- 组合逻辑：assign_w_op_Av -/
def assign_w_op_Av (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let w_op_Av := (if ((!(false) || s.dcd_valid) || !(true)) then bvArrayRead 32 32 0 31 (s.regset) ((s.dcd_A).toNat) else BitVec.ofNat 32 0)
  { s with
    w_op_Av := w_op_Av
  }

/-- 组合逻辑：assign_w_op_Bv -/
def assign_w_op_Bv (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let w_op_Bv := (if ((!(false) || s.dcd_valid) || !(true)) then bvArrayRead 32 32 0 31 (s.regset) ((s.dcd_B).toNat) else BitVec.ofNat 32 0)
  { s with
    w_op_Bv := w_op_Bv
  }

/-- 组合逻辑：assign_GEN_DISTRIBUTED_REGS__unused_prereg_addrs -/
def assign_GEN_DISTRIBUTED_REGS__unused_prereg_addrs (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let GEN_DISTRIBUTED_REGS__unused_prereg_addrs := BitVec.getLsbD (BitVec.extractLsb 10 0 (BitVec.extractLsb 10 0 (boolToBitVec (bvReduceAnd (BitVec.append (n := 1) (m := 10) (boolToBitVec (false)) (BitVec.append (n := 5) (m := 5) (s.dcd_preA) (s.dcd_preB))))))) 0
  { s with
    GEN_DISTRIBUTED_REGS__unused_prereg_addrs := GEN_DISTRIBUTED_REGS__unused_prereg_addrs
  }

/-- 组合逻辑：assign_w_cpu_info -/
def assign_w_cpu_info (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let w_cpu_info := BitVec.append (n := 4) (m := 5) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (true)) (boolToBitVec ((if decide (((BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (BitVec.ofNat 32 0)) ^^^ BitVec.ofNat 32 2147483648)).toNat > ((BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (BitVec.ofNat 32 0)) ^^^ BitVec.ofNat 32 2147483648)).toNat) then true else false)))) (BitVec.append (n := 1) (m := 1) (boolToBitVec ((if decide ((BitVec.ofNat 32 1).toNat > (BitVec.ofNat 32 0).toNat) then true else false))) (boolToBitVec ((if decide ((BitVec.ofNat 32 0).toNat > (BitVec.ofNat 32 0).toNat) then true else false))))) (BitVec.append (n := 2) (m := 3) (BitVec.append (n := 1) (m := 1) (boolToBitVec (true)) (boolToBitVec (false))) (BitVec.append (n := 1) (m := 2) (boolToBitVec ((if decide ((BitVec.ofNat 32 1).toNat > (BitVec.ofNat 32 0).toNat) then true else false))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (true)) (boolToBitVec (true)))))
  { s with
    w_cpu_info := w_cpu_info
  }

/-- 组合逻辑：assign_op_R -/
def assign_op_R (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let op_R := s.OP_REG_ADVANEC__r_op_R
  { s with
    op_R := op_R
  }

/-- 组合逻辑：assign_op_Aid -/
def assign_op_Aid (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let op_Aid := s.OP_REG_ADVANEC__r_op_Aid
  { s with
    op_Aid := op_Aid
  }

/-- 组合逻辑：assign_op_Bid -/
def assign_op_Bid (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let op_Bid := s.OP_REG_ADVANEC__r_op_Bid
  { s with
    op_Bid := op_Bid
  }

/-- 组合逻辑：assign_op_rA -/
def assign_op_rA (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let op_rA := s.OP_REG_ADVANEC__r_op_rA
  { s with
    op_rA := op_rA
  }

/-- 组合逻辑：assign_op_rB -/
def assign_op_rB (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let op_rB := s.OP_REG_ADVANEC__r_op_rB
  { s with
    op_rB := op_rB
  }

/-- 组合逻辑：assign_op_F -/
def assign_op_F (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let op_F := BitVec.append (n := 1) (m := 7) (boolToBitVec (BitVec.getLsbD (s.r_op_F) 3)) (BitVec.extractLsb 6 0 (s.r_op_F))
  { s with
    op_F := op_F
  }

/-- 组合逻辑：assign_w_op_valid -/
def assign_w_op_valid (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let w_op_valid := (((!(s.clear_pipeline) && s.dcd_valid) && !(s.dcd_ljmp)) && !(s.dcd_early_branch))
  { s with
    w_op_valid := w_op_valid
  }

/-- 组合逻辑：assign_op_lowpower_clear -/
def assign_op_lowpower_clear (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let op_lowpower_clear := false
  { s with
    op_lowpower_clear := op_lowpower_clear
  }

/-- 组合逻辑：assign_op_break -/
def assign_op_break (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let op_break := s.r_op_break
  { s with
    op_break := op_break
  }

/-- 组合逻辑：assign_op_lock -/
def assign_op_lock (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let op_lock := s.GEN_OPLOCK__r_op_lock
  { s with
    op_lock := op_lock
  }

/-- 组合逻辑：assign_op_wR -/
def assign_op_wR (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let op_wR := s.GEN_OP_WR__r_op_wR
  { s with
    op_wR := op_wR
  }

/-- 组合逻辑：assign_op_sim -/
def assign_op_sim (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let op_sim := BitVec.getLsbD (BitVec.ofNat 32 0) 0
  { s with
    op_sim := op_sim
  }

/-- 组合逻辑：assign_op_sim_immv -/
def assign_op_sim_immv (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let op_sim_immv := BitVec.extractLsb 22 0 (BitVec.ofNat 32 0)
  { s with
    op_sim_immv := op_sim_immv
  }

/-- 组合逻辑：assign_NO_OP_SIM__op_sim_unused -/
def assign_NO_OP_SIM__op_sim_unused (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let NO_OP_SIM__op_sim_unused := BitVec.getLsbD (BitVec.extractLsb 24 0 (BitVec.extractLsb 24 0 (boolToBitVec (bvReduceAnd (BitVec.append (n := 1) (m := 24) (boolToBitVec (false)) (BitVec.append (n := 1) (m := 23) (boolToBitVec (s.dcd_sim)) (s.dcd_sim_immv))))))) 0
  { s with
    NO_OP_SIM__op_sim_unused := NO_OP_SIM__op_sim_unused
  }

/-- 组合逻辑：assign_op_pc -/
def assign_op_pc (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let op_pc := s.SET_OP_PC__r_op_pc
  { s with
    op_pc := op_pc
  }

/-- 组合逻辑：assign_op_opn -/
def assign_op_opn (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let op_opn := s.FWD_OPERATION__r_op_opn
  { s with
    op_opn := op_opn
  }

/-- 组合逻辑：assign_op_gie -/
def assign_op_gie (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let op_gie := s.gie
  { s with
    op_gie := op_gie
  }

/-- 组合逻辑：assign_op_Fl -/
def assign_op_Fl (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let op_Fl := (if s.op_gie then BitVec.extractLsb 3 0 (s.w_uflags) else BitVec.extractLsb 3 0 (s.w_iflags))
  { s with
    op_Fl := op_Fl
  }

/-- 组合逻辑：assign_op_phase -/
def assign_op_phase (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let op_phase := s.OPT_CIS_OP_PHASE__r_op_phase
  { s with
    op_phase := op_phase
  }

/-- 组合逻辑：assign_op_Av -/
def assign_op_Av (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let op_Av := (if (s.wr_reg_ce && decide ((s.wr_reg_id).toNat = (s.op_Aid).toNat)) then s.wr_gpreg_vl else s.r_op_Av)
  { s with
    op_Av := op_Av
  }

/-- 组合逻辑：assign_dcd_A_stall -/
def assign_dcd_A_stall (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_A_stall := (((s.dcd_rA && (((s.op_valid || i.i_mem_rdbusy) || s.div_busy) || s.fpu_busy)) && ((s.op_wF || s.cc_invalid_for_dcd) && s.dcd_Acc)) || ((s.dcd_rA && s.dcd_Acc) && s.cc_invalid_for_dcd))
  { s with
    dcd_A_stall := dcd_A_stall
  }

/-- 组合逻辑：assign_op_Bv -/
def assign_op_Bv (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let op_Bv := (if (((true && s.wr_reg_ce) && decide ((s.wr_reg_id).toNat = (s.op_Bid).toNat)) && s.op_rB) then s.wr_gpreg_vl else s.r_op_Bv)
  { s with
    op_Bv := op_Bv
  }

/-- 组合逻辑：assign_dcd_B_stall -/
def assign_dcd_B_stall (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_B_stall := (((s.dcd_rB && ((((s.op_valid || i.i_mem_rdbusy) || s.div_busy) || s.fpu_busy) || s.alu_busy)) && ((!(s.dcd_zI) && ((((decide ((s.op_R).toNat = (s.dcd_B).toNat) && s.op_wR) || (i.i_mem_rdbusy && !(s.dcd_pipe))) || (((s.alu_busy || s.div_busy) || i.i_mem_rdbusy) && decide ((s.alu_reg).toNat = (s.dcd_B).toNat))) || (s.wr_reg_ce && decide ((BitVec.extractLsb 3 1 (s.wr_reg_id)).toNat = (BitVec.ofNat 3 7).toNat)))) || ((s.op_wF || s.cc_invalid_for_dcd) && s.dcd_Bcc))) || ((s.dcd_rB && s.dcd_Bcc) && s.cc_invalid_for_dcd))
  { s with
    dcd_B_stall := dcd_B_stall
  }

/-- 组合逻辑：assign_dcd_F_stall -/
def assign_dcd_F_stall (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_F_stall := (((!(BitVec.getLsbD (s.dcd_F) 3) || ((s.dcd_rA && decide ((BitVec.extractLsb 3 1 (s.dcd_A)).toNat = (BitVec.ofNat 3 7).toNat)) && decide ((BitVec.extractLsb 4 0 (s.dcd_A)).toNat ≠ (BitVec.append (n := 1) (m := 4) (boolToBitVec (s.gie)) (BitVec.ofNat 4 15)).toNat))) || ((s.dcd_rB && decide ((BitVec.extractLsb 3 1 (s.dcd_B)).toNat = (BitVec.ofNat 3 7).toNat)) && decide ((BitVec.extractLsb 4 0 (s.dcd_B)).toNat ≠ (BitVec.append (n := 1) (m := 4) (boolToBitVec (s.gie)) (BitVec.ofNat 4 15)).toNat))) && ((((s.op_valid && s.op_wR) && decide ((BitVec.extractLsb 3 1 (s.op_R)).toNat = (BitVec.ofNat 3 7).toNat)) && decide ((BitVec.extractLsb 4 0 (s.op_R)).toNat ≠ (BitVec.append (n := 1) (m := 4) (boolToBitVec (s.gie)) (BitVec.ofNat 4 15)).toNat)) || s.pending_sreg_write))
  { s with
    dcd_F_stall := dcd_F_stall
  }

/-- 组合逻辑：assign_doalu__i_clk -/
def assign_doalu__i_clk (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__i_clk := i.i_clk
  { s with
    doalu__i_clk := doalu__i_clk
  }

/-- 组合逻辑：assign_doalu__i_reset -/
def assign_doalu__i_reset (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__i_reset := (i.i_reset || s.clear_pipeline)
  { s with
    doalu__i_reset := doalu__i_reset
  }

/-- 组合逻辑：assign_doalu__i_stb -/
def assign_doalu__i_stb (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__i_stb := s.alu_ce
  { s with
    doalu__i_stb := doalu__i_stb
  }

/-- 组合逻辑：assign_doalu__i_op -/
def assign_doalu__i_op (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__i_op := (if (!(false) || s.alu_ce) then s.op_opn else BitVec.ofNat 4 0)
  { s with
    doalu__i_op := doalu__i_op
  }

/-- 组合逻辑：assign_doalu__i_a -/
def assign_doalu__i_a (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__i_a := (if (!(false) || s.alu_ce) then s.op_Av else BitVec.ofNat 32 0)
  { s with
    doalu__i_a := doalu__i_a
  }

/-- 组合逻辑：assign_doalu__i_b -/
def assign_doalu__i_b (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__i_b := (if (!(false) || s.alu_ce) then s.op_Bv else BitVec.ofNat 32 0)
  { s with
    doalu__i_b := doalu__i_b
  }

/-- 组合逻辑：assign_alu_result -/
def assign_alu_result (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let alu_result := s.doalu__o_c
  { s with
    alu_result := alu_result
  }

/-- 组合逻辑：assign_alu_flags -/
def assign_alu_flags (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let alu_flags := s.doalu__o_f
  { s with
    alu_flags := alu_flags
  }

/-- 组合逻辑：assign_alu_valid -/
def assign_alu_valid (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let alu_valid := s.doalu__o_valid
  { s with
    alu_valid := alu_valid
  }

/-- 组合逻辑：assign_alu_busy -/
def assign_alu_busy (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let alu_busy := s.doalu__o_busy
  { s with
    alu_busy := alu_busy
  }

/-- 组合逻辑：assign_doalu__IMPLEMENT_SHIFTS__w_pre_asr_input -/
def assign_doalu__IMPLEMENT_SHIFTS__w_pre_asr_input (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__IMPLEMENT_SHIFTS__w_pre_asr_input := BitVec.append (n := 32) (m := 1) (s.doalu__i_a) (boolToBitVec (false))
  { s with
    doalu__IMPLEMENT_SHIFTS__w_pre_asr_input := doalu__IMPLEMENT_SHIFTS__w_pre_asr_input
  }

/-- 组合逻辑：assign_doalu__IMPLEMENT_SHIFTS__w_pre_asr_shifted -/
def assign_doalu__IMPLEMENT_SHIFTS__w_pre_asr_shifted (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__IMPLEMENT_SHIFTS__w_pre_asr_shifted := BitVec.sshiftRight (s.doalu__IMPLEMENT_SHIFTS__w_pre_asr_input) (BitVec.extractLsb 4 0 (s.doalu__i_b)).toNat
  { s with
    doalu__IMPLEMENT_SHIFTS__w_pre_asr_shifted := doalu__IMPLEMENT_SHIFTS__w_pre_asr_shifted
  }

/-- 组合逻辑：assign_doalu__w_asr_result -/
def assign_doalu__w_asr_result (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__w_asr_result := (if bvNonzero (BitVec.extractLsb 31 5 (s.doalu__i_b)) then BitVec.append (n := 16) (m := 17) (BitVec.append (n := 8) (m := 8) (BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31)) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31)) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31)) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31)) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31))))) (BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31)) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31)) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31)) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31)) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31)))))) (BitVec.append (n := 8) (m := 9) (BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31)) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31)) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31)) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31)) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31))))) (BitVec.append (n := 4) (m := 5) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31)) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31)) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31)))) (BitVec.append (n := 2) (m := 3) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31)) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31))) (BitVec.append (n := 1) (m := 2) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31)) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31))))))) else s.doalu__IMPLEMENT_SHIFTS__w_pre_asr_shifted)
  { s with
    doalu__w_asr_result := doalu__w_asr_result
  }

/-- 组合逻辑：assign_doalu__w_lsr_result -/
def assign_doalu__w_lsr_result (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__w_lsr_result := (if (bvNonzero (BitVec.extractLsb 31 6 (s.doalu__i_b)) || (BitVec.getLsbD (s.doalu__i_b) 5 && decide ((BitVec.extractLsb 4 0 (s.doalu__i_b)).toNat ≠ (BitVec.ofNat 32 0).toNat))) then BitVec.ofNat 33 0 else (if BitVec.getLsbD (s.doalu__i_b) 5 then BitVec.append (n := 32) (m := 1) (BitVec.ofNat 32 0) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 31)) else BitVec.ushiftRight (BitVec.append (n := 32) (m := 1) (s.doalu__i_a) (boolToBitVec (false))) (BitVec.extractLsb 4 0 (s.doalu__i_b)).toNat))
  { s with
    doalu__w_lsr_result := doalu__w_lsr_result
  }

/-- 组合逻辑：assign_doalu__w_lsl_result -/
def assign_doalu__w_lsl_result (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__w_lsl_result := (if (bvNonzero (BitVec.extractLsb 31 6 (s.doalu__i_b)) || (BitVec.getLsbD (s.doalu__i_b) 5 && decide ((BitVec.extractLsb 4 0 (s.doalu__i_b)).toNat ≠ (BitVec.ofNat 32 0).toNat))) then BitVec.ofNat 33 0 else (if BitVec.getLsbD (s.doalu__i_b) 5 then BitVec.append (n := 1) (m := 32) (boolToBitVec (BitVec.getLsbD (s.doalu__i_a) 0)) (BitVec.ofNat 32 0) else BitVec.shiftLeft (BitVec.append (n := 1) (m := 32) (boolToBitVec (false)) (s.doalu__i_a)) (BitVec.extractLsb 4 0 (s.doalu__i_b)).toNat))
  { s with
    doalu__w_lsl_result := doalu__w_lsl_result
  }

/-- 组合逻辑：assign_doalu__w_brev_result -/
def assign_doalu__w_brev_result (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__w_brev_result := BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.doalu__i_b) 0)) (boolToBitVec (BitVec.getLsbD (s.doalu__i_b) 1))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.doalu__i_b) 2)) (boolToBitVec (BitVec.getLsbD (s.doalu__i_b) 3)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.doalu__i_b) 4)) (boolToBitVec (BitVec.getLsbD (s.doalu__i_b) 5))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.doalu__i_b) 6)) (boolToBitVec (BitVec.getLsbD (s.doalu__i_b) 7))))) (BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.doalu__i_b) 8)) (boolToBitVec (BitVec.getLsbD (s.doalu__i_b) 9))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.doalu__i_b) 10)) (boolToBitVec (BitVec.getLsbD (s.doalu__i_b) 11)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.doalu__i_b) 12)) (boolToBitVec (BitVec.getLsbD (s.doalu__i_b) 13))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.doalu__i_b) 14)) (boolToBitVec (BitVec.getLsbD (s.doalu__i_b) 15)))))) (BitVec.append (n := 8) (m := 8) (BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.doalu__i_b) 16)) (boolToBitVec (BitVec.getLsbD (s.doalu__i_b) 17))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.doalu__i_b) 18)) (boolToBitVec (BitVec.getLsbD (s.doalu__i_b) 19)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.doalu__i_b) 20)) (boolToBitVec (BitVec.getLsbD (s.doalu__i_b) 21))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.doalu__i_b) 22)) (boolToBitVec (BitVec.getLsbD (s.doalu__i_b) 23))))) (BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.doalu__i_b) 24)) (boolToBitVec (BitVec.getLsbD (s.doalu__i_b) 25))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.doalu__i_b) 26)) (boolToBitVec (BitVec.getLsbD (s.doalu__i_b) 27)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.doalu__i_b) 28)) (boolToBitVec (BitVec.getLsbD (s.doalu__i_b) 29))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.doalu__i_b) 30)) (boolToBitVec (BitVec.getLsbD (s.doalu__i_b) 31))))))
  { s with
    doalu__w_brev_result := doalu__w_brev_result
  }

/-- 组合逻辑：assign_doalu__this_is_a_multiply_op -/
def assign_doalu__this_is_a_multiply_op (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__this_is_a_multiply_op := (s.doalu__i_stb && (decide ((BitVec.extractLsb 3 1 (s.doalu__i_op)).toNat = (BitVec.ofNat 3 5).toNat) || decide ((BitVec.extractLsb 3 0 (s.doalu__i_op)).toNat = (BitVec.ofNat 4 12).toNat)))
  { s with
    doalu__this_is_a_multiply_op := doalu__this_is_a_multiply_op
  }

/-- 组合逻辑：assign_doalu__thempy__i_clk -/
def assign_doalu__thempy__i_clk (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__thempy__i_clk := s.doalu__i_clk
  { s with
    doalu__thempy__i_clk := doalu__thempy__i_clk
  }

/-- 组合逻辑：assign_doalu__thempy__i_reset -/
def assign_doalu__thempy__i_reset (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__thempy__i_reset := s.doalu__i_reset
  { s with
    doalu__thempy__i_reset := doalu__thempy__i_reset
  }

/-- 组合逻辑：assign_doalu__thempy__i_stb -/
def assign_doalu__thempy__i_stb (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__thempy__i_stb := s.doalu__this_is_a_multiply_op
  { s with
    doalu__thempy__i_stb := doalu__thempy__i_stb
  }

/-- 组合逻辑：assign_doalu__thempy__i_op -/
def assign_doalu__thempy__i_op (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__thempy__i_op := BitVec.extractLsb 1 0 (s.doalu__i_op)
  { s with
    doalu__thempy__i_op := doalu__thempy__i_op
  }

/-- 组合逻辑：assign_doalu__thempy__i_a -/
def assign_doalu__thempy__i_a (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__thempy__i_a := s.doalu__i_a
  { s with
    doalu__thempy__i_a := doalu__thempy__i_a
  }

/-- 组合逻辑：assign_doalu__thempy__i_b -/
def assign_doalu__thempy__i_b (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__thempy__i_b := s.doalu__i_b
  { s with
    doalu__thempy__i_b := doalu__thempy__i_b
  }

/-- 组合逻辑：assign_doalu__mpydone -/
def assign_doalu__mpydone (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__mpydone := s.doalu__thempy__o_valid
  { s with
    doalu__mpydone := doalu__mpydone
  }

/-- 组合逻辑：assign_doalu__mpybusy -/
def assign_doalu__mpybusy (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__mpybusy := s.doalu__thempy__o_busy
  { s with
    doalu__mpybusy := doalu__mpybusy
  }

/-- 组合逻辑：assign_doalu__mpy_result -/
def assign_doalu__mpy_result (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__mpy_result := s.doalu__thempy__o_result
  { s with
    doalu__mpy_result := doalu__mpy_result
  }

/-- 组合逻辑：assign_doalu__mpyhi -/
def assign_doalu__mpyhi (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__mpyhi := s.doalu__thempy__o_hi
  { s with
    doalu__mpyhi := doalu__mpyhi
  }

/-- 组合逻辑：assign_doalu__thempy__o_result -/
def assign_doalu__thempy__o_result (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__thempy__o_result := BitVec.ofNat 64 0
  { s with
    doalu__thempy__o_result := doalu__thempy__o_result
  }

/-- 组合逻辑：assign_doalu__thempy__o_busy -/
def assign_doalu__thempy__o_busy (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__thempy__o_busy := false
  { s with
    doalu__thempy__o_busy := doalu__thempy__o_busy
  }

/-- 组合逻辑：assign_doalu__thempy__o_valid -/
def assign_doalu__thempy__o_valid (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__thempy__o_valid := s.doalu__thempy__i_stb
  { s with
    doalu__thempy__o_valid := doalu__thempy__o_valid
  }

/-- 组合逻辑：assign_doalu__thempy__o_hi -/
def assign_doalu__thempy__o_hi (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__thempy__o_hi := false
  { s with
    doalu__thempy__o_hi := doalu__thempy__o_hi
  }

/-- 组合逻辑：assign_doalu__o_busy -/
def assign_doalu__o_busy (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__o_busy := s.doalu__r_busy
  { s with
    doalu__o_busy := doalu__o_busy
  }

/-- 组合逻辑：assign_doalu__z -/
def assign_doalu__z (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__z := decide ((s.doalu__o_c).toNat = (BitVec.ofNat 32 0).toNat)
  { s with
    doalu__z := doalu__z
  }

/-- 组合逻辑：assign_doalu__n -/
def assign_doalu__n (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__n := BitVec.getLsbD (s.doalu__o_c) 31
  { s with
    doalu__n := doalu__n
  }

/-- 组合逻辑：assign_doalu__v -/
def assign_doalu__v (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__v := (s.doalu__set_ovfl && decide (boolToNat (s.doalu__pre_sign) ≠ boolToNat (BitVec.getLsbD (s.doalu__o_c) 31)))
  { s with
    doalu__v := doalu__v
  }

/-- 组合逻辑：assign_doalu__vx -/
def assign_doalu__vx (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__vx := (s.doalu__keep_sgn_on_ovfl && decide (boolToNat (s.doalu__pre_sign) ≠ boolToNat (BitVec.getLsbD (s.doalu__o_c) 31)))
  { s with
    doalu__vx := doalu__vx
  }

/-- 组合逻辑：assign_doalu__o_f -/
def assign_doalu__o_f (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let doalu__o_f := BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.doalu__v)) (boolToBitVec (Bool.xor (s.doalu__n) (s.doalu__vx)))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.doalu__c)) (boolToBitVec (s.doalu__z)))
  { s with
    doalu__o_f := doalu__o_f
  }

/-- 组合逻辑：assign_DIVIDE__thedivide__i_clk -/
def assign_DIVIDE__thedivide__i_clk (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let DIVIDE__thedivide__i_clk := i.i_clk
  { s with
    DIVIDE__thedivide__i_clk := DIVIDE__thedivide__i_clk
  }

/-- 组合逻辑：assign_DIVIDE__thedivide__i_reset -/
def assign_DIVIDE__thedivide__i_reset (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let DIVIDE__thedivide__i_reset := (i.i_reset || s.clear_pipeline)
  { s with
    DIVIDE__thedivide__i_reset := DIVIDE__thedivide__i_reset
  }

/-- 组合逻辑：assign_DIVIDE__thedivide__i_wr -/
def assign_DIVIDE__thedivide__i_wr (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let DIVIDE__thedivide__i_wr := s.div_ce
  { s with
    DIVIDE__thedivide__i_wr := DIVIDE__thedivide__i_wr
  }

/-- 组合逻辑：assign_DIVIDE__thedivide__i_signed -/
def assign_DIVIDE__thedivide__i_signed (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let DIVIDE__thedivide__i_signed := BitVec.getLsbD (s.op_opn) 0
  { s with
    DIVIDE__thedivide__i_signed := DIVIDE__thedivide__i_signed
  }

/-- 组合逻辑：assign_DIVIDE__thedivide__i_numerator -/
def assign_DIVIDE__thedivide__i_numerator (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let DIVIDE__thedivide__i_numerator := s.op_Av
  { s with
    DIVIDE__thedivide__i_numerator := DIVIDE__thedivide__i_numerator
  }

/-- 组合逻辑：assign_DIVIDE__thedivide__i_denominator -/
def assign_DIVIDE__thedivide__i_denominator (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let DIVIDE__thedivide__i_denominator := s.op_Bv
  { s with
    DIVIDE__thedivide__i_denominator := DIVIDE__thedivide__i_denominator
  }

/-- 组合逻辑：assign_div_busy -/
def assign_div_busy (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let div_busy := s.DIVIDE__thedivide__o_busy
  { s with
    div_busy := div_busy
  }

/-- 组合逻辑：assign_div_valid -/
def assign_div_valid (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let div_valid := s.DIVIDE__thedivide__o_valid
  { s with
    div_valid := div_valid
  }

/-- 组合逻辑：assign_div_error -/
def assign_div_error (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let div_error := s.DIVIDE__thedivide__o_err
  { s with
    div_error := div_error
  }

/-- 组合逻辑：assign_div_result -/
def assign_div_result (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let div_result := s.DIVIDE__thedivide__o_quotient
  { s with
    div_result := div_result
  }

/-- 组合逻辑：assign_div_flags -/
def assign_div_flags (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let div_flags := s.DIVIDE__thedivide__o_flags
  { s with
    div_flags := div_flags
  }

/-- 组合逻辑：assign_DIVIDE__thedivide__diff -/
def assign_DIVIDE__thedivide__diff (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let DIVIDE__thedivide__diff := BitVec.extractLsb 32 0 ((BitVec.extractLsb 32 0 (BitVec.append (n := 1) (m := 32) (boolToBitVec (false)) (BitVec.extractLsb 31 0 (BitVec.extractLsb 62 31 (s.DIVIDE__thedivide__r_dividend)))) - BitVec.extractLsb 32 0 (BitVec.append (n := 1) (m := 32) (boolToBitVec (false)) (BitVec.extractLsb 31 0 (s.DIVIDE__thedivide__r_divisor)))))
  { s with
    DIVIDE__thedivide__diff := DIVIDE__thedivide__diff
  }

/-- 组合逻辑：assign_DIVIDE__thedivide__w_n -/
def assign_DIVIDE__thedivide__w_n (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let DIVIDE__thedivide__w_n := BitVec.getLsbD (s.DIVIDE__thedivide__o_quotient) 31
  { s with
    DIVIDE__thedivide__w_n := DIVIDE__thedivide__w_n
  }

/-- 组合逻辑：assign_DIVIDE__thedivide__o_flags -/
def assign_DIVIDE__thedivide__o_flags (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let DIVIDE__thedivide__o_flags := BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (s.DIVIDE__thedivide__w_n))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.DIVIDE__thedivide__r_c)) (boolToBitVec (s.DIVIDE__thedivide__r_z)))
  { s with
    DIVIDE__thedivide__o_flags := DIVIDE__thedivide__o_flags
  }

/-- 组合逻辑：assign_fpu_error -/
def assign_fpu_error (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let fpu_error := false
  { s with
    fpu_error := fpu_error
  }

/-- 组合逻辑：assign_fpu_busy -/
def assign_fpu_busy (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let fpu_busy := false
  { s with
    fpu_busy := fpu_busy
  }

/-- 组合逻辑：assign_fpu_valid -/
def assign_fpu_valid (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let fpu_valid := false
  { s with
    fpu_valid := fpu_valid
  }

/-- 组合逻辑：assign_fpu_result -/
def assign_fpu_result (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let fpu_result := BitVec.ofNat 32 0
  { s with
    fpu_result := fpu_result
  }

/-- 组合逻辑：assign_fpu_flags -/
def assign_fpu_flags (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let fpu_flags := BitVec.ofNat 4 0
  { s with
    fpu_flags := fpu_flags
  }

/-- 组合逻辑：assign_set_cond -/
def assign_set_cond (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let set_cond := decide (((BitVec.extractLsb 7 4 (s.op_F) &&& BitVec.extractLsb 3 0 (s.op_Fl))).toNat = (BitVec.extractLsb 3 0 (s.op_F)).toNat)
  { s with
    set_cond := set_cond
  }

/-- 组合逻辑：assign_alu_phase -/
def assign_alu_phase (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let alu_phase := s.GEN_ALU_PHASE__r_alu_phase
  { s with
    alu_phase := alu_phase
  }

/-- 组合逻辑：assign_alu_gie -/
def assign_alu_gie (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let alu_gie := s.gie
  { s with
    alu_gie := alu_gie
  }

/-- 组合逻辑：assign_alu_pc -/
def assign_alu_pc (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let alu_pc := s.GEN_ALU_PC__r_alu_pc
  { s with
    alu_pc := alu_pc
  }

/-- 组合逻辑：assign_alu_illegal -/
def assign_alu_illegal (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let alu_illegal := s.SET_ALU_ILLEGAL__r_alu_illegal
  { s with
    alu_illegal := alu_illegal
  }

/-- 组合逻辑：assign_alu_pc_valid -/
def assign_alu_pc_valid (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let alu_pc_valid := (s.r_alu_pc_valid && ((!(s.alu_busy) && !(s.div_busy)) && !(s.fpu_busy)))
  { s with
    alu_pc_valid := alu_pc_valid
  }

/-- 组合逻辑：assign_prelock_stall -/
def assign_prelock_stall (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let prelock_stall := (true && s.BUSLOCK__r_prelock_stall)
  { s with
    prelock_stall := prelock_stall
  }

/-- 组合逻辑：assign_o_bus_lock -/
def assign_o_bus_lock (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let o_bus_lock := BitVec.getLsbD (BitVec.extractLsb 1 0 (BitVec.extractLsb 1 0 (boolToBitVec (bvNonzero (s.BUSLOCK__r_bus_lock))))) 0
  { s with
    o_bus_lock := o_bus_lock
  }

/-- 组合逻辑：assign_o_mem_lock_pc -/
def assign_o_mem_lock_pc (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let o_mem_lock_pc := s.BUSLOCK__r_lock_pc
  { s with
    o_mem_lock_pc := o_mem_lock_pc
  }

/-- 组合逻辑：assign_last_lock_insn -/
def assign_last_lock_insn (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let last_lock_insn := decide ((s.BUSLOCK__r_bus_lock).toNat <= (BitVec.ofNat 32 1).toNat)
  { s with
    last_lock_insn := last_lock_insn
  }

/-- 组合逻辑：assign_o_mem_ce -/
def assign_o_mem_ce (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let o_mem_ce := (s.mem_ce && s.set_cond)
  { s with
    o_mem_ce := o_mem_ce
  }

/-- 组合逻辑：assign_o_mem_op -/
def assign_o_mem_op (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let o_mem_op := (if ((s.mem_ce && s.set_cond) || !(false)) then BitVec.extractLsb 2 0 (s.op_opn) else BitVec.ofNat 3 0)
  { s with
    o_mem_op := o_mem_op
  }

/-- 组合逻辑：assign_o_mem_data -/
def assign_o_mem_data (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let o_mem_data := (if ((s.mem_ce && s.set_cond) || !(false)) then s.op_Av else BitVec.ofNat 32 0)
  { s with
    o_mem_data := o_mem_data
  }

/-- 组合逻辑：assign_o_mem_addr -/
def assign_o_mem_addr (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let o_mem_addr := (if ((s.mem_ce && s.set_cond) || !(false)) then s.op_Bv else BitVec.ofNat 32 0)
  { s with
    o_mem_addr := o_mem_addr
  }

/-- 组合逻辑：assign_o_mem_reg -/
def assign_o_mem_reg (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let o_mem_reg := (if ((s.mem_ce && s.set_cond) || !(false)) then s.op_R else BitVec.ofNat 5 0)
  { s with
    o_mem_reg := o_mem_reg
  }

/-- 组合逻辑：assign_alu_sim -/
def assign_alu_sim (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let alu_sim := BitVec.getLsbD (BitVec.ofNat 32 0) 0
  { s with
    alu_sim := alu_sim
  }

/-- 组合逻辑：assign_alu_sim_immv -/
def assign_alu_sim_immv (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let alu_sim_immv := BitVec.extractLsb 22 0 (BitVec.ofNat 32 0)
  { s with
    alu_sim_immv := alu_sim_immv
  }

/-- 组合逻辑：assign_cpu_sim -/
def assign_cpu_sim (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let cpu_sim := BitVec.getLsbD (BitVec.ofNat 32 0) 0
  { s with
    cpu_sim := cpu_sim
  }

/-- 组合逻辑：assign_wr_reg_id -/
def assign_wr_reg_id (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let wr_reg_id := (if i.i_mem_valid then i.i_mem_wreg else s.alu_reg)
  { s with
    wr_reg_id := wr_reg_id
  }

/-- 组合逻辑：assign_wr_write_cc -/
def assign_wr_write_cc (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let wr_write_cc := decide ((BitVec.extractLsb 3 0 (s.wr_reg_id)).toNat = (BitVec.ofNat 4 14).toNat)
  { s with
    wr_write_cc := wr_write_cc
  }

/-- 组合逻辑：assign_wr_write_scc -/
def assign_wr_write_scc (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let wr_write_scc := decide ((BitVec.extractLsb 4 0 (s.wr_reg_id)).toNat = (BitVec.append (n := 1) (m := 4) (boolToBitVec (false)) (BitVec.ofNat 4 14)).toNat)
  { s with
    wr_write_scc := wr_write_scc
  }

/-- 组合逻辑：assign_wr_write_ucc -/
def assign_wr_write_ucc (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let wr_write_ucc := decide ((BitVec.extractLsb 4 0 (s.wr_reg_id)).toNat = (BitVec.append (n := 1) (m := 4) (boolToBitVec (true)) (BitVec.ofNat 4 14)).toNat)
  { s with
    wr_write_ucc := wr_write_ucc
  }

/-- 组合逻辑：assign_wr_write_pc -/
def assign_wr_write_pc (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let wr_write_pc := decide ((BitVec.extractLsb 3 0 (s.wr_reg_id)).toNat = (BitVec.ofNat 4 15).toNat)
  { s with
    wr_write_pc := wr_write_pc
  }

/-- 组合逻辑：assign_w_uflags -/
def assign_w_uflags (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let w_uflags := BitVec.append (n := 7) (m := 9) (BitVec.append (n := 4) (m := 3) (BitVec.append (n := 2) (m := 2) (BitVec.ofNat 2 0) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.uhalt_phase)) (boolToBitVec (s.ufpu_err_flag)))) (BitVec.append (n := 1) (m := 2) (boolToBitVec (s.udiv_err_flag)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.ubus_err_flag)) (boolToBitVec (s.trap))))) (BitVec.append (n := 3) (m := 6) (BitVec.append (n := 1) (m := 2) (boolToBitVec (s.ill_err_u)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.ubreak)) (boolToBitVec ((!(s.gie) && s.user_step))))) (BitVec.append (n := 1) (m := 5) (boolToBitVec (true)) (BitVec.append (n := 1) (m := 4) (boolToBitVec (s.sleep)) ((if (s.wr_flags_ce && s.alu_gie) then s.wr_flags else s.flags)))))
  { s with
    w_uflags := w_uflags
  }

/-- 组合逻辑：assign_w_iflags -/
def assign_w_iflags (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let w_iflags := BitVec.append (n := 7) (m := 9) (BitVec.append (n := 4) (m := 3) (BitVec.append (n := 2) (m := 2) (BitVec.ofNat 2 0) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.ihalt_phase)) (boolToBitVec (s.ifpu_err_flag)))) (BitVec.append (n := 1) (m := 2) (boolToBitVec (s.idiv_err_flag)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.ibus_err_flag)) (boolToBitVec (s.trap))))) (BitVec.append (n := 3) (m := 6) (BitVec.append (n := 1) (m := 2) (boolToBitVec (s.ill_err_i)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.break_en)) (boolToBitVec (false)))) (BitVec.append (n := 1) (m := 5) (boolToBitVec (false)) (BitVec.append (n := 1) (m := 4) (boolToBitVec (s.sleep)) ((if (s.wr_flags_ce && !(s.alu_gie)) then s.wr_flags else s.iflags)))))
  { s with
    w_iflags := w_iflags
  }

/-- 组合逻辑：assign_break_pending -/
def assign_break_pending (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let break_pending := s.GEN_PENDING_BREAK__r_break_pending
  { s with
    break_pending := break_pending
  }

/-- 组合逻辑：assign_o_break -/
def assign_o_break (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let o_break := ((((((((s.break_en || !(s.op_gie)) && s.break_pending) && !(s.clear_pipeline)) || s.ill_err_i) || (!(s.alu_gie) && i.i_bus_err)) || (!(s.alu_gie) && s.div_error)) || (!(s.alu_gie) && s.fpu_error)) || ((!(s.alu_gie) && s.alu_illegal) && !(s.clear_pipeline)))
  { s with
    o_break := o_break
  }

/-- 组合逻辑：assign_step -/
def assign_step (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let step := (s.user_step && s.gie)
  { s with
    step := step
  }

/-- 组合逻辑：assign_w_clken -/
def assign_w_clken (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let w_clken := s.GEN_CLOCK_GATE__r_clken
  { s with
    w_clken := w_clken
  }

/-- 组合逻辑：assign_o_clken -/
def assign_o_clken (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let o_clken := (((s.GEN_CLOCK_GATE__r_clken || (true && i.i_dbg_we)) || i.i_clear_cache) || (!(i.i_halt) && (i.i_interrupt || !(s.sleep))))
  { s with
    o_clken := o_clken
  }

/-- 组合逻辑：assign_pending_interrupt -/
def assign_pending_interrupt (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let pending_interrupt := (s.GEN_PENDING_INTERRUPT__r_pending_interrupt && !(i.i_halt))
  { s with
    pending_interrupt := pending_interrupt
  }

/-- 组合逻辑：assign_w_switch_to_interrupt -/
def assign_w_switch_to_interrupt (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let w_switch_to_interrupt := (s.gie && (((((((s.pending_interrupt && !(s.alu_phase)) && !(s.o_bus_lock)) && !(i.i_mem_busy)) || s.div_error) || s.fpu_error) || i.i_bus_err) || (((s.wr_reg_ce && !(BitVec.getLsbD (s.wr_spreg_vl) 5)) && BitVec.getLsbD (s.wr_reg_id) 4) && s.wr_write_cc)))
  { s with
    w_switch_to_interrupt := w_switch_to_interrupt
  }

/-- 组合逻辑：assign_w_release_from_interrupt -/
def assign_w_release_from_interrupt (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let w_release_from_interrupt := ((!(s.gie) && !(i.i_interrupt)) && ((s.wr_reg_ce && BitVec.getLsbD (s.wr_spreg_vl) 5) && s.wr_write_scc))
  { s with
    w_release_from_interrupt := w_release_from_interrupt
  }

/-- 组合逻辑：assign_stepped -/
def assign_stepped (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let stepped := s.GEN_PENDING_INTERRUPT__r_user_stepped
  { s with
    stepped := stepped
  }

/-- 组合逻辑：assign_gie -/
def assign_gie (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let gie := s.SET_GIE__r_gie
  { s with
    gie := gie
  }

/-- 组合逻辑：assign_trap -/
def assign_trap (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let trap := s.SET_TRAP_N_UBREAK__r_trap
  { s with
    trap := trap
  }

/-- 组合逻辑：assign_ubreak -/
def assign_ubreak (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let ubreak := s.SET_TRAP_N_UBREAK__r_ubreak
  { s with
    ubreak := ubreak
  }

/-- 组合逻辑：assign_ill_err_u -/
def assign_ill_err_u (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let ill_err_u := s.SET_USER_ILLEGAL_INSN__r_ill_err_u
  { s with
    ill_err_u := ill_err_u
  }

/-- 组合逻辑：assign_ubus_err_flag -/
def assign_ubus_err_flag (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let ubus_err_flag := s.SET_USER_BUSERR__r_ubus_err_flag
  { s with
    ubus_err_flag := ubus_err_flag
  }

/-- 组合逻辑：assign_idiv_err_flag -/
def assign_idiv_err_flag (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let idiv_err_flag := s.DIVERR__r_idiv_err_flag
  { s with
    idiv_err_flag := idiv_err_flag
  }

/-- 组合逻辑：assign_udiv_err_flag -/
def assign_udiv_err_flag (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let udiv_err_flag := s.DIVERR__USER_DIVERR__r_udiv_err_flag
  { s with
    udiv_err_flag := udiv_err_flag
  }

/-- 组合逻辑：assign_ifpu_err_flag -/
def assign_ifpu_err_flag (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let ifpu_err_flag := false
  { s with
    ifpu_err_flag := ifpu_err_flag
  }

/-- 组合逻辑：assign_ufpu_err_flag -/
def assign_ufpu_err_flag (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let ufpu_err_flag := false
  { s with
    ufpu_err_flag := ufpu_err_flag
  }

/-- 组合逻辑：assign_ihalt_phase -/
def assign_ihalt_phase (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let ihalt_phase := s.GEN_IHALT_PHASE__r_ihalt_phase
  { s with
    ihalt_phase := ihalt_phase
  }

/-- 组合逻辑：assign_uhalt_phase -/
def assign_uhalt_phase (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let uhalt_phase := s.GEN_UHALT_PHASE__r_uhalt_phase
  { s with
    uhalt_phase := uhalt_phase
  }

/-- 组合逻辑：assign_upc -/
def assign_upc (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let upc := s.SET_USER_PC__r_upc
  { s with
    upc := upc
  }

/-- 组合逻辑：assign_cc_write_hold -/
def assign_cc_write_hold (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let cc_write_hold := ((s.wr_reg_ce && s.wr_write_cc) || s.last_write_to_cc)
  { s with
    cc_write_hold := cc_write_hold
  }

/-- 组合逻辑：assign_o_clear_icache -/
def assign_o_clear_icache (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let o_clear_icache := s.r_clear_icache
  { s with
    o_clear_icache := o_clear_icache
  }

/-- 组合逻辑：assign_o_clear_dcache -/
def assign_o_clear_dcache (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let o_clear_dcache := s.CLEAR_DCACHE__r_clear_dcache
  { s with
    o_clear_dcache := o_clear_dcache
  }

/-- 组合逻辑：assign_o_dbg_reg -/
def assign_o_dbg_reg (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let o_dbg_reg := s.SETDBG__r_dbg_reg
  { s with
    o_dbg_reg := o_dbg_reg
  }

/-- 组合逻辑：assign_o_dbg_stall -/
def assign_o_dbg_stall (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let o_dbg_stall := (true && (!(s.r_halted) || s.r_dbg_stall))
  { s with
    o_dbg_stall := o_dbg_stall
  }

/-- 组合逻辑：assign_o_op_stall -/
def assign_o_op_stall (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let o_op_stall := (s.master_ce && s.op_stall)
  { s with
    o_op_stall := o_op_stall
  }

/-- 组合逻辑：assign_o_pf_stall -/
def assign_o_pf_stall (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let o_pf_stall := (s.master_ce && !(i.i_pf_valid))
  { s with
    o_pf_stall := o_pf_stall
  }

/-- 组合逻辑：assign_o_i_count -/
def assign_o_i_count (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let o_i_count := (s.alu_pc_valid && !(s.clear_pipeline))
  { s with
    o_i_count := o_i_count
  }

/-- 组合逻辑：assign_o_debug -/
def assign_o_debug (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let o_debug := BitVec.ofNat 32 0
  { s with
    o_debug := o_debug
  }

/-- 组合逻辑：assign_o_prof_stb -/
def assign_o_prof_stb (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let o_prof_stb := false
  { s with
    o_prof_stb := o_prof_stb
  }

/-- 组合逻辑：assign_o_prof_addr -/
def assign_o_prof_addr (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let o_prof_addr := BitVec.ofNat 32 0
  { s with
    o_prof_addr := o_prof_addr
  }

/-- 组合逻辑：assign_o_prof_ticks -/
def assign_o_prof_ticks (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let o_prof_ticks := BitVec.ofNat 32 0
  { s with
    o_prof_ticks := o_prof_ticks
  }

/-- 组合逻辑：assign_unused -/
def assign_unused (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let unused := BitVec.getLsbD (BitVec.extractLsb 25 0 (BitVec.extractLsb 25 0 (boolToBitVec (bvReduceAnd (BitVec.append (n := 13) (m := 13) (BitVec.append (n := 6) (m := 7) (BitVec.append (n := 2) (m := 4) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (s.fpu_ce))) (BitVec.append (n := 2) (m := 2) (BitVec.extractLsb 1 0 (s.wr_spreg_vl)) (BitVec.extractLsb 1 0 (s.ipc)))) (BitVec.append (n := 4) (m := 3) (BitVec.append (n := 2) (m := 2) (BitVec.extractLsb 1 0 (s.upc)) (BitVec.extractLsb 1 0 (s.pf_pc))) (BitVec.append (n := 1) (m := 2) (boolToBitVec (s.dcd_rA)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.dcd_pipe)) (boolToBitVec (s.dcd_zI)))))) (BitVec.append (n := 5) (m := 8) (BitVec.append (n := 2) (m := 3) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.dcd_A_stall)) (boolToBitVec (s.dcd_B_stall))) (BitVec.append (n := 1) (m := 2) (boolToBitVec (s.dcd_F_stall)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.op_Rcc)) (boolToBitVec (s.op_pipe))))) (BitVec.append (n := 2) (m := 6) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.op_lock)) (boolToBitVec (i.i_mem_pipe_stalled))) (BitVec.append (n := 1) (m := 5) (boolToBitVec (s.prelock_stall)) (BitVec.append (n := 4) (m := 1) (s.dcd_F) (boolToBitVec (s.w_clken))))))))))) 0
  { s with
    unused := unused
  }

/-- 组合逻辑：proc_alwayscomb -/
def proc_alwayscomb (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let dcd_stalled := (s.dcd_valid && s.op_stall)
  { s with
    dcd_stalled := dcd_stalled
  }

/-- 组合逻辑：proc_alwayscomb_1 -/
def proc_alwayscomb_1 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let adf_ce_unconditional := (((!(s.master_stall) && !(s.op_valid_mem)) && !(i.i_mem_rdbusy)) && ((!(i.i_mem_busy) || !(s.op_wR)) || decide ((BitVec.extractLsb 4 0 (s.op_R)).toNat ≠ (BitVec.append (n := 1) (m := 4) (boolToBitVec (s.gie)) (BitVec.ofNat 4 14)).toNat)))
  { s with
    adf_ce_unconditional := adf_ce_unconditional
  }

/-- 组合逻辑：proc_alwayscomb_2 -/
def proc_alwayscomb_2 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_cis_op := (if !(BitVec.getLsbD (s.instruction_decoder__iword) 31) then BitVec.extractLsb 26 22 (s.instruction_decoder__iword) else (if decide ((BitVec.extractLsb 26 24 (s.instruction_decoder__iword)).toNat = (BitVec.ofNat 3 0).toNat) then BitVec.ofNat 5 0 else (if decide ((BitVec.extractLsb 26 24 (s.instruction_decoder__iword)).toNat = (BitVec.ofNat 3 1).toNat) then BitVec.ofNat 5 1 else (if decide ((BitVec.extractLsb 26 24 (s.instruction_decoder__iword)).toNat = (BitVec.ofNat 3 2).toNat) then BitVec.ofNat 5 2 else (if decide ((BitVec.extractLsb 26 24 (s.instruction_decoder__iword)).toNat = (BitVec.ofNat 3 3).toNat) then BitVec.ofNat 5 16 else (if decide ((BitVec.extractLsb 26 24 (s.instruction_decoder__iword)).toNat = (BitVec.ofNat 3 4).toNat) then BitVec.ofNat 5 18 else (if decide ((BitVec.extractLsb 26 24 (s.instruction_decoder__iword)).toNat = (BitVec.ofNat 3 5).toNat) then BitVec.ofNat 5 19 else (if decide ((BitVec.extractLsb 26 24 (s.instruction_decoder__iword)).toNat = (BitVec.ofNat 3 6).toNat) then BitVec.ofNat 5 24 else (if decide ((BitVec.extractLsb 26 24 (s.instruction_decoder__iword)).toNat = (BitVec.ofNat 3 7).toNat) then BitVec.ofNat 5 13 else s.instruction_decoder__w_cis_op)))))))))
  { s with
    instruction_decoder__w_cis_op := instruction_decoder__w_cis_op
  }

/-- 组合逻辑：proc_alwayscomb_3 -/
def proc_alwayscomb_3 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_immsrc := (if s.instruction_decoder__w_ldi then BitVec.extractLsb 1 0 (BitVec.ofNat 32 0) else (if s.instruction_decoder__w_mov then BitVec.extractLsb 1 0 (BitVec.ofNat 32 1) else (if !(BitVec.getLsbD (s.instruction_decoder__iword) 18) then BitVec.extractLsb 1 0 (BitVec.ofNat 32 2) else BitVec.extractLsb 1 0 (BitVec.ofNat 32 3))))
  { s with
    instruction_decoder__w_immsrc := instruction_decoder__w_immsrc
  }

/-- 组合逻辑：proc_alwayscomb_4 -/
def proc_alwayscomb_4 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let instruction_decoder__w_fullI := (if decide ((s.instruction_decoder__w_immsrc).toNat = (BitVec.ofNat 2 0).toNat) then BitVec.extractLsb 22 0 (s.instruction_decoder__iword) else (if decide ((s.instruction_decoder__w_immsrc).toNat = (BitVec.ofNat 2 1).toNat) then BitVec.append (n := 10) (m := 13) (BitVec.append (n := 5) (m := 5) (BitVec.append (n := 2) (m := 3) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__iword) 12)) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__iword) 12))) (BitVec.append (n := 1) (m := 2) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__iword) 12)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__iword) 12)) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__iword) 12))))) (BitVec.append (n := 2) (m := 3) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__iword) 12)) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__iword) 12))) (BitVec.append (n := 1) (m := 2) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__iword) 12)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__iword) 12)) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__iword) 12)))))) (BitVec.extractLsb 12 0 (s.instruction_decoder__iword)) else (if decide ((s.instruction_decoder__w_immsrc).toNat = (BitVec.ofNat 2 2).toNat) then BitVec.append (n := 5) (m := 18) (BitVec.append (n := 2) (m := 3) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__iword) 17)) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__iword) 17))) (BitVec.append (n := 1) (m := 2) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__iword) 17)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__iword) 17)) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__iword) 17))))) (BitVec.extractLsb 17 0 (s.instruction_decoder__iword)) else (if decide ((s.instruction_decoder__w_immsrc).toNat = (BitVec.ofNat 2 3).toNat) then BitVec.append (n := 9) (m := 14) (BitVec.append (n := 4) (m := 5) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__iword) 13)) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__iword) 13))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__iword) 13)) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__iword) 13)))) (BitVec.append (n := 2) (m := 3) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__iword) 13)) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__iword) 13))) (BitVec.append (n := 1) (m := 2) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__iword) 13)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__iword) 13)) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__iword) 13)))))) (BitVec.extractLsb 13 0 (s.instruction_decoder__iword)) else s.instruction_decoder__w_fullI))))
  { s with
    instruction_decoder__w_fullI := instruction_decoder__w_fullI
  }

/-- 组合逻辑：proc_alwayscomb_5 -/
def proc_alwayscomb_5 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let w_pcA_v := (if (!(true) || decide (boolToNat (BitVec.getLsbD (s.dcd_A) 4) = boolToNat (s.dcd_gie))) then bvRangeWrite 32 31 0 (BitVec.ofNat 32 0) (BitVec.append (n := 30) (m := 2) (BitVec.extractLsb 31 2 (s.dcd_pc)) (BitVec.ofNat 2 0)) else bvRangeWrite 32 31 0 (BitVec.ofNat 32 0) (BitVec.append (n := 30) (m := 2) (BitVec.extractLsb 31 2 (s.upc)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.uhalt_phase)) (boolToBitVec (false)))))
  { s with
    w_pcA_v := w_pcA_v
  }

/-- 组合逻辑：proc_alwayscomb_6 -/
def proc_alwayscomb_6 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let avsrc := (if (true && s.wr_reg_ce) then (if ((!(s.op_ce) && decide ((s.wr_reg_id).toNat = (s.op_Aid).toNat)) && s.op_rA) then BitVec.ofNat 3 4 else (if (s.op_ce && decide ((s.wr_reg_id).toNat = (s.dcd_A).toNat)) then BitVec.ofNat 3 4 else (if (!(true) || s.op_ce) then (if s.dcd_Apc then BitVec.ofNat 3 5 else (if s.dcd_Acc then BitVec.ofNat 3 6 else BitVec.ofNat 3 7)) else BitVec.ofNat 3 0))) else (if (!(true) || s.op_ce) then (if s.dcd_Apc then BitVec.ofNat 3 5 else (if s.dcd_Acc then BitVec.ofNat 3 6 else BitVec.ofNat 3 7)) else BitVec.ofNat 3 0))
  { s with
    avsrc := avsrc
  }

/-- 组合逻辑：proc_alwayscomb_7 -/
def proc_alwayscomb_7 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let w_pcB_v := (if (!(true) || decide (boolToNat (BitVec.getLsbD (s.dcd_B) 4) = boolToNat (s.dcd_gie))) then bvRangeWrite 32 31 0 (BitVec.ofNat 32 0) (BitVec.append (n := 30) (m := 2) (BitVec.extractLsb 31 2 (s.dcd_pc)) (BitVec.ofNat 2 0)) else bvRangeWrite 32 31 0 (BitVec.ofNat 32 0) (BitVec.append (n := 30) (m := 2) (BitVec.extractLsb 31 2 (s.upc)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.uhalt_phase)) (boolToBitVec (false)))))
  { s with
    w_pcB_v := w_pcB_v
  }

/-- 组合逻辑：proc_alwayscomb_8 -/
def proc_alwayscomb_8 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let bisrc := (if !(s.dcd_rB) then BitVec.extractLsb 1 0 (BitVec.ofNat 32 0) else (if ((true && s.wr_reg_ce) && decide ((s.wr_reg_id).toNat = (s.dcd_B).toNat)) then BitVec.extractLsb 1 0 (BitVec.ofNat 32 1) else (if s.dcd_Bcc then BitVec.extractLsb 1 0 (BitVec.ofNat 32 2) else BitVec.extractLsb 1 0 (BitVec.ofNat 32 3))))
  { s with
    bisrc := bisrc
  }

/-- 组合逻辑：proc_alwayscomb_9 -/
def proc_alwayscomb_9 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let w_op_BnI := (if decide ((BitVec.extractLsb 1 0 (s.bisrc)).toNat = (BitVec.ofNat 2 0).toNat) then BitVec.ofNat 32 0 else (if decide ((BitVec.extractLsb 1 0 (s.bisrc)).toNat = (BitVec.ofNat 2 1).toNat) then s.wr_gpreg_vl else (if decide ((BitVec.extractLsb 1 0 (s.bisrc)).toNat = (BitVec.ofNat 2 2).toNat) then BitVec.append (n := 9) (m := 23) (s.w_cpu_info) (BitVec.append (n := 7) (m := 16) (BitVec.extractLsb 22 16 (s.w_op_Bv)) ((if BitVec.getLsbD (s.dcd_B) 4 then s.w_uflags else s.w_iflags))) else (if decide ((BitVec.extractLsb 1 0 (s.bisrc)).toNat = (BitVec.ofNat 2 3).toNat) then s.w_op_Bv else s.w_op_BnI))))
  { s with
    w_op_BnI := w_op_BnI
  }

/-- 组合逻辑：proc_alwayscomb_10 -/
def proc_alwayscomb_10 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let bvsrc := (if (!(true) || s.op_ce) then (if (s.dcd_Bpc && s.dcd_rB) then BitVec.ofNat 3 4 else BitVec.ofNat 3 5) else (if (((true && s.op_rB) && s.wr_reg_ce) && decide ((s.op_Bid).toNat = (s.wr_reg_id).toNat)) then BitVec.ofNat 3 6 else BitVec.extractLsb 2 0 (BitVec.ofNat 32 0)))
  { s with
    bvsrc := bvsrc
  }

/-- 组合逻辑：proc_alwayscomb_11 -/
def proc_alwayscomb_11 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let wr_reg_ce := (if (((s.alu_wR && s.alu_valid) || (s.div_valid && !(s.div_error))) || (s.fpu_valid && !(s.fpu_error))) then ((s.dbgv || i.i_mem_valid) || !(s.clear_pipeline)) else (s.dbgv || i.i_mem_valid))
  { s with
    wr_reg_ce := wr_reg_ce
  }

/-- 组合逻辑：proc_alwayscomb_12 -/
def proc_alwayscomb_12 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let wr_gpreg_vl := (if decide ((s.wr_index).toNat = (BitVec.ofNat 3 0).toNat) then s.dbg_val else (if decide ((s.wr_index).toNat = (BitVec.ofNat 3 1).toNat) then i.i_mem_result else (if decide ((s.wr_index).toNat = (BitVec.ofNat 3 3).toNat) then s.div_result else (if decide ((s.wr_index).toNat = (((i.__rtl_nondet_0001 &&& BitVec.ofNat 3 3) ||| BitVec.ofNat 3 4)).toNat) then s.fpu_result else s.alu_result))))
  { s with
    wr_gpreg_vl := wr_gpreg_vl
  }

/-- 组合逻辑：proc_alwayscomb_13 -/
def proc_alwayscomb_13 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let wr_spreg_vl := (if decide ((BitVec.extractLsb 1 0 (s.wr_index)).toNat = (BitVec.ofNat 2 0).toNat) then s.dbg_val else (if decide ((BitVec.extractLsb 1 0 (s.wr_index)).toNat = (BitVec.ofNat 2 1).toNat) then i.i_mem_result else s.alu_result))
  { s with
    wr_spreg_vl := wr_spreg_vl
  }

/-- 组合逻辑：proc_alwayscomb_14 -/
def proc_alwayscomb_14 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let wr_flags_ce := (if (!(s.alu_wF) || s.clear_pipeline) then false else ((s.alu_valid || (s.div_valid && !(s.div_error))) || (s.fpu_valid && !(s.fpu_error))))
  { s with
    wr_flags_ce := wr_flags_ce
  }

/-- 组合逻辑：proc_alwayscomb_15 -/
def proc_alwayscomb_15 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let wr_flags := (if decide ((s.wr_index).toNat = (BitVec.ofNat 3 2).toNat) then s.alu_flags else (if decide ((s.wr_index).toNat = (BitVec.ofNat 3 3).toNat) then s.div_flags else (if decide ((s.wr_index).toNat = (((i.__rtl_nondet_0002 &&& BitVec.ofNat 3 3) ||| BitVec.ofNat 3 4)).toNat) then s.fpu_flags else BitVec.extractLsb 3 0 (BitVec.ofNat 32 0))))
  { s with
    wr_flags := wr_flags
  }

/-- 组合逻辑：proc_alwayscomb_16 -/
def proc_alwayscomb_16 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let pfpcset := (if i.i_reset then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else (if ((s.dbgv && s.wr_reg_ce) && (decide (boolToNat (BitVec.getLsbD (s.wr_reg_id) 4) = boolToNat (s.gie)) && s.wr_write_pc)) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else (if (s.w_switch_to_interrupt || (!(s.gie) && (s.o_clear_icache || s.dbg_clear_pipe))) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else (if (s.w_release_from_interrupt || (s.gie && (s.o_clear_icache || s.dbg_clear_pipe))) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else (if (s.wr_reg_ce && (decide (boolToNat (BitVec.getLsbD (s.wr_reg_id) 4) = boolToNat (s.gie)) && s.wr_write_pc)) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else (if (s.dcd_early_branch_stb && !(s.clear_pipeline)) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else (if (s.new_pc || (s.o_pf_ready && i.i_pf_valid)) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else BitVec.getLsbD (BitVec.ofNat 32 0) 0)))))))
  let pfpcsrc := (if i.i_reset then BitVec.extractLsb 2 0 (BitVec.ofNat 32 0) else (if ((s.dbgv && s.wr_reg_ce) && (decide (boolToNat (BitVec.getLsbD (s.wr_reg_id) 4) = boolToNat (s.gie)) && s.wr_write_pc)) then BitVec.extractLsb 2 0 (BitVec.ofNat 32 1) else (if (s.w_switch_to_interrupt || (!(s.gie) && (s.o_clear_icache || s.dbg_clear_pipe))) then BitVec.extractLsb 2 0 (BitVec.ofNat 32 2) else (if (s.w_release_from_interrupt || (s.gie && (s.o_clear_icache || s.dbg_clear_pipe))) then BitVec.extractLsb 2 0 (BitVec.ofNat 32 3) else (if (s.wr_reg_ce && (decide (boolToNat (BitVec.getLsbD (s.wr_reg_id) 4) = boolToNat (s.gie)) && s.wr_write_pc)) then BitVec.extractLsb 2 0 (BitVec.ofNat 32 1) else (if (s.dcd_early_branch_stb && !(s.clear_pipeline)) then BitVec.extractLsb 2 0 (BitVec.ofNat 32 4) else (if (s.new_pc || (s.o_pf_ready && i.i_pf_valid)) then BitVec.extractLsb 2 0 (BitVec.ofNat 32 5) else BitVec.extractLsb 2 0 (BitVec.ofNat 32 0))))))))
  { s with
    pfpcset := pfpcset
    pfpcsrc := pfpcsrc
  }

/-- 组合逻辑：proc_alwayscomb_17 -/
def proc_alwayscomb_17 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let debug_pc := (if BitVec.getLsbD (i.i_dbg_rreg) 4 then bvRangeWrite 32 31 0 (BitVec.ofNat 32 0) (BitVec.append (n := 30) (m := 2) (BitVec.extractLsb 31 2 (s.upc)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.uhalt_phase)) (boolToBitVec (false)))) else bvRangeWrite 32 31 0 (BitVec.ofNat 32 0) (BitVec.append (n := 30) (m := 2) (BitVec.extractLsb 31 2 (s.ipc)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.ihalt_phase)) (boolToBitVec (false)))))
  { s with
    debug_pc := debug_pc
  }

/-- 组合逻辑：proc_alwayscomb_18 -/
def proc_alwayscomb_18 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let SETDBG__pre_dbg_reg := bvArrayRead 32 32 0 31 (s.regset) ((i.i_dbg_rreg).toNat)
  { s with
    SETDBG__pre_dbg_reg := SETDBG__pre_dbg_reg
  }

private def _rtl_comb_block_0 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let result :=
    assign_clear_pipeline s i
    |> (fun s' => assign_cc_invalid_for_dcd s' i)
    |> (fun s' => assign_pending_sreg_write s' i)
    |> (fun s' => assign_instruction_decoder__i_clk s' i)
    |> (fun s' => assign_instruction_decoder__i_instruction s' i)
    |> (fun s' => assign_instruction_decoder__i_pc s' i)
    |> (fun s' => assign_instruction_decoder__i_pf_valid s' i)
    |> (fun s' => assign_instruction_decoder__i_illegal s' i)
    |> (fun s' => assign_dcd_illegal s' i)
    |> (fun s' => assign_dcd_pc s' i)
    |> (fun s' => assign_dcd_full_R s' i)
    |> (fun s' => assign_dcd_full_A s' i)
    |> (fun s' => assign_dcd_full_B s' i)
    |> (fun s' => assign_dcd_zI s' i)
    |> (fun s' => assign_dcd_F s' i)
    |> (fun s' => assign_dcd_wF s' i)
    |> (fun s' => assign_dcd_opn s' i)
    |> (fun s' => assign_dcd_ALU s' i)
    |> (fun s' => assign_dcd_M s' i)
    |> (fun s' => assign_dcd_DIV s' i)
    |> (fun s' => assign_dcd_FP s' i)
    |> (fun s' => assign_dcd_break s' i)
    |> (fun s' => assign_dcd_lock s' i)
    |> (fun s' => assign_dcd_wR s' i)
    |> (fun s' => assign_dcd_rA s' i)
    |> (fun s' => assign_dcd_rB s' i)
    |> (fun s' => assign_dcd_sim s' i)
    |> (fun s' => assign_dcd_sim_immv s' i)
    |> (fun s' => assign_instruction_decoder__o_phase s' i)
    |> (fun s' => assign_instruction_decoder__illegal_shift s' i)
    |> (fun s' => assign_instruction_decoder__o_ljmp s' i)
    |> (fun s' => assign_instruction_decoder__w_ljmp_dly s' i)

  result

private def _rtl_comb_block_1 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let result :=
    assign_instruction_decoder__o_early_branch s i
    |> (fun s' => assign_instruction_decoder__o_early_branch_stb s' i)
    |> (fun s' => assign_instruction_decoder__o_branch_pc s' i)
    |> (fun s' => assign_instruction_decoder__insn_is_pipeable s' i)
    |> (fun s' => assign_instruction_decoder__o_pipe s' i)
    |> (fun s' => assign_instruction_decoder__o_valid s' i)
    |> (fun s' => assign_instruction_decoder__o_I s' i)
    |> (fun s' => assign_op_pipe s' i)
    |> (fun s' => assign_w_cpu_info s' i)
    |> (fun s' => assign_op_R s' i)
    |> (fun s' => assign_op_Aid s' i)
    |> (fun s' => assign_op_Bid s' i)
    |> (fun s' => assign_op_rA s' i)
    |> (fun s' => assign_op_rB s' i)
    |> (fun s' => assign_op_F s' i)
    |> (fun s' => assign_op_lowpower_clear s' i)
    |> (fun s' => assign_op_break s' i)
    |> (fun s' => assign_op_lock s' i)
    |> (fun s' => assign_op_wR s' i)
    |> (fun s' => assign_op_sim s' i)
    |> (fun s' => assign_op_sim_immv s' i)
    |> (fun s' => assign_op_pc s' i)
    |> (fun s' => assign_op_opn s' i)
    |> (fun s' => assign_op_phase s' i)
    |> (fun s' => assign_doalu__i_clk s' i)
    |> (fun s' => assign_alu_result s' i)
    |> (fun s' => assign_alu_valid s' i)
    |> (fun s' => assign_doalu__thempy__o_result s' i)
    |> (fun s' => assign_doalu__thempy__o_busy s' i)
    |> (fun s' => assign_doalu__thempy__o_hi s' i)
    |> (fun s' => assign_doalu__o_busy s' i)
    |> (fun s' => assign_doalu__z s' i)

  result

private def _rtl_comb_block_2 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let result :=
    assign_doalu__n s i
    |> (fun s' => assign_doalu__v s' i)
    |> (fun s' => assign_doalu__vx s' i)
    |> (fun s' => assign_DIVIDE__thedivide__i_clk s' i)
    |> (fun s' => assign_div_busy s' i)
    |> (fun s' => assign_div_valid s' i)
    |> (fun s' => assign_div_error s' i)
    |> (fun s' => assign_div_result s' i)
    |> (fun s' => assign_DIVIDE__thedivide__diff s' i)
    |> (fun s' => assign_DIVIDE__thedivide__w_n s' i)
    |> (fun s' => assign_fpu_error s' i)
    |> (fun s' => assign_fpu_busy s' i)
    |> (fun s' => assign_fpu_valid s' i)
    |> (fun s' => assign_fpu_result s' i)
    |> (fun s' => assign_fpu_flags s' i)
    |> (fun s' => assign_alu_phase s' i)
    |> (fun s' => assign_alu_pc s' i)
    |> (fun s' => assign_alu_illegal s' i)
    |> (fun s' => assign_prelock_stall s' i)
    |> (fun s' => assign_o_bus_lock s' i)
    |> (fun s' => assign_o_mem_lock_pc s' i)
    |> (fun s' => assign_last_lock_insn s' i)
    |> (fun s' => assign_alu_sim s' i)
    |> (fun s' => assign_alu_sim_immv s' i)
    |> (fun s' => assign_cpu_sim s' i)
    |> (fun s' => assign_wr_reg_id s' i)
    |> (fun s' => assign_break_pending s' i)
    |> (fun s' => assign_w_clken s' i)
    |> (fun s' => assign_o_clken s' i)
    |> (fun s' => assign_pending_interrupt s' i)
    |> (fun s' => assign_stepped s' i)
    |> (fun s' => assign_gie s' i)

  result

private def _rtl_comb_block_3 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let result :=
    assign_trap s i
    |> (fun s' => assign_ubreak s' i)
    |> (fun s' => assign_ill_err_u s' i)
    |> (fun s' => assign_ubus_err_flag s' i)
    |> (fun s' => assign_idiv_err_flag s' i)
    |> (fun s' => assign_udiv_err_flag s' i)
    |> (fun s' => assign_ifpu_err_flag s' i)
    |> (fun s' => assign_ufpu_err_flag s' i)
    |> (fun s' => assign_ihalt_phase s' i)
    |> (fun s' => assign_uhalt_phase s' i)
    |> (fun s' => assign_upc s' i)
    |> (fun s' => assign_o_clear_icache s' i)
    |> (fun s' => assign_o_clear_dcache s' i)
    |> (fun s' => assign_o_dbg_reg s' i)
    |> (fun s' => assign_o_dbg_stall s' i)
    |> (fun s' => assign_o_debug s' i)
    |> (fun s' => assign_o_prof_stb s' i)
    |> (fun s' => assign_o_prof_addr s' i)
    |> (fun s' => assign_o_prof_ticks s' i)
    |> (fun s' => proc_alwayscomb_18 s' i)
    |> (fun s' => assign_pf_gie s' i)
    |> (fun s' => assign_instruction_decoder__i_reset s' i)
    |> (fun s' => assign_dcd_valid s' i)
    |> (fun s' => assign_dcd_phase s' i)
    |> (fun s' => assign_dcd_I s' i)
    |> (fun s' => assign_dcd_early_branch s' i)
    |> (fun s' => assign_dcd_early_branch_stb s' i)
    |> (fun s' => assign_dcd_branch_pc s' i)
    |> (fun s' => assign_dcd_ljmp s' i)
    |> (fun s' => assign_dcd_pipe s' i)
    |> (fun s' => assign_instruction_decoder__pf_valid s' i)
    |> (fun s' => assign_instruction_decoder__iword s' i)

  result

private def _rtl_comb_block_4 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let result :=
    assign_instruction_decoder__GEN_EARLY_BRANCH_LOGIC__w_add_to_pc s i
    |> (fun s' => assign_NO_OP_SIM__op_sim_unused s' i)
    |> (fun s' => assign_op_gie s' i)
    |> (fun s' => assign_doalu__i_reset s' i)
    |> (fun s' => assign_alu_busy s' i)
    |> (fun s' => assign_doalu__thempy__i_clk s' i)
    |> (fun s' => assign_doalu__mpybusy s' i)
    |> (fun s' => assign_doalu__mpy_result s' i)
    |> (fun s' => assign_doalu__mpyhi s' i)
    |> (fun s' => assign_doalu__o_f s' i)
    |> (fun s' => assign_DIVIDE__thedivide__i_reset s' i)
    |> (fun s' => assign_DIVIDE__thedivide__i_signed s' i)
    |> (fun s' => assign_DIVIDE__thedivide__o_flags s' i)
    |> (fun s' => assign_alu_gie s' i)
    |> (fun s' => assign_wr_write_cc s' i)
    |> (fun s' => assign_wr_write_scc s' i)
    |> (fun s' => assign_wr_write_ucc s' i)
    |> (fun s' => assign_wr_write_pc s' i)
    |> (fun s' => assign_step s' i)
    |> (fun s' => proc_alwayscomb_11 s' i)
    |> (fun s' => proc_alwayscomb_12 s' i)
    |> (fun s' => proc_alwayscomb_13 s' i)
    |> (fun s' => proc_alwayscomb_14 s' i)
    |> (fun s' => proc_alwayscomb_17 s' i)
    |> (fun s' => assign_o_pf_new_pc s' i)
    |> (fun s' => assign_o_pf_request_address s' i)
    |> (fun s' => assign_instruction_decoder__i_gie s' i)
    |> (fun s' => assign_instruction_decoder__w_cis_ljmp s' i)
    |> (fun s' => assign_instruction_decoder__w_ljmp s' i)
    |> (fun s' => assign_instruction_decoder__w_op s' i)
    |> (fun s' => assign_instruction_decoder__GEN_CIS_IMMEDIATE__w_halfbits s' i)
    |> (fun s' => assign_dcd_Rcc s' i)

  result

private def _rtl_comb_block_5 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let result :=
    assign_dcd_Rpc s i
    |> (fun s' => assign_dcd_R s' i)
    |> (fun s' => assign_dcd_Acc s' i)
    |> (fun s' => assign_dcd_Apc s' i)
    |> (fun s' => assign_dcd_A s' i)
    |> (fun s' => assign_dcd_Bcc s' i)
    |> (fun s' => assign_dcd_Bpc s' i)
    |> (fun s' => assign_dcd_B s' i)
    |> (fun s' => assign_dcd_gie s' i)
    |> (fun s' => assign_w_op_valid s' i)
    |> (fun s' => assign_op_Av s' i)
    |> (fun s' => assign_op_Bv s' i)
    |> (fun s' => assign_alu_flags s' i)
    |> (fun s' => assign_doalu__thempy__i_reset s' i)
    |> (fun s' => assign_div_flags s' i)
    |> (fun s' => assign_alu_pc_valid s' i)
    |> (fun s' => assign_o_break s' i)
    |> (fun s' => assign_w_switch_to_interrupt s' i)
    |> (fun s' => assign_w_release_from_interrupt s' i)
    |> (fun s' => assign_cc_write_hold s' i)
    |> (fun s' => proc_alwayscomb_2 s' i)
    |> (fun s' => assign_master_ce s' i)
    |> (fun s' => assign_instruction_decoder__w_mov s' i)
    |> (fun s' => assign_instruction_decoder__w_ldi s' i)
    |> (fun s' => assign_instruction_decoder__w_brev s' i)
    |> (fun s' => assign_instruction_decoder__w_mpy s' i)
    |> (fun s' => assign_instruction_decoder__w_cmptst s' i)
    |> (fun s' => assign_instruction_decoder__w_ldilo s' i)
    |> (fun s' => assign_instruction_decoder__w_ALU s' i)
    |> (fun s' => assign_instruction_decoder__w_add s' i)
    |> (fun s' => assign_instruction_decoder__w_mem s' i)
    |> (fun s' => assign_instruction_decoder__w_div s' i)

  result

private def _rtl_comb_block_6 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let result :=
    assign_instruction_decoder__GEN_CIS_IMMEDIATE__w_halfI s i
    |> (fun s' => assign_w_op_Av s' i)
    |> (fun s' => assign_w_op_Bv s' i)
    |> (fun s' => assign_dcd_A_stall s' i)
    |> (fun s' => assign_dcd_B_stall s' i)
    |> (fun s' => assign_dcd_F_stall s' i)
    |> (fun s' => assign_DIVIDE__thedivide__i_numerator s' i)
    |> (fun s' => assign_DIVIDE__thedivide__i_denominator s' i)
    |> (fun s' => assign_o_i_count s' i)
    |> (fun s' => proc_alwayscomb_5 s' i)
    |> (fun s' => proc_alwayscomb_7 s' i)
    |> (fun s' => proc_alwayscomb_8 s' i)
    |> (fun s' => proc_alwayscomb_15 s' i)
    |> (fun s' => assign_master_stall s' i)
    |> (fun s' => assign_instruction_decoder__w_sto s' i)
    |> (fun s' => assign_instruction_decoder__w_dcdR s' i)
    |> (fun s' => assign_instruction_decoder__w_dcdB s' i)
    |> (fun s' => assign_w_uflags s' i)
    |> (fun s' => assign_w_iflags s' i)
    |> (fun s' => assign_o_pf_stall s' i)
    |> (fun s' => proc_alwayscomb_3 s' i)
    |> (fun s' => assign_alu_stall s' i)
    |> (fun s' => assign_mem_stalled s' i)
    |> (fun s' => assign_instruction_decoder__w_fpu s' i)
    |> (fun s' => assign_instruction_decoder__w_special s' i)
    |> (fun s' => assign_instruction_decoder__w_dcdA s' i)
    |> (fun s' => assign_instruction_decoder__w_dcdR_pc s' i)
    |> (fun s' => assign_instruction_decoder__w_dcdR_cc s' i)
    |> (fun s' => assign_instruction_decoder__o_preB s' i)
    |> (fun s' => assign_op_Fl s' i)
    |> (fun s' => proc_alwayscomb_1 s' i)
    |> (fun s' => proc_alwayscomb_4 s' i)

  result

private def _rtl_comb_block_7 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let result :=
    proc_alwayscomb_9 s i
    |> (fun s' => assign_alu_ce s' i)
    |> (fun s' => assign_GEN_ALU_STALL__unused_alu_stall s' i)
    |> (fun s' => assign_mem_ce s' i)
    |> (fun s' => assign_dcd_preB s' i)
    |> (fun s' => assign_instruction_decoder__w_break s' i)
    |> (fun s' => assign_instruction_decoder__w_lock s' i)
    |> (fun s' => assign_instruction_decoder__w_sim s' i)
    |> (fun s' => assign_instruction_decoder__w_noop s' i)
    |> (fun s' => assign_instruction_decoder__w_dcdA_pc s' i)
    |> (fun s' => assign_instruction_decoder__w_dcdA_cc s' i)
    |> (fun s' => assign_instruction_decoder__w_cond s' i)
    |> (fun s' => assign_instruction_decoder__w_rA s' i)
    |> (fun s' => assign_instruction_decoder__w_rB s' i)
    |> (fun s' => assign_instruction_decoder__w_wR_n s' i)
    |> (fun s' => assign_instruction_decoder__w_I s' i)
    |> (fun s' => assign_instruction_decoder__o_preA s' i)
    |> (fun s' => assign_set_cond s' i)
    |> (fun s' => assign_div_ce s' i)
    |> (fun s' => assign_fpu_ce s' i)
    |> (fun s' => assign_op_stall s' i)
    |> (fun s' => assign_dcd_preA s' i)
    |> (fun s' => assign_instruction_decoder__w_dcdB_pc s' i)
    |> (fun s' => assign_instruction_decoder__w_dcdB_cc s' i)
    |> (fun s' => assign_instruction_decoder__w_wR s' i)
    |> (fun s' => assign_instruction_decoder__w_wF s' i)
    |> (fun s' => assign_instruction_decoder__w_Iz s' i)
    |> (fun s' => assign_instruction_decoder__possibly_unused s' i)
    |> (fun s' => assign_doalu__i_stb s' i)
    |> (fun s' => assign_doalu__i_op s' i)
    |> (fun s' => assign_doalu__i_a s' i)
    |> (fun s' => assign_doalu__i_b s' i)

  result

private def _rtl_comb_block_8 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let result :=
    assign_o_mem_ce s i
    |> (fun s' => assign_o_mem_op s' i)
    |> (fun s' => assign_o_mem_data s' i)
    |> (fun s' => assign_o_mem_addr s' i)
    |> (fun s' => assign_o_mem_reg s' i)
    |> (fun s' => assign_op_ce s' i)
    |> (fun s' => assign_GEN_DISTRIBUTED_REGS__unused_prereg_addrs s' i)
    |> (fun s' => assign_doalu__IMPLEMENT_SHIFTS__w_pre_asr_input s' i)
    |> (fun s' => assign_doalu__w_lsr_result s' i)
    |> (fun s' => assign_doalu__w_lsl_result s' i)
    |> (fun s' => assign_doalu__w_brev_result s' i)
    |> (fun s' => assign_doalu__this_is_a_multiply_op s' i)
    |> (fun s' => assign_doalu__thempy__i_op s' i)
    |> (fun s' => assign_doalu__thempy__i_a s' i)
    |> (fun s' => assign_doalu__thempy__i_b s' i)
    |> (fun s' => assign_DIVIDE__thedivide__i_wr s' i)
    |> (fun s' => assign_o_op_stall s' i)
    |> (fun s' => assign_unused s' i)
    |> (fun s' => proc_alwayscomb s' i)
    |> (fun s' => assign_o_pf_ready s' i)
    |> (fun s' => assign_dcd_ce s' i)
    |> (fun s' => assign_instruction_decoder__i_stalled s' i)
    |> (fun s' => assign_doalu__IMPLEMENT_SHIFTS__w_pre_asr_shifted s' i)
    |> (fun s' => assign_doalu__thempy__i_stb s' i)
    |> (fun s' => proc_alwayscomb_6 s' i)
    |> (fun s' => proc_alwayscomb_10 s' i)
    |> (fun s' => assign_instruction_decoder__i_ce s' i)
    |> (fun s' => assign_doalu__w_asr_result s' i)
    |> (fun s' => assign_doalu__thempy__o_valid s' i)
    |> (fun s' => proc_alwayscomb_16 s' i)
    |> (fun s' => assign_doalu__mpydone s' i)

  result

/-- Combinational fixed-point schedule derived from IR dependencies -/
def comb (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let result :=
    _rtl_comb_block_0 s i
    |> (fun s' => _rtl_comb_block_1 s' i)
    |> (fun s' => _rtl_comb_block_2 s' i)
    |> (fun s' => _rtl_comb_block_3 s' i)
    |> (fun s' => _rtl_comb_block_4 s' i)
    |> (fun s' => _rtl_comb_block_5 s' i)
    |> (fun s' => _rtl_comb_block_6 s' i)
    |> (fun s' => _rtl_comb_block_7 s' i)
    |> (fun s' => _rtl_comb_block_8 s' i)

  result

/-- 时序逻辑: proc_alwaysff (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    GEN_OP_STALL__r_cc_invalid_for_dcd := (if s.clear_pipeline then false else (if ((((s.alu_ce || s.mem_ce) && s.set_cond) && s.op_valid) && (s.op_wF || (s.op_wR && decide ((BitVec.extractLsb 4 0 (s.op_R)).toNat = (BitVec.append (n := 1) (m := 4) (boolToBitVec (s.op_gie)) (BitVec.ofNat 4 14)).toNat)))) then true else (if s.GEN_OP_STALL__r_cc_invalid_for_dcd then (((s.alu_busy || i.i_mem_rdbusy) || s.div_busy) || s.fpu_busy) else false)))
  }

/-- 时序逻辑: proc_alwaysff_1 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_1 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    GEN_OP_STALL__r_pending_sreg_write := (if s.clear_pipeline then false else (if ((((((s.adf_ce_unconditional || s.mem_ce) && s.set_cond) && !(s.op_illegal)) && s.op_wR) && decide ((BitVec.extractLsb 3 1 (s.op_R)).toNat = (BitVec.ofNat 3 7).toNat)) && decide ((BitVec.extractLsb 4 0 (s.op_R)).toNat ≠ (BitVec.append (n := 1) (m := 4) (boolToBitVec (s.gie)) (BitVec.ofNat 4 15)).toNat)) then true else (if (!(i.i_mem_rdbusy) && !(s.alu_busy)) then false else s.GEN_OP_STALL__r_pending_sreg_write)))
  }

/-- 时序逻辑: proc_alwaysff_2 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_2 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    instruction_decoder__GEN_CIS_PHASE__r_phase := (if (s.instruction_decoder__i_reset || s.instruction_decoder__w_ljmp_dly) then false else (if (s.instruction_decoder__i_ce && s.instruction_decoder__pf_valid) then (if s.instruction_decoder__o_phase then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (BitVec.getLsbD (s.instruction_decoder__i_instruction) 31 && !(s.instruction_decoder__i_illegal))) else (if s.instruction_decoder__i_ce then false else s.instruction_decoder__GEN_CIS_PHASE__r_phase)))
  }

/-- 时序逻辑: proc_alwaysff_3 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_3 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    instruction_decoder__o_illegal := (if s.instruction_decoder__i_reset then false else (if (s.instruction_decoder__i_ce && s.instruction_decoder__o_phase) then s.instruction_decoder__o_illegal else (if (s.instruction_decoder__i_ce && s.instruction_decoder__i_pf_valid) then (if s.instruction_decoder__i_illegal then true else (if (decide ((BitVec.extractLsb 3 1 (s.instruction_decoder__w_dcdR)).toNat = (BitVec.ofNat 3 7).toNat) && decide ((BitVec.extractLsb 4 1 (s.instruction_decoder__w_cis_op)).toNat = (BitVec.ofNat 4 13).toNat)) then true else (if (!(false) && s.instruction_decoder__w_sim) then true else (if (!(false) && s.instruction_decoder__w_fpu) then true else (if ((true && s.instruction_decoder__w_div) && decide ((BitVec.extractLsb 3 1 (s.instruction_decoder__w_dcdR)).toNat = (BitVec.ofNat 3 7).toNat)) then true else (if (!(false) && s.instruction_decoder__w_mpy) then true else (if s.instruction_decoder__illegal_shift then true else false))))))) else s.instruction_decoder__o_illegal)))
  }

/-- 时序逻辑: proc_alwaysff_4 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_4 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    instruction_decoder__o_pc := (if (s.instruction_decoder__i_ce && (s.instruction_decoder__o_phase || s.instruction_decoder__i_pf_valid)) then (if BitVec.getLsbD (s.instruction_decoder__iword) 31 then (if s.instruction_decoder__o_phase then bvRangeWrite 32 31 1 (bvBitWrite 32 (s.instruction_decoder__o_pc) ((BitVec.ofNat 32 0).toNat) (false)) ((BitVec.extractLsb 31 1 (s.instruction_decoder__o_pc) + BitVec.ofNat 31 1)) else BitVec.append (n := 30) (m := 2) (BitVec.extractLsb 31 2 (s.instruction_decoder__i_pc)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (true)) (boolToBitVec (false)))) else BitVec.append (n := 30) (m := 2) ((BitVec.extractLsb 31 2 (s.instruction_decoder__i_pc) + BitVec.ofNat 30 1)) (BitVec.ofNat 2 0)) else s.instruction_decoder__o_pc)
  }

/-- 时序逻辑: proc_alwaysff_5 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_5 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    instruction_decoder__o_ALU := (if s.instruction_decoder__i_ce then ((((s.instruction_decoder__w_ALU || s.instruction_decoder__w_ldi) || s.instruction_decoder__w_cmptst) || s.instruction_decoder__w_noop) || (!(true) && s.instruction_decoder__w_lock)) else s.instruction_decoder__o_ALU)
    instruction_decoder__o_DV := (if s.instruction_decoder__i_ce then (true && s.instruction_decoder__w_div) else s.instruction_decoder__o_DV)
    instruction_decoder__o_FP := (if s.instruction_decoder__i_ce then (false && s.instruction_decoder__w_fpu) else s.instruction_decoder__o_FP)
    instruction_decoder__o_M := (if s.instruction_decoder__i_ce then s.instruction_decoder__w_mem else s.instruction_decoder__o_M)
    instruction_decoder__o_break := (if s.instruction_decoder__i_ce then s.instruction_decoder__w_break else s.instruction_decoder__o_break)
    instruction_decoder__o_cond := (if s.instruction_decoder__i_ce then s.instruction_decoder__w_cond else s.instruction_decoder__o_cond)
    instruction_decoder__o_dcdA := (if s.instruction_decoder__i_ce then BitVec.append (n := 1) (m := 6) (boolToBitVec (s.instruction_decoder__w_dcdA_cc)) (BitVec.append (n := 1) (m := 5) (boolToBitVec (s.instruction_decoder__w_dcdA_pc)) (s.instruction_decoder__w_dcdA)) else s.instruction_decoder__o_dcdA)
    instruction_decoder__o_dcdB := (if s.instruction_decoder__i_ce then BitVec.append (n := 1) (m := 6) (boolToBitVec (s.instruction_decoder__w_dcdB_cc)) (BitVec.append (n := 1) (m := 5) (boolToBitVec (s.instruction_decoder__w_dcdB_pc)) (s.instruction_decoder__w_dcdB)) else s.instruction_decoder__o_dcdB)
    instruction_decoder__o_dcdR := (if s.instruction_decoder__i_ce then BitVec.append (n := 1) (m := 6) (boolToBitVec (s.instruction_decoder__w_dcdR_cc)) (BitVec.append (n := 1) (m := 5) (boolToBitVec (s.instruction_decoder__w_dcdR_pc)) (s.instruction_decoder__w_dcdR)) else s.instruction_decoder__o_dcdR)
    instruction_decoder__o_lock := (if s.instruction_decoder__i_ce then (true && s.instruction_decoder__w_lock) else s.instruction_decoder__o_lock)
    instruction_decoder__o_op := (if s.instruction_decoder__i_ce then (if ((s.instruction_decoder__w_ldi || s.instruction_decoder__w_noop) || s.instruction_decoder__w_lock) then BitVec.ofNat 4 13 else BitVec.extractLsb 3 0 (s.instruction_decoder__w_cis_op)) else s.instruction_decoder__o_op)
    instruction_decoder__o_rA := (if s.instruction_decoder__i_ce then s.instruction_decoder__w_rA else s.instruction_decoder__o_rA)
    instruction_decoder__o_rB := (if s.instruction_decoder__i_ce then s.instruction_decoder__w_rB else s.instruction_decoder__o_rB)
    instruction_decoder__o_sim := (if s.instruction_decoder__i_ce then false else s.instruction_decoder__o_sim)
    instruction_decoder__o_sim_immv := (if s.instruction_decoder__i_ce then BitVec.extractLsb 22 0 (BitVec.ofNat 32 0) else s.instruction_decoder__o_sim_immv)
    instruction_decoder__o_wF := (if s.instruction_decoder__i_ce then s.instruction_decoder__w_wF else s.instruction_decoder__o_wF)
    instruction_decoder__o_wR := (if s.instruction_decoder__i_ce then s.instruction_decoder__w_wR else s.instruction_decoder__o_wR)
    instruction_decoder__o_zI := (if s.instruction_decoder__i_ce then s.instruction_decoder__w_Iz else s.instruction_decoder__o_zI)
    instruction_decoder__r_I := (if s.instruction_decoder__i_ce then s.instruction_decoder__w_I else s.instruction_decoder__r_I)
    instruction_decoder__r_nxt_half := (if s.instruction_decoder__i_ce then BitVec.extractLsb 14 0 (s.instruction_decoder__iword) else s.instruction_decoder__r_nxt_half)
  }

/-- 时序逻辑: proc_alwaysff_6 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_6 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_ljmp := (if s.instruction_decoder__i_reset then false else (if s.instruction_decoder__i_ce then (if (s.instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_ljmp && s.instruction_decoder__pf_valid) then false else (if s.instruction_decoder__o_early_branch_stb then false else (if s.instruction_decoder__pf_valid then (if (true && BitVec.getLsbD (s.instruction_decoder__iword) 31) then s.instruction_decoder__w_cis_ljmp else s.instruction_decoder__w_ljmp) else (if ((true && s.instruction_decoder__o_phase) && BitVec.getLsbD (s.instruction_decoder__iword) 31) then s.instruction_decoder__w_cis_ljmp else s.instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_ljmp)))) else s.instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_ljmp))
  }

/-- 时序逻辑: proc_alwaysff_7 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_7 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_early_branch := (if s.instruction_decoder__i_reset then false else (if (s.instruction_decoder__i_ce && s.instruction_decoder__pf_valid) then (if s.instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_ljmp then true else (if s.instruction_decoder__GEN_EARLY_BRANCH_LOGIC__w_add_to_pc then true else false)) else (if s.instruction_decoder__i_ce then false else s.instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_early_branch)))
    instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_early_branch_stb := (if s.instruction_decoder__i_reset then false else (if (s.instruction_decoder__i_ce && s.instruction_decoder__pf_valid) then (if s.instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_ljmp then true else (if s.instruction_decoder__GEN_EARLY_BRANCH_LOGIC__w_add_to_pc then (!(false) || decide ((BitVec.extractLsb 17 0 (s.instruction_decoder__i_instruction)).toNat ≠ (BitVec.ofNat 32 0).toNat)) else false)) else false))
  }

/-- 时序逻辑: proc_alwaysff_8 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_8 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_branch_pc := (if s.instruction_decoder__i_ce then (if s.instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_ljmp then BitVec.append (n := 30) (m := 2) (BitVec.extractLsb 31 2 (s.instruction_decoder__iword)) (BitVec.ofNat 2 0) else bvRangeWrite 32 1 0 (bvRangeWrite 32 31 2 (s.instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_branch_pc) (((BitVec.extractLsb 31 2 (s.instruction_decoder__i_pc) + BitVec.append (n := 15) (m := 15) (BitVec.append (n := 7) (m := 8) (BitVec.append (n := 3) (m := 4) (BitVec.append (n := 1) (m := 2) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__i_instruction) 17)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__i_instruction) 17)) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__i_instruction) 17)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__i_instruction) 17)) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__i_instruction) 17))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__i_instruction) 17)) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__i_instruction) 17))))) (BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__i_instruction) 17)) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__i_instruction) 17))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__i_instruction) 17)) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__i_instruction) 17)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__i_instruction) 17)) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__i_instruction) 17))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__i_instruction) 17)) (boolToBitVec (BitVec.getLsbD (s.instruction_decoder__i_instruction) 17)))))) (BitVec.extractLsb 16 2 (s.instruction_decoder__i_instruction))) + BitVec.append (n := 29) (m := 1) (BitVec.append (n := 14) (m := 15) (BitVec.append (n := 7) (m := 7) (BitVec.append (n := 3) (m := 4) (BitVec.append (n := 1) (m := 2) (boolToBitVec (false)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))))) (BitVec.append (n := 3) (m := 4) (BitVec.append (n := 1) (m := 2) (boolToBitVec (false)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false)))))) (BitVec.append (n := 7) (m := 8) (BitVec.append (n := 3) (m := 4) (BitVec.append (n := 1) (m := 2) (boolToBitVec (false)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))))) (BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))))))) (boolToBitVec (true))))) (BitVec.ofNat 2 0)) else s.instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_branch_pc)
  }

/-- 时序逻辑: proc_alwaysff_9 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_9 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    instruction_decoder__GEN_OPIPE__r_insn_is_pipeable := (if s.instruction_decoder__i_reset then false else (if ((s.instruction_decoder__i_ce && (!(s.instruction_decoder__pf_valid) || s.instruction_decoder__i_illegal)) && !(s.instruction_decoder__o_phase)) then false else (if s.instruction_decoder__o_ljmp then false else (if (s.instruction_decoder__i_ce && (!(true) && BitVec.getLsbD (s.instruction_decoder__i_instruction) 31)) then false else (if s.instruction_decoder__i_ce then ((((s.instruction_decoder__w_mem && s.instruction_decoder__w_rB) && decide ((BitVec.extractLsb 3 1 (s.instruction_decoder__w_dcdB)).toNat ≠ (BitVec.ofNat 3 7).toNat)) && decide ((BitVec.extractLsb 3 1 (s.instruction_decoder__w_dcdR)).toNat ≠ (BitVec.ofNat 3 7).toNat)) && (BitVec.getLsbD (s.instruction_decoder__w_cis_op) 0 || decide ((s.instruction_decoder__w_dcdB).toNat ≠ (s.instruction_decoder__w_dcdA).toNat))) else s.instruction_decoder__GEN_OPIPE__r_insn_is_pipeable)))))
  }

/-- 时序逻辑: proc_alwaysff_10 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_10 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    instruction_decoder__GEN_OPIPE__r_pipe := (if s.instruction_decoder__i_reset then false else (if s.instruction_decoder__i_ce then ((((((s.instruction_decoder__pf_valid || s.instruction_decoder__o_phase) && s.instruction_decoder__GEN_OPIPE__r_insn_is_pipeable) && s.instruction_decoder__w_mem) && decide (boolToNat (BitVec.getLsbD (s.instruction_decoder__o_op) 0) = boolToNat (BitVec.getLsbD (s.instruction_decoder__w_cis_op) 0))) && s.instruction_decoder__w_rB) && decide ((BitVec.extractLsb 3 0 (s.instruction_decoder__w_dcdB)).toNat = (BitVec.extractLsb 3 0 (s.instruction_decoder__o_dcdB)).toNat)) else s.instruction_decoder__GEN_OPIPE__r_pipe))
  }

/-- 时序逻辑: proc_alwaysff_11 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_11 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    instruction_decoder__r_valid := (if s.instruction_decoder__i_reset then false else (if s.instruction_decoder__i_ce then ((s.instruction_decoder__pf_valid || s.instruction_decoder__o_phase) && !(s.instruction_decoder__o_ljmp)) else (if !(s.instruction_decoder__i_stalled) then false else s.instruction_decoder__r_valid)))
  }

/-- 时序逻辑: proc_alwaysff_12 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_12 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    GEN_OP_PIPE__r_op_pipe := (if (((false && i.i_reset) || s.clear_pipeline) || i.i_halt) then false else (if s.op_ce then ((s.dcd_pipe && s.op_valid_mem) && (!(false) || !(s.dcd_illegal))) else (if (s.wr_reg_ce && decide ((s.wr_reg_id).toNat = (BitVec.extractLsb 4 0 (s.op_Bid)).toNat)) then false else (if s.mem_ce then false else s.GEN_OP_PIPE__r_op_pipe))))
  }

/-- 时序逻辑: proc_alwaysff_13 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_13 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    OP_REG_ADVANEC__r_op_Aid := (if (s.op_ce && (!(false) || s.w_op_valid)) then s.dcd_A else s.OP_REG_ADVANEC__r_op_Aid)
    OP_REG_ADVANEC__r_op_Bid := (if (s.op_ce && (!(false) || s.w_op_valid)) then (if ((s.dcd_rB && !(s.dcd_early_branch)) && !(s.dcd_illegal)) then s.dcd_B else s.OP_REG_ADVANEC__r_op_Bid) else s.OP_REG_ADVANEC__r_op_Bid)
    OP_REG_ADVANEC__r_op_R := (if (s.op_ce && (!(false) || s.w_op_valid)) then s.dcd_R else s.OP_REG_ADVANEC__r_op_R)
    OP_REG_ADVANEC__r_op_rA := (if s.op_lowpower_clear then false else (if (s.op_ce && (!(false) || s.w_op_valid)) then ((s.dcd_rA && !(s.dcd_early_branch)) && !(s.dcd_illegal)) else s.OP_REG_ADVANEC__r_op_rA))
    OP_REG_ADVANEC__r_op_rB := (if s.op_lowpower_clear then false else (if (s.op_ce && (!(false) || s.w_op_valid)) then ((s.dcd_rB && !(s.dcd_early_branch)) && !(s.dcd_illegal)) else s.OP_REG_ADVANEC__r_op_rB))
    op_Rcc := (if (s.op_ce && (!(false) || s.w_op_valid)) then ((s.dcd_Rcc && s.dcd_wR) && decide (boolToNat (BitVec.getLsbD (s.dcd_R) 4) = boolToNat (s.dcd_gie))) else s.op_Rcc)
  }

/-- 时序逻辑: proc_alwaysff_14 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_14 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    r_op_Av := (if s.op_lowpower_clear then BitVec.ofNat 32 0 else (if BitVec.getLsbD (s.avsrc) 2 then (if decide ((BitVec.extractLsb 1 0 (s.avsrc)).toNat = (BitVec.ofNat 2 0).toNat) then s.wr_gpreg_vl else (if decide ((BitVec.extractLsb 1 0 (s.avsrc)).toNat = (BitVec.ofNat 2 1).toNat) then s.w_pcA_v else (if decide ((BitVec.extractLsb 1 0 (s.avsrc)).toNat = (BitVec.ofNat 2 2).toNat) then BitVec.append (n := 9) (m := 23) (s.w_cpu_info) (BitVec.append (n := 7) (m := 16) (BitVec.extractLsb 22 16 (s.w_op_Av)) ((if BitVec.getLsbD (s.dcd_A) 4 then s.w_uflags else s.w_iflags))) else (if decide ((BitVec.extractLsb 1 0 (s.avsrc)).toNat = (BitVec.ofNat 2 3).toNat) then s.w_op_Av else s.r_op_Av)))) else s.r_op_Av))
  }

/-- 时序逻辑: proc_alwaysff_15 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_15 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    r_op_Bv := (if s.op_lowpower_clear then BitVec.ofNat 32 0 else (if BitVec.getLsbD (s.bvsrc) 2 then (if decide ((BitVec.extractLsb 1 0 (s.bvsrc)).toNat = (BitVec.ofNat 2 0).toNat) then (s.w_pcB_v + BitVec.append (n := 30) (m := 2) (BitVec.extractLsb 29 0 (s.dcd_I)) (BitVec.ofNat 2 0)) else (if decide ((BitVec.extractLsb 1 0 (s.bvsrc)).toNat = (BitVec.ofNat 2 1).toNat) then (s.w_op_BnI + s.dcd_I) else (if decide ((BitVec.extractLsb 1 0 (s.bvsrc)).toNat = (((i.__rtl_nondet_0000 &&& BitVec.ofNat 2 1) ||| BitVec.ofNat 2 2)).toNat) then s.wr_gpreg_vl else s.r_op_Bv))) else s.r_op_Bv))
  }

/-- 时序逻辑: proc_alwaysff_16 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_16 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    r_op_F := (if s.op_lowpower_clear then BitVec.ofNat 7 0 else (if (!(true) || s.op_ce) then (if decide ((BitVec.extractLsb 2 0 (s.dcd_F)).toNat = (BitVec.ofNat 3 0).toNat) then BitVec.ofNat 7 0 else (if decide ((BitVec.extractLsb 2 0 (s.dcd_F)).toNat = (BitVec.ofNat 3 1).toNat) then BitVec.ofNat 7 17 else (if decide ((BitVec.extractLsb 2 0 (s.dcd_F)).toNat = (BitVec.ofNat 3 2).toNat) then BitVec.ofNat 7 68 else (if decide ((BitVec.extractLsb 2 0 (s.dcd_F)).toNat = (BitVec.ofNat 3 3).toNat) then BitVec.ofNat 7 34 else (if decide ((BitVec.extractLsb 2 0 (s.dcd_F)).toNat = (BitVec.ofNat 3 4).toNat) then BitVec.ofNat 7 8 else (if decide ((BitVec.extractLsb 2 0 (s.dcd_F)).toNat = (BitVec.ofNat 3 5).toNat) then BitVec.ofNat 7 16 else (if decide ((BitVec.extractLsb 2 0 (s.dcd_F)).toNat = (BitVec.ofNat 3 6).toNat) then BitVec.ofNat 7 64 else (if decide ((BitVec.extractLsb 2 0 (s.dcd_F)).toNat = (BitVec.ofNat 3 7).toNat) then BitVec.ofNat 7 32 else s.r_op_F)))))))) else s.r_op_F))
  }

/-- 时序逻辑: proc_alwaysff_17 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_17 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    op_valid := (if (i.i_reset || s.clear_pipeline) then false else (if s.op_ce then (s.w_op_valid || s.dcd_early_branch) else (if (s.adf_ce_unconditional || s.mem_ce) then false else s.op_valid)))
    op_valid_alu := (if (i.i_reset || s.clear_pipeline) then false else (if s.op_ce then (s.w_op_valid && (s.dcd_ALU || s.dcd_illegal)) else (if (s.adf_ce_unconditional || s.mem_ce) then false else s.op_valid_alu)))
    op_valid_div := (if (i.i_reset || s.clear_pipeline) then false else (if s.op_ce then (((true && s.dcd_DIV) && !(s.dcd_illegal)) && s.w_op_valid) else (if (s.adf_ce_unconditional || s.mem_ce) then false else s.op_valid_div)))
    op_valid_fpu := (if (i.i_reset || s.clear_pipeline) then false else (if s.op_ce then (((false && s.dcd_FP) && !(s.dcd_illegal)) && s.w_op_valid) else (if (s.adf_ce_unconditional || s.mem_ce) then false else s.op_valid_fpu)))
    op_valid_mem := (if (i.i_reset || s.clear_pipeline) then false else (if s.op_ce then ((s.dcd_M && !(s.dcd_illegal)) && s.w_op_valid) else (if (s.adf_ce_unconditional || s.mem_ce) then false else s.op_valid_mem)))
  }

/-- 时序逻辑: proc_alwaysff_18 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_18 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    r_op_break := (if s.clear_pipeline then false else (if (true && s.op_ce) then ((s.dcd_valid && s.dcd_break) && !(s.dcd_illegal)) else s.r_op_break))
  }

/-- 时序逻辑: proc_alwaysff_19 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_19 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    GEN_OPLOCK__r_op_lock := (if s.clear_pipeline then false else (if s.op_ce then ((s.dcd_valid && s.dcd_lock) && !(s.dcd_illegal)) else s.GEN_OPLOCK__r_op_lock))
  }

/-- 时序逻辑: proc_alwaysff_20 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_20 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    op_illegal := (if (i.i_reset || s.clear_pipeline) then false else (if s.op_ce then (((s.dcd_valid && !(s.dcd_ljmp)) && !(s.dcd_early_branch)) && s.dcd_illegal) else s.op_illegal))
  }

/-- 时序逻辑: proc_alwaysff_21 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_21 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    op_wF := (if s.op_lowpower_clear then false else (if (!(true) || s.op_ce) then ((s.dcd_wF && (!(s.dcd_Rcc) || !(s.dcd_wR))) && !(s.dcd_early_branch)) else s.op_wF))
  }

/-- 时序逻辑: proc_alwaysff_22 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_22 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    GEN_OP_WR__r_op_wR := (if s.op_lowpower_clear then false else (if s.op_ce then (s.dcd_wR && !(s.dcd_early_branch)) else s.GEN_OP_WR__r_op_wR))
  }

/-- 时序逻辑: proc_alwaysff_23 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_23 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    SET_OP_PC__r_op_pc := (if s.op_ce then (if s.dcd_early_branch then s.dcd_branch_pc else s.dcd_pc) else s.SET_OP_PC__r_op_pc)
  }

/-- 时序逻辑: proc_alwaysff_24 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_24 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    FWD_OPERATION__r_op_opn := (if (s.op_ce && ((!(false) || s.w_op_valid) || s.dcd_early_branch)) then (if (s.dcd_early_branch || s.dcd_illegal) then BitVec.ofNat 4 13 else s.dcd_opn) else s.FWD_OPERATION__r_op_opn)
  }

/-- 时序逻辑: proc_alwaysff_25 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_25 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    OPT_CIS_OP_PHASE__r_op_phase := (if (i.i_reset || s.clear_pipeline) then false else (if s.op_ce then (s.dcd_phase && (!(s.dcd_wR) || !(s.dcd_Rpc))) else s.OPT_CIS_OP_PHASE__r_op_phase))
  }

/-- 时序逻辑: proc_alwaysff_26 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_26 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    doalu__set_ovfl := (if s.doalu__i_stb then ((((decide ((s.doalu__i_op).toNat = (BitVec.ofNat 4 0).toNat) && decide (boolToNat (BitVec.getLsbD (s.doalu__i_a) 31) ≠ boolToNat (BitVec.getLsbD (s.doalu__i_b) 31))) || (decide ((s.doalu__i_op).toNat = (BitVec.ofNat 4 2).toNat) && decide (boolToNat (BitVec.getLsbD (s.doalu__i_a) 31) = boolToNat (BitVec.getLsbD (s.doalu__i_b) 31)))) || decide ((s.doalu__i_op).toNat = (BitVec.ofNat 4 6).toNat)) || decide ((s.doalu__i_op).toNat = (BitVec.ofNat 4 5).toNat)) else s.doalu__set_ovfl)
  }

/-- 时序逻辑: proc_alwaysff_27 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_27 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    doalu__keep_sgn_on_ovfl := (if s.doalu__i_stb then ((decide ((s.doalu__i_op).toNat = (BitVec.ofNat 4 0).toNat) && decide (boolToNat (BitVec.getLsbD (s.doalu__i_a) 31) ≠ boolToNat (BitVec.getLsbD (s.doalu__i_b) 31))) || (decide ((s.doalu__i_op).toNat = (BitVec.ofNat 4 2).toNat) && decide (boolToNat (BitVec.getLsbD (s.doalu__i_a) 31) = boolToNat (BitVec.getLsbD (s.doalu__i_b) 31)))) else s.doalu__keep_sgn_on_ovfl)
  }

/-- 时序逻辑: proc_alwaysff_28 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_28 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    doalu__c := (if s.doalu__i_stb then (if decide ((s.doalu__i_op).toNat = (BitVec.ofNat 4 0).toNat) then BitVec.getLsbD (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 ((BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (BitVec.append (n := 1) (m := 32) (boolToBitVec (false)) (s.doalu__i_a)))) - BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (BitVec.append (n := 1) (m := 32) (boolToBitVec (false)) (s.doalu__i_b)))))))) 32 else (if decide ((s.doalu__i_op).toNat = (BitVec.ofNat 4 1).toNat) then false else (if decide ((s.doalu__i_op).toNat = (BitVec.ofNat 4 2).toNat) then BitVec.getLsbD (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 ((BitVec.extractLsb 32 0 (BitVec.append (n := 1) (m := 32) (boolToBitVec (false)) (BitVec.extractLsb 31 0 (s.doalu__i_a))) + BitVec.extractLsb 32 0 (BitVec.append (n := 1) (m := 32) (boolToBitVec (false)) (BitVec.extractLsb 31 0 (s.doalu__i_b))))))) 32 else (if decide ((s.doalu__i_op).toNat = (BitVec.ofNat 4 3).toNat) then false else (if decide ((s.doalu__i_op).toNat = (BitVec.ofNat 4 4).toNat) then false else (if decide ((s.doalu__i_op).toNat = (BitVec.ofNat 4 5).toNat) then BitVec.getLsbD (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (s.doalu__w_lsr_result)))))) 0 else (if decide ((s.doalu__i_op).toNat = (BitVec.ofNat 4 6).toNat) then BitVec.getLsbD (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (s.doalu__w_lsl_result)))))) 32 else (if decide ((s.doalu__i_op).toNat = (BitVec.ofNat 4 7).toNat) then BitVec.getLsbD (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (s.doalu__w_asr_result)))))) 0 else false)))))))) else s.doalu__c)
    doalu__o_c := (if s.doalu__i_stb then (if decide ((s.doalu__i_op).toNat = (BitVec.ofNat 4 0).toNat) then BitVec.extractLsb 31 0 (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 ((BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (BitVec.append (n := 1) (m := 32) (boolToBitVec (false)) (s.doalu__i_a)))) - BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (BitVec.append (n := 1) (m := 32) (boolToBitVec (false)) (s.doalu__i_b)))))))) else (if decide ((s.doalu__i_op).toNat = (BitVec.ofNat 4 1).toNat) then (s.doalu__i_a &&& s.doalu__i_b) else (if decide ((s.doalu__i_op).toNat = (BitVec.ofNat 4 2).toNat) then BitVec.extractLsb 31 0 (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 ((BitVec.extractLsb 32 0 (BitVec.append (n := 1) (m := 32) (boolToBitVec (false)) (BitVec.extractLsb 31 0 (s.doalu__i_a))) + BitVec.extractLsb 32 0 (BitVec.append (n := 1) (m := 32) (boolToBitVec (false)) (BitVec.extractLsb 31 0 (s.doalu__i_b))))))) else (if decide ((s.doalu__i_op).toNat = (BitVec.ofNat 4 3).toNat) then (s.doalu__i_a ||| s.doalu__i_b) else (if decide ((s.doalu__i_op).toNat = (BitVec.ofNat 4 4).toNat) then (s.doalu__i_a ^^^ s.doalu__i_b) else (if decide ((s.doalu__i_op).toNat = (BitVec.ofNat 4 5).toNat) then BitVec.extractLsb 32 1 (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (s.doalu__w_lsr_result)))))) else (if decide ((s.doalu__i_op).toNat = (BitVec.ofNat 4 6).toNat) then BitVec.extractLsb 31 0 (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (s.doalu__w_lsl_result)))))) else (if decide ((s.doalu__i_op).toNat = (BitVec.ofNat 4 7).toNat) then BitVec.extractLsb 32 1 (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (s.doalu__w_asr_result)))))) else (if decide ((s.doalu__i_op).toNat = (BitVec.ofNat 4 8).toNat) then s.doalu__w_brev_result else (if decide ((s.doalu__i_op).toNat = (BitVec.ofNat 4 9).toNat) then BitVec.append (n := 16) (m := 16) (BitVec.extractLsb 31 16 (s.doalu__i_a)) (BitVec.extractLsb 15 0 (s.doalu__i_b)) else (if decide ((s.doalu__i_op).toNat = (BitVec.ofNat 4 10).toNat) then BitVec.extractLsb 63 32 (s.doalu__mpy_result) else (if decide ((s.doalu__i_op).toNat = (BitVec.ofNat 4 11).toNat) then BitVec.extractLsb 63 32 (s.doalu__mpy_result) else (if decide ((s.doalu__i_op).toNat = (BitVec.ofNat 4 12).toNat) then BitVec.extractLsb 31 0 (s.doalu__mpy_result) else s.doalu__i_b))))))))))))) else (if s.doalu__mpyhi then BitVec.extractLsb 63 32 (s.doalu__mpy_result) else BitVec.extractLsb 31 0 (s.doalu__mpy_result)))
    doalu__pre_sign := (if s.doalu__i_stb then BitVec.getLsbD (s.doalu__i_a) 31 else s.doalu__pre_sign)
  }

/-- 时序逻辑: proc_alwaysff_29 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_29 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    doalu__r_busy := false
  }

/-- 时序逻辑: proc_alwaysff_30 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_30 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    doalu__o_valid := (if s.doalu__i_reset then false else s.doalu__i_stb)
  }

/-- 时序逻辑: proc_alwaysff_31 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_31 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    DIVIDE__thedivide__r_busy := (if s.DIVIDE__thedivide__i_reset then false else (if s.DIVIDE__thedivide__i_wr then true else (if (s.DIVIDE__thedivide__last_bit || s.DIVIDE__thedivide__zero_divisor) then false else s.DIVIDE__thedivide__r_busy)))
  }

/-- 时序逻辑: proc_alwaysff_32 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_32 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    DIVIDE__thedivide__o_busy := (if s.DIVIDE__thedivide__i_reset then false else (if s.DIVIDE__thedivide__i_wr then true else (if ((s.DIVIDE__thedivide__last_bit && !(s.DIVIDE__thedivide__r_sign)) || s.DIVIDE__thedivide__zero_divisor) then false else (if !(s.DIVIDE__thedivide__r_busy) then false else s.DIVIDE__thedivide__o_busy))))
  }

/-- 时序逻辑: proc_alwaysff_33 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_33 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    DIVIDE__thedivide__zero_divisor := (if s.DIVIDE__thedivide__i_wr then decide ((s.DIVIDE__thedivide__i_denominator).toNat = (BitVec.ofNat 32 0).toNat) else s.DIVIDE__thedivide__zero_divisor)
  }

/-- 时序逻辑: proc_alwaysff_34 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_34 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    DIVIDE__thedivide__o_valid := (if (s.DIVIDE__thedivide__i_reset || s.DIVIDE__thedivide__o_valid) then false else (if (s.DIVIDE__thedivide__r_busy && s.DIVIDE__thedivide__zero_divisor) then true else (if s.DIVIDE__thedivide__r_busy then (if s.DIVIDE__thedivide__last_bit then !(s.DIVIDE__thedivide__r_sign) else s.DIVIDE__thedivide__o_valid) else (if s.DIVIDE__thedivide__r_sign then true else false))))
  }

/-- 时序逻辑: proc_alwaysff_35 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_35 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    DIVIDE__thedivide__o_err := (if s.DIVIDE__thedivide__i_reset then false else (if (s.DIVIDE__thedivide__r_busy && s.DIVIDE__thedivide__zero_divisor) then true else false))
  }

/-- 时序逻辑: proc_alwaysff_36 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_36 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    DIVIDE__thedivide__r_bit := (if s.DIVIDE__thedivide__i_reset then BitVec.extractLsb 4 0 (BitVec.ofNat 32 0) else (if (s.DIVIDE__thedivide__r_busy && !(s.DIVIDE__thedivide__pre_sign)) then (s.DIVIDE__thedivide__r_bit + BitVec.ofNat 5 1) else BitVec.extractLsb 4 0 (BitVec.ofNat 32 0)))
  }

/-- 时序逻辑: proc_alwaysff_37 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_37 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    DIVIDE__thedivide__last_bit := (if s.DIVIDE__thedivide__i_reset then false else (if s.DIVIDE__thedivide__r_busy then decide ((s.DIVIDE__thedivide__r_bit).toNat = ((BitVec.append (n := 2) (m := 3) (BitVec.append (n := 1) (m := 1) (boolToBitVec (true)) (boolToBitVec (true))) (BitVec.append (n := 1) (m := 2) (boolToBitVec (true)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (true)) (boolToBitVec (true)))) - BitVec.ofNat 5 1)).toNat) else false))
  }

/-- 时序逻辑: proc_alwaysff_38 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_38 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    DIVIDE__thedivide__pre_sign := (if s.DIVIDE__thedivide__i_reset then false else ((s.DIVIDE__thedivide__i_wr && s.DIVIDE__thedivide__i_signed) && (BitVec.getLsbD (s.DIVIDE__thedivide__i_numerator) 31 || BitVec.getLsbD (s.DIVIDE__thedivide__i_denominator) 31)))
  }

/-- 时序逻辑: proc_alwaysff_39 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_39 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    DIVIDE__thedivide__r_z := (if s.DIVIDE__thedivide__i_wr then true else (if ((s.DIVIDE__thedivide__r_busy && !(s.DIVIDE__thedivide__pre_sign)) && !(BitVec.getLsbD (s.DIVIDE__thedivide__diff) 32)) then false else s.DIVIDE__thedivide__r_z))
  }

/-- 时序逻辑: proc_alwaysff_40 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_40 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    DIVIDE__thedivide__r_dividend := (if s.DIVIDE__thedivide__pre_sign then (if BitVec.getLsbD (s.DIVIDE__thedivide__r_dividend) 31 then bvRangeWrite 63 32 0 (bvRangeWrite 63 62 0 (s.DIVIDE__thedivide__r_dividend) (BitVec.append (n := 31) (m := 32) (BitVec.append (n := 15) (m := 16) (BitVec.append (n := 7) (m := 8) (BitVec.append (n := 3) (m := 4) (BitVec.append (n := 1) (m := 2) (boolToBitVec (false)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))))) (BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false)))))) (BitVec.append (n := 8) (m := 8) (BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))))) (BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))))))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))))) (BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false)))))) (BitVec.append (n := 8) (m := 8) (BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))))) (BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))))))))) (-(BitVec.append (n := 1) (m := 32) (boolToBitVec (true)) (BitVec.extractLsb 31 0 (s.DIVIDE__thedivide__r_dividend)))) else s.DIVIDE__thedivide__r_dividend) else (if s.DIVIDE__thedivide__r_busy then (if !(BitVec.getLsbD (s.DIVIDE__thedivide__diff) 32) then bvRangeWrite 63 62 32 (BitVec.append (n := 62) (m := 1) (BitVec.extractLsb 61 0 (s.DIVIDE__thedivide__r_dividend)) (boolToBitVec (false))) (BitVec.extractLsb 30 0 (s.DIVIDE__thedivide__diff)) else BitVec.append (n := 62) (m := 1) (BitVec.extractLsb 61 0 (s.DIVIDE__thedivide__r_dividend)) (boolToBitVec (false))) else (if (!(s.DIVIDE__thedivide__r_busy) && (!(false) || s.DIVIDE__thedivide__i_wr)) then BitVec.append (n := 31) (m := 32) (BitVec.ofNat 31 0) (s.DIVIDE__thedivide__i_numerator) else s.DIVIDE__thedivide__r_dividend)))
  }

/-- 时序逻辑: proc_alwaysff_41 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_41 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    DIVIDE__thedivide__r_divisor := (if s.DIVIDE__thedivide__i_reset then BitVec.ofNat 32 0 else (if (s.DIVIDE__thedivide__pre_sign && s.DIVIDE__thedivide__r_busy) then (if BitVec.getLsbD (s.DIVIDE__thedivide__r_divisor) 31 then -(s.DIVIDE__thedivide__r_divisor) else s.DIVIDE__thedivide__r_divisor) else (if (!(s.DIVIDE__thedivide__r_busy) && (!(false) || s.DIVIDE__thedivide__i_wr)) then s.DIVIDE__thedivide__i_denominator else s.DIVIDE__thedivide__r_divisor)))
  }

/-- 时序逻辑: proc_alwaysff_42 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_42 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    DIVIDE__thedivide__r_sign := (if s.DIVIDE__thedivide__i_reset then false else (if s.DIVIDE__thedivide__pre_sign then Bool.xor (BitVec.getLsbD (s.DIVIDE__thedivide__r_divisor) 31) (BitVec.getLsbD (s.DIVIDE__thedivide__r_dividend) 31) else (if s.DIVIDE__thedivide__r_busy then (s.DIVIDE__thedivide__r_sign && !(s.DIVIDE__thedivide__zero_divisor)) else false)))
  }

/-- 时序逻辑: proc_alwaysff_43 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_43 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    DIVIDE__thedivide__o_quotient := (if s.DIVIDE__thedivide__i_reset then BitVec.ofNat 32 0 else (if s.DIVIDE__thedivide__r_busy then (if !(BitVec.getLsbD (s.DIVIDE__thedivide__diff) 32) then bvBitWrite 32 (BitVec.append (n := 31) (m := 1) (BitVec.extractLsb 30 0 (s.DIVIDE__thedivide__o_quotient)) (boolToBitVec (false))) ((BitVec.ofNat 32 0).toNat) (true) else BitVec.append (n := 31) (m := 1) (BitVec.extractLsb 30 0 (s.DIVIDE__thedivide__o_quotient)) (boolToBitVec (false))) else (if s.DIVIDE__thedivide__r_sign then -(s.DIVIDE__thedivide__o_quotient) else BitVec.ofNat 32 0)))
  }

/-- 时序逻辑: proc_alwaysff_44 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_44 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    DIVIDE__thedivide__r_c := (if s.DIVIDE__thedivide__i_reset then false else (s.DIVIDE__thedivide__r_busy && decide ((s.DIVIDE__thedivide__diff).toNat = (BitVec.ofNat 33 0).toNat)))
  }

/-- 时序逻辑: proc_alwaysff_45 (clk=i_clk, rst=i_reset) — 复位由 step 顶层处理 -/
def proc_alwaysff_45 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    alu_wF := (if i.i_reset then false else (if s.alu_ce then ((s.op_wF && s.set_cond) && !(s.op_illegal)) else (if !(s.alu_busy) then false else s.alu_wF)))
    alu_wR := (if i.i_reset then false else (if s.alu_ce then ((s.op_wR && s.set_cond) && !(s.op_illegal)) else (if !(s.alu_busy) then (s.r_halted && ((true && i.i_dbg_we) && !(s.o_dbg_stall))) else s.alu_wR)))
  }

/-- 时序逻辑: proc_alwaysff_46 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_46 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    GEN_ALU_PHASE__r_alu_phase := (if (i.i_reset || s.clear_pipeline) then false else (if ((s.adf_ce_unconditional || s.mem_ce) && s.op_valid) then s.op_phase else (if (s.adf_ce_unconditional || s.mem_ce) then false else s.GEN_ALU_PHASE__r_alu_phase)))
  }

/-- 时序逻辑: proc_alwaysff_47 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_47 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    alu_reg := (if (((s.alu_ce || s.div_ce) || s.o_mem_ce) || s.fpu_ce) then s.op_R else (if ((true && i.i_dbg_we) && !(s.o_dbg_stall)) then i.i_dbg_wreg else s.alu_reg))
  }

/-- 时序逻辑: proc_alwaysff_48 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_48 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    wr_index := bvBitWrite 3 ((if ((true && i.i_dbg_we) && !(s.o_dbg_stall)) then BitVec.ofNat 3 0 else (if ((true && (s.mem_ce || s.adf_ce_unconditional)) || (!(true) && s.op_valid)) then bvBitWrite 3 (bvBitWrite 3 (bvBitWrite 3 (BitVec.extractLsb 2 0 (BitVec.ofNat 32 0)) ((BitVec.ofNat 32 0).toNat) ((s.op_valid_mem || s.op_valid_div))) ((BitVec.ofNat 32 1).toNat) ((s.op_valid_alu || s.op_valid_div))) ((BitVec.ofNat 32 2).toNat) (s.op_valid_fpu) else s.wr_index))) ((BitVec.ofNat 32 2).toNat) (false)
  }

/-- 时序逻辑: proc_alwaysff_49 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_49 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    dbgv := (if (i.i_reset || !(s.r_halted)) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else ((true && i.i_dbg_we) && !(s.o_dbg_stall)))
  }

/-- 时序逻辑: proc_alwaysff_50 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_50 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    dbg_val := i.i_dbg_data
  }

/-- 时序逻辑: proc_alwaysff_51 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_51 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    dbg_clear_pipe := (if ((i.i_reset || s.clear_pipeline) || !(s.r_halted)) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if ((true && i.i_dbg_we) && !(s.o_dbg_stall)) then (if decide ((BitVec.extractLsb 3 1 (i.i_dbg_wreg)).toNat = (BitVec.ofNat 3 7).toNat) then true else (if (decide ((i.i_dbg_wreg).toNat = (s.op_Bid).toNat) && s.op_rB) then true else false)) else false))
  }

/-- 时序逻辑: proc_alwaysff_52 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_52 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    GEN_ALU_PC__r_alu_pc := (if (s.adf_ce_unconditional || (((s.master_ce && s.op_valid_mem) && !(s.clear_pipeline)) && !(s.mem_stalled))) then s.op_pc else s.GEN_ALU_PC__r_alu_pc)
  }

/-- 时序逻辑: proc_alwaysff_53 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_53 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    SET_ALU_ILLEGAL__r_alu_illegal := (if s.clear_pipeline then false else (if s.adf_ce_unconditional then s.op_illegal else false))
  }

/-- 时序逻辑: proc_alwaysff_54 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_54 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    r_alu_pc_valid := (if s.clear_pipeline then false else (if (s.adf_ce_unconditional && !(s.op_phase)) then true else (if (((!(s.alu_busy) && !(s.div_busy)) && !(s.fpu_busy)) || s.clear_pipeline) then false else s.r_alu_pc_valid)))
  }

/-- 时序逻辑: proc_alwaysff_55 (clk=i_clk, rst=i_reset) — 复位由 step 顶层处理 -/
def proc_alwaysff_55 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    mem_pc_valid := (if i.i_reset then false else s.mem_ce)
  }

/-- 时序逻辑: proc_alwaysff_56 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_56 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    BUSLOCK__r_prelock_stall := (if (!(true) || s.clear_pipeline) then false else (if (((s.op_valid && s.op_lock) && decide ((s.BUSLOCK__r_bus_lock).toNat = (BitVec.ofNat 2 0).toNat)) && s.adf_ce_unconditional) then true else (if ((s.op_valid && s.dcd_valid) && (i.i_pf_valid || s.dcd_early_branch)) then false else s.BUSLOCK__r_prelock_stall)))
  }

/-- 时序逻辑: proc_alwaysff_57 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_57 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    BUSLOCK__r_lock_pc := (if ((s.op_valid && s.op_ce) && s.op_lock) then (s.op_pc - BitVec.ofNat 32 4) else s.BUSLOCK__r_lock_pc)
  }

/-- 时序逻辑: proc_alwaysff_58 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_58 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    BUSLOCK__r_bus_lock := (if s.clear_pipeline then BitVec.ofNat 2 0 else (if (s.op_valid && (s.adf_ce_unconditional || s.mem_ce)) then (if decide ((s.BUSLOCK__r_bus_lock).toNat ≠ (BitVec.ofNat 2 0).toNat) then BitVec.extractLsb 1 0 ((BitVec.extractLsb 31 0 (BitVec.append (n := 30) (m := 2) (BitVec.ofNat 30 0) (BitVec.extractLsb 1 0 (s.BUSLOCK__r_bus_lock))) - BitVec.extractLsb 31 0 (BitVec.ofNat 32 1))) else (if s.op_lock then BitVec.ofNat 2 3 else s.BUSLOCK__r_bus_lock)) else s.BUSLOCK__r_bus_lock))
  }

/-- 时序逻辑: proc_alwaysff_59 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_59 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    regset := (if s.wr_reg_ce then bvArrayWrite 32 32 0 31 (s.regset) ((s.wr_reg_id).toNat) (s.wr_gpreg_vl) else s.regset)
  }

/-- 时序逻辑: proc_alwaysff_60 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_60 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    flags := (if (s.wr_reg_ce && s.wr_write_ucc) then BitVec.extractLsb 3 0 (s.wr_gpreg_vl) else (if (s.wr_flags_ce && s.alu_gie) then s.wr_flags else s.flags))
  }

/-- 时序逻辑: proc_alwaysff_61 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_61 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    iflags := (if (s.wr_reg_ce && s.wr_write_scc) then BitVec.extractLsb 3 0 (s.wr_gpreg_vl) else (if (s.wr_flags_ce && !(s.alu_gie)) then s.wr_flags else s.iflags))
  }

/-- 时序逻辑: proc_alwaysff_62 (clk=i_clk, rst=i_reset) — 复位由 step 顶层处理 -/
def proc_alwaysff_62 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    break_en := (if i.i_reset then false else (if (s.wr_reg_ce && s.wr_write_scc) then BitVec.getLsbD (s.wr_spreg_vl) 7 else s.break_en))
  }

/-- 时序逻辑: proc_alwaysff_63 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_63 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    GEN_PENDING_BREAK__r_break_pending := (if (s.clear_pipeline || !(s.op_valid)) then false else (if (s.op_break && !(s.GEN_PENDING_BREAK__r_break_pending)) then (((((!(s.alu_busy) && !(s.div_busy)) && !(s.fpu_busy)) && !(i.i_mem_busy)) && !(s.wr_reg_ce)) && (!(s.step) || !(s.stepped))) else s.GEN_PENDING_BREAK__r_break_pending))
  }

/-- 时序逻辑: proc_alwaysff_64 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_64 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    sleep := (if (i.i_reset || s.w_switch_to_interrupt) then false else (if (s.wr_reg_ce && s.wr_write_cc) then (if !(s.alu_gie) then (BitVec.getLsbD (s.wr_spreg_vl) 4 && (!(i.i_interrupt) || !(BitVec.getLsbD (s.wr_spreg_vl) 5))) else (if BitVec.getLsbD (s.wr_spreg_vl) 5 then BitVec.getLsbD (s.wr_spreg_vl) 4 else s.sleep)) else s.sleep))
  }

/-- 时序逻辑: proc_alwaysff_65 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_65 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    user_step := (if (i.i_reset || !(true)) then false else (if ((s.wr_reg_ce && !(s.alu_gie)) && s.wr_write_ucc) then BitVec.getLsbD (s.wr_spreg_vl) 6 else s.user_step))
  }

/-- 时序逻辑: proc_alwaysff_66 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_66 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    GEN_CLOCK_GATE__r_clken := (if i.i_reset then !(true) else (if ((i.i_halt && s.r_halted) && (!(true) || !(i.i_dbg_we))) then ((i.i_mem_busy || !(i.i_halt)) || s.o_mem_ce) else (if (!(i.i_halt) && ((!(s.sleep) || i.i_interrupt) || s.pending_interrupt)) then true else (if (i.i_halt && !(s.r_halted)) then true else (if (((((((i.i_mem_busy || s.o_mem_ce) || s.alu_busy) || s.div_busy) || s.fpu_busy) || s.wr_reg_ce) || (true && i.i_dbg_we)) || i.i_bus_err) then true else (if s.alu_phase then true else (if s.o_bus_lock then true else false)))))))
  }

/-- 时序逻辑: proc_alwaysff_67 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_67 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    GEN_PENDING_INTERRUPT__r_user_stepped := (if ((i.i_reset || !(s.gie)) || !(s.user_step)) then false else (if ((((s.op_valid && !(s.op_phase)) && !(s.op_lock)) && s.last_lock_insn) && (s.adf_ce_unconditional || s.mem_ce)) then true else s.GEN_PENDING_INTERRUPT__r_user_stepped))
  }

/-- 时序逻辑: proc_alwaysff_68 (clk=i_clk, rst=i_reset) — 复位由 step 顶层处理 -/
def proc_alwaysff_68 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    GEN_PENDING_INTERRUPT__r_pending_interrupt := (if i.i_reset then false else (if (!(s.gie) || s.w_switch_to_interrupt) then false else (if (s.clear_pipeline && (!(s.user_step) || !(s.stepped))) then false else (if ((((((!(s.alu_busy) && !(i.i_mem_busy)) && !(s.div_busy)) && !(s.fpu_busy)) || s.wr_reg_ce) && s.user_step) && s.stepped) then true else (if (s.adf_ce_unconditional && s.op_illegal) then true else (if s.break_pending then true else (if i.i_interrupt then true else s.GEN_PENDING_INTERRUPT__r_pending_interrupt)))))))
  }

/-- 时序逻辑: proc_alwaysff_69 (clk=i_clk, rst=i_reset) — 复位由 step 顶层处理 -/
def proc_alwaysff_69 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    SET_GIE__r_gie := (if i.i_reset then false else (if s.w_switch_to_interrupt then false else (if s.w_release_from_interrupt then true else s.SET_GIE__r_gie)))
  }

/-- 时序逻辑: proc_alwaysff_70 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_70 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    SET_TRAP_N_UBREAK__r_trap := (if (i.i_reset || s.w_release_from_interrupt) then false else (if (s.wr_reg_ce && s.wr_write_ucc) then (if !(s.alu_gie) then (s.SET_TRAP_N_UBREAK__r_trap && BitVec.getLsbD (s.wr_spreg_vl) 9) else (if !(BitVec.getLsbD (s.wr_spreg_vl) 5) then !(s.dbgv) else s.SET_TRAP_N_UBREAK__r_trap)) else s.SET_TRAP_N_UBREAK__r_trap))
  }

/-- 时序逻辑: proc_alwaysff_71 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_71 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    SET_TRAP_N_UBREAK__r_ubreak := (if (i.i_reset || s.w_release_from_interrupt) then false else (if ((s.op_gie && s.break_pending) && s.w_switch_to_interrupt) then true else (if (((!(s.alu_gie) || s.dbgv) && s.wr_reg_ce) && s.wr_write_ucc) then (s.ubreak && BitVec.getLsbD (s.wr_spreg_vl) 7) else s.SET_TRAP_N_UBREAK__r_ubreak)))
  }

/-- 时序逻辑: proc_alwaysff_72 (clk=i_clk, rst=i_reset) — 复位由 step 顶层处理 -/
def proc_alwaysff_72 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    ill_err_i := (if i.i_reset then false else (if (s.dbgv && s.wr_write_scc) then (s.ill_err_i && BitVec.getLsbD (s.wr_spreg_vl) 8) else (if ((!(s.alu_gie) && s.alu_illegal) && !(s.clear_pipeline)) then true else s.ill_err_i)))
  }

/-- 时序逻辑: proc_alwaysff_73 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_73 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    SET_USER_ILLEGAL_INSN__r_ill_err_u := (if (i.i_reset || s.w_release_from_interrupt) then false else (if (((!(s.alu_gie) || s.dbgv) && s.wr_reg_ce) && s.wr_write_ucc) then (s.ill_err_u && BitVec.getLsbD (s.wr_spreg_vl) 8) else (if ((s.alu_gie && s.alu_illegal) && !(s.clear_pipeline)) then true else s.SET_USER_ILLEGAL_INSN__r_ill_err_u)))
  }

/-- 时序逻辑: proc_alwaysff_74 (clk=i_clk, rst=i_reset) — 复位由 step 顶层处理 -/
def proc_alwaysff_74 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    ibus_err_flag := (if i.i_reset then false else (if (s.dbgv && s.wr_write_scc) then (s.ibus_err_flag && BitVec.getLsbD (s.wr_spreg_vl) 10) else (if (i.i_bus_err && !(s.alu_gie)) then true else s.ibus_err_flag)))
  }

/-- 时序逻辑: proc_alwaysff_75 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_75 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    SET_USER_BUSERR__r_ubus_err_flag := (if (i.i_reset || s.w_release_from_interrupt) then false else (if (((!(s.alu_gie) || s.dbgv) && s.wr_reg_ce) && s.wr_write_ucc) then (s.ubus_err_flag && BitVec.getLsbD (s.wr_spreg_vl) 10) else (if (i.i_bus_err && s.alu_gie) then true else s.SET_USER_BUSERR__r_ubus_err_flag)))
  }

/-- 时序逻辑: proc_alwaysff_76 (clk=i_clk, rst=i_reset) — 复位由 step 顶层处理 -/
def proc_alwaysff_76 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    DIVERR__r_idiv_err_flag := (if i.i_reset then false else (if (s.dbgv && s.wr_write_scc) then (s.DIVERR__r_idiv_err_flag && BitVec.getLsbD (s.wr_spreg_vl) 11) else (if (s.div_error && !(s.alu_gie)) then true else s.DIVERR__r_idiv_err_flag)))
  }

/-- 时序逻辑: proc_alwaysff_77 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_77 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    DIVERR__USER_DIVERR__r_udiv_err_flag := (if (i.i_reset || s.w_release_from_interrupt) then false else (if (((!(s.alu_gie) || s.dbgv) && s.wr_reg_ce) && s.wr_write_ucc) then (s.DIVERR__USER_DIVERR__r_udiv_err_flag && BitVec.getLsbD (s.wr_spreg_vl) 11) else (if (s.div_error && s.alu_gie) then true else s.DIVERR__USER_DIVERR__r_udiv_err_flag)))
  }

/-- 时序逻辑: proc_alwaysff_78 (clk=i_clk, rst=i_reset) — 复位由 step 顶层处理 -/
def proc_alwaysff_78 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    GEN_IHALT_PHASE__r_ihalt_phase := (if i.i_reset then false else (if ((!(s.alu_gie) && s.alu_pc_valid) && !(s.clear_pipeline)) then s.alu_phase else s.GEN_IHALT_PHASE__r_ihalt_phase))
  }

/-- 时序逻辑: proc_alwaysff_79 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_79 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    GEN_UHALT_PHASE__r_uhalt_phase := (if (i.i_reset || s.w_release_from_interrupt) then false else (if (s.alu_gie && s.alu_pc_valid) then s.alu_phase else (if (((!(s.alu_gie) && s.wr_reg_ce) && s.wr_write_pc) && BitVec.getLsbD (s.wr_reg_id) 4) then BitVec.getLsbD (s.wr_spreg_vl) 1 else s.GEN_UHALT_PHASE__r_uhalt_phase)))
  }

/-- 时序逻辑: proc_alwaysff_80 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_80 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    SET_USER_PC__r_upc := (if ((s.wr_reg_ce && BitVec.getLsbD (s.wr_reg_id) 4) && s.wr_write_pc) then BitVec.append (n := 30) (m := 2) (BitVec.extractLsb 31 2 (s.wr_spreg_vl)) (BitVec.ofNat 2 0) else (if (s.alu_gie && (((s.alu_pc_valid && !(s.clear_pipeline)) && !(s.alu_illegal)) || s.mem_pc_valid)) then s.alu_pc else s.SET_USER_PC__r_upc))
  }

/-- 时序逻辑: proc_alwaysff_81 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_81 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    ipc := (if i.i_reset then BitVec.append (n := 30) (m := 2) (BitVec.ofNat 30 262144) (BitVec.ofNat 2 0) else (if ((s.wr_reg_ce && !(BitVec.getLsbD (s.wr_reg_id) 4)) && s.wr_write_pc) then BitVec.append (n := 30) (m := 2) (BitVec.extractLsb 31 2 (s.wr_spreg_vl)) (BitVec.ofNat 2 0) else (if ((!(s.alu_gie) && !(s.alu_phase)) && (((s.alu_pc_valid && !(s.clear_pipeline)) && !(s.alu_illegal)) || s.mem_pc_valid)) then s.alu_pc else s.ipc)))
  }

/-- 时序逻辑: proc_alwaysff_82 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_82 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    pf_pc := (if s.pfpcset then (if decide ((s.pfpcsrc).toNat = (BitVec.ofNat 3 0).toNat) then BitVec.append (n := 30) (m := 2) (BitVec.ofNat 30 262144) (BitVec.ofNat 2 0) else (if decide ((s.pfpcsrc).toNat = (BitVec.ofNat 3 1).toNat) then BitVec.append (n := 30) (m := 2) (BitVec.extractLsb 31 2 (s.wr_spreg_vl)) (BitVec.ofNat 2 0) else (if decide ((s.pfpcsrc).toNat = (BitVec.ofNat 3 2).toNat) then BitVec.append (n := 30) (m := 2) (BitVec.extractLsb 31 2 (s.ipc)) (BitVec.ofNat 2 0) else (if decide ((s.pfpcsrc).toNat = (BitVec.ofNat 3 3).toNat) then BitVec.append (n := 30) (m := 2) (BitVec.extractLsb 31 2 (s.upc)) (BitVec.ofNat 2 0) else (if decide ((s.pfpcsrc).toNat = (BitVec.ofNat 3 4).toNat) then BitVec.append (n := 30) (m := 2) ((BitVec.extractLsb 31 2 (s.dcd_branch_pc) + BitVec.ofNat 30 1)) (BitVec.ofNat 2 0) else (if decide ((s.pfpcsrc).toNat = (BitVec.ofNat 3 5).toNat) then BitVec.append (n := 30) (m := 2) ((BitVec.extractLsb 31 2 (s.pf_pc) + BitVec.ofNat 30 1)) (BitVec.ofNat 2 0) else BitVec.append (n := 30) (m := 2) (BitVec.ofNat 30 262144) (BitVec.ofNat 2 0))))))) else s.pf_pc)
  }

/-- 时序逻辑: proc_alwaysff_83 (clk=i_clk, rst=i_reset) — 复位由 step 顶层处理 -/
def proc_alwaysff_83 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    last_write_to_cc := (if i.i_reset then false else (s.wr_reg_ce && s.wr_write_cc))
  }

/-- 时序逻辑: proc_alwaysff_84 (clk=i_clk, rst=i_reset) — 复位由 step 顶层处理 -/
def proc_alwaysff_84 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    r_clear_icache := (if i.i_reset then false else (if (i.i_clear_cache && !(s.o_dbg_stall)) then true else (if (s.wr_reg_ce && s.wr_write_scc) then BitVec.getLsbD (s.wr_spreg_vl) 14 else false)))
  }

/-- 时序逻辑: proc_alwaysff_85 (clk=i_clk, rst=i_reset) — 复位由 step 顶层处理 -/
def proc_alwaysff_85 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    CLEAR_DCACHE__r_clear_dcache := (if i.i_reset then false else (if (i.i_clear_cache && !(s.o_dbg_stall)) then true else (if (s.wr_reg_ce && s.wr_write_scc) then BitVec.getLsbD (s.wr_spreg_vl) 15 else false)))
  }

/-- 时序逻辑: proc_alwaysff_86 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_86 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    new_pc := (if ((i.i_reset || s.o_clear_icache) || s.dbg_clear_pipe) then true else (if s.w_switch_to_interrupt then true else (if s.w_release_from_interrupt then true else (if ((s.wr_reg_ce && decide (boolToNat (s.alu_gie) = boolToNat (BitVec.getLsbD (s.wr_reg_id) 4))) && s.wr_write_pc) then true else false))))
  }

/-- 时序逻辑: proc_alwaysff_87 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_87 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    SETDBG__r_dbg_reg := (if decide ((BitVec.extractLsb 3 0 (i.i_dbg_rreg)).toNat = (BitVec.ofNat 4 15).toNat) then s.debug_pc else (if decide ((BitVec.extractLsb 3 0 (i.i_dbg_rreg)).toNat = (BitVec.ofNat 4 14).toNat) then bvBitWrite 32 (bvRangeWrite 32 31 23 (bvRangeWrite 32 15 0 (s.SETDBG__pre_dbg_reg) ((if BitVec.getLsbD (i.i_dbg_rreg) 4 then s.w_uflags else s.w_iflags))) (s.w_cpu_info)) ((BitVec.ofNat 32 5).toNat) (BitVec.getLsbD (i.i_dbg_rreg) 4) else s.SETDBG__pre_dbg_reg))
  }

/-- 时序逻辑: proc_alwaysff_88 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_88 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    o_dbg_cc := BitVec.append (n := 1) (m := 2) (boolToBitVec (i.i_bus_err)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.gie)) (boolToBitVec (s.sleep)))
  }

/-- 时序逻辑: proc_alwaysff_89 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_89 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    r_halted := (if i.i_reset then true else (if !(i.i_halt) then false else (if s.r_halted then true else ((!(s.alu_phase) && !(s.o_bus_lock)) && (((((i.i_pf_valid && !(i.i_mem_busy)) && !(s.alu_busy)) && !(s.div_busy)) && !(s.fpu_busy)) && (s.dcd_valid || s.dcd_illegal))))))
  }

/-- 时序逻辑: proc_alwaysff_90 (clk=i_clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_90 (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  { s with
    r_dbg_stall := (if i.i_reset then true else (if (!(s.r_halted) || (s.wr_reg_ce && decide ((BitVec.extractLsb 3 1 (s.wr_reg_id)).toNat = (BitVec.ofNat 3 7).toNat))) then true else ((true && i.i_dbg_we) && !(s.o_dbg_stall))))
  }

/-- Parallel nonblocking commit for the single clock domain -/
def commit (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let s1 := proc_alwaysff s i
  let s2 := proc_alwaysff_1 s i
  let s3 := proc_alwaysff_2 s i
  let s4 := proc_alwaysff_3 s i
  let s5 := proc_alwaysff_4 s i
  let s6 := proc_alwaysff_5 s i
  let s7 := proc_alwaysff_6 s i
  let s8 := proc_alwaysff_7 s i
  let s9 := proc_alwaysff_8 s i
  let s10 := proc_alwaysff_9 s i
  let s11 := proc_alwaysff_10 s i
  let s12 := proc_alwaysff_11 s i
  let s13 := proc_alwaysff_12 s i
  let s14 := proc_alwaysff_13 s i
  let s15 := proc_alwaysff_14 s i
  let s16 := proc_alwaysff_15 s i
  let s17 := proc_alwaysff_16 s i
  let s18 := proc_alwaysff_17 s i
  let s19 := proc_alwaysff_18 s i
  let s20 := proc_alwaysff_19 s i
  let s21 := proc_alwaysff_20 s i
  let s22 := proc_alwaysff_21 s i
  let s23 := proc_alwaysff_22 s i
  let s24 := proc_alwaysff_23 s i
  let s25 := proc_alwaysff_24 s i
  let s26 := proc_alwaysff_25 s i
  let s27 := proc_alwaysff_26 s i
  let s28 := proc_alwaysff_27 s i
  let s29 := proc_alwaysff_28 s i
  let s30 := proc_alwaysff_29 s i
  let s31 := proc_alwaysff_30 s i
  let s32 := proc_alwaysff_31 s i
  let s33 := proc_alwaysff_32 s i
  let s34 := proc_alwaysff_33 s i
  let s35 := proc_alwaysff_34 s i
  let s36 := proc_alwaysff_35 s i
  let s37 := proc_alwaysff_36 s i
  let s38 := proc_alwaysff_37 s i
  let s39 := proc_alwaysff_38 s i
  let s40 := proc_alwaysff_39 s i
  let s41 := proc_alwaysff_40 s i
  let s42 := proc_alwaysff_41 s i
  let s43 := proc_alwaysff_42 s i
  let s44 := proc_alwaysff_43 s i
  let s45 := proc_alwaysff_44 s i
  let s46 := proc_alwaysff_45 s i
  let s47 := proc_alwaysff_46 s i
  let s48 := proc_alwaysff_47 s i
  let s49 := proc_alwaysff_48 s i
  let s50 := proc_alwaysff_49 s i
  let s51 := proc_alwaysff_50 s i
  let s52 := proc_alwaysff_51 s i
  let s53 := proc_alwaysff_52 s i
  let s54 := proc_alwaysff_53 s i
  let s55 := proc_alwaysff_54 s i
  let s56 := proc_alwaysff_55 s i
  let s57 := proc_alwaysff_56 s i
  let s58 := proc_alwaysff_57 s i
  let s59 := proc_alwaysff_58 s i
  let s60 := proc_alwaysff_59 s i
  let s61 := proc_alwaysff_60 s i
  let s62 := proc_alwaysff_61 s i
  let s63 := proc_alwaysff_62 s i
  let s64 := proc_alwaysff_63 s i
  let s65 := proc_alwaysff_64 s i
  let s66 := proc_alwaysff_65 s i
  let s67 := proc_alwaysff_66 s i
  let s68 := proc_alwaysff_67 s i
  let s69 := proc_alwaysff_68 s i
  let s70 := proc_alwaysff_69 s i
  let s71 := proc_alwaysff_70 s i
  let s72 := proc_alwaysff_71 s i
  let s73 := proc_alwaysff_72 s i
  let s74 := proc_alwaysff_73 s i
  let s75 := proc_alwaysff_74 s i
  let s76 := proc_alwaysff_75 s i
  let s77 := proc_alwaysff_76 s i
  let s78 := proc_alwaysff_77 s i
  let s79 := proc_alwaysff_78 s i
  let s80 := proc_alwaysff_79 s i
  let s81 := proc_alwaysff_80 s i
  let s82 := proc_alwaysff_81 s i
  let s83 := proc_alwaysff_82 s i
  let s84 := proc_alwaysff_83 s i
  let s85 := proc_alwaysff_84 s i
  let s86 := proc_alwaysff_85 s i
  let s87 := proc_alwaysff_86 s i
  let s88 := proc_alwaysff_87 s i
  let s89 := proc_alwaysff_88 s i
  let s90 := proc_alwaysff_89 s i
  let s91 := proc_alwaysff_90 s i
  let result := {
    BUSLOCK__r_bus_lock := s59.BUSLOCK__r_bus_lock
    BUSLOCK__r_lock_pc := s58.BUSLOCK__r_lock_pc
    BUSLOCK__r_prelock_stall := s57.BUSLOCK__r_prelock_stall
    CLEAR_DCACHE__r_clear_dcache := s86.CLEAR_DCACHE__r_clear_dcache
    DIVERR__USER_DIVERR__r_udiv_err_flag := s78.DIVERR__USER_DIVERR__r_udiv_err_flag
    DIVERR__r_idiv_err_flag := s77.DIVERR__r_idiv_err_flag
    DIVIDE__thedivide__last_bit := s38.DIVIDE__thedivide__last_bit
    DIVIDE__thedivide__o_busy := s33.DIVIDE__thedivide__o_busy
    DIVIDE__thedivide__o_err := s36.DIVIDE__thedivide__o_err
    DIVIDE__thedivide__o_quotient := s44.DIVIDE__thedivide__o_quotient
    DIVIDE__thedivide__o_valid := s35.DIVIDE__thedivide__o_valid
    DIVIDE__thedivide__pre_sign := s39.DIVIDE__thedivide__pre_sign
    DIVIDE__thedivide__r_bit := s37.DIVIDE__thedivide__r_bit
    DIVIDE__thedivide__r_busy := s32.DIVIDE__thedivide__r_busy
    DIVIDE__thedivide__r_c := s45.DIVIDE__thedivide__r_c
    DIVIDE__thedivide__r_dividend := s41.DIVIDE__thedivide__r_dividend
    DIVIDE__thedivide__r_divisor := s42.DIVIDE__thedivide__r_divisor
    DIVIDE__thedivide__r_sign := s43.DIVIDE__thedivide__r_sign
    DIVIDE__thedivide__r_z := s40.DIVIDE__thedivide__r_z
    DIVIDE__thedivide__zero_divisor := s34.DIVIDE__thedivide__zero_divisor
    FWD_OPERATION__r_op_opn := s25.FWD_OPERATION__r_op_opn
    GEN_ALU_PC__r_alu_pc := s53.GEN_ALU_PC__r_alu_pc
    GEN_ALU_PHASE__r_alu_phase := s47.GEN_ALU_PHASE__r_alu_phase
    GEN_CLOCK_GATE__r_clken := s67.GEN_CLOCK_GATE__r_clken
    GEN_IHALT_PHASE__r_ihalt_phase := s79.GEN_IHALT_PHASE__r_ihalt_phase
    GEN_OPLOCK__r_op_lock := s20.GEN_OPLOCK__r_op_lock
    GEN_OP_PIPE__r_op_pipe := s13.GEN_OP_PIPE__r_op_pipe
    GEN_OP_STALL__r_cc_invalid_for_dcd := s1.GEN_OP_STALL__r_cc_invalid_for_dcd
    GEN_OP_STALL__r_pending_sreg_write := s2.GEN_OP_STALL__r_pending_sreg_write
    GEN_OP_WR__r_op_wR := s23.GEN_OP_WR__r_op_wR
    GEN_PENDING_BREAK__r_break_pending := s64.GEN_PENDING_BREAK__r_break_pending
    GEN_PENDING_INTERRUPT__r_pending_interrupt := s69.GEN_PENDING_INTERRUPT__r_pending_interrupt
    GEN_PENDING_INTERRUPT__r_user_stepped := s68.GEN_PENDING_INTERRUPT__r_user_stepped
    GEN_UHALT_PHASE__r_uhalt_phase := s80.GEN_UHALT_PHASE__r_uhalt_phase
    OPT_CIS_OP_PHASE__r_op_phase := s26.OPT_CIS_OP_PHASE__r_op_phase
    OP_REG_ADVANEC__r_op_Aid := s14.OP_REG_ADVANEC__r_op_Aid
    OP_REG_ADVANEC__r_op_Bid := s14.OP_REG_ADVANEC__r_op_Bid
    OP_REG_ADVANEC__r_op_R := s14.OP_REG_ADVANEC__r_op_R
    OP_REG_ADVANEC__r_op_rA := s14.OP_REG_ADVANEC__r_op_rA
    OP_REG_ADVANEC__r_op_rB := s14.OP_REG_ADVANEC__r_op_rB
    SETDBG__r_dbg_reg := s88.SETDBG__r_dbg_reg
    SET_ALU_ILLEGAL__r_alu_illegal := s54.SET_ALU_ILLEGAL__r_alu_illegal
    SET_GIE__r_gie := s70.SET_GIE__r_gie
    SET_OP_PC__r_op_pc := s24.SET_OP_PC__r_op_pc
    SET_TRAP_N_UBREAK__r_trap := s71.SET_TRAP_N_UBREAK__r_trap
    SET_TRAP_N_UBREAK__r_ubreak := s72.SET_TRAP_N_UBREAK__r_ubreak
    SET_USER_BUSERR__r_ubus_err_flag := s76.SET_USER_BUSERR__r_ubus_err_flag
    SET_USER_ILLEGAL_INSN__r_ill_err_u := s74.SET_USER_ILLEGAL_INSN__r_ill_err_u
    SET_USER_PC__r_upc := s81.SET_USER_PC__r_upc
    alu_reg := s48.alu_reg
    alu_wF := s46.alu_wF
    alu_wR := s46.alu_wR
    break_en := s63.break_en
    dbg_clear_pipe := s52.dbg_clear_pipe
    dbg_val := s51.dbg_val
    dbgv := s50.dbgv
    doalu__c := s29.doalu__c
    doalu__keep_sgn_on_ovfl := s28.doalu__keep_sgn_on_ovfl
    doalu__o_c := s29.doalu__o_c
    doalu__o_valid := s31.doalu__o_valid
    doalu__pre_sign := s29.doalu__pre_sign
    doalu__r_busy := s30.doalu__r_busy
    doalu__set_ovfl := s27.doalu__set_ovfl
    flags := s61.flags
    ibus_err_flag := s75.ibus_err_flag
    iflags := s62.iflags
    ill_err_i := s73.ill_err_i
    instruction_decoder__GEN_CIS_PHASE__r_phase := s3.instruction_decoder__GEN_CIS_PHASE__r_phase
    instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_branch_pc := s9.instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_branch_pc
    instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_early_branch := s8.instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_early_branch
    instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_early_branch_stb := s8.instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_early_branch_stb
    instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_ljmp := s7.instruction_decoder__GEN_EARLY_BRANCH_LOGIC__r_ljmp
    instruction_decoder__GEN_OPIPE__r_insn_is_pipeable := s10.instruction_decoder__GEN_OPIPE__r_insn_is_pipeable
    instruction_decoder__GEN_OPIPE__r_pipe := s11.instruction_decoder__GEN_OPIPE__r_pipe
    instruction_decoder__o_ALU := s6.instruction_decoder__o_ALU
    instruction_decoder__o_DV := s6.instruction_decoder__o_DV
    instruction_decoder__o_FP := s6.instruction_decoder__o_FP
    instruction_decoder__o_M := s6.instruction_decoder__o_M
    instruction_decoder__o_break := s6.instruction_decoder__o_break
    instruction_decoder__o_cond := s6.instruction_decoder__o_cond
    instruction_decoder__o_dcdA := s6.instruction_decoder__o_dcdA
    instruction_decoder__o_dcdB := s6.instruction_decoder__o_dcdB
    instruction_decoder__o_dcdR := s6.instruction_decoder__o_dcdR
    instruction_decoder__o_illegal := s4.instruction_decoder__o_illegal
    instruction_decoder__o_lock := s6.instruction_decoder__o_lock
    instruction_decoder__o_op := s6.instruction_decoder__o_op
    instruction_decoder__o_pc := s5.instruction_decoder__o_pc
    instruction_decoder__o_rA := s6.instruction_decoder__o_rA
    instruction_decoder__o_rB := s6.instruction_decoder__o_rB
    instruction_decoder__o_sim := s6.instruction_decoder__o_sim
    instruction_decoder__o_sim_immv := s6.instruction_decoder__o_sim_immv
    instruction_decoder__o_wF := s6.instruction_decoder__o_wF
    instruction_decoder__o_wR := s6.instruction_decoder__o_wR
    instruction_decoder__o_zI := s6.instruction_decoder__o_zI
    instruction_decoder__r_I := s6.instruction_decoder__r_I
    instruction_decoder__r_nxt_half := s6.instruction_decoder__r_nxt_half
    instruction_decoder__r_valid := s12.instruction_decoder__r_valid
    ipc := s82.ipc
    last_write_to_cc := s84.last_write_to_cc
    mem_pc_valid := s56.mem_pc_valid
    new_pc := s87.new_pc
    o_dbg_cc := s89.o_dbg_cc
    op_Rcc := s14.op_Rcc
    op_illegal := s21.op_illegal
    op_valid := s18.op_valid
    op_valid_alu := s18.op_valid_alu
    op_valid_div := s18.op_valid_div
    op_valid_fpu := s18.op_valid_fpu
    op_valid_mem := s18.op_valid_mem
    op_wF := s22.op_wF
    pf_pc := s83.pf_pc
    r_alu_pc_valid := s55.r_alu_pc_valid
    r_clear_icache := s85.r_clear_icache
    r_dbg_stall := s91.r_dbg_stall
    r_halted := s90.r_halted
    r_op_Av := s15.r_op_Av
    r_op_Bv := s16.r_op_Bv
    r_op_F := s17.r_op_F
    r_op_break := s19.r_op_break
    regset := s60.regset
    sleep := s65.sleep
    user_step := s66.user_step
    wr_index := s49.wr_index
    w_uflags := s.w_uflags
    w_iflags := s.w_iflags
    break_pending := s.break_pending
    trap := s.trap
    gie := s.gie
    ubreak := s.ubreak
    pending_interrupt := s.pending_interrupt
    stepped := s.stepped
    step := s.step
    ill_err_u := s.ill_err_u
    ubus_err_flag := s.ubus_err_flag
    idiv_err_flag := s.idiv_err_flag
    udiv_err_flag := s.udiv_err_flag
    ifpu_err_flag := s.ifpu_err_flag
    ufpu_err_flag := s.ufpu_err_flag
    ihalt_phase := s.ihalt_phase
    uhalt_phase := s.uhalt_phase
    master_ce := s.master_ce
    master_stall := s.master_stall
    clear_pipeline := s.clear_pipeline
    pf_gie := s.pf_gie
    dcd_opn := s.dcd_opn
    dcd_ce := s.dcd_ce
    dcd_phase := s.dcd_phase
    dcd_A := s.dcd_A
    dcd_B := s.dcd_B
    dcd_R := s.dcd_R
    dcd_preA := s.dcd_preA
    dcd_preB := s.dcd_preB
    dcd_Acc := s.dcd_Acc
    dcd_Bcc := s.dcd_Bcc
    dcd_Apc := s.dcd_Apc
    dcd_Bpc := s.dcd_Bpc
    dcd_Rcc := s.dcd_Rcc
    dcd_Rpc := s.dcd_Rpc
    dcd_F := s.dcd_F
    dcd_wR := s.dcd_wR
    dcd_rA := s.dcd_rA
    dcd_rB := s.dcd_rB
    dcd_ALU := s.dcd_ALU
    dcd_M := s.dcd_M
    dcd_DIV := s.dcd_DIV
    dcd_FP := s.dcd_FP
    dcd_wF := s.dcd_wF
    dcd_gie := s.dcd_gie
    dcd_break := s.dcd_break
    dcd_lock := s.dcd_lock
    dcd_pipe := s.dcd_pipe
    dcd_ljmp := s.dcd_ljmp
    dcd_valid := s.dcd_valid
    dcd_pc := s.dcd_pc
    dcd_I := s.dcd_I
    dcd_zI := s.dcd_zI
    dcd_A_stall := s.dcd_A_stall
    dcd_B_stall := s.dcd_B_stall
    dcd_F_stall := s.dcd_F_stall
    dcd_illegal := s.dcd_illegal
    dcd_early_branch := s.dcd_early_branch
    dcd_early_branch_stb := s.dcd_early_branch_stb
    dcd_branch_pc := s.dcd_branch_pc
    dcd_sim := s.dcd_sim
    dcd_sim_immv := s.dcd_sim_immv
    prelock_stall := s.prelock_stall
    last_lock_insn := s.last_lock_insn
    cc_invalid_for_dcd := s.cc_invalid_for_dcd
    pending_sreg_write := s.pending_sreg_write
    op_stall := s.op_stall
    op_opn := s.op_opn
    op_R := s.op_R
    op_Aid := s.op_Aid
    op_Bid := s.op_Bid
    op_rA := s.op_rA
    op_rB := s.op_rB
    op_pc := s.op_pc
    w_op_Av := s.w_op_Av
    w_op_Bv := s.w_op_Bv
    op_Av := s.op_Av
    op_Bv := s.op_Bv
    op_wR := s.op_wR
    op_gie := s.op_gie
    op_Fl := s.op_Fl
    op_F := s.op_F
    op_ce := s.op_ce
    op_phase := s.op_phase
    op_pipe := s.op_pipe
    w_op_valid := s.w_op_valid
    op_lowpower_clear := s.op_lowpower_clear
    w_cpu_info := s.w_cpu_info
    op_break := s.op_break
    op_lock := s.op_lock
    op_sim := s.op_sim
    op_sim_immv := s.op_sim_immv
    alu_sim := s.alu_sim
    alu_sim_immv := s.alu_sim_immv
    alu_pc := s.alu_pc
    alu_pc_valid := s.alu_pc_valid
    alu_phase := s.alu_phase
    alu_ce := s.alu_ce
    alu_stall := s.alu_stall
    alu_result := s.alu_result
    alu_flags := s.alu_flags
    alu_valid := s.alu_valid
    alu_busy := s.alu_busy
    set_cond := s.set_cond
    alu_gie := s.alu_gie
    alu_illegal := s.alu_illegal
    mem_ce := s.mem_ce
    mem_stalled := s.mem_stalled
    div_ce := s.div_ce
    div_error := s.div_error
    div_busy := s.div_busy
    div_valid := s.div_valid
    div_result := s.div_result
    div_flags := s.div_flags
    fpu_ce := s.fpu_ce
    fpu_error := s.fpu_error
    fpu_busy := s.fpu_busy
    fpu_valid := s.fpu_valid
    fpu_result := s.fpu_result
    fpu_flags := s.fpu_flags
    wr_write_pc := s.wr_write_pc
    wr_write_cc := s.wr_write_cc
    wr_write_scc := s.wr_write_scc
    wr_write_ucc := s.wr_write_ucc
    wr_reg_id := s.wr_reg_id
    w_switch_to_interrupt := s.w_switch_to_interrupt
    w_release_from_interrupt := s.w_release_from_interrupt
    upc := s.upc
    cc_write_hold := s.cc_write_hold
    w_clken := s.w_clken
    GEN_ALU_STALL__unused_alu_stall := s.GEN_ALU_STALL__unused_alu_stall
    dcd_full_R := s.dcd_full_R
    dcd_full_A := s.dcd_full_A
    dcd_full_B := s.dcd_full_B
    instruction_decoder__i_clk := s.instruction_decoder__i_clk
    instruction_decoder__i_reset := s.instruction_decoder__i_reset
    instruction_decoder__i_ce := s.instruction_decoder__i_ce
    instruction_decoder__i_stalled := s.instruction_decoder__i_stalled
    instruction_decoder__i_instruction := s.instruction_decoder__i_instruction
    instruction_decoder__i_gie := s.instruction_decoder__i_gie
    instruction_decoder__i_pc := s.instruction_decoder__i_pc
    instruction_decoder__i_pf_valid := s.instruction_decoder__i_pf_valid
    instruction_decoder__i_illegal := s.instruction_decoder__i_illegal
    instruction_decoder__o_valid := s.instruction_decoder__o_valid
    instruction_decoder__o_phase := s.instruction_decoder__o_phase
    instruction_decoder__o_preA := s.instruction_decoder__o_preA
    instruction_decoder__o_preB := s.instruction_decoder__o_preB
    instruction_decoder__o_I := s.instruction_decoder__o_I
    instruction_decoder__o_early_branch := s.instruction_decoder__o_early_branch
    instruction_decoder__o_early_branch_stb := s.instruction_decoder__o_early_branch_stb
    instruction_decoder__o_branch_pc := s.instruction_decoder__o_branch_pc
    instruction_decoder__o_ljmp := s.instruction_decoder__o_ljmp
    instruction_decoder__o_pipe := s.instruction_decoder__o_pipe
    instruction_decoder__w_op := s.instruction_decoder__w_op
    instruction_decoder__w_ldi := s.instruction_decoder__w_ldi
    instruction_decoder__w_mov := s.instruction_decoder__w_mov
    instruction_decoder__w_cmptst := s.instruction_decoder__w_cmptst
    instruction_decoder__w_ldilo := s.instruction_decoder__w_ldilo
    instruction_decoder__w_ALU := s.instruction_decoder__w_ALU
    instruction_decoder__w_brev := s.instruction_decoder__w_brev
    instruction_decoder__w_noop := s.instruction_decoder__w_noop
    instruction_decoder__w_lock := s.instruction_decoder__w_lock
    instruction_decoder__w_sim := s.instruction_decoder__w_sim
    instruction_decoder__w_break := s.instruction_decoder__w_break
    instruction_decoder__w_special := s.instruction_decoder__w_special
    instruction_decoder__w_add := s.instruction_decoder__w_add
    instruction_decoder__w_mpy := s.instruction_decoder__w_mpy
    instruction_decoder__w_dcdR := s.instruction_decoder__w_dcdR
    instruction_decoder__w_dcdB := s.instruction_decoder__w_dcdB
    instruction_decoder__w_dcdA := s.instruction_decoder__w_dcdA
    instruction_decoder__w_dcdR_pc := s.instruction_decoder__w_dcdR_pc
    instruction_decoder__w_dcdR_cc := s.instruction_decoder__w_dcdR_cc
    instruction_decoder__w_dcdA_pc := s.instruction_decoder__w_dcdA_pc
    instruction_decoder__w_dcdA_cc := s.instruction_decoder__w_dcdA_cc
    instruction_decoder__w_dcdB_pc := s.instruction_decoder__w_dcdB_pc
    instruction_decoder__w_dcdB_cc := s.instruction_decoder__w_dcdB_cc
    instruction_decoder__w_cond := s.instruction_decoder__w_cond
    instruction_decoder__w_wF := s.instruction_decoder__w_wF
    instruction_decoder__w_mem := s.instruction_decoder__w_mem
    instruction_decoder__w_sto := s.instruction_decoder__w_sto
    instruction_decoder__w_div := s.instruction_decoder__w_div
    instruction_decoder__w_fpu := s.instruction_decoder__w_fpu
    instruction_decoder__w_wR := s.instruction_decoder__w_wR
    instruction_decoder__w_rA := s.instruction_decoder__w_rA
    instruction_decoder__w_rB := s.instruction_decoder__w_rB
    instruction_decoder__w_wR_n := s.instruction_decoder__w_wR_n
    instruction_decoder__w_ljmp := s.instruction_decoder__w_ljmp
    instruction_decoder__w_ljmp_dly := s.instruction_decoder__w_ljmp_dly
    instruction_decoder__w_cis_ljmp := s.instruction_decoder__w_cis_ljmp
    instruction_decoder__iword := s.instruction_decoder__iword
    instruction_decoder__pf_valid := s.instruction_decoder__pf_valid
    instruction_decoder__w_I := s.instruction_decoder__w_I
    instruction_decoder__w_Iz := s.instruction_decoder__w_Iz
    instruction_decoder__insn_is_pipeable := s.instruction_decoder__insn_is_pipeable
    instruction_decoder__illegal_shift := s.instruction_decoder__illegal_shift
    instruction_decoder__GEN_CIS_IMMEDIATE__w_halfI := s.instruction_decoder__GEN_CIS_IMMEDIATE__w_halfI
    instruction_decoder__GEN_CIS_IMMEDIATE__w_halfbits := s.instruction_decoder__GEN_CIS_IMMEDIATE__w_halfbits
    instruction_decoder__GEN_EARLY_BRANCH_LOGIC__w_add_to_pc := s.instruction_decoder__GEN_EARLY_BRANCH_LOGIC__w_add_to_pc
    instruction_decoder__possibly_unused := s.instruction_decoder__possibly_unused
    GEN_DISTRIBUTED_REGS__unused_prereg_addrs := s.GEN_DISTRIBUTED_REGS__unused_prereg_addrs
    NO_OP_SIM__op_sim_unused := s.NO_OP_SIM__op_sim_unused
    doalu__i_clk := s.doalu__i_clk
    doalu__i_reset := s.doalu__i_reset
    doalu__i_stb := s.doalu__i_stb
    doalu__i_op := s.doalu__i_op
    doalu__i_a := s.doalu__i_a
    doalu__i_b := s.doalu__i_b
    doalu__o_f := s.doalu__o_f
    doalu__o_busy := s.doalu__o_busy
    doalu__w_brev_result := s.doalu__w_brev_result
    doalu__z := s.doalu__z
    doalu__n := s.doalu__n
    doalu__v := s.doalu__v
    doalu__vx := s.doalu__vx
    doalu__w_lsr_result := s.doalu__w_lsr_result
    doalu__w_asr_result := s.doalu__w_asr_result
    doalu__w_lsl_result := s.doalu__w_lsl_result
    doalu__mpy_result := s.doalu__mpy_result
    doalu__mpyhi := s.doalu__mpyhi
    doalu__mpybusy := s.doalu__mpybusy
    doalu__mpydone := s.doalu__mpydone
    doalu__this_is_a_multiply_op := s.doalu__this_is_a_multiply_op
    doalu__IMPLEMENT_SHIFTS__w_pre_asr_input := s.doalu__IMPLEMENT_SHIFTS__w_pre_asr_input
    doalu__IMPLEMENT_SHIFTS__w_pre_asr_shifted := s.doalu__IMPLEMENT_SHIFTS__w_pre_asr_shifted
    doalu__thempy__i_clk := s.doalu__thempy__i_clk
    doalu__thempy__i_reset := s.doalu__thempy__i_reset
    doalu__thempy__i_stb := s.doalu__thempy__i_stb
    doalu__thempy__i_op := s.doalu__thempy__i_op
    doalu__thempy__i_a := s.doalu__thempy__i_a
    doalu__thempy__i_b := s.doalu__thempy__i_b
    doalu__thempy__o_valid := s.doalu__thempy__o_valid
    doalu__thempy__o_busy := s.doalu__thempy__o_busy
    doalu__thempy__o_result := s.doalu__thempy__o_result
    doalu__thempy__o_hi := s.doalu__thempy__o_hi
    DIVIDE__thedivide__i_clk := s.DIVIDE__thedivide__i_clk
    DIVIDE__thedivide__i_reset := s.DIVIDE__thedivide__i_reset
    DIVIDE__thedivide__i_wr := s.DIVIDE__thedivide__i_wr
    DIVIDE__thedivide__i_signed := s.DIVIDE__thedivide__i_signed
    DIVIDE__thedivide__i_numerator := s.DIVIDE__thedivide__i_numerator
    DIVIDE__thedivide__i_denominator := s.DIVIDE__thedivide__i_denominator
    DIVIDE__thedivide__o_flags := s.DIVIDE__thedivide__o_flags
    DIVIDE__thedivide__diff := s.DIVIDE__thedivide__diff
    DIVIDE__thedivide__w_n := s.DIVIDE__thedivide__w_n
    cpu_sim := s.cpu_sim
    unused := s.unused
    o_clken := s.o_clken
    o_dbg_stall := s.o_dbg_stall
    o_dbg_reg := s.o_dbg_reg
    o_break := s.o_break
    o_pf_new_pc := s.o_pf_new_pc
    o_clear_icache := s.o_clear_icache
    o_pf_ready := s.o_pf_ready
    o_pf_request_address := s.o_pf_request_address
    o_clear_dcache := s.o_clear_dcache
    o_mem_ce := s.o_mem_ce
    o_bus_lock := s.o_bus_lock
    o_mem_op := s.o_mem_op
    o_mem_addr := s.o_mem_addr
    o_mem_data := s.o_mem_data
    o_mem_lock_pc := s.o_mem_lock_pc
    o_mem_reg := s.o_mem_reg
    o_op_stall := s.o_op_stall
    o_pf_stall := s.o_pf_stall
    o_i_count := s.o_i_count
    o_debug := s.o_debug
    o_prof_stb := s.o_prof_stb
    o_prof_addr := s.o_prof_addr
    o_prof_ticks := s.o_prof_ticks
    SETDBG__pre_dbg_reg := s.SETDBG__pre_dbg_reg
    adf_ce_unconditional := s.adf_ce_unconditional
    avsrc := s.avsrc
    bisrc := s.bisrc
    bvsrc := s.bvsrc
    dcd_stalled := s.dcd_stalled
    debug_pc := s.debug_pc
    instruction_decoder__w_cis_op := s.instruction_decoder__w_cis_op
    instruction_decoder__w_fullI := s.instruction_decoder__w_fullI
    instruction_decoder__w_immsrc := s.instruction_decoder__w_immsrc
    pfpcset := s.pfpcset
    pfpcsrc := s.pfpcsrc
    w_op_BnI := s.w_op_BnI
    w_pcA_v := s.w_pcA_v
    w_pcB_v := s.w_pcB_v
    wr_flags := s.wr_flags
    wr_flags_ce := s.wr_flags_ce
    wr_gpreg_vl := s.wr_gpreg_vl
    wr_reg_ce := s.wr_reg_ce
    wr_spreg_vl := s.wr_spreg_vl
  }
  result

/-- step: pre-comb → parallel next-state commit → post-comb settle -/
def step (s : zipcoreState) (i : zipcoreInputs) : zipcoreState :=
  let s_pre := comb s i
  let s_next := commit s_pre i
  let s_settled := comb s_next i
  s_settled

/-- Output helper -/
def outputs (s : zipcoreState) : zipcoreOutputs :=
  {
    o_clken := s.o_clken
    o_dbg_stall := s.o_dbg_stall
    o_dbg_reg := s.o_dbg_reg
    o_dbg_cc := s.o_dbg_cc
    o_break := s.o_break
    o_pf_new_pc := s.o_pf_new_pc
    o_clear_icache := s.o_clear_icache
    o_pf_ready := s.o_pf_ready
    o_pf_request_address := s.o_pf_request_address
    o_clear_dcache := s.o_clear_dcache
    o_mem_ce := s.o_mem_ce
    o_bus_lock := s.o_bus_lock
    o_mem_op := s.o_mem_op
    o_mem_addr := s.o_mem_addr
    o_mem_data := s.o_mem_data
    o_mem_lock_pc := s.o_mem_lock_pc
    o_mem_reg := s.o_mem_reg
    o_op_stall := s.o_op_stall
    o_pf_stall := s.o_pf_stall
    o_i_count := s.o_i_count
    o_debug := s.o_debug
    o_prof_stb := s.o_prof_stb
    o_prof_addr := s.o_prof_addr
    o_prof_ticks := s.o_prof_ticks
  }


end zipcore
