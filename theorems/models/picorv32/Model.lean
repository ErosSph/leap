/-
自动生成的 Lean 4 代码
源模块：picorv32
生成时间：Lean 4 RTL 编译器
-/

import Std
set_option linter.unusedVariables false
set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace picorv32

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

structure picorv32StateBlock0 where
  alu_out_0_q : Bool
  alu_out_q : BitVec 32
  alu_wait : Bool
  alu_wait_2 : Bool
  cached_ascii_instr : BitVec 64
  cached_insn_imm : BitVec 32
  cached_insn_opcode : BitVec 32
  cached_insn_rd : BitVec 5
  cached_insn_rs1 : BitVec 5
  cached_insn_rs2 : BitVec 5
  clear_prefetched_high_word_q : Bool
  compressed_instr : Bool
  count_cycle : BitVec 64
  count_instr : BitVec 64
  cpu_state : BitVec 8
  cpuregs : BitVec 1024
  current_pc : BitVec 32
  dbg_insn_addr : BitVec 32
  dbg_next : Bool
  dbg_rs1val : BitVec 32
  dbg_rs1val_valid : Bool
  dbg_rs2val : BitVec 32
  dbg_rs2val_valid : Bool
  dbg_valid_insn : Bool
  decoded_imm : BitVec 32
  decoded_imm_j : BitVec 32
  decoded_rd : BitVec 5
  decoded_rs1 : BitVec 5
  decoded_rs2 : BitVec 5
  decoder_pseudo_trigger : Bool
  decoder_pseudo_trigger_q : Bool
  decoder_trigger : Bool
  decoder_trigger_q : Bool
  do_waitirq : Bool
  eoi : BitVec 32
  instr_add : Bool
  instr_addi : Bool
  instr_and : Bool
  instr_andi : Bool
  instr_auipc : Bool
  instr_beq : Bool
  instr_bge : Bool
  instr_bgeu : Bool
  instr_blt : Bool
  instr_bltu : Bool
  instr_bne : Bool
  instr_ecall_ebreak : Bool
  instr_fence : Bool
  instr_getq : Bool
  instr_jal : Bool
  instr_jalr : Bool
  instr_lb : Bool
  instr_lbu : Bool
  instr_lh : Bool
  instr_lhu : Bool
  instr_lui : Bool
  instr_lw : Bool
  instr_maskirq : Bool
  instr_or : Bool
  instr_ori : Bool
  instr_rdcycle : Bool
  instr_rdcycleh : Bool
  instr_rdinstr : Bool
  instr_rdinstrh : Bool

structure picorv32StateBlock1 where
  instr_retirq : Bool
  instr_sb : Bool
  instr_setq : Bool
  instr_sh : Bool
  instr_sll : Bool
  instr_slli : Bool
  instr_slt : Bool
  instr_slti : Bool
  instr_sltiu : Bool
  instr_sltu : Bool
  instr_sra : Bool
  instr_srai : Bool
  instr_srl : Bool
  instr_srli : Bool
  instr_sub : Bool
  instr_sw : Bool
  instr_timer : Bool
  instr_waitirq : Bool
  instr_xor : Bool
  instr_xori : Bool
  irq_active : Bool
  irq_delay : Bool
  irq_mask : BitVec 32
  irq_pending : BitVec 32
  irq_state : BitVec 2
  is_alu_reg_imm : Bool
  is_alu_reg_reg : Bool
  is_beq_bne_blt_bge_bltu_bgeu : Bool
  is_compare : Bool
  is_jalr_addi_slti_sltiu_xori_ori_andi : Bool
  is_lb_lh_lw_lbu_lhu : Bool
  is_lbu_lhu_lw : Bool
  is_lui_auipc_jal : Bool
  is_lui_auipc_jal_jalr_addi_add_sub : Bool
  is_sb_sh_sw : Bool
  is_sll_srl_sra : Bool
  is_slli_srli_srai : Bool
  is_slti_blt_slt : Bool
  is_sltiu_bltu_sltu : Bool
  last_mem_valid : Bool
  latched_branch : Bool
  latched_compr : Bool
  latched_is_lb : Bool
  latched_is_lh : Bool
  latched_is_lu : Bool
  latched_rd : BitVec 5
  latched_stalu : Bool
  latched_store : Bool
  latched_trace : Bool
  mem_16bit_buffer : BitVec 16
  mem_addr : BitVec 32
  mem_do_prefetch : Bool
  mem_do_rdata : Bool
  mem_do_rinst : Bool
  mem_do_wdata : Bool
  mem_instr : Bool
  mem_la_firstword_reg : Bool
  mem_la_secondword : Bool
  mem_rdata_q : BitVec 32
  mem_state : BitVec 2
  mem_valid : Bool
  mem_wdata : BitVec 32
  mem_wordsize : BitVec 2
  mem_wstrb : BitVec 4

structure picorv32StateBlock2 where
  next_insn_opcode : BitVec 32
  next_irq_pending : BitVec 32
  pcpi_insn : BitVec 32
  pcpi_timeout : Bool
  pcpi_timeout_counter : BitVec 4
  pcpi_valid : Bool
  prefetched_high_word : Bool
  q_ascii_instr : BitVec 64
  q_insn_imm : BitVec 32
  q_insn_opcode : BitVec 32
  q_insn_rd : BitVec 5
  q_insn_rs1 : BitVec 5
  q_insn_rs2 : BitVec 5
  reg_next_pc : BitVec 32
  reg_op1 : BitVec 32
  reg_op2 : BitVec 32
  reg_out : BitVec 32
  reg_pc : BitVec 32
  reg_sh : BitVec 5
  set_mem_do_rdata : Bool
  set_mem_do_rinst : Bool
  set_mem_do_wdata : Bool
  timer : BitVec 32
  trace_data : BitVec 36
  trace_valid : Bool
  trap : Bool
  dbg_mem_valid : Bool
  dbg_mem_instr : Bool
  dbg_mem_ready : Bool
  dbg_mem_addr : BitVec 32
  dbg_mem_wdata : BitVec 32
  dbg_mem_wstrb : BitVec 4
  dbg_mem_rdata : BitVec 32
  next_pc : BitVec 32
  pcpi_mul_wr : Bool
  pcpi_mul_rd : BitVec 32
  pcpi_mul_wait : Bool
  pcpi_mul_ready : Bool
  pcpi_div_wr : Bool
  pcpi_div_rd : BitVec 32
  pcpi_div_wait : Bool
  pcpi_div_ready : Bool
  mem_xfer : Bool
  mem_la_firstword : Bool
  mem_la_firstword_xfer : Bool
  mem_rdata_latched_noshuffle : BitVec 32
  mem_rdata_latched : BitVec 32
  mem_la_use_prefetched_high_word : Bool
  mem_busy : Bool
  mem_done : Bool
  instr_trap : Bool
  is_rdcycle_rdcycleh_rdinstr_rdinstrh : Bool
  launch_next_insn : Bool
  mem_la_read : Bool
  mem_la_write : Bool
  mem_la_addr : BitVec 32
  pcpi_rs1 : BitVec 32
  pcpi_rs2 : BitVec 32
  alu_add_sub : BitVec 32
  alu_eq : Bool
  alu_lts : Bool
  alu_ltu : Bool
  alu_out : BitVec 32
  alu_out_0 : Bool

structure picorv32StateBlock3 where
  alu_shl : BitVec 32
  alu_shr : BitVec 32
  clear_prefetched_high_word : Bool
  cpuregs_rs1 : BitVec 32
  cpuregs_rs2 : BitVec 32
  cpuregs_wrdata : BitVec 32
  cpuregs_write : Bool
  dbg_ascii_instr : BitVec 64
  dbg_ascii_state : BitVec 128
  dbg_insn_imm : BitVec 32
  dbg_insn_opcode : BitVec 32
  dbg_insn_rd : BitVec 5
  dbg_insn_rs1 : BitVec 5
  dbg_insn_rs2 : BitVec 5
  decoded_rs : BitVec 5
  mem_la_wdata : BitVec 32
  mem_la_wstrb : BitVec 4
  mem_rdata_word : BitVec 32
  new_ascii_instr : BitVec 64
  pcpi_int_rd : BitVec 32
  pcpi_int_ready : Bool
  pcpi_int_wait : Bool
  pcpi_int_wr : Bool

/-- picorv32 状态结构（保留全部字段的嵌套具体记录） -/
structure picorv32State extends picorv32StateBlock0, picorv32StateBlock1, picorv32StateBlock2, picorv32StateBlock3 where

/-- picorv32 输入信号 -/
structure picorv32Inputs where
  clk : Bool
  resetn : Bool
  mem_ready : Bool
  mem_rdata : BitVec 32
  pcpi_wr : Bool
  pcpi_rd : BitVec 32
  pcpi_wait : Bool
  pcpi_ready : Bool
  irq : BitVec 32
  __rtl_nondet_0000 : BitVec 32
  __rtl_nondet_0001 : BitVec 32
  __rtl_nondet_0003 : BitVec 16
  __rtl_nondet_0004 : BitVec 16
  __rtl_nondet_0002 : BitVec 32
  __rtl_nondet_0005 : BitVec 32
  __rtl_nondet_0006 : Bool
  __rtl_nondet_0007 : BitVec 32
  __rtl_nondet_0008 : BitVec 32
  __rtl_nondet_0009 : BitVec 32
  __rtl_nondet_0010 : BitVec 32
  __rtl_nondet_0011 : BitVec 32
  __rtl_nondet_0012 : BitVec 32
  __rtl_nondet_0013 : BitVec 32
  __rtl_nondet_0014 : BitVec 32
  __rtl_nondet_0015 : BitVec 32
  __rtl_nondet_0016 : BitVec 32
  __rtl_nondet_0017 : BitVec 32
  __rtl_nondet_0018 : BitVec 32
  __rtl_nondet_0019 : BitVec 32

/-- picorv32 输出信号 -/
structure picorv32Outputs where
  trap : Bool
  mem_valid : Bool
  mem_instr : Bool
  mem_addr : BitVec 32
  mem_wdata : BitVec 32
  mem_wstrb : BitVec 4
  mem_la_read : Bool
  mem_la_write : Bool
  mem_la_addr : BitVec 32
  mem_la_wdata : BitVec 32
  mem_la_wstrb : BitVec 4
  pcpi_valid : Bool
  pcpi_insn : BitVec 32
  pcpi_rs1 : BitVec 32
  pcpi_rs2 : BitVec 32
  eoi : BitVec 32
  trace_valid : Bool
  trace_data : BitVec 36

/-- picorv32 初始状态 -/
def init : picorv32State where
  alu_out_0_q := false
  alu_out_q := BitVec.ofNat 32 0
  alu_wait := false
  alu_wait_2 := false
  cached_ascii_instr := BitVec.ofNat 64 0
  cached_insn_imm := BitVec.ofNat 32 0
  cached_insn_opcode := BitVec.ofNat 32 0
  cached_insn_rd := BitVec.ofNat 5 0
  cached_insn_rs1 := BitVec.ofNat 5 0
  cached_insn_rs2 := BitVec.ofNat 5 0
  clear_prefetched_high_word_q := false
  compressed_instr := false
  count_cycle := BitVec.ofNat 64 0
  count_instr := BitVec.ofNat 64 0
  cpu_state := BitVec.ofNat 8 0
  cpuregs := BitVec.ofNat 1024 0
  current_pc := BitVec.ofNat 32 0
  dbg_insn_addr := BitVec.ofNat 32 0
  dbg_next := false
  dbg_rs1val := BitVec.ofNat 32 0
  dbg_rs1val_valid := false
  dbg_rs2val := BitVec.ofNat 32 0
  dbg_rs2val_valid := false
  dbg_valid_insn := false
  decoded_imm := BitVec.ofNat 32 0
  decoded_imm_j := BitVec.ofNat 32 0
  decoded_rd := BitVec.ofNat 5 0
  decoded_rs1 := BitVec.ofNat 5 0
  decoded_rs2 := BitVec.ofNat 5 0
  decoder_pseudo_trigger := false
  decoder_pseudo_trigger_q := false
  decoder_trigger := false
  decoder_trigger_q := false
  do_waitirq := false
  eoi := BitVec.ofNat 32 0
  instr_add := false
  instr_addi := false
  instr_and := false
  instr_andi := false
  instr_auipc := false
  instr_beq := false
  instr_bge := false
  instr_bgeu := false
  instr_blt := false
  instr_bltu := false
  instr_bne := false
  instr_ecall_ebreak := false
  instr_fence := false
  instr_getq := false
  instr_jal := false
  instr_jalr := false
  instr_lb := false
  instr_lbu := false
  instr_lh := false
  instr_lhu := false
  instr_lui := false
  instr_lw := false
  instr_maskirq := false
  instr_or := false
  instr_ori := false
  instr_rdcycle := false
  instr_rdcycleh := false
  instr_rdinstr := false
  instr_rdinstrh := false
  instr_retirq := false
  instr_sb := false
  instr_setq := false
  instr_sh := false
  instr_sll := false
  instr_slli := false
  instr_slt := false
  instr_slti := false
  instr_sltiu := false
  instr_sltu := false
  instr_sra := false
  instr_srai := false
  instr_srl := false
  instr_srli := false
  instr_sub := false
  instr_sw := false
  instr_timer := false
  instr_waitirq := false
  instr_xor := false
  instr_xori := false
  irq_active := false
  irq_delay := false
  irq_mask := BitVec.ofNat 32 0
  irq_pending := BitVec.ofNat 32 0
  irq_state := BitVec.ofNat 2 0
  is_alu_reg_imm := false
  is_alu_reg_reg := false
  is_beq_bne_blt_bge_bltu_bgeu := false
  is_compare := false
  is_jalr_addi_slti_sltiu_xori_ori_andi := false
  is_lb_lh_lw_lbu_lhu := false
  is_lbu_lhu_lw := false
  is_lui_auipc_jal := false
  is_lui_auipc_jal_jalr_addi_add_sub := false
  is_sb_sh_sw := false
  is_sll_srl_sra := false
  is_slli_srli_srai := false
  is_slti_blt_slt := false
  is_sltiu_bltu_sltu := false
  last_mem_valid := false
  latched_branch := false
  latched_compr := false
  latched_is_lb := false
  latched_is_lh := false
  latched_is_lu := false
  latched_rd := BitVec.ofNat 5 0
  latched_stalu := false
  latched_store := false
  latched_trace := false
  mem_16bit_buffer := BitVec.ofNat 16 0
  mem_addr := BitVec.ofNat 32 0
  mem_do_prefetch := false
  mem_do_rdata := false
  mem_do_rinst := false
  mem_do_wdata := false
  mem_instr := false
  mem_la_firstword_reg := false
  mem_la_secondword := false
  mem_rdata_q := BitVec.ofNat 32 0
  mem_state := BitVec.ofNat 2 0
  mem_valid := false
  mem_wdata := BitVec.ofNat 32 0
  mem_wordsize := BitVec.ofNat 2 0
  mem_wstrb := BitVec.ofNat 4 0
  next_insn_opcode := BitVec.ofNat 32 0
  next_irq_pending := BitVec.ofNat 32 0
  pcpi_insn := BitVec.ofNat 32 0
  pcpi_timeout := false
  pcpi_timeout_counter := BitVec.ofNat 4 0
  pcpi_valid := false
  prefetched_high_word := false
  q_ascii_instr := BitVec.ofNat 64 0
  q_insn_imm := BitVec.ofNat 32 0
  q_insn_opcode := BitVec.ofNat 32 0
  q_insn_rd := BitVec.ofNat 5 0
  q_insn_rs1 := BitVec.ofNat 5 0
  q_insn_rs2 := BitVec.ofNat 5 0
  reg_next_pc := BitVec.ofNat 32 0
  reg_op1 := BitVec.ofNat 32 0
  reg_op2 := BitVec.ofNat 32 0
  reg_out := BitVec.ofNat 32 0
  reg_pc := BitVec.ofNat 32 0
  reg_sh := BitVec.ofNat 5 0
  set_mem_do_rdata := false
  set_mem_do_rinst := false
  set_mem_do_wdata := false
  timer := BitVec.ofNat 32 0
  trace_data := BitVec.ofNat 36 0
  trace_valid := false
  trap := false
  dbg_mem_valid := false
  dbg_mem_instr := false
  dbg_mem_ready := false
  dbg_mem_addr := BitVec.ofNat 32 0
  dbg_mem_wdata := BitVec.ofNat 32 0
  dbg_mem_wstrb := BitVec.ofNat 4 0
  dbg_mem_rdata := BitVec.ofNat 32 0
  next_pc := BitVec.ofNat 32 0
  pcpi_mul_wr := false
  pcpi_mul_rd := BitVec.ofNat 32 0
  pcpi_mul_wait := false
  pcpi_mul_ready := false
  pcpi_div_wr := false
  pcpi_div_rd := BitVec.ofNat 32 0
  pcpi_div_wait := false
  pcpi_div_ready := false
  mem_xfer := false
  mem_la_firstword := false
  mem_la_firstword_xfer := false
  mem_rdata_latched_noshuffle := BitVec.ofNat 32 0
  mem_rdata_latched := BitVec.ofNat 32 0
  mem_la_use_prefetched_high_word := false
  mem_busy := false
  mem_done := false
  instr_trap := false
  is_rdcycle_rdcycleh_rdinstr_rdinstrh := false
  launch_next_insn := false
  mem_la_read := false
  mem_la_write := false
  mem_la_addr := BitVec.ofNat 32 0
  pcpi_rs1 := BitVec.ofNat 32 0
  pcpi_rs2 := BitVec.ofNat 32 0
  alu_add_sub := BitVec.ofNat 32 0
  alu_eq := false
  alu_lts := false
  alu_ltu := false
  alu_out := BitVec.ofNat 32 0
  alu_out_0 := false
  alu_shl := BitVec.ofNat 32 0
  alu_shr := BitVec.ofNat 32 0
  clear_prefetched_high_word := false
  cpuregs_rs1 := BitVec.ofNat 32 0
  cpuregs_rs2 := BitVec.ofNat 32 0
  cpuregs_wrdata := BitVec.ofNat 32 0
  cpuregs_write := false
  dbg_ascii_instr := BitVec.ofNat 64 0
  dbg_ascii_state := BitVec.ofNat 128 0
  dbg_insn_imm := BitVec.ofNat 32 0
  dbg_insn_opcode := BitVec.ofNat 32 0
  dbg_insn_rd := BitVec.ofNat 5 0
  dbg_insn_rs1 := BitVec.ofNat 5 0
  dbg_insn_rs2 := BitVec.ofNat 5 0
  decoded_rs := BitVec.ofNat 5 0
  mem_la_wdata := BitVec.ofNat 32 0
  mem_la_wstrb := BitVec.ofNat 4 0
  mem_rdata_word := BitVec.ofNat 32 0
  new_ascii_instr := BitVec.ofNat 64 0
  pcpi_int_rd := BitVec.ofNat 32 0
  pcpi_int_ready := false
  pcpi_int_wait := false
  pcpi_int_wr := false

