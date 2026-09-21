/-
自动生成的 Lean 4 代码
源模块：serv_rf_top
生成时间：Lean 4 RTL 编译器
-/

import Std
set_option linter.unusedVariables false
set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace serv_rf_top

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

structure serv_rf_topStateBlock0 where
  cpu__alu__add_cy_r : Bool
  cpu__alu__cmp_r : Bool
  cpu__bufreg2__dhi : BitVec 8
  cpu__bufreg2__dlo : BitVec 24
  cpu__bufreg__c_r : Bool
  cpu__bufreg__data : BitVec 32
  cpu__ctrl__o_ibus_adr : BitVec 32
  cpu__ctrl__pc_plus_4_cy_r : Bool
  cpu__ctrl__pc_plus_offset_cy_r : Bool
  cpu__decode__funct3 : BitVec 3
  cpu__decode__imm25 : Bool
  cpu__decode__imm30 : Bool
  cpu__decode__op20 : Bool
  cpu__decode__op21 : Bool
  cpu__decode__op22 : Bool
  cpu__decode__op26 : Bool
  cpu__decode__opcode : BitVec 5
  cpu__gen_csr__csr__mcause31 : Bool
  cpu__gen_csr__csr__mcause3_0 : BitVec 4
  cpu__gen_csr__csr__mie_mtie : Bool
  cpu__gen_csr__csr__mstatus_mie : Bool
  cpu__gen_csr__csr__mstatus_mpie : Bool
  cpu__gen_csr__csr__o_new_irq : Bool
  cpu__gen_csr__csr__timer_irq_r : Bool
  cpu__immdec__gen_immdec_w_eq_1__imm11_7 : BitVec 5
  cpu__immdec__gen_immdec_w_eq_1__imm19_12_20 : BitVec 9
  cpu__immdec__gen_immdec_w_eq_1__imm24_20 : BitVec 5
  cpu__immdec__gen_immdec_w_eq_1__imm30_25 : BitVec 6
  cpu__immdec__gen_immdec_w_eq_1__imm31 : Bool
  cpu__immdec__gen_immdec_w_eq_1__imm7 : Bool
  cpu__mem_if__signbit : Bool
  cpu__state__gen_cnt_w_eq_1__cnt_lsb : BitVec 4
  cpu__state__gen_csr__misalign_trap_sync_r : Bool
  cpu__state__ibus_cyc : Bool
  cpu__state__init_done : Bool
  cpu__state__o_cnt : BitVec 3
  cpu__state__o_ctrl_jump : Bool
  rf_ram__memory : BitVec 1152
  rf_ram__rdata : BitVec 2
  rf_ram__regzero : Bool
  rf_ram_if__rcnt : BitVec 5
  rf_ram_if__rdata0 : BitVec 2
  rf_ram_if__rdata1 : Bool
  rf_ram_if__rgate : Bool
  rf_ram_if__rgnt : Bool
  rf_ram_if__rreq_r : Bool
  rf_ram_if__rtrig1 : Bool
  rf_ram_if__wdata0_r : BitVec 2
  rf_ram_if__wdata1_r : BitVec 3
  rf_ram_if__wen0_r : Bool
  rf_ram_if__wen1_r : Bool
  rf_wreq : Bool
  rf_rreq : Bool
  wreg0 : BitVec 6
  wreg1 : BitVec 6
  wen0 : Bool
  wen1 : Bool
  wdata0 : Bool
  wdata1 : Bool
  rreg0 : BitVec 6
  rreg1 : BitVec 6
  rf_ready : Bool
  rdata0 : Bool
  rdata1 : Bool

structure serv_rf_topStateBlock1 where
  waddr : BitVec 10
  wdata : BitVec 2
  wen : Bool
  raddr : BitVec 10
  ren : Bool
  rdata : BitVec 2
  rf_ram_if__i_clk : Bool
  rf_ram_if__i_rst : Bool
  rf_ram_if__i_wreq : Bool
  rf_ram_if__i_rreq : Bool
  rf_ram_if__o_ready : Bool
  rf_ram_if__i_wreg0 : BitVec 6
  rf_ram_if__i_wreg1 : BitVec 6
  rf_ram_if__i_wen0 : Bool
  rf_ram_if__i_wen1 : Bool
  rf_ram_if__i_wdata0 : Bool
  rf_ram_if__i_wdata1 : Bool
  rf_ram_if__i_rreg0 : BitVec 6
  rf_ram_if__i_rreg1 : BitVec 6
  rf_ram_if__o_rdata0 : Bool
  rf_ram_if__o_rdata1 : Bool
  rf_ram_if__o_waddr : BitVec 10
  rf_ram_if__o_wdata : BitVec 2
  rf_ram_if__o_wen : Bool
  rf_ram_if__o_raddr : BitVec 10
  rf_ram_if__o_ren : Bool
  rf_ram_if__i_rdata : BitVec 2
  rf_ram_if__wcnt : BitVec 5
  rf_ram_if__wtrig0 : Bool
  rf_ram_if__wtrig1 : Bool
  rf_ram_if__wreg : BitVec 6
  rf_ram_if__rtrig0 : Bool
  rf_ram_if__rreg : BitVec 6
  rf_ram__i_clk : Bool
  rf_ram__i_waddr : BitVec 10
  rf_ram__i_wdata : BitVec 2
  rf_ram__i_wen : Bool
  rf_ram__i_raddr : BitVec 10
  rf_ram__i_ren : Bool
  rf_ram__o_rdata : BitVec 2
  cpu__clk : Bool
  cpu__i_rst : Bool
  cpu__i_timer_irq : Bool
  cpu__o_rf_rreq : Bool
  cpu__o_rf_wreq : Bool
  cpu__i_rf_ready : Bool
  cpu__o_wreg0 : BitVec 6
  cpu__o_wreg1 : BitVec 6
  cpu__o_wen0 : Bool
  cpu__o_wen1 : Bool
  cpu__o_wdata0 : Bool
  cpu__o_wdata1 : Bool
  cpu__o_rreg0 : BitVec 6
  cpu__o_rreg1 : BitVec 6
  cpu__i_rdata0 : Bool
  cpu__i_rdata1 : Bool
  cpu__o_ibus_adr : BitVec 32
  cpu__o_ibus_cyc : Bool
  cpu__i_ibus_rdt : BitVec 32
  cpu__i_ibus_ack : Bool
  cpu__o_dbus_adr : BitVec 32
  cpu__o_dbus_dat : BitVec 32
  cpu__o_dbus_sel : BitVec 4
  cpu__o_dbus_we : Bool

structure serv_rf_topStateBlock2 where
  cpu__o_dbus_cyc : Bool
  cpu__i_dbus_rdt : BitVec 32
  cpu__i_dbus_ack : Bool
  cpu__o_ext_funct3 : BitVec 3
  cpu__i_ext_ready : Bool
  cpu__i_ext_rd : BitVec 32
  cpu__o_ext_rs1 : BitVec 32
  cpu__o_ext_rs2 : BitVec 32
  cpu__o_mdu_valid : Bool
  cpu__rd_addr : BitVec 5
  cpu__rs1_addr : BitVec 5
  cpu__rs2_addr : BitVec 5
  cpu__immdec_ctrl : BitVec 4
  cpu__immdec_en : BitVec 4
  cpu__sh_right : Bool
  cpu__bne_or_bge : Bool
  cpu__cond_branch : Bool
  cpu__two_stage_op : Bool
  cpu__e_op : Bool
  cpu__ebreak : Bool
  cpu__branch_op : Bool
  cpu__shift_op : Bool
  cpu__rd_op : Bool
  cpu__mdu_op : Bool
  cpu__rd_alu_en : Bool
  cpu__rd_csr_en : Bool
  cpu__rd_mem_en : Bool
  cpu__ctrl_rd : Bool
  cpu__alu_rd : Bool
  cpu__mem_rd : Bool
  cpu__csr_rd : Bool
  cpu__mtval_pc : Bool
  cpu__ctrl_pc_en : Bool
  cpu__jump : Bool
  cpu__jal_or_jalr : Bool
  cpu__utype : Bool
  cpu__mret : Bool
  cpu__imm : Bool
  cpu__trap : Bool
  cpu__pc_rel : Bool
  cpu__iscomp : Bool
  cpu__init : Bool
  cpu__cnt_en : Bool
  cpu__cnt0to3 : Bool
  cpu__cnt12to31 : Bool
  cpu__cnt0 : Bool
  cpu__cnt1 : Bool
  cpu__cnt2 : Bool
  cpu__cnt3 : Bool
  cpu__cnt7 : Bool
  cpu__cnt11 : Bool
  cpu__cnt12 : Bool
  cpu__cnt_done : Bool
  cpu__bufreg_en : Bool
  cpu__bufreg_sh_signed : Bool
  cpu__bufreg_rs1_en : Bool
  cpu__bufreg_imm_en : Bool
  cpu__bufreg_clr_lsb : Bool
  cpu__bufreg_q : Bool
  cpu__bufreg2_q : Bool
  cpu__dbus_rdt : BitVec 32
  cpu__dbus_ack : Bool
  cpu__alu_sub : Bool
  cpu__alu_bool_op : BitVec 2

structure serv_rf_topStateBlock3 where
  cpu__alu_cmp_eq : Bool
  cpu__alu_cmp_sig : Bool
  cpu__alu_cmp : Bool
  cpu__alu_rd_sel : BitVec 3
  cpu__rs1 : Bool
  cpu__rs2 : Bool
  cpu__rd_en : Bool
  cpu__op_b : Bool
  cpu__op_b_sel : Bool
  cpu__mem_signed : Bool
  cpu__mem_word : Bool
  cpu__mem_half : Bool
  cpu__mem_bytecnt : BitVec 2
  cpu__sh_done : Bool
  cpu__mem_misalign : Bool
  cpu__bad_pc : Bool
  cpu__csr_mstatus_en : Bool
  cpu__csr_mie_en : Bool
  cpu__csr_mcause_en : Bool
  cpu__csr_source : BitVec 2
  cpu__csr_imm : Bool
  cpu__csr_d_sel : Bool
  cpu__csr_en : Bool
  cpu__csr_addr : BitVec 2
  cpu__csr_pc : Bool
  cpu__csr_imm_en : Bool
  cpu__csr_in : Bool
  cpu__rf_csr_out : Bool
  cpu__dbus_en : Bool
  cpu__new_irq : Bool
  cpu__lsb : BitVec 2
  cpu__i_wb_rdt : BitVec 32
  cpu__wb_ibus_adr : BitVec 32
  cpu__wb_ibus_cyc : Bool
  cpu__wb_ibus_rdt : BitVec 32
  cpu__wb_ibus_ack : Bool
  cpu__state__i_clk : Bool
  cpu__state__i_rst : Bool
  cpu__state__i_new_irq : Bool
  cpu__state__i_alu_cmp : Bool
  cpu__state__o_init : Bool
  cpu__state__o_cnt_en : Bool
  cpu__state__o_cnt0to3 : Bool
  cpu__state__o_cnt12to31 : Bool
  cpu__state__o_cnt0 : Bool
  cpu__state__o_cnt1 : Bool
  cpu__state__o_cnt2 : Bool
  cpu__state__o_cnt3 : Bool
  cpu__state__o_cnt7 : Bool
  cpu__state__o_cnt11 : Bool
  cpu__state__o_cnt12 : Bool
  cpu__state__o_cnt_done : Bool
  cpu__state__o_bufreg_en : Bool
  cpu__state__o_ctrl_pc_en : Bool
  cpu__state__o_ctrl_trap : Bool
  cpu__state__i_ctrl_misalign : Bool
  cpu__state__i_sh_done : Bool
  cpu__state__o_mem_bytecnt : BitVec 2
  cpu__state__i_mem_misalign : Bool
  cpu__state__i_bne_or_bge : Bool
  cpu__state__i_cond_branch : Bool
  cpu__state__i_dbus_en : Bool
  cpu__state__i_two_stage_op : Bool
  cpu__state__i_branch_op : Bool

structure serv_rf_topStateBlock4 where
  cpu__state__i_shift_op : Bool
  cpu__state__i_sh_right : Bool
  cpu__state__i_alu_rd_sel1 : Bool
  cpu__state__i_rd_alu_en : Bool
  cpu__state__i_e_op : Bool
  cpu__state__i_rd_op : Bool
  cpu__state__i_mdu_op : Bool
  cpu__state__o_mdu_valid : Bool
  cpu__state__i_mdu_ready : Bool
  cpu__state__o_dbus_cyc : Bool
  cpu__state__i_dbus_ack : Bool
  cpu__state__o_ibus_cyc : Bool
  cpu__state__i_ibus_ack : Bool
  cpu__state__o_rf_rreq : Bool
  cpu__state__o_rf_wreq : Bool
  cpu__state__i_rf_ready : Bool
  cpu__state__o_rf_rd_en : Bool
  cpu__state__misalign_trap_sync : Bool
  cpu__state__cnt_r : BitVec 4
  cpu__state__take_branch : Bool
  cpu__state__last_init : Bool
  cpu__state__trap_pending : Bool
  cpu__decode__clk : Bool
  cpu__decode__i_wb_rdt : BitVec 30
  cpu__decode__i_wb_en : Bool
  cpu__decode__co_mdu_op : Bool
  cpu__decode__co_two_stage_op : Bool
  cpu__decode__co_shift_op : Bool
  cpu__decode__co_branch_op : Bool
  cpu__decode__co_dbus_en : Bool
  cpu__decode__co_mtval_pc : Bool
  cpu__decode__co_mem_word : Bool
  cpu__decode__co_rd_alu_en : Bool
  cpu__decode__co_rd_mem_en : Bool
  cpu__decode__co_ext_funct3 : BitVec 3
  cpu__decode__co_bufreg_rs1_en : Bool
  cpu__decode__co_bufreg_imm_en : Bool
  cpu__decode__co_bufreg_clr_lsb : Bool
  cpu__decode__co_cond_branch : Bool
  cpu__decode__co_ctrl_utype : Bool
  cpu__decode__co_ctrl_jal_or_jalr : Bool
  cpu__decode__co_ctrl_pc_rel : Bool
  cpu__decode__co_rd_op : Bool
  cpu__decode__co_sh_right : Bool
  cpu__decode__co_bne_or_bge : Bool
  cpu__decode__csr_op : Bool
  cpu__decode__co_ebreak : Bool
  cpu__decode__co_ctrl_mret : Bool
  cpu__decode__co_e_op : Bool
  cpu__decode__co_bufreg_sh_signed : Bool
  cpu__decode__co_alu_sub : Bool
  cpu__decode__csr_valid : Bool
  cpu__decode__co_rd_csr_en : Bool
  cpu__decode__co_csr_en : Bool
  cpu__decode__co_csr_mstatus_en : Bool
  cpu__decode__co_csr_mie_en : Bool
  cpu__decode__co_csr_mcause_en : Bool
  cpu__decode__co_csr_source : BitVec 2
  cpu__decode__co_csr_d_sel : Bool
  cpu__decode__co_csr_imm_en : Bool
  cpu__decode__co_csr_addr : BitVec 2
  cpu__decode__co_alu_cmp_eq : Bool
  cpu__decode__co_alu_cmp_sig : Bool
  cpu__decode__co_mem_cmd : Bool

structure serv_rf_topStateBlock5 where
  cpu__decode__co_mem_signed : Bool
  cpu__decode__co_mem_half : Bool
  cpu__decode__co_alu_bool_op : BitVec 2
  cpu__decode__co_immdec_ctrl : BitVec 4
  cpu__decode__co_immdec_en : BitVec 4
  cpu__decode__co_alu_rd_sel : BitVec 3
  cpu__decode__co_op_b_source : Bool
  cpu__immdec__i_clk : Bool
  cpu__immdec__i_cnt_en : Bool
  cpu__immdec__i_cnt_done : Bool
  cpu__immdec__i_immdec_en : BitVec 4
  cpu__immdec__i_csr_imm_en : Bool
  cpu__immdec__i_ctrl : BitVec 4
  cpu__immdec__o_rd_addr : BitVec 5
  cpu__immdec__o_rs1_addr : BitVec 5
  cpu__immdec__o_rs2_addr : BitVec 5
  cpu__immdec__o_csr_imm : Bool
  cpu__immdec__o_imm : Bool
  cpu__immdec__i_wb_en : Bool
  cpu__immdec__i_wb_rdt : BitVec 25
  cpu__immdec__gen_immdec_w_eq_1__signbit : Bool
  cpu__bufreg__i_clk : Bool
  cpu__bufreg__i_cnt0 : Bool
  cpu__bufreg__i_cnt1 : Bool
  cpu__bufreg__i_cnt_done : Bool
  cpu__bufreg__i_en : Bool
  cpu__bufreg__i_init : Bool
  cpu__bufreg__i_mdu_op : Bool
  cpu__bufreg__o_lsb : BitVec 2
  cpu__bufreg__i_rs1_en : Bool
  cpu__bufreg__i_imm_en : Bool
  cpu__bufreg__i_clr_lsb : Bool
  cpu__bufreg__i_shift_op : Bool
  cpu__bufreg__i_right_shift_op : Bool
  cpu__bufreg__i_shamt : BitVec 3
  cpu__bufreg__i_sh_signed : Bool
  cpu__bufreg__i_rs1 : Bool
  cpu__bufreg__i_imm : Bool
  cpu__bufreg__o_q : Bool
  cpu__bufreg__o_dbus_adr : BitVec 32
  cpu__bufreg__o_ext_rs1 : BitVec 32
  cpu__bufreg__c : Bool
  cpu__bufreg__q : Bool
  cpu__bufreg__clr_lsb : Bool
  cpu__bufreg2__i_clk : Bool
  cpu__bufreg2__i_en : Bool
  cpu__bufreg2__i_init : Bool
  cpu__bufreg2__i_cnt7 : Bool
  cpu__bufreg2__i_cnt_done : Bool
  cpu__bufreg2__i_sh_right : Bool
  cpu__bufreg2__i_lsb : BitVec 2
  cpu__bufreg2__i_bytecnt : BitVec 2
  cpu__bufreg2__o_sh_done : Bool
  cpu__bufreg2__i_op_b_sel : Bool
  cpu__bufreg2__i_shift_op : Bool
  cpu__bufreg2__i_rs2 : Bool
  cpu__bufreg2__i_imm : Bool
  cpu__bufreg2__o_op_b : Bool
  cpu__bufreg2__o_q : Bool
  cpu__bufreg2__o_dat : BitVec 32
  cpu__bufreg2__i_load : Bool
  cpu__bufreg2__i_dat : BitVec 32
  cpu__bufreg2__byte_valid : Bool
  cpu__bufreg2__shift_en : Bool

structure serv_rf_topStateBlock6 where
  cpu__bufreg2__cnt_en : Bool
  cpu__bufreg2__cnt_next : BitVec 8
  cpu__bufreg2__dat_shamt : BitVec 8
  cpu__ctrl__clk : Bool
  cpu__ctrl__i_rst : Bool
  cpu__ctrl__i_pc_en : Bool
  cpu__ctrl__i_cnt12to31 : Bool
  cpu__ctrl__i_cnt0 : Bool
  cpu__ctrl__i_cnt1 : Bool
  cpu__ctrl__i_cnt2 : Bool
  cpu__ctrl__i_jump : Bool
  cpu__ctrl__i_jal_or_jalr : Bool
  cpu__ctrl__i_utype : Bool
  cpu__ctrl__i_pc_rel : Bool
  cpu__ctrl__i_trap : Bool
  cpu__ctrl__i_iscomp : Bool
  cpu__ctrl__i_imm : Bool
  cpu__ctrl__i_buf : Bool
  cpu__ctrl__i_csr_pc : Bool
  cpu__ctrl__o_rd : Bool
  cpu__ctrl__o_bad_pc : Bool
  cpu__ctrl__pc_plus_4 : Bool
  cpu__ctrl__pc_plus_4_cy : Bool
  cpu__ctrl__pc_plus_4_cy_r_w : Bool
  cpu__ctrl__pc_plus_offset : Bool
  cpu__ctrl__pc_plus_offset_cy : Bool
  cpu__ctrl__pc_plus_offset_cy_r_w : Bool
  cpu__ctrl__pc_plus_offset_aligned : Bool
  cpu__ctrl__plus_4 : Bool
  cpu__ctrl__pc : Bool
  cpu__ctrl__new_pc : Bool
  cpu__ctrl__offset_a : Bool
  cpu__ctrl__offset_b : Bool
  cpu__alu__clk : Bool
  cpu__alu__i_en : Bool
  cpu__alu__i_cnt0 : Bool
  cpu__alu__o_cmp : Bool
  cpu__alu__i_sub : Bool
  cpu__alu__i_bool_op : BitVec 2
  cpu__alu__i_cmp_eq : Bool
  cpu__alu__i_cmp_sig : Bool
  cpu__alu__i_rd_sel : BitVec 3
  cpu__alu__i_rs1 : Bool
  cpu__alu__i_op_b : Bool
  cpu__alu__i_buf : Bool
  cpu__alu__o_rd : Bool
  cpu__alu__result_add : Bool
  cpu__alu__result_slt : Bool
  cpu__alu__add_cy : Bool
  cpu__alu__rs1_sx : Bool
  cpu__alu__op_b_sx : Bool
  cpu__alu__add_b : Bool
  cpu__alu__result_lt : Bool
  cpu__alu__result_eq : Bool
  cpu__alu__result_bool : Bool
  cpu__rf_if__i_cnt_en : Bool
  cpu__rf_if__o_wreg0 : BitVec 6
  cpu__rf_if__o_wreg1 : BitVec 6
  cpu__rf_if__o_wen0 : Bool
  cpu__rf_if__o_wen1 : Bool
  cpu__rf_if__o_wdata0 : Bool
  cpu__rf_if__o_wdata1 : Bool
  cpu__rf_if__o_rreg0 : BitVec 6
  cpu__rf_if__o_rreg1 : BitVec 6

structure serv_rf_topStateBlock7 where
  cpu__rf_if__i_rdata0 : Bool
  cpu__rf_if__i_rdata1 : Bool
  cpu__rf_if__i_trap : Bool
  cpu__rf_if__i_mret : Bool
  cpu__rf_if__i_mepc : Bool
  cpu__rf_if__i_mtval_pc : Bool
  cpu__rf_if__i_bufreg_q : Bool
  cpu__rf_if__i_bad_pc : Bool
  cpu__rf_if__o_csr_pc : Bool
  cpu__rf_if__i_csr_en : Bool
  cpu__rf_if__i_csr_addr : BitVec 2
  cpu__rf_if__i_csr : Bool
  cpu__rf_if__o_csr : Bool
  cpu__rf_if__i_rd_wen : Bool
  cpu__rf_if__i_rd_waddr : BitVec 5
  cpu__rf_if__i_ctrl_rd : Bool
  cpu__rf_if__i_alu_rd : Bool
  cpu__rf_if__i_rd_alu_en : Bool
  cpu__rf_if__i_csr_rd : Bool
  cpu__rf_if__i_rd_csr_en : Bool
  cpu__rf_if__i_mem_rd : Bool
  cpu__rf_if__i_rd_mem_en : Bool
  cpu__rf_if__i_rs1_raddr : BitVec 5
  cpu__rf_if__o_rs1 : Bool
  cpu__rf_if__i_rs2_raddr : BitVec 5
  cpu__rf_if__o_rs2 : Bool
  cpu__rf_if__rd_wen : Bool
  cpu__rf_if__gen_csr__rd : Bool
  cpu__rf_if__gen_csr__mtval : Bool
  cpu__rf_if__gen_csr__sel_rs2 : Bool
  cpu__mem_if__i_clk : Bool
  cpu__mem_if__i_bytecnt : BitVec 2
  cpu__mem_if__i_lsb : BitVec 2
  cpu__mem_if__o_misalign : Bool
  cpu__mem_if__i_signed : Bool
  cpu__mem_if__i_word : Bool
  cpu__mem_if__i_half : Bool
  cpu__mem_if__i_mdu_op : Bool
  cpu__mem_if__i_bufreg2_q : Bool
  cpu__mem_if__o_rd : Bool
  cpu__mem_if__o_wb_sel : BitVec 4
  cpu__mem_if__dat_valid : Bool
  cpu__gen_csr__csr__i_clk : Bool
  cpu__gen_csr__csr__i_rst : Bool
  cpu__gen_csr__csr__i_trig_irq : Bool
  cpu__gen_csr__csr__i_en : Bool
  cpu__gen_csr__csr__i_cnt0to3 : Bool
  cpu__gen_csr__csr__i_cnt3 : Bool
  cpu__gen_csr__csr__i_cnt7 : Bool
  cpu__gen_csr__csr__i_cnt11 : Bool
  cpu__gen_csr__csr__i_cnt12 : Bool
  cpu__gen_csr__csr__i_cnt_done : Bool
  cpu__gen_csr__csr__i_mem_op : Bool
  cpu__gen_csr__csr__i_mtip : Bool
  cpu__gen_csr__csr__i_trap : Bool
  cpu__gen_csr__csr__i_e_op : Bool
  cpu__gen_csr__csr__i_ebreak : Bool
  cpu__gen_csr__csr__i_mem_cmd : Bool
  cpu__gen_csr__csr__i_mstatus_en : Bool
  cpu__gen_csr__csr__i_mie_en : Bool
  cpu__gen_csr__csr__i_mcause_en : Bool
  cpu__gen_csr__csr__i_csr_source : BitVec 2
  cpu__gen_csr__csr__i_mret : Bool
  cpu__gen_csr__csr__i_csr_d_sel : Bool

structure serv_rf_topStateBlock8 where
  cpu__gen_csr__csr__i_rf_csr_out : Bool
  cpu__gen_csr__csr__o_csr_in : Bool
  cpu__gen_csr__csr__i_csr_imm : Bool
  cpu__gen_csr__csr__i_rs1 : Bool
  cpu__gen_csr__csr__o_q : Bool
  cpu__gen_csr__csr__mcause : Bool
  cpu__gen_csr__csr__csr_in : Bool
  cpu__gen_csr__csr__csr_out : Bool
  cpu__gen_csr__csr__d : Bool
  cpu__gen_csr__csr__mstatus : Bool
  cpu__gen_csr__csr__timer_irq : Bool
  o_ibus_adr : BitVec 32
  o_ibus_cyc : Bool
  o_dbus_adr : BitVec 32
  o_dbus_dat : BitVec 32
  o_dbus_sel : BitVec 4
  o_dbus_we : Bool
  o_dbus_cyc : Bool
  o_ext_rs1 : BitVec 32
  o_ext_rs2 : BitVec 32
  o_ext_funct3 : BitVec 3
  o_mdu_valid : Bool
  cpu__decode__o_alu_bool_op : BitVec 2
  cpu__decode__o_alu_cmp_eq : Bool
  cpu__decode__o_alu_cmp_sig : Bool
  cpu__decode__o_alu_rd_sel : BitVec 3
  cpu__decode__o_alu_sub : Bool
  cpu__decode__o_bne_or_bge : Bool
  cpu__decode__o_branch_op : Bool
  cpu__decode__o_bufreg_clr_lsb : Bool
  cpu__decode__o_bufreg_imm_en : Bool
  cpu__decode__o_bufreg_rs1_en : Bool
  cpu__decode__o_bufreg_sh_signed : Bool
  cpu__decode__o_cond_branch : Bool
  cpu__decode__o_csr_addr : BitVec 2
  cpu__decode__o_csr_d_sel : Bool
  cpu__decode__o_csr_en : Bool
  cpu__decode__o_csr_imm_en : Bool
  cpu__decode__o_csr_mcause_en : Bool
  cpu__decode__o_csr_mie_en : Bool
  cpu__decode__o_csr_mstatus_en : Bool
  cpu__decode__o_csr_source : BitVec 2
  cpu__decode__o_ctrl_jal_or_jalr : Bool
  cpu__decode__o_ctrl_mret : Bool
  cpu__decode__o_ctrl_pc_rel : Bool
  cpu__decode__o_ctrl_utype : Bool
  cpu__decode__o_dbus_en : Bool
  cpu__decode__o_e_op : Bool
  cpu__decode__o_ebreak : Bool
  cpu__decode__o_ext_funct3 : BitVec 3
  cpu__decode__o_immdec_ctrl : BitVec 4
  cpu__decode__o_immdec_en : BitVec 4
  cpu__decode__o_mdu_op : Bool
  cpu__decode__o_mem_cmd : Bool
  cpu__decode__o_mem_half : Bool
  cpu__decode__o_mem_signed : Bool
  cpu__decode__o_mem_word : Bool
  cpu__decode__o_mtval_pc : Bool
  cpu__decode__o_op_b_source : Bool
  cpu__decode__o_rd_alu_en : Bool
  cpu__decode__o_rd_csr_en : Bool
  cpu__decode__o_rd_mem_en : Bool
  cpu__decode__o_rd_op : Bool
  cpu__decode__o_sh_right : Bool

structure serv_rf_topStateBlock9 where
  cpu__decode__o_shift_op : Bool
  cpu__decode__o_two_stage_op : Bool

/-- serv_rf_top 状态结构（保留全部字段的嵌套具体记录） -/
structure serv_rf_topState extends serv_rf_topStateBlock0, serv_rf_topStateBlock1, serv_rf_topStateBlock2, serv_rf_topStateBlock3, serv_rf_topStateBlock4, serv_rf_topStateBlock5, serv_rf_topStateBlock6, serv_rf_topStateBlock7, serv_rf_topStateBlock8, serv_rf_topStateBlock9 where

/-- serv_rf_top 输入信号 -/
structure serv_rf_topInputs where
  clk : Bool
  i_rst : Bool
  i_timer_irq : Bool
  i_ibus_rdt : BitVec 32
  i_ibus_ack : Bool
  i_dbus_rdt : BitVec 32
  i_dbus_ack : Bool
  i_ext_rd : BitVec 32
  i_ext_ready : Bool
  __rtl_nondet_0001 : Bool
  __rtl_nondet_0000 : Bool

/-- serv_rf_top 输出信号 -/
structure serv_rf_topOutputs where
  o_ibus_adr : BitVec 32
  o_ibus_cyc : Bool
  o_dbus_adr : BitVec 32
  o_dbus_dat : BitVec 32
  o_dbus_sel : BitVec 4
  o_dbus_we : Bool
  o_dbus_cyc : Bool
  o_ext_rs1 : BitVec 32
  o_ext_rs2 : BitVec 32
  o_ext_funct3 : BitVec 3
  o_mdu_valid : Bool

/-- serv_rf_top 初始状态 -/
def init : serv_rf_topState where
  cpu__alu__add_cy_r := false
  cpu__alu__cmp_r := false
  cpu__bufreg2__dhi := BitVec.ofNat 8 0
  cpu__bufreg2__dlo := BitVec.ofNat 24 0
  cpu__bufreg__c_r := false
  cpu__bufreg__data := BitVec.ofNat 32 0
  cpu__ctrl__o_ibus_adr := BitVec.ofNat 32 0
  cpu__ctrl__pc_plus_4_cy_r := false
  cpu__ctrl__pc_plus_offset_cy_r := false
  cpu__decode__funct3 := BitVec.ofNat 3 0
  cpu__decode__imm25 := false
  cpu__decode__imm30 := false
  cpu__decode__op20 := false
  cpu__decode__op21 := false
  cpu__decode__op22 := false
  cpu__decode__op26 := false
  cpu__decode__opcode := BitVec.ofNat 5 0
  cpu__gen_csr__csr__mcause31 := false
  cpu__gen_csr__csr__mcause3_0 := BitVec.ofNat 4 0
  cpu__gen_csr__csr__mie_mtie := false
  cpu__gen_csr__csr__mstatus_mie := false
  cpu__gen_csr__csr__mstatus_mpie := false
  cpu__gen_csr__csr__o_new_irq := false
  cpu__gen_csr__csr__timer_irq_r := false
  cpu__immdec__gen_immdec_w_eq_1__imm11_7 := BitVec.ofNat 5 0
  cpu__immdec__gen_immdec_w_eq_1__imm19_12_20 := BitVec.ofNat 9 0
  cpu__immdec__gen_immdec_w_eq_1__imm24_20 := BitVec.ofNat 5 0
  cpu__immdec__gen_immdec_w_eq_1__imm30_25 := BitVec.ofNat 6 0
  cpu__immdec__gen_immdec_w_eq_1__imm31 := false
  cpu__immdec__gen_immdec_w_eq_1__imm7 := false
  cpu__mem_if__signbit := false
  cpu__state__gen_cnt_w_eq_1__cnt_lsb := BitVec.ofNat 4 0
  cpu__state__gen_csr__misalign_trap_sync_r := false
  cpu__state__ibus_cyc := false
  cpu__state__init_done := false
  cpu__state__o_cnt := BitVec.ofNat 3 0
  cpu__state__o_ctrl_jump := false
  rf_ram__memory := BitVec.ofNat 1152 0
  rf_ram__rdata := BitVec.ofNat 2 0
  rf_ram__regzero := false
  rf_ram_if__rcnt := BitVec.ofNat 5 0
  rf_ram_if__rdata0 := BitVec.ofNat 2 0
  rf_ram_if__rdata1 := false
  rf_ram_if__rgate := false
  rf_ram_if__rgnt := false
  rf_ram_if__rreq_r := false
  rf_ram_if__rtrig1 := false
  rf_ram_if__wdata0_r := BitVec.ofNat 2 0
  rf_ram_if__wdata1_r := BitVec.ofNat 3 0
  rf_ram_if__wen0_r := false
  rf_ram_if__wen1_r := false
  rf_wreq := false
  rf_rreq := false
  wreg0 := BitVec.ofNat 6 0
  wreg1 := BitVec.ofNat 6 0
  wen0 := false
  wen1 := false
  wdata0 := false
  wdata1 := false
  rreg0 := BitVec.ofNat 6 0
  rreg1 := BitVec.ofNat 6 0
  rf_ready := false
  rdata0 := false
  rdata1 := false
  waddr := BitVec.ofNat 10 0
  wdata := BitVec.ofNat 2 0
  wen := false
  raddr := BitVec.ofNat 10 0
  ren := false
  rdata := BitVec.ofNat 2 0
  rf_ram_if__i_clk := false
  rf_ram_if__i_rst := false
  rf_ram_if__i_wreq := false
  rf_ram_if__i_rreq := false
  rf_ram_if__o_ready := false
  rf_ram_if__i_wreg0 := BitVec.ofNat 6 0
  rf_ram_if__i_wreg1 := BitVec.ofNat 6 0
  rf_ram_if__i_wen0 := false
  rf_ram_if__i_wen1 := false
  rf_ram_if__i_wdata0 := false
  rf_ram_if__i_wdata1 := false
  rf_ram_if__i_rreg0 := BitVec.ofNat 6 0
  rf_ram_if__i_rreg1 := BitVec.ofNat 6 0
  rf_ram_if__o_rdata0 := false
  rf_ram_if__o_rdata1 := false
  rf_ram_if__o_waddr := BitVec.ofNat 10 0
  rf_ram_if__o_wdata := BitVec.ofNat 2 0
  rf_ram_if__o_wen := false
  rf_ram_if__o_raddr := BitVec.ofNat 10 0
  rf_ram_if__o_ren := false
  rf_ram_if__i_rdata := BitVec.ofNat 2 0
  rf_ram_if__wcnt := BitVec.ofNat 5 0
  rf_ram_if__wtrig0 := false
  rf_ram_if__wtrig1 := false
  rf_ram_if__wreg := BitVec.ofNat 6 0
  rf_ram_if__rtrig0 := false
  rf_ram_if__rreg := BitVec.ofNat 6 0
  rf_ram__i_clk := false
  rf_ram__i_waddr := BitVec.ofNat 10 0
  rf_ram__i_wdata := BitVec.ofNat 2 0
  rf_ram__i_wen := false
  rf_ram__i_raddr := BitVec.ofNat 10 0
  rf_ram__i_ren := false
  rf_ram__o_rdata := BitVec.ofNat 2 0
  cpu__clk := false
  cpu__i_rst := false
  cpu__i_timer_irq := false
  cpu__o_rf_rreq := false
  cpu__o_rf_wreq := false
  cpu__i_rf_ready := false
  cpu__o_wreg0 := BitVec.ofNat 6 0
  cpu__o_wreg1 := BitVec.ofNat 6 0
  cpu__o_wen0 := false
  cpu__o_wen1 := false
  cpu__o_wdata0 := false
  cpu__o_wdata1 := false
  cpu__o_rreg0 := BitVec.ofNat 6 0
  cpu__o_rreg1 := BitVec.ofNat 6 0
  cpu__i_rdata0 := false
  cpu__i_rdata1 := false
  cpu__o_ibus_adr := BitVec.ofNat 32 0
  cpu__o_ibus_cyc := false
  cpu__i_ibus_rdt := BitVec.ofNat 32 0
  cpu__i_ibus_ack := false
  cpu__o_dbus_adr := BitVec.ofNat 32 0
  cpu__o_dbus_dat := BitVec.ofNat 32 0
  cpu__o_dbus_sel := BitVec.ofNat 4 0
  cpu__o_dbus_we := false
  cpu__o_dbus_cyc := false
  cpu__i_dbus_rdt := BitVec.ofNat 32 0
  cpu__i_dbus_ack := false
  cpu__o_ext_funct3 := BitVec.ofNat 3 0
  cpu__i_ext_ready := false
  cpu__i_ext_rd := BitVec.ofNat 32 0
  cpu__o_ext_rs1 := BitVec.ofNat 32 0
  cpu__o_ext_rs2 := BitVec.ofNat 32 0
  cpu__o_mdu_valid := false
  cpu__rd_addr := BitVec.ofNat 5 0
  cpu__rs1_addr := BitVec.ofNat 5 0
  cpu__rs2_addr := BitVec.ofNat 5 0
  cpu__immdec_ctrl := BitVec.ofNat 4 0
  cpu__immdec_en := BitVec.ofNat 4 0
  cpu__sh_right := false
  cpu__bne_or_bge := false
  cpu__cond_branch := false
  cpu__two_stage_op := false
  cpu__e_op := false
  cpu__ebreak := false
  cpu__branch_op := false
  cpu__shift_op := false
  cpu__rd_op := false
  cpu__mdu_op := false
  cpu__rd_alu_en := false
  cpu__rd_csr_en := false
  cpu__rd_mem_en := false
  cpu__ctrl_rd := false
  cpu__alu_rd := false
  cpu__mem_rd := false
  cpu__csr_rd := false
  cpu__mtval_pc := false
  cpu__ctrl_pc_en := false
  cpu__jump := false
  cpu__jal_or_jalr := false
  cpu__utype := false
  cpu__mret := false
  cpu__imm := false
  cpu__trap := false
  cpu__pc_rel := false
  cpu__iscomp := false
  cpu__init := false
  cpu__cnt_en := false
  cpu__cnt0to3 := false
  cpu__cnt12to31 := false
  cpu__cnt0 := false
  cpu__cnt1 := false
  cpu__cnt2 := false
  cpu__cnt3 := false
  cpu__cnt7 := false
  cpu__cnt11 := false
  cpu__cnt12 := false
  cpu__cnt_done := false
  cpu__bufreg_en := false
  cpu__bufreg_sh_signed := false
  cpu__bufreg_rs1_en := false
  cpu__bufreg_imm_en := false
  cpu__bufreg_clr_lsb := false
  cpu__bufreg_q := false
  cpu__bufreg2_q := false
  cpu__dbus_rdt := BitVec.ofNat 32 0
  cpu__dbus_ack := false
  cpu__alu_sub := false
  cpu__alu_bool_op := BitVec.ofNat 2 0
  cpu__alu_cmp_eq := false
  cpu__alu_cmp_sig := false
  cpu__alu_cmp := false
  cpu__alu_rd_sel := BitVec.ofNat 3 0
  cpu__rs1 := false
  cpu__rs2 := false
  cpu__rd_en := false
  cpu__op_b := false
  cpu__op_b_sel := false
  cpu__mem_signed := false
  cpu__mem_word := false
  cpu__mem_half := false
  cpu__mem_bytecnt := BitVec.ofNat 2 0
  cpu__sh_done := false
  cpu__mem_misalign := false
  cpu__bad_pc := false
  cpu__csr_mstatus_en := false
  cpu__csr_mie_en := false
  cpu__csr_mcause_en := false
  cpu__csr_source := BitVec.ofNat 2 0
  cpu__csr_imm := false
  cpu__csr_d_sel := false
  cpu__csr_en := false
  cpu__csr_addr := BitVec.ofNat 2 0
  cpu__csr_pc := false
  cpu__csr_imm_en := false
  cpu__csr_in := false
  cpu__rf_csr_out := false
  cpu__dbus_en := false
  cpu__new_irq := false
  cpu__lsb := BitVec.ofNat 2 0
  cpu__i_wb_rdt := BitVec.ofNat 32 0
  cpu__wb_ibus_adr := BitVec.ofNat 32 0
  cpu__wb_ibus_cyc := false
  cpu__wb_ibus_rdt := BitVec.ofNat 32 0
  cpu__wb_ibus_ack := false
  cpu__state__i_clk := false
  cpu__state__i_rst := false
  cpu__state__i_new_irq := false
  cpu__state__i_alu_cmp := false
  cpu__state__o_init := false
  cpu__state__o_cnt_en := false
  cpu__state__o_cnt0to3 := false
  cpu__state__o_cnt12to31 := false
  cpu__state__o_cnt0 := false
  cpu__state__o_cnt1 := false
  cpu__state__o_cnt2 := false
  cpu__state__o_cnt3 := false
  cpu__state__o_cnt7 := false
  cpu__state__o_cnt11 := false
  cpu__state__o_cnt12 := false
  cpu__state__o_cnt_done := false
  cpu__state__o_bufreg_en := false
  cpu__state__o_ctrl_pc_en := false
  cpu__state__o_ctrl_trap := false
  cpu__state__i_ctrl_misalign := false
  cpu__state__i_sh_done := false
  cpu__state__o_mem_bytecnt := BitVec.ofNat 2 0
  cpu__state__i_mem_misalign := false
  cpu__state__i_bne_or_bge := false
  cpu__state__i_cond_branch := false
  cpu__state__i_dbus_en := false
  cpu__state__i_two_stage_op := false
  cpu__state__i_branch_op := false
  cpu__state__i_shift_op := false
  cpu__state__i_sh_right := false
  cpu__state__i_alu_rd_sel1 := false
  cpu__state__i_rd_alu_en := false
  cpu__state__i_e_op := false
  cpu__state__i_rd_op := false
  cpu__state__i_mdu_op := false
  cpu__state__o_mdu_valid := false
  cpu__state__i_mdu_ready := false
  cpu__state__o_dbus_cyc := false
  cpu__state__i_dbus_ack := false
  cpu__state__o_ibus_cyc := false
  cpu__state__i_ibus_ack := false
  cpu__state__o_rf_rreq := false
  cpu__state__o_rf_wreq := false
  cpu__state__i_rf_ready := false
  cpu__state__o_rf_rd_en := false
  cpu__state__misalign_trap_sync := false
  cpu__state__cnt_r := BitVec.ofNat 4 0
  cpu__state__take_branch := false
  cpu__state__last_init := false
  cpu__state__trap_pending := false
  cpu__decode__clk := false
  cpu__decode__i_wb_rdt := BitVec.ofNat 30 0
  cpu__decode__i_wb_en := false
  cpu__decode__co_mdu_op := false
  cpu__decode__co_two_stage_op := false
  cpu__decode__co_shift_op := false
  cpu__decode__co_branch_op := false
  cpu__decode__co_dbus_en := false
  cpu__decode__co_mtval_pc := false
  cpu__decode__co_mem_word := false
  cpu__decode__co_rd_alu_en := false
  cpu__decode__co_rd_mem_en := false
  cpu__decode__co_ext_funct3 := BitVec.ofNat 3 0
  cpu__decode__co_bufreg_rs1_en := false
  cpu__decode__co_bufreg_imm_en := false
  cpu__decode__co_bufreg_clr_lsb := false
  cpu__decode__co_cond_branch := false
  cpu__decode__co_ctrl_utype := false
  cpu__decode__co_ctrl_jal_or_jalr := false
  cpu__decode__co_ctrl_pc_rel := false
  cpu__decode__co_rd_op := false
  cpu__decode__co_sh_right := false
  cpu__decode__co_bne_or_bge := false
  cpu__decode__csr_op := false
  cpu__decode__co_ebreak := false
  cpu__decode__co_ctrl_mret := false
  cpu__decode__co_e_op := false
  cpu__decode__co_bufreg_sh_signed := false
  cpu__decode__co_alu_sub := false
  cpu__decode__csr_valid := false
  cpu__decode__co_rd_csr_en := false
  cpu__decode__co_csr_en := false
  cpu__decode__co_csr_mstatus_en := false
  cpu__decode__co_csr_mie_en := false
  cpu__decode__co_csr_mcause_en := false
  cpu__decode__co_csr_source := BitVec.ofNat 2 0
  cpu__decode__co_csr_d_sel := false
  cpu__decode__co_csr_imm_en := false
  cpu__decode__co_csr_addr := BitVec.ofNat 2 0
  cpu__decode__co_alu_cmp_eq := false
  cpu__decode__co_alu_cmp_sig := false
  cpu__decode__co_mem_cmd := false
  cpu__decode__co_mem_signed := false
  cpu__decode__co_mem_half := false
  cpu__decode__co_alu_bool_op := BitVec.ofNat 2 0
  cpu__decode__co_immdec_ctrl := BitVec.ofNat 4 0
  cpu__decode__co_immdec_en := BitVec.ofNat 4 0
  cpu__decode__co_alu_rd_sel := BitVec.ofNat 3 0
  cpu__decode__co_op_b_source := false
  cpu__immdec__i_clk := false
  cpu__immdec__i_cnt_en := false
  cpu__immdec__i_cnt_done := false
  cpu__immdec__i_immdec_en := BitVec.ofNat 4 0
  cpu__immdec__i_csr_imm_en := false
  cpu__immdec__i_ctrl := BitVec.ofNat 4 0
  cpu__immdec__o_rd_addr := BitVec.ofNat 5 0
  cpu__immdec__o_rs1_addr := BitVec.ofNat 5 0
  cpu__immdec__o_rs2_addr := BitVec.ofNat 5 0
  cpu__immdec__o_csr_imm := false
  cpu__immdec__o_imm := false
  cpu__immdec__i_wb_en := false
  cpu__immdec__i_wb_rdt := BitVec.ofNat 25 0
  cpu__immdec__gen_immdec_w_eq_1__signbit := false
  cpu__bufreg__i_clk := false
  cpu__bufreg__i_cnt0 := false
  cpu__bufreg__i_cnt1 := false
  cpu__bufreg__i_cnt_done := false
  cpu__bufreg__i_en := false
  cpu__bufreg__i_init := false
  cpu__bufreg__i_mdu_op := false
  cpu__bufreg__o_lsb := BitVec.ofNat 2 0
  cpu__bufreg__i_rs1_en := false
  cpu__bufreg__i_imm_en := false
  cpu__bufreg__i_clr_lsb := false
  cpu__bufreg__i_shift_op := false
  cpu__bufreg__i_right_shift_op := false
  cpu__bufreg__i_shamt := BitVec.ofNat 3 0
  cpu__bufreg__i_sh_signed := false
  cpu__bufreg__i_rs1 := false
  cpu__bufreg__i_imm := false
  cpu__bufreg__o_q := false
  cpu__bufreg__o_dbus_adr := BitVec.ofNat 32 0
  cpu__bufreg__o_ext_rs1 := BitVec.ofNat 32 0
  cpu__bufreg__c := false
  cpu__bufreg__q := false
  cpu__bufreg__clr_lsb := false
  cpu__bufreg2__i_clk := false
  cpu__bufreg2__i_en := false
  cpu__bufreg2__i_init := false
  cpu__bufreg2__i_cnt7 := false
  cpu__bufreg2__i_cnt_done := false
  cpu__bufreg2__i_sh_right := false
  cpu__bufreg2__i_lsb := BitVec.ofNat 2 0
  cpu__bufreg2__i_bytecnt := BitVec.ofNat 2 0
  cpu__bufreg2__o_sh_done := false
  cpu__bufreg2__i_op_b_sel := false
  cpu__bufreg2__i_shift_op := false
  cpu__bufreg2__i_rs2 := false
  cpu__bufreg2__i_imm := false
  cpu__bufreg2__o_op_b := false
  cpu__bufreg2__o_q := false
  cpu__bufreg2__o_dat := BitVec.ofNat 32 0
  cpu__bufreg2__i_load := false
  cpu__bufreg2__i_dat := BitVec.ofNat 32 0
  cpu__bufreg2__byte_valid := false
  cpu__bufreg2__shift_en := false
  cpu__bufreg2__cnt_en := false
  cpu__bufreg2__cnt_next := BitVec.ofNat 8 0
  cpu__bufreg2__dat_shamt := BitVec.ofNat 8 0
  cpu__ctrl__clk := false
  cpu__ctrl__i_rst := false
  cpu__ctrl__i_pc_en := false
  cpu__ctrl__i_cnt12to31 := false
  cpu__ctrl__i_cnt0 := false
  cpu__ctrl__i_cnt1 := false
  cpu__ctrl__i_cnt2 := false
  cpu__ctrl__i_jump := false
  cpu__ctrl__i_jal_or_jalr := false
  cpu__ctrl__i_utype := false
  cpu__ctrl__i_pc_rel := false
  cpu__ctrl__i_trap := false
  cpu__ctrl__i_iscomp := false
  cpu__ctrl__i_imm := false
  cpu__ctrl__i_buf := false
  cpu__ctrl__i_csr_pc := false
  cpu__ctrl__o_rd := false
  cpu__ctrl__o_bad_pc := false
  cpu__ctrl__pc_plus_4 := false
  cpu__ctrl__pc_plus_4_cy := false
  cpu__ctrl__pc_plus_4_cy_r_w := false
  cpu__ctrl__pc_plus_offset := false
  cpu__ctrl__pc_plus_offset_cy := false
  cpu__ctrl__pc_plus_offset_cy_r_w := false
  cpu__ctrl__pc_plus_offset_aligned := false
  cpu__ctrl__plus_4 := false
  cpu__ctrl__pc := false
  cpu__ctrl__new_pc := false
  cpu__ctrl__offset_a := false
  cpu__ctrl__offset_b := false
  cpu__alu__clk := false
  cpu__alu__i_en := false
  cpu__alu__i_cnt0 := false
  cpu__alu__o_cmp := false
  cpu__alu__i_sub := false
  cpu__alu__i_bool_op := BitVec.ofNat 2 0
  cpu__alu__i_cmp_eq := false
  cpu__alu__i_cmp_sig := false
  cpu__alu__i_rd_sel := BitVec.ofNat 3 0
  cpu__alu__i_rs1 := false
  cpu__alu__i_op_b := false
  cpu__alu__i_buf := false
  cpu__alu__o_rd := false
  cpu__alu__result_add := false
  cpu__alu__result_slt := false
  cpu__alu__add_cy := false
  cpu__alu__rs1_sx := false
  cpu__alu__op_b_sx := false
  cpu__alu__add_b := false
  cpu__alu__result_lt := false
  cpu__alu__result_eq := false
  cpu__alu__result_bool := false
  cpu__rf_if__i_cnt_en := false
  cpu__rf_if__o_wreg0 := BitVec.ofNat 6 0
  cpu__rf_if__o_wreg1 := BitVec.ofNat 6 0
  cpu__rf_if__o_wen0 := false
  cpu__rf_if__o_wen1 := false
  cpu__rf_if__o_wdata0 := false
  cpu__rf_if__o_wdata1 := false
  cpu__rf_if__o_rreg0 := BitVec.ofNat 6 0
  cpu__rf_if__o_rreg1 := BitVec.ofNat 6 0
  cpu__rf_if__i_rdata0 := false
  cpu__rf_if__i_rdata1 := false
  cpu__rf_if__i_trap := false
  cpu__rf_if__i_mret := false
  cpu__rf_if__i_mepc := false
  cpu__rf_if__i_mtval_pc := false
  cpu__rf_if__i_bufreg_q := false
  cpu__rf_if__i_bad_pc := false
  cpu__rf_if__o_csr_pc := false
  cpu__rf_if__i_csr_en := false
  cpu__rf_if__i_csr_addr := BitVec.ofNat 2 0
  cpu__rf_if__i_csr := false
  cpu__rf_if__o_csr := false
  cpu__rf_if__i_rd_wen := false
  cpu__rf_if__i_rd_waddr := BitVec.ofNat 5 0
  cpu__rf_if__i_ctrl_rd := false
  cpu__rf_if__i_alu_rd := false
  cpu__rf_if__i_rd_alu_en := false
  cpu__rf_if__i_csr_rd := false
  cpu__rf_if__i_rd_csr_en := false
  cpu__rf_if__i_mem_rd := false
  cpu__rf_if__i_rd_mem_en := false
  cpu__rf_if__i_rs1_raddr := BitVec.ofNat 5 0
  cpu__rf_if__o_rs1 := false
  cpu__rf_if__i_rs2_raddr := BitVec.ofNat 5 0
  cpu__rf_if__o_rs2 := false
  cpu__rf_if__rd_wen := false
  cpu__rf_if__gen_csr__rd := false
  cpu__rf_if__gen_csr__mtval := false
  cpu__rf_if__gen_csr__sel_rs2 := false
  cpu__mem_if__i_clk := false
  cpu__mem_if__i_bytecnt := BitVec.ofNat 2 0
  cpu__mem_if__i_lsb := BitVec.ofNat 2 0
  cpu__mem_if__o_misalign := false
  cpu__mem_if__i_signed := false
  cpu__mem_if__i_word := false
  cpu__mem_if__i_half := false
  cpu__mem_if__i_mdu_op := false
  cpu__mem_if__i_bufreg2_q := false
  cpu__mem_if__o_rd := false
  cpu__mem_if__o_wb_sel := BitVec.ofNat 4 0
  cpu__mem_if__dat_valid := false
  cpu__gen_csr__csr__i_clk := false
  cpu__gen_csr__csr__i_rst := false
  cpu__gen_csr__csr__i_trig_irq := false
  cpu__gen_csr__csr__i_en := false
  cpu__gen_csr__csr__i_cnt0to3 := false
  cpu__gen_csr__csr__i_cnt3 := false
  cpu__gen_csr__csr__i_cnt7 := false
  cpu__gen_csr__csr__i_cnt11 := false
  cpu__gen_csr__csr__i_cnt12 := false
  cpu__gen_csr__csr__i_cnt_done := false
  cpu__gen_csr__csr__i_mem_op := false
  cpu__gen_csr__csr__i_mtip := false
  cpu__gen_csr__csr__i_trap := false
  cpu__gen_csr__csr__i_e_op := false
  cpu__gen_csr__csr__i_ebreak := false
  cpu__gen_csr__csr__i_mem_cmd := false
  cpu__gen_csr__csr__i_mstatus_en := false
  cpu__gen_csr__csr__i_mie_en := false
  cpu__gen_csr__csr__i_mcause_en := false
  cpu__gen_csr__csr__i_csr_source := BitVec.ofNat 2 0
  cpu__gen_csr__csr__i_mret := false
  cpu__gen_csr__csr__i_csr_d_sel := false
  cpu__gen_csr__csr__i_rf_csr_out := false
  cpu__gen_csr__csr__o_csr_in := false
  cpu__gen_csr__csr__i_csr_imm := false
  cpu__gen_csr__csr__i_rs1 := false
  cpu__gen_csr__csr__o_q := false
  cpu__gen_csr__csr__mcause := false
  cpu__gen_csr__csr__csr_in := false
  cpu__gen_csr__csr__csr_out := false
  cpu__gen_csr__csr__d := false
  cpu__gen_csr__csr__mstatus := false
  cpu__gen_csr__csr__timer_irq := false
  o_ibus_adr := BitVec.ofNat 32 0
  o_ibus_cyc := false
  o_dbus_adr := BitVec.ofNat 32 0
  o_dbus_dat := BitVec.ofNat 32 0
  o_dbus_sel := BitVec.ofNat 4 0
  o_dbus_we := false
  o_dbus_cyc := false
  o_ext_rs1 := BitVec.ofNat 32 0
  o_ext_rs2 := BitVec.ofNat 32 0
  o_ext_funct3 := BitVec.ofNat 3 0
  o_mdu_valid := false
  cpu__decode__o_alu_bool_op := BitVec.ofNat 2 0
  cpu__decode__o_alu_cmp_eq := false
  cpu__decode__o_alu_cmp_sig := false
  cpu__decode__o_alu_rd_sel := BitVec.ofNat 3 0
  cpu__decode__o_alu_sub := false
  cpu__decode__o_bne_or_bge := false
  cpu__decode__o_branch_op := false
  cpu__decode__o_bufreg_clr_lsb := false
  cpu__decode__o_bufreg_imm_en := false
  cpu__decode__o_bufreg_rs1_en := false
  cpu__decode__o_bufreg_sh_signed := false
  cpu__decode__o_cond_branch := false
  cpu__decode__o_csr_addr := BitVec.ofNat 2 0
  cpu__decode__o_csr_d_sel := false
  cpu__decode__o_csr_en := false
  cpu__decode__o_csr_imm_en := false
  cpu__decode__o_csr_mcause_en := false
  cpu__decode__o_csr_mie_en := false
  cpu__decode__o_csr_mstatus_en := false
  cpu__decode__o_csr_source := BitVec.ofNat 2 0
  cpu__decode__o_ctrl_jal_or_jalr := false
  cpu__decode__o_ctrl_mret := false
  cpu__decode__o_ctrl_pc_rel := false
  cpu__decode__o_ctrl_utype := false
  cpu__decode__o_dbus_en := false
  cpu__decode__o_e_op := false
  cpu__decode__o_ebreak := false
  cpu__decode__o_ext_funct3 := BitVec.ofNat 3 0
  cpu__decode__o_immdec_ctrl := BitVec.ofNat 4 0
  cpu__decode__o_immdec_en := BitVec.ofNat 4 0
  cpu__decode__o_mdu_op := false
  cpu__decode__o_mem_cmd := false
  cpu__decode__o_mem_half := false
  cpu__decode__o_mem_signed := false
  cpu__decode__o_mem_word := false
  cpu__decode__o_mtval_pc := false
  cpu__decode__o_op_b_source := false
  cpu__decode__o_rd_alu_en := false
  cpu__decode__o_rd_csr_en := false
  cpu__decode__o_rd_mem_en := false
  cpu__decode__o_rd_op := false
  cpu__decode__o_sh_right := false
  cpu__decode__o_shift_op := false
  cpu__decode__o_two_stage_op := false

/-- serv_rf_top 默认输入值 -/
def defaultInputs : serv_rf_topInputs where
  clk := false
  i_rst := true
  i_timer_irq := false
  i_ibus_rdt := BitVec.ofNat 32 0
  i_ibus_ack := false
  i_dbus_rdt := BitVec.ofNat 32 0
  i_dbus_ack := false
  i_ext_rd := BitVec.ofNat 32 0
  i_ext_ready := false
  __rtl_nondet_0001 := false
  __rtl_nondet_0000 := false

/-- 组合逻辑：assign_rf_ram_if__i_clk -/
def assign_rf_ram_if__i_clk (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram_if__i_clk := i.clk
  { s with
    rf_ram_if__i_clk := rf_ram_if__i_clk
  }

/-- 组合逻辑：assign_rf_ram_if__i_rst -/
def assign_rf_ram_if__i_rst (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram_if__i_rst := i.i_rst
  { s with
    rf_ram_if__i_rst := rf_ram_if__i_rst
  }

/-- 组合逻辑：assign_rf_ram_if__i_wreq -/
def assign_rf_ram_if__i_wreq (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram_if__i_wreq := s.rf_wreq
  { s with
    rf_ram_if__i_wreq := rf_ram_if__i_wreq
  }

/-- 组合逻辑：assign_rf_ram_if__i_rreq -/
def assign_rf_ram_if__i_rreq (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram_if__i_rreq := s.rf_rreq
  { s with
    rf_ram_if__i_rreq := rf_ram_if__i_rreq
  }

/-- 组合逻辑：assign_rf_ready -/
def assign_rf_ready (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ready := s.rf_ram_if__o_ready
  { s with
    rf_ready := rf_ready
  }

/-- 组合逻辑：assign_rf_ram_if__i_wreg0 -/
def assign_rf_ram_if__i_wreg0 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram_if__i_wreg0 := s.wreg0
  { s with
    rf_ram_if__i_wreg0 := rf_ram_if__i_wreg0
  }

/-- 组合逻辑：assign_rf_ram_if__i_wreg1 -/
def assign_rf_ram_if__i_wreg1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram_if__i_wreg1 := s.wreg1
  { s with
    rf_ram_if__i_wreg1 := rf_ram_if__i_wreg1
  }

/-- 组合逻辑：assign_rf_ram_if__i_wen0 -/
def assign_rf_ram_if__i_wen0 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram_if__i_wen0 := s.wen0
  { s with
    rf_ram_if__i_wen0 := rf_ram_if__i_wen0
  }

/-- 组合逻辑：assign_rf_ram_if__i_wen1 -/
def assign_rf_ram_if__i_wen1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram_if__i_wen1 := s.wen1
  { s with
    rf_ram_if__i_wen1 := rf_ram_if__i_wen1
  }

/-- 组合逻辑：assign_rf_ram_if__i_wdata0 -/
def assign_rf_ram_if__i_wdata0 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram_if__i_wdata0 := s.wdata0
  { s with
    rf_ram_if__i_wdata0 := rf_ram_if__i_wdata0
  }

/-- 组合逻辑：assign_rf_ram_if__i_wdata1 -/
def assign_rf_ram_if__i_wdata1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram_if__i_wdata1 := s.wdata1
  { s with
    rf_ram_if__i_wdata1 := rf_ram_if__i_wdata1
  }

/-- 组合逻辑：assign_rf_ram_if__i_rreg0 -/
def assign_rf_ram_if__i_rreg0 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram_if__i_rreg0 := s.rreg0
  { s with
    rf_ram_if__i_rreg0 := rf_ram_if__i_rreg0
  }

/-- 组合逻辑：assign_rf_ram_if__i_rreg1 -/
def assign_rf_ram_if__i_rreg1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram_if__i_rreg1 := s.rreg1
  { s with
    rf_ram_if__i_rreg1 := rf_ram_if__i_rreg1
  }

/-- 组合逻辑：assign_rdata0 -/
def assign_rdata0 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rdata0 := s.rf_ram_if__o_rdata0
  { s with
    rdata0 := rdata0
  }

/-- 组合逻辑：assign_rdata1 -/
def assign_rdata1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rdata1 := s.rf_ram_if__o_rdata1
  { s with
    rdata1 := rdata1
  }

/-- 组合逻辑：assign_waddr -/
def assign_waddr (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let waddr := s.rf_ram_if__o_waddr
  { s with
    waddr := waddr
  }

/-- 组合逻辑：assign_wdata -/
def assign_wdata (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let wdata := s.rf_ram_if__o_wdata
  { s with
    wdata := wdata
  }

/-- 组合逻辑：assign_wen -/
def assign_wen (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let wen := s.rf_ram_if__o_wen
  { s with
    wen := wen
  }

/-- 组合逻辑：assign_raddr -/
def assign_raddr (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let raddr := s.rf_ram_if__o_raddr
  { s with
    raddr := raddr
  }

/-- 组合逻辑：assign_ren -/
def assign_ren (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let ren := s.rf_ram_if__o_ren
  { s with
    ren := ren
  }

/-- 组合逻辑：assign_rf_ram_if__i_rdata -/
def assign_rf_ram_if__i_rdata (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram_if__i_rdata := s.rdata
  { s with
    rf_ram_if__i_rdata := rf_ram_if__i_rdata
  }

/-- 组合逻辑：assign_rf_ram_if__o_ready -/
def assign_rf_ram_if__o_ready (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram_if__o_ready := (s.rf_ram_if__rgnt || s.rf_ram_if__i_wreq)
  { s with
    rf_ram_if__o_ready := rf_ram_if__o_ready
  }

/-- 组合逻辑：assign_rf_ram_if__wtrig0 -/
def assign_rf_ram_if__wtrig0 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram_if__wtrig0 := s.rf_ram_if__rtrig1
  { s with
    rf_ram_if__wtrig0 := rf_ram_if__wtrig0
  }

/-- 组合逻辑：assign_rf_ram_if__wtrig1 -/
def assign_rf_ram_if__wtrig1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram_if__wtrig1 := BitVec.getLsbD (s.rf_ram_if__wcnt) 0
  { s with
    rf_ram_if__wtrig1 := rf_ram_if__wtrig1
  }

/-- 组合逻辑：assign_rf_ram_if__o_wdata -/
def assign_rf_ram_if__o_wdata (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram_if__o_wdata := (if s.rf_ram_if__wtrig1 then BitVec.extractLsb 1 0 (s.rf_ram_if__wdata1_r) else s.rf_ram_if__wdata0_r)
  { s with
    rf_ram_if__o_wdata := rf_ram_if__o_wdata
  }

/-- 组合逻辑：assign_rf_ram_if__wreg -/
def assign_rf_ram_if__wreg (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram_if__wreg := (if s.rf_ram_if__wtrig1 then s.rf_ram_if__i_wreg1 else s.rf_ram_if__i_wreg0)
  { s with
    rf_ram_if__wreg := rf_ram_if__wreg
  }

/-- 组合逻辑：assign_rf_ram_if__o_waddr -/
def assign_rf_ram_if__o_waddr (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram_if__o_waddr := BitVec.append (n := 6) (m := 4) (s.rf_ram_if__wreg) (BitVec.extractLsb 4 1 (s.rf_ram_if__wcnt))
  { s with
    rf_ram_if__o_waddr := rf_ram_if__o_waddr
  }

/-- 组合逻辑：assign_rf_ram_if__o_wen -/
def assign_rf_ram_if__o_wen (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram_if__o_wen := ((s.rf_ram_if__wtrig0 && s.rf_ram_if__wen0_r) || (s.rf_ram_if__wtrig1 && s.rf_ram_if__wen1_r))
  { s with
    rf_ram_if__o_wen := rf_ram_if__o_wen
  }

/-- 组合逻辑：assign_rf_ram_if__wcnt -/
def assign_rf_ram_if__wcnt (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram_if__wcnt := (s.rf_ram_if__rcnt - BitVec.ofNat 5 4)
  { s with
    rf_ram_if__wcnt := rf_ram_if__wcnt
  }

/-- 组合逻辑：assign_rf_ram_if__rreg -/
def assign_rf_ram_if__rreg (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram_if__rreg := (if s.rf_ram_if__rtrig0 then s.rf_ram_if__i_rreg1 else s.rf_ram_if__i_rreg0)
  { s with
    rf_ram_if__rreg := rf_ram_if__rreg
  }

/-- 组合逻辑：assign_rf_ram_if__o_raddr -/
def assign_rf_ram_if__o_raddr (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram_if__o_raddr := BitVec.append (n := 6) (m := 4) (s.rf_ram_if__rreg) (BitVec.extractLsb 4 1 (s.rf_ram_if__rcnt))
  { s with
    rf_ram_if__o_raddr := rf_ram_if__o_raddr
  }

/-- 组合逻辑：assign_rf_ram_if__o_rdata0 -/
def assign_rf_ram_if__o_rdata0 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram_if__o_rdata0 := bitVecToBool (BitVec.extractLsb 0 0 (s.rf_ram_if__rdata0))
  { s with
    rf_ram_if__o_rdata0 := rf_ram_if__o_rdata0
  }

/-- 组合逻辑：assign_rf_ram_if__o_rdata1 -/
def assign_rf_ram_if__o_rdata1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram_if__o_rdata1 := (if s.rf_ram_if__rtrig1 then bitVecToBool (BitVec.extractLsb 0 0 (s.rf_ram_if__i_rdata)) else bitVecToBool (BitVec.extractLsb 0 0 (boolToBitVec (s.rf_ram_if__rdata1))))
  { s with
    rf_ram_if__o_rdata1 := rf_ram_if__o_rdata1
  }

/-- 组合逻辑：assign_rf_ram_if__rtrig0 -/
def assign_rf_ram_if__rtrig0 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram_if__rtrig0 := decide ((BitVec.extractLsb 0 0 (s.rf_ram_if__rcnt)).toNat = (BitVec.ofNat 32 1).toNat)
  { s with
    rf_ram_if__rtrig0 := rf_ram_if__rtrig0
  }

/-- 组合逻辑：assign_rf_ram_if__o_ren -/
def assign_rf_ram_if__o_ren (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram_if__o_ren := s.rf_ram_if__rgate
  { s with
    rf_ram_if__o_ren := rf_ram_if__o_ren
  }

/-- 组合逻辑：assign_rf_ram__i_clk -/
def assign_rf_ram__i_clk (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram__i_clk := i.clk
  { s with
    rf_ram__i_clk := rf_ram__i_clk
  }

/-- 组合逻辑：assign_rf_ram__i_waddr -/
def assign_rf_ram__i_waddr (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram__i_waddr := s.waddr
  { s with
    rf_ram__i_waddr := rf_ram__i_waddr
  }

/-- 组合逻辑：assign_rf_ram__i_wdata -/
def assign_rf_ram__i_wdata (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram__i_wdata := s.wdata
  { s with
    rf_ram__i_wdata := rf_ram__i_wdata
  }

/-- 组合逻辑：assign_rf_ram__i_wen -/
def assign_rf_ram__i_wen (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram__i_wen := s.wen
  { s with
    rf_ram__i_wen := rf_ram__i_wen
  }

/-- 组合逻辑：assign_rf_ram__i_raddr -/
def assign_rf_ram__i_raddr (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram__i_raddr := s.raddr
  { s with
    rf_ram__i_raddr := rf_ram__i_raddr
  }

/-- 组合逻辑：assign_rf_ram__i_ren -/
def assign_rf_ram__i_ren (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram__i_ren := s.ren
  { s with
    rf_ram__i_ren := rf_ram__i_ren
  }

/-- 组合逻辑：assign_rdata -/
def assign_rdata (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rdata := s.rf_ram__o_rdata
  { s with
    rdata := rdata
  }

/-- 组合逻辑：assign_rf_ram__o_rdata -/
def assign_rf_ram__o_rdata (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_ram__o_rdata := (s.rf_ram__rdata &&& ~~~(BitVec.append (n := 1) (m := 1) (boolToBitVec (s.rf_ram__regzero)) (boolToBitVec (s.rf_ram__regzero))))
  { s with
    rf_ram__o_rdata := rf_ram__o_rdata
  }

/-- 组合逻辑：assign_cpu__clk -/
def assign_cpu__clk (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__clk := i.clk
  { s with
    cpu__clk := cpu__clk
  }

/-- 组合逻辑：assign_cpu__i_rst -/
def assign_cpu__i_rst (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__i_rst := i.i_rst
  { s with
    cpu__i_rst := cpu__i_rst
  }

/-- 组合逻辑：assign_cpu__i_timer_irq -/
def assign_cpu__i_timer_irq (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__i_timer_irq := i.i_timer_irq
  { s with
    cpu__i_timer_irq := cpu__i_timer_irq
  }

/-- 组合逻辑：assign_rf_rreq -/
def assign_rf_rreq (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_rreq := s.cpu__o_rf_rreq
  { s with
    rf_rreq := rf_rreq
  }

/-- 组合逻辑：assign_rf_wreq -/
def assign_rf_wreq (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rf_wreq := s.cpu__o_rf_wreq
  { s with
    rf_wreq := rf_wreq
  }

/-- 组合逻辑：assign_cpu__i_rf_ready -/
def assign_cpu__i_rf_ready (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__i_rf_ready := s.rf_ready
  { s with
    cpu__i_rf_ready := cpu__i_rf_ready
  }

/-- 组合逻辑：assign_wreg0 -/
def assign_wreg0 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let wreg0 := s.cpu__o_wreg0
  { s with
    wreg0 := wreg0
  }

/-- 组合逻辑：assign_wreg1 -/
def assign_wreg1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let wreg1 := s.cpu__o_wreg1
  { s with
    wreg1 := wreg1
  }

/-- 组合逻辑：assign_wen0 -/
def assign_wen0 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let wen0 := s.cpu__o_wen0
  { s with
    wen0 := wen0
  }

/-- 组合逻辑：assign_wen1 -/
def assign_wen1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let wen1 := s.cpu__o_wen1
  { s with
    wen1 := wen1
  }

/-- 组合逻辑：assign_wdata0 -/
def assign_wdata0 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let wdata0 := s.cpu__o_wdata0
  { s with
    wdata0 := wdata0
  }

/-- 组合逻辑：assign_wdata1 -/
def assign_wdata1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let wdata1 := s.cpu__o_wdata1
  { s with
    wdata1 := wdata1
  }

/-- 组合逻辑：assign_rreg0 -/
def assign_rreg0 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rreg0 := s.cpu__o_rreg0
  { s with
    rreg0 := rreg0
  }

/-- 组合逻辑：assign_rreg1 -/
def assign_rreg1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let rreg1 := s.cpu__o_rreg1
  { s with
    rreg1 := rreg1
  }

/-- 组合逻辑：assign_cpu__i_rdata0 -/
def assign_cpu__i_rdata0 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__i_rdata0 := s.rdata0
  { s with
    cpu__i_rdata0 := cpu__i_rdata0
  }

/-- 组合逻辑：assign_cpu__i_rdata1 -/
def assign_cpu__i_rdata1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__i_rdata1 := s.rdata1
  { s with
    cpu__i_rdata1 := cpu__i_rdata1
  }

/-- 组合逻辑：assign_o_ibus_adr -/
def assign_o_ibus_adr (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let o_ibus_adr := s.cpu__o_ibus_adr
  { s with
    o_ibus_adr := o_ibus_adr
  }

/-- 组合逻辑：assign_o_ibus_cyc -/
def assign_o_ibus_cyc (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let o_ibus_cyc := s.cpu__o_ibus_cyc
  { s with
    o_ibus_cyc := o_ibus_cyc
  }

/-- 组合逻辑：assign_cpu__i_ibus_rdt -/
def assign_cpu__i_ibus_rdt (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__i_ibus_rdt := i.i_ibus_rdt
  { s with
    cpu__i_ibus_rdt := cpu__i_ibus_rdt
  }

/-- 组合逻辑：assign_cpu__i_ibus_ack -/
def assign_cpu__i_ibus_ack (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__i_ibus_ack := i.i_ibus_ack
  { s with
    cpu__i_ibus_ack := cpu__i_ibus_ack
  }

/-- 组合逻辑：assign_o_dbus_adr -/
def assign_o_dbus_adr (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let o_dbus_adr := s.cpu__o_dbus_adr
  { s with
    o_dbus_adr := o_dbus_adr
  }

/-- 组合逻辑：assign_o_dbus_dat -/
def assign_o_dbus_dat (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let o_dbus_dat := s.cpu__o_dbus_dat
  { s with
    o_dbus_dat := o_dbus_dat
  }

/-- 组合逻辑：assign_o_dbus_sel -/
def assign_o_dbus_sel (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let o_dbus_sel := s.cpu__o_dbus_sel
  { s with
    o_dbus_sel := o_dbus_sel
  }

/-- 组合逻辑：assign_o_dbus_we -/
def assign_o_dbus_we (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let o_dbus_we := s.cpu__o_dbus_we
  { s with
    o_dbus_we := o_dbus_we
  }

/-- 组合逻辑：assign_o_dbus_cyc -/
def assign_o_dbus_cyc (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let o_dbus_cyc := s.cpu__o_dbus_cyc
  { s with
    o_dbus_cyc := o_dbus_cyc
  }

/-- 组合逻辑：assign_cpu__i_dbus_rdt -/
def assign_cpu__i_dbus_rdt (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__i_dbus_rdt := i.i_dbus_rdt
  { s with
    cpu__i_dbus_rdt := cpu__i_dbus_rdt
  }

/-- 组合逻辑：assign_cpu__i_dbus_ack -/
def assign_cpu__i_dbus_ack (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__i_dbus_ack := i.i_dbus_ack
  { s with
    cpu__i_dbus_ack := cpu__i_dbus_ack
  }

/-- 组合逻辑：assign_o_ext_funct3 -/
def assign_o_ext_funct3 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let o_ext_funct3 := s.cpu__o_ext_funct3
  { s with
    o_ext_funct3 := o_ext_funct3
  }

/-- 组合逻辑：assign_cpu__i_ext_ready -/
def assign_cpu__i_ext_ready (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__i_ext_ready := i.i_ext_ready
  { s with
    cpu__i_ext_ready := cpu__i_ext_ready
  }

/-- 组合逻辑：assign_cpu__i_ext_rd -/
def assign_cpu__i_ext_rd (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__i_ext_rd := i.i_ext_rd
  { s with
    cpu__i_ext_rd := cpu__i_ext_rd
  }

/-- 组合逻辑：assign_o_ext_rs1 -/
def assign_o_ext_rs1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let o_ext_rs1 := s.cpu__o_ext_rs1
  { s with
    o_ext_rs1 := o_ext_rs1
  }

/-- 组合逻辑：assign_o_ext_rs2 -/
def assign_o_ext_rs2 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let o_ext_rs2 := s.cpu__o_ext_rs2
  { s with
    o_ext_rs2 := o_ext_rs2
  }

/-- 组合逻辑：assign_o_mdu_valid -/
def assign_o_mdu_valid (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let o_mdu_valid := s.cpu__o_mdu_valid
  { s with
    o_mdu_valid := o_mdu_valid
  }

/-- 组合逻辑：assign_cpu__o_ibus_adr -/
def assign_cpu__o_ibus_adr (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__o_ibus_adr := s.cpu__wb_ibus_adr
  { s with
    cpu__o_ibus_adr := cpu__o_ibus_adr
  }

/-- 组合逻辑：assign_cpu__o_ibus_cyc -/
def assign_cpu__o_ibus_cyc (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__o_ibus_cyc := s.cpu__wb_ibus_cyc
  { s with
    cpu__o_ibus_cyc := cpu__o_ibus_cyc
  }

/-- 组合逻辑：assign_cpu__wb_ibus_rdt -/
def assign_cpu__wb_ibus_rdt (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__wb_ibus_rdt := s.cpu__i_ibus_rdt
  { s with
    cpu__wb_ibus_rdt := cpu__wb_ibus_rdt
  }

/-- 组合逻辑：assign_cpu__wb_ibus_ack -/
def assign_cpu__wb_ibus_ack (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__wb_ibus_ack := s.cpu__i_ibus_ack
  { s with
    cpu__wb_ibus_ack := cpu__wb_ibus_ack
  }

/-- 组合逻辑：assign_cpu__i_wb_rdt -/
def assign_cpu__i_wb_rdt (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__i_wb_rdt := s.cpu__wb_ibus_rdt
  { s with
    cpu__i_wb_rdt := cpu__i_wb_rdt
  }

/-- 组合逻辑：assign_cpu__iscomp -/
def assign_cpu__iscomp (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__iscomp := false
  { s with
    cpu__iscomp := cpu__iscomp
  }

/-- 组合逻辑：assign_cpu__state__i_clk -/
def assign_cpu__state__i_clk (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__i_clk := s.cpu__clk
  { s with
    cpu__state__i_clk := cpu__state__i_clk
  }

/-- 组合逻辑：assign_cpu__state__i_rst -/
def assign_cpu__state__i_rst (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__i_rst := s.cpu__i_rst
  { s with
    cpu__state__i_rst := cpu__state__i_rst
  }

/-- 组合逻辑：assign_cpu__state__i_new_irq -/
def assign_cpu__state__i_new_irq (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__i_new_irq := s.cpu__new_irq
  { s with
    cpu__state__i_new_irq := cpu__state__i_new_irq
  }

/-- 组合逻辑：assign_cpu__state__i_alu_cmp -/
def assign_cpu__state__i_alu_cmp (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__i_alu_cmp := s.cpu__alu_cmp
  { s with
    cpu__state__i_alu_cmp := cpu__state__i_alu_cmp
  }

/-- 组合逻辑：assign_cpu__init -/
def assign_cpu__init (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__init := s.cpu__state__o_init
  { s with
    cpu__init := cpu__init
  }

/-- 组合逻辑：assign_cpu__cnt_en -/
def assign_cpu__cnt_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__cnt_en := s.cpu__state__o_cnt_en
  { s with
    cpu__cnt_en := cpu__cnt_en
  }

/-- 组合逻辑：assign_cpu__cnt0to3 -/
def assign_cpu__cnt0to3 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__cnt0to3 := s.cpu__state__o_cnt0to3
  { s with
    cpu__cnt0to3 := cpu__cnt0to3
  }

/-- 组合逻辑：assign_cpu__cnt12to31 -/
def assign_cpu__cnt12to31 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__cnt12to31 := s.cpu__state__o_cnt12to31
  { s with
    cpu__cnt12to31 := cpu__cnt12to31
  }

/-- 组合逻辑：assign_cpu__cnt0 -/
def assign_cpu__cnt0 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__cnt0 := s.cpu__state__o_cnt0
  { s with
    cpu__cnt0 := cpu__cnt0
  }

/-- 组合逻辑：assign_cpu__cnt1 -/
def assign_cpu__cnt1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__cnt1 := s.cpu__state__o_cnt1
  { s with
    cpu__cnt1 := cpu__cnt1
  }

/-- 组合逻辑：assign_cpu__cnt2 -/
def assign_cpu__cnt2 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__cnt2 := s.cpu__state__o_cnt2
  { s with
    cpu__cnt2 := cpu__cnt2
  }

/-- 组合逻辑：assign_cpu__cnt3 -/
def assign_cpu__cnt3 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__cnt3 := s.cpu__state__o_cnt3
  { s with
    cpu__cnt3 := cpu__cnt3
  }

/-- 组合逻辑：assign_cpu__cnt7 -/
def assign_cpu__cnt7 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__cnt7 := s.cpu__state__o_cnt7
  { s with
    cpu__cnt7 := cpu__cnt7
  }

/-- 组合逻辑：assign_cpu__cnt11 -/
def assign_cpu__cnt11 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__cnt11 := s.cpu__state__o_cnt11
  { s with
    cpu__cnt11 := cpu__cnt11
  }

/-- 组合逻辑：assign_cpu__cnt12 -/
def assign_cpu__cnt12 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__cnt12 := s.cpu__state__o_cnt12
  { s with
    cpu__cnt12 := cpu__cnt12
  }

/-- 组合逻辑：assign_cpu__cnt_done -/
def assign_cpu__cnt_done (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__cnt_done := s.cpu__state__o_cnt_done
  { s with
    cpu__cnt_done := cpu__cnt_done
  }

/-- 组合逻辑：assign_cpu__bufreg_en -/
def assign_cpu__bufreg_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg_en := s.cpu__state__o_bufreg_en
  { s with
    cpu__bufreg_en := cpu__bufreg_en
  }

/-- 组合逻辑：assign_cpu__ctrl_pc_en -/
def assign_cpu__ctrl_pc_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ctrl_pc_en := s.cpu__state__o_ctrl_pc_en
  { s with
    cpu__ctrl_pc_en := cpu__ctrl_pc_en
  }

/-- 组合逻辑：assign_cpu__jump -/
def assign_cpu__jump (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__jump := s.cpu__state__o_ctrl_jump
  { s with
    cpu__jump := cpu__jump
  }

/-- 组合逻辑：assign_cpu__trap -/
def assign_cpu__trap (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__trap := s.cpu__state__o_ctrl_trap
  { s with
    cpu__trap := cpu__trap
  }

/-- 组合逻辑：assign_cpu__state__i_ctrl_misalign -/
def assign_cpu__state__i_ctrl_misalign (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__i_ctrl_misalign := BitVec.getLsbD (s.cpu__lsb) 1
  { s with
    cpu__state__i_ctrl_misalign := cpu__state__i_ctrl_misalign
  }

/-- 组合逻辑：assign_cpu__state__i_sh_done -/
def assign_cpu__state__i_sh_done (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__i_sh_done := s.cpu__sh_done
  { s with
    cpu__state__i_sh_done := cpu__state__i_sh_done
  }

/-- 组合逻辑：assign_cpu__mem_bytecnt -/
def assign_cpu__mem_bytecnt (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__mem_bytecnt := s.cpu__state__o_mem_bytecnt
  { s with
    cpu__mem_bytecnt := cpu__mem_bytecnt
  }

/-- 组合逻辑：assign_cpu__state__i_mem_misalign -/
def assign_cpu__state__i_mem_misalign (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__i_mem_misalign := s.cpu__mem_misalign
  { s with
    cpu__state__i_mem_misalign := cpu__state__i_mem_misalign
  }

/-- 组合逻辑：assign_cpu__state__i_bne_or_bge -/
def assign_cpu__state__i_bne_or_bge (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__i_bne_or_bge := s.cpu__bne_or_bge
  { s with
    cpu__state__i_bne_or_bge := cpu__state__i_bne_or_bge
  }

/-- 组合逻辑：assign_cpu__state__i_cond_branch -/
def assign_cpu__state__i_cond_branch (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__i_cond_branch := s.cpu__cond_branch
  { s with
    cpu__state__i_cond_branch := cpu__state__i_cond_branch
  }

/-- 组合逻辑：assign_cpu__state__i_dbus_en -/
def assign_cpu__state__i_dbus_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__i_dbus_en := s.cpu__dbus_en
  { s with
    cpu__state__i_dbus_en := cpu__state__i_dbus_en
  }

/-- 组合逻辑：assign_cpu__state__i_two_stage_op -/
def assign_cpu__state__i_two_stage_op (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__i_two_stage_op := s.cpu__two_stage_op
  { s with
    cpu__state__i_two_stage_op := cpu__state__i_two_stage_op
  }

/-- 组合逻辑：assign_cpu__state__i_branch_op -/
def assign_cpu__state__i_branch_op (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__i_branch_op := s.cpu__branch_op
  { s with
    cpu__state__i_branch_op := cpu__state__i_branch_op
  }

/-- 组合逻辑：assign_cpu__state__i_shift_op -/
def assign_cpu__state__i_shift_op (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__i_shift_op := s.cpu__shift_op
  { s with
    cpu__state__i_shift_op := cpu__state__i_shift_op
  }

/-- 组合逻辑：assign_cpu__state__i_sh_right -/
def assign_cpu__state__i_sh_right (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__i_sh_right := s.cpu__sh_right
  { s with
    cpu__state__i_sh_right := cpu__state__i_sh_right
  }

/-- 组合逻辑：assign_cpu__state__i_alu_rd_sel1 -/
def assign_cpu__state__i_alu_rd_sel1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__i_alu_rd_sel1 := BitVec.getLsbD (s.cpu__alu_rd_sel) 1
  { s with
    cpu__state__i_alu_rd_sel1 := cpu__state__i_alu_rd_sel1
  }

/-- 组合逻辑：assign_cpu__state__i_rd_alu_en -/
def assign_cpu__state__i_rd_alu_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__i_rd_alu_en := s.cpu__rd_alu_en
  { s with
    cpu__state__i_rd_alu_en := cpu__state__i_rd_alu_en
  }

/-- 组合逻辑：assign_cpu__state__i_e_op -/
def assign_cpu__state__i_e_op (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__i_e_op := s.cpu__e_op
  { s with
    cpu__state__i_e_op := cpu__state__i_e_op
  }

/-- 组合逻辑：assign_cpu__state__i_rd_op -/
def assign_cpu__state__i_rd_op (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__i_rd_op := s.cpu__rd_op
  { s with
    cpu__state__i_rd_op := cpu__state__i_rd_op
  }

/-- 组合逻辑：assign_cpu__state__i_mdu_op -/
def assign_cpu__state__i_mdu_op (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__i_mdu_op := s.cpu__mdu_op
  { s with
    cpu__state__i_mdu_op := cpu__state__i_mdu_op
  }

/-- 组合逻辑：assign_cpu__o_mdu_valid -/
def assign_cpu__o_mdu_valid (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__o_mdu_valid := s.cpu__state__o_mdu_valid
  { s with
    cpu__o_mdu_valid := cpu__o_mdu_valid
  }

/-- 组合逻辑：assign_cpu__state__i_mdu_ready -/
def assign_cpu__state__i_mdu_ready (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__i_mdu_ready := s.cpu__i_ext_ready
  { s with
    cpu__state__i_mdu_ready := cpu__state__i_mdu_ready
  }

/-- 组合逻辑：assign_cpu__o_dbus_cyc -/
def assign_cpu__o_dbus_cyc (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__o_dbus_cyc := s.cpu__state__o_dbus_cyc
  { s with
    cpu__o_dbus_cyc := cpu__o_dbus_cyc
  }

/-- 组合逻辑：assign_cpu__state__i_dbus_ack -/
def assign_cpu__state__i_dbus_ack (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__i_dbus_ack := s.cpu__i_dbus_ack
  { s with
    cpu__state__i_dbus_ack := cpu__state__i_dbus_ack
  }

/-- 组合逻辑：assign_cpu__wb_ibus_cyc -/
def assign_cpu__wb_ibus_cyc (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__wb_ibus_cyc := s.cpu__state__o_ibus_cyc
  { s with
    cpu__wb_ibus_cyc := cpu__wb_ibus_cyc
  }

/-- 组合逻辑：assign_cpu__state__i_ibus_ack -/
def assign_cpu__state__i_ibus_ack (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__i_ibus_ack := s.cpu__wb_ibus_ack
  { s with
    cpu__state__i_ibus_ack := cpu__state__i_ibus_ack
  }

/-- 组合逻辑：assign_cpu__o_rf_rreq -/
def assign_cpu__o_rf_rreq (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__o_rf_rreq := s.cpu__state__o_rf_rreq
  { s with
    cpu__o_rf_rreq := cpu__o_rf_rreq
  }

/-- 组合逻辑：assign_cpu__o_rf_wreq -/
def assign_cpu__o_rf_wreq (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__o_rf_wreq := s.cpu__state__o_rf_wreq
  { s with
    cpu__o_rf_wreq := cpu__o_rf_wreq
  }

/-- 组合逻辑：assign_cpu__state__i_rf_ready -/
def assign_cpu__state__i_rf_ready (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__i_rf_ready := s.cpu__i_rf_ready
  { s with
    cpu__state__i_rf_ready := cpu__state__i_rf_ready
  }

/-- 组合逻辑：assign_cpu__rd_en -/
def assign_cpu__rd_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rd_en := s.cpu__state__o_rf_rd_en
  { s with
    cpu__rd_en := cpu__rd_en
  }

/-- 组合逻辑：assign_cpu__state__o_ctrl_pc_en -/
def assign_cpu__state__o_ctrl_pc_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__o_ctrl_pc_en := (s.cpu__state__o_cnt_en && !(s.cpu__state__o_init))
  { s with
    cpu__state__o_ctrl_pc_en := cpu__state__o_ctrl_pc_en
  }

/-- 组合逻辑：assign_cpu__state__o_mem_bytecnt -/
def assign_cpu__state__o_mem_bytecnt (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__o_mem_bytecnt := BitVec.extractLsb 2 1 (s.cpu__state__o_cnt)
  { s with
    cpu__state__o_mem_bytecnt := cpu__state__o_mem_bytecnt
  }

/-- 组合逻辑：assign_cpu__state__o_cnt0to3 -/
def assign_cpu__state__o_cnt0to3 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__o_cnt0to3 := decide ((BitVec.extractLsb 2 0 (s.cpu__state__o_cnt)).toNat = (BitVec.ofNat 3 0).toNat)
  { s with
    cpu__state__o_cnt0to3 := cpu__state__o_cnt0to3
  }

/-- 组合逻辑：assign_cpu__state__o_cnt12to31 -/
def assign_cpu__state__o_cnt12to31 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__o_cnt12to31 := (BitVec.getLsbD (s.cpu__state__o_cnt) 2 || decide ((BitVec.extractLsb 1 0 (s.cpu__state__o_cnt)).toNat = (BitVec.ofNat 2 3).toNat))
  { s with
    cpu__state__o_cnt12to31 := cpu__state__o_cnt12to31
  }

/-- 组合逻辑：assign_cpu__state__o_cnt0 -/
def assign_cpu__state__o_cnt0 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__o_cnt0 := (decide ((BitVec.extractLsb 2 0 (s.cpu__state__o_cnt)).toNat = (BitVec.ofNat 3 0).toNat) && BitVec.getLsbD (s.cpu__state__cnt_r) 0)
  { s with
    cpu__state__o_cnt0 := cpu__state__o_cnt0
  }

/-- 组合逻辑：assign_cpu__state__o_cnt1 -/
def assign_cpu__state__o_cnt1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__o_cnt1 := (decide ((BitVec.extractLsb 2 0 (s.cpu__state__o_cnt)).toNat = (BitVec.ofNat 3 0).toNat) && BitVec.getLsbD (s.cpu__state__cnt_r) 1)
  { s with
    cpu__state__o_cnt1 := cpu__state__o_cnt1
  }

/-- 组合逻辑：assign_cpu__state__o_cnt2 -/
def assign_cpu__state__o_cnt2 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__o_cnt2 := (decide ((BitVec.extractLsb 2 0 (s.cpu__state__o_cnt)).toNat = (BitVec.ofNat 3 0).toNat) && BitVec.getLsbD (s.cpu__state__cnt_r) 2)
  { s with
    cpu__state__o_cnt2 := cpu__state__o_cnt2
  }

/-- 组合逻辑：assign_cpu__state__o_cnt3 -/
def assign_cpu__state__o_cnt3 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__o_cnt3 := (decide ((BitVec.extractLsb 2 0 (s.cpu__state__o_cnt)).toNat = (BitVec.ofNat 3 0).toNat) && BitVec.getLsbD (s.cpu__state__cnt_r) 3)
  { s with
    cpu__state__o_cnt3 := cpu__state__o_cnt3
  }

/-- 组合逻辑：assign_cpu__state__o_cnt7 -/
def assign_cpu__state__o_cnt7 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__o_cnt7 := (decide ((BitVec.extractLsb 2 0 (s.cpu__state__o_cnt)).toNat = (BitVec.ofNat 3 1).toNat) && BitVec.getLsbD (s.cpu__state__cnt_r) 3)
  { s with
    cpu__state__o_cnt7 := cpu__state__o_cnt7
  }

/-- 组合逻辑：assign_cpu__state__o_cnt11 -/
def assign_cpu__state__o_cnt11 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__o_cnt11 := (decide ((BitVec.extractLsb 2 0 (s.cpu__state__o_cnt)).toNat = (BitVec.ofNat 3 2).toNat) && BitVec.getLsbD (s.cpu__state__cnt_r) 3)
  { s with
    cpu__state__o_cnt11 := cpu__state__o_cnt11
  }

/-- 组合逻辑：assign_cpu__state__o_cnt12 -/
def assign_cpu__state__o_cnt12 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__o_cnt12 := (decide ((BitVec.extractLsb 2 0 (s.cpu__state__o_cnt)).toNat = (BitVec.ofNat 3 3).toNat) && BitVec.getLsbD (s.cpu__state__cnt_r) 0)
  { s with
    cpu__state__o_cnt12 := cpu__state__o_cnt12
  }

/-- 组合逻辑：assign_cpu__state__take_branch -/
def assign_cpu__state__take_branch (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__take_branch := (s.cpu__state__i_branch_op && (!(s.cpu__state__i_cond_branch) || Bool.xor (s.cpu__state__i_alu_cmp) (s.cpu__state__i_bne_or_bge)))
  { s with
    cpu__state__take_branch := cpu__state__take_branch
  }

/-- 组合逻辑：assign_cpu__state__last_init -/
def assign_cpu__state__last_init (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__last_init := (s.cpu__state__o_cnt_done && s.cpu__state__o_init)
  { s with
    cpu__state__last_init := cpu__state__last_init
  }

/-- 组合逻辑：assign_cpu__state__o_mdu_valid -/
def assign_cpu__state__o_mdu_valid (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__o_mdu_valid := (((false && !(s.cpu__state__o_cnt_en)) && s.cpu__state__init_done) && s.cpu__state__i_mdu_op)
  { s with
    cpu__state__o_mdu_valid := cpu__state__o_mdu_valid
  }

/-- 组合逻辑：assign_cpu__state__trap_pending -/
def assign_cpu__state__trap_pending (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__trap_pending := (true && (((s.cpu__state__take_branch && s.cpu__state__i_ctrl_misalign) && true) || (s.cpu__state__i_dbus_en && s.cpu__state__i_mem_misalign)))
  { s with
    cpu__state__trap_pending := cpu__state__trap_pending
  }

/-- 组合逻辑：assign_cpu__state__o_rf_wreq -/
def assign_cpu__state__o_rf_wreq (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__o_rf_wreq := (((((s.cpu__state__i_shift_op && (if s.cpu__state__i_sh_right then (s.cpu__state__i_sh_done && (s.cpu__state__last_init || (!(s.cpu__state__o_cnt_en) && s.cpu__state__init_done))) else s.cpu__state__last_init)) || s.cpu__state__i_dbus_ack) || (false && s.cpu__state__i_mdu_ready)) || (s.cpu__state__i_branch_op && (s.cpu__state__last_init && !(s.cpu__state__trap_pending)))) || ((s.cpu__state__i_rd_alu_en && s.cpu__state__i_alu_rd_sel1) && s.cpu__state__last_init))
  { s with
    cpu__state__o_rf_wreq := cpu__state__o_rf_wreq
  }

/-- 组合逻辑：assign_cpu__state__o_dbus_cyc -/
def assign_cpu__state__o_dbus_cyc (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__o_dbus_cyc := (((!(s.cpu__state__o_cnt_en) && s.cpu__state__init_done) && s.cpu__state__i_dbus_en) && !(s.cpu__state__i_mem_misalign))
  { s with
    cpu__state__o_dbus_cyc := cpu__state__o_dbus_cyc
  }

/-- 组合逻辑：assign_cpu__state__o_rf_rreq -/
def assign_cpu__state__o_rf_rreq (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__o_rf_rreq := (s.cpu__state__i_ibus_ack || (s.cpu__state__trap_pending && s.cpu__state__last_init))
  { s with
    cpu__state__o_rf_rreq := cpu__state__o_rf_rreq
  }

/-- 组合逻辑：assign_cpu__state__o_rf_rd_en -/
def assign_cpu__state__o_rf_rd_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__o_rf_rd_en := (s.cpu__state__i_rd_op && !(s.cpu__state__o_init))
  { s with
    cpu__state__o_rf_rd_en := cpu__state__o_rf_rd_en
  }

/-- 组合逻辑：assign_cpu__state__o_bufreg_en -/
def assign_cpu__state__o_bufreg_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__o_bufreg_en := ((s.cpu__state__o_cnt_en && (s.cpu__state__o_init || ((s.cpu__state__o_ctrl_trap || s.cpu__state__i_branch_op) && s.cpu__state__i_two_stage_op))) || ((s.cpu__state__i_shift_op && s.cpu__state__init_done) && (s.cpu__state__i_sh_right || s.cpu__state__i_sh_done)))
  { s with
    cpu__state__o_bufreg_en := cpu__state__o_bufreg_en
  }

/-- 组合逻辑：assign_cpu__state__o_ibus_cyc -/
def assign_cpu__state__o_ibus_cyc (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__o_ibus_cyc := (s.cpu__state__ibus_cyc && !(s.cpu__state__i_rst))
  { s with
    cpu__state__o_ibus_cyc := cpu__state__o_ibus_cyc
  }

/-- 组合逻辑：assign_cpu__state__o_init -/
def assign_cpu__state__o_init (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__o_init := ((s.cpu__state__i_two_stage_op && !(s.cpu__state__i_new_irq)) && !(s.cpu__state__init_done))
  { s with
    cpu__state__o_init := cpu__state__o_init
  }

/-- 组合逻辑：assign_cpu__state__o_cnt_done -/
def assign_cpu__state__o_cnt_done (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__o_cnt_done := (decide ((BitVec.extractLsb 2 0 (s.cpu__state__o_cnt)).toNat = (BitVec.ofNat 3 7).toNat) && BitVec.getLsbD (s.cpu__state__cnt_r) 3)
  { s with
    cpu__state__o_cnt_done := cpu__state__o_cnt_done
  }

/-- 组合逻辑：assign_cpu__state__cnt_r -/
def assign_cpu__state__cnt_r (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__cnt_r := s.cpu__state__gen_cnt_w_eq_1__cnt_lsb
  { s with
    cpu__state__cnt_r := cpu__state__cnt_r
  }

/-- 组合逻辑：assign_cpu__state__o_cnt_en -/
def assign_cpu__state__o_cnt_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__o_cnt_en := bvNonzero (s.cpu__state__gen_cnt_w_eq_1__cnt_lsb)
  { s with
    cpu__state__o_cnt_en := cpu__state__o_cnt_en
  }

/-- 组合逻辑：assign_cpu__state__o_ctrl_trap -/
def assign_cpu__state__o_ctrl_trap (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__o_ctrl_trap := (true && ((s.cpu__state__i_e_op || s.cpu__state__i_new_irq) || s.cpu__state__misalign_trap_sync))
  { s with
    cpu__state__o_ctrl_trap := cpu__state__o_ctrl_trap
  }

/-- 组合逻辑：assign_cpu__state__misalign_trap_sync -/
def assign_cpu__state__misalign_trap_sync (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__state__misalign_trap_sync := s.cpu__state__gen_csr__misalign_trap_sync_r
  { s with
    cpu__state__misalign_trap_sync := cpu__state__misalign_trap_sync
  }

/-- 组合逻辑：assign_cpu__decode__clk -/
def assign_cpu__decode__clk (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__clk := s.cpu__clk
  { s with
    cpu__decode__clk := cpu__decode__clk
  }

/-- 组合逻辑：assign_cpu__decode__i_wb_rdt -/
def assign_cpu__decode__i_wb_rdt (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__i_wb_rdt := BitVec.extractLsb 31 2 (s.cpu__i_wb_rdt)
  { s with
    cpu__decode__i_wb_rdt := cpu__decode__i_wb_rdt
  }

/-- 组合逻辑：assign_cpu__decode__i_wb_en -/
def assign_cpu__decode__i_wb_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__i_wb_en := s.cpu__wb_ibus_ack
  { s with
    cpu__decode__i_wb_en := cpu__decode__i_wb_en
  }

/-- 组合逻辑：assign_cpu__sh_right -/
def assign_cpu__sh_right (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__sh_right := s.cpu__decode__o_sh_right
  { s with
    cpu__sh_right := cpu__sh_right
  }

/-- 组合逻辑：assign_cpu__bne_or_bge -/
def assign_cpu__bne_or_bge (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bne_or_bge := s.cpu__decode__o_bne_or_bge
  { s with
    cpu__bne_or_bge := cpu__bne_or_bge
  }

/-- 组合逻辑：assign_cpu__cond_branch -/
def assign_cpu__cond_branch (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__cond_branch := s.cpu__decode__o_cond_branch
  { s with
    cpu__cond_branch := cpu__cond_branch
  }

/-- 组合逻辑：assign_cpu__e_op -/
def assign_cpu__e_op (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__e_op := s.cpu__decode__o_e_op
  { s with
    cpu__e_op := cpu__e_op
  }

/-- 组合逻辑：assign_cpu__ebreak -/
def assign_cpu__ebreak (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ebreak := s.cpu__decode__o_ebreak
  { s with
    cpu__ebreak := cpu__ebreak
  }

/-- 组合逻辑：assign_cpu__branch_op -/
def assign_cpu__branch_op (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__branch_op := s.cpu__decode__o_branch_op
  { s with
    cpu__branch_op := cpu__branch_op
  }

/-- 组合逻辑：assign_cpu__shift_op -/
def assign_cpu__shift_op (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__shift_op := s.cpu__decode__o_shift_op
  { s with
    cpu__shift_op := cpu__shift_op
  }

/-- 组合逻辑：assign_cpu__rd_op -/
def assign_cpu__rd_op (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rd_op := s.cpu__decode__o_rd_op
  { s with
    cpu__rd_op := cpu__rd_op
  }

/-- 组合逻辑：assign_cpu__two_stage_op -/
def assign_cpu__two_stage_op (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__two_stage_op := s.cpu__decode__o_two_stage_op
  { s with
    cpu__two_stage_op := cpu__two_stage_op
  }

/-- 组合逻辑：assign_cpu__dbus_en -/
def assign_cpu__dbus_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__dbus_en := s.cpu__decode__o_dbus_en
  { s with
    cpu__dbus_en := cpu__dbus_en
  }

/-- 组合逻辑：assign_cpu__mdu_op -/
def assign_cpu__mdu_op (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__mdu_op := s.cpu__decode__o_mdu_op
  { s with
    cpu__mdu_op := cpu__mdu_op
  }

/-- 组合逻辑：assign_cpu__o_ext_funct3 -/
def assign_cpu__o_ext_funct3 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__o_ext_funct3 := s.cpu__decode__o_ext_funct3
  { s with
    cpu__o_ext_funct3 := cpu__o_ext_funct3
  }

/-- 组合逻辑：assign_cpu__bufreg_rs1_en -/
def assign_cpu__bufreg_rs1_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg_rs1_en := s.cpu__decode__o_bufreg_rs1_en
  { s with
    cpu__bufreg_rs1_en := cpu__bufreg_rs1_en
  }

/-- 组合逻辑：assign_cpu__bufreg_imm_en -/
def assign_cpu__bufreg_imm_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg_imm_en := s.cpu__decode__o_bufreg_imm_en
  { s with
    cpu__bufreg_imm_en := cpu__bufreg_imm_en
  }

/-- 组合逻辑：assign_cpu__bufreg_clr_lsb -/
def assign_cpu__bufreg_clr_lsb (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg_clr_lsb := s.cpu__decode__o_bufreg_clr_lsb
  { s with
    cpu__bufreg_clr_lsb := cpu__bufreg_clr_lsb
  }

/-- 组合逻辑：assign_cpu__bufreg_sh_signed -/
def assign_cpu__bufreg_sh_signed (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg_sh_signed := s.cpu__decode__o_bufreg_sh_signed
  { s with
    cpu__bufreg_sh_signed := cpu__bufreg_sh_signed
  }

/-- 组合逻辑：assign_cpu__jal_or_jalr -/
def assign_cpu__jal_or_jalr (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__jal_or_jalr := s.cpu__decode__o_ctrl_jal_or_jalr
  { s with
    cpu__jal_or_jalr := cpu__jal_or_jalr
  }

/-- 组合逻辑：assign_cpu__utype -/
def assign_cpu__utype (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__utype := s.cpu__decode__o_ctrl_utype
  { s with
    cpu__utype := cpu__utype
  }

/-- 组合逻辑：assign_cpu__pc_rel -/
def assign_cpu__pc_rel (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__pc_rel := s.cpu__decode__o_ctrl_pc_rel
  { s with
    cpu__pc_rel := cpu__pc_rel
  }

/-- 组合逻辑：assign_cpu__mret -/
def assign_cpu__mret (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__mret := s.cpu__decode__o_ctrl_mret
  { s with
    cpu__mret := cpu__mret
  }

/-- 组合逻辑：assign_cpu__alu_sub -/
def assign_cpu__alu_sub (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__alu_sub := s.cpu__decode__o_alu_sub
  { s with
    cpu__alu_sub := cpu__alu_sub
  }

/-- 组合逻辑：assign_cpu__alu_bool_op -/
def assign_cpu__alu_bool_op (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__alu_bool_op := s.cpu__decode__o_alu_bool_op
  { s with
    cpu__alu_bool_op := cpu__alu_bool_op
  }

/-- 组合逻辑：assign_cpu__alu_cmp_eq -/
def assign_cpu__alu_cmp_eq (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__alu_cmp_eq := s.cpu__decode__o_alu_cmp_eq
  { s with
    cpu__alu_cmp_eq := cpu__alu_cmp_eq
  }

/-- 组合逻辑：assign_cpu__alu_cmp_sig -/
def assign_cpu__alu_cmp_sig (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__alu_cmp_sig := s.cpu__decode__o_alu_cmp_sig
  { s with
    cpu__alu_cmp_sig := cpu__alu_cmp_sig
  }

/-- 组合逻辑：assign_cpu__alu_rd_sel -/
def assign_cpu__alu_rd_sel (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__alu_rd_sel := s.cpu__decode__o_alu_rd_sel
  { s with
    cpu__alu_rd_sel := cpu__alu_rd_sel
  }

/-- 组合逻辑：assign_cpu__mem_signed -/
def assign_cpu__mem_signed (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__mem_signed := s.cpu__decode__o_mem_signed
  { s with
    cpu__mem_signed := cpu__mem_signed
  }

/-- 组合逻辑：assign_cpu__mem_word -/
def assign_cpu__mem_word (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__mem_word := s.cpu__decode__o_mem_word
  { s with
    cpu__mem_word := cpu__mem_word
  }

/-- 组合逻辑：assign_cpu__mem_half -/
def assign_cpu__mem_half (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__mem_half := s.cpu__decode__o_mem_half
  { s with
    cpu__mem_half := cpu__mem_half
  }

/-- 组合逻辑：assign_cpu__o_dbus_we -/
def assign_cpu__o_dbus_we (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__o_dbus_we := s.cpu__decode__o_mem_cmd
  { s with
    cpu__o_dbus_we := cpu__o_dbus_we
  }

/-- 组合逻辑：assign_cpu__csr_en -/
def assign_cpu__csr_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__csr_en := s.cpu__decode__o_csr_en
  { s with
    cpu__csr_en := cpu__csr_en
  }

/-- 组合逻辑：assign_cpu__csr_addr -/
def assign_cpu__csr_addr (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__csr_addr := s.cpu__decode__o_csr_addr
  { s with
    cpu__csr_addr := cpu__csr_addr
  }

/-- 组合逻辑：assign_cpu__csr_mstatus_en -/
def assign_cpu__csr_mstatus_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__csr_mstatus_en := s.cpu__decode__o_csr_mstatus_en
  { s with
    cpu__csr_mstatus_en := cpu__csr_mstatus_en
  }

/-- 组合逻辑：assign_cpu__csr_mie_en -/
def assign_cpu__csr_mie_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__csr_mie_en := s.cpu__decode__o_csr_mie_en
  { s with
    cpu__csr_mie_en := cpu__csr_mie_en
  }

/-- 组合逻辑：assign_cpu__csr_mcause_en -/
def assign_cpu__csr_mcause_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__csr_mcause_en := s.cpu__decode__o_csr_mcause_en
  { s with
    cpu__csr_mcause_en := cpu__csr_mcause_en
  }

/-- 组合逻辑：assign_cpu__csr_source -/
def assign_cpu__csr_source (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__csr_source := s.cpu__decode__o_csr_source
  { s with
    cpu__csr_source := cpu__csr_source
  }

/-- 组合逻辑：assign_cpu__csr_d_sel -/
def assign_cpu__csr_d_sel (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__csr_d_sel := s.cpu__decode__o_csr_d_sel
  { s with
    cpu__csr_d_sel := cpu__csr_d_sel
  }

/-- 组合逻辑：assign_cpu__csr_imm_en -/
def assign_cpu__csr_imm_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__csr_imm_en := s.cpu__decode__o_csr_imm_en
  { s with
    cpu__csr_imm_en := cpu__csr_imm_en
  }

/-- 组合逻辑：assign_cpu__mtval_pc -/
def assign_cpu__mtval_pc (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__mtval_pc := s.cpu__decode__o_mtval_pc
  { s with
    cpu__mtval_pc := cpu__mtval_pc
  }

/-- 组合逻辑：assign_cpu__immdec_ctrl -/
def assign_cpu__immdec_ctrl (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__immdec_ctrl := s.cpu__decode__o_immdec_ctrl
  { s with
    cpu__immdec_ctrl := cpu__immdec_ctrl
  }

/-- 组合逻辑：assign_cpu__immdec_en -/
def assign_cpu__immdec_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__immdec_en := s.cpu__decode__o_immdec_en
  { s with
    cpu__immdec_en := cpu__immdec_en
  }

/-- 组合逻辑：assign_cpu__op_b_sel -/
def assign_cpu__op_b_sel (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__op_b_sel := s.cpu__decode__o_op_b_source
  { s with
    cpu__op_b_sel := cpu__op_b_sel
  }

/-- 组合逻辑：assign_cpu__rd_mem_en -/
def assign_cpu__rd_mem_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rd_mem_en := s.cpu__decode__o_rd_mem_en
  { s with
    cpu__rd_mem_en := cpu__rd_mem_en
  }

/-- 组合逻辑：assign_cpu__rd_csr_en -/
def assign_cpu__rd_csr_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rd_csr_en := s.cpu__decode__o_rd_csr_en
  { s with
    cpu__rd_csr_en := cpu__rd_csr_en
  }

/-- 组合逻辑：assign_cpu__rd_alu_en -/
def assign_cpu__rd_alu_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rd_alu_en := s.cpu__decode__o_rd_alu_en
  { s with
    cpu__rd_alu_en := cpu__rd_alu_en
  }

/-- 组合逻辑：assign_cpu__decode__co_mdu_op -/
def assign_cpu__decode__co_mdu_op (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_mdu_op := ((false && decide ((s.cpu__decode__opcode).toNat = (BitVec.ofNat 5 12).toNat)) && s.cpu__decode__imm25)
  { s with
    cpu__decode__co_mdu_op := cpu__decode__co_mdu_op
  }

/-- 组合逻辑：assign_cpu__decode__co_two_stage_op -/
def assign_cpu__decode__co_two_stage_op (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_two_stage_op := (((!(BitVec.getLsbD (s.cpu__decode__opcode) 2) || (((BitVec.getLsbD (s.cpu__decode__funct3) 0 && !(BitVec.getLsbD (s.cpu__decode__funct3) 1)) && !(BitVec.getLsbD (s.cpu__decode__opcode) 0)) && !(BitVec.getLsbD (s.cpu__decode__opcode) 4))) || (((BitVec.getLsbD (s.cpu__decode__funct3) 1 && !(BitVec.getLsbD (s.cpu__decode__funct3) 2)) && !(BitVec.getLsbD (s.cpu__decode__opcode) 0)) && !(BitVec.getLsbD (s.cpu__decode__opcode) 4))) || s.cpu__decode__co_mdu_op)
  { s with
    cpu__decode__co_two_stage_op := cpu__decode__co_two_stage_op
  }

/-- 组合逻辑：assign_cpu__decode__co_shift_op -/
def assign_cpu__decode__co_shift_op (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_shift_op := ((BitVec.getLsbD (s.cpu__decode__opcode) 2 && !(BitVec.getLsbD (s.cpu__decode__funct3) 1)) && !(s.cpu__decode__co_mdu_op))
  { s with
    cpu__decode__co_shift_op := cpu__decode__co_shift_op
  }

/-- 组合逻辑：assign_cpu__decode__co_branch_op -/
def assign_cpu__decode__co_branch_op (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_branch_op := BitVec.getLsbD (s.cpu__decode__opcode) 4
  { s with
    cpu__decode__co_branch_op := cpu__decode__co_branch_op
  }

/-- 组合逻辑：assign_cpu__decode__co_dbus_en -/
def assign_cpu__decode__co_dbus_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_dbus_en := (!(BitVec.getLsbD (s.cpu__decode__opcode) 2) && !(BitVec.getLsbD (s.cpu__decode__opcode) 4))
  { s with
    cpu__decode__co_dbus_en := cpu__decode__co_dbus_en
  }

/-- 组合逻辑：assign_cpu__decode__co_mtval_pc -/
def assign_cpu__decode__co_mtval_pc (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_mtval_pc := BitVec.getLsbD (s.cpu__decode__opcode) 4
  { s with
    cpu__decode__co_mtval_pc := cpu__decode__co_mtval_pc
  }

/-- 组合逻辑：assign_cpu__decode__co_mem_word -/
def assign_cpu__decode__co_mem_word (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_mem_word := BitVec.getLsbD (s.cpu__decode__funct3) 1
  { s with
    cpu__decode__co_mem_word := cpu__decode__co_mem_word
  }

/-- 组合逻辑：assign_cpu__decode__co_rd_alu_en -/
def assign_cpu__decode__co_rd_alu_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_rd_alu_en := (((!(BitVec.getLsbD (s.cpu__decode__opcode) 0) && BitVec.getLsbD (s.cpu__decode__opcode) 2) && !(BitVec.getLsbD (s.cpu__decode__opcode) 4)) && !(s.cpu__decode__co_mdu_op))
  { s with
    cpu__decode__co_rd_alu_en := cpu__decode__co_rd_alu_en
  }

/-- 组合逻辑：assign_cpu__decode__co_rd_mem_en -/
def assign_cpu__decode__co_rd_mem_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_rd_mem_en := ((!(BitVec.getLsbD (s.cpu__decode__opcode) 2) && !(BitVec.getLsbD (s.cpu__decode__opcode) 0)) || s.cpu__decode__co_mdu_op)
  { s with
    cpu__decode__co_rd_mem_en := cpu__decode__co_rd_mem_en
  }

/-- 组合逻辑：assign_cpu__decode__co_ext_funct3 -/
def assign_cpu__decode__co_ext_funct3 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_ext_funct3 := s.cpu__decode__funct3
  { s with
    cpu__decode__co_ext_funct3 := cpu__decode__co_ext_funct3
  }

/-- 组合逻辑：assign_cpu__decode__co_bufreg_rs1_en -/
def assign_cpu__decode__co_bufreg_rs1_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_bufreg_rs1_en := (!(BitVec.getLsbD (s.cpu__decode__opcode) 4) || (!(BitVec.getLsbD (s.cpu__decode__opcode) 1) && BitVec.getLsbD (s.cpu__decode__opcode) 0))
  { s with
    cpu__decode__co_bufreg_rs1_en := cpu__decode__co_bufreg_rs1_en
  }

/-- 组合逻辑：assign_cpu__decode__co_bufreg_imm_en -/
def assign_cpu__decode__co_bufreg_imm_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_bufreg_imm_en := !(BitVec.getLsbD (s.cpu__decode__opcode) 2)
  { s with
    cpu__decode__co_bufreg_imm_en := cpu__decode__co_bufreg_imm_en
  }

/-- 组合逻辑：assign_cpu__decode__co_bufreg_clr_lsb -/
def assign_cpu__decode__co_bufreg_clr_lsb (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_bufreg_clr_lsb := (BitVec.getLsbD (s.cpu__decode__opcode) 4 && (decide ((BitVec.extractLsb 1 0 (s.cpu__decode__opcode)).toNat = (BitVec.ofNat 2 0).toNat) || decide ((BitVec.extractLsb 1 0 (s.cpu__decode__opcode)).toNat = (BitVec.ofNat 2 3).toNat)))
  { s with
    cpu__decode__co_bufreg_clr_lsb := cpu__decode__co_bufreg_clr_lsb
  }

/-- 组合逻辑：assign_cpu__decode__co_cond_branch -/
def assign_cpu__decode__co_cond_branch (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_cond_branch := !(BitVec.getLsbD (s.cpu__decode__opcode) 0)
  { s with
    cpu__decode__co_cond_branch := cpu__decode__co_cond_branch
  }

/-- 组合逻辑：assign_cpu__decode__co_ctrl_utype -/
def assign_cpu__decode__co_ctrl_utype (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_ctrl_utype := ((!(BitVec.getLsbD (s.cpu__decode__opcode) 4) && BitVec.getLsbD (s.cpu__decode__opcode) 2) && BitVec.getLsbD (s.cpu__decode__opcode) 0)
  { s with
    cpu__decode__co_ctrl_utype := cpu__decode__co_ctrl_utype
  }

/-- 组合逻辑：assign_cpu__decode__co_ctrl_jal_or_jalr -/
def assign_cpu__decode__co_ctrl_jal_or_jalr (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_ctrl_jal_or_jalr := (BitVec.getLsbD (s.cpu__decode__opcode) 4 && BitVec.getLsbD (s.cpu__decode__opcode) 0)
  { s with
    cpu__decode__co_ctrl_jal_or_jalr := cpu__decode__co_ctrl_jal_or_jalr
  }

/-- 组合逻辑：assign_cpu__decode__co_ctrl_pc_rel -/
def assign_cpu__decode__co_ctrl_pc_rel (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_ctrl_pc_rel := (((decide ((BitVec.extractLsb 2 0 (s.cpu__decode__opcode)).toNat = (BitVec.ofNat 3 0).toNat) || decide ((BitVec.extractLsb 1 0 (s.cpu__decode__opcode)).toNat = (BitVec.ofNat 2 3).toNat)) || ((BitVec.getLsbD (s.cpu__decode__opcode) 4 && BitVec.getLsbD (s.cpu__decode__opcode) 2) && s.cpu__decode__op20)) || decide ((BitVec.extractLsb 4 3 (s.cpu__decode__opcode)).toNat = (BitVec.ofNat 2 0).toNat))
  { s with
    cpu__decode__co_ctrl_pc_rel := cpu__decode__co_ctrl_pc_rel
  }

/-- 组合逻辑：assign_cpu__decode__co_rd_op -/
def assign_cpu__decode__co_rd_op (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_rd_op := ((BitVec.getLsbD (s.cpu__decode__opcode) 2 || ((!(BitVec.getLsbD (s.cpu__decode__opcode) 2) && BitVec.getLsbD (s.cpu__decode__opcode) 4) && BitVec.getLsbD (s.cpu__decode__opcode) 0)) || ((!(BitVec.getLsbD (s.cpu__decode__opcode) 2) && !(BitVec.getLsbD (s.cpu__decode__opcode) 3)) && !(BitVec.getLsbD (s.cpu__decode__opcode) 0)))
  { s with
    cpu__decode__co_rd_op := cpu__decode__co_rd_op
  }

/-- 组合逻辑：assign_cpu__decode__co_sh_right -/
def assign_cpu__decode__co_sh_right (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_sh_right := BitVec.getLsbD (s.cpu__decode__funct3) 2
  { s with
    cpu__decode__co_sh_right := cpu__decode__co_sh_right
  }

/-- 组合逻辑：assign_cpu__decode__co_bne_or_bge -/
def assign_cpu__decode__co_bne_or_bge (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_bne_or_bge := BitVec.getLsbD (s.cpu__decode__funct3) 0
  { s with
    cpu__decode__co_bne_or_bge := cpu__decode__co_bne_or_bge
  }

/-- 组合逻辑：assign_cpu__decode__csr_op -/
def assign_cpu__decode__csr_op (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__csr_op := ((BitVec.getLsbD (s.cpu__decode__opcode) 4 && BitVec.getLsbD (s.cpu__decode__opcode) 2) && bvNonzero (s.cpu__decode__funct3))
  { s with
    cpu__decode__csr_op := cpu__decode__csr_op
  }

/-- 组合逻辑：assign_cpu__decode__co_ebreak -/
def assign_cpu__decode__co_ebreak (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_ebreak := s.cpu__decode__op20
  { s with
    cpu__decode__co_ebreak := cpu__decode__co_ebreak
  }

/-- 组合逻辑：assign_cpu__decode__co_ctrl_mret -/
def assign_cpu__decode__co_ctrl_mret (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_ctrl_mret := (((BitVec.getLsbD (s.cpu__decode__opcode) 4 && BitVec.getLsbD (s.cpu__decode__opcode) 2) && s.cpu__decode__op21) && !(bvNonzero (s.cpu__decode__funct3)))
  { s with
    cpu__decode__co_ctrl_mret := cpu__decode__co_ctrl_mret
  }

/-- 组合逻辑：assign_cpu__decode__co_e_op -/
def assign_cpu__decode__co_e_op (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_e_op := (((BitVec.getLsbD (s.cpu__decode__opcode) 4 && BitVec.getLsbD (s.cpu__decode__opcode) 2) && !(s.cpu__decode__op21)) && !(bvNonzero (s.cpu__decode__funct3)))
  { s with
    cpu__decode__co_e_op := cpu__decode__co_e_op
  }

/-- 组合逻辑：assign_cpu__decode__co_bufreg_sh_signed -/
def assign_cpu__decode__co_bufreg_sh_signed (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_bufreg_sh_signed := s.cpu__decode__imm30
  { s with
    cpu__decode__co_bufreg_sh_signed := cpu__decode__co_bufreg_sh_signed
  }

/-- 组合逻辑：assign_cpu__decode__co_alu_sub -/
def assign_cpu__decode__co_alu_sub (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_alu_sub := (((BitVec.getLsbD (s.cpu__decode__funct3) 1 || BitVec.getLsbD (s.cpu__decode__funct3) 0) || (BitVec.getLsbD (s.cpu__decode__opcode) 3 && s.cpu__decode__imm30)) || BitVec.getLsbD (s.cpu__decode__opcode) 4)
  { s with
    cpu__decode__co_alu_sub := cpu__decode__co_alu_sub
  }

/-- 组合逻辑：assign_cpu__decode__csr_valid -/
def assign_cpu__decode__csr_valid (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__csr_valid := (s.cpu__decode__op20 || (s.cpu__decode__op26 && !(s.cpu__decode__op21)))
  { s with
    cpu__decode__csr_valid := cpu__decode__csr_valid
  }

/-- 组合逻辑：assign_cpu__decode__co_rd_csr_en -/
def assign_cpu__decode__co_rd_csr_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_rd_csr_en := s.cpu__decode__csr_op
  { s with
    cpu__decode__co_rd_csr_en := cpu__decode__co_rd_csr_en
  }

/-- 组合逻辑：assign_cpu__decode__co_csr_en -/
def assign_cpu__decode__co_csr_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_csr_en := (s.cpu__decode__csr_op && s.cpu__decode__csr_valid)
  { s with
    cpu__decode__co_csr_en := cpu__decode__co_csr_en
  }

/-- 组合逻辑：assign_cpu__decode__co_csr_mstatus_en -/
def assign_cpu__decode__co_csr_mstatus_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_csr_mstatus_en := (((s.cpu__decode__csr_op && !(s.cpu__decode__op26)) && !(s.cpu__decode__op22)) && !(s.cpu__decode__op20))
  { s with
    cpu__decode__co_csr_mstatus_en := cpu__decode__co_csr_mstatus_en
  }

/-- 组合逻辑：assign_cpu__decode__co_csr_mie_en -/
def assign_cpu__decode__co_csr_mie_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_csr_mie_en := (((s.cpu__decode__csr_op && !(s.cpu__decode__op26)) && s.cpu__decode__op22) && !(s.cpu__decode__op20))
  { s with
    cpu__decode__co_csr_mie_en := cpu__decode__co_csr_mie_en
  }

/-- 组合逻辑：assign_cpu__decode__co_csr_mcause_en -/
def assign_cpu__decode__co_csr_mcause_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_csr_mcause_en := ((s.cpu__decode__csr_op && s.cpu__decode__op21) && !(s.cpu__decode__op20))
  { s with
    cpu__decode__co_csr_mcause_en := cpu__decode__co_csr_mcause_en
  }

/-- 组合逻辑：assign_cpu__decode__co_csr_source -/
def assign_cpu__decode__co_csr_source (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_csr_source := BitVec.extractLsb 1 0 (s.cpu__decode__funct3)
  { s with
    cpu__decode__co_csr_source := cpu__decode__co_csr_source
  }

/-- 组合逻辑：assign_cpu__decode__co_csr_d_sel -/
def assign_cpu__decode__co_csr_d_sel (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_csr_d_sel := BitVec.getLsbD (s.cpu__decode__funct3) 2
  { s with
    cpu__decode__co_csr_d_sel := cpu__decode__co_csr_d_sel
  }

/-- 组合逻辑：assign_cpu__decode__co_csr_imm_en -/
def assign_cpu__decode__co_csr_imm_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_csr_imm_en := ((BitVec.getLsbD (s.cpu__decode__opcode) 4 && BitVec.getLsbD (s.cpu__decode__opcode) 2) && BitVec.getLsbD (s.cpu__decode__funct3) 2)
  { s with
    cpu__decode__co_csr_imm_en := cpu__decode__co_csr_imm_en
  }

/-- 组合逻辑：assign_cpu__decode__co_csr_addr -/
def assign_cpu__decode__co_csr_addr (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_csr_addr := BitVec.append (n := 1) (m := 1) (boolToBitVec ((s.cpu__decode__op26 && s.cpu__decode__op20))) (boolToBitVec ((!(s.cpu__decode__op26) || s.cpu__decode__op21)))
  { s with
    cpu__decode__co_csr_addr := cpu__decode__co_csr_addr
  }

/-- 组合逻辑：assign_cpu__decode__co_alu_cmp_eq -/
def assign_cpu__decode__co_alu_cmp_eq (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_alu_cmp_eq := decide ((BitVec.extractLsb 2 1 (s.cpu__decode__funct3)).toNat = (BitVec.ofNat 2 0).toNat)
  { s with
    cpu__decode__co_alu_cmp_eq := cpu__decode__co_alu_cmp_eq
  }

/-- 组合逻辑：assign_cpu__decode__co_alu_cmp_sig -/
def assign_cpu__decode__co_alu_cmp_sig (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_alu_cmp_sig := !(((BitVec.getLsbD (s.cpu__decode__funct3) 0 && BitVec.getLsbD (s.cpu__decode__funct3) 1) || (BitVec.getLsbD (s.cpu__decode__funct3) 1 && BitVec.getLsbD (s.cpu__decode__funct3) 2)))
  { s with
    cpu__decode__co_alu_cmp_sig := cpu__decode__co_alu_cmp_sig
  }

/-- 组合逻辑：assign_cpu__decode__co_mem_cmd -/
def assign_cpu__decode__co_mem_cmd (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_mem_cmd := BitVec.getLsbD (s.cpu__decode__opcode) 3
  { s with
    cpu__decode__co_mem_cmd := cpu__decode__co_mem_cmd
  }

/-- 组合逻辑：assign_cpu__decode__co_mem_signed -/
def assign_cpu__decode__co_mem_signed (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_mem_signed := !(BitVec.getLsbD (s.cpu__decode__funct3) 2)
  { s with
    cpu__decode__co_mem_signed := cpu__decode__co_mem_signed
  }

/-- 组合逻辑：assign_cpu__decode__co_mem_half -/
def assign_cpu__decode__co_mem_half (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_mem_half := BitVec.getLsbD (s.cpu__decode__funct3) 0
  { s with
    cpu__decode__co_mem_half := cpu__decode__co_mem_half
  }

/-- 组合逻辑：assign_cpu__decode__co_alu_bool_op -/
def assign_cpu__decode__co_alu_bool_op (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_alu_bool_op := BitVec.extractLsb 1 0 (s.cpu__decode__funct3)
  { s with
    cpu__decode__co_alu_bool_op := cpu__decode__co_alu_bool_op
  }

/-- 组合逻辑：assign_cpu__decode__co_immdec_ctrl -/
def assign_cpu__decode__co_immdec_ctrl (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_immdec_ctrl := BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.cpu__decode__opcode) 4)) (boolToBitVec ((BitVec.getLsbD (s.cpu__decode__opcode) 4 && !(BitVec.getLsbD (s.cpu__decode__opcode) 0))))) (BitVec.append (n := 1) (m := 1) (boolToBitVec ((decide ((BitVec.extractLsb 1 0 (s.cpu__decode__opcode)).toNat = (BitVec.ofNat 2 0).toNat) || decide ((BitVec.extractLsb 2 1 (s.cpu__decode__opcode)).toNat = (BitVec.ofNat 2 0).toNat)))) (boolToBitVec (decide ((BitVec.extractLsb 3 0 (s.cpu__decode__opcode)).toNat = (BitVec.ofNat 4 8).toNat))))
  { s with
    cpu__decode__co_immdec_ctrl := cpu__decode__co_immdec_ctrl
  }

/-- 组合逻辑：assign_cpu__decode__co_immdec_en -/
def assign_cpu__decode__co_immdec_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_immdec_en := BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec ((((BitVec.getLsbD (s.cpu__decode__opcode) 4 || BitVec.getLsbD (s.cpu__decode__opcode) 3) || BitVec.getLsbD (s.cpu__decode__opcode) 2) || !(BitVec.getLsbD (s.cpu__decode__opcode) 0)))) (boolToBitVec ((((BitVec.getLsbD (s.cpu__decode__opcode) 4 && BitVec.getLsbD (s.cpu__decode__opcode) 2) || !(BitVec.getLsbD (s.cpu__decode__opcode) 3)) || BitVec.getLsbD (s.cpu__decode__opcode) 0)))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (((decide ((BitVec.extractLsb 2 1 (s.cpu__decode__opcode)).toNat = (BitVec.ofNat 2 1).toNat) || (BitVec.getLsbD (s.cpu__decode__opcode) 2 && BitVec.getLsbD (s.cpu__decode__opcode) 0)) || s.cpu__decode__co_csr_imm_en))) (boolToBitVec (!(s.cpu__decode__co_rd_op))))
  { s with
    cpu__decode__co_immdec_en := cpu__decode__co_immdec_en
  }

/-- 组合逻辑：assign_cpu__decode__co_alu_rd_sel -/
def assign_cpu__decode__co_alu_rd_sel (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_alu_rd_sel := BitVec.append (n := 1) (m := 2) (boolToBitVec (BitVec.getLsbD (s.cpu__decode__funct3) 2)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (decide ((BitVec.extractLsb 2 1 (s.cpu__decode__funct3)).toNat = (BitVec.ofNat 2 1).toNat))) (boolToBitVec (decide ((s.cpu__decode__funct3).toNat = (BitVec.ofNat 3 0).toNat))))
  { s with
    cpu__decode__co_alu_rd_sel := cpu__decode__co_alu_rd_sel
  }

/-- 组合逻辑：assign_cpu__decode__co_op_b_source -/
def assign_cpu__decode__co_op_b_source (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__co_op_b_source := BitVec.getLsbD (s.cpu__decode__opcode) 3
  { s with
    cpu__decode__co_op_b_source := cpu__decode__co_op_b_source
  }

/-- 组合逻辑：assign_cpu__immdec__i_clk -/
def assign_cpu__immdec__i_clk (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__immdec__i_clk := s.cpu__clk
  { s with
    cpu__immdec__i_clk := cpu__immdec__i_clk
  }

/-- 组合逻辑：assign_cpu__immdec__i_cnt_en -/
def assign_cpu__immdec__i_cnt_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__immdec__i_cnt_en := s.cpu__cnt_en
  { s with
    cpu__immdec__i_cnt_en := cpu__immdec__i_cnt_en
  }

/-- 组合逻辑：assign_cpu__immdec__i_cnt_done -/
def assign_cpu__immdec__i_cnt_done (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__immdec__i_cnt_done := s.cpu__cnt_done
  { s with
    cpu__immdec__i_cnt_done := cpu__immdec__i_cnt_done
  }

/-- 组合逻辑：assign_cpu__immdec__i_immdec_en -/
def assign_cpu__immdec__i_immdec_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__immdec__i_immdec_en := s.cpu__immdec_en
  { s with
    cpu__immdec__i_immdec_en := cpu__immdec__i_immdec_en
  }

/-- 组合逻辑：assign_cpu__immdec__i_csr_imm_en -/
def assign_cpu__immdec__i_csr_imm_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__immdec__i_csr_imm_en := s.cpu__csr_imm_en
  { s with
    cpu__immdec__i_csr_imm_en := cpu__immdec__i_csr_imm_en
  }

/-- 组合逻辑：assign_cpu__immdec__i_ctrl -/
def assign_cpu__immdec__i_ctrl (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__immdec__i_ctrl := s.cpu__immdec_ctrl
  { s with
    cpu__immdec__i_ctrl := cpu__immdec__i_ctrl
  }

/-- 组合逻辑：assign_cpu__rd_addr -/
def assign_cpu__rd_addr (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rd_addr := s.cpu__immdec__o_rd_addr
  { s with
    cpu__rd_addr := cpu__rd_addr
  }

/-- 组合逻辑：assign_cpu__rs1_addr -/
def assign_cpu__rs1_addr (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rs1_addr := s.cpu__immdec__o_rs1_addr
  { s with
    cpu__rs1_addr := cpu__rs1_addr
  }

/-- 组合逻辑：assign_cpu__rs2_addr -/
def assign_cpu__rs2_addr (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rs2_addr := s.cpu__immdec__o_rs2_addr
  { s with
    cpu__rs2_addr := cpu__rs2_addr
  }

/-- 组合逻辑：assign_cpu__csr_imm -/
def assign_cpu__csr_imm (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__csr_imm := s.cpu__immdec__o_csr_imm
  { s with
    cpu__csr_imm := cpu__csr_imm
  }

/-- 组合逻辑：assign_cpu__imm -/
def assign_cpu__imm (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__imm := s.cpu__immdec__o_imm
  { s with
    cpu__imm := cpu__imm
  }

/-- 组合逻辑：assign_cpu__immdec__i_wb_en -/
def assign_cpu__immdec__i_wb_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__immdec__i_wb_en := s.cpu__wb_ibus_ack
  { s with
    cpu__immdec__i_wb_en := cpu__immdec__i_wb_en
  }

/-- 组合逻辑：assign_cpu__immdec__i_wb_rdt -/
def assign_cpu__immdec__i_wb_rdt (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__immdec__i_wb_rdt := BitVec.extractLsb 31 7 (s.cpu__i_wb_rdt)
  { s with
    cpu__immdec__i_wb_rdt := cpu__immdec__i_wb_rdt
  }

/-- 组合逻辑：assign_cpu__immdec__o_csr_imm -/
def assign_cpu__immdec__o_csr_imm (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__immdec__o_csr_imm := BitVec.getLsbD (s.cpu__immdec__gen_immdec_w_eq_1__imm19_12_20) 4
  { s with
    cpu__immdec__o_csr_imm := cpu__immdec__o_csr_imm
  }

/-- 组合逻辑：assign_cpu__immdec__gen_immdec_w_eq_1__signbit -/
def assign_cpu__immdec__gen_immdec_w_eq_1__signbit (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__immdec__gen_immdec_w_eq_1__signbit := (s.cpu__immdec__gen_immdec_w_eq_1__imm31 && !(s.cpu__immdec__i_csr_imm_en))
  { s with
    cpu__immdec__gen_immdec_w_eq_1__signbit := cpu__immdec__gen_immdec_w_eq_1__signbit
  }

/-- 组合逻辑：assign_cpu__immdec__o_rs1_addr -/
def assign_cpu__immdec__o_rs1_addr (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__immdec__o_rs1_addr := BitVec.extractLsb 8 4 (s.cpu__immdec__gen_immdec_w_eq_1__imm19_12_20)
  { s with
    cpu__immdec__o_rs1_addr := cpu__immdec__o_rs1_addr
  }

/-- 组合逻辑：assign_cpu__immdec__o_rs2_addr -/
def assign_cpu__immdec__o_rs2_addr (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__immdec__o_rs2_addr := s.cpu__immdec__gen_immdec_w_eq_1__imm24_20
  { s with
    cpu__immdec__o_rs2_addr := cpu__immdec__o_rs2_addr
  }

/-- 组合逻辑：assign_cpu__immdec__o_rd_addr -/
def assign_cpu__immdec__o_rd_addr (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__immdec__o_rd_addr := s.cpu__immdec__gen_immdec_w_eq_1__imm11_7
  { s with
    cpu__immdec__o_rd_addr := cpu__immdec__o_rd_addr
  }

/-- 组合逻辑：assign_cpu__immdec__o_imm -/
def assign_cpu__immdec__o_imm (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__immdec__o_imm := (if s.cpu__immdec__i_cnt_done then s.cpu__immdec__gen_immdec_w_eq_1__signbit else (if BitVec.getLsbD (s.cpu__immdec__i_ctrl) 0 then BitVec.getLsbD (s.cpu__immdec__gen_immdec_w_eq_1__imm11_7) 0 else BitVec.getLsbD (s.cpu__immdec__gen_immdec_w_eq_1__imm24_20) 0))
  { s with
    cpu__immdec__o_imm := cpu__immdec__o_imm
  }

/-- 组合逻辑：assign_cpu__bufreg__i_clk -/
def assign_cpu__bufreg__i_clk (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg__i_clk := s.cpu__clk
  { s with
    cpu__bufreg__i_clk := cpu__bufreg__i_clk
  }

/-- 组合逻辑：assign_cpu__bufreg__i_cnt0 -/
def assign_cpu__bufreg__i_cnt0 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg__i_cnt0 := s.cpu__cnt0
  { s with
    cpu__bufreg__i_cnt0 := cpu__bufreg__i_cnt0
  }

/-- 组合逻辑：assign_cpu__bufreg__i_cnt1 -/
def assign_cpu__bufreg__i_cnt1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg__i_cnt1 := s.cpu__cnt1
  { s with
    cpu__bufreg__i_cnt1 := cpu__bufreg__i_cnt1
  }

/-- 组合逻辑：assign_cpu__bufreg__i_cnt_done -/
def assign_cpu__bufreg__i_cnt_done (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg__i_cnt_done := s.cpu__cnt_done
  { s with
    cpu__bufreg__i_cnt_done := cpu__bufreg__i_cnt_done
  }

/-- 组合逻辑：assign_cpu__bufreg__i_en -/
def assign_cpu__bufreg__i_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg__i_en := s.cpu__bufreg_en
  { s with
    cpu__bufreg__i_en := cpu__bufreg__i_en
  }

/-- 组合逻辑：assign_cpu__bufreg__i_init -/
def assign_cpu__bufreg__i_init (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg__i_init := s.cpu__init
  { s with
    cpu__bufreg__i_init := cpu__bufreg__i_init
  }

/-- 组合逻辑：assign_cpu__bufreg__i_mdu_op -/
def assign_cpu__bufreg__i_mdu_op (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg__i_mdu_op := s.cpu__mdu_op
  { s with
    cpu__bufreg__i_mdu_op := cpu__bufreg__i_mdu_op
  }

/-- 组合逻辑：assign_cpu__lsb -/
def assign_cpu__lsb (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__lsb := s.cpu__bufreg__o_lsb
  { s with
    cpu__lsb := cpu__lsb
  }

/-- 组合逻辑：assign_cpu__bufreg__i_rs1_en -/
def assign_cpu__bufreg__i_rs1_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg__i_rs1_en := s.cpu__bufreg_rs1_en
  { s with
    cpu__bufreg__i_rs1_en := cpu__bufreg__i_rs1_en
  }

/-- 组合逻辑：assign_cpu__bufreg__i_imm_en -/
def assign_cpu__bufreg__i_imm_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg__i_imm_en := s.cpu__bufreg_imm_en
  { s with
    cpu__bufreg__i_imm_en := cpu__bufreg__i_imm_en
  }

/-- 组合逻辑：assign_cpu__bufreg__i_clr_lsb -/
def assign_cpu__bufreg__i_clr_lsb (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg__i_clr_lsb := s.cpu__bufreg_clr_lsb
  { s with
    cpu__bufreg__i_clr_lsb := cpu__bufreg__i_clr_lsb
  }

/-- 组合逻辑：assign_cpu__bufreg__i_shift_op -/
def assign_cpu__bufreg__i_shift_op (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg__i_shift_op := s.cpu__shift_op
  { s with
    cpu__bufreg__i_shift_op := cpu__bufreg__i_shift_op
  }

/-- 组合逻辑：assign_cpu__bufreg__i_right_shift_op -/
def assign_cpu__bufreg__i_right_shift_op (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg__i_right_shift_op := s.cpu__sh_right
  { s with
    cpu__bufreg__i_right_shift_op := cpu__bufreg__i_right_shift_op
  }

/-- 组合逻辑：assign_cpu__bufreg__i_shamt -/
def assign_cpu__bufreg__i_shamt (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg__i_shamt := BitVec.extractLsb 26 24 (s.cpu__o_dbus_dat)
  { s with
    cpu__bufreg__i_shamt := cpu__bufreg__i_shamt
  }

/-- 组合逻辑：assign_cpu__bufreg__i_sh_signed -/
def assign_cpu__bufreg__i_sh_signed (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg__i_sh_signed := s.cpu__bufreg_sh_signed
  { s with
    cpu__bufreg__i_sh_signed := cpu__bufreg__i_sh_signed
  }

/-- 组合逻辑：assign_cpu__bufreg__i_rs1 -/
def assign_cpu__bufreg__i_rs1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg__i_rs1 := s.cpu__rs1
  { s with
    cpu__bufreg__i_rs1 := cpu__bufreg__i_rs1
  }

/-- 组合逻辑：assign_cpu__bufreg__i_imm -/
def assign_cpu__bufreg__i_imm (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg__i_imm := s.cpu__imm
  { s with
    cpu__bufreg__i_imm := cpu__bufreg__i_imm
  }

/-- 组合逻辑：assign_cpu__bufreg_q -/
def assign_cpu__bufreg_q (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg_q := s.cpu__bufreg__o_q
  { s with
    cpu__bufreg_q := cpu__bufreg_q
  }

/-- 组合逻辑：assign_cpu__o_dbus_adr -/
def assign_cpu__o_dbus_adr (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__o_dbus_adr := s.cpu__bufreg__o_dbus_adr
  { s with
    cpu__o_dbus_adr := cpu__o_dbus_adr
  }

/-- 组合逻辑：assign_cpu__o_ext_rs1 -/
def assign_cpu__o_ext_rs1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__o_ext_rs1 := s.cpu__bufreg__o_ext_rs1
  { s with
    cpu__o_ext_rs1 := cpu__o_ext_rs1
  }

/-- 组合逻辑：assign_cpu__bufreg__clr_lsb -/
def assign_cpu__bufreg__clr_lsb (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg__clr_lsb := bitVecToBool (boolToBitVec ((s.cpu__bufreg__i_cnt0 && s.cpu__bufreg__i_clr_lsb)))
  { s with
    cpu__bufreg__clr_lsb := cpu__bufreg__clr_lsb
  }

/-- 组合逻辑：assign_cpu__bufreg__c -/
def assign_cpu__bufreg__c (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg__c := BitVec.getLsbD (BitVec.extractLsb 1 0 ((BitVec.extractLsb 1 0 ((BitVec.extractLsb 1 0 (BitVec.extractLsb 1 0 (BitVec.extractLsb 1 0 (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec ((s.cpu__bufreg__i_rs1 && bitVecToBool (boolToBitVec (s.cpu__bufreg__i_rs1_en)))))))) + BitVec.extractLsb 1 0 (BitVec.extractLsb 1 0 (BitVec.extractLsb 1 0 (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (((s.cpu__bufreg__i_imm && bitVecToBool (boolToBitVec (s.cpu__bufreg__i_imm_en))) && !(s.cpu__bufreg__clr_lsb))))))))) + BitVec.extractLsb 1 0 (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (s.cpu__bufreg__c_r)))))) 1
  { s with
    cpu__bufreg__c := cpu__bufreg__c
  }

/-- 组合逻辑：assign_cpu__bufreg__q -/
def assign_cpu__bufreg__q (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg__q := BitVec.getLsbD (BitVec.extractLsb 1 0 ((BitVec.extractLsb 1 0 ((BitVec.extractLsb 1 0 (BitVec.extractLsb 1 0 (BitVec.extractLsb 1 0 (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec ((s.cpu__bufreg__i_rs1 && bitVecToBool (boolToBitVec (s.cpu__bufreg__i_rs1_en)))))))) + BitVec.extractLsb 1 0 (BitVec.extractLsb 1 0 (BitVec.extractLsb 1 0 (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (((s.cpu__bufreg__i_imm && bitVecToBool (boolToBitVec (s.cpu__bufreg__i_imm_en))) && !(s.cpu__bufreg__clr_lsb))))))))) + BitVec.extractLsb 1 0 (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (s.cpu__bufreg__c_r)))))) 0
  { s with
    cpu__bufreg__q := cpu__bufreg__q
  }

/-- 组合逻辑：assign_cpu__bufreg__o_lsb -/
def assign_cpu__bufreg__o_lsb (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg__o_lsb := (if (false && s.cpu__bufreg__i_mdu_op) then BitVec.ofNat 2 0 else BitVec.extractLsb 1 0 (s.cpu__bufreg__data))
  { s with
    cpu__bufreg__o_lsb := cpu__bufreg__o_lsb
  }

/-- 组合逻辑：assign_cpu__bufreg__o_q -/
def assign_cpu__bufreg__o_q (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg__o_q := (BitVec.getLsbD (s.cpu__bufreg__data) 0 && bitVecToBool (boolToBitVec (s.cpu__bufreg__i_en)))
  { s with
    cpu__bufreg__o_q := cpu__bufreg__o_q
  }

/-- 组合逻辑：assign_cpu__bufreg__o_dbus_adr -/
def assign_cpu__bufreg__o_dbus_adr (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg__o_dbus_adr := BitVec.append (n := 30) (m := 2) (BitVec.extractLsb 31 2 (s.cpu__bufreg__data)) (BitVec.ofNat 2 0)
  { s with
    cpu__bufreg__o_dbus_adr := cpu__bufreg__o_dbus_adr
  }

/-- 组合逻辑：assign_cpu__bufreg__o_ext_rs1 -/
def assign_cpu__bufreg__o_ext_rs1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg__o_ext_rs1 := s.cpu__bufreg__data
  { s with
    cpu__bufreg__o_ext_rs1 := cpu__bufreg__o_ext_rs1
  }

/-- 组合逻辑：assign_cpu__bufreg2__i_clk -/
def assign_cpu__bufreg2__i_clk (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg2__i_clk := s.cpu__clk
  { s with
    cpu__bufreg2__i_clk := cpu__bufreg2__i_clk
  }

/-- 组合逻辑：assign_cpu__bufreg2__i_en -/
def assign_cpu__bufreg2__i_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg2__i_en := s.cpu__cnt_en
  { s with
    cpu__bufreg2__i_en := cpu__bufreg2__i_en
  }

/-- 组合逻辑：assign_cpu__bufreg2__i_init -/
def assign_cpu__bufreg2__i_init (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg2__i_init := s.cpu__init
  { s with
    cpu__bufreg2__i_init := cpu__bufreg2__i_init
  }

/-- 组合逻辑：assign_cpu__bufreg2__i_cnt7 -/
def assign_cpu__bufreg2__i_cnt7 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg2__i_cnt7 := s.cpu__cnt7
  { s with
    cpu__bufreg2__i_cnt7 := cpu__bufreg2__i_cnt7
  }

/-- 组合逻辑：assign_cpu__bufreg2__i_cnt_done -/
def assign_cpu__bufreg2__i_cnt_done (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg2__i_cnt_done := s.cpu__cnt_done
  { s with
    cpu__bufreg2__i_cnt_done := cpu__bufreg2__i_cnt_done
  }

/-- 组合逻辑：assign_cpu__bufreg2__i_sh_right -/
def assign_cpu__bufreg2__i_sh_right (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg2__i_sh_right := s.cpu__sh_right
  { s with
    cpu__bufreg2__i_sh_right := cpu__bufreg2__i_sh_right
  }

/-- 组合逻辑：assign_cpu__bufreg2__i_lsb -/
def assign_cpu__bufreg2__i_lsb (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg2__i_lsb := s.cpu__lsb
  { s with
    cpu__bufreg2__i_lsb := cpu__bufreg2__i_lsb
  }

/-- 组合逻辑：assign_cpu__bufreg2__i_bytecnt -/
def assign_cpu__bufreg2__i_bytecnt (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg2__i_bytecnt := s.cpu__mem_bytecnt
  { s with
    cpu__bufreg2__i_bytecnt := cpu__bufreg2__i_bytecnt
  }

/-- 组合逻辑：assign_cpu__sh_done -/
def assign_cpu__sh_done (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__sh_done := s.cpu__bufreg2__o_sh_done
  { s with
    cpu__sh_done := cpu__sh_done
  }

/-- 组合逻辑：assign_cpu__bufreg2__i_op_b_sel -/
def assign_cpu__bufreg2__i_op_b_sel (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg2__i_op_b_sel := s.cpu__op_b_sel
  { s with
    cpu__bufreg2__i_op_b_sel := cpu__bufreg2__i_op_b_sel
  }

/-- 组合逻辑：assign_cpu__bufreg2__i_shift_op -/
def assign_cpu__bufreg2__i_shift_op (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg2__i_shift_op := s.cpu__shift_op
  { s with
    cpu__bufreg2__i_shift_op := cpu__bufreg2__i_shift_op
  }

/-- 组合逻辑：assign_cpu__bufreg2__i_rs2 -/
def assign_cpu__bufreg2__i_rs2 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg2__i_rs2 := s.cpu__rs2
  { s with
    cpu__bufreg2__i_rs2 := cpu__bufreg2__i_rs2
  }

/-- 组合逻辑：assign_cpu__bufreg2__i_imm -/
def assign_cpu__bufreg2__i_imm (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg2__i_imm := s.cpu__imm
  { s with
    cpu__bufreg2__i_imm := cpu__bufreg2__i_imm
  }

/-- 组合逻辑：assign_cpu__op_b -/
def assign_cpu__op_b (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__op_b := s.cpu__bufreg2__o_op_b
  { s with
    cpu__op_b := cpu__op_b
  }

/-- 组合逻辑：assign_cpu__bufreg2_q -/
def assign_cpu__bufreg2_q (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg2_q := s.cpu__bufreg2__o_q
  { s with
    cpu__bufreg2_q := cpu__bufreg2_q
  }

/-- 组合逻辑：assign_cpu__o_dbus_dat -/
def assign_cpu__o_dbus_dat (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__o_dbus_dat := s.cpu__bufreg2__o_dat
  { s with
    cpu__o_dbus_dat := cpu__o_dbus_dat
  }

/-- 组合逻辑：assign_cpu__bufreg2__i_load -/
def assign_cpu__bufreg2__i_load (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg2__i_load := s.cpu__dbus_ack
  { s with
    cpu__bufreg2__i_load := cpu__bufreg2__i_load
  }

/-- 组合逻辑：assign_cpu__bufreg2__i_dat -/
def assign_cpu__bufreg2__i_dat (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg2__i_dat := s.cpu__dbus_rdt
  { s with
    cpu__bufreg2__i_dat := cpu__bufreg2__i_dat
  }

/-- 组合逻辑：assign_cpu__bufreg2__byte_valid -/
def assign_cpu__bufreg2__byte_valid (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg2__byte_valid := (((((!(BitVec.getLsbD (s.cpu__bufreg2__i_lsb) 0) && !(BitVec.getLsbD (s.cpu__bufreg2__i_lsb) 1)) || (!(BitVec.getLsbD (s.cpu__bufreg2__i_bytecnt) 0) && !(BitVec.getLsbD (s.cpu__bufreg2__i_bytecnt) 1))) || (!(BitVec.getLsbD (s.cpu__bufreg2__i_bytecnt) 1) && !(BitVec.getLsbD (s.cpu__bufreg2__i_lsb) 1))) || (!(BitVec.getLsbD (s.cpu__bufreg2__i_bytecnt) 1) && !(BitVec.getLsbD (s.cpu__bufreg2__i_lsb) 0))) || (!(BitVec.getLsbD (s.cpu__bufreg2__i_bytecnt) 0) && !(BitVec.getLsbD (s.cpu__bufreg2__i_lsb) 1)))
  { s with
    cpu__bufreg2__byte_valid := cpu__bufreg2__byte_valid
  }

/-- 组合逻辑：assign_cpu__bufreg2__o_op_b -/
def assign_cpu__bufreg2__o_op_b (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg2__o_op_b := (if s.cpu__bufreg2__i_op_b_sel then s.cpu__bufreg2__i_rs2 else s.cpu__bufreg2__i_imm)
  { s with
    cpu__bufreg2__o_op_b := cpu__bufreg2__o_op_b
  }

/-- 组合逻辑：assign_cpu__bufreg2__shift_en -/
def assign_cpu__bufreg2__shift_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg2__shift_en := (if s.cpu__bufreg2__i_shift_op then ((s.cpu__bufreg2__i_en && s.cpu__bufreg2__i_init) && decide ((s.cpu__bufreg2__i_bytecnt).toNat = (BitVec.ofNat 2 0).toNat)) else (s.cpu__bufreg2__i_en && s.cpu__bufreg2__byte_valid))
  { s with
    cpu__bufreg2__shift_en := cpu__bufreg2__shift_en
  }

/-- 组合逻辑：assign_cpu__bufreg2__cnt_en -/
def assign_cpu__bufreg2__cnt_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg2__cnt_en := (s.cpu__bufreg2__i_shift_op && (!(s.cpu__bufreg2__i_init) || (s.cpu__bufreg2__i_cnt_done && s.cpu__bufreg2__i_sh_right)))
  { s with
    cpu__bufreg2__cnt_en := cpu__bufreg2__cnt_en
  }

/-- 组合逻辑：assign_cpu__bufreg2__cnt_next -/
def assign_cpu__bufreg2__cnt_next (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg2__cnt_next := BitVec.append (n := 1) (m := 7) (boolToBitVec (s.cpu__bufreg2__o_op_b)) (BitVec.append (n := 1) (m := 6) (boolToBitVec (BitVec.getLsbD (s.cpu__bufreg2__dhi) 7)) ((BitVec.extractLsb 5 0 (s.cpu__bufreg2__dhi) - BitVec.ofNat 6 1)))
  { s with
    cpu__bufreg2__cnt_next := cpu__bufreg2__cnt_next
  }

/-- 组合逻辑：assign_cpu__bufreg2__dat_shamt -/
def assign_cpu__bufreg2__dat_shamt (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg2__dat_shamt := (if s.cpu__bufreg2__cnt_en then s.cpu__bufreg2__cnt_next else BitVec.append (n := 1) (m := 7) (boolToBitVec (s.cpu__bufreg2__o_op_b)) (BitVec.extractLsb 7 1 (s.cpu__bufreg2__dhi)))
  { s with
    cpu__bufreg2__dat_shamt := cpu__bufreg2__dat_shamt
  }

/-- 组合逻辑：assign_cpu__bufreg2__o_sh_done -/
def assign_cpu__bufreg2__o_sh_done (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg2__o_sh_done := BitVec.getLsbD (s.cpu__bufreg2__dat_shamt) 5
  { s with
    cpu__bufreg2__o_sh_done := cpu__bufreg2__o_sh_done
  }

/-- 组合逻辑：assign_cpu__bufreg2__o_q -/
def assign_cpu__bufreg2__o_q (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg2__o_q := ((((bitVecToBool (boolToBitVec (decide ((s.cpu__bufreg2__i_lsb).toNat = (BitVec.ofNat 2 3).toNat))) && bitVecToBool (BitVec.extractLsb 24 24 (s.cpu__bufreg2__o_dat))) || (bitVecToBool (boolToBitVec (decide ((s.cpu__bufreg2__i_lsb).toNat = (BitVec.ofNat 2 2).toNat))) && bitVecToBool (BitVec.extractLsb 16 16 (s.cpu__bufreg2__o_dat)))) || (bitVecToBool (boolToBitVec (decide ((s.cpu__bufreg2__i_lsb).toNat = (BitVec.ofNat 2 1).toNat))) && bitVecToBool (BitVec.extractLsb 8 8 (s.cpu__bufreg2__o_dat)))) || (bitVecToBool (boolToBitVec (decide ((s.cpu__bufreg2__i_lsb).toNat = (BitVec.ofNat 2 0).toNat))) && bitVecToBool (BitVec.extractLsb 0 0 (s.cpu__bufreg2__o_dat))))
  { s with
    cpu__bufreg2__o_q := cpu__bufreg2__o_q
  }

/-- 组合逻辑：assign_cpu__bufreg2__o_dat -/
def assign_cpu__bufreg2__o_dat (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bufreg2__o_dat := BitVec.append (n := 8) (m := 24) (s.cpu__bufreg2__dhi) (s.cpu__bufreg2__dlo)
  { s with
    cpu__bufreg2__o_dat := cpu__bufreg2__o_dat
  }

/-- 组合逻辑：assign_cpu__ctrl__clk -/
def assign_cpu__ctrl__clk (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ctrl__clk := s.cpu__clk
  { s with
    cpu__ctrl__clk := cpu__ctrl__clk
  }

/-- 组合逻辑：assign_cpu__ctrl__i_rst -/
def assign_cpu__ctrl__i_rst (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ctrl__i_rst := s.cpu__i_rst
  { s with
    cpu__ctrl__i_rst := cpu__ctrl__i_rst
  }

/-- 组合逻辑：assign_cpu__ctrl__i_pc_en -/
def assign_cpu__ctrl__i_pc_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ctrl__i_pc_en := s.cpu__ctrl_pc_en
  { s with
    cpu__ctrl__i_pc_en := cpu__ctrl__i_pc_en
  }

/-- 组合逻辑：assign_cpu__ctrl__i_cnt12to31 -/
def assign_cpu__ctrl__i_cnt12to31 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ctrl__i_cnt12to31 := s.cpu__cnt12to31
  { s with
    cpu__ctrl__i_cnt12to31 := cpu__ctrl__i_cnt12to31
  }

/-- 组合逻辑：assign_cpu__ctrl__i_cnt0 -/
def assign_cpu__ctrl__i_cnt0 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ctrl__i_cnt0 := s.cpu__cnt0
  { s with
    cpu__ctrl__i_cnt0 := cpu__ctrl__i_cnt0
  }

/-- 组合逻辑：assign_cpu__ctrl__i_cnt1 -/
def assign_cpu__ctrl__i_cnt1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ctrl__i_cnt1 := s.cpu__cnt1
  { s with
    cpu__ctrl__i_cnt1 := cpu__ctrl__i_cnt1
  }

/-- 组合逻辑：assign_cpu__ctrl__i_cnt2 -/
def assign_cpu__ctrl__i_cnt2 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ctrl__i_cnt2 := s.cpu__cnt2
  { s with
    cpu__ctrl__i_cnt2 := cpu__ctrl__i_cnt2
  }

/-- 组合逻辑：assign_cpu__ctrl__i_jump -/
def assign_cpu__ctrl__i_jump (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ctrl__i_jump := s.cpu__jump
  { s with
    cpu__ctrl__i_jump := cpu__ctrl__i_jump
  }

/-- 组合逻辑：assign_cpu__ctrl__i_jal_or_jalr -/
def assign_cpu__ctrl__i_jal_or_jalr (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ctrl__i_jal_or_jalr := s.cpu__jal_or_jalr
  { s with
    cpu__ctrl__i_jal_or_jalr := cpu__ctrl__i_jal_or_jalr
  }

/-- 组合逻辑：assign_cpu__ctrl__i_utype -/
def assign_cpu__ctrl__i_utype (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ctrl__i_utype := s.cpu__utype
  { s with
    cpu__ctrl__i_utype := cpu__ctrl__i_utype
  }

/-- 组合逻辑：assign_cpu__ctrl__i_pc_rel -/
def assign_cpu__ctrl__i_pc_rel (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ctrl__i_pc_rel := s.cpu__pc_rel
  { s with
    cpu__ctrl__i_pc_rel := cpu__ctrl__i_pc_rel
  }

/-- 组合逻辑：assign_cpu__ctrl__i_trap -/
def assign_cpu__ctrl__i_trap (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ctrl__i_trap := (s.cpu__trap || s.cpu__mret)
  { s with
    cpu__ctrl__i_trap := cpu__ctrl__i_trap
  }

/-- 组合逻辑：assign_cpu__ctrl__i_iscomp -/
def assign_cpu__ctrl__i_iscomp (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ctrl__i_iscomp := s.cpu__iscomp
  { s with
    cpu__ctrl__i_iscomp := cpu__ctrl__i_iscomp
  }

/-- 组合逻辑：assign_cpu__ctrl__i_imm -/
def assign_cpu__ctrl__i_imm (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ctrl__i_imm := s.cpu__imm
  { s with
    cpu__ctrl__i_imm := cpu__ctrl__i_imm
  }

/-- 组合逻辑：assign_cpu__ctrl__i_buf -/
def assign_cpu__ctrl__i_buf (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ctrl__i_buf := s.cpu__bufreg_q
  { s with
    cpu__ctrl__i_buf := cpu__ctrl__i_buf
  }

/-- 组合逻辑：assign_cpu__ctrl__i_csr_pc -/
def assign_cpu__ctrl__i_csr_pc (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ctrl__i_csr_pc := s.cpu__csr_pc
  { s with
    cpu__ctrl__i_csr_pc := cpu__ctrl__i_csr_pc
  }

/-- 组合逻辑：assign_cpu__ctrl_rd -/
def assign_cpu__ctrl_rd (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ctrl_rd := s.cpu__ctrl__o_rd
  { s with
    cpu__ctrl_rd := cpu__ctrl_rd
  }

/-- 组合逻辑：assign_cpu__bad_pc -/
def assign_cpu__bad_pc (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__bad_pc := s.cpu__ctrl__o_bad_pc
  { s with
    cpu__bad_pc := cpu__bad_pc
  }

/-- 组合逻辑：assign_cpu__wb_ibus_adr -/
def assign_cpu__wb_ibus_adr (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__wb_ibus_adr := s.cpu__ctrl__o_ibus_adr
  { s with
    cpu__wb_ibus_adr := cpu__wb_ibus_adr
  }

/-- 组合逻辑：assign_cpu__ctrl__pc -/
def assign_cpu__ctrl__pc (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ctrl__pc := bitVecToBool (BitVec.extractLsb 0 0 (s.cpu__ctrl__o_ibus_adr))
  { s with
    cpu__ctrl__pc := cpu__ctrl__pc
  }

/-- 组合逻辑：assign_cpu__ctrl__plus_4 -/
def assign_cpu__ctrl__plus_4 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ctrl__plus_4 := (if s.cpu__ctrl__i_iscomp then s.cpu__ctrl__i_cnt1 else s.cpu__ctrl__i_cnt2)
  { s with
    cpu__ctrl__plus_4 := cpu__ctrl__plus_4
  }

/-- 组合逻辑：assign_cpu__ctrl__o_bad_pc -/
def assign_cpu__ctrl__o_bad_pc (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ctrl__o_bad_pc := s.cpu__ctrl__pc_plus_offset_aligned
  { s with
    cpu__ctrl__o_bad_pc := cpu__ctrl__o_bad_pc
  }

/-- 组合逻辑：assign_cpu__ctrl__pc_plus_4_cy -/
def assign_cpu__ctrl__pc_plus_4_cy (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ctrl__pc_plus_4_cy := BitVec.getLsbD (BitVec.extractLsb 1 0 ((BitVec.extractLsb 1 0 ((BitVec.extractLsb 1 0 (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (s.cpu__ctrl__pc))) + BitVec.extractLsb 1 0 (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (s.cpu__ctrl__plus_4))))) + BitVec.extractLsb 1 0 (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (s.cpu__ctrl__pc_plus_4_cy_r_w)))))) 1
  { s with
    cpu__ctrl__pc_plus_4_cy := cpu__ctrl__pc_plus_4_cy
  }

/-- 组合逻辑：assign_cpu__ctrl__pc_plus_4 -/
def assign_cpu__ctrl__pc_plus_4 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ctrl__pc_plus_4 := BitVec.getLsbD (BitVec.extractLsb 1 0 ((BitVec.extractLsb 1 0 ((BitVec.extractLsb 1 0 (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (s.cpu__ctrl__pc))) + BitVec.extractLsb 1 0 (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (s.cpu__ctrl__plus_4))))) + BitVec.extractLsb 1 0 (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (s.cpu__ctrl__pc_plus_4_cy_r_w)))))) 0
  { s with
    cpu__ctrl__pc_plus_4 := cpu__ctrl__pc_plus_4
  }

/-- 组合逻辑：assign_cpu__ctrl__new_pc -/
def assign_cpu__ctrl__new_pc (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ctrl__new_pc := (if s.cpu__ctrl__i_trap then (s.cpu__ctrl__i_csr_pc && !((s.cpu__ctrl__i_cnt0 || s.cpu__ctrl__i_cnt1))) else (if s.cpu__ctrl__i_jump then s.cpu__ctrl__pc_plus_offset_aligned else s.cpu__ctrl__pc_plus_4))
  { s with
    cpu__ctrl__new_pc := cpu__ctrl__new_pc
  }

/-- 组合逻辑：assign_cpu__ctrl__o_rd -/
def assign_cpu__ctrl__o_rd (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ctrl__o_rd := ((bitVecToBool (boolToBitVec (s.cpu__ctrl__i_utype)) && s.cpu__ctrl__pc_plus_offset_aligned) || (s.cpu__ctrl__pc_plus_4 && bitVecToBool (boolToBitVec (s.cpu__ctrl__i_jal_or_jalr))))
  { s with
    cpu__ctrl__o_rd := cpu__ctrl__o_rd
  }

/-- 组合逻辑：assign_cpu__ctrl__offset_a -/
def assign_cpu__ctrl__offset_a (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ctrl__offset_a := (bitVecToBool (boolToBitVec (s.cpu__ctrl__i_pc_rel)) && s.cpu__ctrl__pc)
  { s with
    cpu__ctrl__offset_a := cpu__ctrl__offset_a
  }

/-- 组合逻辑：assign_cpu__ctrl__offset_b -/
def assign_cpu__ctrl__offset_b (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ctrl__offset_b := (if s.cpu__ctrl__i_utype then (s.cpu__ctrl__i_imm && bitVecToBool (boolToBitVec (s.cpu__ctrl__i_cnt12to31))) else s.cpu__ctrl__i_buf)
  { s with
    cpu__ctrl__offset_b := cpu__ctrl__offset_b
  }

/-- 组合逻辑：assign_cpu__ctrl__pc_plus_offset_cy -/
def assign_cpu__ctrl__pc_plus_offset_cy (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ctrl__pc_plus_offset_cy := BitVec.getLsbD (BitVec.extractLsb 1 0 ((BitVec.extractLsb 1 0 ((BitVec.extractLsb 1 0 (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (s.cpu__ctrl__offset_a))) + BitVec.extractLsb 1 0 (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (s.cpu__ctrl__offset_b))))) + BitVec.extractLsb 1 0 (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (s.cpu__ctrl__pc_plus_offset_cy_r_w)))))) 1
  { s with
    cpu__ctrl__pc_plus_offset_cy := cpu__ctrl__pc_plus_offset_cy
  }

/-- 组合逻辑：assign_cpu__ctrl__pc_plus_offset -/
def assign_cpu__ctrl__pc_plus_offset (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ctrl__pc_plus_offset := BitVec.getLsbD (BitVec.extractLsb 1 0 ((BitVec.extractLsb 1 0 ((BitVec.extractLsb 1 0 (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (s.cpu__ctrl__offset_a))) + BitVec.extractLsb 1 0 (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (s.cpu__ctrl__offset_b))))) + BitVec.extractLsb 1 0 (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (s.cpu__ctrl__pc_plus_offset_cy_r_w)))))) 0
  { s with
    cpu__ctrl__pc_plus_offset := cpu__ctrl__pc_plus_offset
  }

/-- 组合逻辑：assign_cpu__ctrl__pc_plus_offset_aligned -/
def assign_cpu__ctrl__pc_plus_offset_aligned (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ctrl__pc_plus_offset_aligned := bitVecToBool (boolToBitVec ((s.cpu__ctrl__pc_plus_offset && !(s.cpu__ctrl__i_cnt0))))
  { s with
    cpu__ctrl__pc_plus_offset_aligned := cpu__ctrl__pc_plus_offset_aligned
  }

/-- 组合逻辑：assign_cpu__ctrl__pc_plus_offset_cy_r_w -/
def assign_cpu__ctrl__pc_plus_offset_cy_r_w (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ctrl__pc_plus_offset_cy_r_w := bitVecToBool (boolToBitVec (s.cpu__ctrl__pc_plus_offset_cy_r))
  { s with
    cpu__ctrl__pc_plus_offset_cy_r_w := cpu__ctrl__pc_plus_offset_cy_r_w
  }

/-- 组合逻辑：assign_cpu__ctrl__pc_plus_4_cy_r_w -/
def assign_cpu__ctrl__pc_plus_4_cy_r_w (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__ctrl__pc_plus_4_cy_r_w := bitVecToBool (boolToBitVec (s.cpu__ctrl__pc_plus_4_cy_r))
  { s with
    cpu__ctrl__pc_plus_4_cy_r_w := cpu__ctrl__pc_plus_4_cy_r_w
  }

/-- 组合逻辑：assign_cpu__alu__clk -/
def assign_cpu__alu__clk (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__alu__clk := s.cpu__clk
  { s with
    cpu__alu__clk := cpu__alu__clk
  }

/-- 组合逻辑：assign_cpu__alu__i_en -/
def assign_cpu__alu__i_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__alu__i_en := s.cpu__cnt_en
  { s with
    cpu__alu__i_en := cpu__alu__i_en
  }

/-- 组合逻辑：assign_cpu__alu__i_cnt0 -/
def assign_cpu__alu__i_cnt0 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__alu__i_cnt0 := s.cpu__cnt0
  { s with
    cpu__alu__i_cnt0 := cpu__alu__i_cnt0
  }

/-- 组合逻辑：assign_cpu__alu_cmp -/
def assign_cpu__alu_cmp (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__alu_cmp := s.cpu__alu__o_cmp
  { s with
    cpu__alu_cmp := cpu__alu_cmp
  }

/-- 组合逻辑：assign_cpu__alu__i_sub -/
def assign_cpu__alu__i_sub (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__alu__i_sub := s.cpu__alu_sub
  { s with
    cpu__alu__i_sub := cpu__alu__i_sub
  }

/-- 组合逻辑：assign_cpu__alu__i_bool_op -/
def assign_cpu__alu__i_bool_op (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__alu__i_bool_op := s.cpu__alu_bool_op
  { s with
    cpu__alu__i_bool_op := cpu__alu__i_bool_op
  }

/-- 组合逻辑：assign_cpu__alu__i_cmp_eq -/
def assign_cpu__alu__i_cmp_eq (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__alu__i_cmp_eq := s.cpu__alu_cmp_eq
  { s with
    cpu__alu__i_cmp_eq := cpu__alu__i_cmp_eq
  }

/-- 组合逻辑：assign_cpu__alu__i_cmp_sig -/
def assign_cpu__alu__i_cmp_sig (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__alu__i_cmp_sig := s.cpu__alu_cmp_sig
  { s with
    cpu__alu__i_cmp_sig := cpu__alu__i_cmp_sig
  }

/-- 组合逻辑：assign_cpu__alu__i_rd_sel -/
def assign_cpu__alu__i_rd_sel (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__alu__i_rd_sel := s.cpu__alu_rd_sel
  { s with
    cpu__alu__i_rd_sel := cpu__alu__i_rd_sel
  }

/-- 组合逻辑：assign_cpu__alu__i_rs1 -/
def assign_cpu__alu__i_rs1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__alu__i_rs1 := s.cpu__rs1
  { s with
    cpu__alu__i_rs1 := cpu__alu__i_rs1
  }

/-- 组合逻辑：assign_cpu__alu__i_op_b -/
def assign_cpu__alu__i_op_b (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__alu__i_op_b := s.cpu__op_b
  { s with
    cpu__alu__i_op_b := cpu__alu__i_op_b
  }

/-- 组合逻辑：assign_cpu__alu__i_buf -/
def assign_cpu__alu__i_buf (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__alu__i_buf := s.cpu__bufreg_q
  { s with
    cpu__alu__i_buf := cpu__alu__i_buf
  }

/-- 组合逻辑：assign_cpu__alu_rd -/
def assign_cpu__alu_rd (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__alu_rd := s.cpu__alu__o_rd
  { s with
    cpu__alu_rd := cpu__alu_rd
  }

/-- 组合逻辑：assign_cpu__alu__rs1_sx -/
def assign_cpu__alu__rs1_sx (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__alu__rs1_sx := (s.cpu__alu__i_rs1 && s.cpu__alu__i_cmp_sig)
  { s with
    cpu__alu__rs1_sx := cpu__alu__rs1_sx
  }

/-- 组合逻辑：assign_cpu__alu__op_b_sx -/
def assign_cpu__alu__op_b_sx (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__alu__op_b_sx := (s.cpu__alu__i_op_b && s.cpu__alu__i_cmp_sig)
  { s with
    cpu__alu__op_b_sx := cpu__alu__op_b_sx
  }

/-- 组合逻辑：assign_cpu__alu__add_b -/
def assign_cpu__alu__add_b (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__alu__add_b := Bool.xor (s.cpu__alu__i_op_b) (bitVecToBool (boolToBitVec (s.cpu__alu__i_sub)))
  { s with
    cpu__alu__add_b := cpu__alu__add_b
  }

/-- 组合逻辑：assign_cpu__alu__add_cy -/
def assign_cpu__alu__add_cy (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__alu__add_cy := BitVec.getLsbD (BitVec.extractLsb 1 0 ((BitVec.extractLsb 1 0 ((BitVec.extractLsb 1 0 (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (s.cpu__alu__i_rs1))) + BitVec.extractLsb 1 0 (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (s.cpu__alu__add_b))))) + BitVec.extractLsb 1 0 (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (s.cpu__alu__add_cy_r)))))) 1
  { s with
    cpu__alu__add_cy := cpu__alu__add_cy
  }

/-- 组合逻辑：assign_cpu__alu__result_add -/
def assign_cpu__alu__result_add (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__alu__result_add := BitVec.getLsbD (BitVec.extractLsb 1 0 ((BitVec.extractLsb 1 0 ((BitVec.extractLsb 1 0 (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (s.cpu__alu__i_rs1))) + BitVec.extractLsb 1 0 (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (s.cpu__alu__add_b))))) + BitVec.extractLsb 1 0 (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (s.cpu__alu__add_cy_r)))))) 0
  { s with
    cpu__alu__result_add := cpu__alu__result_add
  }

/-- 组合逻辑：assign_cpu__alu__result_lt -/
def assign_cpu__alu__result_lt (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__alu__result_lt := bitVecToBool (boolToBitVec (bitVecToBool (boolToBitVec (s.cpu__alu__rs1_sx) + boolToBitVec (!(s.cpu__alu__op_b_sx)))) + boolToBitVec (s.cpu__alu__add_cy))
  { s with
    cpu__alu__result_lt := cpu__alu__result_lt
  }

/-- 组合逻辑：assign_cpu__alu__result_eq -/
def assign_cpu__alu__result_eq (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__alu__result_eq := (!(s.cpu__alu__result_add) && (s.cpu__alu__cmp_r || s.cpu__alu__i_cnt0))
  { s with
    cpu__alu__result_eq := cpu__alu__result_eq
  }

/-- 组合逻辑：assign_cpu__alu__o_cmp -/
def assign_cpu__alu__o_cmp (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__alu__o_cmp := (if s.cpu__alu__i_cmp_eq then s.cpu__alu__result_eq else s.cpu__alu__result_lt)
  { s with
    cpu__alu__o_cmp := cpu__alu__o_cmp
  }

/-- 组合逻辑：assign_cpu__alu__result_bool -/
def assign_cpu__alu__result_bool (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__alu__result_bool := ((Bool.xor (s.cpu__alu__i_rs1) (s.cpu__alu__i_op_b) && !(bitVecToBool (boolToBitVec (BitVec.getLsbD (s.cpu__alu__i_bool_op) 0)))) || ((bitVecToBool (boolToBitVec (BitVec.getLsbD (s.cpu__alu__i_bool_op) 1)) && s.cpu__alu__i_op_b) && s.cpu__alu__i_rs1))
  { s with
    cpu__alu__result_bool := cpu__alu__result_bool
  }

/-- 组合逻辑：assign_cpu__alu__result_slt -/
def assign_cpu__alu__result_slt (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__alu__result_slt := bitVecToBool (boolToBitVec ((s.cpu__alu__cmp_r && s.cpu__alu__i_cnt0)))
  { s with
    cpu__alu__result_slt := cpu__alu__result_slt
  }

/-- 组合逻辑：assign_cpu__alu__o_rd -/
def assign_cpu__alu__o_rd (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__alu__o_rd := (((s.cpu__alu__i_buf || (bitVecToBool (boolToBitVec (BitVec.getLsbD (s.cpu__alu__i_rd_sel) 0)) && s.cpu__alu__result_add)) || (bitVecToBool (boolToBitVec (BitVec.getLsbD (s.cpu__alu__i_rd_sel) 1)) && s.cpu__alu__result_slt)) || (bitVecToBool (boolToBitVec (BitVec.getLsbD (s.cpu__alu__i_rd_sel) 2)) && s.cpu__alu__result_bool))
  { s with
    cpu__alu__o_rd := cpu__alu__o_rd
  }

/-- 组合逻辑：assign_cpu__rf_if__i_cnt_en -/
def assign_cpu__rf_if__i_cnt_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__i_cnt_en := s.cpu__cnt_en
  { s with
    cpu__rf_if__i_cnt_en := cpu__rf_if__i_cnt_en
  }

/-- 组合逻辑：assign_cpu__o_wreg0 -/
def assign_cpu__o_wreg0 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__o_wreg0 := s.cpu__rf_if__o_wreg0
  { s with
    cpu__o_wreg0 := cpu__o_wreg0
  }

/-- 组合逻辑：assign_cpu__o_wreg1 -/
def assign_cpu__o_wreg1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__o_wreg1 := s.cpu__rf_if__o_wreg1
  { s with
    cpu__o_wreg1 := cpu__o_wreg1
  }

/-- 组合逻辑：assign_cpu__o_wen0 -/
def assign_cpu__o_wen0 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__o_wen0 := s.cpu__rf_if__o_wen0
  { s with
    cpu__o_wen0 := cpu__o_wen0
  }

/-- 组合逻辑：assign_cpu__o_wen1 -/
def assign_cpu__o_wen1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__o_wen1 := s.cpu__rf_if__o_wen1
  { s with
    cpu__o_wen1 := cpu__o_wen1
  }

/-- 组合逻辑：assign_cpu__o_wdata0 -/
def assign_cpu__o_wdata0 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__o_wdata0 := s.cpu__rf_if__o_wdata0
  { s with
    cpu__o_wdata0 := cpu__o_wdata0
  }

/-- 组合逻辑：assign_cpu__o_wdata1 -/
def assign_cpu__o_wdata1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__o_wdata1 := s.cpu__rf_if__o_wdata1
  { s with
    cpu__o_wdata1 := cpu__o_wdata1
  }

/-- 组合逻辑：assign_cpu__o_rreg0 -/
def assign_cpu__o_rreg0 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__o_rreg0 := s.cpu__rf_if__o_rreg0
  { s with
    cpu__o_rreg0 := cpu__o_rreg0
  }

/-- 组合逻辑：assign_cpu__o_rreg1 -/
def assign_cpu__o_rreg1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__o_rreg1 := s.cpu__rf_if__o_rreg1
  { s with
    cpu__o_rreg1 := cpu__o_rreg1
  }

/-- 组合逻辑：assign_cpu__rf_if__i_rdata0 -/
def assign_cpu__rf_if__i_rdata0 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__i_rdata0 := s.cpu__i_rdata0
  { s with
    cpu__rf_if__i_rdata0 := cpu__rf_if__i_rdata0
  }

/-- 组合逻辑：assign_cpu__rf_if__i_rdata1 -/
def assign_cpu__rf_if__i_rdata1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__i_rdata1 := s.cpu__i_rdata1
  { s with
    cpu__rf_if__i_rdata1 := cpu__rf_if__i_rdata1
  }

/-- 组合逻辑：assign_cpu__rf_if__i_trap -/
def assign_cpu__rf_if__i_trap (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__i_trap := s.cpu__trap
  { s with
    cpu__rf_if__i_trap := cpu__rf_if__i_trap
  }

/-- 组合逻辑：assign_cpu__rf_if__i_mret -/
def assign_cpu__rf_if__i_mret (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__i_mret := s.cpu__mret
  { s with
    cpu__rf_if__i_mret := cpu__rf_if__i_mret
  }

/-- 组合逻辑：assign_cpu__rf_if__i_mepc -/
def assign_cpu__rf_if__i_mepc (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__i_mepc := bitVecToBool (BitVec.extractLsb 0 0 (s.cpu__wb_ibus_adr))
  { s with
    cpu__rf_if__i_mepc := cpu__rf_if__i_mepc
  }

/-- 组合逻辑：assign_cpu__rf_if__i_mtval_pc -/
def assign_cpu__rf_if__i_mtval_pc (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__i_mtval_pc := s.cpu__mtval_pc
  { s with
    cpu__rf_if__i_mtval_pc := cpu__rf_if__i_mtval_pc
  }

/-- 组合逻辑：assign_cpu__rf_if__i_bufreg_q -/
def assign_cpu__rf_if__i_bufreg_q (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__i_bufreg_q := s.cpu__bufreg_q
  { s with
    cpu__rf_if__i_bufreg_q := cpu__rf_if__i_bufreg_q
  }

/-- 组合逻辑：assign_cpu__rf_if__i_bad_pc -/
def assign_cpu__rf_if__i_bad_pc (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__i_bad_pc := s.cpu__bad_pc
  { s with
    cpu__rf_if__i_bad_pc := cpu__rf_if__i_bad_pc
  }

/-- 组合逻辑：assign_cpu__csr_pc -/
def assign_cpu__csr_pc (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__csr_pc := s.cpu__rf_if__o_csr_pc
  { s with
    cpu__csr_pc := cpu__csr_pc
  }

/-- 组合逻辑：assign_cpu__rf_if__i_csr_en -/
def assign_cpu__rf_if__i_csr_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__i_csr_en := s.cpu__csr_en
  { s with
    cpu__rf_if__i_csr_en := cpu__rf_if__i_csr_en
  }

/-- 组合逻辑：assign_cpu__rf_if__i_csr_addr -/
def assign_cpu__rf_if__i_csr_addr (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__i_csr_addr := s.cpu__csr_addr
  { s with
    cpu__rf_if__i_csr_addr := cpu__rf_if__i_csr_addr
  }

/-- 组合逻辑：assign_cpu__rf_if__i_csr -/
def assign_cpu__rf_if__i_csr (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__i_csr := s.cpu__csr_in
  { s with
    cpu__rf_if__i_csr := cpu__rf_if__i_csr
  }

/-- 组合逻辑：assign_cpu__rf_csr_out -/
def assign_cpu__rf_csr_out (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_csr_out := s.cpu__rf_if__o_csr
  { s with
    cpu__rf_csr_out := cpu__rf_csr_out
  }

/-- 组合逻辑：assign_cpu__rf_if__i_rd_wen -/
def assign_cpu__rf_if__i_rd_wen (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__i_rd_wen := s.cpu__rd_en
  { s with
    cpu__rf_if__i_rd_wen := cpu__rf_if__i_rd_wen
  }

/-- 组合逻辑：assign_cpu__rf_if__i_rd_waddr -/
def assign_cpu__rf_if__i_rd_waddr (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__i_rd_waddr := s.cpu__rd_addr
  { s with
    cpu__rf_if__i_rd_waddr := cpu__rf_if__i_rd_waddr
  }

/-- 组合逻辑：assign_cpu__rf_if__i_ctrl_rd -/
def assign_cpu__rf_if__i_ctrl_rd (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__i_ctrl_rd := s.cpu__ctrl_rd
  { s with
    cpu__rf_if__i_ctrl_rd := cpu__rf_if__i_ctrl_rd
  }

/-- 组合逻辑：assign_cpu__rf_if__i_alu_rd -/
def assign_cpu__rf_if__i_alu_rd (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__i_alu_rd := s.cpu__alu_rd
  { s with
    cpu__rf_if__i_alu_rd := cpu__rf_if__i_alu_rd
  }

/-- 组合逻辑：assign_cpu__rf_if__i_rd_alu_en -/
def assign_cpu__rf_if__i_rd_alu_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__i_rd_alu_en := s.cpu__rd_alu_en
  { s with
    cpu__rf_if__i_rd_alu_en := cpu__rf_if__i_rd_alu_en
  }

/-- 组合逻辑：assign_cpu__rf_if__i_csr_rd -/
def assign_cpu__rf_if__i_csr_rd (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__i_csr_rd := s.cpu__csr_rd
  { s with
    cpu__rf_if__i_csr_rd := cpu__rf_if__i_csr_rd
  }

/-- 组合逻辑：assign_cpu__rf_if__i_rd_csr_en -/
def assign_cpu__rf_if__i_rd_csr_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__i_rd_csr_en := s.cpu__rd_csr_en
  { s with
    cpu__rf_if__i_rd_csr_en := cpu__rf_if__i_rd_csr_en
  }

/-- 组合逻辑：assign_cpu__rf_if__i_mem_rd -/
def assign_cpu__rf_if__i_mem_rd (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__i_mem_rd := s.cpu__mem_rd
  { s with
    cpu__rf_if__i_mem_rd := cpu__rf_if__i_mem_rd
  }

/-- 组合逻辑：assign_cpu__rf_if__i_rd_mem_en -/
def assign_cpu__rf_if__i_rd_mem_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__i_rd_mem_en := s.cpu__rd_mem_en
  { s with
    cpu__rf_if__i_rd_mem_en := cpu__rf_if__i_rd_mem_en
  }

/-- 组合逻辑：assign_cpu__rf_if__i_rs1_raddr -/
def assign_cpu__rf_if__i_rs1_raddr (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__i_rs1_raddr := s.cpu__rs1_addr
  { s with
    cpu__rf_if__i_rs1_raddr := cpu__rf_if__i_rs1_raddr
  }

/-- 组合逻辑：assign_cpu__rs1 -/
def assign_cpu__rs1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rs1 := s.cpu__rf_if__o_rs1
  { s with
    cpu__rs1 := cpu__rs1
  }

/-- 组合逻辑：assign_cpu__rf_if__i_rs2_raddr -/
def assign_cpu__rf_if__i_rs2_raddr (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__i_rs2_raddr := s.cpu__rs2_addr
  { s with
    cpu__rf_if__i_rs2_raddr := cpu__rf_if__i_rs2_raddr
  }

/-- 组合逻辑：assign_cpu__rs2 -/
def assign_cpu__rs2 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rs2 := s.cpu__rf_if__o_rs2
  { s with
    cpu__rs2 := cpu__rs2
  }

/-- 组合逻辑：assign_cpu__rf_if__rd_wen -/
def assign_cpu__rf_if__rd_wen (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__rd_wen := (s.cpu__rf_if__i_rd_wen && bvNonzero (s.cpu__rf_if__i_rd_waddr))
  { s with
    cpu__rf_if__rd_wen := cpu__rf_if__rd_wen
  }

/-- 组合逻辑：assign_cpu__rf_if__gen_csr__rd -/
def assign_cpu__rf_if__gen_csr__rd (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__gen_csr__rd := ((((bitVecToBool (boolToBitVec (s.cpu__rf_if__i_rd_alu_en)) && s.cpu__rf_if__i_alu_rd) || (bitVecToBool (boolToBitVec (s.cpu__rf_if__i_rd_csr_en)) && s.cpu__rf_if__i_csr_rd)) || (bitVecToBool (boolToBitVec (s.cpu__rf_if__i_rd_mem_en)) && s.cpu__rf_if__i_mem_rd)) || s.cpu__rf_if__i_ctrl_rd)
  { s with
    cpu__rf_if__gen_csr__rd := cpu__rf_if__gen_csr__rd
  }

/-- 组合逻辑：assign_cpu__rf_if__gen_csr__mtval -/
def assign_cpu__rf_if__gen_csr__mtval (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__gen_csr__mtval := (if s.cpu__rf_if__i_mtval_pc then s.cpu__rf_if__i_bad_pc else s.cpu__rf_if__i_bufreg_q)
  { s with
    cpu__rf_if__gen_csr__mtval := cpu__rf_if__gen_csr__mtval
  }

/-- 组合逻辑：assign_cpu__rf_if__o_wdata0 -/
def assign_cpu__rf_if__o_wdata0 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__o_wdata0 := (if s.cpu__rf_if__i_trap then s.cpu__rf_if__gen_csr__mtval else s.cpu__rf_if__gen_csr__rd)
  { s with
    cpu__rf_if__o_wdata0 := cpu__rf_if__o_wdata0
  }

/-- 组合逻辑：assign_cpu__rf_if__o_wdata1 -/
def assign_cpu__rf_if__o_wdata1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__o_wdata1 := (if s.cpu__rf_if__i_trap then s.cpu__rf_if__i_mepc else s.cpu__rf_if__i_csr)
  { s with
    cpu__rf_if__o_wdata1 := cpu__rf_if__o_wdata1
  }

/-- 组合逻辑：assign_cpu__rf_if__o_wreg0 -/
def assign_cpu__rf_if__o_wreg0 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__o_wreg0 := (if s.cpu__rf_if__i_trap then BitVec.ofNat 6 35 else BitVec.append (n := 1) (m := 5) (boolToBitVec (false)) (s.cpu__rf_if__i_rd_waddr))
  { s with
    cpu__rf_if__o_wreg0 := cpu__rf_if__o_wreg0
  }

/-- 组合逻辑：assign_cpu__rf_if__o_wreg1 -/
def assign_cpu__rf_if__o_wreg1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__o_wreg1 := (if s.cpu__rf_if__i_trap then BitVec.ofNat 6 34 else BitVec.append (n := 4) (m := 2) (BitVec.ofNat 4 8) (s.cpu__rf_if__i_csr_addr))
  { s with
    cpu__rf_if__o_wreg1 := cpu__rf_if__o_wreg1
  }

/-- 组合逻辑：assign_cpu__rf_if__o_wen0 -/
def assign_cpu__rf_if__o_wen0 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__o_wen0 := (s.cpu__rf_if__i_cnt_en && (s.cpu__rf_if__i_trap || s.cpu__rf_if__rd_wen))
  { s with
    cpu__rf_if__o_wen0 := cpu__rf_if__o_wen0
  }

/-- 组合逻辑：assign_cpu__rf_if__o_wen1 -/
def assign_cpu__rf_if__o_wen1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__o_wen1 := (s.cpu__rf_if__i_cnt_en && (s.cpu__rf_if__i_trap || s.cpu__rf_if__i_csr_en))
  { s with
    cpu__rf_if__o_wen1 := cpu__rf_if__o_wen1
  }

/-- 组合逻辑：assign_cpu__rf_if__o_rreg0 -/
def assign_cpu__rf_if__o_rreg0 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__o_rreg0 := BitVec.append (n := 1) (m := 5) (boolToBitVec (false)) (s.cpu__rf_if__i_rs1_raddr)
  { s with
    cpu__rf_if__o_rreg0 := cpu__rf_if__o_rreg0
  }

/-- 组合逻辑：assign_cpu__rf_if__gen_csr__sel_rs2 -/
def assign_cpu__rf_if__gen_csr__sel_rs2 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__gen_csr__sel_rs2 := !(((s.cpu__rf_if__i_trap || s.cpu__rf_if__i_mret) || s.cpu__rf_if__i_csr_en))
  { s with
    cpu__rf_if__gen_csr__sel_rs2 := cpu__rf_if__gen_csr__sel_rs2
  }

/-- 组合逻辑：assign_cpu__rf_if__o_rreg1 -/
def assign_cpu__rf_if__o_rreg1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__o_rreg1 := BitVec.append (n := 1) (m := 5) (boolToBitVec (!(s.cpu__rf_if__gen_csr__sel_rs2))) (BitVec.append (n := 3) (m := 2) ((BitVec.extractLsb 4 2 (s.cpu__rf_if__i_rs2_raddr) &&& BitVec.append (n := 1) (m := 2) (boolToBitVec (s.cpu__rf_if__gen_csr__sel_rs2)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.cpu__rf_if__gen_csr__sel_rs2)) (boolToBitVec (s.cpu__rf_if__gen_csr__sel_rs2))))) ((((BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (s.cpu__rf_if__i_trap)) ||| BitVec.append (n := 1) (m := 1) (boolToBitVec (s.cpu__rf_if__i_mret)) (boolToBitVec (false))) ||| (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.cpu__rf_if__i_csr_en)) (boolToBitVec (s.cpu__rf_if__i_csr_en)) &&& s.cpu__rf_if__i_csr_addr)) ||| (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.cpu__rf_if__gen_csr__sel_rs2)) (boolToBitVec (s.cpu__rf_if__gen_csr__sel_rs2)) &&& BitVec.extractLsb 1 0 (s.cpu__rf_if__i_rs2_raddr)))))
  { s with
    cpu__rf_if__o_rreg1 := cpu__rf_if__o_rreg1
  }

/-- 组合逻辑：assign_cpu__rf_if__o_rs1 -/
def assign_cpu__rf_if__o_rs1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__o_rs1 := s.cpu__rf_if__i_rdata0
  { s with
    cpu__rf_if__o_rs1 := cpu__rf_if__o_rs1
  }

/-- 组合逻辑：assign_cpu__rf_if__o_rs2 -/
def assign_cpu__rf_if__o_rs2 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__o_rs2 := s.cpu__rf_if__i_rdata1
  { s with
    cpu__rf_if__o_rs2 := cpu__rf_if__o_rs2
  }

/-- 组合逻辑：assign_cpu__rf_if__o_csr -/
def assign_cpu__rf_if__o_csr (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__o_csr := (s.cpu__rf_if__i_rdata1 && bitVecToBool (boolToBitVec (s.cpu__rf_if__i_csr_en)))
  { s with
    cpu__rf_if__o_csr := cpu__rf_if__o_csr
  }

/-- 组合逻辑：assign_cpu__rf_if__o_csr_pc -/
def assign_cpu__rf_if__o_csr_pc (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__rf_if__o_csr_pc := s.cpu__rf_if__i_rdata1
  { s with
    cpu__rf_if__o_csr_pc := cpu__rf_if__o_csr_pc
  }

/-- 组合逻辑：assign_cpu__mem_if__i_clk -/
def assign_cpu__mem_if__i_clk (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__mem_if__i_clk := s.cpu__clk
  { s with
    cpu__mem_if__i_clk := cpu__mem_if__i_clk
  }

/-- 组合逻辑：assign_cpu__mem_if__i_bytecnt -/
def assign_cpu__mem_if__i_bytecnt (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__mem_if__i_bytecnt := s.cpu__mem_bytecnt
  { s with
    cpu__mem_if__i_bytecnt := cpu__mem_if__i_bytecnt
  }

/-- 组合逻辑：assign_cpu__mem_if__i_lsb -/
def assign_cpu__mem_if__i_lsb (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__mem_if__i_lsb := s.cpu__lsb
  { s with
    cpu__mem_if__i_lsb := cpu__mem_if__i_lsb
  }

/-- 组合逻辑：assign_cpu__mem_misalign -/
def assign_cpu__mem_misalign (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__mem_misalign := s.cpu__mem_if__o_misalign
  { s with
    cpu__mem_misalign := cpu__mem_misalign
  }

/-- 组合逻辑：assign_cpu__mem_if__i_signed -/
def assign_cpu__mem_if__i_signed (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__mem_if__i_signed := s.cpu__mem_signed
  { s with
    cpu__mem_if__i_signed := cpu__mem_if__i_signed
  }

/-- 组合逻辑：assign_cpu__mem_if__i_word -/
def assign_cpu__mem_if__i_word (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__mem_if__i_word := s.cpu__mem_word
  { s with
    cpu__mem_if__i_word := cpu__mem_if__i_word
  }

/-- 组合逻辑：assign_cpu__mem_if__i_half -/
def assign_cpu__mem_if__i_half (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__mem_if__i_half := s.cpu__mem_half
  { s with
    cpu__mem_if__i_half := cpu__mem_if__i_half
  }

/-- 组合逻辑：assign_cpu__mem_if__i_mdu_op -/
def assign_cpu__mem_if__i_mdu_op (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__mem_if__i_mdu_op := s.cpu__mdu_op
  { s with
    cpu__mem_if__i_mdu_op := cpu__mem_if__i_mdu_op
  }

/-- 组合逻辑：assign_cpu__mem_if__i_bufreg2_q -/
def assign_cpu__mem_if__i_bufreg2_q (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__mem_if__i_bufreg2_q := s.cpu__bufreg2_q
  { s with
    cpu__mem_if__i_bufreg2_q := cpu__mem_if__i_bufreg2_q
  }

/-- 组合逻辑：assign_cpu__mem_rd -/
def assign_cpu__mem_rd (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__mem_rd := s.cpu__mem_if__o_rd
  { s with
    cpu__mem_rd := cpu__mem_rd
  }

/-- 组合逻辑：assign_cpu__o_dbus_sel -/
def assign_cpu__o_dbus_sel (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__o_dbus_sel := s.cpu__mem_if__o_wb_sel
  { s with
    cpu__o_dbus_sel := cpu__o_dbus_sel
  }

/-- 组合逻辑：assign_cpu__mem_if__dat_valid -/
def assign_cpu__mem_if__dat_valid (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__mem_if__dat_valid := (((s.cpu__mem_if__i_mdu_op || s.cpu__mem_if__i_word) || decide ((s.cpu__mem_if__i_bytecnt).toNat = (BitVec.ofNat 2 0).toNat)) || (s.cpu__mem_if__i_half && !(BitVec.getLsbD (s.cpu__mem_if__i_bytecnt) 1)))
  { s with
    cpu__mem_if__dat_valid := cpu__mem_if__dat_valid
  }

/-- 组合逻辑：assign_cpu__mem_if__o_rd -/
def assign_cpu__mem_if__o_rd (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__mem_if__o_rd := (if s.cpu__mem_if__dat_valid then s.cpu__mem_if__i_bufreg2_q else bitVecToBool (boolToBitVec ((s.cpu__mem_if__i_signed && s.cpu__mem_if__signbit))))
  { s with
    cpu__mem_if__o_rd := cpu__mem_if__o_rd
  }

/-- 组合逻辑：assign_cpu__mem_if__o_wb_sel -/
def assign_cpu__mem_if__o_wb_sel (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__mem_if__o_wb_sel := BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (((decide ((s.cpu__mem_if__i_lsb).toNat = (BitVec.ofNat 2 3).toNat) || s.cpu__mem_if__i_word) || (s.cpu__mem_if__i_half && BitVec.getLsbD (s.cpu__mem_if__i_lsb) 1)))) (boolToBitVec ((decide ((s.cpu__mem_if__i_lsb).toNat = (BitVec.ofNat 2 2).toNat) || s.cpu__mem_if__i_word)))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (((decide ((s.cpu__mem_if__i_lsb).toNat = (BitVec.ofNat 2 1).toNat) || s.cpu__mem_if__i_word) || (s.cpu__mem_if__i_half && !(BitVec.getLsbD (s.cpu__mem_if__i_lsb) 1))))) (boolToBitVec (decide ((s.cpu__mem_if__i_lsb).toNat = (BitVec.ofNat 2 0).toNat))))
  { s with
    cpu__mem_if__o_wb_sel := cpu__mem_if__o_wb_sel
  }

/-- 组合逻辑：assign_cpu__mem_if__o_misalign -/
def assign_cpu__mem_if__o_misalign (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__mem_if__o_misalign := (true && ((BitVec.getLsbD (s.cpu__mem_if__i_lsb) 0 && (s.cpu__mem_if__i_word || s.cpu__mem_if__i_half)) || (BitVec.getLsbD (s.cpu__mem_if__i_lsb) 1 && s.cpu__mem_if__i_word)))
  { s with
    cpu__mem_if__o_misalign := cpu__mem_if__o_misalign
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__i_clk -/
def assign_cpu__gen_csr__csr__i_clk (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__i_clk := s.cpu__clk
  { s with
    cpu__gen_csr__csr__i_clk := cpu__gen_csr__csr__i_clk
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__i_rst -/
def assign_cpu__gen_csr__csr__i_rst (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__i_rst := s.cpu__i_rst
  { s with
    cpu__gen_csr__csr__i_rst := cpu__gen_csr__csr__i_rst
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__i_trig_irq -/
def assign_cpu__gen_csr__csr__i_trig_irq (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__i_trig_irq := s.cpu__wb_ibus_ack
  { s with
    cpu__gen_csr__csr__i_trig_irq := cpu__gen_csr__csr__i_trig_irq
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__i_en -/
def assign_cpu__gen_csr__csr__i_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__i_en := s.cpu__cnt_en
  { s with
    cpu__gen_csr__csr__i_en := cpu__gen_csr__csr__i_en
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__i_cnt0to3 -/
def assign_cpu__gen_csr__csr__i_cnt0to3 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__i_cnt0to3 := s.cpu__cnt0to3
  { s with
    cpu__gen_csr__csr__i_cnt0to3 := cpu__gen_csr__csr__i_cnt0to3
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__i_cnt3 -/
def assign_cpu__gen_csr__csr__i_cnt3 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__i_cnt3 := s.cpu__cnt3
  { s with
    cpu__gen_csr__csr__i_cnt3 := cpu__gen_csr__csr__i_cnt3
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__i_cnt7 -/
def assign_cpu__gen_csr__csr__i_cnt7 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__i_cnt7 := s.cpu__cnt7
  { s with
    cpu__gen_csr__csr__i_cnt7 := cpu__gen_csr__csr__i_cnt7
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__i_cnt11 -/
def assign_cpu__gen_csr__csr__i_cnt11 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__i_cnt11 := s.cpu__cnt11
  { s with
    cpu__gen_csr__csr__i_cnt11 := cpu__gen_csr__csr__i_cnt11
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__i_cnt12 -/
def assign_cpu__gen_csr__csr__i_cnt12 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__i_cnt12 := s.cpu__cnt12
  { s with
    cpu__gen_csr__csr__i_cnt12 := cpu__gen_csr__csr__i_cnt12
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__i_cnt_done -/
def assign_cpu__gen_csr__csr__i_cnt_done (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__i_cnt_done := s.cpu__cnt_done
  { s with
    cpu__gen_csr__csr__i_cnt_done := cpu__gen_csr__csr__i_cnt_done
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__i_mem_op -/
def assign_cpu__gen_csr__csr__i_mem_op (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__i_mem_op := !(s.cpu__mtval_pc)
  { s with
    cpu__gen_csr__csr__i_mem_op := cpu__gen_csr__csr__i_mem_op
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__i_mtip -/
def assign_cpu__gen_csr__csr__i_mtip (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__i_mtip := s.cpu__i_timer_irq
  { s with
    cpu__gen_csr__csr__i_mtip := cpu__gen_csr__csr__i_mtip
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__i_trap -/
def assign_cpu__gen_csr__csr__i_trap (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__i_trap := s.cpu__trap
  { s with
    cpu__gen_csr__csr__i_trap := cpu__gen_csr__csr__i_trap
  }

/-- 组合逻辑：assign_cpu__new_irq -/
def assign_cpu__new_irq (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__new_irq := s.cpu__gen_csr__csr__o_new_irq
  { s with
    cpu__new_irq := cpu__new_irq
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__i_e_op -/
def assign_cpu__gen_csr__csr__i_e_op (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__i_e_op := s.cpu__e_op
  { s with
    cpu__gen_csr__csr__i_e_op := cpu__gen_csr__csr__i_e_op
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__i_ebreak -/
def assign_cpu__gen_csr__csr__i_ebreak (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__i_ebreak := s.cpu__ebreak
  { s with
    cpu__gen_csr__csr__i_ebreak := cpu__gen_csr__csr__i_ebreak
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__i_mem_cmd -/
def assign_cpu__gen_csr__csr__i_mem_cmd (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__i_mem_cmd := s.cpu__o_dbus_we
  { s with
    cpu__gen_csr__csr__i_mem_cmd := cpu__gen_csr__csr__i_mem_cmd
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__i_mstatus_en -/
def assign_cpu__gen_csr__csr__i_mstatus_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__i_mstatus_en := s.cpu__csr_mstatus_en
  { s with
    cpu__gen_csr__csr__i_mstatus_en := cpu__gen_csr__csr__i_mstatus_en
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__i_mie_en -/
def assign_cpu__gen_csr__csr__i_mie_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__i_mie_en := s.cpu__csr_mie_en
  { s with
    cpu__gen_csr__csr__i_mie_en := cpu__gen_csr__csr__i_mie_en
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__i_mcause_en -/
def assign_cpu__gen_csr__csr__i_mcause_en (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__i_mcause_en := s.cpu__csr_mcause_en
  { s with
    cpu__gen_csr__csr__i_mcause_en := cpu__gen_csr__csr__i_mcause_en
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__i_csr_source -/
def assign_cpu__gen_csr__csr__i_csr_source (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__i_csr_source := s.cpu__csr_source
  { s with
    cpu__gen_csr__csr__i_csr_source := cpu__gen_csr__csr__i_csr_source
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__i_mret -/
def assign_cpu__gen_csr__csr__i_mret (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__i_mret := s.cpu__mret
  { s with
    cpu__gen_csr__csr__i_mret := cpu__gen_csr__csr__i_mret
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__i_csr_d_sel -/
def assign_cpu__gen_csr__csr__i_csr_d_sel (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__i_csr_d_sel := s.cpu__csr_d_sel
  { s with
    cpu__gen_csr__csr__i_csr_d_sel := cpu__gen_csr__csr__i_csr_d_sel
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__i_rf_csr_out -/
def assign_cpu__gen_csr__csr__i_rf_csr_out (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__i_rf_csr_out := s.cpu__rf_csr_out
  { s with
    cpu__gen_csr__csr__i_rf_csr_out := cpu__gen_csr__csr__i_rf_csr_out
  }

/-- 组合逻辑：assign_cpu__csr_in -/
def assign_cpu__csr_in (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__csr_in := s.cpu__gen_csr__csr__o_csr_in
  { s with
    cpu__csr_in := cpu__csr_in
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__i_csr_imm -/
def assign_cpu__gen_csr__csr__i_csr_imm (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__i_csr_imm := s.cpu__csr_imm
  { s with
    cpu__gen_csr__csr__i_csr_imm := cpu__gen_csr__csr__i_csr_imm
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__i_rs1 -/
def assign_cpu__gen_csr__csr__i_rs1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__i_rs1 := s.cpu__rs1
  { s with
    cpu__gen_csr__csr__i_rs1 := cpu__gen_csr__csr__i_rs1
  }

/-- 组合逻辑：assign_cpu__csr_rd -/
def assign_cpu__csr_rd (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__csr_rd := s.cpu__gen_csr__csr__o_q
  { s with
    cpu__csr_rd := cpu__csr_rd
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__d -/
def assign_cpu__gen_csr__csr__d (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__d := (if s.cpu__gen_csr__csr__i_csr_d_sel then s.cpu__gen_csr__csr__i_csr_imm else s.cpu__gen_csr__csr__i_rs1)
  { s with
    cpu__gen_csr__csr__d := cpu__gen_csr__csr__d
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__csr_in -/
def assign_cpu__gen_csr__csr__csr_in (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__csr_in := (if decide ((s.cpu__gen_csr__csr__i_csr_source).toNat = (BitVec.ofNat 2 1).toNat) then s.cpu__gen_csr__csr__d else (if decide ((s.cpu__gen_csr__csr__i_csr_source).toNat = (BitVec.ofNat 2 2).toNat) then (s.cpu__gen_csr__csr__csr_out || s.cpu__gen_csr__csr__d) else (if decide ((s.cpu__gen_csr__csr__i_csr_source).toNat = (BitVec.ofNat 2 3).toNat) then (s.cpu__gen_csr__csr__csr_out && !(s.cpu__gen_csr__csr__d)) else (if decide ((s.cpu__gen_csr__csr__i_csr_source).toNat = (BitVec.ofNat 2 0).toNat) then s.cpu__gen_csr__csr__csr_out else bitVecToBool (boolToBitVec (i.__rtl_nondet_0001))))))
  { s with
    cpu__gen_csr__csr__csr_in := cpu__gen_csr__csr__csr_in
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__mstatus -/
def assign_cpu__gen_csr__csr__mstatus (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__mstatus := ((s.cpu__gen_csr__csr__mstatus_mie && s.cpu__gen_csr__csr__i_cnt3) || (s.cpu__gen_csr__csr__i_cnt11 || s.cpu__gen_csr__csr__i_cnt12))
  { s with
    cpu__gen_csr__csr__mstatus := cpu__gen_csr__csr__mstatus
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__csr_out -/
def assign_cpu__gen_csr__csr__csr_out (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__csr_out := (((bitVecToBool (boolToBitVec ((s.cpu__gen_csr__csr__i_mstatus_en && s.cpu__gen_csr__csr__i_en))) && s.cpu__gen_csr__csr__mstatus) || s.cpu__gen_csr__csr__i_rf_csr_out) || (bitVecToBool (boolToBitVec ((s.cpu__gen_csr__csr__i_mcause_en && s.cpu__gen_csr__csr__i_en))) && s.cpu__gen_csr__csr__mcause))
  { s with
    cpu__gen_csr__csr__csr_out := cpu__gen_csr__csr__csr_out
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__o_q -/
def assign_cpu__gen_csr__csr__o_q (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__o_q := s.cpu__gen_csr__csr__csr_out
  { s with
    cpu__gen_csr__csr__o_q := cpu__gen_csr__csr__o_q
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__timer_irq -/
def assign_cpu__gen_csr__csr__timer_irq (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__timer_irq := ((s.cpu__gen_csr__csr__i_mtip && s.cpu__gen_csr__csr__mstatus_mie) && s.cpu__gen_csr__csr__mie_mtie)
  { s with
    cpu__gen_csr__csr__timer_irq := cpu__gen_csr__csr__timer_irq
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__mcause -/
def assign_cpu__gen_csr__csr__mcause (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__mcause := (if s.cpu__gen_csr__csr__i_cnt0to3 then bitVecToBool (BitVec.extractLsb 0 0 (s.cpu__gen_csr__csr__mcause3_0)) else (if s.cpu__gen_csr__csr__i_cnt_done then s.cpu__gen_csr__csr__mcause31 else bitVecToBool (boolToBitVec (false))))
  { s with
    cpu__gen_csr__csr__mcause := cpu__gen_csr__csr__mcause
  }

/-- 组合逻辑：assign_cpu__gen_csr__csr__o_csr_in -/
def assign_cpu__gen_csr__csr__o_csr_in (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__gen_csr__csr__o_csr_in := s.cpu__gen_csr__csr__csr_in
  { s with
    cpu__gen_csr__csr__o_csr_in := cpu__gen_csr__csr__o_csr_in
  }

/-- 组合逻辑：assign_cpu__dbus_rdt -/
def assign_cpu__dbus_rdt (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__dbus_rdt := s.cpu__i_dbus_rdt
  { s with
    cpu__dbus_rdt := cpu__dbus_rdt
  }

/-- 组合逻辑：assign_cpu__dbus_ack -/
def assign_cpu__dbus_ack (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__dbus_ack := s.cpu__i_dbus_ack
  { s with
    cpu__dbus_ack := cpu__dbus_ack
  }

/-- 组合逻辑：assign_cpu__o_ext_rs2 -/
def assign_cpu__o_ext_rs2 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__o_ext_rs2 := s.cpu__o_dbus_dat
  { s with
    cpu__o_ext_rs2 := cpu__o_ext_rs2
  }

/-- 组合逻辑：proc_alwayscomb -/
def proc_alwayscomb (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let cpu__decode__o_alu_bool_op := s.cpu__decode__co_alu_bool_op
  let cpu__decode__o_alu_cmp_eq := s.cpu__decode__co_alu_cmp_eq
  let cpu__decode__o_alu_cmp_sig := s.cpu__decode__co_alu_cmp_sig
  let cpu__decode__o_alu_rd_sel := s.cpu__decode__co_alu_rd_sel
  let cpu__decode__o_alu_sub := s.cpu__decode__co_alu_sub
  let cpu__decode__o_bne_or_bge := s.cpu__decode__co_bne_or_bge
  let cpu__decode__o_branch_op := s.cpu__decode__co_branch_op
  let cpu__decode__o_bufreg_clr_lsb := s.cpu__decode__co_bufreg_clr_lsb
  let cpu__decode__o_bufreg_imm_en := s.cpu__decode__co_bufreg_imm_en
  let cpu__decode__o_bufreg_rs1_en := s.cpu__decode__co_bufreg_rs1_en
  let cpu__decode__o_bufreg_sh_signed := s.cpu__decode__co_bufreg_sh_signed
  let cpu__decode__o_cond_branch := s.cpu__decode__co_cond_branch
  let cpu__decode__o_csr_addr := s.cpu__decode__co_csr_addr
  let cpu__decode__o_csr_d_sel := s.cpu__decode__co_csr_d_sel
  let cpu__decode__o_csr_en := s.cpu__decode__co_csr_en
  let cpu__decode__o_csr_imm_en := s.cpu__decode__co_csr_imm_en
  let cpu__decode__o_csr_mcause_en := s.cpu__decode__co_csr_mcause_en
  let cpu__decode__o_csr_mie_en := s.cpu__decode__co_csr_mie_en
  let cpu__decode__o_csr_mstatus_en := s.cpu__decode__co_csr_mstatus_en
  let cpu__decode__o_csr_source := s.cpu__decode__co_csr_source
  let cpu__decode__o_ctrl_jal_or_jalr := s.cpu__decode__co_ctrl_jal_or_jalr
  let cpu__decode__o_ctrl_mret := s.cpu__decode__co_ctrl_mret
  let cpu__decode__o_ctrl_pc_rel := s.cpu__decode__co_ctrl_pc_rel
  let cpu__decode__o_ctrl_utype := s.cpu__decode__co_ctrl_utype
  let cpu__decode__o_dbus_en := s.cpu__decode__co_dbus_en
  let cpu__decode__o_e_op := s.cpu__decode__co_e_op
  let cpu__decode__o_ebreak := s.cpu__decode__co_ebreak
  let cpu__decode__o_ext_funct3 := s.cpu__decode__co_ext_funct3
  let cpu__decode__o_immdec_ctrl := s.cpu__decode__co_immdec_ctrl
  let cpu__decode__o_immdec_en := s.cpu__decode__co_immdec_en
  let cpu__decode__o_mdu_op := s.cpu__decode__co_mdu_op
  let cpu__decode__o_mem_cmd := s.cpu__decode__co_mem_cmd
  let cpu__decode__o_mem_half := s.cpu__decode__co_mem_half
  let cpu__decode__o_mem_signed := s.cpu__decode__co_mem_signed
  let cpu__decode__o_mem_word := s.cpu__decode__co_mem_word
  let cpu__decode__o_mtval_pc := s.cpu__decode__co_mtval_pc
  let cpu__decode__o_op_b_source := s.cpu__decode__co_op_b_source
  let cpu__decode__o_rd_alu_en := s.cpu__decode__co_rd_alu_en
  let cpu__decode__o_rd_csr_en := s.cpu__decode__co_rd_csr_en
  let cpu__decode__o_rd_mem_en := s.cpu__decode__co_rd_mem_en
  let cpu__decode__o_rd_op := s.cpu__decode__co_rd_op
  let cpu__decode__o_sh_right := s.cpu__decode__co_sh_right
  let cpu__decode__o_shift_op := s.cpu__decode__co_shift_op
  let cpu__decode__o_two_stage_op := s.cpu__decode__co_two_stage_op
  { s with
    cpu__decode__o_alu_bool_op := cpu__decode__o_alu_bool_op
    cpu__decode__o_alu_cmp_eq := cpu__decode__o_alu_cmp_eq
    cpu__decode__o_alu_cmp_sig := cpu__decode__o_alu_cmp_sig
    cpu__decode__o_alu_rd_sel := cpu__decode__o_alu_rd_sel
    cpu__decode__o_alu_sub := cpu__decode__o_alu_sub
    cpu__decode__o_bne_or_bge := cpu__decode__o_bne_or_bge
    cpu__decode__o_branch_op := cpu__decode__o_branch_op
    cpu__decode__o_bufreg_clr_lsb := cpu__decode__o_bufreg_clr_lsb
    cpu__decode__o_bufreg_imm_en := cpu__decode__o_bufreg_imm_en
    cpu__decode__o_bufreg_rs1_en := cpu__decode__o_bufreg_rs1_en
    cpu__decode__o_bufreg_sh_signed := cpu__decode__o_bufreg_sh_signed
    cpu__decode__o_cond_branch := cpu__decode__o_cond_branch
    cpu__decode__o_csr_addr := cpu__decode__o_csr_addr
    cpu__decode__o_csr_d_sel := cpu__decode__o_csr_d_sel
    cpu__decode__o_csr_en := cpu__decode__o_csr_en
    cpu__decode__o_csr_imm_en := cpu__decode__o_csr_imm_en
    cpu__decode__o_csr_mcause_en := cpu__decode__o_csr_mcause_en
    cpu__decode__o_csr_mie_en := cpu__decode__o_csr_mie_en
    cpu__decode__o_csr_mstatus_en := cpu__decode__o_csr_mstatus_en
    cpu__decode__o_csr_source := cpu__decode__o_csr_source
    cpu__decode__o_ctrl_jal_or_jalr := cpu__decode__o_ctrl_jal_or_jalr
    cpu__decode__o_ctrl_mret := cpu__decode__o_ctrl_mret
    cpu__decode__o_ctrl_pc_rel := cpu__decode__o_ctrl_pc_rel
    cpu__decode__o_ctrl_utype := cpu__decode__o_ctrl_utype
    cpu__decode__o_dbus_en := cpu__decode__o_dbus_en
    cpu__decode__o_e_op := cpu__decode__o_e_op
    cpu__decode__o_ebreak := cpu__decode__o_ebreak
    cpu__decode__o_ext_funct3 := cpu__decode__o_ext_funct3
    cpu__decode__o_immdec_ctrl := cpu__decode__o_immdec_ctrl
    cpu__decode__o_immdec_en := cpu__decode__o_immdec_en
    cpu__decode__o_mdu_op := cpu__decode__o_mdu_op
    cpu__decode__o_mem_cmd := cpu__decode__o_mem_cmd
    cpu__decode__o_mem_half := cpu__decode__o_mem_half
    cpu__decode__o_mem_signed := cpu__decode__o_mem_signed
    cpu__decode__o_mem_word := cpu__decode__o_mem_word
    cpu__decode__o_mtval_pc := cpu__decode__o_mtval_pc
    cpu__decode__o_op_b_source := cpu__decode__o_op_b_source
    cpu__decode__o_rd_alu_en := cpu__decode__o_rd_alu_en
    cpu__decode__o_rd_csr_en := cpu__decode__o_rd_csr_en
    cpu__decode__o_rd_mem_en := cpu__decode__o_rd_mem_en
    cpu__decode__o_rd_op := cpu__decode__o_rd_op
    cpu__decode__o_sh_right := cpu__decode__o_sh_right
    cpu__decode__o_shift_op := cpu__decode__o_shift_op
    cpu__decode__o_two_stage_op := cpu__decode__o_two_stage_op
  }

private def _rtl_comb_block_0 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let result :=
    assign_rf_ram_if__i_clk s i
    |> (fun s' => assign_rf_ram_if__i_rst s' i)
    |> (fun s' => assign_rf_ram_if__wtrig0 s' i)
    |> (fun s' => assign_rf_ram_if__wcnt s' i)
    |> (fun s' => assign_rf_ram_if__o_rdata0 s' i)
    |> (fun s' => assign_rf_ram_if__rtrig0 s' i)
    |> (fun s' => assign_rf_ram_if__o_ren s' i)
    |> (fun s' => assign_rf_ram__i_clk s' i)
    |> (fun s' => assign_rf_ram__o_rdata s' i)
    |> (fun s' => assign_cpu__clk s' i)
    |> (fun s' => assign_cpu__i_rst s' i)
    |> (fun s' => assign_cpu__i_timer_irq s' i)
    |> (fun s' => assign_cpu__i_ibus_rdt s' i)
    |> (fun s' => assign_cpu__i_ibus_ack s' i)
    |> (fun s' => assign_cpu__i_dbus_rdt s' i)
    |> (fun s' => assign_cpu__i_dbus_ack s' i)
    |> (fun s' => assign_cpu__i_ext_ready s' i)
    |> (fun s' => assign_cpu__i_ext_rd s' i)
    |> (fun s' => assign_cpu__iscomp s' i)
    |> (fun s' => assign_cpu__jump s' i)
    |> (fun s' => assign_cpu__state__o_mem_bytecnt s' i)
    |> (fun s' => assign_cpu__state__o_cnt0to3 s' i)
    |> (fun s' => assign_cpu__state__o_cnt12to31 s' i)
    |> (fun s' => assign_cpu__state__cnt_r s' i)
    |> (fun s' => assign_cpu__state__o_cnt_en s' i)
    |> (fun s' => assign_cpu__state__misalign_trap_sync s' i)
    |> (fun s' => assign_cpu__decode__co_mdu_op s' i)
    |> (fun s' => assign_cpu__decode__co_branch_op s' i)
    |> (fun s' => assign_cpu__decode__co_dbus_en s' i)
    |> (fun s' => assign_cpu__decode__co_mtval_pc s' i)
    |> (fun s' => assign_cpu__decode__co_mem_word s' i)
    |> (fun s' => assign_cpu__decode__co_ext_funct3 s' i)

  result

private def _rtl_comb_block_1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let result :=
    assign_cpu__decode__co_bufreg_rs1_en s i
    |> (fun s' => assign_cpu__decode__co_bufreg_imm_en s' i)
    |> (fun s' => assign_cpu__decode__co_bufreg_clr_lsb s' i)
    |> (fun s' => assign_cpu__decode__co_cond_branch s' i)
    |> (fun s' => assign_cpu__decode__co_ctrl_utype s' i)
    |> (fun s' => assign_cpu__decode__co_ctrl_jal_or_jalr s' i)
    |> (fun s' => assign_cpu__decode__co_ctrl_pc_rel s' i)
    |> (fun s' => assign_cpu__decode__co_rd_op s' i)
    |> (fun s' => assign_cpu__decode__co_sh_right s' i)
    |> (fun s' => assign_cpu__decode__co_bne_or_bge s' i)
    |> (fun s' => assign_cpu__decode__csr_op s' i)
    |> (fun s' => assign_cpu__decode__co_ebreak s' i)
    |> (fun s' => assign_cpu__decode__co_ctrl_mret s' i)
    |> (fun s' => assign_cpu__decode__co_e_op s' i)
    |> (fun s' => assign_cpu__decode__co_bufreg_sh_signed s' i)
    |> (fun s' => assign_cpu__decode__co_alu_sub s' i)
    |> (fun s' => assign_cpu__decode__csr_valid s' i)
    |> (fun s' => assign_cpu__decode__co_csr_source s' i)
    |> (fun s' => assign_cpu__decode__co_csr_d_sel s' i)
    |> (fun s' => assign_cpu__decode__co_csr_imm_en s' i)
    |> (fun s' => assign_cpu__decode__co_csr_addr s' i)
    |> (fun s' => assign_cpu__decode__co_alu_cmp_eq s' i)
    |> (fun s' => assign_cpu__decode__co_alu_cmp_sig s' i)
    |> (fun s' => assign_cpu__decode__co_mem_cmd s' i)
    |> (fun s' => assign_cpu__decode__co_mem_signed s' i)
    |> (fun s' => assign_cpu__decode__co_mem_half s' i)
    |> (fun s' => assign_cpu__decode__co_alu_bool_op s' i)
    |> (fun s' => assign_cpu__decode__co_immdec_ctrl s' i)
    |> (fun s' => assign_cpu__decode__co_alu_rd_sel s' i)
    |> (fun s' => assign_cpu__decode__co_op_b_source s' i)
    |> (fun s' => assign_cpu__immdec__o_csr_imm s' i)
    |> (fun s' => assign_cpu__immdec__o_rs1_addr s' i)

  result

private def _rtl_comb_block_2 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let result :=
    assign_cpu__immdec__o_rs2_addr s i
    |> (fun s' => assign_cpu__immdec__o_rd_addr s' i)
    |> (fun s' => assign_cpu__bufreg__o_dbus_adr s' i)
    |> (fun s' => assign_cpu__bufreg__o_ext_rs1 s' i)
    |> (fun s' => assign_cpu__bufreg2__o_dat s' i)
    |> (fun s' => assign_cpu__wb_ibus_adr s' i)
    |> (fun s' => assign_cpu__ctrl__pc s' i)
    |> (fun s' => assign_cpu__ctrl__pc_plus_offset_cy_r_w s' i)
    |> (fun s' => assign_cpu__ctrl__pc_plus_4_cy_r_w s' i)
    |> (fun s' => assign_cpu__new_irq s' i)
    |> (fun s' => assign_rdata0 s' i)
    |> (fun s' => assign_ren s' i)
    |> (fun s' => assign_rf_ram_if__wtrig1 s' i)
    |> (fun s' => assign_rdata s' i)
    |> (fun s' => assign_cpu__o_ibus_adr s' i)
    |> (fun s' => assign_cpu__wb_ibus_rdt s' i)
    |> (fun s' => assign_cpu__wb_ibus_ack s' i)
    |> (fun s' => assign_cpu__state__i_clk s' i)
    |> (fun s' => assign_cpu__state__i_rst s' i)
    |> (fun s' => assign_cpu__state__i_new_irq s' i)
    |> (fun s' => assign_cpu__cnt_en s' i)
    |> (fun s' => assign_cpu__cnt0to3 s' i)
    |> (fun s' => assign_cpu__cnt12to31 s' i)
    |> (fun s' => assign_cpu__mem_bytecnt s' i)
    |> (fun s' => assign_cpu__state__i_mdu_ready s' i)
    |> (fun s' => assign_cpu__state__i_dbus_ack s' i)
    |> (fun s' => assign_cpu__state__o_cnt0 s' i)
    |> (fun s' => assign_cpu__state__o_cnt1 s' i)
    |> (fun s' => assign_cpu__state__o_cnt2 s' i)
    |> (fun s' => assign_cpu__state__o_cnt3 s' i)
    |> (fun s' => assign_cpu__state__o_cnt7 s' i)
    |> (fun s' => assign_cpu__state__o_cnt11 s' i)

  result

private def _rtl_comb_block_3 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let result :=
    assign_cpu__state__o_cnt12 s i
    |> (fun s' => assign_cpu__state__o_cnt_done s' i)
    |> (fun s' => assign_cpu__decode__clk s' i)
    |> (fun s' => assign_cpu__decode__co_two_stage_op s' i)
    |> (fun s' => assign_cpu__decode__co_shift_op s' i)
    |> (fun s' => assign_cpu__decode__co_rd_alu_en s' i)
    |> (fun s' => assign_cpu__decode__co_rd_mem_en s' i)
    |> (fun s' => assign_cpu__decode__co_rd_csr_en s' i)
    |> (fun s' => assign_cpu__decode__co_csr_en s' i)
    |> (fun s' => assign_cpu__decode__co_csr_mstatus_en s' i)
    |> (fun s' => assign_cpu__decode__co_csr_mie_en s' i)
    |> (fun s' => assign_cpu__decode__co_csr_mcause_en s' i)
    |> (fun s' => assign_cpu__decode__co_immdec_en s' i)
    |> (fun s' => assign_cpu__immdec__i_clk s' i)
    |> (fun s' => assign_cpu__rd_addr s' i)
    |> (fun s' => assign_cpu__rs1_addr s' i)
    |> (fun s' => assign_cpu__rs2_addr s' i)
    |> (fun s' => assign_cpu__csr_imm s' i)
    |> (fun s' => assign_cpu__bufreg__i_clk s' i)
    |> (fun s' => assign_cpu__o_dbus_adr s' i)
    |> (fun s' => assign_cpu__o_ext_rs1 s' i)
    |> (fun s' => assign_cpu__bufreg2__i_clk s' i)
    |> (fun s' => assign_cpu__o_dbus_dat s' i)
    |> (fun s' => assign_cpu__ctrl__clk s' i)
    |> (fun s' => assign_cpu__ctrl__i_rst s' i)
    |> (fun s' => assign_cpu__ctrl__i_jump s' i)
    |> (fun s' => assign_cpu__ctrl__i_iscomp s' i)
    |> (fun s' => assign_cpu__alu__clk s' i)
    |> (fun s' => assign_cpu__rf_if__i_mepc s' i)
    |> (fun s' => assign_cpu__mem_if__i_clk s' i)
    |> (fun s' => assign_cpu__gen_csr__csr__i_clk s' i)
    |> (fun s' => assign_cpu__gen_csr__csr__i_rst s' i)

  result

private def _rtl_comb_block_4 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let result :=
    assign_cpu__gen_csr__csr__i_mtip s i
    |> (fun s' => assign_cpu__dbus_rdt s' i)
    |> (fun s' => assign_cpu__dbus_ack s' i)
    |> (fun s' => assign_rf_ram_if__i_rdata s' i)
    |> (fun s' => assign_rf_ram_if__o_wdata s' i)
    |> (fun s' => assign_rf_ram_if__o_wen s' i)
    |> (fun s' => assign_rf_ram__i_ren s' i)
    |> (fun s' => assign_cpu__i_rdata0 s' i)
    |> (fun s' => assign_o_ibus_adr s' i)
    |> (fun s' => assign_o_dbus_adr s' i)
    |> (fun s' => assign_o_dbus_dat s' i)
    |> (fun s' => assign_o_ext_rs1 s' i)
    |> (fun s' => assign_cpu__i_wb_rdt s' i)
    |> (fun s' => assign_cpu__cnt0 s' i)
    |> (fun s' => assign_cpu__cnt1 s' i)
    |> (fun s' => assign_cpu__cnt2 s' i)
    |> (fun s' => assign_cpu__cnt3 s' i)
    |> (fun s' => assign_cpu__cnt7 s' i)
    |> (fun s' => assign_cpu__cnt11 s' i)
    |> (fun s' => assign_cpu__cnt12 s' i)
    |> (fun s' => assign_cpu__cnt_done s' i)
    |> (fun s' => assign_cpu__state__i_ibus_ack s' i)
    |> (fun s' => assign_cpu__state__o_ibus_cyc s' i)
    |> (fun s' => assign_cpu__decode__i_wb_en s' i)
    |> (fun s' => assign_cpu__immdec__i_cnt_en s' i)
    |> (fun s' => assign_cpu__immdec__i_wb_en s' i)
    |> (fun s' => assign_cpu__bufreg__i_shamt s' i)
    |> (fun s' => assign_cpu__bufreg2__i_en s' i)
    |> (fun s' => assign_cpu__bufreg2__i_bytecnt s' i)
    |> (fun s' => assign_cpu__bufreg2__i_load s' i)
    |> (fun s' => assign_cpu__bufreg2__i_dat s' i)
    |> (fun s' => assign_cpu__ctrl__i_cnt12to31 s' i)

  result

private def _rtl_comb_block_5 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let result :=
    assign_cpu__alu__i_en s i
    |> (fun s' => assign_cpu__rf_if__i_cnt_en s' i)
    |> (fun s' => assign_cpu__rf_if__i_rd_waddr s' i)
    |> (fun s' => assign_cpu__rf_if__i_rs1_raddr s' i)
    |> (fun s' => assign_cpu__rf_if__i_rs2_raddr s' i)
    |> (fun s' => assign_cpu__mem_if__i_bytecnt s' i)
    |> (fun s' => assign_cpu__gen_csr__csr__i_trig_irq s' i)
    |> (fun s' => assign_cpu__gen_csr__csr__i_en s' i)
    |> (fun s' => assign_cpu__gen_csr__csr__i_cnt0to3 s' i)
    |> (fun s' => assign_cpu__gen_csr__csr__i_csr_imm s' i)
    |> (fun s' => assign_cpu__gen_csr__csr__timer_irq s' i)
    |> (fun s' => assign_cpu__o_ext_rs2 s' i)
    |> (fun s' => proc_alwayscomb s' i)
    |> (fun s' => assign_wdata s' i)
    |> (fun s' => assign_wen s' i)
    |> (fun s' => assign_rf_ram_if__o_rdata1 s' i)
    |> (fun s' => assign_o_ext_rs2 s' i)
    |> (fun s' => assign_cpu__wb_ibus_cyc s' i)
    |> (fun s' => assign_cpu__decode__i_wb_rdt s' i)
    |> (fun s' => assign_cpu__sh_right s' i)
    |> (fun s' => assign_cpu__bne_or_bge s' i)
    |> (fun s' => assign_cpu__cond_branch s' i)
    |> (fun s' => assign_cpu__e_op s' i)
    |> (fun s' => assign_cpu__ebreak s' i)
    |> (fun s' => assign_cpu__branch_op s' i)
    |> (fun s' => assign_cpu__shift_op s' i)
    |> (fun s' => assign_cpu__rd_op s' i)
    |> (fun s' => assign_cpu__two_stage_op s' i)
    |> (fun s' => assign_cpu__dbus_en s' i)
    |> (fun s' => assign_cpu__mdu_op s' i)
    |> (fun s' => assign_cpu__o_ext_funct3 s' i)
    |> (fun s' => assign_cpu__bufreg_rs1_en s' i)

  result

private def _rtl_comb_block_6 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let result :=
    assign_cpu__bufreg_imm_en s i
    |> (fun s' => assign_cpu__bufreg_clr_lsb s' i)
    |> (fun s' => assign_cpu__bufreg_sh_signed s' i)
    |> (fun s' => assign_cpu__jal_or_jalr s' i)
    |> (fun s' => assign_cpu__utype s' i)
    |> (fun s' => assign_cpu__pc_rel s' i)
    |> (fun s' => assign_cpu__mret s' i)
    |> (fun s' => assign_cpu__alu_sub s' i)
    |> (fun s' => assign_cpu__alu_bool_op s' i)
    |> (fun s' => assign_cpu__alu_cmp_eq s' i)
    |> (fun s' => assign_cpu__alu_cmp_sig s' i)
    |> (fun s' => assign_cpu__alu_rd_sel s' i)
    |> (fun s' => assign_cpu__mem_signed s' i)
    |> (fun s' => assign_cpu__mem_word s' i)
    |> (fun s' => assign_cpu__mem_half s' i)
    |> (fun s' => assign_cpu__o_dbus_we s' i)
    |> (fun s' => assign_cpu__csr_en s' i)
    |> (fun s' => assign_cpu__csr_addr s' i)
    |> (fun s' => assign_cpu__csr_mstatus_en s' i)
    |> (fun s' => assign_cpu__csr_mie_en s' i)
    |> (fun s' => assign_cpu__csr_mcause_en s' i)
    |> (fun s' => assign_cpu__csr_source s' i)
    |> (fun s' => assign_cpu__csr_d_sel s' i)
    |> (fun s' => assign_cpu__csr_imm_en s' i)
    |> (fun s' => assign_cpu__mtval_pc s' i)
    |> (fun s' => assign_cpu__immdec_ctrl s' i)
    |> (fun s' => assign_cpu__immdec_en s' i)
    |> (fun s' => assign_cpu__op_b_sel s' i)
    |> (fun s' => assign_cpu__rd_mem_en s' i)
    |> (fun s' => assign_cpu__rd_csr_en s' i)
    |> (fun s' => assign_cpu__rd_alu_en s' i)
    |> (fun s' => assign_cpu__immdec__i_cnt_done s' i)

  result

private def _rtl_comb_block_7 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let result :=
    assign_cpu__immdec__i_wb_rdt s i
    |> (fun s' => assign_cpu__bufreg__i_cnt0 s' i)
    |> (fun s' => assign_cpu__bufreg__i_cnt1 s' i)
    |> (fun s' => assign_cpu__bufreg__i_cnt_done s' i)
    |> (fun s' => assign_cpu__bufreg2__i_cnt7 s' i)
    |> (fun s' => assign_cpu__bufreg2__i_cnt_done s' i)
    |> (fun s' => assign_cpu__ctrl__i_cnt0 s' i)
    |> (fun s' => assign_cpu__ctrl__i_cnt1 s' i)
    |> (fun s' => assign_cpu__ctrl__i_cnt2 s' i)
    |> (fun s' => assign_cpu__alu__i_cnt0 s' i)
    |> (fun s' => assign_cpu__rf_if__i_rdata0 s' i)
    |> (fun s' => assign_cpu__rf_if__o_rreg0 s' i)
    |> (fun s' => assign_cpu__gen_csr__csr__i_cnt3 s' i)
    |> (fun s' => assign_cpu__gen_csr__csr__i_cnt7 s' i)
    |> (fun s' => assign_cpu__gen_csr__csr__i_cnt11 s' i)
    |> (fun s' => assign_cpu__gen_csr__csr__i_cnt12 s' i)
    |> (fun s' => assign_cpu__gen_csr__csr__i_cnt_done s' i)
    |> (fun s' => assign_rdata1 s' i)
    |> (fun s' => assign_rf_ram__i_wdata s' i)
    |> (fun s' => assign_rf_ram__i_wen s' i)
    |> (fun s' => assign_o_dbus_we s' i)
    |> (fun s' => assign_o_ext_funct3 s' i)
    |> (fun s' => assign_cpu__o_ibus_cyc s' i)
    |> (fun s' => assign_cpu__state__i_bne_or_bge s' i)
    |> (fun s' => assign_cpu__state__i_cond_branch s' i)
    |> (fun s' => assign_cpu__state__i_dbus_en s' i)
    |> (fun s' => assign_cpu__state__i_two_stage_op s' i)
    |> (fun s' => assign_cpu__state__i_branch_op s' i)
    |> (fun s' => assign_cpu__state__i_shift_op s' i)
    |> (fun s' => assign_cpu__state__i_sh_right s' i)
    |> (fun s' => assign_cpu__state__i_alu_rd_sel1 s' i)
    |> (fun s' => assign_cpu__state__i_rd_alu_en s' i)

  result

private def _rtl_comb_block_8 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let result :=
    assign_cpu__state__i_e_op s i
    |> (fun s' => assign_cpu__state__i_rd_op s' i)
    |> (fun s' => assign_cpu__state__i_mdu_op s' i)
    |> (fun s' => assign_cpu__immdec__i_immdec_en s' i)
    |> (fun s' => assign_cpu__immdec__i_csr_imm_en s' i)
    |> (fun s' => assign_cpu__immdec__i_ctrl s' i)
    |> (fun s' => assign_cpu__bufreg__i_mdu_op s' i)
    |> (fun s' => assign_cpu__bufreg__i_rs1_en s' i)
    |> (fun s' => assign_cpu__bufreg__i_imm_en s' i)
    |> (fun s' => assign_cpu__bufreg__i_clr_lsb s' i)
    |> (fun s' => assign_cpu__bufreg__i_shift_op s' i)
    |> (fun s' => assign_cpu__bufreg__i_right_shift_op s' i)
    |> (fun s' => assign_cpu__bufreg__i_sh_signed s' i)
    |> (fun s' => assign_cpu__bufreg2__i_sh_right s' i)
    |> (fun s' => assign_cpu__bufreg2__i_op_b_sel s' i)
    |> (fun s' => assign_cpu__bufreg2__i_shift_op s' i)
    |> (fun s' => assign_cpu__ctrl__i_jal_or_jalr s' i)
    |> (fun s' => assign_cpu__ctrl__i_utype s' i)
    |> (fun s' => assign_cpu__ctrl__i_pc_rel s' i)
    |> (fun s' => assign_cpu__ctrl__plus_4 s' i)
    |> (fun s' => assign_cpu__alu__i_sub s' i)
    |> (fun s' => assign_cpu__alu__i_bool_op s' i)
    |> (fun s' => assign_cpu__alu__i_cmp_eq s' i)
    |> (fun s' => assign_cpu__alu__i_cmp_sig s' i)
    |> (fun s' => assign_cpu__alu__i_rd_sel s' i)
    |> (fun s' => assign_cpu__alu__result_slt s' i)
    |> (fun s' => assign_cpu__o_rreg0 s' i)
    |> (fun s' => assign_cpu__rf_if__i_mret s' i)
    |> (fun s' => assign_cpu__rf_if__i_mtval_pc s' i)
    |> (fun s' => assign_cpu__rf_if__i_csr_en s' i)
    |> (fun s' => assign_cpu__rf_if__i_csr_addr s' i)
    |> (fun s' => assign_cpu__rf_if__i_rd_alu_en s' i)

  result

private def _rtl_comb_block_9 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let result :=
    assign_cpu__rf_if__i_rd_csr_en s i
    |> (fun s' => assign_cpu__rf_if__i_rd_mem_en s' i)
    |> (fun s' => assign_cpu__rf_if__o_rs1 s' i)
    |> (fun s' => assign_cpu__mem_if__i_signed s' i)
    |> (fun s' => assign_cpu__mem_if__i_word s' i)
    |> (fun s' => assign_cpu__mem_if__i_half s' i)
    |> (fun s' => assign_cpu__mem_if__i_mdu_op s' i)
    |> (fun s' => assign_cpu__gen_csr__csr__i_mem_op s' i)
    |> (fun s' => assign_cpu__gen_csr__csr__i_e_op s' i)
    |> (fun s' => assign_cpu__gen_csr__csr__i_ebreak s' i)
    |> (fun s' => assign_cpu__gen_csr__csr__i_mem_cmd s' i)
    |> (fun s' => assign_cpu__gen_csr__csr__i_mstatus_en s' i)
    |> (fun s' => assign_cpu__gen_csr__csr__i_mie_en s' i)
    |> (fun s' => assign_cpu__gen_csr__csr__i_mcause_en s' i)
    |> (fun s' => assign_cpu__gen_csr__csr__i_csr_source s' i)
    |> (fun s' => assign_cpu__gen_csr__csr__i_mret s' i)
    |> (fun s' => assign_cpu__gen_csr__csr__i_csr_d_sel s' i)
    |> (fun s' => assign_cpu__gen_csr__csr__mstatus s' i)
    |> (fun s' => assign_cpu__gen_csr__csr__mcause s' i)
    |> (fun s' => assign_rreg0 s' i)
    |> (fun s' => assign_cpu__i_rdata1 s' i)
    |> (fun s' => assign_o_ibus_cyc s' i)
    |> (fun s' => assign_cpu__state__o_mdu_valid s' i)
    |> (fun s' => assign_cpu__state__o_init s' i)
    |> (fun s' => assign_cpu__state__o_ctrl_trap s' i)
    |> (fun s' => assign_cpu__immdec__gen_immdec_w_eq_1__signbit s' i)
    |> (fun s' => assign_cpu__bufreg__clr_lsb s' i)
    |> (fun s' => assign_cpu__bufreg__o_lsb s' i)
    |> (fun s' => assign_cpu__ctrl__pc_plus_4_cy s' i)
    |> (fun s' => assign_cpu__ctrl__pc_plus_4 s' i)
    |> (fun s' => assign_cpu__ctrl__offset_a s' i)
    |> (fun s' => assign_cpu__rs1 s' i)

  result

private def _rtl_comb_block_10 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let result :=
    assign_cpu__mem_if__dat_valid s i
    |> (fun s' => assign_rf_ram_if__i_rreg0 s' i)
    |> (fun s' => assign_cpu__init s' i)
    |> (fun s' => assign_cpu__trap s' i)
    |> (fun s' => assign_cpu__o_mdu_valid s' i)
    |> (fun s' => assign_cpu__state__o_ctrl_pc_en s' i)
    |> (fun s' => assign_cpu__state__last_init s' i)
    |> (fun s' => assign_cpu__state__o_rf_rd_en s' i)
    |> (fun s' => assign_cpu__immdec__o_imm s' i)
    |> (fun s' => assign_cpu__lsb s' i)
    |> (fun s' => assign_cpu__bufreg__i_rs1 s' i)
    |> (fun s' => assign_cpu__alu__i_rs1 s' i)
    |> (fun s' => assign_cpu__rf_if__i_rdata1 s' i)
    |> (fun s' => assign_cpu__gen_csr__csr__i_rs1 s' i)
    |> (fun s' => assign_o_mdu_valid s' i)
    |> (fun s' => assign_cpu__ctrl_pc_en s' i)
    |> (fun s' => assign_cpu__state__i_ctrl_misalign s' i)
    |> (fun s' => assign_cpu__rd_en s' i)
    |> (fun s' => assign_cpu__imm s' i)
    |> (fun s' => assign_cpu__bufreg__i_init s' i)
    |> (fun s' => assign_cpu__bufreg2__i_init s' i)
    |> (fun s' => assign_cpu__bufreg2__i_lsb s' i)
    |> (fun s' => assign_cpu__ctrl__i_trap s' i)
    |> (fun s' => assign_cpu__alu__rs1_sx s' i)
    |> (fun s' => assign_cpu__rf_if__i_trap s' i)
    |> (fun s' => assign_cpu__rf_if__o_rs2 s' i)
    |> (fun s' => assign_cpu__rf_if__o_csr s' i)
    |> (fun s' => assign_cpu__rf_if__o_csr_pc s' i)
    |> (fun s' => assign_cpu__mem_if__i_lsb s' i)
    |> (fun s' => assign_cpu__gen_csr__csr__i_trap s' i)
    |> (fun s' => assign_cpu__gen_csr__csr__d s' i)
    |> (fun s' => assign_cpu__bufreg__i_imm s' i)

  result

private def _rtl_comb_block_11 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let result :=
    assign_cpu__bufreg2__i_imm s i
    |> (fun s' => assign_cpu__bufreg2__byte_valid s' i)
    |> (fun s' => assign_cpu__bufreg2__cnt_en s' i)
    |> (fun s' => assign_cpu__bufreg2__o_q s' i)
    |> (fun s' => assign_cpu__ctrl__i_pc_en s' i)
    |> (fun s' => assign_cpu__ctrl__i_imm s' i)
    |> (fun s' => assign_cpu__csr_pc s' i)
    |> (fun s' => assign_cpu__rf_csr_out s' i)
    |> (fun s' => assign_cpu__rf_if__i_rd_wen s' i)
    |> (fun s' => assign_cpu__rs2 s' i)
    |> (fun s' => assign_cpu__rf_if__o_wreg0 s' i)
    |> (fun s' => assign_cpu__rf_if__o_wreg1 s' i)
    |> (fun s' => assign_cpu__rf_if__o_wen1 s' i)
    |> (fun s' => assign_cpu__rf_if__gen_csr__sel_rs2 s' i)
    |> (fun s' => assign_cpu__mem_if__o_wb_sel s' i)
    |> (fun s' => assign_cpu__mem_if__o_misalign s' i)
    |> (fun s' => assign_cpu__bufreg__c s' i)
    |> (fun s' => assign_cpu__bufreg__q s' i)
    |> (fun s' => assign_cpu__bufreg2__i_rs2 s' i)
    |> (fun s' => assign_cpu__bufreg2_q s' i)
    |> (fun s' => assign_cpu__bufreg2__shift_en s' i)
    |> (fun s' => assign_cpu__ctrl__i_csr_pc s' i)
    |> (fun s' => assign_cpu__o_wreg0 s' i)
    |> (fun s' => assign_cpu__o_wreg1 s' i)
    |> (fun s' => assign_cpu__o_wen1 s' i)
    |> (fun s' => assign_cpu__rf_if__rd_wen s' i)
    |> (fun s' => assign_cpu__rf_if__o_rreg1 s' i)
    |> (fun s' => assign_cpu__mem_misalign s' i)
    |> (fun s' => assign_cpu__o_dbus_sel s' i)
    |> (fun s' => assign_cpu__gen_csr__csr__i_rf_csr_out s' i)
    |> (fun s' => assign_wreg0 s' i)
    |> (fun s' => assign_wreg1 s' i)

  result

private def _rtl_comb_block_12 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let result :=
    assign_wen1 s i
    |> (fun s' => assign_o_dbus_sel s' i)
    |> (fun s' => assign_cpu__state__i_mem_misalign s' i)
    |> (fun s' => assign_cpu__bufreg2__o_op_b s' i)
    |> (fun s' => assign_cpu__o_rreg1 s' i)
    |> (fun s' => assign_cpu__rf_if__o_wen0 s' i)
    |> (fun s' => assign_cpu__mem_if__i_bufreg2_q s' i)
    |> (fun s' => assign_cpu__gen_csr__csr__csr_out s' i)
    |> (fun s' => assign_rf_ram_if__i_wreg0 s' i)
    |> (fun s' => assign_rf_ram_if__i_wreg1 s' i)
    |> (fun s' => assign_rf_ram_if__i_wen1 s' i)
    |> (fun s' => assign_rreg1 s' i)
    |> (fun s' => assign_cpu__state__o_dbus_cyc s' i)
    |> (fun s' => assign_cpu__op_b s' i)
    |> (fun s' => assign_cpu__bufreg2__cnt_next s' i)
    |> (fun s' => assign_cpu__o_wen0 s' i)
    |> (fun s' => assign_cpu__mem_if__o_rd s' i)
    |> (fun s' => assign_cpu__gen_csr__csr__csr_in s' i)
    |> (fun s' => assign_cpu__gen_csr__csr__o_q s' i)
    |> (fun s' => assign_rf_ram_if__i_rreg1 s' i)
    |> (fun s' => assign_rf_ram_if__wreg s' i)
    |> (fun s' => assign_wen0 s' i)
    |> (fun s' => assign_cpu__o_dbus_cyc s' i)
    |> (fun s' => assign_cpu__bufreg2__dat_shamt s' i)
    |> (fun s' => assign_cpu__alu__i_op_b s' i)
    |> (fun s' => assign_cpu__mem_rd s' i)
    |> (fun s' => assign_cpu__csr_rd s' i)
    |> (fun s' => assign_cpu__gen_csr__csr__o_csr_in s' i)
    |> (fun s' => assign_rf_ram_if__i_wen0 s' i)
    |> (fun s' => assign_rf_ram_if__o_waddr s' i)
    |> (fun s' => assign_rf_ram_if__rreg s' i)
    |> (fun s' => assign_o_dbus_cyc s' i)

  result

private def _rtl_comb_block_13 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let result :=
    assign_cpu__bufreg2__o_sh_done s i
    |> (fun s' => assign_cpu__alu__op_b_sx s' i)
    |> (fun s' => assign_cpu__alu__add_b s' i)
    |> (fun s' => assign_cpu__alu__result_bool s' i)
    |> (fun s' => assign_cpu__rf_if__i_csr_rd s' i)
    |> (fun s' => assign_cpu__rf_if__i_mem_rd s' i)
    |> (fun s' => assign_cpu__csr_in s' i)
    |> (fun s' => assign_waddr s' i)
    |> (fun s' => assign_rf_ram_if__o_raddr s' i)
    |> (fun s' => assign_cpu__sh_done s' i)
    |> (fun s' => assign_cpu__alu__add_cy s' i)
    |> (fun s' => assign_cpu__alu__result_add s' i)
    |> (fun s' => assign_cpu__rf_if__i_csr s' i)
    |> (fun s' => assign_raddr s' i)
    |> (fun s' => assign_rf_ram__i_waddr s' i)
    |> (fun s' => assign_cpu__state__i_sh_done s' i)
    |> (fun s' => assign_cpu__alu__result_lt s' i)
    |> (fun s' => assign_cpu__alu__result_eq s' i)
    |> (fun s' => assign_cpu__rf_if__o_wdata1 s' i)
    |> (fun s' => assign_rf_ram__i_raddr s' i)
    |> (fun s' => assign_cpu__state__o_bufreg_en s' i)
    |> (fun s' => assign_cpu__alu__o_cmp s' i)
    |> (fun s' => assign_cpu__o_wdata1 s' i)
    |> (fun s' => assign_wdata1 s' i)
    |> (fun s' => assign_cpu__bufreg_en s' i)
    |> (fun s' => assign_cpu__alu_cmp s' i)
    |> (fun s' => assign_rf_ram_if__i_wdata1 s' i)
    |> (fun s' => assign_cpu__state__i_alu_cmp s' i)
    |> (fun s' => assign_cpu__bufreg__i_en s' i)
    |> (fun s' => assign_cpu__state__take_branch s' i)
    |> (fun s' => assign_cpu__bufreg__o_q s' i)
    |> (fun s' => assign_cpu__state__trap_pending s' i)

  result

private def _rtl_comb_block_14 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let result :=
    assign_cpu__bufreg_q s i
    |> (fun s' => assign_cpu__state__o_rf_wreq s' i)
    |> (fun s' => assign_cpu__state__o_rf_rreq s' i)
    |> (fun s' => assign_cpu__ctrl__i_buf s' i)
    |> (fun s' => assign_cpu__alu__i_buf s' i)
    |> (fun s' => assign_cpu__rf_if__i_bufreg_q s' i)
    |> (fun s' => assign_cpu__o_rf_rreq s' i)
    |> (fun s' => assign_cpu__o_rf_wreq s' i)
    |> (fun s' => assign_cpu__ctrl__offset_b s' i)
    |> (fun s' => assign_cpu__alu__o_rd s' i)
    |> (fun s' => assign_rf_rreq s' i)
    |> (fun s' => assign_rf_wreq s' i)
    |> (fun s' => assign_cpu__ctrl__pc_plus_offset_cy s' i)
    |> (fun s' => assign_cpu__ctrl__pc_plus_offset s' i)
    |> (fun s' => assign_cpu__alu_rd s' i)
    |> (fun s' => assign_rf_ram_if__i_wreq s' i)
    |> (fun s' => assign_rf_ram_if__i_rreq s' i)
    |> (fun s' => assign_cpu__ctrl__pc_plus_offset_aligned s' i)
    |> (fun s' => assign_cpu__rf_if__i_alu_rd s' i)
    |> (fun s' => assign_rf_ram_if__o_ready s' i)
    |> (fun s' => assign_cpu__ctrl__o_bad_pc s' i)
    |> (fun s' => assign_cpu__ctrl__new_pc s' i)
    |> (fun s' => assign_cpu__ctrl__o_rd s' i)
    |> (fun s' => assign_rf_ready s' i)
    |> (fun s' => assign_cpu__ctrl_rd s' i)
    |> (fun s' => assign_cpu__bad_pc s' i)
    |> (fun s' => assign_cpu__i_rf_ready s' i)
    |> (fun s' => assign_cpu__rf_if__i_bad_pc s' i)
    |> (fun s' => assign_cpu__rf_if__i_ctrl_rd s' i)
    |> (fun s' => assign_cpu__state__i_rf_ready s' i)
    |> (fun s' => assign_cpu__rf_if__gen_csr__rd s' i)
    |> (fun s' => assign_cpu__rf_if__gen_csr__mtval s' i)

  result

private def _rtl_comb_block_15 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let result :=
    assign_cpu__rf_if__o_wdata0 s i
    |> (fun s' => assign_cpu__o_wdata0 s' i)
    |> (fun s' => assign_wdata0 s' i)
    |> (fun s' => assign_rf_ram_if__i_wdata0 s' i)

  result

/-- Combinational fixed-point schedule derived from IR dependencies -/
def comb (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
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
    |> (fun s' => _rtl_comb_block_9 s' i)
    |> (fun s' => _rtl_comb_block_10 s' i)
    |> (fun s' => _rtl_comb_block_11 s' i)
    |> (fun s' => _rtl_comb_block_12 s' i)
    |> (fun s' => _rtl_comb_block_13 s' i)
    |> (fun s' => _rtl_comb_block_14 s' i)
    |> (fun s' => _rtl_comb_block_15 s' i)

  result

/-- 时序逻辑: proc_alwaysff (clk=clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  { s with
    rf_ram_if__wdata0_r := BitVec.append (n := 1) (m := 1) (boolToBitVec (s.rf_ram_if__i_wdata0)) (BitVec.extractLsb 1 1 (s.rf_ram_if__wdata0_r))
    rf_ram_if__wdata1_r := BitVec.append (n := 1) (m := 2) (boolToBitVec (s.rf_ram_if__i_wdata1)) (BitVec.extractLsb 2 1 (s.rf_ram_if__wdata1_r))
    rf_ram_if__wen0_r := (if BitVec.getLsbD (s.rf_ram_if__wcnt) 0 then s.rf_ram_if__i_wen0 else s.rf_ram_if__wen0_r)
    rf_ram_if__wen1_r := (if BitVec.getLsbD (s.rf_ram_if__wcnt) 0 then s.rf_ram_if__i_wen1 else s.rf_ram_if__wen1_r)
  }

/-- 时序逻辑: proc_alwaysff_1 (clk=clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_1 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  { s with
    rf_ram_if__rdata1 := (if s.rf_ram_if__rtrig1 then bitVecToBool (BitVec.extractLsb 1 1 (s.rf_ram_if__i_rdata)) else s.rf_ram_if__rdata1)
  }

/-- 时序逻辑: proc_alwaysff_2 (clk=clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_2 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  { s with
    rf_ram_if__rcnt := (if s.rf_ram_if__i_rst then BitVec.append (n := 2) (m := 3) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))) (BitVec.append (n := 1) (m := 2) (boolToBitVec (false)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false)))) else (if (s.rf_ram_if__i_rreq || s.rf_ram_if__i_wreq) then BitVec.append (n := 3) (m := 2) (BitVec.append (n := 1) (m := 2) (boolToBitVec (false)) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false)))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (s.rf_ram_if__i_wreq)) (boolToBitVec (false))) else (s.rf_ram_if__rcnt + BitVec.append (n := 4) (m := 1) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (boolToBitVec (false)))) (boolToBitVec (true)))))
    rf_ram_if__rdata0 := (if s.rf_ram_if__rtrig0 then s.rf_ram_if__i_rdata else BitVec.append (n := 1) (m := 1) (boolToBitVec (false)) (BitVec.extractLsb 1 1 (s.rf_ram_if__rdata0)))
    rf_ram_if__rgate := (if s.rf_ram_if__i_rst then false else (if (bvReduceAnd (s.rf_ram_if__rcnt) || s.rf_ram_if__i_rreq) then s.rf_ram_if__i_rreq else s.rf_ram_if__rgate))
    rf_ram_if__rgnt := (if s.rf_ram_if__i_rst then false else s.rf_ram_if__rreq_r)
    rf_ram_if__rreq_r := (if s.rf_ram_if__i_rst then false else s.rf_ram_if__i_rreq)
    rf_ram_if__rtrig1 := s.rf_ram_if__rtrig0
  }

/-- 时序逻辑: proc_alwaysff_3 (clk=clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_3 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  { s with
    rf_ram__memory := (if s.rf_ram__i_wen then bvArrayWrite 2 576 0 575 (s.rf_ram__memory) ((s.rf_ram__i_waddr).toNat) (s.rf_ram__i_wdata) else s.rf_ram__memory)
    rf_ram__rdata := (if s.rf_ram__i_ren then bvArrayRead 2 576 0 575 (s.rf_ram__memory) ((s.rf_ram__i_raddr).toNat) else BitVec.append (n := 1) (m := 1) (boolToBitVec (i.__rtl_nondet_0000)) (boolToBitVec (i.__rtl_nondet_0000)))
  }

/-- 时序逻辑: proc_alwaysff_4 (clk=clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_4 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  { s with
    rf_ram__regzero := BitVec.getLsbD (BitVec.extractLsb 5 0 (BitVec.extractLsb 5 0 (boolToBitVec (!(bvNonzero (BitVec.extractLsb 9 4 (s.rf_ram__i_raddr))))))) 0
  }

/-- 时序逻辑: proc_alwaysff_5 (clk=clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_5 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  { s with
    cpu__state__ibus_cyc := (if ((s.cpu__state__i_ibus_ack || s.cpu__state__o_cnt_done) || s.cpu__state__i_rst) then (s.cpu__state__o_ctrl_pc_en || s.cpu__state__i_rst) else s.cpu__state__ibus_cyc)
    cpu__state__init_done := (if s.cpu__state__i_rst then false else (if s.cpu__state__o_cnt_done then (s.cpu__state__o_init && !(s.cpu__state__init_done)) else s.cpu__state__init_done))
    cpu__state__o_ctrl_jump := (if s.cpu__state__i_rst then false else (if s.cpu__state__o_cnt_done then (s.cpu__state__o_init && s.cpu__state__take_branch) else s.cpu__state__o_ctrl_jump))
  }

/-- 时序逻辑: proc_alwaysff_6 (clk=clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_6 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  { s with
    cpu__state__gen_cnt_w_eq_1__cnt_lsb := (if (s.cpu__state__i_rst && decide ((BitVec.ofNat 32 1296649801).toNat ≠ (BitVec.ofNat 32 1313820229).toNat)) then BitVec.ofNat 4 0 else BitVec.append (n := 3) (m := 1) (BitVec.extractLsb 2 0 (s.cpu__state__gen_cnt_w_eq_1__cnt_lsb)) (boolToBitVec (((BitVec.getLsbD (s.cpu__state__gen_cnt_w_eq_1__cnt_lsb) 3 && !(s.cpu__state__o_cnt_done)) || s.cpu__state__i_rf_ready))))
    cpu__state__o_cnt := (if (s.cpu__state__i_rst && decide ((BitVec.ofNat 32 1296649801).toNat ≠ (BitVec.ofNat 32 1313820229).toNat)) then BitVec.ofNat 3 0 else (s.cpu__state__o_cnt + BitVec.append (n := 2) (m := 1) (BitVec.ofNat 2 0) (boolToBitVec (BitVec.getLsbD (s.cpu__state__cnt_r) 3))))
  }

/-- 时序逻辑: proc_alwaysff_7 (clk=clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_7 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  { s with
    cpu__state__gen_csr__misalign_trap_sync_r := (if ((s.cpu__state__i_ibus_ack || s.cpu__state__o_cnt_done) || s.cpu__state__i_rst) then (!((s.cpu__state__i_ibus_ack || s.cpu__state__i_rst)) && ((s.cpu__state__trap_pending && s.cpu__state__o_init) || s.cpu__state__gen_csr__misalign_trap_sync_r)) else s.cpu__state__gen_csr__misalign_trap_sync_r)
  }

/-- 时序逻辑: proc_alwaysff_8 (clk=clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_8 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  { s with
    cpu__decode__funct3 := (if s.cpu__decode__i_wb_en then BitVec.extractLsb 12 10 (s.cpu__decode__i_wb_rdt) else s.cpu__decode__funct3)
    cpu__decode__imm25 := (if s.cpu__decode__i_wb_en then BitVec.getLsbD (s.cpu__decode__i_wb_rdt) 23 else s.cpu__decode__imm25)
    cpu__decode__imm30 := (if s.cpu__decode__i_wb_en then BitVec.getLsbD (s.cpu__decode__i_wb_rdt) 28 else s.cpu__decode__imm30)
    cpu__decode__op20 := (if s.cpu__decode__i_wb_en then BitVec.getLsbD (s.cpu__decode__i_wb_rdt) 18 else s.cpu__decode__op20)
    cpu__decode__op21 := (if s.cpu__decode__i_wb_en then BitVec.getLsbD (s.cpu__decode__i_wb_rdt) 19 else s.cpu__decode__op21)
    cpu__decode__op22 := (if s.cpu__decode__i_wb_en then BitVec.getLsbD (s.cpu__decode__i_wb_rdt) 20 else s.cpu__decode__op22)
    cpu__decode__op26 := (if s.cpu__decode__i_wb_en then BitVec.getLsbD (s.cpu__decode__i_wb_rdt) 24 else s.cpu__decode__op26)
    cpu__decode__opcode := (if s.cpu__decode__i_wb_en then BitVec.extractLsb 4 0 (s.cpu__decode__i_wb_rdt) else s.cpu__decode__opcode)
  }

/-- 时序逻辑: proc_alwaysff_9 (clk=clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_9 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  { s with
    cpu__immdec__gen_immdec_w_eq_1__imm11_7 := (if (s.cpu__immdec__i_wb_en || (s.cpu__immdec__i_cnt_en && BitVec.getLsbD (s.cpu__immdec__i_immdec_en) 0)) then (if s.cpu__immdec__i_wb_en then BitVec.extractLsb 4 0 (s.cpu__immdec__i_wb_rdt) else BitVec.append (n := 1) (m := 4) (boolToBitVec (BitVec.getLsbD (s.cpu__immdec__gen_immdec_w_eq_1__imm30_25) 0)) (BitVec.extractLsb 4 1 (s.cpu__immdec__gen_immdec_w_eq_1__imm11_7))) else s.cpu__immdec__gen_immdec_w_eq_1__imm11_7)
    cpu__immdec__gen_immdec_w_eq_1__imm19_12_20 := (if (s.cpu__immdec__i_wb_en || (s.cpu__immdec__i_cnt_en && BitVec.getLsbD (s.cpu__immdec__i_immdec_en) 1)) then (if s.cpu__immdec__i_wb_en then BitVec.append (n := 8) (m := 1) (BitVec.extractLsb 12 5 (s.cpu__immdec__i_wb_rdt)) (boolToBitVec (BitVec.getLsbD (s.cpu__immdec__i_wb_rdt) 13)) else BitVec.append (n := 1) (m := 8) (boolToBitVec ((if BitVec.getLsbD (s.cpu__immdec__i_ctrl) 3 then s.cpu__immdec__gen_immdec_w_eq_1__signbit else BitVec.getLsbD (s.cpu__immdec__gen_immdec_w_eq_1__imm24_20) 0))) (BitVec.extractLsb 8 1 (s.cpu__immdec__gen_immdec_w_eq_1__imm19_12_20))) else s.cpu__immdec__gen_immdec_w_eq_1__imm19_12_20)
    cpu__immdec__gen_immdec_w_eq_1__imm24_20 := (if (s.cpu__immdec__i_wb_en || (s.cpu__immdec__i_cnt_en && BitVec.getLsbD (s.cpu__immdec__i_immdec_en) 2)) then (if s.cpu__immdec__i_wb_en then BitVec.extractLsb 17 13 (s.cpu__immdec__i_wb_rdt) else BitVec.append (n := 1) (m := 4) (boolToBitVec (BitVec.getLsbD (s.cpu__immdec__gen_immdec_w_eq_1__imm30_25) 0)) (BitVec.extractLsb 4 1 (s.cpu__immdec__gen_immdec_w_eq_1__imm24_20))) else s.cpu__immdec__gen_immdec_w_eq_1__imm24_20)
    cpu__immdec__gen_immdec_w_eq_1__imm30_25 := (if (s.cpu__immdec__i_wb_en || (s.cpu__immdec__i_cnt_en && BitVec.getLsbD (s.cpu__immdec__i_immdec_en) 3)) then (if s.cpu__immdec__i_wb_en then BitVec.extractLsb 23 18 (s.cpu__immdec__i_wb_rdt) else BitVec.append (n := 1) (m := 5) (boolToBitVec ((if BitVec.getLsbD (s.cpu__immdec__i_ctrl) 2 then s.cpu__immdec__gen_immdec_w_eq_1__imm7 else (if BitVec.getLsbD (s.cpu__immdec__i_ctrl) 1 then s.cpu__immdec__gen_immdec_w_eq_1__signbit else BitVec.getLsbD (s.cpu__immdec__gen_immdec_w_eq_1__imm19_12_20) 0)))) (BitVec.extractLsb 5 1 (s.cpu__immdec__gen_immdec_w_eq_1__imm30_25))) else s.cpu__immdec__gen_immdec_w_eq_1__imm30_25)
    cpu__immdec__gen_immdec_w_eq_1__imm31 := (if s.cpu__immdec__i_wb_en then BitVec.getLsbD (s.cpu__immdec__i_wb_rdt) 24 else s.cpu__immdec__gen_immdec_w_eq_1__imm31)
    cpu__immdec__gen_immdec_w_eq_1__imm7 := (if (s.cpu__immdec__i_wb_en || s.cpu__immdec__i_cnt_en) then (if s.cpu__immdec__i_wb_en then BitVec.getLsbD (s.cpu__immdec__i_wb_rdt) 0 else s.cpu__immdec__gen_immdec_w_eq_1__signbit) else s.cpu__immdec__gen_immdec_w_eq_1__imm7)
  }

/-- 时序逻辑: proc_alwaysff_10 (clk=clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_10 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  { s with
    cpu__bufreg__c_r := bitVecToBool (bvBitWrite 1 (boolToBitVec (false)) ((BitVec.ofNat 32 0).toNat) ((s.cpu__bufreg__c && s.cpu__bufreg__i_en)))
  }

/-- 时序逻辑: proc_alwaysff_11 (clk=clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_11 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  { s with
    cpu__bufreg__data := (if (if s.cpu__bufreg__i_init then (s.cpu__bufreg__i_cnt0 || s.cpu__bufreg__i_cnt1) else s.cpu__bufreg__i_en) then bvRangeWrite 32 1 0 ((if s.cpu__bufreg__i_en then bvRangeWrite 32 31 2 (s.cpu__bufreg__data) (BitVec.append (n := 1) (m := 29) (boolToBitVec ((if s.cpu__bufreg__i_init then s.cpu__bufreg__q else bitVecToBool (boolToBitVec ((BitVec.getLsbD (s.cpu__bufreg__data) 31 && s.cpu__bufreg__i_sh_signed)))))) (BitVec.extractLsb 31 3 (s.cpu__bufreg__data))) else s.cpu__bufreg__data)) (BitVec.append (n := 1) (m := 1) (boolToBitVec ((if s.cpu__bufreg__i_init then s.cpu__bufreg__q else BitVec.getLsbD (s.cpu__bufreg__data) 2))) (boolToBitVec (BitVec.getLsbD (s.cpu__bufreg__data) 1))) else (if s.cpu__bufreg__i_en then bvRangeWrite 32 31 2 (s.cpu__bufreg__data) (BitVec.append (n := 1) (m := 29) (boolToBitVec ((if s.cpu__bufreg__i_init then s.cpu__bufreg__q else bitVecToBool (boolToBitVec ((BitVec.getLsbD (s.cpu__bufreg__data) 31 && s.cpu__bufreg__i_sh_signed)))))) (BitVec.extractLsb 31 3 (s.cpu__bufreg__data))) else s.cpu__bufreg__data))
  }

/-- 时序逻辑: proc_alwaysff_12 (clk=clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_12 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  { s with
    cpu__bufreg2__dhi := (if ((s.cpu__bufreg2__shift_en || s.cpu__bufreg2__cnt_en) || s.cpu__bufreg2__i_load) then (if s.cpu__bufreg2__i_load then BitVec.extractLsb 31 24 (s.cpu__bufreg2__i_dat) else (s.cpu__bufreg2__dat_shamt &&& BitVec.append (n := 2) (m := 6) (BitVec.ofNat 2 3) (BitVec.append (n := 1) (m := 5) (boolToBitVec (!(((s.cpu__bufreg2__i_shift_op && s.cpu__bufreg2__i_cnt7) && !(s.cpu__bufreg2__cnt_en))))) (BitVec.ofNat 5 31)))) else s.cpu__bufreg2__dhi)
    cpu__bufreg2__dlo := (if (s.cpu__bufreg2__shift_en || s.cpu__bufreg2__i_load) then (if s.cpu__bufreg2__i_load then BitVec.extractLsb 23 0 (s.cpu__bufreg2__i_dat) else BitVec.append (n := 1) (m := 23) (BitVec.extractLsb 0 0 (s.cpu__bufreg2__dhi)) (BitVec.extractLsb 23 1 (s.cpu__bufreg2__dlo))) else s.cpu__bufreg2__dlo)
  }

/-- 时序逻辑: proc_alwaysff_13 (clk=clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_13 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  { s with
    cpu__ctrl__o_ibus_adr := (if (s.cpu__ctrl__i_pc_en || s.cpu__ctrl__i_rst) then (if s.cpu__ctrl__i_rst then BitVec.ofNat 32 0 else BitVec.append (n := 1) (m := 31) (boolToBitVec (s.cpu__ctrl__new_pc)) (BitVec.extractLsb 31 1 (s.cpu__ctrl__o_ibus_adr))) else s.cpu__ctrl__o_ibus_adr)
    cpu__ctrl__pc_plus_4_cy_r := (s.cpu__ctrl__i_pc_en && s.cpu__ctrl__pc_plus_4_cy)
    cpu__ctrl__pc_plus_offset_cy_r := (s.cpu__ctrl__i_pc_en && s.cpu__ctrl__pc_plus_offset_cy)
  }

/-- 时序逻辑: proc_alwaysff_14 (clk=clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_14 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  { s with
    cpu__alu__add_cy_r := bitVecToBool (bvBitWrite 1 (boolToBitVec (false)) ((BitVec.ofNat 32 0).toNat) ((if s.cpu__alu__i_en then s.cpu__alu__add_cy else s.cpu__alu__i_sub)))
    cpu__alu__cmp_r := (if s.cpu__alu__i_en then s.cpu__alu__o_cmp else s.cpu__alu__cmp_r)
  }

/-- 时序逻辑: proc_alwaysff_15 (clk=clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_15 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  { s with
    cpu__mem_if__signbit := (if s.cpu__mem_if__dat_valid then s.cpu__mem_if__i_bufreg2_q else s.cpu__mem_if__signbit)
  }

/-- 时序逻辑: proc_alwaysff_16 (clk=clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_16 (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  { s with
    cpu__gen_csr__csr__mcause31 := (if ((s.cpu__gen_csr__csr__i_mcause_en && s.cpu__gen_csr__csr__i_cnt_done) || s.cpu__gen_csr__csr__i_trap) then (if s.cpu__gen_csr__csr__i_trap then s.cpu__gen_csr__csr__o_new_irq else s.cpu__gen_csr__csr__csr_in) else s.cpu__gen_csr__csr__mcause31)
    cpu__gen_csr__csr__mcause3_0 := (if (((s.cpu__gen_csr__csr__i_mcause_en && s.cpu__gen_csr__csr__i_en) && s.cpu__gen_csr__csr__i_cnt0to3) || (s.cpu__gen_csr__csr__i_trap && s.cpu__gen_csr__csr__i_cnt_done)) then bvBitWrite 4 (bvBitWrite 4 (bvBitWrite 4 (bvBitWrite 4 (s.cpu__gen_csr__csr__mcause3_0) ((BitVec.ofNat 32 3).toNat) (((s.cpu__gen_csr__csr__i_e_op && !(s.cpu__gen_csr__csr__i_ebreak)) || (!(s.cpu__gen_csr__csr__i_trap) && s.cpu__gen_csr__csr__csr_in)))) ((BitVec.ofNat 32 2).toNat) (((s.cpu__gen_csr__csr__o_new_irq || s.cpu__gen_csr__csr__i_mem_op) || (!(s.cpu__gen_csr__csr__i_trap) && (if decide ((BitVec.ofNat 32 1).toNat = (BitVec.ofNat 32 1).toNat) then BitVec.getLsbD (s.cpu__gen_csr__csr__mcause3_0) 3 else s.cpu__gen_csr__csr__csr_in))))) ((BitVec.ofNat 32 1).toNat) ((((s.cpu__gen_csr__csr__o_new_irq || s.cpu__gen_csr__csr__i_e_op) || (s.cpu__gen_csr__csr__i_mem_op && s.cpu__gen_csr__csr__i_mem_cmd)) || (!(s.cpu__gen_csr__csr__i_trap) && (if decide ((BitVec.ofNat 32 1).toNat = (BitVec.ofNat 32 1).toNat) then BitVec.getLsbD (s.cpu__gen_csr__csr__mcause3_0) 2 else s.cpu__gen_csr__csr__csr_in))))) ((BitVec.ofNat 32 0).toNat) (((s.cpu__gen_csr__csr__o_new_irq || s.cpu__gen_csr__csr__i_e_op) || (!(s.cpu__gen_csr__csr__i_trap) && (if decide ((BitVec.ofNat 32 1).toNat = (BitVec.ofNat 32 1).toNat) then BitVec.getLsbD (s.cpu__gen_csr__csr__mcause3_0) 1 else s.cpu__gen_csr__csr__csr_in)))) else s.cpu__gen_csr__csr__mcause3_0)
    cpu__gen_csr__csr__mie_mtie := (if s.cpu__gen_csr__csr__i_rst then false else (if (s.cpu__gen_csr__csr__i_mie_en && s.cpu__gen_csr__csr__i_cnt7) then s.cpu__gen_csr__csr__csr_in else s.cpu__gen_csr__csr__mie_mtie))
    cpu__gen_csr__csr__mstatus_mie := (if (((s.cpu__gen_csr__csr__i_trap && s.cpu__gen_csr__csr__i_cnt_done) || ((s.cpu__gen_csr__csr__i_mstatus_en && s.cpu__gen_csr__csr__i_cnt3) && s.cpu__gen_csr__csr__i_en)) || s.cpu__gen_csr__csr__i_mret) then (!(s.cpu__gen_csr__csr__i_trap) && (if s.cpu__gen_csr__csr__i_mret then s.cpu__gen_csr__csr__mstatus_mpie else s.cpu__gen_csr__csr__csr_in)) else s.cpu__gen_csr__csr__mstatus_mie)
    cpu__gen_csr__csr__mstatus_mpie := (if (s.cpu__gen_csr__csr__i_trap && s.cpu__gen_csr__csr__i_cnt_done) then s.cpu__gen_csr__csr__mstatus_mie else s.cpu__gen_csr__csr__mstatus_mpie)
    cpu__gen_csr__csr__o_new_irq := (if s.cpu__gen_csr__csr__i_rst then false else (if s.cpu__gen_csr__csr__i_trig_irq then (s.cpu__gen_csr__csr__timer_irq && !(s.cpu__gen_csr__csr__timer_irq_r)) else s.cpu__gen_csr__csr__o_new_irq))
    cpu__gen_csr__csr__timer_irq_r := (if s.cpu__gen_csr__csr__i_trig_irq then s.cpu__gen_csr__csr__timer_irq else s.cpu__gen_csr__csr__timer_irq_r)
  }

/-- Parallel nonblocking commit for the single clock domain -/
def commit (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
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
  let result := {
    cpu__alu__add_cy_r := s15.cpu__alu__add_cy_r
    cpu__alu__cmp_r := s15.cpu__alu__cmp_r
    cpu__bufreg2__dhi := s13.cpu__bufreg2__dhi
    cpu__bufreg2__dlo := s13.cpu__bufreg2__dlo
    cpu__bufreg__c_r := s11.cpu__bufreg__c_r
    cpu__bufreg__data := s12.cpu__bufreg__data
    cpu__ctrl__o_ibus_adr := s14.cpu__ctrl__o_ibus_adr
    cpu__ctrl__pc_plus_4_cy_r := s14.cpu__ctrl__pc_plus_4_cy_r
    cpu__ctrl__pc_plus_offset_cy_r := s14.cpu__ctrl__pc_plus_offset_cy_r
    cpu__decode__funct3 := s9.cpu__decode__funct3
    cpu__decode__imm25 := s9.cpu__decode__imm25
    cpu__decode__imm30 := s9.cpu__decode__imm30
    cpu__decode__op20 := s9.cpu__decode__op20
    cpu__decode__op21 := s9.cpu__decode__op21
    cpu__decode__op22 := s9.cpu__decode__op22
    cpu__decode__op26 := s9.cpu__decode__op26
    cpu__decode__opcode := s9.cpu__decode__opcode
    cpu__gen_csr__csr__mcause31 := s17.cpu__gen_csr__csr__mcause31
    cpu__gen_csr__csr__mcause3_0 := s17.cpu__gen_csr__csr__mcause3_0
    cpu__gen_csr__csr__mie_mtie := s17.cpu__gen_csr__csr__mie_mtie
    cpu__gen_csr__csr__mstatus_mie := s17.cpu__gen_csr__csr__mstatus_mie
    cpu__gen_csr__csr__mstatus_mpie := s17.cpu__gen_csr__csr__mstatus_mpie
    cpu__gen_csr__csr__o_new_irq := s17.cpu__gen_csr__csr__o_new_irq
    cpu__gen_csr__csr__timer_irq_r := s17.cpu__gen_csr__csr__timer_irq_r
    cpu__immdec__gen_immdec_w_eq_1__imm11_7 := s10.cpu__immdec__gen_immdec_w_eq_1__imm11_7
    cpu__immdec__gen_immdec_w_eq_1__imm19_12_20 := s10.cpu__immdec__gen_immdec_w_eq_1__imm19_12_20
    cpu__immdec__gen_immdec_w_eq_1__imm24_20 := s10.cpu__immdec__gen_immdec_w_eq_1__imm24_20
    cpu__immdec__gen_immdec_w_eq_1__imm30_25 := s10.cpu__immdec__gen_immdec_w_eq_1__imm30_25
    cpu__immdec__gen_immdec_w_eq_1__imm31 := s10.cpu__immdec__gen_immdec_w_eq_1__imm31
    cpu__immdec__gen_immdec_w_eq_1__imm7 := s10.cpu__immdec__gen_immdec_w_eq_1__imm7
    cpu__mem_if__signbit := s16.cpu__mem_if__signbit
    cpu__state__gen_cnt_w_eq_1__cnt_lsb := s7.cpu__state__gen_cnt_w_eq_1__cnt_lsb
    cpu__state__gen_csr__misalign_trap_sync_r := s8.cpu__state__gen_csr__misalign_trap_sync_r
    cpu__state__ibus_cyc := s6.cpu__state__ibus_cyc
    cpu__state__init_done := s6.cpu__state__init_done
    cpu__state__o_cnt := s7.cpu__state__o_cnt
    cpu__state__o_ctrl_jump := s6.cpu__state__o_ctrl_jump
    rf_ram__memory := s4.rf_ram__memory
    rf_ram__rdata := s4.rf_ram__rdata
    rf_ram__regzero := s5.rf_ram__regzero
    rf_ram_if__rcnt := s3.rf_ram_if__rcnt
    rf_ram_if__rdata0 := s3.rf_ram_if__rdata0
    rf_ram_if__rdata1 := s2.rf_ram_if__rdata1
    rf_ram_if__rgate := s3.rf_ram_if__rgate
    rf_ram_if__rgnt := s3.rf_ram_if__rgnt
    rf_ram_if__rreq_r := s3.rf_ram_if__rreq_r
    rf_ram_if__rtrig1 := s3.rf_ram_if__rtrig1
    rf_ram_if__wdata0_r := s1.rf_ram_if__wdata0_r
    rf_ram_if__wdata1_r := s1.rf_ram_if__wdata1_r
    rf_ram_if__wen0_r := s1.rf_ram_if__wen0_r
    rf_ram_if__wen1_r := s1.rf_ram_if__wen1_r
    rf_wreq := s.rf_wreq
    rf_rreq := s.rf_rreq
    wreg0 := s.wreg0
    wreg1 := s.wreg1
    wen0 := s.wen0
    wen1 := s.wen1
    wdata0 := s.wdata0
    wdata1 := s.wdata1
    rreg0 := s.rreg0
    rreg1 := s.rreg1
    rf_ready := s.rf_ready
    rdata0 := s.rdata0
    rdata1 := s.rdata1
    waddr := s.waddr
    wdata := s.wdata
    wen := s.wen
    raddr := s.raddr
    ren := s.ren
    rdata := s.rdata
    rf_ram_if__i_clk := s.rf_ram_if__i_clk
    rf_ram_if__i_rst := s.rf_ram_if__i_rst
    rf_ram_if__i_wreq := s.rf_ram_if__i_wreq
    rf_ram_if__i_rreq := s.rf_ram_if__i_rreq
    rf_ram_if__o_ready := s.rf_ram_if__o_ready
    rf_ram_if__i_wreg0 := s.rf_ram_if__i_wreg0
    rf_ram_if__i_wreg1 := s.rf_ram_if__i_wreg1
    rf_ram_if__i_wen0 := s.rf_ram_if__i_wen0
    rf_ram_if__i_wen1 := s.rf_ram_if__i_wen1
    rf_ram_if__i_wdata0 := s.rf_ram_if__i_wdata0
    rf_ram_if__i_wdata1 := s.rf_ram_if__i_wdata1
    rf_ram_if__i_rreg0 := s.rf_ram_if__i_rreg0
    rf_ram_if__i_rreg1 := s.rf_ram_if__i_rreg1
    rf_ram_if__o_rdata0 := s.rf_ram_if__o_rdata0
    rf_ram_if__o_rdata1 := s.rf_ram_if__o_rdata1
    rf_ram_if__o_waddr := s.rf_ram_if__o_waddr
    rf_ram_if__o_wdata := s.rf_ram_if__o_wdata
    rf_ram_if__o_wen := s.rf_ram_if__o_wen
    rf_ram_if__o_raddr := s.rf_ram_if__o_raddr
    rf_ram_if__o_ren := s.rf_ram_if__o_ren
    rf_ram_if__i_rdata := s.rf_ram_if__i_rdata
    rf_ram_if__wcnt := s.rf_ram_if__wcnt
    rf_ram_if__wtrig0 := s.rf_ram_if__wtrig0
    rf_ram_if__wtrig1 := s.rf_ram_if__wtrig1
    rf_ram_if__wreg := s.rf_ram_if__wreg
    rf_ram_if__rtrig0 := s.rf_ram_if__rtrig0
    rf_ram_if__rreg := s.rf_ram_if__rreg
    rf_ram__i_clk := s.rf_ram__i_clk
    rf_ram__i_waddr := s.rf_ram__i_waddr
    rf_ram__i_wdata := s.rf_ram__i_wdata
    rf_ram__i_wen := s.rf_ram__i_wen
    rf_ram__i_raddr := s.rf_ram__i_raddr
    rf_ram__i_ren := s.rf_ram__i_ren
    rf_ram__o_rdata := s.rf_ram__o_rdata
    cpu__clk := s.cpu__clk
    cpu__i_rst := s.cpu__i_rst
    cpu__i_timer_irq := s.cpu__i_timer_irq
    cpu__o_rf_rreq := s.cpu__o_rf_rreq
    cpu__o_rf_wreq := s.cpu__o_rf_wreq
    cpu__i_rf_ready := s.cpu__i_rf_ready
    cpu__o_wreg0 := s.cpu__o_wreg0
    cpu__o_wreg1 := s.cpu__o_wreg1
    cpu__o_wen0 := s.cpu__o_wen0
    cpu__o_wen1 := s.cpu__o_wen1
    cpu__o_wdata0 := s.cpu__o_wdata0
    cpu__o_wdata1 := s.cpu__o_wdata1
    cpu__o_rreg0 := s.cpu__o_rreg0
    cpu__o_rreg1 := s.cpu__o_rreg1
    cpu__i_rdata0 := s.cpu__i_rdata0
    cpu__i_rdata1 := s.cpu__i_rdata1
    cpu__o_ibus_adr := s.cpu__o_ibus_adr
    cpu__o_ibus_cyc := s.cpu__o_ibus_cyc
    cpu__i_ibus_rdt := s.cpu__i_ibus_rdt
    cpu__i_ibus_ack := s.cpu__i_ibus_ack
    cpu__o_dbus_adr := s.cpu__o_dbus_adr
    cpu__o_dbus_dat := s.cpu__o_dbus_dat
    cpu__o_dbus_sel := s.cpu__o_dbus_sel
    cpu__o_dbus_we := s.cpu__o_dbus_we
    cpu__o_dbus_cyc := s.cpu__o_dbus_cyc
    cpu__i_dbus_rdt := s.cpu__i_dbus_rdt
    cpu__i_dbus_ack := s.cpu__i_dbus_ack
    cpu__o_ext_funct3 := s.cpu__o_ext_funct3
    cpu__i_ext_ready := s.cpu__i_ext_ready
    cpu__i_ext_rd := s.cpu__i_ext_rd
    cpu__o_ext_rs1 := s.cpu__o_ext_rs1
    cpu__o_ext_rs2 := s.cpu__o_ext_rs2
    cpu__o_mdu_valid := s.cpu__o_mdu_valid
    cpu__rd_addr := s.cpu__rd_addr
    cpu__rs1_addr := s.cpu__rs1_addr
    cpu__rs2_addr := s.cpu__rs2_addr
    cpu__immdec_ctrl := s.cpu__immdec_ctrl
    cpu__immdec_en := s.cpu__immdec_en
    cpu__sh_right := s.cpu__sh_right
    cpu__bne_or_bge := s.cpu__bne_or_bge
    cpu__cond_branch := s.cpu__cond_branch
    cpu__two_stage_op := s.cpu__two_stage_op
    cpu__e_op := s.cpu__e_op
    cpu__ebreak := s.cpu__ebreak
    cpu__branch_op := s.cpu__branch_op
    cpu__shift_op := s.cpu__shift_op
    cpu__rd_op := s.cpu__rd_op
    cpu__mdu_op := s.cpu__mdu_op
    cpu__rd_alu_en := s.cpu__rd_alu_en
    cpu__rd_csr_en := s.cpu__rd_csr_en
    cpu__rd_mem_en := s.cpu__rd_mem_en
    cpu__ctrl_rd := s.cpu__ctrl_rd
    cpu__alu_rd := s.cpu__alu_rd
    cpu__mem_rd := s.cpu__mem_rd
    cpu__csr_rd := s.cpu__csr_rd
    cpu__mtval_pc := s.cpu__mtval_pc
    cpu__ctrl_pc_en := s.cpu__ctrl_pc_en
    cpu__jump := s.cpu__jump
    cpu__jal_or_jalr := s.cpu__jal_or_jalr
    cpu__utype := s.cpu__utype
    cpu__mret := s.cpu__mret
    cpu__imm := s.cpu__imm
    cpu__trap := s.cpu__trap
    cpu__pc_rel := s.cpu__pc_rel
    cpu__iscomp := s.cpu__iscomp
    cpu__init := s.cpu__init
    cpu__cnt_en := s.cpu__cnt_en
    cpu__cnt0to3 := s.cpu__cnt0to3
    cpu__cnt12to31 := s.cpu__cnt12to31
    cpu__cnt0 := s.cpu__cnt0
    cpu__cnt1 := s.cpu__cnt1
    cpu__cnt2 := s.cpu__cnt2
    cpu__cnt3 := s.cpu__cnt3
    cpu__cnt7 := s.cpu__cnt7
    cpu__cnt11 := s.cpu__cnt11
    cpu__cnt12 := s.cpu__cnt12
    cpu__cnt_done := s.cpu__cnt_done
    cpu__bufreg_en := s.cpu__bufreg_en
    cpu__bufreg_sh_signed := s.cpu__bufreg_sh_signed
    cpu__bufreg_rs1_en := s.cpu__bufreg_rs1_en
    cpu__bufreg_imm_en := s.cpu__bufreg_imm_en
    cpu__bufreg_clr_lsb := s.cpu__bufreg_clr_lsb
    cpu__bufreg_q := s.cpu__bufreg_q
    cpu__bufreg2_q := s.cpu__bufreg2_q
    cpu__dbus_rdt := s.cpu__dbus_rdt
    cpu__dbus_ack := s.cpu__dbus_ack
    cpu__alu_sub := s.cpu__alu_sub
    cpu__alu_bool_op := s.cpu__alu_bool_op
    cpu__alu_cmp_eq := s.cpu__alu_cmp_eq
    cpu__alu_cmp_sig := s.cpu__alu_cmp_sig
    cpu__alu_cmp := s.cpu__alu_cmp
    cpu__alu_rd_sel := s.cpu__alu_rd_sel
    cpu__rs1 := s.cpu__rs1
    cpu__rs2 := s.cpu__rs2
    cpu__rd_en := s.cpu__rd_en
    cpu__op_b := s.cpu__op_b
    cpu__op_b_sel := s.cpu__op_b_sel
    cpu__mem_signed := s.cpu__mem_signed
    cpu__mem_word := s.cpu__mem_word
    cpu__mem_half := s.cpu__mem_half
    cpu__mem_bytecnt := s.cpu__mem_bytecnt
    cpu__sh_done := s.cpu__sh_done
    cpu__mem_misalign := s.cpu__mem_misalign
    cpu__bad_pc := s.cpu__bad_pc
    cpu__csr_mstatus_en := s.cpu__csr_mstatus_en
    cpu__csr_mie_en := s.cpu__csr_mie_en
    cpu__csr_mcause_en := s.cpu__csr_mcause_en
    cpu__csr_source := s.cpu__csr_source
    cpu__csr_imm := s.cpu__csr_imm
    cpu__csr_d_sel := s.cpu__csr_d_sel
    cpu__csr_en := s.cpu__csr_en
    cpu__csr_addr := s.cpu__csr_addr
    cpu__csr_pc := s.cpu__csr_pc
    cpu__csr_imm_en := s.cpu__csr_imm_en
    cpu__csr_in := s.cpu__csr_in
    cpu__rf_csr_out := s.cpu__rf_csr_out
    cpu__dbus_en := s.cpu__dbus_en
    cpu__new_irq := s.cpu__new_irq
    cpu__lsb := s.cpu__lsb
    cpu__i_wb_rdt := s.cpu__i_wb_rdt
    cpu__wb_ibus_adr := s.cpu__wb_ibus_adr
    cpu__wb_ibus_cyc := s.cpu__wb_ibus_cyc
    cpu__wb_ibus_rdt := s.cpu__wb_ibus_rdt
    cpu__wb_ibus_ack := s.cpu__wb_ibus_ack
    cpu__state__i_clk := s.cpu__state__i_clk
    cpu__state__i_rst := s.cpu__state__i_rst
    cpu__state__i_new_irq := s.cpu__state__i_new_irq
    cpu__state__i_alu_cmp := s.cpu__state__i_alu_cmp
    cpu__state__o_init := s.cpu__state__o_init
    cpu__state__o_cnt_en := s.cpu__state__o_cnt_en
    cpu__state__o_cnt0to3 := s.cpu__state__o_cnt0to3
    cpu__state__o_cnt12to31 := s.cpu__state__o_cnt12to31
    cpu__state__o_cnt0 := s.cpu__state__o_cnt0
    cpu__state__o_cnt1 := s.cpu__state__o_cnt1
    cpu__state__o_cnt2 := s.cpu__state__o_cnt2
    cpu__state__o_cnt3 := s.cpu__state__o_cnt3
    cpu__state__o_cnt7 := s.cpu__state__o_cnt7
    cpu__state__o_cnt11 := s.cpu__state__o_cnt11
    cpu__state__o_cnt12 := s.cpu__state__o_cnt12
    cpu__state__o_cnt_done := s.cpu__state__o_cnt_done
    cpu__state__o_bufreg_en := s.cpu__state__o_bufreg_en
    cpu__state__o_ctrl_pc_en := s.cpu__state__o_ctrl_pc_en
    cpu__state__o_ctrl_trap := s.cpu__state__o_ctrl_trap
    cpu__state__i_ctrl_misalign := s.cpu__state__i_ctrl_misalign
    cpu__state__i_sh_done := s.cpu__state__i_sh_done
    cpu__state__o_mem_bytecnt := s.cpu__state__o_mem_bytecnt
    cpu__state__i_mem_misalign := s.cpu__state__i_mem_misalign
    cpu__state__i_bne_or_bge := s.cpu__state__i_bne_or_bge
    cpu__state__i_cond_branch := s.cpu__state__i_cond_branch
    cpu__state__i_dbus_en := s.cpu__state__i_dbus_en
    cpu__state__i_two_stage_op := s.cpu__state__i_two_stage_op
    cpu__state__i_branch_op := s.cpu__state__i_branch_op
    cpu__state__i_shift_op := s.cpu__state__i_shift_op
    cpu__state__i_sh_right := s.cpu__state__i_sh_right
    cpu__state__i_alu_rd_sel1 := s.cpu__state__i_alu_rd_sel1
    cpu__state__i_rd_alu_en := s.cpu__state__i_rd_alu_en
    cpu__state__i_e_op := s.cpu__state__i_e_op
    cpu__state__i_rd_op := s.cpu__state__i_rd_op
    cpu__state__i_mdu_op := s.cpu__state__i_mdu_op
    cpu__state__o_mdu_valid := s.cpu__state__o_mdu_valid
    cpu__state__i_mdu_ready := s.cpu__state__i_mdu_ready
    cpu__state__o_dbus_cyc := s.cpu__state__o_dbus_cyc
    cpu__state__i_dbus_ack := s.cpu__state__i_dbus_ack
    cpu__state__o_ibus_cyc := s.cpu__state__o_ibus_cyc
    cpu__state__i_ibus_ack := s.cpu__state__i_ibus_ack
    cpu__state__o_rf_rreq := s.cpu__state__o_rf_rreq
    cpu__state__o_rf_wreq := s.cpu__state__o_rf_wreq
    cpu__state__i_rf_ready := s.cpu__state__i_rf_ready
    cpu__state__o_rf_rd_en := s.cpu__state__o_rf_rd_en
    cpu__state__misalign_trap_sync := s.cpu__state__misalign_trap_sync
    cpu__state__cnt_r := s.cpu__state__cnt_r
    cpu__state__take_branch := s.cpu__state__take_branch
    cpu__state__last_init := s.cpu__state__last_init
    cpu__state__trap_pending := s.cpu__state__trap_pending
    cpu__decode__clk := s.cpu__decode__clk
    cpu__decode__i_wb_rdt := s.cpu__decode__i_wb_rdt
    cpu__decode__i_wb_en := s.cpu__decode__i_wb_en
    cpu__decode__co_mdu_op := s.cpu__decode__co_mdu_op
    cpu__decode__co_two_stage_op := s.cpu__decode__co_two_stage_op
    cpu__decode__co_shift_op := s.cpu__decode__co_shift_op
    cpu__decode__co_branch_op := s.cpu__decode__co_branch_op
    cpu__decode__co_dbus_en := s.cpu__decode__co_dbus_en
    cpu__decode__co_mtval_pc := s.cpu__decode__co_mtval_pc
    cpu__decode__co_mem_word := s.cpu__decode__co_mem_word
    cpu__decode__co_rd_alu_en := s.cpu__decode__co_rd_alu_en
    cpu__decode__co_rd_mem_en := s.cpu__decode__co_rd_mem_en
    cpu__decode__co_ext_funct3 := s.cpu__decode__co_ext_funct3
    cpu__decode__co_bufreg_rs1_en := s.cpu__decode__co_bufreg_rs1_en
    cpu__decode__co_bufreg_imm_en := s.cpu__decode__co_bufreg_imm_en
    cpu__decode__co_bufreg_clr_lsb := s.cpu__decode__co_bufreg_clr_lsb
    cpu__decode__co_cond_branch := s.cpu__decode__co_cond_branch
    cpu__decode__co_ctrl_utype := s.cpu__decode__co_ctrl_utype
    cpu__decode__co_ctrl_jal_or_jalr := s.cpu__decode__co_ctrl_jal_or_jalr
    cpu__decode__co_ctrl_pc_rel := s.cpu__decode__co_ctrl_pc_rel
    cpu__decode__co_rd_op := s.cpu__decode__co_rd_op
    cpu__decode__co_sh_right := s.cpu__decode__co_sh_right
    cpu__decode__co_bne_or_bge := s.cpu__decode__co_bne_or_bge
    cpu__decode__csr_op := s.cpu__decode__csr_op
    cpu__decode__co_ebreak := s.cpu__decode__co_ebreak
    cpu__decode__co_ctrl_mret := s.cpu__decode__co_ctrl_mret
    cpu__decode__co_e_op := s.cpu__decode__co_e_op
    cpu__decode__co_bufreg_sh_signed := s.cpu__decode__co_bufreg_sh_signed
    cpu__decode__co_alu_sub := s.cpu__decode__co_alu_sub
    cpu__decode__csr_valid := s.cpu__decode__csr_valid
    cpu__decode__co_rd_csr_en := s.cpu__decode__co_rd_csr_en
    cpu__decode__co_csr_en := s.cpu__decode__co_csr_en
    cpu__decode__co_csr_mstatus_en := s.cpu__decode__co_csr_mstatus_en
    cpu__decode__co_csr_mie_en := s.cpu__decode__co_csr_mie_en
    cpu__decode__co_csr_mcause_en := s.cpu__decode__co_csr_mcause_en
    cpu__decode__co_csr_source := s.cpu__decode__co_csr_source
    cpu__decode__co_csr_d_sel := s.cpu__decode__co_csr_d_sel
    cpu__decode__co_csr_imm_en := s.cpu__decode__co_csr_imm_en
    cpu__decode__co_csr_addr := s.cpu__decode__co_csr_addr
    cpu__decode__co_alu_cmp_eq := s.cpu__decode__co_alu_cmp_eq
    cpu__decode__co_alu_cmp_sig := s.cpu__decode__co_alu_cmp_sig
    cpu__decode__co_mem_cmd := s.cpu__decode__co_mem_cmd
    cpu__decode__co_mem_signed := s.cpu__decode__co_mem_signed
    cpu__decode__co_mem_half := s.cpu__decode__co_mem_half
    cpu__decode__co_alu_bool_op := s.cpu__decode__co_alu_bool_op
    cpu__decode__co_immdec_ctrl := s.cpu__decode__co_immdec_ctrl
    cpu__decode__co_immdec_en := s.cpu__decode__co_immdec_en
    cpu__decode__co_alu_rd_sel := s.cpu__decode__co_alu_rd_sel
    cpu__decode__co_op_b_source := s.cpu__decode__co_op_b_source
    cpu__immdec__i_clk := s.cpu__immdec__i_clk
    cpu__immdec__i_cnt_en := s.cpu__immdec__i_cnt_en
    cpu__immdec__i_cnt_done := s.cpu__immdec__i_cnt_done
    cpu__immdec__i_immdec_en := s.cpu__immdec__i_immdec_en
    cpu__immdec__i_csr_imm_en := s.cpu__immdec__i_csr_imm_en
    cpu__immdec__i_ctrl := s.cpu__immdec__i_ctrl
    cpu__immdec__o_rd_addr := s.cpu__immdec__o_rd_addr
    cpu__immdec__o_rs1_addr := s.cpu__immdec__o_rs1_addr
    cpu__immdec__o_rs2_addr := s.cpu__immdec__o_rs2_addr
    cpu__immdec__o_csr_imm := s.cpu__immdec__o_csr_imm
    cpu__immdec__o_imm := s.cpu__immdec__o_imm
    cpu__immdec__i_wb_en := s.cpu__immdec__i_wb_en
    cpu__immdec__i_wb_rdt := s.cpu__immdec__i_wb_rdt
    cpu__immdec__gen_immdec_w_eq_1__signbit := s.cpu__immdec__gen_immdec_w_eq_1__signbit
    cpu__bufreg__i_clk := s.cpu__bufreg__i_clk
    cpu__bufreg__i_cnt0 := s.cpu__bufreg__i_cnt0
    cpu__bufreg__i_cnt1 := s.cpu__bufreg__i_cnt1
    cpu__bufreg__i_cnt_done := s.cpu__bufreg__i_cnt_done
    cpu__bufreg__i_en := s.cpu__bufreg__i_en
    cpu__bufreg__i_init := s.cpu__bufreg__i_init
    cpu__bufreg__i_mdu_op := s.cpu__bufreg__i_mdu_op
    cpu__bufreg__o_lsb := s.cpu__bufreg__o_lsb
    cpu__bufreg__i_rs1_en := s.cpu__bufreg__i_rs1_en
    cpu__bufreg__i_imm_en := s.cpu__bufreg__i_imm_en
    cpu__bufreg__i_clr_lsb := s.cpu__bufreg__i_clr_lsb
    cpu__bufreg__i_shift_op := s.cpu__bufreg__i_shift_op
    cpu__bufreg__i_right_shift_op := s.cpu__bufreg__i_right_shift_op
    cpu__bufreg__i_shamt := s.cpu__bufreg__i_shamt
    cpu__bufreg__i_sh_signed := s.cpu__bufreg__i_sh_signed
    cpu__bufreg__i_rs1 := s.cpu__bufreg__i_rs1
    cpu__bufreg__i_imm := s.cpu__bufreg__i_imm
    cpu__bufreg__o_q := s.cpu__bufreg__o_q
    cpu__bufreg__o_dbus_adr := s.cpu__bufreg__o_dbus_adr
    cpu__bufreg__o_ext_rs1 := s.cpu__bufreg__o_ext_rs1
    cpu__bufreg__c := s.cpu__bufreg__c
    cpu__bufreg__q := s.cpu__bufreg__q
    cpu__bufreg__clr_lsb := s.cpu__bufreg__clr_lsb
    cpu__bufreg2__i_clk := s.cpu__bufreg2__i_clk
    cpu__bufreg2__i_en := s.cpu__bufreg2__i_en
    cpu__bufreg2__i_init := s.cpu__bufreg2__i_init
    cpu__bufreg2__i_cnt7 := s.cpu__bufreg2__i_cnt7
    cpu__bufreg2__i_cnt_done := s.cpu__bufreg2__i_cnt_done
    cpu__bufreg2__i_sh_right := s.cpu__bufreg2__i_sh_right
    cpu__bufreg2__i_lsb := s.cpu__bufreg2__i_lsb
    cpu__bufreg2__i_bytecnt := s.cpu__bufreg2__i_bytecnt
    cpu__bufreg2__o_sh_done := s.cpu__bufreg2__o_sh_done
    cpu__bufreg2__i_op_b_sel := s.cpu__bufreg2__i_op_b_sel
    cpu__bufreg2__i_shift_op := s.cpu__bufreg2__i_shift_op
    cpu__bufreg2__i_rs2 := s.cpu__bufreg2__i_rs2
    cpu__bufreg2__i_imm := s.cpu__bufreg2__i_imm
    cpu__bufreg2__o_op_b := s.cpu__bufreg2__o_op_b
    cpu__bufreg2__o_q := s.cpu__bufreg2__o_q
    cpu__bufreg2__o_dat := s.cpu__bufreg2__o_dat
    cpu__bufreg2__i_load := s.cpu__bufreg2__i_load
    cpu__bufreg2__i_dat := s.cpu__bufreg2__i_dat
    cpu__bufreg2__byte_valid := s.cpu__bufreg2__byte_valid
    cpu__bufreg2__shift_en := s.cpu__bufreg2__shift_en
    cpu__bufreg2__cnt_en := s.cpu__bufreg2__cnt_en
    cpu__bufreg2__cnt_next := s.cpu__bufreg2__cnt_next
    cpu__bufreg2__dat_shamt := s.cpu__bufreg2__dat_shamt
    cpu__ctrl__clk := s.cpu__ctrl__clk
    cpu__ctrl__i_rst := s.cpu__ctrl__i_rst
    cpu__ctrl__i_pc_en := s.cpu__ctrl__i_pc_en
    cpu__ctrl__i_cnt12to31 := s.cpu__ctrl__i_cnt12to31
    cpu__ctrl__i_cnt0 := s.cpu__ctrl__i_cnt0
    cpu__ctrl__i_cnt1 := s.cpu__ctrl__i_cnt1
    cpu__ctrl__i_cnt2 := s.cpu__ctrl__i_cnt2
    cpu__ctrl__i_jump := s.cpu__ctrl__i_jump
    cpu__ctrl__i_jal_or_jalr := s.cpu__ctrl__i_jal_or_jalr
    cpu__ctrl__i_utype := s.cpu__ctrl__i_utype
    cpu__ctrl__i_pc_rel := s.cpu__ctrl__i_pc_rel
    cpu__ctrl__i_trap := s.cpu__ctrl__i_trap
    cpu__ctrl__i_iscomp := s.cpu__ctrl__i_iscomp
    cpu__ctrl__i_imm := s.cpu__ctrl__i_imm
    cpu__ctrl__i_buf := s.cpu__ctrl__i_buf
    cpu__ctrl__i_csr_pc := s.cpu__ctrl__i_csr_pc
    cpu__ctrl__o_rd := s.cpu__ctrl__o_rd
    cpu__ctrl__o_bad_pc := s.cpu__ctrl__o_bad_pc
    cpu__ctrl__pc_plus_4 := s.cpu__ctrl__pc_plus_4
    cpu__ctrl__pc_plus_4_cy := s.cpu__ctrl__pc_plus_4_cy
    cpu__ctrl__pc_plus_4_cy_r_w := s.cpu__ctrl__pc_plus_4_cy_r_w
    cpu__ctrl__pc_plus_offset := s.cpu__ctrl__pc_plus_offset
    cpu__ctrl__pc_plus_offset_cy := s.cpu__ctrl__pc_plus_offset_cy
    cpu__ctrl__pc_plus_offset_cy_r_w := s.cpu__ctrl__pc_plus_offset_cy_r_w
    cpu__ctrl__pc_plus_offset_aligned := s.cpu__ctrl__pc_plus_offset_aligned
    cpu__ctrl__plus_4 := s.cpu__ctrl__plus_4
    cpu__ctrl__pc := s.cpu__ctrl__pc
    cpu__ctrl__new_pc := s.cpu__ctrl__new_pc
    cpu__ctrl__offset_a := s.cpu__ctrl__offset_a
    cpu__ctrl__offset_b := s.cpu__ctrl__offset_b
    cpu__alu__clk := s.cpu__alu__clk
    cpu__alu__i_en := s.cpu__alu__i_en
    cpu__alu__i_cnt0 := s.cpu__alu__i_cnt0
    cpu__alu__o_cmp := s.cpu__alu__o_cmp
    cpu__alu__i_sub := s.cpu__alu__i_sub
    cpu__alu__i_bool_op := s.cpu__alu__i_bool_op
    cpu__alu__i_cmp_eq := s.cpu__alu__i_cmp_eq
    cpu__alu__i_cmp_sig := s.cpu__alu__i_cmp_sig
    cpu__alu__i_rd_sel := s.cpu__alu__i_rd_sel
    cpu__alu__i_rs1 := s.cpu__alu__i_rs1
    cpu__alu__i_op_b := s.cpu__alu__i_op_b
    cpu__alu__i_buf := s.cpu__alu__i_buf
    cpu__alu__o_rd := s.cpu__alu__o_rd
    cpu__alu__result_add := s.cpu__alu__result_add
    cpu__alu__result_slt := s.cpu__alu__result_slt
    cpu__alu__add_cy := s.cpu__alu__add_cy
    cpu__alu__rs1_sx := s.cpu__alu__rs1_sx
    cpu__alu__op_b_sx := s.cpu__alu__op_b_sx
    cpu__alu__add_b := s.cpu__alu__add_b
    cpu__alu__result_lt := s.cpu__alu__result_lt
    cpu__alu__result_eq := s.cpu__alu__result_eq
    cpu__alu__result_bool := s.cpu__alu__result_bool
    cpu__rf_if__i_cnt_en := s.cpu__rf_if__i_cnt_en
    cpu__rf_if__o_wreg0 := s.cpu__rf_if__o_wreg0
    cpu__rf_if__o_wreg1 := s.cpu__rf_if__o_wreg1
    cpu__rf_if__o_wen0 := s.cpu__rf_if__o_wen0
    cpu__rf_if__o_wen1 := s.cpu__rf_if__o_wen1
    cpu__rf_if__o_wdata0 := s.cpu__rf_if__o_wdata0
    cpu__rf_if__o_wdata1 := s.cpu__rf_if__o_wdata1
    cpu__rf_if__o_rreg0 := s.cpu__rf_if__o_rreg0
    cpu__rf_if__o_rreg1 := s.cpu__rf_if__o_rreg1
    cpu__rf_if__i_rdata0 := s.cpu__rf_if__i_rdata0
    cpu__rf_if__i_rdata1 := s.cpu__rf_if__i_rdata1
    cpu__rf_if__i_trap := s.cpu__rf_if__i_trap
    cpu__rf_if__i_mret := s.cpu__rf_if__i_mret
    cpu__rf_if__i_mepc := s.cpu__rf_if__i_mepc
    cpu__rf_if__i_mtval_pc := s.cpu__rf_if__i_mtval_pc
    cpu__rf_if__i_bufreg_q := s.cpu__rf_if__i_bufreg_q
    cpu__rf_if__i_bad_pc := s.cpu__rf_if__i_bad_pc
    cpu__rf_if__o_csr_pc := s.cpu__rf_if__o_csr_pc
    cpu__rf_if__i_csr_en := s.cpu__rf_if__i_csr_en
    cpu__rf_if__i_csr_addr := s.cpu__rf_if__i_csr_addr
    cpu__rf_if__i_csr := s.cpu__rf_if__i_csr
    cpu__rf_if__o_csr := s.cpu__rf_if__o_csr
    cpu__rf_if__i_rd_wen := s.cpu__rf_if__i_rd_wen
    cpu__rf_if__i_rd_waddr := s.cpu__rf_if__i_rd_waddr
    cpu__rf_if__i_ctrl_rd := s.cpu__rf_if__i_ctrl_rd
    cpu__rf_if__i_alu_rd := s.cpu__rf_if__i_alu_rd
    cpu__rf_if__i_rd_alu_en := s.cpu__rf_if__i_rd_alu_en
    cpu__rf_if__i_csr_rd := s.cpu__rf_if__i_csr_rd
    cpu__rf_if__i_rd_csr_en := s.cpu__rf_if__i_rd_csr_en
    cpu__rf_if__i_mem_rd := s.cpu__rf_if__i_mem_rd
    cpu__rf_if__i_rd_mem_en := s.cpu__rf_if__i_rd_mem_en
    cpu__rf_if__i_rs1_raddr := s.cpu__rf_if__i_rs1_raddr
    cpu__rf_if__o_rs1 := s.cpu__rf_if__o_rs1
    cpu__rf_if__i_rs2_raddr := s.cpu__rf_if__i_rs2_raddr
    cpu__rf_if__o_rs2 := s.cpu__rf_if__o_rs2
    cpu__rf_if__rd_wen := s.cpu__rf_if__rd_wen
    cpu__rf_if__gen_csr__rd := s.cpu__rf_if__gen_csr__rd
    cpu__rf_if__gen_csr__mtval := s.cpu__rf_if__gen_csr__mtval
    cpu__rf_if__gen_csr__sel_rs2 := s.cpu__rf_if__gen_csr__sel_rs2
    cpu__mem_if__i_clk := s.cpu__mem_if__i_clk
    cpu__mem_if__i_bytecnt := s.cpu__mem_if__i_bytecnt
    cpu__mem_if__i_lsb := s.cpu__mem_if__i_lsb
    cpu__mem_if__o_misalign := s.cpu__mem_if__o_misalign
    cpu__mem_if__i_signed := s.cpu__mem_if__i_signed
    cpu__mem_if__i_word := s.cpu__mem_if__i_word
    cpu__mem_if__i_half := s.cpu__mem_if__i_half
    cpu__mem_if__i_mdu_op := s.cpu__mem_if__i_mdu_op
    cpu__mem_if__i_bufreg2_q := s.cpu__mem_if__i_bufreg2_q
    cpu__mem_if__o_rd := s.cpu__mem_if__o_rd
    cpu__mem_if__o_wb_sel := s.cpu__mem_if__o_wb_sel
    cpu__mem_if__dat_valid := s.cpu__mem_if__dat_valid
    cpu__gen_csr__csr__i_clk := s.cpu__gen_csr__csr__i_clk
    cpu__gen_csr__csr__i_rst := s.cpu__gen_csr__csr__i_rst
    cpu__gen_csr__csr__i_trig_irq := s.cpu__gen_csr__csr__i_trig_irq
    cpu__gen_csr__csr__i_en := s.cpu__gen_csr__csr__i_en
    cpu__gen_csr__csr__i_cnt0to3 := s.cpu__gen_csr__csr__i_cnt0to3
    cpu__gen_csr__csr__i_cnt3 := s.cpu__gen_csr__csr__i_cnt3
    cpu__gen_csr__csr__i_cnt7 := s.cpu__gen_csr__csr__i_cnt7
    cpu__gen_csr__csr__i_cnt11 := s.cpu__gen_csr__csr__i_cnt11
    cpu__gen_csr__csr__i_cnt12 := s.cpu__gen_csr__csr__i_cnt12
    cpu__gen_csr__csr__i_cnt_done := s.cpu__gen_csr__csr__i_cnt_done
    cpu__gen_csr__csr__i_mem_op := s.cpu__gen_csr__csr__i_mem_op
    cpu__gen_csr__csr__i_mtip := s.cpu__gen_csr__csr__i_mtip
    cpu__gen_csr__csr__i_trap := s.cpu__gen_csr__csr__i_trap
    cpu__gen_csr__csr__i_e_op := s.cpu__gen_csr__csr__i_e_op
    cpu__gen_csr__csr__i_ebreak := s.cpu__gen_csr__csr__i_ebreak
    cpu__gen_csr__csr__i_mem_cmd := s.cpu__gen_csr__csr__i_mem_cmd
    cpu__gen_csr__csr__i_mstatus_en := s.cpu__gen_csr__csr__i_mstatus_en
    cpu__gen_csr__csr__i_mie_en := s.cpu__gen_csr__csr__i_mie_en
    cpu__gen_csr__csr__i_mcause_en := s.cpu__gen_csr__csr__i_mcause_en
    cpu__gen_csr__csr__i_csr_source := s.cpu__gen_csr__csr__i_csr_source
    cpu__gen_csr__csr__i_mret := s.cpu__gen_csr__csr__i_mret
    cpu__gen_csr__csr__i_csr_d_sel := s.cpu__gen_csr__csr__i_csr_d_sel
    cpu__gen_csr__csr__i_rf_csr_out := s.cpu__gen_csr__csr__i_rf_csr_out
    cpu__gen_csr__csr__o_csr_in := s.cpu__gen_csr__csr__o_csr_in
    cpu__gen_csr__csr__i_csr_imm := s.cpu__gen_csr__csr__i_csr_imm
    cpu__gen_csr__csr__i_rs1 := s.cpu__gen_csr__csr__i_rs1
    cpu__gen_csr__csr__o_q := s.cpu__gen_csr__csr__o_q
    cpu__gen_csr__csr__mcause := s.cpu__gen_csr__csr__mcause
    cpu__gen_csr__csr__csr_in := s.cpu__gen_csr__csr__csr_in
    cpu__gen_csr__csr__csr_out := s.cpu__gen_csr__csr__csr_out
    cpu__gen_csr__csr__d := s.cpu__gen_csr__csr__d
    cpu__gen_csr__csr__mstatus := s.cpu__gen_csr__csr__mstatus
    cpu__gen_csr__csr__timer_irq := s.cpu__gen_csr__csr__timer_irq
    o_ibus_adr := s.o_ibus_adr
    o_ibus_cyc := s.o_ibus_cyc
    o_dbus_adr := s.o_dbus_adr
    o_dbus_dat := s.o_dbus_dat
    o_dbus_sel := s.o_dbus_sel
    o_dbus_we := s.o_dbus_we
    o_dbus_cyc := s.o_dbus_cyc
    o_ext_rs1 := s.o_ext_rs1
    o_ext_rs2 := s.o_ext_rs2
    o_ext_funct3 := s.o_ext_funct3
    o_mdu_valid := s.o_mdu_valid
    cpu__decode__o_alu_bool_op := s.cpu__decode__o_alu_bool_op
    cpu__decode__o_alu_cmp_eq := s.cpu__decode__o_alu_cmp_eq
    cpu__decode__o_alu_cmp_sig := s.cpu__decode__o_alu_cmp_sig
    cpu__decode__o_alu_rd_sel := s.cpu__decode__o_alu_rd_sel
    cpu__decode__o_alu_sub := s.cpu__decode__o_alu_sub
    cpu__decode__o_bne_or_bge := s.cpu__decode__o_bne_or_bge
    cpu__decode__o_branch_op := s.cpu__decode__o_branch_op
    cpu__decode__o_bufreg_clr_lsb := s.cpu__decode__o_bufreg_clr_lsb
    cpu__decode__o_bufreg_imm_en := s.cpu__decode__o_bufreg_imm_en
    cpu__decode__o_bufreg_rs1_en := s.cpu__decode__o_bufreg_rs1_en
    cpu__decode__o_bufreg_sh_signed := s.cpu__decode__o_bufreg_sh_signed
    cpu__decode__o_cond_branch := s.cpu__decode__o_cond_branch
    cpu__decode__o_csr_addr := s.cpu__decode__o_csr_addr
    cpu__decode__o_csr_d_sel := s.cpu__decode__o_csr_d_sel
    cpu__decode__o_csr_en := s.cpu__decode__o_csr_en
    cpu__decode__o_csr_imm_en := s.cpu__decode__o_csr_imm_en
    cpu__decode__o_csr_mcause_en := s.cpu__decode__o_csr_mcause_en
    cpu__decode__o_csr_mie_en := s.cpu__decode__o_csr_mie_en
    cpu__decode__o_csr_mstatus_en := s.cpu__decode__o_csr_mstatus_en
    cpu__decode__o_csr_source := s.cpu__decode__o_csr_source
    cpu__decode__o_ctrl_jal_or_jalr := s.cpu__decode__o_ctrl_jal_or_jalr
    cpu__decode__o_ctrl_mret := s.cpu__decode__o_ctrl_mret
    cpu__decode__o_ctrl_pc_rel := s.cpu__decode__o_ctrl_pc_rel
    cpu__decode__o_ctrl_utype := s.cpu__decode__o_ctrl_utype
    cpu__decode__o_dbus_en := s.cpu__decode__o_dbus_en
    cpu__decode__o_e_op := s.cpu__decode__o_e_op
    cpu__decode__o_ebreak := s.cpu__decode__o_ebreak
    cpu__decode__o_ext_funct3 := s.cpu__decode__o_ext_funct3
    cpu__decode__o_immdec_ctrl := s.cpu__decode__o_immdec_ctrl
    cpu__decode__o_immdec_en := s.cpu__decode__o_immdec_en
    cpu__decode__o_mdu_op := s.cpu__decode__o_mdu_op
    cpu__decode__o_mem_cmd := s.cpu__decode__o_mem_cmd
    cpu__decode__o_mem_half := s.cpu__decode__o_mem_half
    cpu__decode__o_mem_signed := s.cpu__decode__o_mem_signed
    cpu__decode__o_mem_word := s.cpu__decode__o_mem_word
    cpu__decode__o_mtval_pc := s.cpu__decode__o_mtval_pc
    cpu__decode__o_op_b_source := s.cpu__decode__o_op_b_source
    cpu__decode__o_rd_alu_en := s.cpu__decode__o_rd_alu_en
    cpu__decode__o_rd_csr_en := s.cpu__decode__o_rd_csr_en
    cpu__decode__o_rd_mem_en := s.cpu__decode__o_rd_mem_en
    cpu__decode__o_rd_op := s.cpu__decode__o_rd_op
    cpu__decode__o_sh_right := s.cpu__decode__o_sh_right
    cpu__decode__o_shift_op := s.cpu__decode__o_shift_op
    cpu__decode__o_two_stage_op := s.cpu__decode__o_two_stage_op
  }
  result

/-- step: pre-comb → parallel next-state commit → post-comb settle -/
def step (s : serv_rf_topState) (i : serv_rf_topInputs) : serv_rf_topState :=
  let s_pre := comb s i
  let s_next := commit s_pre i
  let s_settled := comb s_next i
  s_settled

/-- Output helper -/
def outputs (s : serv_rf_topState) : serv_rf_topOutputs :=
  {
    o_ibus_adr := s.o_ibus_adr
    o_ibus_cyc := s.o_ibus_cyc
    o_dbus_adr := s.o_dbus_adr
    o_dbus_dat := s.o_dbus_dat
    o_dbus_sel := s.o_dbus_sel
    o_dbus_we := s.o_dbus_we
    o_dbus_cyc := s.o_dbus_cyc
    o_ext_rs1 := s.o_ext_rs1
    o_ext_rs2 := s.o_ext_rs2
    o_ext_funct3 := s.o_ext_funct3
    o_mdu_valid := s.o_mdu_valid
  }


end serv_rf_top