/-- picorv32 默认输入值 -/
def defaultInputs : picorv32Inputs where
  clk := false
  resetn := true
  mem_ready := false
  mem_rdata := BitVec.ofNat 32 0
  pcpi_wr := false
  pcpi_rd := BitVec.ofNat 32 0
  pcpi_wait := false
  pcpi_ready := false
  irq := BitVec.ofNat 32 0
  __rtl_nondet_0000 := BitVec.ofNat 32 0
  __rtl_nondet_0001 := BitVec.ofNat 32 0
  __rtl_nondet_0003 := BitVec.ofNat 16 0
  __rtl_nondet_0004 := BitVec.ofNat 16 0
  __rtl_nondet_0002 := BitVec.ofNat 32 0
  __rtl_nondet_0005 := BitVec.ofNat 32 0
  __rtl_nondet_0006 := false
  __rtl_nondet_0007 := BitVec.ofNat 32 0
  __rtl_nondet_0008 := BitVec.ofNat 32 0
  __rtl_nondet_0009 := BitVec.ofNat 32 0
  __rtl_nondet_0010 := BitVec.ofNat 32 0
  __rtl_nondet_0011 := BitVec.ofNat 32 0
  __rtl_nondet_0012 := BitVec.ofNat 32 0
  __rtl_nondet_0013 := BitVec.ofNat 32 0
  __rtl_nondet_0014 := BitVec.ofNat 32 0
  __rtl_nondet_0015 := BitVec.ofNat 32 0
  __rtl_nondet_0016 := BitVec.ofNat 32 0
  __rtl_nondet_0017 := BitVec.ofNat 32 0
  __rtl_nondet_0018 := BitVec.ofNat 32 0
  __rtl_nondet_0019 := BitVec.ofNat 32 0

/-- 组合逻辑：assign_dbg_mem_valid -/
def assign_dbg_mem_valid (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let dbg_mem_valid := s.mem_valid
  { s with
    dbg_mem_valid := dbg_mem_valid
  }

/-- 组合逻辑：assign_dbg_mem_instr -/
def assign_dbg_mem_instr (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let dbg_mem_instr := s.mem_instr
  { s with
    dbg_mem_instr := dbg_mem_instr
  }

/-- 组合逻辑：assign_dbg_mem_ready -/
def assign_dbg_mem_ready (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let dbg_mem_ready := i.mem_ready
  { s with
    dbg_mem_ready := dbg_mem_ready
  }

/-- 组合逻辑：assign_dbg_mem_addr -/
def assign_dbg_mem_addr (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let dbg_mem_addr := s.mem_addr
  { s with
    dbg_mem_addr := dbg_mem_addr
  }

/-- 组合逻辑：assign_dbg_mem_wdata -/
def assign_dbg_mem_wdata (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let dbg_mem_wdata := s.mem_wdata
  { s with
    dbg_mem_wdata := dbg_mem_wdata
  }

/-- 组合逻辑：assign_dbg_mem_wstrb -/
def assign_dbg_mem_wstrb (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let dbg_mem_wstrb := s.mem_wstrb
  { s with
    dbg_mem_wstrb := dbg_mem_wstrb
  }

/-- 组合逻辑：assign_dbg_mem_rdata -/
def assign_dbg_mem_rdata (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let dbg_mem_rdata := i.mem_rdata
  { s with
    dbg_mem_rdata := dbg_mem_rdata
  }

/-- 组合逻辑：assign_pcpi_rs1 -/
def assign_pcpi_rs1 (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let pcpi_rs1 := s.reg_op1
  { s with
    pcpi_rs1 := pcpi_rs1
  }

/-- 组合逻辑：assign_pcpi_rs2 -/
def assign_pcpi_rs2 (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let pcpi_rs2 := s.reg_op2
  { s with
    pcpi_rs2 := pcpi_rs2
  }

/-- 组合逻辑：assign_pcpi_mul_wr -/
def assign_pcpi_mul_wr (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let pcpi_mul_wr := false
  { s with
    pcpi_mul_wr := pcpi_mul_wr
  }

/-- 组合逻辑：assign_pcpi_mul_rd -/
def assign_pcpi_mul_rd (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let pcpi_mul_rd := i.__rtl_nondet_0000
  { s with
    pcpi_mul_rd := pcpi_mul_rd
  }

/-- 组合逻辑：assign_pcpi_mul_wait -/
def assign_pcpi_mul_wait (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let pcpi_mul_wait := false
  { s with
    pcpi_mul_wait := pcpi_mul_wait
  }

/-- 组合逻辑：assign_pcpi_mul_ready -/
def assign_pcpi_mul_ready (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let pcpi_mul_ready := false
  { s with
    pcpi_mul_ready := pcpi_mul_ready
  }

/-- 组合逻辑：assign_pcpi_div_wr -/
def assign_pcpi_div_wr (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let pcpi_div_wr := false
  { s with
    pcpi_div_wr := pcpi_div_wr
  }

/-- 组合逻辑：assign_pcpi_div_rd -/
def assign_pcpi_div_rd (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let pcpi_div_rd := i.__rtl_nondet_0001
  { s with
    pcpi_div_rd := pcpi_div_rd
  }

/-- 组合逻辑：assign_pcpi_div_wait -/
def assign_pcpi_div_wait (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let pcpi_div_wait := false
  { s with
    pcpi_div_wait := pcpi_div_wait
  }

/-- 组合逻辑：assign_pcpi_div_ready -/
def assign_pcpi_div_ready (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let pcpi_div_ready := false
  { s with
    pcpi_div_ready := pcpi_div_ready
  }

/-- 组合逻辑：assign_mem_la_firstword -/
def assign_mem_la_firstword (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let mem_la_firstword := (((false && (s.mem_do_prefetch || s.mem_do_rinst)) && BitVec.getLsbD (s.next_pc) 1) && !(s.mem_la_secondword))
  { s with
    mem_la_firstword := mem_la_firstword
  }

/-- 组合逻辑：assign_mem_la_firstword_xfer -/
def assign_mem_la_firstword_xfer (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let mem_la_firstword_xfer := ((false && s.mem_xfer) && (if !(s.last_mem_valid) then s.mem_la_firstword else s.mem_la_firstword_reg))
  { s with
    mem_la_firstword_xfer := mem_la_firstword_xfer
  }

/-- 组合逻辑：assign_mem_la_use_prefetched_high_word -/
def assign_mem_la_use_prefetched_high_word (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let mem_la_use_prefetched_high_word := (((false && s.mem_la_firstword) && s.prefetched_high_word) && !(s.clear_prefetched_high_word))
  { s with
    mem_la_use_prefetched_high_word := mem_la_use_prefetched_high_word
  }

/-- 组合逻辑：assign_mem_xfer -/
def assign_mem_xfer (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let mem_xfer := ((s.mem_valid && i.mem_ready) || (s.mem_la_use_prefetched_high_word && s.mem_do_rinst))
  { s with
    mem_xfer := mem_xfer
  }

/-- 组合逻辑：assign_mem_busy -/
def assign_mem_busy (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let mem_busy := bvNonzero (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.mem_do_prefetch)) (boolToBitVec (s.mem_do_rinst))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.mem_do_rdata)) (boolToBitVec (s.mem_do_wdata))))
  { s with
    mem_busy := mem_busy
  }

/-- 组合逻辑：assign_mem_done -/
def assign_mem_done (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let mem_done := ((i.resetn && (((s.mem_xfer && bvNonzero (s.mem_state)) && ((s.mem_do_rinst || s.mem_do_rdata) || s.mem_do_wdata)) || (bvReduceAnd (s.mem_state) && s.mem_do_rinst))) && (!(s.mem_la_firstword) || (!(bvReduceAnd (BitVec.extractLsb 1 0 (s.mem_rdata_latched))) && s.mem_xfer)))
  { s with
    mem_done := mem_done
  }

/-- 组合逻辑：assign_mem_la_write -/
def assign_mem_la_write (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let mem_la_write := ((i.resetn && !(bvNonzero (s.mem_state))) && s.mem_do_wdata)
  { s with
    mem_la_write := mem_la_write
  }

/-- 组合逻辑：assign_mem_la_read -/
def assign_mem_la_read (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let mem_la_read := (i.resetn && (((!(s.mem_la_use_prefetched_high_word) && !(bvNonzero (s.mem_state))) && ((s.mem_do_rinst || s.mem_do_prefetch) || s.mem_do_rdata)) || ((((false && s.mem_xfer) && (if !(s.last_mem_valid) then s.mem_la_firstword else s.mem_la_firstword_reg)) && !(s.mem_la_secondword)) && bvReduceAnd (BitVec.extractLsb 1 0 (s.mem_rdata_latched)))))
  { s with
    mem_la_read := mem_la_read
  }

/-- 组合逻辑：assign_mem_la_addr -/
def assign_mem_la_addr (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let mem_la_addr := (if (s.mem_do_prefetch || s.mem_do_rinst) then BitVec.append (n := 30) (m := 2) ((BitVec.extractLsb 31 2 (s.next_pc) + BitVec.setWidth 30 (boolToBitVec (s.mem_la_firstword_xfer)))) (BitVec.ofNat 2 0) else BitVec.append (n := 30) (m := 2) (BitVec.extractLsb 31 2 (s.reg_op1)) (BitVec.ofNat 2 0))
  { s with
    mem_la_addr := mem_la_addr
  }

/-- 组合逻辑：assign_mem_rdata_latched_noshuffle -/
def assign_mem_rdata_latched_noshuffle (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let mem_rdata_latched_noshuffle := (if (s.mem_xfer || false) then i.mem_rdata else s.mem_rdata_q)
  { s with
    mem_rdata_latched_noshuffle := mem_rdata_latched_noshuffle
  }

/-- 组合逻辑：assign_mem_rdata_latched -/
def assign_mem_rdata_latched (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let mem_rdata_latched := (if (false && s.mem_la_use_prefetched_high_word) then BitVec.append (n := 16) (m := 16) (i.__rtl_nondet_0003) (s.mem_16bit_buffer) else (if (false && s.mem_la_secondword) then BitVec.append (n := 16) (m := 16) (BitVec.extractLsb 15 0 (s.mem_rdata_latched_noshuffle)) (s.mem_16bit_buffer) else (if (false && s.mem_la_firstword) then BitVec.append (n := 16) (m := 16) (i.__rtl_nondet_0004) (BitVec.extractLsb 31 16 (s.mem_rdata_latched_noshuffle)) else s.mem_rdata_latched_noshuffle)))
  { s with
    mem_rdata_latched := mem_rdata_latched
  }

/-- 组合逻辑：assign_instr_trap -/
def assign_instr_trap (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let instr_trap := (true && !(bvNonzero (BitVec.append (n := 24) (m := 24) (BitVec.append (n := 12) (m := 12) (BitVec.append (n := 6) (m := 6) (BitVec.append (n := 3) (m := 3) (BitVec.append (n := 1) (m := 2) (boolToBitVec (s.instr_lui)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_auipc)) (boolToBitVec (s.instr_jal)))) (BitVec.append (n := 1) (m := 2) (boolToBitVec (s.instr_jalr)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_beq)) (boolToBitVec (s.instr_bne))))) (BitVec.append (n := 3) (m := 3) (BitVec.append (n := 1) (m := 2) (boolToBitVec (s.instr_blt)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_bge)) (boolToBitVec (s.instr_bltu)))) (BitVec.append (n := 1) (m := 2) (boolToBitVec (s.instr_bgeu)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_lb)) (boolToBitVec (s.instr_lh)))))) (BitVec.append (n := 6) (m := 6) (BitVec.append (n := 3) (m := 3) (BitVec.append (n := 1) (m := 2) (boolToBitVec (s.instr_lw)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_lbu)) (boolToBitVec (s.instr_lhu)))) (BitVec.append (n := 1) (m := 2) (boolToBitVec (s.instr_sb)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_sh)) (boolToBitVec (s.instr_sw))))) (BitVec.append (n := 3) (m := 3) (BitVec.append (n := 1) (m := 2) (boolToBitVec (s.instr_addi)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_slti)) (boolToBitVec (s.instr_sltiu)))) (BitVec.append (n := 1) (m := 2) (boolToBitVec (s.instr_xori)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_ori)) (boolToBitVec (s.instr_andi))))))) (BitVec.append (n := 12) (m := 12) (BitVec.append (n := 6) (m := 6) (BitVec.append (n := 3) (m := 3) (BitVec.append (n := 1) (m := 2) (boolToBitVec (s.instr_slli)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_srli)) (boolToBitVec (s.instr_srai)))) (BitVec.append (n := 1) (m := 2) (boolToBitVec (s.instr_add)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_sub)) (boolToBitVec (s.instr_sll))))) (BitVec.append (n := 3) (m := 3) (BitVec.append (n := 1) (m := 2) (boolToBitVec (s.instr_slt)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_sltu)) (boolToBitVec (s.instr_xor)))) (BitVec.append (n := 1) (m := 2) (boolToBitVec (s.instr_srl)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_sra)) (boolToBitVec (s.instr_or)))))) (BitVec.append (n := 6) (m := 6) (BitVec.append (n := 3) (m := 3) (BitVec.append (n := 1) (m := 2) (boolToBitVec (s.instr_and)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_rdcycle)) (boolToBitVec (s.instr_rdcycleh)))) (BitVec.append (n := 1) (m := 2) (boolToBitVec (s.instr_rdinstr)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_rdinstrh)) (boolToBitVec (s.instr_fence))))) (BitVec.append (n := 3) (m := 3) (BitVec.append (n := 1) (m := 2) (boolToBitVec (s.instr_getq)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_setq)) (boolToBitVec (s.instr_retirq)))) (BitVec.append (n := 1) (m := 2) (boolToBitVec (s.instr_maskirq)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_waitirq)) (boolToBitVec (s.instr_timer))))))))))
  { s with
    instr_trap := instr_trap
  }

/-- 组合逻辑：assign_is_rdcycle_rdcycleh_rdinstr_rdinstrh -/
def assign_is_rdcycle_rdcycleh_rdinstr_rdinstrh (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let is_rdcycle_rdcycleh_rdinstr_rdinstrh := bvNonzero (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_rdcycle)) (boolToBitVec (s.instr_rdcycleh))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_rdinstr)) (boolToBitVec (s.instr_rdinstrh))))
  { s with
    is_rdcycle_rdcycleh_rdinstr_rdinstrh := is_rdcycle_rdcycleh_rdinstr_rdinstrh
  }

/-- 组合逻辑：assign_next_pc -/
def assign_next_pc (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let next_pc := (if (s.latched_store && s.latched_branch) then (s.reg_out &&& ~~~(BitVec.ofNat 32 1)) else s.reg_next_pc)
  { s with
    next_pc := next_pc
  }

/-- 组合逻辑：assign_launch_next_insn -/
def assign_launch_next_insn (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let launch_next_insn := ((decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) && s.decoder_trigger) && (((true || s.irq_delay) || s.irq_active) || !(bvNonzero ((s.irq_pending &&& ~~~(s.irq_mask))))))
  { s with
    launch_next_insn := launch_next_insn
  }

/-- 组合逻辑：proc_alwayscomb -/
def proc_alwayscomb (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let pcpi_int_rd := (if decide (boolToNat (true) = boolToNat ((false && i.pcpi_ready))) then (if false then i.pcpi_rd else BitVec.ofNat 32 0) else (if decide (boolToNat (true) = boolToNat (((false || false) && s.pcpi_mul_ready))) then s.pcpi_mul_rd else (if decide (boolToNat (true) = boolToNat ((false && s.pcpi_div_ready))) then s.pcpi_div_rd else i.__rtl_nondet_0002)))
  let pcpi_int_ready := BitVec.getLsbD (BitVec.extractLsb 2 0 (BitVec.extractLsb 2 0 (boolToBitVec (bvNonzero (BitVec.append (n := 1) (m := 2) (boolToBitVec ((false && i.pcpi_ready))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (((false || false) && s.pcpi_mul_ready))) (boolToBitVec ((false && s.pcpi_div_ready))))))))) 0
  let pcpi_int_wait := BitVec.getLsbD (BitVec.extractLsb 2 0 (BitVec.extractLsb 2 0 (boolToBitVec (bvNonzero (BitVec.append (n := 1) (m := 2) (boolToBitVec ((false && i.pcpi_wait))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (((false || false) && s.pcpi_mul_wait))) (boolToBitVec ((false && s.pcpi_div_wait))))))))) 0
  let pcpi_int_wr := (if decide (boolToNat (true) = boolToNat ((false && i.pcpi_ready))) then BitVec.getLsbD ((if false then BitVec.extractLsb 31 0 (BitVec.append (n := 31) (m := 1) (BitVec.ofNat 31 0) (boolToBitVec (i.pcpi_wr))) else BitVec.extractLsb 31 0 (BitVec.ofNat 32 0))) 0 else (if decide (boolToNat (true) = boolToNat (((false || false) && s.pcpi_mul_ready))) then s.pcpi_mul_wr else (if decide (boolToNat (true) = boolToNat ((false && s.pcpi_div_ready))) then s.pcpi_div_wr else BitVec.getLsbD (BitVec.ofNat 32 0) 0)))
  { s with
    pcpi_int_rd := pcpi_int_rd
    pcpi_int_ready := pcpi_int_ready
    pcpi_int_wait := pcpi_int_wait
    pcpi_int_wr := pcpi_int_wr
  }

/-- 组合逻辑：proc_alwayscomb_1 -/
def proc_alwayscomb_1 (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let mem_la_wdata := (if decide ((s.mem_wordsize).toNat = (BitVec.ofNat 32 0).toNat) then s.reg_op2 else (if decide ((s.mem_wordsize).toNat = (BitVec.ofNat 32 1).toNat) then BitVec.append (n := 16) (m := 16) (BitVec.extractLsb 15 0 (s.reg_op2)) (BitVec.extractLsb 15 0 (s.reg_op2)) else (if decide ((s.mem_wordsize).toNat = (BitVec.ofNat 32 2).toNat) then BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.extractLsb 7 0 (s.reg_op2)) (BitVec.extractLsb 7 0 (s.reg_op2))) (BitVec.append (n := 8) (m := 8) (BitVec.extractLsb 7 0 (s.reg_op2)) (BitVec.extractLsb 7 0 (s.reg_op2))) else s.mem_la_wdata)))
  let mem_la_wstrb := (if decide ((s.mem_wordsize).toNat = (BitVec.ofNat 32 0).toNat) then BitVec.ofNat 4 15 else (if decide ((s.mem_wordsize).toNat = (BitVec.ofNat 32 1).toNat) then (if BitVec.getLsbD (s.reg_op1) 1 then BitVec.ofNat 4 12 else BitVec.ofNat 4 3) else (if decide ((s.mem_wordsize).toNat = (BitVec.ofNat 32 2).toNat) then BitVec.shiftLeft (BitVec.ofNat 4 1) (BitVec.extractLsb 1 0 (s.reg_op1)).toNat else s.mem_la_wstrb)))
  let mem_rdata_word := (if decide ((s.mem_wordsize).toNat = (BitVec.ofNat 32 0).toNat) then i.mem_rdata else (if decide ((s.mem_wordsize).toNat = (BitVec.ofNat 32 1).toNat) then (if decide (boolToNat (BitVec.getLsbD (s.reg_op1) 1) = boolToNat (false)) then BitVec.append (n := 16) (m := 16) (BitVec.ofNat 16 0) (BitVec.extractLsb 15 0 (i.mem_rdata)) else (if decide (boolToNat (BitVec.getLsbD (s.reg_op1) 1) = boolToNat (true)) then BitVec.append (n := 16) (m := 16) (BitVec.ofNat 16 0) (BitVec.extractLsb 31 16 (i.mem_rdata)) else s.mem_rdata_word)) else (if decide ((s.mem_wordsize).toNat = (BitVec.ofNat 32 2).toNat) then (if decide ((BitVec.extractLsb 1 0 (s.reg_op1)).toNat = (BitVec.ofNat 2 0).toNat) then BitVec.append (n := 24) (m := 8) (BitVec.ofNat 24 0) (BitVec.extractLsb 7 0 (i.mem_rdata)) else (if decide ((BitVec.extractLsb 1 0 (s.reg_op1)).toNat = (BitVec.ofNat 2 1).toNat) then BitVec.append (n := 24) (m := 8) (BitVec.ofNat 24 0) (BitVec.extractLsb 15 8 (i.mem_rdata)) else (if decide ((BitVec.extractLsb 1 0 (s.reg_op1)).toNat = (BitVec.ofNat 2 2).toNat) then BitVec.append (n := 24) (m := 8) (BitVec.ofNat 24 0) (BitVec.extractLsb 23 16 (i.mem_rdata)) else (if decide ((BitVec.extractLsb 1 0 (s.reg_op1)).toNat = (BitVec.ofNat 2 3).toNat) then BitVec.append (n := 24) (m := 8) (BitVec.ofNat 24 0) (BitVec.extractLsb 31 24 (i.mem_rdata)) else s.mem_rdata_word)))) else s.mem_rdata_word)))
  { s with
    mem_la_wdata := mem_la_wdata
    mem_la_wstrb := mem_la_wstrb
    mem_rdata_word := mem_rdata_word
  }

/-- 组合逻辑：proc_alwayscomb_2 -/
def proc_alwayscomb_2 (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let new_ascii_instr := (if s.instr_timer then BitVec.extractLsb 63 0 (BitVec.ofNat 64 499984983410) else (if s.instr_waitirq then BitVec.extractLsb 63 0 (BitVec.ofNat 64 33602627781096049) else (if s.instr_maskirq then BitVec.extractLsb 63 0 (BitVec.ofNat 64 30787920812667505) else (if s.instr_retirq then BitVec.extractLsb 63 0 (BitVec.ofNat 64 125780070330993) else (if s.instr_setq then BitVec.extractLsb 63 0 (BitVec.ofNat 64 1936028785) else (if s.instr_getq then BitVec.extractLsb 63 0 (BitVec.ofNat 64 1734702193) else (if s.instr_fence then BitVec.extractLsb 63 0 (BitVec.ofNat 64 439788397413) else (if s.instr_rdinstrh then BitVec.ofNat 64 8242829141099180648 else (if s.instr_rdinstr then BitVec.extractLsb 63 0 (BitVec.ofNat 64 32198551332418674) else (if s.instr_rdcycleh then BitVec.ofNat 64 8242822591005091176 else (if s.instr_rdcycle then BitVec.extractLsb 63 0 (BitVec.ofNat 64 32198525746113637) else (if s.instr_and then BitVec.extractLsb 63 0 (BitVec.ofNat 64 6385252) else (if s.instr_or then BitVec.extractLsb 63 0 (BitVec.ofNat 64 28530) else (if s.instr_sra then BitVec.extractLsb 63 0 (BitVec.ofNat 64 7565921) else (if s.instr_srl then BitVec.extractLsb 63 0 (BitVec.ofNat 64 7565932) else (if s.instr_xor then BitVec.extractLsb 63 0 (BitVec.ofNat 64 7892850) else (if s.instr_sltu then BitVec.extractLsb 63 0 (BitVec.ofNat 64 1936487541) else (if s.instr_slt then BitVec.extractLsb 63 0 (BitVec.ofNat 64 7564404) else (if s.instr_sll then BitVec.extractLsb 63 0 (BitVec.ofNat 64 7564396) else (if s.instr_sub then BitVec.extractLsb 63 0 (BitVec.ofNat 64 7566690) else (if s.instr_add then BitVec.extractLsb 63 0 (BitVec.ofNat 64 6382692) else (if s.instr_srai then BitVec.extractLsb 63 0 (BitVec.ofNat 64 1936875881) else (if s.instr_srli then BitVec.extractLsb 63 0 (BitVec.ofNat 64 1936878697) else (if s.instr_slli then BitVec.extractLsb 63 0 (BitVec.ofNat 64 1936485481) else (if s.instr_andi then BitVec.extractLsb 63 0 (BitVec.ofNat 64 1634624617) else (if s.instr_ori then BitVec.extractLsb 63 0 (BitVec.ofNat 64 7303785) else (if s.instr_xori then BitVec.extractLsb 63 0 (BitVec.ofNat 64 2020569705) else (if s.instr_sltiu then BitVec.extractLsb 63 0 (BitVec.ofNat 64 495740807541) else (if s.instr_slti then BitVec.extractLsb 63 0 (BitVec.ofNat 64 1936487529) else (if s.instr_addi then BitVec.extractLsb 63 0 (BitVec.ofNat 64 1633969257) else (if s.instr_sw then BitVec.extractLsb 63 0 (BitVec.ofNat 64 29559) else (if s.instr_sh then BitVec.extractLsb 63 0 (BitVec.ofNat 64 29544) else (if s.instr_sb then BitVec.extractLsb 63 0 (BitVec.ofNat 64 29538) else (if s.instr_lhu then BitVec.extractLsb 63 0 (BitVec.ofNat 64 7104629) else (if s.instr_lbu then BitVec.extractLsb 63 0 (BitVec.ofNat 64 7103093) else (if s.instr_lw then BitVec.extractLsb 63 0 (BitVec.ofNat 64 27767) else (if s.instr_lh then BitVec.extractLsb 63 0 (BitVec.ofNat 64 27752) else (if s.instr_lb then BitVec.extractLsb 63 0 (BitVec.ofNat 64 27746) else (if s.instr_bgeu then BitVec.extractLsb 63 0 (BitVec.ofNat 64 1650943349) else (if s.instr_bltu then BitVec.extractLsb 63 0 (BitVec.ofNat 64 1651274869) else (if s.instr_bge then BitVec.extractLsb 63 0 (BitVec.ofNat 64 6448997) else (if s.instr_blt then BitVec.extractLsb 63 0 (BitVec.ofNat 64 6450292) else (if s.instr_bne then BitVec.extractLsb 63 0 (BitVec.ofNat 64 6450789) else (if s.instr_beq then BitVec.extractLsb 63 0 (BitVec.ofNat 64 6448497) else (if s.instr_jalr then BitVec.extractLsb 63 0 (BitVec.ofNat 64 1784769650) else (if s.instr_jal then BitVec.extractLsb 63 0 (BitVec.ofNat 64 6971756) else (if s.instr_auipc then BitVec.extractLsb 63 0 (BitVec.ofNat 64 418581672035) else (if s.instr_lui then BitVec.extractLsb 63 0 (BitVec.ofNat 64 7107945) else BitVec.extractLsb 63 0 (BitVec.ofNat 64 0)))))))))))))))))))))))))))))))))))))))))))))))))
  { s with
    new_ascii_instr := new_ascii_instr
  }

/-- 组合逻辑：proc_alwayscomb_3 -/
def proc_alwayscomb_3 (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let dbg_ascii_instr := (if s.dbg_next then (if s.decoder_pseudo_trigger_q then s.cached_ascii_instr else s.new_ascii_instr) else s.q_ascii_instr)
  let dbg_insn_imm := (if s.dbg_next then (if s.decoder_pseudo_trigger_q then s.cached_insn_imm else s.decoded_imm) else s.q_insn_imm)
  let dbg_insn_opcode := (if s.dbg_next then (if s.decoder_pseudo_trigger_q then s.cached_insn_opcode else (if bvReduceAnd (BitVec.extractLsb 1 0 (s.next_insn_opcode)) then s.next_insn_opcode else BitVec.append (n := 16) (m := 16) (BitVec.ofNat 16 0) (BitVec.extractLsb 15 0 (s.next_insn_opcode)))) else s.q_insn_opcode)
  let dbg_insn_rd := (if s.dbg_next then (if s.decoder_pseudo_trigger_q then s.cached_insn_rd else s.decoded_rd) else s.q_insn_rd)
  let dbg_insn_rs1 := (if s.dbg_next then (if s.decoder_pseudo_trigger_q then s.cached_insn_rs1 else s.decoded_rs1) else s.q_insn_rs1)
  let dbg_insn_rs2 := (if s.dbg_next then (if s.decoder_pseudo_trigger_q then s.cached_insn_rs2 else s.decoded_rs2) else s.q_insn_rs2)
  { s with
    dbg_ascii_instr := dbg_ascii_instr
    dbg_insn_imm := dbg_insn_imm
    dbg_insn_opcode := dbg_insn_opcode
    dbg_insn_rd := dbg_insn_rd
    dbg_insn_rs1 := dbg_insn_rs1
    dbg_insn_rs2 := dbg_insn_rs2
  }

/-- 组合逻辑：proc_alwayscomb_4 -/
def proc_alwayscomb_4 (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let dbg_ascii_state := (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 1).toNat) then BitVec.extractLsb 127 0 (BitVec.ofNat 128 465541358957) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 2).toNat) then BitVec.extractLsb 127 0 (BitVec.ofNat 128 495874565485) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 4).toNat) then BitVec.extractLsb 127 0 (BitVec.ofNat 128 495672977012) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 8).toNat) then BitVec.extractLsb 127 0 (BitVec.ofNat 128 1702389091) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 16).toNat) then BitVec.extractLsb 127 0 (BitVec.ofNat 128 119178353865522) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then BitVec.extractLsb 127 0 (BitVec.ofNat 128 119178353865521) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then BitVec.extractLsb 127 0 (BitVec.ofNat 128 439788790632) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then BitVec.extractLsb 127 0 (BitVec.ofNat 128 1953653104) else BitVec.extractLsb 127 0 (BitVec.ofNat 128 0)))))))))
  { s with
    dbg_ascii_state := dbg_ascii_state
  }

/-- 组合逻辑：proc_alwayscomb_5 -/
def proc_alwayscomb_5 (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let alu_add_sub := (if s.instr_sub then (s.reg_op1 - s.reg_op2) else (s.reg_op1 + s.reg_op2))
  let alu_eq := decide ((s.reg_op1).toNat = (s.reg_op2).toNat)
  let alu_lts := decide (((BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (s.reg_op1)))) ^^^ BitVec.ofNat 32 2147483648)).toNat < ((BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (s.reg_op2)))) ^^^ BitVec.ofNat 32 2147483648)).toNat)
  let alu_ltu := decide ((s.reg_op1).toNat < (s.reg_op2).toNat)
  let alu_shl := BitVec.shiftLeft (s.reg_op1) (BitVec.extractLsb 4 0 (s.reg_op2)).toNat
  let alu_shr := BitVec.extractLsb 31 0 (BitVec.sshiftRight (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (BitVec.extractLsb 32 0 (BitVec.append (n := 1) (m := 32) (boolToBitVec ((if (s.instr_sra || s.instr_srai) then BitVec.getLsbD (s.reg_op1) 31 else false))) (s.reg_op1))))) (BitVec.extractLsb 4 0 (s.reg_op2)).toNat)
  { s with
    alu_add_sub := alu_add_sub
    alu_eq := alu_eq
    alu_lts := alu_lts
    alu_ltu := alu_ltu
    alu_shl := alu_shl
    alu_shr := alu_shr
  }

/-- 组合逻辑：proc_alwayscomb_6 -/
def proc_alwayscomb_6 (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let alu_out := (if decide (boolToNat (true) = boolToNat (s.is_lui_auipc_jal_jalr_addi_add_sub)) then s.alu_add_sub else (if decide (boolToNat (true) = boolToNat (s.is_compare)) then BitVec.extractLsb 31 0 (BitVec.append (n := 31) (m := 1) (BitVec.ofNat 31 0) (boolToBitVec ((if decide (boolToNat (true) = boolToNat (s.instr_beq)) then s.alu_eq else (if decide (boolToNat (true) = boolToNat (s.instr_bne)) then !(s.alu_eq) else (if decide (boolToNat (true) = boolToNat (s.instr_bge)) then !(s.alu_lts) else (if decide (boolToNat (true) = boolToNat (s.instr_bgeu)) then !(s.alu_ltu) else (if decide (boolToNat (true) = boolToNat ((s.is_slti_blt_slt && (!(false) || !(bvNonzero (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_beq)) (boolToBitVec (s.instr_bne))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_bge)) (boolToBitVec (s.instr_bgeu))))))))) then s.alu_lts else (if decide (boolToNat (true) = boolToNat ((s.is_sltiu_bltu_sltu && (!(false) || !(bvNonzero (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_beq)) (boolToBitVec (s.instr_bne))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_bge)) (boolToBitVec (s.instr_bgeu))))))))) then s.alu_ltu else BitVec.getLsbD (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (i.__rtl_nondet_0007))) 0))))))))) else (if decide (boolToNat (true) = boolToNat ((s.instr_xori || s.instr_xor))) then (s.reg_op1 ^^^ s.reg_op2) else (if decide (boolToNat (true) = boolToNat ((s.instr_ori || s.instr_or))) then (s.reg_op1 ||| s.reg_op2) else (if decide (boolToNat (true) = boolToNat ((s.instr_andi || s.instr_and))) then (s.reg_op1 &&& s.reg_op2) else (if decide (boolToNat (true) = boolToNat ((false && (s.instr_sll || s.instr_slli)))) then s.alu_shl else (if decide (boolToNat (true) = boolToNat ((false && (((s.instr_srl || s.instr_srli) || s.instr_sra) || s.instr_srai)))) then s.alu_shr else i.__rtl_nondet_0008)))))))
  let alu_out_0 := (if decide (boolToNat (true) = boolToNat (s.instr_beq)) then s.alu_eq else (if decide (boolToNat (true) = boolToNat (s.instr_bne)) then !(s.alu_eq) else (if decide (boolToNat (true) = boolToNat (s.instr_bge)) then !(s.alu_lts) else (if decide (boolToNat (true) = boolToNat (s.instr_bgeu)) then !(s.alu_ltu) else (if decide (boolToNat (true) = boolToNat ((s.is_slti_blt_slt && (!(false) || !(bvNonzero (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_beq)) (boolToBitVec (s.instr_bne))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_bge)) (boolToBitVec (s.instr_bgeu))))))))) then s.alu_lts else (if decide (boolToNat (true) = boolToNat ((s.is_sltiu_bltu_sltu && (!(false) || !(bvNonzero (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_beq)) (boolToBitVec (s.instr_bne))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_bge)) (boolToBitVec (s.instr_bgeu))))))))) then s.alu_ltu else BitVec.getLsbD (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (i.__rtl_nondet_0007))) 0))))))
  { s with
    alu_out := alu_out
    alu_out_0 := alu_out_0
  }

/-- 组合逻辑：proc_alwayscomb_7 -/
def proc_alwayscomb_7 (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let clear_prefetched_high_word := (if ((s.latched_branch || bvNonzero (s.irq_state)) || !(i.resetn)) then false else (if !(s.prefetched_high_word) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.clear_prefetched_high_word_q))
  { s with
    clear_prefetched_high_word := clear_prefetched_high_word
  }

/-- 组合逻辑：proc_alwayscomb_8 -/
def proc_alwayscomb_8 (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let cpuregs_wrdata := (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then (if decide (boolToNat (true) = boolToNat (s.latched_branch)) then (s.reg_pc + (if s.latched_compr then BitVec.ofNat 32 2 else BitVec.ofNat 32 4)) else (if decide (boolToNat (true) = boolToNat ((s.latched_store && !(s.latched_branch)))) then (if s.latched_stalu then s.alu_out_q else s.reg_out) else (if decide (boolToNat (true) = boolToNat ((false && BitVec.getLsbD (s.irq_state) 0))) then (s.reg_next_pc ||| BitVec.setWidth 32 (boolToBitVec (s.latched_compr))) else (if decide (boolToNat (true) = boolToNat ((false && BitVec.getLsbD (s.irq_state) 1))) then (s.irq_pending &&& ~~~(s.irq_mask)) else i.__rtl_nondet_0009)))) else i.__rtl_nondet_0009)
  let cpuregs_write := (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then (if decide (boolToNat (true) = boolToNat (s.latched_branch)) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else (if decide (boolToNat (true) = boolToNat ((s.latched_store && !(s.latched_branch)))) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else (if decide (boolToNat (true) = boolToNat ((false && BitVec.getLsbD (s.irq_state) 0))) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else (if decide (boolToNat (true) = boolToNat ((false && BitVec.getLsbD (s.irq_state) 1))) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else BitVec.getLsbD (BitVec.ofNat 32 0) 0)))) else BitVec.getLsbD (BitVec.ofNat 32 0) 0)
  { s with
    cpuregs_wrdata := cpuregs_wrdata
    cpuregs_write := cpuregs_write
  }

/-- 组合逻辑：proc_alwayscomb_9 -/
def proc_alwayscomb_9 (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let cpuregs_rs1 := (if bvNonzero (s.decoded_rs1) then bvArrayRead 32 32 0 31 (s.cpuregs) ((s.decoded_rs1).toNat) else BitVec.ofNat 32 0)
  let cpuregs_rs2 := (if bvNonzero (s.decoded_rs2) then bvArrayRead 32 32 0 31 (s.cpuregs) ((s.decoded_rs2).toNat) else BitVec.ofNat 32 0)
  let decoded_rs := BitVec.extractLsb 4 0 (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (i.__rtl_nondet_0010)))
  { s with
    cpuregs_rs1 := cpuregs_rs1
    cpuregs_rs2 := cpuregs_rs2
    decoded_rs := decoded_rs
  }

private def _rtl_comb_block_0 (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let result :=
    assign_dbg_mem_valid s i
    |> (fun s' => assign_dbg_mem_instr s' i)
    |> (fun s' => assign_dbg_mem_ready s' i)
    |> (fun s' => assign_dbg_mem_addr s' i)
    |> (fun s' => assign_dbg_mem_wdata s' i)
    |> (fun s' => assign_dbg_mem_wstrb s' i)
    |> (fun s' => assign_dbg_mem_rdata s' i)
    |> (fun s' => assign_pcpi_rs1 s' i)
    |> (fun s' => assign_pcpi_rs2 s' i)
    |> (fun s' => assign_pcpi_mul_wr s' i)
    |> (fun s' => assign_pcpi_mul_rd s' i)
    |> (fun s' => assign_pcpi_mul_wait s' i)
    |> (fun s' => assign_pcpi_mul_ready s' i)
    |> (fun s' => assign_pcpi_div_wr s' i)
    |> (fun s' => assign_pcpi_div_rd s' i)
    |> (fun s' => assign_pcpi_div_wait s' i)
    |> (fun s' => assign_pcpi_div_ready s' i)
    |> (fun s' => assign_mem_busy s' i)
    |> (fun s' => assign_mem_la_write s' i)
    |> (fun s' => assign_instr_trap s' i)
    |> (fun s' => assign_is_rdcycle_rdcycleh_rdinstr_rdinstrh s' i)
    |> (fun s' => assign_next_pc s' i)
    |> (fun s' => assign_launch_next_insn s' i)
    |> (fun s' => proc_alwayscomb_1 s' i)
    |> (fun s' => proc_alwayscomb_2 s' i)
    |> (fun s' => proc_alwayscomb_4 s' i)
    |> (fun s' => proc_alwayscomb_5 s' i)
    |> (fun s' => proc_alwayscomb_7 s' i)
    |> (fun s' => proc_alwayscomb_8 s' i)
    |> (fun s' => proc_alwayscomb_9 s' i)
    |> (fun s' => assign_mem_la_firstword s' i)
    |> (fun s' => proc_alwayscomb s' i)

  result

private def _rtl_comb_block_1 (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let result :=
    proc_alwayscomb_3 s i
    |> (fun s' => proc_alwayscomb_6 s' i)
    |> (fun s' => assign_mem_la_use_prefetched_high_word s' i)
    |> (fun s' => assign_mem_xfer s' i)
    |> (fun s' => assign_mem_la_firstword_xfer s' i)
    |> (fun s' => assign_mem_rdata_latched_noshuffle s' i)
    |> (fun s' => assign_mem_la_addr s' i)
    |> (fun s' => assign_mem_rdata_latched s' i)
    |> (fun s' => assign_mem_done s' i)
    |> (fun s' => assign_mem_la_read s' i)

  result

/-- Combinational fixed-point schedule derived from IR dependencies -/
def comb (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let result :=
    _rtl_comb_block_0 s i
    |> (fun s' => _rtl_comb_block_1 s' i)

  result

/-- 时序逻辑: proc_alwaysff (clk=clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  { s with
    last_mem_valid := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (s.mem_valid && !(i.mem_ready)))
    mem_la_firstword_reg := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if !(s.last_mem_valid) then s.mem_la_firstword else s.mem_la_firstword_reg))
  }

/-- 时序逻辑: proc_alwaysff_1 (clk=clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_1 (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  { s with
    mem_rdata_q := (if s.mem_xfer then (if false then s.mem_rdata_latched else i.mem_rdata) else s.mem_rdata_q)
    next_insn_opcode := (if s.mem_xfer then (if false then s.mem_rdata_latched else i.mem_rdata) else s.next_insn_opcode)
  }

/-- 时序逻辑: proc_alwaysff_2 (clk=clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_2 (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  s

/-- 时序逻辑: proc_alwaysff_3 (clk=clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_3 (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  { s with
    mem_addr := (if (!(i.resetn) || s.trap) then s.mem_addr else (if (s.mem_la_read || s.mem_la_write) then s.mem_la_addr else s.mem_addr))
    mem_instr := (if (!(i.resetn) || s.trap) then s.mem_instr else (if decide ((s.mem_state).toNat = (BitVec.ofNat 32 0).toNat) then (if s.mem_do_wdata then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if ((s.mem_do_prefetch || s.mem_do_rinst) || s.mem_do_rdata) then (s.mem_do_prefetch || s.mem_do_rinst) else s.mem_instr)) else s.mem_instr))
    mem_la_secondword := (if (!(i.resetn) || s.trap) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.mem_state).toNat = (BitVec.ofNat 32 0).toNat) then s.mem_la_secondword else (if decide ((s.mem_state).toNat = (BitVec.ofNat 32 1).toNat) then (if s.mem_xfer then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.mem_la_secondword) else s.mem_la_secondword)))
    mem_state := (if (!(i.resetn) || s.trap) then (if !(i.resetn) then BitVec.extractLsb 1 0 (BitVec.ofNat 32 0) else s.mem_state) else (if decide ((s.mem_state).toNat = (BitVec.ofNat 32 0).toNat) then (if s.mem_do_wdata then BitVec.extractLsb 1 0 (BitVec.ofNat 32 2) else (if ((s.mem_do_prefetch || s.mem_do_rinst) || s.mem_do_rdata) then BitVec.extractLsb 1 0 (BitVec.ofNat 32 1) else s.mem_state)) else (if decide ((s.mem_state).toNat = (BitVec.ofNat 32 1).toNat) then (if s.mem_xfer then BitVec.extractLsb 1 0 ((if (s.mem_do_rinst || s.mem_do_rdata) then BitVec.extractLsb 31 0 (BitVec.ofNat 32 0) else BitVec.extractLsb 31 0 (BitVec.ofNat 32 3))) else s.mem_state) else (if decide ((s.mem_state).toNat = (BitVec.ofNat 32 2).toNat) then (if s.mem_xfer then BitVec.extractLsb 1 0 (BitVec.ofNat 32 0) else s.mem_state) else (if decide ((s.mem_state).toNat = (BitVec.ofNat 32 3).toNat) then (if s.mem_do_rinst then BitVec.extractLsb 1 0 (BitVec.ofNat 32 0) else s.mem_state) else s.mem_state)))))
    mem_valid := (if (!(i.resetn) || s.trap) then (if (!(i.resetn) || i.mem_ready) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.mem_valid) else (if decide ((s.mem_state).toNat = (BitVec.ofNat 32 0).toNat) then (if s.mem_do_wdata then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else (if ((s.mem_do_prefetch || s.mem_do_rinst) || s.mem_do_rdata) then !(s.mem_la_use_prefetched_high_word) else s.mem_valid)) else (if decide ((s.mem_state).toNat = (BitVec.ofNat 32 1).toNat) then (if s.mem_xfer then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.mem_valid) else (if decide ((s.mem_state).toNat = (BitVec.ofNat 32 2).toNat) then (if s.mem_xfer then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.mem_valid) else s.mem_valid))))
    mem_wdata := (if (!(i.resetn) || s.trap) then s.mem_wdata else (if s.mem_la_write then s.mem_la_wdata else s.mem_wdata))
    mem_wstrb := (if (!(i.resetn) || s.trap) then s.mem_wstrb else (if decide ((s.mem_state).toNat = (BitVec.ofNat 32 0).toNat) then (if ((s.mem_do_prefetch || s.mem_do_rinst) || s.mem_do_rdata) then BitVec.extractLsb 3 0 (BitVec.ofNat 32 0) else (if (s.mem_la_read || s.mem_la_write) then (s.mem_la_wstrb &&& BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.mem_la_write)) (boolToBitVec (s.mem_la_write))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.mem_la_write)) (boolToBitVec (s.mem_la_write)))) else s.mem_wstrb)) else (if (s.mem_la_read || s.mem_la_write) then (s.mem_la_wstrb &&& BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.mem_la_write)) (boolToBitVec (s.mem_la_write))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.mem_la_write)) (boolToBitVec (s.mem_la_write)))) else s.mem_wstrb)))
    prefetched_high_word := (if s.clear_prefetched_high_word then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if (!(i.resetn) || s.trap) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.prefetched_high_word))
  }

/-- 时序逻辑: proc_alwaysff_4 (clk=clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_4 (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  { s with
    cached_ascii_instr := (if s.decoder_trigger_q then s.new_ascii_instr else s.cached_ascii_instr)
    cached_insn_imm := (if s.decoder_trigger_q then s.decoded_imm else s.cached_insn_imm)
    cached_insn_opcode := (if s.decoder_trigger_q then (if bvReduceAnd (BitVec.extractLsb 1 0 (s.next_insn_opcode)) then s.next_insn_opcode else BitVec.append (n := 16) (m := 16) (BitVec.ofNat 16 0) (BitVec.extractLsb 15 0 (s.next_insn_opcode))) else s.cached_insn_opcode)
    cached_insn_rd := (if s.decoder_trigger_q then s.decoded_rd else s.cached_insn_rd)
    cached_insn_rs1 := (if s.decoder_trigger_q then s.decoded_rs1 else s.cached_insn_rs1)
    cached_insn_rs2 := (if s.decoder_trigger_q then s.decoded_rs2 else s.cached_insn_rs2)
    dbg_insn_addr := (if s.launch_next_insn then s.next_pc else s.dbg_insn_addr)
    dbg_next := s.launch_next_insn
    dbg_valid_insn := (if (!(i.resetn) || s.trap) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if s.launch_next_insn then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else s.dbg_valid_insn))
    q_ascii_instr := s.dbg_ascii_instr
    q_insn_imm := s.dbg_insn_imm
    q_insn_opcode := s.dbg_insn_opcode
    q_insn_rd := s.dbg_insn_rd
    q_insn_rs1 := s.dbg_insn_rs1
    q_insn_rs2 := s.dbg_insn_rs2
  }

/-- 时序逻辑: proc_alwaysff_5 (clk=clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_5 (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  { s with
    compressed_instr := (if (s.mem_do_rinst && s.mem_done) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.compressed_instr)
    decoded_imm := (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then (if decide (boolToNat (true) = boolToNat (s.instr_jal)) then s.decoded_imm_j else (if decide ((BitVec.ofNat 2 1).toNat = boolToNat (bvNonzero (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_lui)) (boolToBitVec (s.instr_auipc))))) then BitVec.extractLsb 31 0 (BitVec.shiftLeft (BitVec.extractLsb 31 0 (BitVec.append (n := 12) (m := 20) (BitVec.ofNat 12 0) (BitVec.extractLsb 19 0 (BitVec.extractLsb 31 12 (s.mem_rdata_q))))) (BitVec.ofNat 32 12).toNat) else (if decide ((BitVec.ofNat 3 1).toNat = boolToNat (bvNonzero (BitVec.append (n := 1) (m := 2) (boolToBitVec (s.instr_jalr)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.is_lb_lh_lw_lbu_lhu)) (boolToBitVec (s.is_alu_reg_imm)))))) then BitVec.extractLsb 31 0 (BitVec.append (n := 20) (m := 12) ((if BitVec.getLsbD (BitVec.extractLsb 11 0 (BitVec.extractLsb 31 20 (s.mem_rdata_q))) 11 then BitVec.ofNat 20 1048575 else BitVec.ofNat 20 0)) (BitVec.extractLsb 11 0 (BitVec.extractLsb 31 20 (s.mem_rdata_q)))) else (if decide (boolToNat (true) = boolToNat (s.is_beq_bne_blt_bge_bltu_bgeu)) then BitVec.extractLsb 31 0 (BitVec.append (n := 19) (m := 13) ((if BitVec.getLsbD (BitVec.extractLsb 12 0 (BitVec.append (n := 2) (m := 11) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.mem_rdata_q) 31)) (boolToBitVec (BitVec.getLsbD (s.mem_rdata_q) 7))) (BitVec.append (n := 6) (m := 5) (BitVec.extractLsb 30 25 (s.mem_rdata_q)) (BitVec.append (n := 4) (m := 1) (BitVec.extractLsb 11 8 (s.mem_rdata_q)) (boolToBitVec (false)))))) 12 then BitVec.ofNat 19 524287 else BitVec.ofNat 19 0)) (BitVec.extractLsb 12 0 (BitVec.append (n := 2) (m := 11) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.mem_rdata_q) 31)) (boolToBitVec (BitVec.getLsbD (s.mem_rdata_q) 7))) (BitVec.append (n := 6) (m := 5) (BitVec.extractLsb 30 25 (s.mem_rdata_q)) (BitVec.append (n := 4) (m := 1) (BitVec.extractLsb 11 8 (s.mem_rdata_q)) (boolToBitVec (false))))))) else (if decide (boolToNat (true) = boolToNat (s.is_sb_sh_sw)) then BitVec.extractLsb 31 0 (BitVec.append (n := 20) (m := 12) ((if BitVec.getLsbD (BitVec.extractLsb 11 0 (BitVec.append (n := 7) (m := 5) (BitVec.extractLsb 31 25 (s.mem_rdata_q)) (BitVec.extractLsb 11 7 (s.mem_rdata_q)))) 11 then BitVec.ofNat 20 1048575 else BitVec.ofNat 20 0)) (BitVec.extractLsb 11 0 (BitVec.append (n := 7) (m := 5) (BitVec.extractLsb 31 25 (s.mem_rdata_q)) (BitVec.extractLsb 11 7 (s.mem_rdata_q))))) else BitVec.extractLsb 31 0 (BitVec.append (n := 31) (m := 1) (BitVec.ofNat 31 0) (boolToBitVec (i.__rtl_nondet_0006)))))))) else s.decoded_imm)
    decoded_imm_j := (if (s.mem_do_rinst && s.mem_done) then bvBitWrite 32 (bvRangeWrite 32 19 12 (bvBitWrite 32 (bvRangeWrite 32 10 1 (bvRangeWrite 32 31 20 (s.decoded_imm_j) (BitVec.extractLsb 31 20 (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (BitVec.append (n := 11) (m := 21) ((if BitVec.getLsbD (BitVec.extractLsb 20 0 (BitVec.append (n := 20) (m := 1) (BitVec.extractLsb 31 12 (s.mem_rdata_latched)) (boolToBitVec (false)))) 20 then BitVec.ofNat 11 2047 else BitVec.ofNat 11 0)) (BitVec.extractLsb 20 0 (BitVec.append (n := 20) (m := 1) (BitVec.extractLsb 31 12 (s.mem_rdata_latched)) (boolToBitVec (false))))))))) (BitVec.extractLsb 19 10 (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (BitVec.append (n := 11) (m := 21) ((if BitVec.getLsbD (BitVec.extractLsb 20 0 (BitVec.append (n := 20) (m := 1) (BitVec.extractLsb 31 12 (s.mem_rdata_latched)) (boolToBitVec (false)))) 20 then BitVec.ofNat 11 2047 else BitVec.ofNat 11 0)) (BitVec.extractLsb 20 0 (BitVec.append (n := 20) (m := 1) (BitVec.extractLsb 31 12 (s.mem_rdata_latched)) (boolToBitVec (false))))))))) ((BitVec.ofNat 32 11).toNat) (BitVec.getLsbD (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (BitVec.append (n := 11) (m := 21) ((if BitVec.getLsbD (BitVec.extractLsb 20 0 (BitVec.append (n := 20) (m := 1) (BitVec.extractLsb 31 12 (s.mem_rdata_latched)) (boolToBitVec (false)))) 20 then BitVec.ofNat 11 2047 else BitVec.ofNat 11 0)) (BitVec.extractLsb 20 0 (BitVec.append (n := 20) (m := 1) (BitVec.extractLsb 31 12 (s.mem_rdata_latched)) (boolToBitVec (false))))))) 9)) (BitVec.extractLsb 8 1 (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (BitVec.append (n := 11) (m := 21) ((if BitVec.getLsbD (BitVec.extractLsb 20 0 (BitVec.append (n := 20) (m := 1) (BitVec.extractLsb 31 12 (s.mem_rdata_latched)) (boolToBitVec (false)))) 20 then BitVec.ofNat 11 2047 else BitVec.ofNat 11 0)) (BitVec.extractLsb 20 0 (BitVec.append (n := 20) (m := 1) (BitVec.extractLsb 31 12 (s.mem_rdata_latched)) (boolToBitVec (false))))))))) ((BitVec.ofNat 32 0).toNat) (BitVec.getLsbD (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (BitVec.append (n := 11) (m := 21) ((if BitVec.getLsbD (BitVec.extractLsb 20 0 (BitVec.append (n := 20) (m := 1) (BitVec.extractLsb 31 12 (s.mem_rdata_latched)) (boolToBitVec (false)))) 20 then BitVec.ofNat 11 2047 else BitVec.ofNat 11 0)) (BitVec.extractLsb 20 0 (BitVec.append (n := 20) (m := 1) (BitVec.extractLsb 31 12 (s.mem_rdata_latched)) (boolToBitVec (false))))))) 0) else s.decoded_imm_j)
    decoded_rd := (if (s.mem_do_rinst && s.mem_done) then BitVec.extractLsb 11 7 (s.mem_rdata_latched) else s.decoded_rd)
    decoded_rs1 := (if (s.mem_do_rinst && s.mem_done) then (if ((decide ((BitVec.extractLsb 6 0 (s.mem_rdata_latched)).toNat = (BitVec.ofNat 7 11).toNat) && decide ((BitVec.extractLsb 31 25 (s.mem_rdata_latched)).toNat = (BitVec.ofNat 7 2).toNat)) && false) then BitVec.extractLsb 4 0 ((if true then BitVec.extractLsb 31 0 (BitVec.ofNat 32 32) else BitVec.extractLsb 31 0 (BitVec.ofNat 32 3))) else (if (((decide ((BitVec.extractLsb 6 0 (s.mem_rdata_latched)).toNat = (BitVec.ofNat 7 11).toNat) && decide ((BitVec.extractLsb 31 25 (s.mem_rdata_latched)).toNat = (BitVec.ofNat 7 0).toNat)) && false) && true) then bvBitWrite 5 (BitVec.extractLsb 19 15 (s.mem_rdata_latched)) ((BitVec.ofNat 32 4).toNat) (true) else BitVec.extractLsb 19 15 (s.mem_rdata_latched))) else s.decoded_rs1)
    decoded_rs2 := (if (s.mem_do_rinst && s.mem_done) then BitVec.extractLsb 24 20 (s.mem_rdata_latched) else s.decoded_rs2)
    instr_add := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then ((s.is_alu_reg_reg && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 0).toNat)) && decide ((BitVec.extractLsb 31 25 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 0).toNat)) else s.instr_add))
    instr_addi := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then (s.is_alu_reg_imm && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 0).toNat)) else s.instr_addi))
    instr_and := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then ((s.is_alu_reg_reg && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 7).toNat)) && decide ((BitVec.extractLsb 31 25 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 0).toNat)) else s.instr_and))
    instr_andi := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then (s.is_alu_reg_imm && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 7).toNat)) else s.instr_andi))
    instr_auipc := (if (s.mem_do_rinst && s.mem_done) then decide ((BitVec.extractLsb 6 0 (s.mem_rdata_latched)).toNat = (BitVec.ofNat 7 23).toNat) else s.instr_auipc)
    instr_beq := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then (s.is_beq_bne_blt_bge_bltu_bgeu && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 0).toNat)) else s.instr_beq))
    instr_bge := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then (s.is_beq_bne_blt_bge_bltu_bgeu && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 5).toNat)) else s.instr_bge))
    instr_bgeu := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then (s.is_beq_bne_blt_bge_bltu_bgeu && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 7).toNat)) else s.instr_bgeu))
    instr_blt := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then (s.is_beq_bne_blt_bge_bltu_bgeu && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 4).toNat)) else s.instr_blt))
    instr_bltu := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then (s.is_beq_bne_blt_bge_bltu_bgeu && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 6).toNat)) else s.instr_bltu))
    instr_bne := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then (s.is_beq_bne_blt_bge_bltu_bgeu && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 1).toNat)) else s.instr_bne))
    instr_ecall_ebreak := (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then (((decide ((BitVec.extractLsb 6 0 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 115).toNat) && !(bvNonzero (BitVec.extractLsb 31 21 (s.mem_rdata_q)))) && !(bvNonzero (BitVec.extractLsb 19 7 (s.mem_rdata_q)))) || (false && decide ((BitVec.extractLsb 15 0 (s.mem_rdata_q)).toNat = (BitVec.ofNat 16 36866).toNat))) else s.instr_ecall_ebreak)
    instr_fence := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then (decide ((BitVec.extractLsb 6 0 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 15).toNat) && !(bvNonzero (BitVec.extractLsb 14 12 (s.mem_rdata_q)))) else s.instr_fence))
    instr_getq := (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then (((decide ((BitVec.extractLsb 6 0 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 11).toNat) && decide ((BitVec.extractLsb 31 25 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 0).toNat)) && false) && true) else s.instr_getq)
    instr_jal := (if (s.mem_do_rinst && s.mem_done) then decide ((BitVec.extractLsb 6 0 (s.mem_rdata_latched)).toNat = (BitVec.ofNat 7 111).toNat) else s.instr_jal)
    instr_jalr := (if (s.mem_do_rinst && s.mem_done) then (decide ((BitVec.extractLsb 6 0 (s.mem_rdata_latched)).toNat = (BitVec.ofNat 7 103).toNat) && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_latched)).toNat = (BitVec.ofNat 3 0).toNat)) else s.instr_jalr)
    instr_lb := (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then (s.is_lb_lh_lw_lbu_lhu && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 0).toNat)) else s.instr_lb)
    instr_lbu := (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then (s.is_lb_lh_lw_lbu_lhu && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 4).toNat)) else s.instr_lbu)
    instr_lh := (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then (s.is_lb_lh_lw_lbu_lhu && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 1).toNat)) else s.instr_lh)
    instr_lhu := (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then (s.is_lb_lh_lw_lbu_lhu && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 5).toNat)) else s.instr_lhu)
    instr_lui := (if (s.mem_do_rinst && s.mem_done) then decide ((BitVec.extractLsb 6 0 (s.mem_rdata_latched)).toNat = (BitVec.ofNat 7 55).toNat) else s.instr_lui)
    instr_lw := (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then (s.is_lb_lh_lw_lbu_lhu && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 2).toNat)) else s.instr_lw)
    instr_maskirq := (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then ((decide ((BitVec.extractLsb 6 0 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 11).toNat) && decide ((BitVec.extractLsb 31 25 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 3).toNat)) && false) else s.instr_maskirq)
    instr_or := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then ((s.is_alu_reg_reg && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 6).toNat)) && decide ((BitVec.extractLsb 31 25 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 0).toNat)) else s.instr_or))
    instr_ori := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then (s.is_alu_reg_imm && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 6).toNat)) else s.instr_ori))
    instr_rdcycle := (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then (((decide ((BitVec.extractLsb 6 0 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 115).toNat) && decide ((BitVec.extractLsb 31 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 32 786434).toNat)) || (decide ((BitVec.extractLsb 6 0 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 115).toNat) && decide ((BitVec.extractLsb 31 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 32 786690).toNat))) && true) else s.instr_rdcycle)
    instr_rdcycleh := (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then ((((decide ((BitVec.extractLsb 6 0 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 115).toNat) && decide ((BitVec.extractLsb 31 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 32 819202).toNat)) || (decide ((BitVec.extractLsb 6 0 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 115).toNat) && decide ((BitVec.extractLsb 31 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 32 819458).toNat))) && true) && true) else s.instr_rdcycleh)
    instr_rdinstr := (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then ((decide ((BitVec.extractLsb 6 0 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 115).toNat) && decide ((BitVec.extractLsb 31 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 32 786946).toNat)) && true) else s.instr_rdinstr)
    instr_rdinstrh := (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then (((decide ((BitVec.extractLsb 6 0 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 115).toNat) && decide ((BitVec.extractLsb 31 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 32 819714).toNat)) && true) && true) else s.instr_rdinstrh)
    instr_retirq := (if (s.mem_do_rinst && s.mem_done) then ((decide ((BitVec.extractLsb 6 0 (s.mem_rdata_latched)).toNat = (BitVec.ofNat 7 11).toNat) && decide ((BitVec.extractLsb 31 25 (s.mem_rdata_latched)).toNat = (BitVec.ofNat 7 2).toNat)) && false) else s.instr_retirq)
    instr_sb := (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then (s.is_sb_sh_sw && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 0).toNat)) else s.instr_sb)
    instr_setq := (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then (((decide ((BitVec.extractLsb 6 0 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 11).toNat) && decide ((BitVec.extractLsb 31 25 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 1).toNat)) && false) && true) else s.instr_setq)
    instr_sh := (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then (s.is_sb_sh_sw && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 1).toNat)) else s.instr_sh)
    instr_sll := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then ((s.is_alu_reg_reg && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 1).toNat)) && decide ((BitVec.extractLsb 31 25 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 0).toNat)) else s.instr_sll))
    instr_slli := (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then ((s.is_alu_reg_imm && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 1).toNat)) && decide ((BitVec.extractLsb 31 25 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 0).toNat)) else s.instr_slli)
    instr_slt := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then ((s.is_alu_reg_reg && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 2).toNat)) && decide ((BitVec.extractLsb 31 25 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 0).toNat)) else s.instr_slt))
    instr_slti := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then (s.is_alu_reg_imm && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 2).toNat)) else s.instr_slti))
    instr_sltiu := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then (s.is_alu_reg_imm && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 3).toNat)) else s.instr_sltiu))
    instr_sltu := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then ((s.is_alu_reg_reg && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 3).toNat)) && decide ((BitVec.extractLsb 31 25 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 0).toNat)) else s.instr_sltu))
    instr_sra := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then ((s.is_alu_reg_reg && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 5).toNat)) && decide ((BitVec.extractLsb 31 25 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 32).toNat)) else s.instr_sra))
    instr_srai := (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then ((s.is_alu_reg_imm && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 5).toNat)) && decide ((BitVec.extractLsb 31 25 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 32).toNat)) else s.instr_srai)
    instr_srl := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then ((s.is_alu_reg_reg && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 5).toNat)) && decide ((BitVec.extractLsb 31 25 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 0).toNat)) else s.instr_srl))
    instr_srli := (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then ((s.is_alu_reg_imm && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 5).toNat)) && decide ((BitVec.extractLsb 31 25 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 0).toNat)) else s.instr_srli)
    instr_sub := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then ((s.is_alu_reg_reg && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 0).toNat)) && decide ((BitVec.extractLsb 31 25 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 32).toNat)) else s.instr_sub))
    instr_sw := (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then (s.is_sb_sh_sw && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 2).toNat)) else s.instr_sw)
    instr_timer := (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then (((decide ((BitVec.extractLsb 6 0 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 11).toNat) && decide ((BitVec.extractLsb 31 25 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 5).toNat)) && false) && true) else s.instr_timer)
    instr_waitirq := (if (s.mem_do_rinst && s.mem_done) then ((decide ((BitVec.extractLsb 6 0 (s.mem_rdata_latched)).toNat = (BitVec.ofNat 7 11).toNat) && decide ((BitVec.extractLsb 31 25 (s.mem_rdata_latched)).toNat = (BitVec.ofNat 7 4).toNat)) && false) else s.instr_waitirq)
    instr_xor := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then ((s.is_alu_reg_reg && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 4).toNat)) && decide ((BitVec.extractLsb 31 25 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 0).toNat)) else s.instr_xor))
    instr_xori := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then (s.is_alu_reg_imm && decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 4).toNat)) else s.instr_xori))
    is_alu_reg_imm := (if (s.mem_do_rinst && s.mem_done) then decide ((BitVec.extractLsb 6 0 (s.mem_rdata_latched)).toNat = (BitVec.ofNat 7 19).toNat) else s.is_alu_reg_imm)
    is_alu_reg_reg := (if (s.mem_do_rinst && s.mem_done) then decide ((BitVec.extractLsb 6 0 (s.mem_rdata_latched)).toNat = (BitVec.ofNat 7 51).toNat) else s.is_alu_reg_reg)
    is_beq_bne_blt_bge_bltu_bgeu := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if (s.mem_do_rinst && s.mem_done) then decide ((BitVec.extractLsb 6 0 (s.mem_rdata_latched)).toNat = (BitVec.ofNat 7 99).toNat) else s.is_beq_bne_blt_bge_bltu_bgeu))
    is_compare := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else BitVec.getLsbD (BitVec.extractLsb 4 0 (BitVec.extractLsb 4 0 (boolToBitVec (bvNonzero (BitVec.append (n := 2) (m := 3) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.is_beq_bne_blt_bge_bltu_bgeu)) (boolToBitVec (s.instr_slti))) (BitVec.append (n := 1) (m := 2) (boolToBitVec (s.instr_slt)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_sltiu)) (boolToBitVec (s.instr_sltu))))))))) 0))
    is_jalr_addi_slti_sltiu_xori_ori_andi := (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then (s.instr_jalr || (s.is_alu_reg_imm && bvNonzero (BitVec.append (n := 3) (m := 3) (BitVec.append (n := 1) (m := 2) (boolToBitVec (decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 0).toNat))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 2).toNat))) (boolToBitVec (decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 3).toNat))))) (BitVec.append (n := 1) (m := 2) (boolToBitVec (decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 4).toNat))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 6).toNat))) (boolToBitVec (decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 7).toNat)))))))) else s.is_jalr_addi_slti_sltiu_xori_ori_andi)
    is_lb_lh_lw_lbu_lhu := (if (s.mem_do_rinst && s.mem_done) then decide ((BitVec.extractLsb 6 0 (s.mem_rdata_latched)).toNat = (BitVec.ofNat 7 3).toNat) else s.is_lb_lh_lw_lbu_lhu)
    is_lbu_lhu_lw := BitVec.getLsbD (BitVec.extractLsb 2 0 (BitVec.extractLsb 2 0 (boolToBitVec (bvNonzero (BitVec.append (n := 1) (m := 2) (boolToBitVec (s.instr_lbu)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_lhu)) (boolToBitVec (s.instr_lw)))))))) 0
    is_lui_auipc_jal := BitVec.getLsbD (BitVec.extractLsb 2 0 (BitVec.extractLsb 2 0 (boolToBitVec (bvNonzero (BitVec.append (n := 1) (m := 2) (boolToBitVec (s.instr_lui)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_auipc)) (boolToBitVec (s.instr_jal)))))))) 0
    is_lui_auipc_jal_jalr_addi_add_sub := (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else BitVec.getLsbD (BitVec.extractLsb 6 0 (BitVec.extractLsb 6 0 (boolToBitVec (bvNonzero (BitVec.append (n := 3) (m := 4) (BitVec.append (n := 1) (m := 2) (boolToBitVec (s.instr_lui)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_auipc)) (boolToBitVec (s.instr_jal)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_jalr)) (boolToBitVec (s.instr_addi))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_add)) (boolToBitVec (s.instr_sub))))))))) 0)
    is_sb_sh_sw := (if (s.mem_do_rinst && s.mem_done) then decide ((BitVec.extractLsb 6 0 (s.mem_rdata_latched)).toNat = (BitVec.ofNat 7 35).toNat) else s.is_sb_sh_sw)
    is_sll_srl_sra := (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then (s.is_alu_reg_reg && bvNonzero (BitVec.append (n := 1) (m := 2) (boolToBitVec ((decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 1).toNat) && decide ((BitVec.extractLsb 31 25 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 0).toNat)))) (BitVec.append (n := 1) (m := 1) (boolToBitVec ((decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 5).toNat) && decide ((BitVec.extractLsb 31 25 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 0).toNat)))) (boolToBitVec ((decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 5).toNat) && decide ((BitVec.extractLsb 31 25 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 32).toNat))))))) else s.is_sll_srl_sra)
    is_slli_srli_srai := (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then (s.is_alu_reg_imm && bvNonzero (BitVec.append (n := 1) (m := 2) (boolToBitVec ((decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 1).toNat) && decide ((BitVec.extractLsb 31 25 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 0).toNat)))) (BitVec.append (n := 1) (m := 1) (boolToBitVec ((decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 5).toNat) && decide ((BitVec.extractLsb 31 25 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 0).toNat)))) (boolToBitVec ((decide ((BitVec.extractLsb 14 12 (s.mem_rdata_q)).toNat = (BitVec.ofNat 3 5).toNat) && decide ((BitVec.extractLsb 31 25 (s.mem_rdata_q)).toNat = (BitVec.ofNat 7 32).toNat))))))) else s.is_slli_srli_srai)
    is_slti_blt_slt := BitVec.getLsbD (BitVec.extractLsb 2 0 (BitVec.extractLsb 2 0 (boolToBitVec (bvNonzero (BitVec.append (n := 1) (m := 2) (boolToBitVec (s.instr_slti)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_blt)) (boolToBitVec (s.instr_slt)))))))) 0
    is_sltiu_bltu_sltu := BitVec.getLsbD (BitVec.extractLsb 2 0 (BitVec.extractLsb 2 0 (boolToBitVec (bvNonzero (BitVec.append (n := 1) (m := 2) (boolToBitVec (s.instr_sltiu)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.instr_bltu)) (boolToBitVec (s.instr_sltu)))))))) 0
    pcpi_insn := (if (s.decoder_trigger && !(s.decoder_pseudo_trigger)) then (if false then s.mem_rdata_q else i.__rtl_nondet_0005) else s.pcpi_insn)
  }

/-- 时序逻辑: proc_alwaysff_6 (clk=clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_6 (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  { s with
    clear_prefetched_high_word_q := s.clear_prefetched_high_word
  }

/-- 时序逻辑: proc_alwaysff_7 (clk=clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_7 (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  { s with
    cpuregs := (if ((i.resetn && s.cpuregs_write) && bvNonzero (s.latched_rd)) then bvArrayWrite 32 32 0 31 (s.cpuregs) ((s.latched_rd).toNat) (s.cpuregs_wrdata) else s.cpuregs)
  }

/-- 时序逻辑: proc_alwaysff_8 (clk=clk, rst=resetn) — 复位由 step 顶层处理 -/
def proc_alwaysff_8 (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  { s with
    alu_out_0_q := s.alu_out_0
    alu_out_q := s.alu_out
    alu_wait := BitVec.getLsbD (BitVec.ofNat 32 0) 0
    alu_wait_2 := BitVec.getLsbD (BitVec.ofNat 32 0) 0
    count_cycle := (if i.resetn then (s.count_cycle + BitVec.ofNat 64 1) else BitVec.ofNat 64 0)
    count_instr := (if !(i.resetn) then BitVec.extractLsb 63 0 (BitVec.ofNat 64 0) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then s.count_instr else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then (if s.decoder_trigger then (s.count_instr + BitVec.ofNat 64 1) else s.count_instr) else s.count_instr)))
    cpu_state := (if (((true && i.resetn) && s.mem_do_rinst) && (if false then BitVec.getLsbD (s.reg_pc) 0 else bvNonzero (BitVec.extractLsb 1 0 (s.reg_pc)))) then BitVec.ofNat 8 128 else (if ((true && i.resetn) && (s.mem_do_rdata || s.mem_do_wdata)) then (if (decide ((s.mem_wordsize).toNat = (BitVec.ofNat 32 1).toNat) && decide (boolToNat (BitVec.getLsbD (s.reg_op1) 0) ≠ (BitVec.ofNat 32 0).toNat)) then BitVec.ofNat 8 128 else (if (decide ((s.mem_wordsize).toNat = (BitVec.ofNat 32 0).toNat) && decide ((BitVec.extractLsb 1 0 (s.reg_op1)).toNat ≠ (BitVec.ofNat 32 0).toNat)) then BitVec.ofNat 8 128 else (if !(i.resetn) then BitVec.ofNat 8 64 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then s.cpu_state else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then (if s.decoder_trigger then (if s.instr_jal then s.cpu_state else BitVec.ofNat 8 32) else s.cpu_state) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then (if decide (boolToNat (true) = boolToNat (((true || false) && s.instr_trap))) then BitVec.ofNat 8 128 else (if decide (boolToNat (true) = boolToNat ((true && s.is_rdcycle_rdcycleh_rdinstr_rdinstrh))) then BitVec.ofNat 8 64 else (if decide (boolToNat (true) = boolToNat (s.is_lui_auipc_jal)) then BitVec.ofNat 8 8 else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_getq))) then BitVec.ofNat 8 64 else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_setq))) then BitVec.ofNat 8 64 else (if decide (boolToNat (true) = boolToNat ((false && s.instr_retirq))) then BitVec.ofNat 8 64 else (if decide (boolToNat (true) = boolToNat ((false && s.instr_maskirq))) then BitVec.ofNat 8 64 else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_timer))) then BitVec.ofNat 8 64 else (if decide (boolToNat (true) = boolToNat ((s.is_lb_lh_lw_lbu_lhu && !(s.instr_trap)))) then BitVec.ofNat 8 1 else (if decide (boolToNat (true) = boolToNat ((s.is_slli_srli_srai && !(false)))) then BitVec.ofNat 8 4 else (if decide (boolToNat (true) = boolToNat (s.is_jalr_addi_slti_sltiu_xori_ori_andi)) then BitVec.ofNat 8 8 else (if decide (boolToNat (true) = boolToNat ((s.is_slli_srli_srai && false))) then BitVec.ofNat 8 8 else (if decide (boolToNat (true) = boolToNat (s.is_sb_sh_sw)) then BitVec.ofNat 8 2 else (if decide (boolToNat (true) = boolToNat ((s.is_sll_srl_sra && !(false)))) then BitVec.ofNat 8 4 else BitVec.ofNat 8 8)))))))))))))) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 16).toNat) then (if decide (boolToNat (true) = boolToNat ((false && s.instr_trap))) then (if s.pcpi_int_ready then BitVec.ofNat 8 64 else (if (true && (s.pcpi_timeout || s.instr_ecall_ebreak)) then BitVec.ofNat 8 128 else s.cpu_state)) else (if decide (boolToNat (true) = boolToNat (s.is_sb_sh_sw)) then BitVec.ofNat 8 2 else (if decide (boolToNat (true) = boolToNat ((s.is_sll_srl_sra && !(false)))) then BitVec.ofNat 8 4 else BitVec.ofNat 8 8))) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 8).toNat) then (if s.is_beq_bne_blt_bge_bltu_bgeu then (if s.mem_done then BitVec.ofNat 8 64 else s.cpu_state) else BitVec.ofNat 8 64) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 4).toNat) then (if decide ((s.reg_sh).toNat = (BitVec.ofNat 32 0).toNat) then BitVec.ofNat 8 64 else s.cpu_state) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 2).toNat) then (if (!(s.mem_do_prefetch) || s.mem_done) then (if (!(s.mem_do_prefetch) && s.mem_done) then BitVec.ofNat 8 64 else s.cpu_state) else s.cpu_state) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 1).toNat) then (if (!(s.mem_do_prefetch) || s.mem_done) then (if (!(s.mem_do_prefetch) && s.mem_done) then BitVec.ofNat 8 64 else s.cpu_state) else s.cpu_state) else s.cpu_state))))))))))) else (if !(i.resetn) then BitVec.ofNat 8 64 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then s.cpu_state else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then (if s.decoder_trigger then (if s.instr_jal then s.cpu_state else BitVec.ofNat 8 32) else s.cpu_state) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then (if decide (boolToNat (true) = boolToNat (((true || false) && s.instr_trap))) then BitVec.ofNat 8 128 else (if decide (boolToNat (true) = boolToNat ((true && s.is_rdcycle_rdcycleh_rdinstr_rdinstrh))) then BitVec.ofNat 8 64 else (if decide (boolToNat (true) = boolToNat (s.is_lui_auipc_jal)) then BitVec.ofNat 8 8 else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_getq))) then BitVec.ofNat 8 64 else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_setq))) then BitVec.ofNat 8 64 else (if decide (boolToNat (true) = boolToNat ((false && s.instr_retirq))) then BitVec.ofNat 8 64 else (if decide (boolToNat (true) = boolToNat ((false && s.instr_maskirq))) then BitVec.ofNat 8 64 else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_timer))) then BitVec.ofNat 8 64 else (if decide (boolToNat (true) = boolToNat ((s.is_lb_lh_lw_lbu_lhu && !(s.instr_trap)))) then BitVec.ofNat 8 1 else (if decide (boolToNat (true) = boolToNat ((s.is_slli_srli_srai && !(false)))) then BitVec.ofNat 8 4 else (if decide (boolToNat (true) = boolToNat (s.is_jalr_addi_slti_sltiu_xori_ori_andi)) then BitVec.ofNat 8 8 else (if decide (boolToNat (true) = boolToNat ((s.is_slli_srli_srai && false))) then BitVec.ofNat 8 8 else (if decide (boolToNat (true) = boolToNat (s.is_sb_sh_sw)) then BitVec.ofNat 8 2 else (if decide (boolToNat (true) = boolToNat ((s.is_sll_srl_sra && !(false)))) then BitVec.ofNat 8 4 else BitVec.ofNat 8 8)))))))))))))) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 16).toNat) then (if decide (boolToNat (true) = boolToNat ((false && s.instr_trap))) then (if s.pcpi_int_ready then BitVec.ofNat 8 64 else (if (true && (s.pcpi_timeout || s.instr_ecall_ebreak)) then BitVec.ofNat 8 128 else s.cpu_state)) else (if decide (boolToNat (true) = boolToNat (s.is_sb_sh_sw)) then BitVec.ofNat 8 2 else (if decide (boolToNat (true) = boolToNat ((s.is_sll_srl_sra && !(false)))) then BitVec.ofNat 8 4 else BitVec.ofNat 8 8))) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 8).toNat) then (if s.is_beq_bne_blt_bge_bltu_bgeu then (if s.mem_done then BitVec.ofNat 8 64 else s.cpu_state) else BitVec.ofNat 8 64) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 4).toNat) then (if decide ((s.reg_sh).toNat = (BitVec.ofNat 32 0).toNat) then BitVec.ofNat 8 64 else s.cpu_state) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 2).toNat) then (if (!(s.mem_do_prefetch) || s.mem_done) then (if (!(s.mem_do_prefetch) && s.mem_done) then BitVec.ofNat 8 64 else s.cpu_state) else s.cpu_state) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 1).toNat) then (if (!(s.mem_do_prefetch) || s.mem_done) then (if (!(s.mem_do_prefetch) && s.mem_done) then BitVec.ofNat 8 64 else s.cpu_state) else s.cpu_state) else s.cpu_state)))))))))))
    current_pc := i.__rtl_nondet_0019
    dbg_rs1val := (if !(i.resetn) then (if s.launch_next_insn then i.__rtl_nondet_0013 else s.dbg_rs1val) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then (if s.launch_next_insn then i.__rtl_nondet_0013 else s.dbg_rs1val) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then (if s.launch_next_insn then i.__rtl_nondet_0013 else s.dbg_rs1val) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then (if decide (boolToNat (true) = boolToNat (((true || false) && s.instr_trap))) then (if s.launch_next_insn then i.__rtl_nondet_0013 else s.dbg_rs1val) else (if decide (boolToNat (true) = boolToNat ((true && s.is_rdcycle_rdcycleh_rdinstr_rdinstrh))) then (if s.launch_next_insn then i.__rtl_nondet_0013 else s.dbg_rs1val) else (if decide (boolToNat (true) = boolToNat (s.is_lui_auipc_jal)) then (if s.launch_next_insn then i.__rtl_nondet_0013 else s.dbg_rs1val) else s.cpuregs_rs1))) else (if s.launch_next_insn then i.__rtl_nondet_0013 else s.dbg_rs1val)))))
    dbg_rs1val_valid := (if !(i.resetn) then (if s.launch_next_insn then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.dbg_rs1val_valid) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then (if s.launch_next_insn then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.dbg_rs1val_valid) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then (if s.launch_next_insn then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.dbg_rs1val_valid) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then (if decide (boolToNat (true) = boolToNat (((true || false) && s.instr_trap))) then (if s.launch_next_insn then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.dbg_rs1val_valid) else (if decide (boolToNat (true) = boolToNat ((true && s.is_rdcycle_rdcycleh_rdinstr_rdinstrh))) then (if s.launch_next_insn then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.dbg_rs1val_valid) else (if decide (boolToNat (true) = boolToNat (s.is_lui_auipc_jal)) then (if s.launch_next_insn then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.dbg_rs1val_valid) else BitVec.getLsbD (BitVec.ofNat 32 1) 0))) else (if s.launch_next_insn then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.dbg_rs1val_valid)))))
    dbg_rs2val := (if !(i.resetn) then (if s.launch_next_insn then i.__rtl_nondet_0014 else s.dbg_rs2val) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then (if s.launch_next_insn then i.__rtl_nondet_0014 else s.dbg_rs2val) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then (if s.launch_next_insn then i.__rtl_nondet_0014 else s.dbg_rs2val) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then (if decide (boolToNat (true) = boolToNat (((true || false) && s.instr_trap))) then (if s.launch_next_insn then i.__rtl_nondet_0014 else s.dbg_rs2val) else (if decide (boolToNat (true) = boolToNat ((true && s.is_rdcycle_rdcycleh_rdinstr_rdinstrh))) then (if s.launch_next_insn then i.__rtl_nondet_0014 else s.dbg_rs2val) else (if decide (boolToNat (true) = boolToNat (s.is_lui_auipc_jal)) then (if s.launch_next_insn then i.__rtl_nondet_0014 else s.dbg_rs2val) else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_getq))) then (if s.launch_next_insn then i.__rtl_nondet_0014 else s.dbg_rs2val) else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_setq))) then (if s.launch_next_insn then i.__rtl_nondet_0014 else s.dbg_rs2val) else (if decide (boolToNat (true) = boolToNat ((false && s.instr_retirq))) then (if s.launch_next_insn then i.__rtl_nondet_0014 else s.dbg_rs2val) else (if decide (boolToNat (true) = boolToNat ((false && s.instr_maskirq))) then (if s.launch_next_insn then i.__rtl_nondet_0014 else s.dbg_rs2val) else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_timer))) then (if s.launch_next_insn then i.__rtl_nondet_0014 else s.dbg_rs2val) else (if decide (boolToNat (true) = boolToNat ((s.is_lb_lh_lw_lbu_lhu && !(s.instr_trap)))) then (if s.launch_next_insn then i.__rtl_nondet_0014 else s.dbg_rs2val) else (if decide (boolToNat (true) = boolToNat ((s.is_slli_srli_srai && !(false)))) then (if s.launch_next_insn then i.__rtl_nondet_0014 else s.dbg_rs2val) else (if decide (boolToNat (true) = boolToNat (s.is_jalr_addi_slti_sltiu_xori_ori_andi)) then (if s.launch_next_insn then i.__rtl_nondet_0014 else s.dbg_rs2val) else (if decide (boolToNat (true) = boolToNat ((s.is_slli_srli_srai && false))) then (if s.launch_next_insn then i.__rtl_nondet_0014 else s.dbg_rs2val) else s.cpuregs_rs2)))))))))))) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 16).toNat) then s.cpuregs_rs2 else (if s.launch_next_insn then i.__rtl_nondet_0014 else s.dbg_rs2val))))))
    dbg_rs2val_valid := (if !(i.resetn) then (if s.launch_next_insn then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.dbg_rs2val_valid) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then (if s.launch_next_insn then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.dbg_rs2val_valid) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then (if s.launch_next_insn then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.dbg_rs2val_valid) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then (if decide (boolToNat (true) = boolToNat (((true || false) && s.instr_trap))) then (if s.launch_next_insn then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.dbg_rs2val_valid) else (if decide (boolToNat (true) = boolToNat ((true && s.is_rdcycle_rdcycleh_rdinstr_rdinstrh))) then (if s.launch_next_insn then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.dbg_rs2val_valid) else (if decide (boolToNat (true) = boolToNat (s.is_lui_auipc_jal)) then (if s.launch_next_insn then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.dbg_rs2val_valid) else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_getq))) then (if s.launch_next_insn then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.dbg_rs2val_valid) else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_setq))) then (if s.launch_next_insn then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.dbg_rs2val_valid) else (if decide (boolToNat (true) = boolToNat ((false && s.instr_retirq))) then (if s.launch_next_insn then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.dbg_rs2val_valid) else (if decide (boolToNat (true) = boolToNat ((false && s.instr_maskirq))) then (if s.launch_next_insn then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.dbg_rs2val_valid) else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_timer))) then (if s.launch_next_insn then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.dbg_rs2val_valid) else (if decide (boolToNat (true) = boolToNat ((s.is_lb_lh_lw_lbu_lhu && !(s.instr_trap)))) then (if s.launch_next_insn then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.dbg_rs2val_valid) else (if decide (boolToNat (true) = boolToNat ((s.is_slli_srli_srai && !(false)))) then (if s.launch_next_insn then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.dbg_rs2val_valid) else (if decide (boolToNat (true) = boolToNat (s.is_jalr_addi_slti_sltiu_xori_ori_andi)) then (if s.launch_next_insn then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.dbg_rs2val_valid) else (if decide (boolToNat (true) = boolToNat ((s.is_slli_srli_srai && false))) then (if s.launch_next_insn then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.dbg_rs2val_valid) else BitVec.getLsbD (BitVec.ofNat 32 1) 0)))))))))))) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 16).toNat) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else (if s.launch_next_insn then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.dbg_rs2val_valid))))))
    decoder_pseudo_trigger := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 16).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 8).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 4).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 2).toNat) then (if (!(s.mem_do_prefetch) || s.mem_done) then (if (!(s.mem_do_prefetch) && s.mem_done) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 1).toNat) then (if (!(s.mem_do_prefetch) || s.mem_done) then (if (!(s.mem_do_prefetch) && s.mem_done) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else BitVec.getLsbD (BitVec.ofNat 32 0) 0)))))))))
    decoder_pseudo_trigger_q := s.decoder_pseudo_trigger
    decoder_trigger := (if !(i.resetn) then (s.mem_do_rinst && s.mem_done) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then (s.mem_do_rinst && s.mem_done) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then (s.mem_do_rinst && s.mem_done) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then (s.mem_do_rinst && s.mem_done) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 16).toNat) then (s.mem_do_rinst && s.mem_done) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 8).toNat) then (if s.is_beq_bne_blt_bge_bltu_bgeu then (if (if false then s.alu_out_0_q else s.alu_out_0) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (s.mem_do_rinst && s.mem_done)) else (s.mem_do_rinst && s.mem_done)) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 4).toNat) then (s.mem_do_rinst && s.mem_done) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 2).toNat) then (if (!(s.mem_do_prefetch) || s.mem_done) then (if (!(s.mem_do_prefetch) && s.mem_done) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else (s.mem_do_rinst && s.mem_done)) else (s.mem_do_rinst && s.mem_done)) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 1).toNat) then (if (!(s.mem_do_prefetch) || s.mem_done) then (if (!(s.mem_do_prefetch) && s.mem_done) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else (s.mem_do_rinst && s.mem_done)) else (s.mem_do_rinst && s.mem_done)) else (s.mem_do_rinst && s.mem_done))))))))))
    decoder_trigger_q := s.decoder_trigger
    do_waitirq := BitVec.getLsbD (BitVec.ofNat 32 0) 0
    eoi := (if !(i.resetn) then BitVec.ofNat 32 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then s.eoi else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then (if decide (boolToNat (true) = boolToNat (s.latched_branch)) then s.eoi else (if decide (boolToNat (true) = boolToNat ((s.latched_store && !(s.latched_branch)))) then s.eoi else (if decide (boolToNat (true) = boolToNat ((false && BitVec.getLsbD (s.irq_state) 0))) then s.eoi else (if decide (boolToNat (true) = boolToNat ((false && BitVec.getLsbD (s.irq_state) 1))) then (s.irq_pending &&& ~~~(s.irq_mask)) else s.eoi)))) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then (if decide (boolToNat (true) = boolToNat (((true || false) && s.instr_trap))) then s.eoi else (if decide (boolToNat (true) = boolToNat ((true && s.is_rdcycle_rdcycleh_rdinstr_rdinstrh))) then s.eoi else (if decide (boolToNat (true) = boolToNat (s.is_lui_auipc_jal)) then s.eoi else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_getq))) then s.eoi else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_setq))) then s.eoi else (if decide (boolToNat (true) = boolToNat ((false && s.instr_retirq))) then BitVec.ofNat 32 0 else s.eoi)))))) else s.eoi))))
    irq_active := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then s.irq_active else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then (if decide (boolToNat (true) = boolToNat (s.latched_branch)) then s.irq_active else (if decide (boolToNat (true) = boolToNat ((s.latched_store && !(s.latched_branch)))) then s.irq_active else (if decide (boolToNat (true) = boolToNat ((false && BitVec.getLsbD (s.irq_state) 0))) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else s.irq_active))) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then (if decide (boolToNat (true) = boolToNat (((true || false) && s.instr_trap))) then s.irq_active else (if decide (boolToNat (true) = boolToNat ((true && s.is_rdcycle_rdcycleh_rdinstr_rdinstrh))) then s.irq_active else (if decide (boolToNat (true) = boolToNat (s.is_lui_auipc_jal)) then s.irq_active else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_getq))) then s.irq_active else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_setq))) then s.irq_active else (if decide (boolToNat (true) = boolToNat ((false && s.instr_retirq))) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.irq_active)))))) else s.irq_active))))
    irq_delay := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then s.irq_delay else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then (if s.decoder_trigger then s.irq_active else s.irq_delay) else s.irq_delay)))
    irq_mask := (if !(i.resetn) then ~~~(BitVec.ofNat 32 0) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then s.irq_mask else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then s.irq_mask else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then (if decide (boolToNat (true) = boolToNat (((true || false) && s.instr_trap))) then s.irq_mask else (if decide (boolToNat (true) = boolToNat ((true && s.is_rdcycle_rdcycleh_rdinstr_rdinstrh))) then s.irq_mask else (if decide (boolToNat (true) = boolToNat (s.is_lui_auipc_jal)) then s.irq_mask else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_getq))) then s.irq_mask else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_setq))) then s.irq_mask else (if decide (boolToNat (true) = boolToNat ((false && s.instr_retirq))) then s.irq_mask else (if decide (boolToNat (true) = boolToNat ((false && s.instr_maskirq))) then (s.cpuregs_rs1 ||| BitVec.ofNat 32 0) else s.irq_mask))))))) else s.irq_mask))))
    irq_pending := ((if !(i.resetn) then BitVec.ofNat 32 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then (if false then (s.irq_pending &&& BitVec.ofNat 32 4294967295) else i.__rtl_nondet_0015) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then (if decide (boolToNat (true) = boolToNat (s.latched_branch)) then (if false then (s.irq_pending &&& BitVec.ofNat 32 4294967295) else i.__rtl_nondet_0015) else (if decide (boolToNat (true) = boolToNat ((s.latched_store && !(s.latched_branch)))) then (if false then (s.irq_pending &&& BitVec.ofNat 32 4294967295) else i.__rtl_nondet_0015) else (if decide (boolToNat (true) = boolToNat ((false && BitVec.getLsbD (s.irq_state) 0))) then (if false then (s.irq_pending &&& BitVec.ofNat 32 4294967295) else i.__rtl_nondet_0015) else (if decide (boolToNat (true) = boolToNat ((false && BitVec.getLsbD (s.irq_state) 1))) then ((if false then (s.irq_pending &&& BitVec.ofNat 32 4294967295) else i.__rtl_nondet_0015) &&& s.irq_mask) else (if false then (s.irq_pending &&& BitVec.ofNat 32 4294967295) else i.__rtl_nondet_0015))))) else (if false then (s.irq_pending &&& BitVec.ofNat 32 4294967295) else i.__rtl_nondet_0015)))) &&& BitVec.ofNat 32 4294967295)
    irq_state := (if !(i.resetn) then BitVec.extractLsb 1 0 (BitVec.ofNat 32 0) else s.irq_state)
    latched_branch := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then s.latched_branch else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then (if s.decoder_trigger then (if s.instr_jal then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then (if decide (boolToNat (true) = boolToNat (((true || false) && s.instr_trap))) then s.latched_branch else (if decide (boolToNat (true) = boolToNat ((true && s.is_rdcycle_rdcycleh_rdinstr_rdinstrh))) then s.latched_branch else (if decide (boolToNat (true) = boolToNat (s.is_lui_auipc_jal)) then s.latched_branch else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_getq))) then s.latched_branch else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_setq))) then s.latched_branch else (if decide (boolToNat (true) = boolToNat ((false && s.instr_retirq))) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else s.latched_branch)))))) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 16).toNat) then s.latched_branch else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 8).toNat) then (if s.is_beq_bne_blt_bge_bltu_bgeu then (if false then s.alu_out_0_q else s.alu_out_0) else s.instr_jalr) else s.latched_branch))))))
    latched_compr := (if !(i.resetn) then s.latched_compr else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then s.latched_compr else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then s.compressed_instr else s.latched_compr)))
    latched_is_lb := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then s.latched_is_lb else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then s.latched_is_lb else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 16).toNat) then s.latched_is_lb else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 8).toNat) then s.latched_is_lb else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 4).toNat) then s.latched_is_lb else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 2).toNat) then s.latched_is_lb else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 1).toNat) then (if (!(s.mem_do_prefetch) || s.mem_done) then (if !(s.mem_do_rdata) then s.instr_lb else s.latched_is_lb) else s.latched_is_lb) else s.latched_is_lb)))))))))
    latched_is_lh := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then s.latched_is_lh else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then s.latched_is_lh else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 16).toNat) then s.latched_is_lh else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 8).toNat) then s.latched_is_lh else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 4).toNat) then s.latched_is_lh else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 2).toNat) then s.latched_is_lh else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 1).toNat) then (if (!(s.mem_do_prefetch) || s.mem_done) then (if !(s.mem_do_rdata) then s.instr_lh else s.latched_is_lh) else s.latched_is_lh) else s.latched_is_lh)))))))))
    latched_is_lu := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then s.latched_is_lu else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then s.latched_is_lu else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 16).toNat) then s.latched_is_lu else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 8).toNat) then s.latched_is_lu else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 4).toNat) then s.latched_is_lu else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 2).toNat) then s.latched_is_lu else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 1).toNat) then (if (!(s.mem_do_prefetch) || s.mem_done) then (if !(s.mem_do_rdata) then s.is_lbu_lhu_lw else s.latched_is_lu) else s.latched_is_lu) else s.latched_is_lu)))))))))
    latched_rd := (if !(i.resetn) then s.latched_rd else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then s.latched_rd else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then s.decoded_rd else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then (if decide (boolToNat (true) = boolToNat (((true || false) && s.instr_trap))) then s.latched_rd else (if decide (boolToNat (true) = boolToNat ((true && s.is_rdcycle_rdcycleh_rdinstr_rdinstrh))) then s.latched_rd else (if decide (boolToNat (true) = boolToNat (s.is_lui_auipc_jal)) then s.latched_rd else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_getq))) then s.latched_rd else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_setq))) then BitVec.extractLsb 4 0 ((BitVec.extractLsb 31 0 (BitVec.append (n := 27) (m := 5) (BitVec.ofNat 27 0) (BitVec.extractLsb 4 0 (s.latched_rd))) ||| BitVec.extractLsb 31 0 (BitVec.ofNat 32 32))) else s.latched_rd))))) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 16).toNat) then s.latched_rd else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 8).toNat) then (if s.is_beq_bne_blt_bge_bltu_bgeu then BitVec.extractLsb 4 0 (BitVec.ofNat 32 0) else s.latched_rd) else s.latched_rd))))))
    latched_stalu := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then s.latched_stalu else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then s.latched_stalu else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 16).toNat) then s.latched_stalu else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 8).toNat) then (if s.is_beq_bne_blt_bge_bltu_bgeu then s.latched_stalu else BitVec.getLsbD (BitVec.ofNat 32 1) 0) else s.latched_stalu))))))
    latched_store := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then s.latched_store else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then (if decide (boolToNat (true) = boolToNat (((true || false) && s.instr_trap))) then s.latched_store else (if decide (boolToNat (true) = boolToNat ((true && s.is_rdcycle_rdcycleh_rdinstr_rdinstrh))) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else (if decide (boolToNat (true) = boolToNat (s.is_lui_auipc_jal)) then s.latched_store else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_getq))) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_setq))) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else (if decide (boolToNat (true) = boolToNat ((false && s.instr_retirq))) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else (if decide (boolToNat (true) = boolToNat ((false && s.instr_maskirq))) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_timer))) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else s.latched_store)))))))) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 16).toNat) then (if decide (boolToNat (true) = boolToNat ((false && s.instr_trap))) then (if s.pcpi_int_ready then s.pcpi_int_wr else s.latched_store) else s.latched_store) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 8).toNat) then (if s.is_beq_bne_blt_bge_bltu_bgeu then (if false then s.alu_out_0_q else s.alu_out_0) else BitVec.getLsbD (BitVec.ofNat 32 1) 0) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 4).toNat) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 2).toNat) then s.latched_store else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 1).toNat) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else s.latched_store)))))))))
    latched_trace := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.latched_trace)
    mem_do_prefetch := (if (!(i.resetn) || s.mem_done) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if !(i.resetn) then s.mem_do_prefetch else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then s.mem_do_prefetch else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then (if s.decoder_trigger then (if s.instr_jal then s.mem_do_prefetch else (!(s.instr_jalr) && !(s.instr_retirq))) else s.mem_do_prefetch) else s.mem_do_prefetch))))
    mem_do_rdata := (if (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 16).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 8).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 4).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 2).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 1).toNat) then (if (!(s.mem_do_prefetch) || s.mem_done) then (if !(s.mem_do_rdata) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else BitVec.getLsbD (BitVec.ofNat 32 0) 0))))))))) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else (if (!(i.resetn) || s.mem_done) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.mem_do_rdata))
    mem_do_rinst := (if (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 16).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 8).toNat) then (if s.is_beq_bne_blt_bge_bltu_bgeu then (if (if false then s.alu_out_0_q else s.alu_out_0) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else BitVec.getLsbD (BitVec.ofNat 32 0) 0)))))) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else (if (!(i.resetn) || s.mem_done) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if !(i.resetn) then s.mem_do_rinst else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then s.mem_do_rinst else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then (if s.decoder_trigger then (if s.instr_jal then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else (if decide (boolToNat (true) = boolToNat (s.latched_branch)) then (!(s.decoder_trigger) && !(s.do_waitirq)) else (if decide (boolToNat (true) = boolToNat ((s.latched_store && !(s.latched_branch)))) then (!(s.decoder_trigger) && !(s.do_waitirq)) else (if decide (boolToNat (true) = boolToNat ((false && BitVec.getLsbD (s.irq_state) 0))) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else (!(s.decoder_trigger) && !(s.do_waitirq)))))) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then (if decide (boolToNat (true) = boolToNat (((true || false) && s.instr_trap))) then s.mem_do_rinst else (if decide (boolToNat (true) = boolToNat ((true && s.is_rdcycle_rdcycleh_rdinstr_rdinstrh))) then s.mem_do_rinst else (if decide (boolToNat (true) = boolToNat (s.is_lui_auipc_jal)) then s.mem_do_prefetch else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_getq))) then s.mem_do_rinst else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_setq))) then s.mem_do_rinst else (if decide (boolToNat (true) = boolToNat ((false && s.instr_retirq))) then s.mem_do_rinst else (if decide (boolToNat (true) = boolToNat ((false && s.instr_maskirq))) then s.mem_do_rinst else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_timer))) then s.mem_do_rinst else (if decide (boolToNat (true) = boolToNat ((s.is_lb_lh_lw_lbu_lhu && !(s.instr_trap)))) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else (if decide (boolToNat (true) = boolToNat ((s.is_slli_srli_srai && !(false)))) then s.mem_do_rinst else (if decide (boolToNat (true) = boolToNat (s.is_jalr_addi_slti_sltiu_xori_ori_andi)) then s.mem_do_prefetch else (if decide (boolToNat (true) = boolToNat ((s.is_slli_srli_srai && false))) then s.mem_do_prefetch else (if decide (boolToNat (true) = boolToNat (s.is_sb_sh_sw)) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else (if decide (boolToNat (true) = boolToNat ((s.is_sll_srl_sra && !(false)))) then s.mem_do_rinst else s.mem_do_prefetch)))))))))))))) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 16).toNat) then (if decide (boolToNat (true) = boolToNat ((false && s.instr_trap))) then (if s.pcpi_int_ready then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else s.mem_do_rinst) else (if decide (boolToNat (true) = boolToNat (s.is_sb_sh_sw)) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else (if decide (boolToNat (true) = boolToNat ((s.is_sll_srl_sra && !(false)))) then s.mem_do_rinst else s.mem_do_prefetch))) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 8).toNat) then s.mem_do_rinst else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 4).toNat) then (if decide ((s.reg_sh).toNat = (BitVec.ofNat 32 0).toNat) then s.mem_do_prefetch else s.mem_do_rinst) else s.mem_do_rinst)))))))))
    mem_do_wdata := (if (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 16).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 8).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 4).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 2).toNat) then (if (!(s.mem_do_prefetch) || s.mem_done) then (if !(s.mem_do_wdata) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else BitVec.getLsbD (BitVec.ofNat 32 0) 0)))))))) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else (if (!(i.resetn) || s.mem_done) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.mem_do_wdata))
    mem_wordsize := (if !(i.resetn) then s.mem_wordsize else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then s.mem_wordsize else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then BitVec.extractLsb 1 0 (BitVec.ofNat 32 0) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then s.mem_wordsize else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 16).toNat) then s.mem_wordsize else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 8).toNat) then s.mem_wordsize else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 4).toNat) then s.mem_wordsize else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 2).toNat) then (if (!(s.mem_do_prefetch) || s.mem_done) then (if !(s.mem_do_wdata) then (if decide (boolToNat (true) = boolToNat (s.instr_sb)) then BitVec.extractLsb 1 0 (BitVec.ofNat 32 2) else (if decide (boolToNat (true) = boolToNat (s.instr_sh)) then BitVec.extractLsb 1 0 (BitVec.ofNat 32 1) else (if decide (boolToNat (true) = boolToNat (s.instr_sw)) then BitVec.extractLsb 1 0 (BitVec.ofNat 32 0) else s.mem_wordsize))) else s.mem_wordsize) else s.mem_wordsize) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 1).toNat) then (if (!(s.mem_do_prefetch) || s.mem_done) then (if !(s.mem_do_rdata) then (if decide (boolToNat (true) = boolToNat ((s.instr_lb || s.instr_lbu))) then BitVec.extractLsb 1 0 (BitVec.ofNat 32 2) else (if decide (boolToNat (true) = boolToNat ((s.instr_lh || s.instr_lhu))) then BitVec.extractLsb 1 0 (BitVec.ofNat 32 1) else (if decide (boolToNat (true) = boolToNat (s.instr_lw)) then BitVec.extractLsb 1 0 (BitVec.ofNat 32 0) else s.mem_wordsize))) else s.mem_wordsize) else s.mem_wordsize) else s.mem_wordsize)))))))))
    next_irq_pending := (if !(i.resetn) then BitVec.ofNat 32 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then (if false then (s.irq_pending &&& BitVec.ofNat 32 4294967295) else i.__rtl_nondet_0015) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then (if decide (boolToNat (true) = boolToNat (s.latched_branch)) then (if false then (s.irq_pending &&& BitVec.ofNat 32 4294967295) else i.__rtl_nondet_0015) else (if decide (boolToNat (true) = boolToNat ((s.latched_store && !(s.latched_branch)))) then (if false then (s.irq_pending &&& BitVec.ofNat 32 4294967295) else i.__rtl_nondet_0015) else (if decide (boolToNat (true) = boolToNat ((false && BitVec.getLsbD (s.irq_state) 0))) then (if false then (s.irq_pending &&& BitVec.ofNat 32 4294967295) else i.__rtl_nondet_0015) else (if decide (boolToNat (true) = boolToNat ((false && BitVec.getLsbD (s.irq_state) 1))) then ((if false then (s.irq_pending &&& BitVec.ofNat 32 4294967295) else i.__rtl_nondet_0015) &&& s.irq_mask) else (if false then (s.irq_pending &&& BitVec.ofNat 32 4294967295) else i.__rtl_nondet_0015))))) else (if false then (s.irq_pending &&& BitVec.ofNat 32 4294967295) else i.__rtl_nondet_0015))))
    pcpi_timeout := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else s.pcpi_timeout)
    pcpi_valid := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then s.pcpi_valid else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then s.pcpi_valid else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then s.pcpi_valid else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 16).toNat) then (if decide (boolToNat (true) = boolToNat ((false && s.instr_trap))) then (if s.pcpi_int_ready then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if (true && (s.pcpi_timeout || s.instr_ecall_ebreak)) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else BitVec.getLsbD (BitVec.ofNat 32 1) 0)) else s.pcpi_valid) else s.pcpi_valid)))))
    reg_next_pc := (if !(i.resetn) then BitVec.ofNat 32 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then s.reg_next_pc else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then (if s.decoder_trigger then (if s.instr_jal then ((if decide (boolToNat (true) = boolToNat (s.latched_branch)) then (if s.latched_store then ((if s.latched_stalu then s.alu_out_q else s.reg_out) &&& ~~~(BitVec.ofNat 32 1)) else s.reg_next_pc) else (if decide (boolToNat (true) = boolToNat ((s.latched_store && !(s.latched_branch)))) then s.reg_next_pc else (if decide (boolToNat (true) = boolToNat ((false && BitVec.getLsbD (s.irq_state) 0))) then BitVec.ofNat 32 16 else s.reg_next_pc))) + s.decoded_imm_j) else ((if decide (boolToNat (true) = boolToNat (s.latched_branch)) then (if s.latched_store then ((if s.latched_stalu then s.alu_out_q else s.reg_out) &&& ~~~(BitVec.ofNat 32 1)) else s.reg_next_pc) else (if decide (boolToNat (true) = boolToNat ((s.latched_store && !(s.latched_branch)))) then s.reg_next_pc else (if decide (boolToNat (true) = boolToNat ((false && BitVec.getLsbD (s.irq_state) 0))) then BitVec.ofNat 32 16 else s.reg_next_pc))) + (if s.compressed_instr then BitVec.ofNat 32 2 else BitVec.ofNat 32 4))) else (if decide (boolToNat (true) = boolToNat (s.latched_branch)) then (if s.latched_store then ((if s.latched_stalu then s.alu_out_q else s.reg_out) &&& ~~~(BitVec.ofNat 32 1)) else s.reg_next_pc) else (if decide (boolToNat (true) = boolToNat ((s.latched_store && !(s.latched_branch)))) then s.reg_next_pc else (if decide (boolToNat (true) = boolToNat ((false && BitVec.getLsbD (s.irq_state) 0))) then BitVec.ofNat 32 16 else s.reg_next_pc)))) else s.reg_next_pc)))
    reg_op1 := (if !(i.resetn) then s.reg_op1 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then s.reg_op1 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then s.reg_op1 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then (if decide (boolToNat (true) = boolToNat (((true || false) && s.instr_trap))) then i.__rtl_nondet_0017 else (if decide (boolToNat (true) = boolToNat ((true && s.is_rdcycle_rdcycleh_rdinstr_rdinstrh))) then i.__rtl_nondet_0017 else (if decide (boolToNat (true) = boolToNat (s.is_lui_auipc_jal)) then (if s.instr_lui then BitVec.ofNat 32 0 else s.reg_pc) else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_getq))) then i.__rtl_nondet_0017 else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_setq))) then i.__rtl_nondet_0017 else (if decide (boolToNat (true) = boolToNat ((false && s.instr_retirq))) then i.__rtl_nondet_0017 else (if decide (boolToNat (true) = boolToNat ((false && s.instr_maskirq))) then i.__rtl_nondet_0017 else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_timer))) then i.__rtl_nondet_0017 else s.cpuregs_rs1)))))))) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 16).toNat) then s.reg_op1 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 8).toNat) then s.reg_op1 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 4).toNat) then (if decide ((s.reg_sh).toNat = (BitVec.ofNat 32 0).toNat) then s.reg_op1 else (if (true && decide ((s.reg_sh).toNat >= (BitVec.ofNat 32 4).toNat)) then (if decide (boolToNat (true) = boolToNat ((s.instr_slli || s.instr_sll))) then BitVec.shiftLeft (s.reg_op1) (BitVec.ofNat 32 4).toNat else (if decide (boolToNat (true) = boolToNat ((s.instr_srli || s.instr_srl))) then BitVec.ushiftRight (s.reg_op1) (BitVec.ofNat 32 4).toNat else (if decide (boolToNat (true) = boolToNat ((s.instr_srai || s.instr_sra))) then BitVec.sshiftRight (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (s.reg_op1))) (BitVec.ofNat 32 4).toNat else s.reg_op1))) else (if decide (boolToNat (true) = boolToNat ((s.instr_slli || s.instr_sll))) then BitVec.shiftLeft (s.reg_op1) (BitVec.ofNat 32 1).toNat else (if decide (boolToNat (true) = boolToNat ((s.instr_srli || s.instr_srl))) then BitVec.ushiftRight (s.reg_op1) (BitVec.ofNat 32 1).toNat else (if decide (boolToNat (true) = boolToNat ((s.instr_srai || s.instr_sra))) then BitVec.sshiftRight (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (s.reg_op1))) (BitVec.ofNat 32 1).toNat else s.reg_op1))))) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 2).toNat) then (if (!(s.mem_do_prefetch) || s.mem_done) then (if !(s.mem_do_wdata) then (s.reg_op1 + s.decoded_imm) else s.reg_op1) else s.reg_op1) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 1).toNat) then (if (!(s.mem_do_prefetch) || s.mem_done) then (if !(s.mem_do_rdata) then (s.reg_op1 + s.decoded_imm) else s.reg_op1) else s.reg_op1) else s.reg_op1)))))))))
    reg_op2 := (if !(i.resetn) then s.reg_op2 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then s.reg_op2 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then s.reg_op2 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then (if decide (boolToNat (true) = boolToNat (((true || false) && s.instr_trap))) then i.__rtl_nondet_0018 else (if decide (boolToNat (true) = boolToNat ((true && s.is_rdcycle_rdcycleh_rdinstr_rdinstrh))) then i.__rtl_nondet_0018 else (if decide (boolToNat (true) = boolToNat (s.is_lui_auipc_jal)) then s.decoded_imm else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_getq))) then i.__rtl_nondet_0018 else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_setq))) then i.__rtl_nondet_0018 else (if decide (boolToNat (true) = boolToNat ((false && s.instr_retirq))) then i.__rtl_nondet_0018 else (if decide (boolToNat (true) = boolToNat ((false && s.instr_maskirq))) then i.__rtl_nondet_0018 else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_timer))) then i.__rtl_nondet_0018 else (if decide (boolToNat (true) = boolToNat ((s.is_lb_lh_lw_lbu_lhu && !(s.instr_trap)))) then i.__rtl_nondet_0018 else (if decide (boolToNat (true) = boolToNat ((s.is_slli_srli_srai && !(false)))) then i.__rtl_nondet_0018 else (if decide (boolToNat (true) = boolToNat (s.is_jalr_addi_slti_sltiu_xori_ori_andi)) then (if (s.is_slli_srli_srai && false) then BitVec.setWidth 32 (s.decoded_rs2) else s.decoded_imm) else (if decide (boolToNat (true) = boolToNat ((s.is_slli_srli_srai && false))) then (if (s.is_slli_srli_srai && false) then BitVec.setWidth 32 (s.decoded_rs2) else s.decoded_imm) else s.cpuregs_rs2)))))))))))) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 16).toNat) then s.cpuregs_rs2 else s.reg_op2)))))
    reg_out := (if !(i.resetn) then i.__rtl_nondet_0012 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then i.__rtl_nondet_0012 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then i.__rtl_nondet_0012 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then (if decide (boolToNat (true) = boolToNat (((true || false) && s.instr_trap))) then i.__rtl_nondet_0012 else (if decide (boolToNat (true) = boolToNat ((true && s.is_rdcycle_rdcycleh_rdinstr_rdinstrh))) then (if decide (boolToNat (true) = boolToNat (s.instr_rdcycle)) then BitVec.extractLsb 31 0 (s.count_cycle) else (if decide (boolToNat (true) = boolToNat ((s.instr_rdcycleh && true))) then BitVec.extractLsb 63 32 (s.count_cycle) else (if decide (boolToNat (true) = boolToNat (s.instr_rdinstr)) then BitVec.extractLsb 31 0 (s.count_instr) else (if decide (boolToNat (true) = boolToNat ((s.instr_rdinstrh && true))) then BitVec.extractLsb 63 32 (s.count_instr) else i.__rtl_nondet_0012)))) else (if decide (boolToNat (true) = boolToNat (s.is_lui_auipc_jal)) then i.__rtl_nondet_0012 else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_getq))) then s.cpuregs_rs1 else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_setq))) then s.cpuregs_rs1 else (if decide (boolToNat (true) = boolToNat ((false && s.instr_retirq))) then (if true then (s.cpuregs_rs1 &&& BitVec.ofNat 32 4294967294) else s.cpuregs_rs1) else (if decide (boolToNat (true) = boolToNat ((false && s.instr_maskirq))) then s.irq_mask else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_timer))) then s.timer else i.__rtl_nondet_0012)))))))) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 16).toNat) then (if decide (boolToNat (true) = boolToNat ((false && s.instr_trap))) then (if s.pcpi_int_ready then s.pcpi_int_rd else i.__rtl_nondet_0012) else i.__rtl_nondet_0012) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 8).toNat) then (s.reg_pc + s.decoded_imm) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 4).toNat) then (if decide ((s.reg_sh).toNat = (BitVec.ofNat 32 0).toNat) then s.reg_op1 else i.__rtl_nondet_0012) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 2).toNat) then i.__rtl_nondet_0012 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 1).toNat) then (if (!(s.mem_do_prefetch) || s.mem_done) then (if (!(s.mem_do_prefetch) && s.mem_done) then (if decide (boolToNat (true) = boolToNat (s.latched_is_lu)) then s.mem_rdata_word else (if decide (boolToNat (true) = boolToNat (s.latched_is_lh)) then BitVec.extractLsb 31 0 (BitVec.append (n := 16) (m := 16) ((if BitVec.getLsbD (BitVec.extractLsb 15 0 (BitVec.extractLsb 15 0 (s.mem_rdata_word))) 15 then BitVec.ofNat 16 65535 else BitVec.ofNat 16 0)) (BitVec.extractLsb 15 0 (BitVec.extractLsb 15 0 (s.mem_rdata_word)))) else (if decide (boolToNat (true) = boolToNat (s.latched_is_lb)) then BitVec.extractLsb 31 0 (BitVec.append (n := 24) (m := 8) ((if BitVec.getLsbD (BitVec.extractLsb 7 0 (BitVec.extractLsb 7 0 (s.mem_rdata_word))) 7 then BitVec.ofNat 24 16777215 else BitVec.ofNat 24 0)) (BitVec.extractLsb 7 0 (BitVec.extractLsb 7 0 (s.mem_rdata_word)))) else i.__rtl_nondet_0012))) else i.__rtl_nondet_0012) else i.__rtl_nondet_0012) else i.__rtl_nondet_0012)))))))))
    reg_pc := (if !(i.resetn) then BitVec.ofNat 32 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then s.reg_pc else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then (if decide (boolToNat (true) = boolToNat (s.latched_branch)) then (if s.latched_store then ((if s.latched_stalu then s.alu_out_q else s.reg_out) &&& ~~~(BitVec.ofNat 32 1)) else s.reg_next_pc) else (if decide (boolToNat (true) = boolToNat ((s.latched_store && !(s.latched_branch)))) then s.reg_next_pc else (if decide (boolToNat (true) = boolToNat ((false && BitVec.getLsbD (s.irq_state) 0))) then BitVec.ofNat 32 16 else s.reg_next_pc))) else s.reg_pc)))
    reg_sh := (if !(i.resetn) then BitVec.extractLsb 4 0 (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (i.__rtl_nondet_0011))) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then BitVec.extractLsb 4 0 (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (i.__rtl_nondet_0011))) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then BitVec.extractLsb 4 0 (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (i.__rtl_nondet_0011))) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then (if decide (boolToNat (true) = boolToNat (((true || false) && s.instr_trap))) then BitVec.extractLsb 4 0 (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (i.__rtl_nondet_0011))) else (if decide (boolToNat (true) = boolToNat ((true && s.is_rdcycle_rdcycleh_rdinstr_rdinstrh))) then BitVec.extractLsb 4 0 (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (i.__rtl_nondet_0011))) else (if decide (boolToNat (true) = boolToNat (s.is_lui_auipc_jal)) then BitVec.extractLsb 4 0 (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (i.__rtl_nondet_0011))) else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_getq))) then BitVec.extractLsb 4 0 (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (i.__rtl_nondet_0011))) else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_setq))) then BitVec.extractLsb 4 0 (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (i.__rtl_nondet_0011))) else (if decide (boolToNat (true) = boolToNat ((false && s.instr_retirq))) then BitVec.extractLsb 4 0 (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (i.__rtl_nondet_0011))) else (if decide (boolToNat (true) = boolToNat ((false && s.instr_maskirq))) then BitVec.extractLsb 4 0 (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (i.__rtl_nondet_0011))) else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_timer))) then BitVec.extractLsb 4 0 (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (i.__rtl_nondet_0011))) else (if decide (boolToNat (true) = boolToNat ((s.is_lb_lh_lw_lbu_lhu && !(s.instr_trap)))) then BitVec.extractLsb 4 0 (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (i.__rtl_nondet_0011))) else (if decide (boolToNat (true) = boolToNat ((s.is_slli_srli_srai && !(false)))) then s.decoded_rs2 else (if decide (boolToNat (true) = boolToNat (s.is_jalr_addi_slti_sltiu_xori_ori_andi)) then BitVec.extractLsb 4 0 (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (i.__rtl_nondet_0011))) else (if decide (boolToNat (true) = boolToNat ((s.is_slli_srli_srai && false))) then BitVec.extractLsb 4 0 (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (i.__rtl_nondet_0011))) else BitVec.extractLsb 4 0 (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (s.cpuregs_rs2))))))))))))))) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 16).toNat) then BitVec.extractLsb 4 0 (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (s.cpuregs_rs2))) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 8).toNat) then BitVec.extractLsb 4 0 (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (i.__rtl_nondet_0011))) else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 4).toNat) then (if decide ((s.reg_sh).toNat = (BitVec.ofNat 32 0).toNat) then BitVec.extractLsb 4 0 (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (i.__rtl_nondet_0011))) else (if (true && decide ((s.reg_sh).toNat >= (BitVec.ofNat 32 4).toNat)) then BitVec.extractLsb 4 0 ((BitVec.extractLsb 31 0 (BitVec.append (n := 27) (m := 5) (BitVec.ofNat 27 0) (BitVec.extractLsb 4 0 (s.reg_sh))) - BitVec.extractLsb 31 0 (BitVec.ofNat 32 4))) else BitVec.extractLsb 4 0 ((BitVec.extractLsb 31 0 (BitVec.append (n := 27) (m := 5) (BitVec.ofNat 27 0) (BitVec.extractLsb 4 0 (s.reg_sh))) - BitVec.extractLsb 31 0 (BitVec.ofNat 32 1))))) else BitVec.extractLsb 4 0 (BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (i.__rtl_nondet_0011))))))))))
    set_mem_do_rdata := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 16).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 8).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 4).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 2).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 1).toNat) then (if (!(s.mem_do_prefetch) || s.mem_done) then (if !(s.mem_do_rdata) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else BitVec.getLsbD (BitVec.ofNat 32 0) 0)))))))))
    set_mem_do_rinst := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 16).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 8).toNat) then (if s.is_beq_bne_blt_bge_bltu_bgeu then (if (if false then s.alu_out_0_q else s.alu_out_0) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else BitVec.getLsbD (BitVec.ofNat 32 0) 0))))))
    set_mem_do_wdata := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 16).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 8).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 4).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 2).toNat) then (if (!(s.mem_do_prefetch) || s.mem_done) then (if !(s.mem_do_wdata) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else BitVec.getLsbD (BitVec.ofNat 32 0) 0))))))))
    timer := (if !(i.resetn) then BitVec.ofNat 32 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then s.timer else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 64).toNat) then s.timer else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 32).toNat) then (if decide (boolToNat (true) = boolToNat (((true || false) && s.instr_trap))) then s.timer else (if decide (boolToNat (true) = boolToNat ((true && s.is_rdcycle_rdcycleh_rdinstr_rdinstrh))) then s.timer else (if decide (boolToNat (true) = boolToNat (s.is_lui_auipc_jal)) then s.timer else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_getq))) then s.timer else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_setq))) then s.timer else (if decide (boolToNat (true) = boolToNat ((false && s.instr_retirq))) then s.timer else (if decide (boolToNat (true) = boolToNat ((false && s.instr_maskirq))) then s.timer else (if decide (boolToNat (true) = boolToNat (((false && true) && s.instr_timer))) then s.cpuregs_rs1 else s.timer)))))))) else s.timer))))
    trace_data := BitVec.extractLsb 35 0 (BitVec.append (n := 4) (m := 32) (BitVec.ofNat 4 0) (BitVec.extractLsb 31 0 (i.__rtl_nondet_0016)))
    trace_valid := BitVec.getLsbD (BitVec.ofNat 32 0) 0
    trap := (if !(i.resetn) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.cpu_state).toNat = (BitVec.ofNat 8 128).toNat) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else BitVec.getLsbD (BitVec.ofNat 32 0) 0))
  }

/-- Parallel nonblocking commit for the single clock domain -/
def commit (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let s1 := proc_alwaysff s i
  let s2 := proc_alwaysff_1 s i
  let s3 := proc_alwaysff_2 s i
  let s4 := proc_alwaysff_3 s i
  let s5 := proc_alwaysff_4 s i
  let s6 := proc_alwaysff_5 s i
  let s7 := proc_alwaysff_6 s i
  let s8 := proc_alwaysff_7 s i
  let s9 := proc_alwaysff_8 s i
  let result := {
    alu_out_0_q := s9.alu_out_0_q
    alu_out_q := s9.alu_out_q
    alu_wait := s9.alu_wait
    alu_wait_2 := s9.alu_wait_2
    cached_ascii_instr := s5.cached_ascii_instr
    cached_insn_imm := s5.cached_insn_imm
    cached_insn_opcode := s5.cached_insn_opcode
    cached_insn_rd := s5.cached_insn_rd
    cached_insn_rs1 := s5.cached_insn_rs1
    cached_insn_rs2 := s5.cached_insn_rs2
    clear_prefetched_high_word_q := s7.clear_prefetched_high_word_q
    compressed_instr := s6.compressed_instr
    count_cycle := s9.count_cycle
    count_instr := s9.count_instr
    cpu_state := s9.cpu_state
    cpuregs := s8.cpuregs
    current_pc := s9.current_pc
    dbg_insn_addr := s5.dbg_insn_addr
    dbg_next := s5.dbg_next
    dbg_rs1val := s9.dbg_rs1val
    dbg_rs1val_valid := s9.dbg_rs1val_valid
    dbg_rs2val := s9.dbg_rs2val
    dbg_rs2val_valid := s9.dbg_rs2val_valid
    dbg_valid_insn := s5.dbg_valid_insn
    decoded_imm := s6.decoded_imm
    decoded_imm_j := s6.decoded_imm_j
    decoded_rd := s6.decoded_rd
    decoded_rs1 := s6.decoded_rs1
    decoded_rs2 := s6.decoded_rs2
    decoder_pseudo_trigger := s9.decoder_pseudo_trigger
    decoder_pseudo_trigger_q := s9.decoder_pseudo_trigger_q
    decoder_trigger := s9.decoder_trigger
    decoder_trigger_q := s9.decoder_trigger_q
    do_waitirq := s9.do_waitirq
    eoi := s9.eoi
    instr_add := s6.instr_add
    instr_addi := s6.instr_addi
    instr_and := s6.instr_and
    instr_andi := s6.instr_andi
    instr_auipc := s6.instr_auipc
    instr_beq := s6.instr_beq
    instr_bge := s6.instr_bge
    instr_bgeu := s6.instr_bgeu
    instr_blt := s6.instr_blt
    instr_bltu := s6.instr_bltu
    instr_bne := s6.instr_bne
    instr_ecall_ebreak := s6.instr_ecall_ebreak
    instr_fence := s6.instr_fence
    instr_getq := s6.instr_getq
    instr_jal := s6.instr_jal
    instr_jalr := s6.instr_jalr
    instr_lb := s6.instr_lb
    instr_lbu := s6.instr_lbu
    instr_lh := s6.instr_lh
    instr_lhu := s6.instr_lhu
    instr_lui := s6.instr_lui
    instr_lw := s6.instr_lw
    instr_maskirq := s6.instr_maskirq
    instr_or := s6.instr_or
    instr_ori := s6.instr_ori
    instr_rdcycle := s6.instr_rdcycle
    instr_rdcycleh := s6.instr_rdcycleh
    instr_rdinstr := s6.instr_rdinstr
    instr_rdinstrh := s6.instr_rdinstrh
    instr_retirq := s6.instr_retirq
    instr_sb := s6.instr_sb
    instr_setq := s6.instr_setq
    instr_sh := s6.instr_sh
    instr_sll := s6.instr_sll
    instr_slli := s6.instr_slli
    instr_slt := s6.instr_slt
    instr_slti := s6.instr_slti
    instr_sltiu := s6.instr_sltiu
    instr_sltu := s6.instr_sltu
    instr_sra := s6.instr_sra
    instr_srai := s6.instr_srai
    instr_srl := s6.instr_srl
    instr_srli := s6.instr_srli
    instr_sub := s6.instr_sub
    instr_sw := s6.instr_sw
    instr_timer := s6.instr_timer
    instr_waitirq := s6.instr_waitirq
    instr_xor := s6.instr_xor
    instr_xori := s6.instr_xori
    irq_active := s9.irq_active
    irq_delay := s9.irq_delay
    irq_mask := s9.irq_mask
    irq_pending := s9.irq_pending
    irq_state := s9.irq_state
    is_alu_reg_imm := s6.is_alu_reg_imm
    is_alu_reg_reg := s6.is_alu_reg_reg
    is_beq_bne_blt_bge_bltu_bgeu := s6.is_beq_bne_blt_bge_bltu_bgeu
    is_compare := s6.is_compare
    is_jalr_addi_slti_sltiu_xori_ori_andi := s6.is_jalr_addi_slti_sltiu_xori_ori_andi
    is_lb_lh_lw_lbu_lhu := s6.is_lb_lh_lw_lbu_lhu
    is_lbu_lhu_lw := s6.is_lbu_lhu_lw
    is_lui_auipc_jal := s6.is_lui_auipc_jal
    is_lui_auipc_jal_jalr_addi_add_sub := s6.is_lui_auipc_jal_jalr_addi_add_sub
    is_sb_sh_sw := s6.is_sb_sh_sw
    is_sll_srl_sra := s6.is_sll_srl_sra
    is_slli_srli_srai := s6.is_slli_srli_srai
    is_slti_blt_slt := s6.is_slti_blt_slt
    is_sltiu_bltu_sltu := s6.is_sltiu_bltu_sltu
    last_mem_valid := s1.last_mem_valid
    latched_branch := s9.latched_branch
    latched_compr := s9.latched_compr
    latched_is_lb := s9.latched_is_lb
    latched_is_lh := s9.latched_is_lh
    latched_is_lu := s9.latched_is_lu
    latched_rd := s9.latched_rd
    latched_stalu := s9.latched_stalu
    latched_store := s9.latched_store
    latched_trace := s9.latched_trace
    mem_16bit_buffer := s.mem_16bit_buffer
    mem_addr := s4.mem_addr
    mem_do_prefetch := s9.mem_do_prefetch
    mem_do_rdata := s9.mem_do_rdata
    mem_do_rinst := s9.mem_do_rinst
    mem_do_wdata := s9.mem_do_wdata
    mem_instr := s4.mem_instr
    mem_la_firstword_reg := s1.mem_la_firstword_reg
    mem_la_secondword := s4.mem_la_secondword
    mem_rdata_q := s2.mem_rdata_q
    mem_state := s4.mem_state
    mem_valid := s4.mem_valid
    mem_wdata := s4.mem_wdata
    mem_wordsize := s9.mem_wordsize
    mem_wstrb := s4.mem_wstrb
    next_insn_opcode := s2.next_insn_opcode
    next_irq_pending := s9.next_irq_pending
    pcpi_insn := s6.pcpi_insn
    pcpi_timeout := s9.pcpi_timeout
    pcpi_timeout_counter := s.pcpi_timeout_counter
    pcpi_valid := s9.pcpi_valid
    prefetched_high_word := s4.prefetched_high_word
    q_ascii_instr := s5.q_ascii_instr
    q_insn_imm := s5.q_insn_imm
    q_insn_opcode := s5.q_insn_opcode
    q_insn_rd := s5.q_insn_rd
    q_insn_rs1 := s5.q_insn_rs1
    q_insn_rs2 := s5.q_insn_rs2
    reg_next_pc := s9.reg_next_pc
    reg_op1 := s9.reg_op1
    reg_op2 := s9.reg_op2
    reg_out := s9.reg_out
    reg_pc := s9.reg_pc
    reg_sh := s9.reg_sh
    set_mem_do_rdata := s9.set_mem_do_rdata
    set_mem_do_rinst := s9.set_mem_do_rinst
    set_mem_do_wdata := s9.set_mem_do_wdata
    timer := s9.timer
    trace_data := s9.trace_data
    trace_valid := s9.trace_valid
    trap := s9.trap
    dbg_mem_valid := s.dbg_mem_valid
    dbg_mem_instr := s.dbg_mem_instr
    dbg_mem_ready := s.dbg_mem_ready
    dbg_mem_addr := s.dbg_mem_addr
    dbg_mem_wdata := s.dbg_mem_wdata
    dbg_mem_wstrb := s.dbg_mem_wstrb
    dbg_mem_rdata := s.dbg_mem_rdata
    next_pc := s.next_pc
    pcpi_mul_wr := s.pcpi_mul_wr
    pcpi_mul_rd := s.pcpi_mul_rd
    pcpi_mul_wait := s.pcpi_mul_wait
    pcpi_mul_ready := s.pcpi_mul_ready
    pcpi_div_wr := s.pcpi_div_wr
    pcpi_div_rd := s.pcpi_div_rd
    pcpi_div_wait := s.pcpi_div_wait
    pcpi_div_ready := s.pcpi_div_ready
    mem_xfer := s.mem_xfer
    mem_la_firstword := s.mem_la_firstword
    mem_la_firstword_xfer := s.mem_la_firstword_xfer
    mem_rdata_latched_noshuffle := s.mem_rdata_latched_noshuffle
    mem_rdata_latched := s.mem_rdata_latched
    mem_la_use_prefetched_high_word := s.mem_la_use_prefetched_high_word
    mem_busy := s.mem_busy
    mem_done := s.mem_done
    instr_trap := s.instr_trap
    is_rdcycle_rdcycleh_rdinstr_rdinstrh := s.is_rdcycle_rdcycleh_rdinstr_rdinstrh
    launch_next_insn := s.launch_next_insn
    mem_la_read := s.mem_la_read
    mem_la_write := s.mem_la_write
    mem_la_addr := s.mem_la_addr
    pcpi_rs1 := s.pcpi_rs1
    pcpi_rs2 := s.pcpi_rs2
    alu_add_sub := s.alu_add_sub
    alu_eq := s.alu_eq
    alu_lts := s.alu_lts
    alu_ltu := s.alu_ltu
    alu_out := s.alu_out
    alu_out_0 := s.alu_out_0
    alu_shl := s.alu_shl
    alu_shr := s.alu_shr
    clear_prefetched_high_word := s.clear_prefetched_high_word
    cpuregs_rs1 := s.cpuregs_rs1
    cpuregs_rs2 := s.cpuregs_rs2
    cpuregs_wrdata := s.cpuregs_wrdata
    cpuregs_write := s.cpuregs_write
    dbg_ascii_instr := s.dbg_ascii_instr
    dbg_ascii_state := s.dbg_ascii_state
    dbg_insn_imm := s.dbg_insn_imm
    dbg_insn_opcode := s.dbg_insn_opcode
    dbg_insn_rd := s.dbg_insn_rd
    dbg_insn_rs1 := s.dbg_insn_rs1
    dbg_insn_rs2 := s.dbg_insn_rs2
    decoded_rs := s.decoded_rs
    mem_la_wdata := s.mem_la_wdata
    mem_la_wstrb := s.mem_la_wstrb
    mem_rdata_word := s.mem_rdata_word
    new_ascii_instr := s.new_ascii_instr
    pcpi_int_rd := s.pcpi_int_rd
    pcpi_int_ready := s.pcpi_int_ready
    pcpi_int_wait := s.pcpi_int_wait
    pcpi_int_wr := s.pcpi_int_wr
  }
  result

/-- step: pre-comb → parallel next-state commit → post-comb settle -/
def step (s : picorv32State) (i : picorv32Inputs) : picorv32State :=
  let s_pre := comb s i
  let s_next := commit s_pre i
  let s_settled := comb s_next i
  s_settled

/-- Output helper -/
def outputs (s : picorv32State) : picorv32Outputs :=
  {
    trap := s.trap
    mem_valid := s.mem_valid
    mem_instr := s.mem_instr
    mem_addr := s.mem_addr
    mem_wdata := s.mem_wdata
    mem_wstrb := s.mem_wstrb
    mem_la_read := s.mem_la_read
    mem_la_write := s.mem_la_write
    mem_la_addr := s.mem_la_addr
    mem_la_wdata := s.mem_la_wdata
    mem_la_wstrb := s.mem_la_wstrb
    pcpi_valid := s.pcpi_valid
    pcpi_insn := s.pcpi_insn
    pcpi_rs1 := s.pcpi_rs1
    pcpi_rs2 := s.pcpi_rs2
    eoi := s.eoi
    trace_valid := s.trace_valid
    trace_data := s.trace_data
  }


end picorv32
