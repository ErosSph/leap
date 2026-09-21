/-
自动生成的 Lean 4 代码
源模块：modexp_core
生成时间：Lean 4 RTL 编译器
-/

import Std
set_option linter.unusedVariables false
set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace modexp_core

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

structure modexp_coreStateBlock0 where
  b_one_reg : BitVec 32
  cycle_ctr_high_reg : BitVec 32
  cycle_ctr_low_reg : BitVec 32
  cycle_ctr_state_reg : Bool
  ei_reg : Bool
  exponation_mode_reg : Bool
  exponent_mem__mem : BitVec 8192
  exponent_mem__ptr_reg : BitVec 8
  exponent_mem__tmp_read_data0 : BitVec 32
  exponent_mem__tmp_read_data1 : BitVec 32
  loop_counter_reg : BitVec 13
  message_mem__mem : BitVec 8192
  message_mem__ptr_reg : BitVec 8
  message_mem__tmp_read_data0 : BitVec 32
  message_mem__tmp_read_data1 : BitVec 32
  modexp_ctrl_reg : BitVec 4
  modulus_mem__mem : BitVec 8192
  modulus_mem__ptr_reg : BitVec 8
  modulus_mem__tmp_read_data0 : BitVec 32
  modulus_mem__tmp_read_data1 : BitVec 32
  montprod_dest_reg : BitVec 2
  montprod_inst__B_bit_index_reg : BitVec 5
  montprod_inst__add_carry_in_sa : Bool
  montprod_inst__add_carry_in_sm : Bool
  montprod_inst__b_reg : Bool
  montprod_inst__loop_counter : BitVec 13
  montprod_inst__montprod_ctrl_reg : BitVec 4
  montprod_inst__q_reg : Bool
  montprod_inst__ready_reg : Bool
  montprod_inst__s_mem__mem : BitVec 8192
  montprod_inst__s_mem__tmp_read_data : BitVec 32
  montprod_inst__s_mem_we : Bool
  montprod_inst__s_mem_wr_addr : BitVec 8
  montprod_inst__s_mux_reg : BitVec 2
  montprod_inst__shr_carry_in : Bool
  montprod_inst__word_index : BitVec 8
  montprod_inst__word_index_prev : BitVec 8
  montprod_select_reg : BitVec 3
  one_reg : BitVec 32
  p_mem__mem : BitVec 8192
  p_mem__tmp_read_data0 : BitVec 32
  p_mem__tmp_read_data1 : BitVec 32
  ready_reg : Bool
  residue_inst__length_m1_reg : BitVec 8
  residue_inst__loop_counter_1_to_nn_reg : BitVec 15
  residue_inst__nn_reg : BitVec 15
  residue_inst__ready_reg : Bool
  residue_inst__residue_ctrl_reg : BitVec 4
  residue_inst__shl_carry_in_reg : Bool
  residue_inst__sub_carry_in_reg : Bool
  residue_inst__word_index_reg : BitVec 8
  residue_mem__mem : BitVec 8192
  residue_mem__tmp_read_data0 : BitVec 32
  residue_mem__tmp_read_data1 : BitVec 32
  residue_valid_reg : Bool
  result_mem__mem : BitVec 8192
  result_mem__ptr_reg : BitVec 8
  result_mem__tmp_read_data0 : BitVec 32
  result_mem__tmp_read_data1 : BitVec 32
  modulus_mem_int_rd_data : BitVec 32
  message_mem_int_rd_data : BitVec 32
  exponent_mem_int_rd_data : BitVec 32
  result_mem_int_rd_data : BitVec 32
  p_mem_rd0_data : BitVec 32

structure modexp_coreStateBlock1 where
  p_mem_rd1_data : BitVec 32
  montprod_ready : Bool
  montprod_opa_addr : BitVec 8
  montprod_opb_addr : BitVec 8
  montprod_opm_addr : BitVec 8
  montprod_result_addr : BitVec 8
  montprod_result_data : BitVec 32
  montprod_result_we : Bool
  residue_ready : Bool
  residue_opa_rd_addr : BitVec 8
  residue_opa_rd_data : BitVec 32
  residue_opa_wr_addr : BitVec 8
  residue_opa_wr_data : BitVec 32
  residue_opa_wr_we : Bool
  residue_opm_addr : BitVec 8
  residue_mem_montprod_read_data : BitVec 32
  length_m1 : BitVec 8
  montprod_inst__clk : Bool
  montprod_inst__reset_n : Bool
  montprod_inst__calculate : Bool
  montprod_inst__ready : Bool
  montprod_inst__length : BitVec 8
  montprod_inst__opa_addr : BitVec 8
  montprod_inst__opa_data : BitVec 32
  montprod_inst__opb_addr : BitVec 8
  montprod_inst__opb_data : BitVec 32
  montprod_inst__opm_addr : BitVec 8
  montprod_inst__opm_data : BitVec 32
  montprod_inst__result_addr : BitVec 8
  montprod_inst__result_data : BitVec 32
  montprod_inst__result_we : Bool
  montprod_inst__s_mem_read_data : BitVec 32
  montprod_inst__add_result_sa : BitVec 32
  montprod_inst__add_carry_out_sa : Bool
  montprod_inst__add_result_sm : BitVec 32
  montprod_inst__add_carry_out_sm : Bool
  montprod_inst__shr_carry_out : Bool
  montprod_inst__shr_adiv2 : BitVec 32
  montprod_inst__s_mem__clk : Bool
  montprod_inst__s_mem__read_addr : BitVec 8
  montprod_inst__s_mem__read_data : BitVec 32
  montprod_inst__s_mem__wr : Bool
  montprod_inst__s_mem__write_addr : BitVec 8
  montprod_inst__s_mem__write_data : BitVec 32
  montprod_inst__s_adder_sa__a : BitVec 32
  montprod_inst__s_adder_sa__b : BitVec 32
  montprod_inst__s_adder_sa__carry_in : Bool
  montprod_inst__s_adder_sa__sum : BitVec 32
  montprod_inst__s_adder_sa__carry_out : Bool
  montprod_inst__s_adder_sm__a : BitVec 32
  montprod_inst__s_adder_sm__b : BitVec 32
  montprod_inst__s_adder_sm__carry_in : Bool
  montprod_inst__s_adder_sm__sum : BitVec 32
  montprod_inst__s_adder_sm__carry_out : Bool
  montprod_inst__shifter__a : BitVec 32
  montprod_inst__shifter__carry_in : Bool
  montprod_inst__shifter__adiv2 : BitVec 32
  montprod_inst__shifter__carry_out : Bool
  residue_inst__clk : Bool
  residue_inst__reset_n : Bool
  residue_inst__calculate : Bool
  residue_inst__ready : Bool
  residue_inst__nn : BitVec 15
  residue_inst__length : BitVec 8

structure modexp_coreStateBlock2 where
  residue_inst__opa_rd_addr : BitVec 8
  residue_inst__opa_rd_data : BitVec 32
  residue_inst__opa_wr_addr : BitVec 8
  residue_inst__opa_wr_data : BitVec 32
  residue_inst__opa_wr_we : Bool
  residue_inst__opm_addr : BitVec 8
  residue_inst__opm_data : BitVec 32
  residue_inst__sub_data : BitVec 32
  residue_inst__shl_data : BitVec 32
  residue_inst__sub_carry_out : Bool
  residue_inst__shl_carry_out : Bool
  residue_inst__subcmp__a : BitVec 32
  residue_inst__subcmp__b : BitVec 32
  residue_inst__subcmp__carry_in : Bool
  residue_inst__subcmp__sum : BitVec 32
  residue_inst__subcmp__carry_out : Bool
  residue_inst__shl__a : BitVec 32
  residue_inst__shl__carry_in : Bool
  residue_inst__shl__amul2 : BitVec 32
  residue_inst__shl__carry_out : Bool
  residue_mem__clk : Bool
  residue_mem__read_addr0 : BitVec 8
  residue_mem__read_data0 : BitVec 32
  residue_mem__read_addr1 : BitVec 8
  residue_mem__read_data1 : BitVec 32
  residue_mem__wr : Bool
  residue_mem__write_addr : BitVec 8
  residue_mem__write_data : BitVec 32
  p_mem__clk : Bool
  p_mem__read_addr0 : BitVec 8
  p_mem__read_data0 : BitVec 32
  p_mem__read_addr1 : BitVec 8
  p_mem__read_data1 : BitVec 32
  p_mem__wr : Bool
  p_mem__write_addr : BitVec 8
  p_mem__write_data : BitVec 32
  exponent_mem__clk : Bool
  exponent_mem__reset_n : Bool
  exponent_mem__read_addr0 : BitVec 8
  exponent_mem__read_data0 : BitVec 32
  exponent_mem__read_data1 : BitVec 32
  exponent_mem__rst : Bool
  exponent_mem__cs : Bool
  exponent_mem__wr : Bool
  exponent_mem__write_data : BitVec 32
  modulus_mem__clk : Bool
  modulus_mem__reset_n : Bool
  modulus_mem__read_addr0 : BitVec 8
  modulus_mem__read_data0 : BitVec 32
  modulus_mem__read_data1 : BitVec 32
  modulus_mem__rst : Bool
  modulus_mem__cs : Bool
  modulus_mem__wr : Bool
  modulus_mem__write_data : BitVec 32
  message_mem__clk : Bool
  message_mem__reset_n : Bool
  message_mem__read_addr0 : BitVec 8
  message_mem__read_data0 : BitVec 32
  message_mem__read_data1 : BitVec 32
  message_mem__rst : Bool
  message_mem__cs : Bool
  message_mem__wr : Bool
  message_mem__write_data : BitVec 32
  result_mem__clk : Bool

structure modexp_coreStateBlock3 where
  result_mem__reset_n : Bool
  result_mem__read_addr0 : BitVec 8
  result_mem__read_data0 : BitVec 32
  result_mem__read_data1 : BitVec 32
  result_mem__rst : Bool
  result_mem__cs : Bool
  result_mem__wr : Bool
  result_mem__write_addr : BitVec 8
  result_mem__write_data : BitVec 32
  ready : Bool
  cycles : BitVec 64
  exponent_mem_api_read_data : BitVec 32
  modulus_mem_api_read_data : BitVec 32
  message_mem_api_read_data : BitVec 32
  result_mem_api_read_data : BitVec 32
  E_bit_index : BitVec 5
  E_word_index : BitVec 8
  b_one_new : BitVec 32
  cycle_ctr_high_new : BitVec 32
  cycle_ctr_high_we : Bool
  cycle_ctr_low_new : BitVec 32
  cycle_ctr_low_we : Bool
  cycle_ctr_start : Bool
  cycle_ctr_state_new : Bool
  cycle_ctr_state_we : Bool
  cycle_ctr_stop : Bool
  ei_new : Bool
  ei_we : Bool
  exponent_mem__ptr_new : BitVec 8
  exponent_mem__ptr_we : Bool
  exponent_mem_int_rd_addr : BitVec 8
  last_iteration : Bool
  loop_counter_new : BitVec 13
  loop_counter_we : Bool
  message_mem__ptr_new : BitVec 8
  message_mem__ptr_we : Bool
  message_mem_int_rd_addr : BitVec 8
  modexp_ctrl_new : BitVec 4
  modexp_ctrl_we : Bool
  modulus_mem__ptr_new : BitVec 8
  modulus_mem__ptr_we : Bool
  modulus_mem_int_rd_addr : BitVec 8
  montprod_calc : Bool
  montprod_dest_new : BitVec 2
  montprod_dest_we : Bool
  montprod_inst__B_bit_index : BitVec 5
  montprod_inst__B_word_index : BitVec 8
  montprod_inst__add_carry_new_sa : Bool
  montprod_inst__add_carry_new_sm : Bool
  montprod_inst__b : Bool
  montprod_inst__length_m1 : BitVec 8
  montprod_inst__loop_counter_dec : BitVec 13
  montprod_inst__loop_counter_new : BitVec 13
  montprod_inst__montprod_ctrl_new : BitVec 4
  montprod_inst__montprod_ctrl_we : Bool
  montprod_inst__opa_addr_reg : BitVec 8
  montprod_inst__opb_addr_reg : BitVec 8
  montprod_inst__opm_addr_reg : BitVec 8
  montprod_inst__q : Bool
  montprod_inst__ready_new : Bool
  montprod_inst__ready_we : Bool
  montprod_inst__reset_word_index_LSW : Bool
  montprod_inst__reset_word_index_MSW : Bool
  montprod_inst__result_addr_reg : BitVec 8

structure modexp_coreStateBlock4 where
  montprod_inst__result_data_reg : BitVec 32
  montprod_inst__s_adder_sa__adder_result : BitVec 33
  montprod_inst__s_adder_sm__adder_result : BitVec 33
  montprod_inst__s_mem_addr : BitVec 8
  montprod_inst__s_mem_new : BitVec 32
  montprod_inst__s_mem_we_new : Bool
  montprod_inst__s_mux_new : BitVec 2
  montprod_inst__shr_carry_new : Bool
  montprod_inst__tmp_result_we : Bool
  montprod_inst__word_index_new : BitVec 8
  montprod_length : BitVec 8
  montprod_opa_data : BitVec 32
  montprod_opb_data : BitVec 32
  montprod_opm_data : BitVec 32
  montprod_select_new : BitVec 3
  montprod_select_we : Bool
  one_new : BitVec 32
  p_mem_rd0_addr : BitVec 8
  p_mem_rd1_addr : BitVec 8
  p_mem_we : Bool
  p_mem_wr_addr : BitVec 8
  p_mem_wr_data : BitVec 32
  ready_new : Bool
  ready_we : Bool
  residue_calculate : Bool
  residue_inst__length_m1_new : BitVec 8
  residue_inst__length_m1_we : Bool
  residue_inst__loop_counter_1_to_nn_new : BitVec 15
  residue_inst__loop_counter_1_to_nn_we : Bool
  residue_inst__nn_we : Bool
  residue_inst__one_data : BitVec 32
  residue_inst__opa_rd_addr_reg : BitVec 8
  residue_inst__opa_wr_addr_reg : BitVec 8
  residue_inst__opa_wr_data_reg : BitVec 32
  residue_inst__opa_wr_we_reg : Bool
  residue_inst__opm_addr_reg : BitVec 8
  residue_inst__ready_new : Bool
  residue_inst__ready_we : Bool
  residue_inst__reset_n_counter : Bool
  residue_inst__reset_word_index : Bool
  residue_inst__residue_ctrl_new : BitVec 4
  residue_inst__residue_ctrl_we : Bool
  residue_inst__shl_carry_in_new : Bool
  residue_inst__sub_carry_in_new : Bool
  residue_inst__subcmp__adder_result : BitVec 33
  residue_inst__word_index_new : BitVec 8
  residue_inst__word_index_we : Bool
  residue_length : BitVec 8
  residue_mem_montprod_read_addr : BitVec 8
  residue_nn : BitVec 15
  residue_opm_data : BitVec 32
  residue_valid_int_validated : Bool
  residue_valid_new : Bool
  result_mem__ptr_new : BitVec 8
  result_mem__ptr_we : Bool
  result_mem_int_rd_addr : BitVec 8
  result_mem_int_we : Bool
  result_mem_int_wr_addr : BitVec 8
  result_mem_int_wr_data : BitVec 32

/-- modexp_core 状态结构（保留全部字段的嵌套具体记录） -/
structure modexp_coreState extends modexp_coreStateBlock0, modexp_coreStateBlock1, modexp_coreStateBlock2, modexp_coreStateBlock3, modexp_coreStateBlock4 where

/-- modexp_core 输入信号 -/
structure modexp_coreInputs where
  clk : Bool
  reset_n : Bool
  start : Bool
  exponent_length : BitVec 8
  modulus_length : BitVec 8
  exponent_mem_api_cs : Bool
  exponent_mem_api_wr : Bool
  exponent_mem_api_rst : Bool
  exponent_mem_api_write_data : BitVec 32
  modulus_mem_api_cs : Bool
  modulus_mem_api_wr : Bool
  modulus_mem_api_rst : Bool
  modulus_mem_api_write_data : BitVec 32
  message_mem_api_cs : Bool
  message_mem_api_wr : Bool
  message_mem_api_rst : Bool
  message_mem_api_write_data : BitVec 32
  result_mem_api_cs : Bool
  result_mem_api_rst : Bool
  exponation_mode_new : Bool
  exponation_mode_we : Bool

/-- modexp_core 输出信号 -/
structure modexp_coreOutputs where
  ready : Bool
  cycles : BitVec 64
  exponent_mem_api_read_data : BitVec 32
  modulus_mem_api_read_data : BitVec 32
  message_mem_api_read_data : BitVec 32
  result_mem_api_read_data : BitVec 32

/-- modexp_core 初始状态 -/
def init : modexp_coreState where
  b_one_reg := BitVec.ofNat 32 0
  cycle_ctr_high_reg := BitVec.ofNat 32 0
  cycle_ctr_low_reg := BitVec.ofNat 32 0
  cycle_ctr_state_reg := false
  ei_reg := false
  exponation_mode_reg := false
  exponent_mem__mem := BitVec.ofNat 8192 0
  exponent_mem__ptr_reg := BitVec.ofNat 8 0
  exponent_mem__tmp_read_data0 := BitVec.ofNat 32 0
  exponent_mem__tmp_read_data1 := BitVec.ofNat 32 0
  loop_counter_reg := BitVec.ofNat 13 0
  message_mem__mem := BitVec.ofNat 8192 0
  message_mem__ptr_reg := BitVec.ofNat 8 0
  message_mem__tmp_read_data0 := BitVec.ofNat 32 0
  message_mem__tmp_read_data1 := BitVec.ofNat 32 0
  modexp_ctrl_reg := BitVec.ofNat 4 0
  modulus_mem__mem := BitVec.ofNat 8192 0
  modulus_mem__ptr_reg := BitVec.ofNat 8 0
  modulus_mem__tmp_read_data0 := BitVec.ofNat 32 0
  modulus_mem__tmp_read_data1 := BitVec.ofNat 32 0
  montprod_dest_reg := BitVec.ofNat 2 0
  montprod_inst__B_bit_index_reg := BitVec.ofNat 5 0
  montprod_inst__add_carry_in_sa := false
  montprod_inst__add_carry_in_sm := false
  montprod_inst__b_reg := false
  montprod_inst__loop_counter := BitVec.ofNat 13 0
  montprod_inst__montprod_ctrl_reg := BitVec.ofNat 4 0
  montprod_inst__q_reg := false
  montprod_inst__ready_reg := false
  montprod_inst__s_mem__mem := BitVec.ofNat 8192 0
  montprod_inst__s_mem__tmp_read_data := BitVec.ofNat 32 0
  montprod_inst__s_mem_we := false
  montprod_inst__s_mem_wr_addr := BitVec.ofNat 8 0
  montprod_inst__s_mux_reg := BitVec.ofNat 2 0
  montprod_inst__shr_carry_in := false
  montprod_inst__word_index := BitVec.ofNat 8 0
  montprod_inst__word_index_prev := BitVec.ofNat 8 0
  montprod_select_reg := BitVec.ofNat 3 0
  one_reg := BitVec.ofNat 32 0
  p_mem__mem := BitVec.ofNat 8192 0
  p_mem__tmp_read_data0 := BitVec.ofNat 32 0
  p_mem__tmp_read_data1 := BitVec.ofNat 32 0
  ready_reg := false
  residue_inst__length_m1_reg := BitVec.ofNat 8 0
  residue_inst__loop_counter_1_to_nn_reg := BitVec.ofNat 15 0
  residue_inst__nn_reg := BitVec.ofNat 15 0
  residue_inst__ready_reg := false
  residue_inst__residue_ctrl_reg := BitVec.ofNat 4 0
  residue_inst__shl_carry_in_reg := false
  residue_inst__sub_carry_in_reg := false
  residue_inst__word_index_reg := BitVec.ofNat 8 0
  residue_mem__mem := BitVec.ofNat 8192 0
  residue_mem__tmp_read_data0 := BitVec.ofNat 32 0
  residue_mem__tmp_read_data1 := BitVec.ofNat 32 0
  residue_valid_reg := false
  result_mem__mem := BitVec.ofNat 8192 0
  result_mem__ptr_reg := BitVec.ofNat 8 0
  result_mem__tmp_read_data0 := BitVec.ofNat 32 0
  result_mem__tmp_read_data1 := BitVec.ofNat 32 0
  modulus_mem_int_rd_data := BitVec.ofNat 32 0
  message_mem_int_rd_data := BitVec.ofNat 32 0
  exponent_mem_int_rd_data := BitVec.ofNat 32 0
  result_mem_int_rd_data := BitVec.ofNat 32 0
  p_mem_rd0_data := BitVec.ofNat 32 0
  p_mem_rd1_data := BitVec.ofNat 32 0
  montprod_ready := false
  montprod_opa_addr := BitVec.ofNat 8 0
  montprod_opb_addr := BitVec.ofNat 8 0
  montprod_opm_addr := BitVec.ofNat 8 0
  montprod_result_addr := BitVec.ofNat 8 0
  montprod_result_data := BitVec.ofNat 32 0
  montprod_result_we := false
  residue_ready := false
  residue_opa_rd_addr := BitVec.ofNat 8 0
  residue_opa_rd_data := BitVec.ofNat 32 0
  residue_opa_wr_addr := BitVec.ofNat 8 0
  residue_opa_wr_data := BitVec.ofNat 32 0
  residue_opa_wr_we := false
  residue_opm_addr := BitVec.ofNat 8 0
  residue_mem_montprod_read_data := BitVec.ofNat 32 0
  length_m1 := BitVec.ofNat 8 0
  montprod_inst__clk := false
  montprod_inst__reset_n := false
  montprod_inst__calculate := false
  montprod_inst__ready := false
  montprod_inst__length := BitVec.ofNat 8 0
  montprod_inst__opa_addr := BitVec.ofNat 8 0
  montprod_inst__opa_data := BitVec.ofNat 32 0
  montprod_inst__opb_addr := BitVec.ofNat 8 0
  montprod_inst__opb_data := BitVec.ofNat 32 0
  montprod_inst__opm_addr := BitVec.ofNat 8 0
  montprod_inst__opm_data := BitVec.ofNat 32 0
  montprod_inst__result_addr := BitVec.ofNat 8 0
  montprod_inst__result_data := BitVec.ofNat 32 0
  montprod_inst__result_we := false
  montprod_inst__s_mem_read_data := BitVec.ofNat 32 0
  montprod_inst__add_result_sa := BitVec.ofNat 32 0
  montprod_inst__add_carry_out_sa := false
  montprod_inst__add_result_sm := BitVec.ofNat 32 0
  montprod_inst__add_carry_out_sm := false
  montprod_inst__shr_carry_out := false
  montprod_inst__shr_adiv2 := BitVec.ofNat 32 0
  montprod_inst__s_mem__clk := false
  montprod_inst__s_mem__read_addr := BitVec.ofNat 8 0
  montprod_inst__s_mem__read_data := BitVec.ofNat 32 0
  montprod_inst__s_mem__wr := false
  montprod_inst__s_mem__write_addr := BitVec.ofNat 8 0
  montprod_inst__s_mem__write_data := BitVec.ofNat 32 0
  montprod_inst__s_adder_sa__a := BitVec.ofNat 32 0
  montprod_inst__s_adder_sa__b := BitVec.ofNat 32 0
  montprod_inst__s_adder_sa__carry_in := false
  montprod_inst__s_adder_sa__sum := BitVec.ofNat 32 0
  montprod_inst__s_adder_sa__carry_out := false
  montprod_inst__s_adder_sm__a := BitVec.ofNat 32 0
  montprod_inst__s_adder_sm__b := BitVec.ofNat 32 0
  montprod_inst__s_adder_sm__carry_in := false
  montprod_inst__s_adder_sm__sum := BitVec.ofNat 32 0
  montprod_inst__s_adder_sm__carry_out := false
  montprod_inst__shifter__a := BitVec.ofNat 32 0
  montprod_inst__shifter__carry_in := false
  montprod_inst__shifter__adiv2 := BitVec.ofNat 32 0
  montprod_inst__shifter__carry_out := false
  residue_inst__clk := false
  residue_inst__reset_n := false
  residue_inst__calculate := false
  residue_inst__ready := false
  residue_inst__nn := BitVec.ofNat 15 0
  residue_inst__length := BitVec.ofNat 8 0
  residue_inst__opa_rd_addr := BitVec.ofNat 8 0
  residue_inst__opa_rd_data := BitVec.ofNat 32 0
  residue_inst__opa_wr_addr := BitVec.ofNat 8 0
  residue_inst__opa_wr_data := BitVec.ofNat 32 0
  residue_inst__opa_wr_we := false
  residue_inst__opm_addr := BitVec.ofNat 8 0
  residue_inst__opm_data := BitVec.ofNat 32 0
  residue_inst__sub_data := BitVec.ofNat 32 0
  residue_inst__shl_data := BitVec.ofNat 32 0
  residue_inst__sub_carry_out := false
  residue_inst__shl_carry_out := false
  residue_inst__subcmp__a := BitVec.ofNat 32 0
  residue_inst__subcmp__b := BitVec.ofNat 32 0
  residue_inst__subcmp__carry_in := false
  residue_inst__subcmp__sum := BitVec.ofNat 32 0
  residue_inst__subcmp__carry_out := false
  residue_inst__shl__a := BitVec.ofNat 32 0
  residue_inst__shl__carry_in := false
  residue_inst__shl__amul2 := BitVec.ofNat 32 0
  residue_inst__shl__carry_out := false
  residue_mem__clk := false
  residue_mem__read_addr0 := BitVec.ofNat 8 0
  residue_mem__read_data0 := BitVec.ofNat 32 0
  residue_mem__read_addr1 := BitVec.ofNat 8 0
  residue_mem__read_data1 := BitVec.ofNat 32 0
  residue_mem__wr := false
  residue_mem__write_addr := BitVec.ofNat 8 0
  residue_mem__write_data := BitVec.ofNat 32 0
  p_mem__clk := false
  p_mem__read_addr0 := BitVec.ofNat 8 0
  p_mem__read_data0 := BitVec.ofNat 32 0
  p_mem__read_addr1 := BitVec.ofNat 8 0
  p_mem__read_data1 := BitVec.ofNat 32 0
  p_mem__wr := false
  p_mem__write_addr := BitVec.ofNat 8 0
  p_mem__write_data := BitVec.ofNat 32 0
  exponent_mem__clk := false
  exponent_mem__reset_n := false
  exponent_mem__read_addr0 := BitVec.ofNat 8 0
  exponent_mem__read_data0 := BitVec.ofNat 32 0
  exponent_mem__read_data1 := BitVec.ofNat 32 0
  exponent_mem__rst := false
  exponent_mem__cs := false
  exponent_mem__wr := false
  exponent_mem__write_data := BitVec.ofNat 32 0
  modulus_mem__clk := false
  modulus_mem__reset_n := false
  modulus_mem__read_addr0 := BitVec.ofNat 8 0
  modulus_mem__read_data0 := BitVec.ofNat 32 0
  modulus_mem__read_data1 := BitVec.ofNat 32 0
  modulus_mem__rst := false
  modulus_mem__cs := false
  modulus_mem__wr := false
  modulus_mem__write_data := BitVec.ofNat 32 0
  message_mem__clk := false
  message_mem__reset_n := false
  message_mem__read_addr0 := BitVec.ofNat 8 0
  message_mem__read_data0 := BitVec.ofNat 32 0
  message_mem__read_data1 := BitVec.ofNat 32 0
  message_mem__rst := false
  message_mem__cs := false
  message_mem__wr := false
  message_mem__write_data := BitVec.ofNat 32 0
  result_mem__clk := false
  result_mem__reset_n := false
  result_mem__read_addr0 := BitVec.ofNat 8 0
  result_mem__read_data0 := BitVec.ofNat 32 0
  result_mem__read_data1 := BitVec.ofNat 32 0
  result_mem__rst := false
  result_mem__cs := false
  result_mem__wr := false
  result_mem__write_addr := BitVec.ofNat 8 0
  result_mem__write_data := BitVec.ofNat 32 0
  ready := false
  cycles := BitVec.ofNat 64 0
  exponent_mem_api_read_data := BitVec.ofNat 32 0
  modulus_mem_api_read_data := BitVec.ofNat 32 0
  message_mem_api_read_data := BitVec.ofNat 32 0
  result_mem_api_read_data := BitVec.ofNat 32 0
  E_bit_index := BitVec.ofNat 5 0
  E_word_index := BitVec.ofNat 8 0
  b_one_new := BitVec.ofNat 32 0
  cycle_ctr_high_new := BitVec.ofNat 32 0
  cycle_ctr_high_we := false
  cycle_ctr_low_new := BitVec.ofNat 32 0
  cycle_ctr_low_we := false
  cycle_ctr_start := false
  cycle_ctr_state_new := false
  cycle_ctr_state_we := false
  cycle_ctr_stop := false
  ei_new := false
  ei_we := false
  exponent_mem__ptr_new := BitVec.ofNat 8 0
  exponent_mem__ptr_we := false
  exponent_mem_int_rd_addr := BitVec.ofNat 8 0
  last_iteration := false
  loop_counter_new := BitVec.ofNat 13 0
  loop_counter_we := false
  message_mem__ptr_new := BitVec.ofNat 8 0
  message_mem__ptr_we := false
  message_mem_int_rd_addr := BitVec.ofNat 8 0
  modexp_ctrl_new := BitVec.ofNat 4 0
  modexp_ctrl_we := false
  modulus_mem__ptr_new := BitVec.ofNat 8 0
  modulus_mem__ptr_we := false
  modulus_mem_int_rd_addr := BitVec.ofNat 8 0
  montprod_calc := false
  montprod_dest_new := BitVec.ofNat 2 0
  montprod_dest_we := false
  montprod_inst__B_bit_index := BitVec.ofNat 5 0
  montprod_inst__B_word_index := BitVec.ofNat 8 0
  montprod_inst__add_carry_new_sa := false
  montprod_inst__add_carry_new_sm := false
  montprod_inst__b := false
  montprod_inst__length_m1 := BitVec.ofNat 8 0
  montprod_inst__loop_counter_dec := BitVec.ofNat 13 0
  montprod_inst__loop_counter_new := BitVec.ofNat 13 0
  montprod_inst__montprod_ctrl_new := BitVec.ofNat 4 0
  montprod_inst__montprod_ctrl_we := false
  montprod_inst__opa_addr_reg := BitVec.ofNat 8 0
  montprod_inst__opb_addr_reg := BitVec.ofNat 8 0
  montprod_inst__opm_addr_reg := BitVec.ofNat 8 0
  montprod_inst__q := false
  montprod_inst__ready_new := false
  montprod_inst__ready_we := false
  montprod_inst__reset_word_index_LSW := false
  montprod_inst__reset_word_index_MSW := false
  montprod_inst__result_addr_reg := BitVec.ofNat 8 0
  montprod_inst__result_data_reg := BitVec.ofNat 32 0
  montprod_inst__s_adder_sa__adder_result := BitVec.ofNat 33 0
  montprod_inst__s_adder_sm__adder_result := BitVec.ofNat 33 0
  montprod_inst__s_mem_addr := BitVec.ofNat 8 0
  montprod_inst__s_mem_new := BitVec.ofNat 32 0
  montprod_inst__s_mem_we_new := false
  montprod_inst__s_mux_new := BitVec.ofNat 2 0
  montprod_inst__shr_carry_new := false
  montprod_inst__tmp_result_we := false
  montprod_inst__word_index_new := BitVec.ofNat 8 0
  montprod_length := BitVec.ofNat 8 0
  montprod_opa_data := BitVec.ofNat 32 0
  montprod_opb_data := BitVec.ofNat 32 0
  montprod_opm_data := BitVec.ofNat 32 0
  montprod_select_new := BitVec.ofNat 3 0
  montprod_select_we := false
  one_new := BitVec.ofNat 32 0
  p_mem_rd0_addr := BitVec.ofNat 8 0
  p_mem_rd1_addr := BitVec.ofNat 8 0
  p_mem_we := false
  p_mem_wr_addr := BitVec.ofNat 8 0
  p_mem_wr_data := BitVec.ofNat 32 0
  ready_new := false
  ready_we := false
  residue_calculate := false
  residue_inst__length_m1_new := BitVec.ofNat 8 0
  residue_inst__length_m1_we := false
  residue_inst__loop_counter_1_to_nn_new := BitVec.ofNat 15 0
  residue_inst__loop_counter_1_to_nn_we := false
  residue_inst__nn_we := false
  residue_inst__one_data := BitVec.ofNat 32 0
  residue_inst__opa_rd_addr_reg := BitVec.ofNat 8 0
  residue_inst__opa_wr_addr_reg := BitVec.ofNat 8 0
  residue_inst__opa_wr_data_reg := BitVec.ofNat 32 0
  residue_inst__opa_wr_we_reg := false
  residue_inst__opm_addr_reg := BitVec.ofNat 8 0
  residue_inst__ready_new := false
  residue_inst__ready_we := false
  residue_inst__reset_n_counter := false
  residue_inst__reset_word_index := false
  residue_inst__residue_ctrl_new := BitVec.ofNat 4 0
  residue_inst__residue_ctrl_we := false
  residue_inst__shl_carry_in_new := false
  residue_inst__sub_carry_in_new := false
  residue_inst__subcmp__adder_result := BitVec.ofNat 33 0
  residue_inst__word_index_new := BitVec.ofNat 8 0
  residue_inst__word_index_we := false
  residue_length := BitVec.ofNat 8 0
  residue_mem_montprod_read_addr := BitVec.ofNat 8 0
  residue_nn := BitVec.ofNat 15 0
  residue_opm_data := BitVec.ofNat 32 0
  residue_valid_int_validated := false
  residue_valid_new := false
  result_mem__ptr_new := BitVec.ofNat 8 0
  result_mem__ptr_we := false
  result_mem_int_rd_addr := BitVec.ofNat 8 0
  result_mem_int_we := false
  result_mem_int_wr_addr := BitVec.ofNat 8 0
  result_mem_int_wr_data := BitVec.ofNat 32 0

/-- modexp_core 默认输入值 -/
def defaultInputs : modexp_coreInputs where
  clk := false
  reset_n := true
  start := false
  exponent_length := BitVec.ofNat 8 0
  modulus_length := BitVec.ofNat 8 0
  exponent_mem_api_cs := false
  exponent_mem_api_wr := false
  exponent_mem_api_rst := true
  exponent_mem_api_write_data := BitVec.ofNat 32 0
  modulus_mem_api_cs := false
  modulus_mem_api_wr := false
  modulus_mem_api_rst := true
  modulus_mem_api_write_data := BitVec.ofNat 32 0
  message_mem_api_cs := false
  message_mem_api_wr := false
  message_mem_api_rst := true
  message_mem_api_write_data := BitVec.ofNat 32 0
  result_mem_api_cs := false
  result_mem_api_rst := true
  exponation_mode_new := false
  exponation_mode_we := false

/-- 组合逻辑：assign_ready -/
def assign_ready (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let ready := s.ready_reg
  { s with
    ready := ready
  }

/-- 组合逻辑：assign_cycles -/
def assign_cycles (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let cycles := BitVec.append (n := 32) (m := 32) (s.cycle_ctr_high_reg) (s.cycle_ctr_low_reg)
  { s with
    cycles := cycles
  }

/-- 组合逻辑：assign_length_m1 -/
def assign_length_m1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let length_m1 := (i.modulus_length - BitVec.ofNat 8 1)
  { s with
    length_m1 := length_m1
  }

/-- 组合逻辑：assign_montprod_inst__clk -/
def assign_montprod_inst__clk (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__clk := i.clk
  { s with
    montprod_inst__clk := montprod_inst__clk
  }

/-- 组合逻辑：assign_montprod_inst__reset_n -/
def assign_montprod_inst__reset_n (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__reset_n := i.reset_n
  { s with
    montprod_inst__reset_n := montprod_inst__reset_n
  }

/-- 组合逻辑：assign_montprod_inst__calculate -/
def assign_montprod_inst__calculate (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__calculate := s.montprod_calc
  { s with
    montprod_inst__calculate := montprod_inst__calculate
  }

/-- 组合逻辑：assign_montprod_ready -/
def assign_montprod_ready (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_ready := s.montprod_inst__ready
  { s with
    montprod_ready := montprod_ready
  }

/-- 组合逻辑：assign_montprod_inst__length -/
def assign_montprod_inst__length (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__length := s.montprod_length
  { s with
    montprod_inst__length := montprod_inst__length
  }

/-- 组合逻辑：assign_montprod_opa_addr -/
def assign_montprod_opa_addr (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_opa_addr := s.montprod_inst__opa_addr
  { s with
    montprod_opa_addr := montprod_opa_addr
  }

/-- 组合逻辑：assign_montprod_inst__opa_data -/
def assign_montprod_inst__opa_data (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__opa_data := s.montprod_opa_data
  { s with
    montprod_inst__opa_data := montprod_inst__opa_data
  }

/-- 组合逻辑：assign_montprod_opb_addr -/
def assign_montprod_opb_addr (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_opb_addr := s.montprod_inst__opb_addr
  { s with
    montprod_opb_addr := montprod_opb_addr
  }

/-- 组合逻辑：assign_montprod_inst__opb_data -/
def assign_montprod_inst__opb_data (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__opb_data := s.montprod_opb_data
  { s with
    montprod_inst__opb_data := montprod_inst__opb_data
  }

/-- 组合逻辑：assign_montprod_opm_addr -/
def assign_montprod_opm_addr (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_opm_addr := s.montprod_inst__opm_addr
  { s with
    montprod_opm_addr := montprod_opm_addr
  }

/-- 组合逻辑：assign_montprod_inst__opm_data -/
def assign_montprod_inst__opm_data (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__opm_data := s.montprod_opm_data
  { s with
    montprod_inst__opm_data := montprod_inst__opm_data
  }

/-- 组合逻辑：assign_montprod_result_addr -/
def assign_montprod_result_addr (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_result_addr := s.montprod_inst__result_addr
  { s with
    montprod_result_addr := montprod_result_addr
  }

/-- 组合逻辑：assign_montprod_result_data -/
def assign_montprod_result_data (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_result_data := s.montprod_inst__result_data
  { s with
    montprod_result_data := montprod_result_data
  }

/-- 组合逻辑：assign_montprod_result_we -/
def assign_montprod_result_we (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_result_we := s.montprod_inst__result_we
  { s with
    montprod_result_we := montprod_result_we
  }

/-- 组合逻辑：assign_montprod_inst__opa_addr -/
def assign_montprod_inst__opa_addr (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__opa_addr := s.montprod_inst__opa_addr_reg
  { s with
    montprod_inst__opa_addr := montprod_inst__opa_addr
  }

/-- 组合逻辑：assign_montprod_inst__opb_addr -/
def assign_montprod_inst__opb_addr (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__opb_addr := s.montprod_inst__opb_addr_reg
  { s with
    montprod_inst__opb_addr := montprod_inst__opb_addr
  }

/-- 组合逻辑：assign_montprod_inst__opm_addr -/
def assign_montprod_inst__opm_addr (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__opm_addr := s.montprod_inst__opm_addr_reg
  { s with
    montprod_inst__opm_addr := montprod_inst__opm_addr
  }

/-- 组合逻辑：assign_montprod_inst__result_addr -/
def assign_montprod_inst__result_addr (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__result_addr := s.montprod_inst__result_addr_reg
  { s with
    montprod_inst__result_addr := montprod_inst__result_addr
  }

/-- 组合逻辑：assign_montprod_inst__result_data -/
def assign_montprod_inst__result_data (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__result_data := s.montprod_inst__result_data_reg
  { s with
    montprod_inst__result_data := montprod_inst__result_data
  }

/-- 组合逻辑：assign_montprod_inst__result_we -/
def assign_montprod_inst__result_we (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__result_we := s.montprod_inst__tmp_result_we
  { s with
    montprod_inst__result_we := montprod_inst__result_we
  }

/-- 组合逻辑：assign_montprod_inst__ready -/
def assign_montprod_inst__ready (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__ready := s.montprod_inst__ready_reg
  { s with
    montprod_inst__ready := montprod_inst__ready
  }

/-- 组合逻辑：assign_montprod_inst__s_mem__clk -/
def assign_montprod_inst__s_mem__clk (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__s_mem__clk := s.montprod_inst__clk
  { s with
    montprod_inst__s_mem__clk := montprod_inst__s_mem__clk
  }

/-- 组合逻辑：assign_montprod_inst__s_mem__read_addr -/
def assign_montprod_inst__s_mem__read_addr (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__s_mem__read_addr := s.montprod_inst__s_mem_addr
  { s with
    montprod_inst__s_mem__read_addr := montprod_inst__s_mem__read_addr
  }

/-- 组合逻辑：assign_montprod_inst__s_mem_read_data -/
def assign_montprod_inst__s_mem_read_data (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__s_mem_read_data := s.montprod_inst__s_mem__read_data
  { s with
    montprod_inst__s_mem_read_data := montprod_inst__s_mem_read_data
  }

/-- 组合逻辑：assign_montprod_inst__s_mem__wr -/
def assign_montprod_inst__s_mem__wr (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__s_mem__wr := s.montprod_inst__s_mem_we
  { s with
    montprod_inst__s_mem__wr := montprod_inst__s_mem__wr
  }

/-- 组合逻辑：assign_montprod_inst__s_mem__write_addr -/
def assign_montprod_inst__s_mem__write_addr (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__s_mem__write_addr := s.montprod_inst__s_mem_wr_addr
  { s with
    montprod_inst__s_mem__write_addr := montprod_inst__s_mem__write_addr
  }

/-- 组合逻辑：assign_montprod_inst__s_mem__write_data -/
def assign_montprod_inst__s_mem__write_data (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__s_mem__write_data := s.montprod_inst__s_mem_new
  { s with
    montprod_inst__s_mem__write_data := montprod_inst__s_mem__write_data
  }

/-- 组合逻辑：assign_montprod_inst__s_mem__read_data -/
def assign_montprod_inst__s_mem__read_data (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__s_mem__read_data := s.montprod_inst__s_mem__tmp_read_data
  { s with
    montprod_inst__s_mem__read_data := montprod_inst__s_mem__read_data
  }

/-- 组合逻辑：assign_montprod_inst__s_adder_sa__a -/
def assign_montprod_inst__s_adder_sa__a (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__s_adder_sa__a := s.montprod_inst__s_mem_read_data
  { s with
    montprod_inst__s_adder_sa__a := montprod_inst__s_adder_sa__a
  }

/-- 组合逻辑：assign_montprod_inst__s_adder_sa__b -/
def assign_montprod_inst__s_adder_sa__b (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__s_adder_sa__b := s.montprod_inst__opa_data
  { s with
    montprod_inst__s_adder_sa__b := montprod_inst__s_adder_sa__b
  }

/-- 组合逻辑：assign_montprod_inst__s_adder_sa__carry_in -/
def assign_montprod_inst__s_adder_sa__carry_in (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__s_adder_sa__carry_in := s.montprod_inst__add_carry_in_sa
  { s with
    montprod_inst__s_adder_sa__carry_in := montprod_inst__s_adder_sa__carry_in
  }

/-- 组合逻辑：assign_montprod_inst__add_result_sa -/
def assign_montprod_inst__add_result_sa (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__add_result_sa := s.montprod_inst__s_adder_sa__sum
  { s with
    montprod_inst__add_result_sa := montprod_inst__add_result_sa
  }

/-- 组合逻辑：assign_montprod_inst__add_carry_out_sa -/
def assign_montprod_inst__add_carry_out_sa (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__add_carry_out_sa := s.montprod_inst__s_adder_sa__carry_out
  { s with
    montprod_inst__add_carry_out_sa := montprod_inst__add_carry_out_sa
  }

/-- 组合逻辑：assign_montprod_inst__s_adder_sa__sum -/
def assign_montprod_inst__s_adder_sa__sum (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__s_adder_sa__sum := BitVec.extractLsb 31 0 (s.montprod_inst__s_adder_sa__adder_result)
  { s with
    montprod_inst__s_adder_sa__sum := montprod_inst__s_adder_sa__sum
  }

/-- 组合逻辑：assign_montprod_inst__s_adder_sa__carry_out -/
def assign_montprod_inst__s_adder_sa__carry_out (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__s_adder_sa__carry_out := BitVec.getLsbD (s.montprod_inst__s_adder_sa__adder_result) 32
  { s with
    montprod_inst__s_adder_sa__carry_out := montprod_inst__s_adder_sa__carry_out
  }

/-- 组合逻辑：assign_montprod_inst__s_adder_sm__a -/
def assign_montprod_inst__s_adder_sm__a (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__s_adder_sm__a := s.montprod_inst__s_mem_read_data
  { s with
    montprod_inst__s_adder_sm__a := montprod_inst__s_adder_sm__a
  }

/-- 组合逻辑：assign_montprod_inst__s_adder_sm__b -/
def assign_montprod_inst__s_adder_sm__b (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__s_adder_sm__b := s.montprod_inst__opm_data
  { s with
    montprod_inst__s_adder_sm__b := montprod_inst__s_adder_sm__b
  }

/-- 组合逻辑：assign_montprod_inst__s_adder_sm__carry_in -/
def assign_montprod_inst__s_adder_sm__carry_in (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__s_adder_sm__carry_in := s.montprod_inst__add_carry_in_sm
  { s with
    montprod_inst__s_adder_sm__carry_in := montprod_inst__s_adder_sm__carry_in
  }

/-- 组合逻辑：assign_montprod_inst__add_result_sm -/
def assign_montprod_inst__add_result_sm (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__add_result_sm := s.montprod_inst__s_adder_sm__sum
  { s with
    montprod_inst__add_result_sm := montprod_inst__add_result_sm
  }

/-- 组合逻辑：assign_montprod_inst__add_carry_out_sm -/
def assign_montprod_inst__add_carry_out_sm (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__add_carry_out_sm := s.montprod_inst__s_adder_sm__carry_out
  { s with
    montprod_inst__add_carry_out_sm := montprod_inst__add_carry_out_sm
  }

/-- 组合逻辑：assign_montprod_inst__s_adder_sm__sum -/
def assign_montprod_inst__s_adder_sm__sum (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__s_adder_sm__sum := BitVec.extractLsb 31 0 (s.montprod_inst__s_adder_sm__adder_result)
  { s with
    montprod_inst__s_adder_sm__sum := montprod_inst__s_adder_sm__sum
  }

/-- 组合逻辑：assign_montprod_inst__s_adder_sm__carry_out -/
def assign_montprod_inst__s_adder_sm__carry_out (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__s_adder_sm__carry_out := BitVec.getLsbD (s.montprod_inst__s_adder_sm__adder_result) 32
  { s with
    montprod_inst__s_adder_sm__carry_out := montprod_inst__s_adder_sm__carry_out
  }

/-- 组合逻辑：assign_montprod_inst__shifter__a -/
def assign_montprod_inst__shifter__a (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__shifter__a := s.montprod_inst__s_mem_read_data
  { s with
    montprod_inst__shifter__a := montprod_inst__shifter__a
  }

/-- 组合逻辑：assign_montprod_inst__shifter__carry_in -/
def assign_montprod_inst__shifter__carry_in (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__shifter__carry_in := s.montprod_inst__shr_carry_in
  { s with
    montprod_inst__shifter__carry_in := montprod_inst__shifter__carry_in
  }

/-- 组合逻辑：assign_montprod_inst__shr_adiv2 -/
def assign_montprod_inst__shr_adiv2 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__shr_adiv2 := s.montprod_inst__shifter__adiv2
  { s with
    montprod_inst__shr_adiv2 := montprod_inst__shr_adiv2
  }

/-- 组合逻辑：assign_montprod_inst__shr_carry_out -/
def assign_montprod_inst__shr_carry_out (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__shr_carry_out := s.montprod_inst__shifter__carry_out
  { s with
    montprod_inst__shr_carry_out := montprod_inst__shr_carry_out
  }

/-- 组合逻辑：assign_montprod_inst__shifter__adiv2 -/
def assign_montprod_inst__shifter__adiv2 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__shifter__adiv2 := BitVec.append (n := 1) (m := 31) (boolToBitVec (s.montprod_inst__shifter__carry_in)) (BitVec.extractLsb 31 1 (s.montprod_inst__shifter__a))
  { s with
    montprod_inst__shifter__adiv2 := montprod_inst__shifter__adiv2
  }

/-- 组合逻辑：assign_montprod_inst__shifter__carry_out -/
def assign_montprod_inst__shifter__carry_out (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__shifter__carry_out := BitVec.getLsbD (s.montprod_inst__shifter__a) 0
  { s with
    montprod_inst__shifter__carry_out := montprod_inst__shifter__carry_out
  }

/-- 组合逻辑：assign_residue_inst__clk -/
def assign_residue_inst__clk (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__clk := i.clk
  { s with
    residue_inst__clk := residue_inst__clk
  }

/-- 组合逻辑：assign_residue_inst__reset_n -/
def assign_residue_inst__reset_n (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__reset_n := i.reset_n
  { s with
    residue_inst__reset_n := residue_inst__reset_n
  }

/-- 组合逻辑：assign_residue_inst__calculate -/
def assign_residue_inst__calculate (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__calculate := s.residue_calculate
  { s with
    residue_inst__calculate := residue_inst__calculate
  }

/-- 组合逻辑：assign_residue_ready -/
def assign_residue_ready (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_ready := s.residue_inst__ready
  { s with
    residue_ready := residue_ready
  }

/-- 组合逻辑：assign_residue_inst__nn -/
def assign_residue_inst__nn (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__nn := s.residue_nn
  { s with
    residue_inst__nn := residue_inst__nn
  }

/-- 组合逻辑：assign_residue_inst__length -/
def assign_residue_inst__length (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__length := s.residue_length
  { s with
    residue_inst__length := residue_inst__length
  }

/-- 组合逻辑：assign_residue_opa_rd_addr -/
def assign_residue_opa_rd_addr (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_opa_rd_addr := s.residue_inst__opa_rd_addr
  { s with
    residue_opa_rd_addr := residue_opa_rd_addr
  }

/-- 组合逻辑：assign_residue_inst__opa_rd_data -/
def assign_residue_inst__opa_rd_data (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__opa_rd_data := s.residue_opa_rd_data
  { s with
    residue_inst__opa_rd_data := residue_inst__opa_rd_data
  }

/-- 组合逻辑：assign_residue_opa_wr_addr -/
def assign_residue_opa_wr_addr (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_opa_wr_addr := s.residue_inst__opa_wr_addr
  { s with
    residue_opa_wr_addr := residue_opa_wr_addr
  }

/-- 组合逻辑：assign_residue_opa_wr_data -/
def assign_residue_opa_wr_data (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_opa_wr_data := s.residue_inst__opa_wr_data
  { s with
    residue_opa_wr_data := residue_opa_wr_data
  }

/-- 组合逻辑：assign_residue_opa_wr_we -/
def assign_residue_opa_wr_we (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_opa_wr_we := s.residue_inst__opa_wr_we
  { s with
    residue_opa_wr_we := residue_opa_wr_we
  }

/-- 组合逻辑：assign_residue_opm_addr -/
def assign_residue_opm_addr (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_opm_addr := s.residue_inst__opm_addr
  { s with
    residue_opm_addr := residue_opm_addr
  }

/-- 组合逻辑：assign_residue_inst__opm_data -/
def assign_residue_inst__opm_data (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__opm_data := s.residue_opm_data
  { s with
    residue_inst__opm_data := residue_inst__opm_data
  }

/-- 组合逻辑：assign_residue_inst__opa_rd_addr -/
def assign_residue_inst__opa_rd_addr (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__opa_rd_addr := s.residue_inst__opa_rd_addr_reg
  { s with
    residue_inst__opa_rd_addr := residue_inst__opa_rd_addr
  }

/-- 组合逻辑：assign_residue_inst__opa_wr_addr -/
def assign_residue_inst__opa_wr_addr (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__opa_wr_addr := s.residue_inst__opa_wr_addr_reg
  { s with
    residue_inst__opa_wr_addr := residue_inst__opa_wr_addr
  }

/-- 组合逻辑：assign_residue_inst__opa_wr_data -/
def assign_residue_inst__opa_wr_data (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__opa_wr_data := s.residue_inst__opa_wr_data_reg
  { s with
    residue_inst__opa_wr_data := residue_inst__opa_wr_data
  }

/-- 组合逻辑：assign_residue_inst__opa_wr_we -/
def assign_residue_inst__opa_wr_we (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__opa_wr_we := s.residue_inst__opa_wr_we_reg
  { s with
    residue_inst__opa_wr_we := residue_inst__opa_wr_we
  }

/-- 组合逻辑：assign_residue_inst__opm_addr -/
def assign_residue_inst__opm_addr (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__opm_addr := s.residue_inst__opm_addr_reg
  { s with
    residue_inst__opm_addr := residue_inst__opm_addr
  }

/-- 组合逻辑：assign_residue_inst__ready -/
def assign_residue_inst__ready (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__ready := s.residue_inst__ready_reg
  { s with
    residue_inst__ready := residue_inst__ready
  }

/-- 组合逻辑：assign_residue_inst__subcmp__a -/
def assign_residue_inst__subcmp__a (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__subcmp__a := s.residue_inst__opa_rd_data
  { s with
    residue_inst__subcmp__a := residue_inst__subcmp__a
  }

/-- 组合逻辑：assign_residue_inst__subcmp__b -/
def assign_residue_inst__subcmp__b (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__subcmp__b := ~~~(s.residue_inst__opm_data)
  { s with
    residue_inst__subcmp__b := residue_inst__subcmp__b
  }

/-- 组合逻辑：assign_residue_inst__subcmp__carry_in -/
def assign_residue_inst__subcmp__carry_in (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__subcmp__carry_in := s.residue_inst__sub_carry_in_reg
  { s with
    residue_inst__subcmp__carry_in := residue_inst__subcmp__carry_in
  }

/-- 组合逻辑：assign_residue_inst__sub_data -/
def assign_residue_inst__sub_data (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__sub_data := s.residue_inst__subcmp__sum
  { s with
    residue_inst__sub_data := residue_inst__sub_data
  }

/-- 组合逻辑：assign_residue_inst__sub_carry_out -/
def assign_residue_inst__sub_carry_out (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__sub_carry_out := s.residue_inst__subcmp__carry_out
  { s with
    residue_inst__sub_carry_out := residue_inst__sub_carry_out
  }

/-- 组合逻辑：assign_residue_inst__subcmp__sum -/
def assign_residue_inst__subcmp__sum (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__subcmp__sum := BitVec.extractLsb 31 0 (s.residue_inst__subcmp__adder_result)
  { s with
    residue_inst__subcmp__sum := residue_inst__subcmp__sum
  }

/-- 组合逻辑：assign_residue_inst__subcmp__carry_out -/
def assign_residue_inst__subcmp__carry_out (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__subcmp__carry_out := BitVec.getLsbD (s.residue_inst__subcmp__adder_result) 32
  { s with
    residue_inst__subcmp__carry_out := residue_inst__subcmp__carry_out
  }

/-- 组合逻辑：assign_residue_inst__shl__a -/
def assign_residue_inst__shl__a (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__shl__a := s.residue_inst__opa_rd_data
  { s with
    residue_inst__shl__a := residue_inst__shl__a
  }

/-- 组合逻辑：assign_residue_inst__shl__carry_in -/
def assign_residue_inst__shl__carry_in (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__shl__carry_in := s.residue_inst__shl_carry_in_reg
  { s with
    residue_inst__shl__carry_in := residue_inst__shl__carry_in
  }

/-- 组合逻辑：assign_residue_inst__shl_data -/
def assign_residue_inst__shl_data (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__shl_data := s.residue_inst__shl__amul2
  { s with
    residue_inst__shl_data := residue_inst__shl_data
  }

/-- 组合逻辑：assign_residue_inst__shl_carry_out -/
def assign_residue_inst__shl_carry_out (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__shl_carry_out := s.residue_inst__shl__carry_out
  { s with
    residue_inst__shl_carry_out := residue_inst__shl_carry_out
  }

/-- 组合逻辑：assign_residue_inst__shl__amul2 -/
def assign_residue_inst__shl__amul2 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__shl__amul2 := BitVec.append (n := 31) (m := 1) (BitVec.extractLsb 30 0 (s.residue_inst__shl__a)) (boolToBitVec (s.residue_inst__shl__carry_in))
  { s with
    residue_inst__shl__amul2 := residue_inst__shl__amul2
  }

/-- 组合逻辑：assign_residue_inst__shl__carry_out -/
def assign_residue_inst__shl__carry_out (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__shl__carry_out := BitVec.getLsbD (s.residue_inst__shl__a) 31
  { s with
    residue_inst__shl__carry_out := residue_inst__shl__carry_out
  }

/-- 组合逻辑：assign_residue_mem__clk -/
def assign_residue_mem__clk (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_mem__clk := i.clk
  { s with
    residue_mem__clk := residue_mem__clk
  }

/-- 组合逻辑：assign_residue_mem__read_addr0 -/
def assign_residue_mem__read_addr0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_mem__read_addr0 := s.residue_opa_rd_addr
  { s with
    residue_mem__read_addr0 := residue_mem__read_addr0
  }

/-- 组合逻辑：assign_residue_opa_rd_data -/
def assign_residue_opa_rd_data (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_opa_rd_data := s.residue_mem__read_data0
  { s with
    residue_opa_rd_data := residue_opa_rd_data
  }

/-- 组合逻辑：assign_residue_mem__read_addr1 -/
def assign_residue_mem__read_addr1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_mem__read_addr1 := s.residue_mem_montprod_read_addr
  { s with
    residue_mem__read_addr1 := residue_mem__read_addr1
  }

/-- 组合逻辑：assign_residue_mem_montprod_read_data -/
def assign_residue_mem_montprod_read_data (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_mem_montprod_read_data := s.residue_mem__read_data1
  { s with
    residue_mem_montprod_read_data := residue_mem_montprod_read_data
  }

/-- 组合逻辑：assign_residue_mem__wr -/
def assign_residue_mem__wr (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_mem__wr := s.residue_opa_wr_we
  { s with
    residue_mem__wr := residue_mem__wr
  }

/-- 组合逻辑：assign_residue_mem__write_addr -/
def assign_residue_mem__write_addr (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_mem__write_addr := s.residue_opa_wr_addr
  { s with
    residue_mem__write_addr := residue_mem__write_addr
  }

/-- 组合逻辑：assign_residue_mem__write_data -/
def assign_residue_mem__write_data (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_mem__write_data := s.residue_opa_wr_data
  { s with
    residue_mem__write_data := residue_mem__write_data
  }

/-- 组合逻辑：assign_residue_mem__read_data0 -/
def assign_residue_mem__read_data0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_mem__read_data0 := s.residue_mem__tmp_read_data0
  { s with
    residue_mem__read_data0 := residue_mem__read_data0
  }

/-- 组合逻辑：assign_residue_mem__read_data1 -/
def assign_residue_mem__read_data1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_mem__read_data1 := s.residue_mem__tmp_read_data1
  { s with
    residue_mem__read_data1 := residue_mem__read_data1
  }

/-- 组合逻辑：assign_p_mem__clk -/
def assign_p_mem__clk (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let p_mem__clk := i.clk
  { s with
    p_mem__clk := p_mem__clk
  }

/-- 组合逻辑：assign_p_mem__read_addr0 -/
def assign_p_mem__read_addr0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let p_mem__read_addr0 := s.p_mem_rd0_addr
  { s with
    p_mem__read_addr0 := p_mem__read_addr0
  }

/-- 组合逻辑：assign_p_mem_rd0_data -/
def assign_p_mem_rd0_data (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let p_mem_rd0_data := s.p_mem__read_data0
  { s with
    p_mem_rd0_data := p_mem_rd0_data
  }

/-- 组合逻辑：assign_p_mem__read_addr1 -/
def assign_p_mem__read_addr1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let p_mem__read_addr1 := s.p_mem_rd1_addr
  { s with
    p_mem__read_addr1 := p_mem__read_addr1
  }

/-- 组合逻辑：assign_p_mem_rd1_data -/
def assign_p_mem_rd1_data (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let p_mem_rd1_data := s.p_mem__read_data1
  { s with
    p_mem_rd1_data := p_mem_rd1_data
  }

/-- 组合逻辑：assign_p_mem__wr -/
def assign_p_mem__wr (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let p_mem__wr := s.p_mem_we
  { s with
    p_mem__wr := p_mem__wr
  }

/-- 组合逻辑：assign_p_mem__write_addr -/
def assign_p_mem__write_addr (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let p_mem__write_addr := s.p_mem_wr_addr
  { s with
    p_mem__write_addr := p_mem__write_addr
  }

/-- 组合逻辑：assign_p_mem__write_data -/
def assign_p_mem__write_data (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let p_mem__write_data := s.p_mem_wr_data
  { s with
    p_mem__write_data := p_mem__write_data
  }

/-- 组合逻辑：assign_p_mem__read_data0 -/
def assign_p_mem__read_data0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let p_mem__read_data0 := s.p_mem__tmp_read_data0
  { s with
    p_mem__read_data0 := p_mem__read_data0
  }

/-- 组合逻辑：assign_p_mem__read_data1 -/
def assign_p_mem__read_data1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let p_mem__read_data1 := s.p_mem__tmp_read_data1
  { s with
    p_mem__read_data1 := p_mem__read_data1
  }

/-- 组合逻辑：assign_exponent_mem__clk -/
def assign_exponent_mem__clk (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let exponent_mem__clk := i.clk
  { s with
    exponent_mem__clk := exponent_mem__clk
  }

/-- 组合逻辑：assign_exponent_mem__reset_n -/
def assign_exponent_mem__reset_n (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let exponent_mem__reset_n := i.reset_n
  { s with
    exponent_mem__reset_n := exponent_mem__reset_n
  }

/-- 组合逻辑：assign_exponent_mem__read_addr0 -/
def assign_exponent_mem__read_addr0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let exponent_mem__read_addr0 := s.exponent_mem_int_rd_addr
  { s with
    exponent_mem__read_addr0 := exponent_mem__read_addr0
  }

/-- 组合逻辑：assign_exponent_mem_int_rd_data -/
def assign_exponent_mem_int_rd_data (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let exponent_mem_int_rd_data := s.exponent_mem__read_data0
  { s with
    exponent_mem_int_rd_data := exponent_mem_int_rd_data
  }

/-- 组合逻辑：assign_exponent_mem_api_read_data -/
def assign_exponent_mem_api_read_data (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let exponent_mem_api_read_data := s.exponent_mem__read_data1
  { s with
    exponent_mem_api_read_data := exponent_mem_api_read_data
  }

/-- 组合逻辑：assign_exponent_mem__rst -/
def assign_exponent_mem__rst (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let exponent_mem__rst := i.exponent_mem_api_rst
  { s with
    exponent_mem__rst := exponent_mem__rst
  }

/-- 组合逻辑：assign_exponent_mem__cs -/
def assign_exponent_mem__cs (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let exponent_mem__cs := i.exponent_mem_api_cs
  { s with
    exponent_mem__cs := exponent_mem__cs
  }

/-- 组合逻辑：assign_exponent_mem__wr -/
def assign_exponent_mem__wr (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let exponent_mem__wr := i.exponent_mem_api_wr
  { s with
    exponent_mem__wr := exponent_mem__wr
  }

/-- 组合逻辑：assign_exponent_mem__write_data -/
def assign_exponent_mem__write_data (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let exponent_mem__write_data := i.exponent_mem_api_write_data
  { s with
    exponent_mem__write_data := exponent_mem__write_data
  }

/-- 组合逻辑：assign_exponent_mem__read_data0 -/
def assign_exponent_mem__read_data0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let exponent_mem__read_data0 := s.exponent_mem__tmp_read_data0
  { s with
    exponent_mem__read_data0 := exponent_mem__read_data0
  }

/-- 组合逻辑：assign_exponent_mem__read_data1 -/
def assign_exponent_mem__read_data1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let exponent_mem__read_data1 := s.exponent_mem__tmp_read_data1
  { s with
    exponent_mem__read_data1 := exponent_mem__read_data1
  }

/-- 组合逻辑：assign_modulus_mem__clk -/
def assign_modulus_mem__clk (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let modulus_mem__clk := i.clk
  { s with
    modulus_mem__clk := modulus_mem__clk
  }

/-- 组合逻辑：assign_modulus_mem__reset_n -/
def assign_modulus_mem__reset_n (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let modulus_mem__reset_n := i.reset_n
  { s with
    modulus_mem__reset_n := modulus_mem__reset_n
  }

/-- 组合逻辑：assign_modulus_mem__read_addr0 -/
def assign_modulus_mem__read_addr0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let modulus_mem__read_addr0 := s.modulus_mem_int_rd_addr
  { s with
    modulus_mem__read_addr0 := modulus_mem__read_addr0
  }

/-- 组合逻辑：assign_modulus_mem_int_rd_data -/
def assign_modulus_mem_int_rd_data (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let modulus_mem_int_rd_data := s.modulus_mem__read_data0
  { s with
    modulus_mem_int_rd_data := modulus_mem_int_rd_data
  }

/-- 组合逻辑：assign_modulus_mem_api_read_data -/
def assign_modulus_mem_api_read_data (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let modulus_mem_api_read_data := s.modulus_mem__read_data1
  { s with
    modulus_mem_api_read_data := modulus_mem_api_read_data
  }

/-- 组合逻辑：assign_modulus_mem__rst -/
def assign_modulus_mem__rst (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let modulus_mem__rst := i.modulus_mem_api_rst
  { s with
    modulus_mem__rst := modulus_mem__rst
  }

/-- 组合逻辑：assign_modulus_mem__cs -/
def assign_modulus_mem__cs (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let modulus_mem__cs := i.modulus_mem_api_cs
  { s with
    modulus_mem__cs := modulus_mem__cs
  }

/-- 组合逻辑：assign_modulus_mem__wr -/
def assign_modulus_mem__wr (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let modulus_mem__wr := i.modulus_mem_api_wr
  { s with
    modulus_mem__wr := modulus_mem__wr
  }

/-- 组合逻辑：assign_modulus_mem__write_data -/
def assign_modulus_mem__write_data (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let modulus_mem__write_data := i.modulus_mem_api_write_data
  { s with
    modulus_mem__write_data := modulus_mem__write_data
  }

/-- 组合逻辑：assign_modulus_mem__read_data0 -/
def assign_modulus_mem__read_data0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let modulus_mem__read_data0 := s.modulus_mem__tmp_read_data0
  { s with
    modulus_mem__read_data0 := modulus_mem__read_data0
  }

/-- 组合逻辑：assign_modulus_mem__read_data1 -/
def assign_modulus_mem__read_data1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let modulus_mem__read_data1 := s.modulus_mem__tmp_read_data1
  { s with
    modulus_mem__read_data1 := modulus_mem__read_data1
  }

/-- 组合逻辑：assign_message_mem__clk -/
def assign_message_mem__clk (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let message_mem__clk := i.clk
  { s with
    message_mem__clk := message_mem__clk
  }

/-- 组合逻辑：assign_message_mem__reset_n -/
def assign_message_mem__reset_n (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let message_mem__reset_n := i.reset_n
  { s with
    message_mem__reset_n := message_mem__reset_n
  }

/-- 组合逻辑：assign_message_mem__read_addr0 -/
def assign_message_mem__read_addr0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let message_mem__read_addr0 := s.message_mem_int_rd_addr
  { s with
    message_mem__read_addr0 := message_mem__read_addr0
  }

/-- 组合逻辑：assign_message_mem_int_rd_data -/
def assign_message_mem_int_rd_data (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let message_mem_int_rd_data := s.message_mem__read_data0
  { s with
    message_mem_int_rd_data := message_mem_int_rd_data
  }

/-- 组合逻辑：assign_message_mem_api_read_data -/
def assign_message_mem_api_read_data (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let message_mem_api_read_data := s.message_mem__read_data1
  { s with
    message_mem_api_read_data := message_mem_api_read_data
  }

/-- 组合逻辑：assign_message_mem__rst -/
def assign_message_mem__rst (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let message_mem__rst := i.message_mem_api_rst
  { s with
    message_mem__rst := message_mem__rst
  }

/-- 组合逻辑：assign_message_mem__cs -/
def assign_message_mem__cs (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let message_mem__cs := i.message_mem_api_cs
  { s with
    message_mem__cs := message_mem__cs
  }

/-- 组合逻辑：assign_message_mem__wr -/
def assign_message_mem__wr (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let message_mem__wr := i.message_mem_api_wr
  { s with
    message_mem__wr := message_mem__wr
  }

/-- 组合逻辑：assign_message_mem__write_data -/
def assign_message_mem__write_data (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let message_mem__write_data := i.message_mem_api_write_data
  { s with
    message_mem__write_data := message_mem__write_data
  }

/-- 组合逻辑：assign_message_mem__read_data0 -/
def assign_message_mem__read_data0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let message_mem__read_data0 := s.message_mem__tmp_read_data0
  { s with
    message_mem__read_data0 := message_mem__read_data0
  }

/-- 组合逻辑：assign_message_mem__read_data1 -/
def assign_message_mem__read_data1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let message_mem__read_data1 := s.message_mem__tmp_read_data1
  { s with
    message_mem__read_data1 := message_mem__read_data1
  }

/-- 组合逻辑：assign_result_mem__clk -/
def assign_result_mem__clk (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let result_mem__clk := i.clk
  { s with
    result_mem__clk := result_mem__clk
  }

/-- 组合逻辑：assign_result_mem__reset_n -/
def assign_result_mem__reset_n (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let result_mem__reset_n := i.reset_n
  { s with
    result_mem__reset_n := result_mem__reset_n
  }

/-- 组合逻辑：assign_result_mem__read_addr0 -/
def assign_result_mem__read_addr0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let result_mem__read_addr0 := BitVec.extractLsb 7 0 (s.result_mem_int_rd_addr)
  { s with
    result_mem__read_addr0 := result_mem__read_addr0
  }

/-- 组合逻辑：assign_result_mem_int_rd_data -/
def assign_result_mem_int_rd_data (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let result_mem_int_rd_data := s.result_mem__read_data0
  { s with
    result_mem_int_rd_data := result_mem_int_rd_data
  }

/-- 组合逻辑：assign_result_mem_api_read_data -/
def assign_result_mem_api_read_data (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let result_mem_api_read_data := s.result_mem__read_data1
  { s with
    result_mem_api_read_data := result_mem_api_read_data
  }

/-- 组合逻辑：assign_result_mem__rst -/
def assign_result_mem__rst (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let result_mem__rst := i.result_mem_api_rst
  { s with
    result_mem__rst := result_mem__rst
  }

/-- 组合逻辑：assign_result_mem__cs -/
def assign_result_mem__cs (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let result_mem__cs := i.result_mem_api_cs
  { s with
    result_mem__cs := result_mem__cs
  }

/-- 组合逻辑：assign_result_mem__wr -/
def assign_result_mem__wr (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let result_mem__wr := s.result_mem_int_we
  { s with
    result_mem__wr := result_mem__wr
  }

/-- 组合逻辑：assign_result_mem__write_addr -/
def assign_result_mem__write_addr (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let result_mem__write_addr := s.result_mem_int_wr_addr
  { s with
    result_mem__write_addr := result_mem__write_addr
  }

/-- 组合逻辑：assign_result_mem__write_data -/
def assign_result_mem__write_data (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let result_mem__write_data := s.result_mem_int_wr_data
  { s with
    result_mem__write_data := result_mem__write_data
  }

/-- 组合逻辑：assign_result_mem__read_data0 -/
def assign_result_mem__read_data0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let result_mem__read_data0 := s.result_mem__tmp_read_data0
  { s with
    result_mem__read_data0 := result_mem__read_data0
  }

/-- 组合逻辑：assign_result_mem__read_data1 -/
def assign_result_mem__read_data1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let result_mem__read_data1 := s.result_mem__tmp_read_data1
  { s with
    result_mem__read_data1 := result_mem__read_data1
  }

/-- 组合逻辑：proc_alwayscomb -/
def proc_alwayscomb (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__s_adder_sa__adder_result := ((BitVec.append (n := 1) (m := 32) (boolToBitVec (false)) (s.montprod_inst__s_adder_sa__a) + BitVec.append (n := 1) (m := 32) (boolToBitVec (false)) (s.montprod_inst__s_adder_sa__b)) + BitVec.append (n := 32) (m := 1) (BitVec.ofNat 32 0) (boolToBitVec (s.montprod_inst__s_adder_sa__carry_in)))
  { s with
    montprod_inst__s_adder_sa__adder_result := montprod_inst__s_adder_sa__adder_result
  }

/-- 组合逻辑：proc_alwayscomb_1 -/
def proc_alwayscomb_1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__s_adder_sm__adder_result := ((BitVec.append (n := 1) (m := 32) (boolToBitVec (false)) (s.montprod_inst__s_adder_sm__a) + BitVec.append (n := 1) (m := 32) (boolToBitVec (false)) (s.montprod_inst__s_adder_sm__b)) + BitVec.append (n := 32) (m := 1) (BitVec.ofNat 32 0) (boolToBitVec (s.montprod_inst__s_adder_sm__carry_in)))
  { s with
    montprod_inst__s_adder_sm__adder_result := montprod_inst__s_adder_sm__adder_result
  }

/-- 组合逻辑：proc_alwayscomb_2 -/
def proc_alwayscomb_2 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__s_mem_new := (if decide ((s.montprod_inst__s_mux_reg).toNat = (BitVec.ofNat 2 0).toNat) then BitVec.ofNat 32 0 else (if decide ((s.montprod_inst__s_mux_reg).toNat = (BitVec.ofNat 2 2).toNat) then s.montprod_inst__add_result_sa else (if decide ((s.montprod_inst__s_mux_reg).toNat = (BitVec.ofNat 2 1).toNat) then s.montprod_inst__add_result_sm else (if decide ((s.montprod_inst__s_mux_reg).toNat = (BitVec.ofNat 2 3).toNat) then s.montprod_inst__shr_adiv2 else s.montprod_inst__s_mem_new))))
  { s with
    montprod_inst__s_mem_new := montprod_inst__s_mem_new
  }

/-- 组合逻辑：proc_alwayscomb_3__assignment_0 -/
def proc_alwayscomb_3__assignment_0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__b := (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 4).toNat) then BitVec.getLsbD (s.montprod_inst__opb_data) ((s.montprod_inst__B_bit_index_reg - BitVec.ofNat 5 0)).toNat else s.montprod_inst__b_reg)
  { s with
    montprod_inst__b := montprod_inst__b
  }

/-- 组合逻辑：proc_alwayscomb_3__assignment_1 -/
def proc_alwayscomb_3__assignment_1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__q := (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 4).toNat) then Bool.xor (BitVec.getLsbD (s.montprod_inst__s_mem_read_data) 0) ((BitVec.getLsbD (s.montprod_inst__opa_data) 0 && BitVec.getLsbD (s.montprod_inst__opb_data) ((s.montprod_inst__B_bit_index_reg - BitVec.ofNat 5 0)).toNat)) else s.montprod_inst__q_reg)
  { s with
    montprod_inst__q := montprod_inst__q
  }

/-- 组合逻辑：proc_alwayscomb_4__assignment_0 -/
def proc_alwayscomb_4__assignment_0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__B_bit_index := (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 2).toNat) then s.montprod_inst__B_bit_index_reg else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 3).toNat) then (BitVec.ofNat 5 31 - BitVec.extractLsb 4 0 (s.montprod_inst__loop_counter)) else s.montprod_inst__B_bit_index_reg))
  { s with
    montprod_inst__B_bit_index := montprod_inst__B_bit_index
  }

/-- 组合逻辑：proc_alwayscomb_4__assignment_1 -/
def proc_alwayscomb_4__assignment_1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__B_word_index := BitVec.extractLsb 12 5 (s.montprod_inst__loop_counter)
  { s with
    montprod_inst__B_word_index := montprod_inst__B_word_index
  }

/-- 组合逻辑：proc_alwayscomb_4__assignment_2 -/
def proc_alwayscomb_4__assignment_2 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__length_m1 := (s.montprod_inst__length - BitVec.ofNat 8 1)
  { s with
    montprod_inst__length_m1 := montprod_inst__length_m1
  }

/-- 组合逻辑：proc_alwayscomb_4__assignment_3 -/
def proc_alwayscomb_4__assignment_3 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__loop_counter_dec := (s.montprod_inst__loop_counter - BitVec.ofNat 13 1)
  { s with
    montprod_inst__loop_counter_dec := montprod_inst__loop_counter_dec
  }

/-- 组合逻辑：proc_alwayscomb_4__assignment_4 -/
def proc_alwayscomb_4__assignment_4 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__loop_counter_new := (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 2).toNat) then (BitVec.append (n := 8) (m := 5) (s.montprod_inst__length) (BitVec.ofNat 5 0) - BitVec.ofNat 13 1) else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 3).toNat) then s.montprod_inst__loop_counter else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 10).toNat) then (s.montprod_inst__loop_counter - BitVec.ofNat 13 1) else s.montprod_inst__loop_counter)))
  { s with
    montprod_inst__loop_counter_new := montprod_inst__loop_counter_new
  }

/-- 组合逻辑：proc_alwayscomb_5__assignment_0 -/
def proc_alwayscomb_5__assignment_0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__opa_addr_reg := (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 3).toNat) then s.montprod_inst__length_m1 else s.montprod_inst__word_index)
  { s with
    montprod_inst__opa_addr_reg := montprod_inst__opa_addr_reg
  }

/-- 组合逻辑：proc_alwayscomb_5__assignment_1 -/
def proc_alwayscomb_5__assignment_1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__opb_addr_reg := s.montprod_inst__B_word_index
  { s with
    montprod_inst__opb_addr_reg := montprod_inst__opb_addr_reg
  }

/-- 组合逻辑：proc_alwayscomb_5__assignment_2 -/
def proc_alwayscomb_5__assignment_2 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__opm_addr_reg := s.montprod_inst__word_index
  { s with
    montprod_inst__opm_addr_reg := montprod_inst__opm_addr_reg
  }

/-- 组合逻辑：proc_alwayscomb_5__assignment_3 -/
def proc_alwayscomb_5__assignment_3 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__result_addr_reg := s.montprod_inst__word_index_prev
  { s with
    montprod_inst__result_addr_reg := montprod_inst__result_addr_reg
  }

/-- 组合逻辑：proc_alwayscomb_5__assignment_4 -/
def proc_alwayscomb_5__assignment_4 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__result_data_reg := s.montprod_inst__s_mem_read_data
  { s with
    montprod_inst__result_data_reg := montprod_inst__result_data_reg
  }

/-- 组合逻辑：proc_alwayscomb_5__assignment_5 -/
def proc_alwayscomb_5__assignment_5 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__s_mem_addr := (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 3).toNat) then s.montprod_inst__length_m1 else s.montprod_inst__word_index)
  { s with
    montprod_inst__s_mem_addr := montprod_inst__s_mem_addr
  }

/-- 组合逻辑：proc_alwayscomb_5__assignment_6 -/
def proc_alwayscomb_5__assignment_6 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__tmp_result_we := (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 12).toNat) then true else false)
  { s with
    montprod_inst__tmp_result_we := montprod_inst__tmp_result_we
  }

/-- 组合逻辑：proc_alwayscomb_5__assignment_7 -/
def proc_alwayscomb_5__assignment_7 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__word_index_new := (if decide (boolToNat (s.montprod_inst__reset_word_index_LSW) = boolToNat (true)) then s.montprod_inst__length_m1 else (if decide (boolToNat (s.montprod_inst__reset_word_index_MSW) = boolToNat (true)) then BitVec.ofNat 8 0 else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 9).toNat) then (s.montprod_inst__word_index + BitVec.ofNat 8 1) else (s.montprod_inst__word_index - BitVec.ofNat 8 1))))
  { s with
    montprod_inst__word_index_new := montprod_inst__word_index_new
  }

/-- 组合逻辑：proc_alwayscomb_6__assignment_0 -/
def proc_alwayscomb_6__assignment_0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__add_carry_new_sa := (if decide ((s.montprod_inst__s_mux_reg).toNat = (BitVec.ofNat 2 1).toNat) then false else (if decide ((s.montprod_inst__s_mux_reg).toNat = (BitVec.ofNat 2 2).toNat) then s.montprod_inst__add_carry_out_sa else false))
  { s with
    montprod_inst__add_carry_new_sa := montprod_inst__add_carry_new_sa
  }

/-- 组合逻辑：proc_alwayscomb_6__assignment_1 -/
def proc_alwayscomb_6__assignment_1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__add_carry_new_sm := (if decide ((s.montprod_inst__s_mux_reg).toNat = (BitVec.ofNat 2 1).toNat) then s.montprod_inst__add_carry_out_sm else false)
  { s with
    montprod_inst__add_carry_new_sm := montprod_inst__add_carry_new_sm
  }

/-- 组合逻辑：proc_alwayscomb_6__assignment_2 -/
def proc_alwayscomb_6__assignment_2 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__s_mem_we_new := (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 1).toNat) then true else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 5).toNat) then s.montprod_inst__q_reg else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 7).toNat) then s.montprod_inst__b_reg else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 9).toNat) then true else false))))
  { s with
    montprod_inst__s_mem_we_new := montprod_inst__s_mem_we_new
  }

/-- 组合逻辑：proc_alwayscomb_6__assignment_3 -/
def proc_alwayscomb_6__assignment_3 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__s_mux_new := (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 1).toNat) then BitVec.ofNat 2 0 else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 5).toNat) then BitVec.ofNat 2 1 else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 7).toNat) then BitVec.ofNat 2 2 else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 9).toNat) then BitVec.ofNat 2 3 else BitVec.ofNat 2 0))))
  { s with
    montprod_inst__s_mux_new := montprod_inst__s_mux_new
  }

/-- 组合逻辑：proc_alwayscomb_6__assignment_4 -/
def proc_alwayscomb_6__assignment_4 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__shr_carry_new := (if decide ((s.montprod_inst__s_mux_reg).toNat = (BitVec.ofNat 2 1).toNat) then false else (if decide ((s.montprod_inst__s_mux_reg).toNat = (BitVec.ofNat 2 2).toNat) then false else (if decide ((s.montprod_inst__s_mux_reg).toNat = (BitVec.ofNat 2 3).toNat) then s.montprod_inst__shr_carry_out else false)))
  { s with
    montprod_inst__shr_carry_new := montprod_inst__shr_carry_new
  }

/-- 组合逻辑：proc_alwayscomb_7__assignment_0 -/
def proc_alwayscomb_7__assignment_0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__montprod_ctrl_new := (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 0).toNat) then (if s.montprod_inst__calculate then BitVec.ofNat 4 1 else BitVec.ofNat 4 0) else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 1).toNat) then (if decide ((s.montprod_inst__word_index).toNat = (BitVec.ofNat 8 0).toNat) then BitVec.ofNat 4 2 else BitVec.ofNat 4 0) else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 2).toNat) then BitVec.ofNat 4 3 else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 3).toNat) then BitVec.ofNat 4 4 else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 4).toNat) then BitVec.ofNat 4 5 else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 5).toNat) then (if decide ((s.montprod_inst__word_index).toNat = (BitVec.ofNat 8 0).toNat) then BitVec.ofNat 4 6 else BitVec.ofNat 4 0) else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 6).toNat) then BitVec.ofNat 4 7 else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 7).toNat) then (if decide ((s.montprod_inst__word_index).toNat = (BitVec.ofNat 8 0).toNat) then BitVec.ofNat 4 8 else BitVec.ofNat 4 0) else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 8).toNat) then BitVec.ofNat 4 9 else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 9).toNat) then (if decide ((s.montprod_inst__word_index).toNat = (s.montprod_inst__length_m1).toNat) then BitVec.ofNat 4 10 else BitVec.ofNat 4 0) else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 10).toNat) then (if decide ((s.montprod_inst__loop_counter).toNat = (BitVec.ofNat 32 0).toNat) then BitVec.ofNat 4 11 else BitVec.ofNat 4 3) else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 11).toNat) then BitVec.ofNat 4 12 else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 12).toNat) then (if decide ((s.montprod_inst__word_index_prev).toNat = (BitVec.ofNat 8 0).toNat) then BitVec.ofNat 4 13 else BitVec.ofNat 4 0) else BitVec.ofNat 4 0)))))))))))))
  { s with
    montprod_inst__montprod_ctrl_new := montprod_inst__montprod_ctrl_new
  }

/-- 组合逻辑：proc_alwayscomb_7__assignment_1 -/
def proc_alwayscomb_7__assignment_1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__montprod_ctrl_we := (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 0).toNat) then (if s.montprod_inst__calculate then true else false) else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 1).toNat) then (if decide ((s.montprod_inst__word_index).toNat = (BitVec.ofNat 8 0).toNat) then true else false) else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 2).toNat) then true else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 3).toNat) then true else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 4).toNat) then true else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 5).toNat) then (if decide ((s.montprod_inst__word_index).toNat = (BitVec.ofNat 8 0).toNat) then true else false) else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 6).toNat) then true else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 7).toNat) then (if decide ((s.montprod_inst__word_index).toNat = (BitVec.ofNat 8 0).toNat) then true else false) else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 8).toNat) then true else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 9).toNat) then (if decide ((s.montprod_inst__word_index).toNat = (s.montprod_inst__length_m1).toNat) then true else false) else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 10).toNat) then true else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 11).toNat) then true else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 12).toNat) then (if decide ((s.montprod_inst__word_index_prev).toNat = (BitVec.ofNat 8 0).toNat) then true else false) else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 13).toNat) then true else false))))))))))))))
  { s with
    montprod_inst__montprod_ctrl_we := montprod_inst__montprod_ctrl_we
  }

/-- 组合逻辑：proc_alwayscomb_7__assignment_2 -/
def proc_alwayscomb_7__assignment_2 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__ready_new := (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 0).toNat) then (if s.montprod_inst__calculate then false else true) else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 1).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 2).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 3).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 4).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 5).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 6).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 7).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 8).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 9).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 10).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 11).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 12).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 13).toNat) then true else false))))))))))))))
  { s with
    montprod_inst__ready_new := montprod_inst__ready_new
  }

/-- 组合逻辑：proc_alwayscomb_7__assignment_3 -/
def proc_alwayscomb_7__assignment_3 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__ready_we := (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 0).toNat) then true else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 1).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 2).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 3).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 4).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 5).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 6).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 7).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 8).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 9).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 10).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 11).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 12).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 13).toNat) then true else false))))))))))))))
  { s with
    montprod_inst__ready_we := montprod_inst__ready_we
  }

/-- 组合逻辑：proc_alwayscomb_7__assignment_4 -/
def proc_alwayscomb_7__assignment_4 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__reset_word_index_LSW := (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 0).toNat) then (if s.montprod_inst__calculate then true else false) else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 1).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 2).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 3).toNat) then true else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 4).toNat) then true else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 5).toNat) then (if decide ((s.montprod_inst__word_index).toNat = (BitVec.ofNat 8 0).toNat) then true else false) else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 6).toNat) then true else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 7).toNat) then (if decide ((s.montprod_inst__word_index).toNat = (BitVec.ofNat 8 0).toNat) then true else false) else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 8).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 9).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 10).toNat) then true else false)))))))))))
  { s with
    montprod_inst__reset_word_index_LSW := montprod_inst__reset_word_index_LSW
  }

/-- 组合逻辑：proc_alwayscomb_7__assignment_5 -/
def proc_alwayscomb_7__assignment_5 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_inst__reset_word_index_MSW := (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 0).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 1).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 2).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 3).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 4).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 5).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 6).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 7).toNat) then false else (if decide ((s.montprod_inst__montprod_ctrl_reg).toNat = (BitVec.ofNat 4 8).toNat) then true else false)))))))))
  { s with
    montprod_inst__reset_word_index_MSW := montprod_inst__reset_word_index_MSW
  }

/-- 组合逻辑：proc_alwayscomb_8 -/
def proc_alwayscomb_8 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__subcmp__adder_result := ((BitVec.append (n := 1) (m := 32) (boolToBitVec (false)) (s.residue_inst__subcmp__a) + BitVec.append (n := 1) (m := 32) (boolToBitVec (false)) (s.residue_inst__subcmp__b)) + BitVec.append (n := 32) (m := 1) (BitVec.ofNat 32 0) (boolToBitVec (s.residue_inst__subcmp__carry_in)))
  { s with
    residue_inst__subcmp__adder_result := residue_inst__subcmp__adder_result
  }

/-- 组合逻辑：proc_alwayscomb_9__assignment_0 -/
def proc_alwayscomb_9__assignment_0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__loop_counter_1_to_nn_new := (if s.residue_inst__reset_n_counter then BitVec.ofNat 15 1 else (s.residue_inst__loop_counter_1_to_nn_reg + BitVec.ofNat 15 1))
  { s with
    residue_inst__loop_counter_1_to_nn_new := residue_inst__loop_counter_1_to_nn_new
  }

/-- 组合逻辑：proc_alwayscomb_9__assignment_1 -/
def proc_alwayscomb_9__assignment_1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__loop_counter_1_to_nn_we := (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 9).toNat) then true else (if s.residue_inst__reset_n_counter then true else false))
  { s with
    residue_inst__loop_counter_1_to_nn_we := residue_inst__loop_counter_1_to_nn_we
  }

/-- 组合逻辑：proc_alwayscomb_10__assignment_0 -/
def proc_alwayscomb_10__assignment_0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__word_index_new := (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 0).toNat) then s.residue_inst__length_m1_new else (if s.residue_inst__reset_word_index then s.residue_inst__length_m1_reg else (s.residue_inst__word_index_reg - BitVec.ofNat 8 1)))
  { s with
    residue_inst__word_index_new := residue_inst__word_index_new
  }

/-- 组合逻辑：proc_alwayscomb_10__assignment_1 -/
def proc_alwayscomb_10__assignment_1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__word_index_we := true
  { s with
    residue_inst__word_index_we := residue_inst__word_index_we
  }

/-- 组合逻辑：proc_alwayscomb_11__assignment_0 -/
def proc_alwayscomb_11__assignment_0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__opa_wr_addr_reg := s.residue_inst__word_index_reg
  { s with
    residue_inst__opa_wr_addr_reg := residue_inst__opa_wr_addr_reg
  }

/-- 组合逻辑：proc_alwayscomb_11__assignment_1 -/
def proc_alwayscomb_11__assignment_1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__opa_wr_data_reg := (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 1).toNat) then s.residue_inst__one_data else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 7).toNat) then s.residue_inst__sub_data else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 3).toNat) then s.residue_inst__shl_data else BitVec.ofNat 32 0)))
  { s with
    residue_inst__opa_wr_data_reg := residue_inst__opa_wr_data_reg
  }

/-- 组合逻辑：proc_alwayscomb_11__assignment_2 -/
def proc_alwayscomb_11__assignment_2 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__opa_wr_we_reg := (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 1).toNat) then true else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 7).toNat) then true else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 3).toNat) then true else false)))
  { s with
    residue_inst__opa_wr_we_reg := residue_inst__opa_wr_we_reg
  }

/-- 组合逻辑：proc_alwayscomb_12__assignment_0 -/
def proc_alwayscomb_12__assignment_0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__opa_rd_addr_reg := s.residue_inst__word_index_new
  { s with
    residue_inst__opa_rd_addr_reg := residue_inst__opa_rd_addr_reg
  }

/-- 组合逻辑：proc_alwayscomb_12__assignment_1 -/
def proc_alwayscomb_12__assignment_1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__opm_addr_reg := s.residue_inst__word_index_new
  { s with
    residue_inst__opm_addr_reg := residue_inst__opm_addr_reg
  }

/-- 组合逻辑：proc_alwayscomb_13__assignment_0 -/
def proc_alwayscomb_13__assignment_0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__shl_carry_in_new := (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 3).toNat) then s.residue_inst__shl_carry_out else false)
  { s with
    residue_inst__shl_carry_in_new := residue_inst__shl_carry_in_new
  }

/-- 组合逻辑：proc_alwayscomb_13__assignment_1 -/
def proc_alwayscomb_13__assignment_1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__sub_carry_in_new := (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 5).toNat) then s.residue_inst__sub_carry_out else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 7).toNat) then s.residue_inst__sub_carry_out else true))
  { s with
    residue_inst__sub_carry_in_new := residue_inst__sub_carry_in_new
  }

/-- 组合逻辑：proc_alwayscomb_14 -/
def proc_alwayscomb_14 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__one_data := (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 1).toNat) then (if decide ((s.residue_inst__word_index_reg).toNat = (s.residue_inst__length_m1_reg).toNat) then BitVec.ofNat 32 1 else BitVec.ofNat 32 0) else BitVec.ofNat 32 0)
  { s with
    residue_inst__one_data := residue_inst__one_data
  }

/-- 组合逻辑：proc_alwayscomb_15__assignment_0 -/
def proc_alwayscomb_15__assignment_0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__length_m1_new := (s.residue_inst__length - BitVec.ofNat 8 1)
  { s with
    residue_inst__length_m1_new := residue_inst__length_m1_new
  }

/-- 组合逻辑：proc_alwayscomb_15__assignment_1 -/
def proc_alwayscomb_15__assignment_1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__length_m1_we := (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 0).toNat) then (if s.residue_inst__calculate then true else false) else false)
  { s with
    residue_inst__length_m1_we := residue_inst__length_m1_we
  }

/-- 组合逻辑：proc_alwayscomb_15__assignment_2 -/
def proc_alwayscomb_15__assignment_2 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__nn_we := (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 0).toNat) then (if s.residue_inst__calculate then true else false) else false)
  { s with
    residue_inst__nn_we := residue_inst__nn_we
  }

/-- 组合逻辑：proc_alwayscomb_15__assignment_3 -/
def proc_alwayscomb_15__assignment_3 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__ready_new := (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 0).toNat) then false else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 1).toNat) then false else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 2).toNat) then false else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 3).toNat) then false else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 4).toNat) then false else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 5).toNat) then false else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 6).toNat) then false else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 7).toNat) then false else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 8).toNat) then false else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 9).toNat) then (if decide ((s.residue_inst__loop_counter_1_to_nn_reg).toNat = (s.residue_inst__nn_reg).toNat) then true else false) else false))))))))))
  { s with
    residue_inst__ready_new := residue_inst__ready_new
  }

/-- 组合逻辑：proc_alwayscomb_15__assignment_4 -/
def proc_alwayscomb_15__assignment_4 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__ready_we := (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 0).toNat) then (if s.residue_inst__calculate then true else false) else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 1).toNat) then false else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 2).toNat) then false else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 3).toNat) then false else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 4).toNat) then false else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 5).toNat) then false else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 6).toNat) then false else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 7).toNat) then false else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 8).toNat) then false else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 9).toNat) then (if decide ((s.residue_inst__loop_counter_1_to_nn_reg).toNat = (s.residue_inst__nn_reg).toNat) then true else false) else false))))))))))
  { s with
    residue_inst__ready_we := residue_inst__ready_we
  }

/-- 组合逻辑：proc_alwayscomb_15__assignment_5 -/
def proc_alwayscomb_15__assignment_5 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__reset_n_counter := (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 0).toNat) then false else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 1).toNat) then false else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 2).toNat) then true else false)))
  { s with
    residue_inst__reset_n_counter := residue_inst__reset_n_counter
  }

/-- 组合逻辑：proc_alwayscomb_15__assignment_6 -/
def proc_alwayscomb_15__assignment_6 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__reset_word_index := (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 0).toNat) then (if s.residue_inst__calculate then true else false) else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 1).toNat) then false else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 2).toNat) then true else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 3).toNat) then false else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 4).toNat) then true else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 5).toNat) then false else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 6).toNat) then true else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 7).toNat) then false else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 8).toNat) then false else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 9).toNat) then (if decide ((s.residue_inst__loop_counter_1_to_nn_reg).toNat = (s.residue_inst__nn_reg).toNat) then false else true) else false))))))))))
  { s with
    residue_inst__reset_word_index := residue_inst__reset_word_index
  }

/-- 组合逻辑：proc_alwayscomb_15__assignment_7 -/
def proc_alwayscomb_15__assignment_7 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__residue_ctrl_new := (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 0).toNat) then (if s.residue_inst__calculate then BitVec.ofNat 4 1 else BitVec.ofNat 4 0) else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 1).toNat) then (if decide ((s.residue_inst__word_index_reg).toNat = (BitVec.ofNat 8 0).toNat) then BitVec.ofNat 4 2 else BitVec.ofNat 4 0) else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 2).toNat) then BitVec.ofNat 4 3 else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 3).toNat) then (if decide ((s.residue_inst__word_index_reg).toNat = (BitVec.ofNat 8 0).toNat) then BitVec.ofNat 4 4 else BitVec.ofNat 4 0) else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 4).toNat) then BitVec.ofNat 4 5 else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 5).toNat) then (if decide ((s.residue_inst__word_index_reg).toNat = (BitVec.ofNat 8 0).toNat) then BitVec.ofNat 4 6 else BitVec.ofNat 4 0) else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 6).toNat) then (if decide (boolToNat (s.residue_inst__sub_carry_in_reg) = boolToNat (true)) then BitVec.ofNat 4 7 else BitVec.ofNat 4 9) else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 7).toNat) then (if decide ((s.residue_inst__word_index_reg).toNat = (BitVec.ofNat 8 0).toNat) then BitVec.ofNat 4 8 else BitVec.ofNat 4 0) else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 8).toNat) then BitVec.ofNat 4 9 else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 9).toNat) then (if decide ((s.residue_inst__loop_counter_1_to_nn_reg).toNat = (s.residue_inst__nn_reg).toNat) then BitVec.ofNat 4 0 else BitVec.ofNat 4 3) else BitVec.ofNat 4 0))))))))))
  { s with
    residue_inst__residue_ctrl_new := residue_inst__residue_ctrl_new
  }

/-- 组合逻辑：proc_alwayscomb_15__assignment_8 -/
def proc_alwayscomb_15__assignment_8 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_inst__residue_ctrl_we := (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 0).toNat) then (if s.residue_inst__calculate then true else false) else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 1).toNat) then (if decide ((s.residue_inst__word_index_reg).toNat = (BitVec.ofNat 8 0).toNat) then true else false) else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 2).toNat) then true else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 3).toNat) then (if decide ((s.residue_inst__word_index_reg).toNat = (BitVec.ofNat 8 0).toNat) then true else false) else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 4).toNat) then true else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 5).toNat) then (if decide ((s.residue_inst__word_index_reg).toNat = (BitVec.ofNat 8 0).toNat) then true else false) else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 6).toNat) then true else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 7).toNat) then (if decide ((s.residue_inst__word_index_reg).toNat = (BitVec.ofNat 8 0).toNat) then true else false) else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 8).toNat) then true else (if decide ((s.residue_inst__residue_ctrl_reg).toNat = (BitVec.ofNat 4 9).toNat) then true else false))))))))))
  { s with
    residue_inst__residue_ctrl_we := residue_inst__residue_ctrl_we
  }

/-- 组合逻辑：proc_alwayscomb_16__assignment_0 -/
def proc_alwayscomb_16__assignment_0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let exponent_mem__ptr_new := (if s.exponent_mem__cs then (s.exponent_mem__ptr_reg + BitVec.ofNat 8 1) else BitVec.ofNat 8 0)
  { s with
    exponent_mem__ptr_new := exponent_mem__ptr_new
  }

/-- 组合逻辑：proc_alwayscomb_16__assignment_1 -/
def proc_alwayscomb_16__assignment_1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let exponent_mem__ptr_we := (if s.exponent_mem__cs then true else (if s.exponent_mem__rst then true else false))
  { s with
    exponent_mem__ptr_we := exponent_mem__ptr_we
  }

/-- 组合逻辑：proc_alwayscomb_17__assignment_0 -/
def proc_alwayscomb_17__assignment_0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let modulus_mem__ptr_new := (if s.modulus_mem__cs then (s.modulus_mem__ptr_reg + BitVec.ofNat 8 1) else BitVec.ofNat 8 0)
  { s with
    modulus_mem__ptr_new := modulus_mem__ptr_new
  }

/-- 组合逻辑：proc_alwayscomb_17__assignment_1 -/
def proc_alwayscomb_17__assignment_1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let modulus_mem__ptr_we := (if s.modulus_mem__cs then true else (if s.modulus_mem__rst then true else false))
  { s with
    modulus_mem__ptr_we := modulus_mem__ptr_we
  }

/-- 组合逻辑：proc_alwayscomb_18__assignment_0 -/
def proc_alwayscomb_18__assignment_0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let message_mem__ptr_new := (if s.message_mem__cs then (s.message_mem__ptr_reg + BitVec.ofNat 8 1) else BitVec.ofNat 8 0)
  { s with
    message_mem__ptr_new := message_mem__ptr_new
  }

/-- 组合逻辑：proc_alwayscomb_18__assignment_1 -/
def proc_alwayscomb_18__assignment_1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let message_mem__ptr_we := (if s.message_mem__cs then true else (if s.message_mem__rst then true else false))
  { s with
    message_mem__ptr_we := message_mem__ptr_we
  }

/-- 组合逻辑：proc_alwayscomb_19__assignment_0 -/
def proc_alwayscomb_19__assignment_0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let result_mem__ptr_new := (if s.result_mem__cs then (s.result_mem__ptr_reg + BitVec.ofNat 8 1) else BitVec.ofNat 8 0)
  { s with
    result_mem__ptr_new := result_mem__ptr_new
  }

/-- 组合逻辑：proc_alwayscomb_19__assignment_1 -/
def proc_alwayscomb_19__assignment_1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let result_mem__ptr_we := (if s.result_mem__cs then true else (if s.result_mem__rst then true else false))
  { s with
    result_mem__ptr_we := result_mem__ptr_we
  }

/-- 组合逻辑：proc_alwayscomb_20__assignment_0 -/
def proc_alwayscomb_20__assignment_0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let cycle_ctr_high_new := (if s.cycle_ctr_state_reg then (if decide (((s.cycle_ctr_low_reg + BitVec.ofNat 32 1)).toNat = (BitVec.ofNat 32 0).toNat) then (s.cycle_ctr_high_reg + BitVec.ofNat 32 1) else BitVec.ofNat 32 0) else BitVec.ofNat 32 0)
  { s with
    cycle_ctr_high_new := cycle_ctr_high_new
  }

/-- 组合逻辑：proc_alwayscomb_20__assignment_1 -/
def proc_alwayscomb_20__assignment_1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let cycle_ctr_high_we := (if s.cycle_ctr_state_reg then (if decide (((s.cycle_ctr_low_reg + BitVec.ofNat 32 1)).toNat = (BitVec.ofNat 32 0).toNat) then true else (if s.cycle_ctr_start then true else false)) else (if s.cycle_ctr_start then true else false))
  { s with
    cycle_ctr_high_we := cycle_ctr_high_we
  }

/-- 组合逻辑：proc_alwayscomb_20__assignment_2 -/
def proc_alwayscomb_20__assignment_2 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let cycle_ctr_low_new := (if s.cycle_ctr_state_reg then (s.cycle_ctr_low_reg + BitVec.ofNat 32 1) else BitVec.ofNat 32 0)
  { s with
    cycle_ctr_low_new := cycle_ctr_low_new
  }

/-- 组合逻辑：proc_alwayscomb_20__assignment_3 -/
def proc_alwayscomb_20__assignment_3 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let cycle_ctr_low_we := (if s.cycle_ctr_state_reg then true else (if s.cycle_ctr_start then true else false))
  { s with
    cycle_ctr_low_we := cycle_ctr_low_we
  }

/-- 组合逻辑：proc_alwayscomb_20__assignment_4 -/
def proc_alwayscomb_20__assignment_4 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let cycle_ctr_state_new := (if s.cycle_ctr_stop then false else (if s.cycle_ctr_start then true else false))
  { s with
    cycle_ctr_state_new := cycle_ctr_state_new
  }

/-- 组合逻辑：proc_alwayscomb_20__assignment_5 -/
def proc_alwayscomb_20__assignment_5 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let cycle_ctr_state_we := (if s.cycle_ctr_stop then true else (if s.cycle_ctr_start then true else false))
  { s with
    cycle_ctr_state_we := cycle_ctr_state_we
  }

/-- 组合逻辑：proc_alwayscomb_21__assignment_0 -/
def proc_alwayscomb_21__assignment_0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let b_one_new := (if decide ((s.montprod_opb_addr).toNat = (s.length_m1).toNat) then BitVec.ofNat 32 1 else BitVec.ofNat 32 0)
  { s with
    b_one_new := b_one_new
  }

/-- 组合逻辑：proc_alwayscomb_21__assignment_1 -/
def proc_alwayscomb_21__assignment_1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let one_new := (if decide ((s.montprod_opa_addr).toNat = (s.length_m1).toNat) then BitVec.ofNat 32 1 else BitVec.ofNat 32 0)
  { s with
    one_new := one_new
  }

/-- 组合逻辑：proc_alwayscomb_22 -/
def proc_alwayscomb_22 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let modulus_mem_int_rd_addr := (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 1).toNat) then s.residue_opm_addr else s.montprod_opm_addr)
  { s with
    modulus_mem_int_rd_addr := modulus_mem_int_rd_addr
  }

/-- 组合逻辑：proc_alwayscomb_23__assignment_0 -/
def proc_alwayscomb_23__assignment_0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_length := i.modulus_length
  { s with
    residue_length := residue_length
  }

/-- 组合逻辑：proc_alwayscomb_23__assignment_1 -/
def proc_alwayscomb_23__assignment_1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_nn := BitVec.append (n := 1) (m := 14) (boolToBitVec (false)) (BitVec.append (n := 8) (m := 6) (i.modulus_length) (BitVec.ofNat 6 0))
  { s with
    residue_nn := residue_nn
  }

/-- 组合逻辑：proc_alwayscomb_23__assignment_2 -/
def proc_alwayscomb_23__assignment_2 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_opm_data := s.modulus_mem_int_rd_data
  { s with
    residue_opm_data := residue_opm_data
  }

/-- 组合逻辑：proc_alwayscomb_24 -/
def proc_alwayscomb_24 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_valid_new := (if (i.modulus_mem_api_cs && i.modulus_mem_api_wr) then false else (if decide (boolToNat (s.residue_valid_int_validated) = boolToNat (true)) then true else s.residue_valid_reg))
  { s with
    residue_valid_new := residue_valid_new
  }

/-- 组合逻辑：proc_alwayscomb_25__assignment_0 -/
def proc_alwayscomb_25__assignment_0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let message_mem_int_rd_addr := s.montprod_opa_addr
  { s with
    message_mem_int_rd_addr := message_mem_int_rd_addr
  }

/-- 组合逻辑：proc_alwayscomb_25__assignment_1 -/
def proc_alwayscomb_25__assignment_1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_length := i.modulus_length
  { s with
    montprod_length := montprod_length
  }

/-- 组合逻辑：proc_alwayscomb_25__assignment_2 -/
def proc_alwayscomb_25__assignment_2 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_opa_data := (if decide ((s.montprod_select_reg).toNat = (BitVec.ofNat 3 0).toNat) then s.one_reg else (if decide ((s.montprod_select_reg).toNat = (BitVec.ofNat 3 1).toNat) then s.message_mem_int_rd_data else (if decide ((s.montprod_select_reg).toNat = (BitVec.ofNat 3 2).toNat) then s.result_mem_int_rd_data else (if decide ((s.montprod_select_reg).toNat = (BitVec.ofNat 3 3).toNat) then s.p_mem_rd0_data else (if decide ((s.montprod_select_reg).toNat = (BitVec.ofNat 3 4).toNat) then s.result_mem_int_rd_data else BitVec.ofNat 32 0)))))
  { s with
    montprod_opa_data := montprod_opa_data
  }

/-- 组合逻辑：proc_alwayscomb_25__assignment_3 -/
def proc_alwayscomb_25__assignment_3 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_opb_data := (if decide ((s.montprod_select_reg).toNat = (BitVec.ofNat 3 0).toNat) then s.residue_mem_montprod_read_data else (if decide ((s.montprod_select_reg).toNat = (BitVec.ofNat 3 1).toNat) then s.residue_mem_montprod_read_data else (if decide ((s.montprod_select_reg).toNat = (BitVec.ofNat 3 2).toNat) then s.p_mem_rd1_data else (if decide ((s.montprod_select_reg).toNat = (BitVec.ofNat 3 3).toNat) then s.p_mem_rd1_data else (if decide ((s.montprod_select_reg).toNat = (BitVec.ofNat 3 4).toNat) then s.b_one_reg else BitVec.ofNat 32 0)))))
  { s with
    montprod_opb_data := montprod_opb_data
  }

/-- 组合逻辑：proc_alwayscomb_25__assignment_4 -/
def proc_alwayscomb_25__assignment_4 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_opm_data := s.modulus_mem_int_rd_data
  { s with
    montprod_opm_data := montprod_opm_data
  }

/-- 组合逻辑：proc_alwayscomb_25__assignment_5 -/
def proc_alwayscomb_25__assignment_5 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let p_mem_rd0_addr := s.montprod_opa_addr
  { s with
    p_mem_rd0_addr := p_mem_rd0_addr
  }

/-- 组合逻辑：proc_alwayscomb_25__assignment_6 -/
def proc_alwayscomb_25__assignment_6 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let p_mem_rd1_addr := s.montprod_opb_addr
  { s with
    p_mem_rd1_addr := p_mem_rd1_addr
  }

/-- 组合逻辑：proc_alwayscomb_25__assignment_7 -/
def proc_alwayscomb_25__assignment_7 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_mem_montprod_read_addr := s.montprod_opb_addr
  { s with
    residue_mem_montprod_read_addr := residue_mem_montprod_read_addr
  }

/-- 组合逻辑：proc_alwayscomb_25__assignment_8 -/
def proc_alwayscomb_25__assignment_8 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let result_mem_int_rd_addr := s.montprod_opa_addr
  { s with
    result_mem_int_rd_addr := result_mem_int_rd_addr
  }

/-- 组合逻辑：proc_alwayscomb_26__assignment_0 -/
def proc_alwayscomb_26__assignment_0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let p_mem_we := (if decide ((s.montprod_dest_reg).toNat = (BitVec.ofNat 2 0).toNat) then false else (if decide ((s.montprod_dest_reg).toNat = (BitVec.ofNat 2 1).toNat) then s.montprod_result_we else false))
  { s with
    p_mem_we := p_mem_we
  }

/-- 组合逻辑：proc_alwayscomb_26__assignment_1 -/
def proc_alwayscomb_26__assignment_1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let p_mem_wr_addr := s.montprod_result_addr
  { s with
    p_mem_wr_addr := p_mem_wr_addr
  }

/-- 组合逻辑：proc_alwayscomb_26__assignment_2 -/
def proc_alwayscomb_26__assignment_2 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let p_mem_wr_data := s.montprod_result_data
  { s with
    p_mem_wr_data := p_mem_wr_data
  }

/-- 组合逻辑：proc_alwayscomb_26__assignment_3 -/
def proc_alwayscomb_26__assignment_3 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let result_mem_int_we := (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 5).toNat) then ((if decide ((s.montprod_dest_reg).toNat = (BitVec.ofNat 2 0).toNat) then s.montprod_result_we else false) && s.ei_reg) else (if decide ((s.montprod_dest_reg).toNat = (BitVec.ofNat 2 0).toNat) then s.montprod_result_we else false))
  { s with
    result_mem_int_we := result_mem_int_we
  }

/-- 组合逻辑：proc_alwayscomb_26__assignment_4 -/
def proc_alwayscomb_26__assignment_4 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let result_mem_int_wr_addr := s.montprod_result_addr
  { s with
    result_mem_int_wr_addr := result_mem_int_wr_addr
  }

/-- 组合逻辑：proc_alwayscomb_26__assignment_5 -/
def proc_alwayscomb_26__assignment_5 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let result_mem_int_wr_data := s.montprod_result_data
  { s with
    result_mem_int_wr_data := result_mem_int_wr_data
  }

/-- 组合逻辑：proc_alwayscomb_27__assignment_0 -/
def proc_alwayscomb_27__assignment_0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let last_iteration := (if decide ((s.loop_counter_reg).toNat = (BitVec.append (n := 8) (m := 5) (s.length_m1) (BitVec.ofNat 5 31)).toNat) then true else false)
  { s with
    last_iteration := last_iteration
  }

/-- 组合逻辑：proc_alwayscomb_27__assignment_1 -/
def proc_alwayscomb_27__assignment_1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let loop_counter_new := (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 3).toNat) then BitVec.ofNat 13 0 else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 7).toNat) then (s.loop_counter_reg + BitVec.ofNat 13 1) else BitVec.ofNat 13 0))
  { s with
    loop_counter_new := loop_counter_new
  }

/-- 组合逻辑：proc_alwayscomb_27__assignment_2 -/
def proc_alwayscomb_27__assignment_2 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let loop_counter_we := (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 3).toNat) then true else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 7).toNat) then true else false))
  { s with
    loop_counter_we := loop_counter_we
  }

/-- 组合逻辑：proc_alwayscomb_28__assignment_0 -/
def proc_alwayscomb_28__assignment_0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let E_bit_index := BitVec.extractLsb 4 0 (s.loop_counter_reg)
  { s with
    E_bit_index := E_bit_index
  }

/-- 组合逻辑：proc_alwayscomb_28__assignment_1 -/
def proc_alwayscomb_28__assignment_1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let E_word_index := (s.length_m1 - BitVec.extractLsb 12 5 (s.loop_counter_new))
  { s with
    E_word_index := E_word_index
  }

/-- 组合逻辑：proc_alwayscomb_28__assignment_2 -/
def proc_alwayscomb_28__assignment_2 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let ei_new := BitVec.getLsbD (s.exponent_mem_int_rd_data) ((BitVec.extractLsb 4 0 (s.loop_counter_reg) - BitVec.ofNat 5 0)).toNat
  { s with
    ei_new := ei_new
  }

/-- 组合逻辑：proc_alwayscomb_28__assignment_3 -/
def proc_alwayscomb_28__assignment_3 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let ei_we := (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 4).toNat) then true else false)
  { s with
    ei_we := ei_we
  }

/-- 组合逻辑：proc_alwayscomb_28__assignment_4 -/
def proc_alwayscomb_28__assignment_4 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let exponent_mem_int_rd_addr := (s.length_m1 - BitVec.extractLsb 12 5 (s.loop_counter_new))
  { s with
    exponent_mem_int_rd_addr := exponent_mem_int_rd_addr
  }

/-- 组合逻辑：proc_alwayscomb_29__assignment_0 -/
def proc_alwayscomb_29__assignment_0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let cycle_ctr_start := (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 0).toNat) then (if i.start then true else false) else false)
  { s with
    cycle_ctr_start := cycle_ctr_start
  }

/-- 组合逻辑：proc_alwayscomb_29__assignment_1 -/
def proc_alwayscomb_29__assignment_1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let cycle_ctr_stop := (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 0).toNat) then false else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 1).toNat) then false else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 2).toNat) then false else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 3).toNat) then false else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 4).toNat) then false else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 5).toNat) then false else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 6).toNat) then false else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 7).toNat) then false else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 8).toNat) then false else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 9).toNat) then true else false))))))))))
  { s with
    cycle_ctr_stop := cycle_ctr_stop
  }

/-- 组合逻辑：proc_alwayscomb_29__assignment_2 -/
def proc_alwayscomb_29__assignment_2 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let modexp_ctrl_new := (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 0).toNat) then (if i.start then (if s.residue_valid_reg then BitVec.ofNat 4 2 else BitVec.ofNat 4 1) else BitVec.ofNat 4 0) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 1).toNat) then (if s.residue_ready then BitVec.ofNat 4 2 else BitVec.ofNat 4 0) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 2).toNat) then (if s.montprod_ready then BitVec.ofNat 4 3 else BitVec.ofNat 4 0) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 3).toNat) then (if decide (boolToNat (s.montprod_ready) = boolToNat (true)) then BitVec.ofNat 4 4 else BitVec.ofNat 4 0) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 4).toNat) then (if (decide (boolToNat (s.ei_new) = boolToNat (false)) && decide (boolToNat (s.exponation_mode_reg) = boolToNat (true))) then BitVec.ofNat 4 6 else BitVec.ofNat 4 5) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 5).toNat) then (if s.montprod_ready then BitVec.ofNat 4 6 else BitVec.ofNat 4 0) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 6).toNat) then (if decide (boolToNat (s.montprod_ready) = boolToNat (true)) then BitVec.ofNat 4 7 else BitVec.ofNat 4 0) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 7).toNat) then (if !(s.last_iteration) then BitVec.ofNat 4 4 else BitVec.ofNat 4 8) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 8).toNat) then (if s.montprod_ready then BitVec.ofNat 4 9 else BitVec.ofNat 4 0) else BitVec.ofNat 4 0)))))))))
  { s with
    modexp_ctrl_new := modexp_ctrl_new
  }

/-- 组合逻辑：proc_alwayscomb_29__assignment_3 -/
def proc_alwayscomb_29__assignment_3 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let modexp_ctrl_we := (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 0).toNat) then (if i.start then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else false) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 1).toNat) then (if s.residue_ready then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else false) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 2).toNat) then (if s.montprod_ready then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else false) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 3).toNat) then (if decide (boolToNat (s.montprod_ready) = boolToNat (true)) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else false) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 4).toNat) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 5).toNat) then (if s.montprod_ready then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else false) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 6).toNat) then (if decide (boolToNat (s.montprod_ready) = boolToNat (true)) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else false) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 7).toNat) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 8).toNat) then (if s.montprod_ready then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else false) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 9).toNat) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else false))))))))))
  { s with
    modexp_ctrl_we := modexp_ctrl_we
  }

/-- 组合逻辑：proc_alwayscomb_29__assignment_4 -/
def proc_alwayscomb_29__assignment_4 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_calc := (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 0).toNat) then (if i.start then (if s.residue_valid_reg then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 1).toNat) then (if s.residue_ready then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 2).toNat) then (if s.montprod_ready then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 3).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 4).toNat) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 5).toNat) then (if s.montprod_ready then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 6).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 7).toNat) then (if !(s.last_iteration) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else BitVec.getLsbD (BitVec.ofNat 32 1) 0) else BitVec.getLsbD (BitVec.ofNat 32 0) 0))))))))
  { s with
    montprod_calc := montprod_calc
  }

/-- 组合逻辑：proc_alwayscomb_29__assignment_5 -/
def proc_alwayscomb_29__assignment_5 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_dest_new := (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 0).toNat) then (if i.start then (if s.residue_valid_reg then BitVec.ofNat 2 0 else BitVec.ofNat 2 2) else BitVec.ofNat 2 2) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 1).toNat) then (if s.residue_ready then BitVec.ofNat 2 0 else BitVec.ofNat 2 2) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 2).toNat) then (if s.montprod_ready then BitVec.ofNat 2 1 else BitVec.ofNat 2 2) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 3).toNat) then BitVec.ofNat 2 2 else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 4).toNat) then (if (decide (boolToNat (s.ei_new) = boolToNat (false)) && decide (boolToNat (s.exponation_mode_reg) = boolToNat (true))) then BitVec.ofNat 2 1 else BitVec.ofNat 2 0) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 5).toNat) then (if s.montprod_ready then BitVec.ofNat 2 1 else BitVec.ofNat 2 2) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 6).toNat) then BitVec.ofNat 2 2 else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 7).toNat) then (if !(s.last_iteration) then BitVec.ofNat 2 2 else BitVec.ofNat 2 0) else BitVec.ofNat 2 2))))))))
  { s with
    montprod_dest_new := montprod_dest_new
  }

/-- 组合逻辑：proc_alwayscomb_29__assignment_6 -/
def proc_alwayscomb_29__assignment_6 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_dest_we := (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 0).toNat) then (if i.start then (if s.residue_valid_reg then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 1).toNat) then (if s.residue_ready then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 2).toNat) then (if s.montprod_ready then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 3).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 4).toNat) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 5).toNat) then (if s.montprod_ready then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 6).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 7).toNat) then (if !(s.last_iteration) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else BitVec.getLsbD (BitVec.ofNat 32 1) 0) else BitVec.getLsbD (BitVec.ofNat 32 0) 0))))))))
  { s with
    montprod_dest_we := montprod_dest_we
  }

/-- 组合逻辑：proc_alwayscomb_29__assignment_7 -/
def proc_alwayscomb_29__assignment_7 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_select_new := (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 0).toNat) then BitVec.ofNat 3 0 else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 1).toNat) then BitVec.ofNat 3 0 else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 2).toNat) then (if s.montprod_ready then BitVec.ofNat 3 1 else BitVec.ofNat 3 0) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 3).toNat) then BitVec.ofNat 3 0 else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 4).toNat) then (if (decide (boolToNat (s.ei_new) = boolToNat (false)) && decide (boolToNat (s.exponation_mode_reg) = boolToNat (true))) then BitVec.ofNat 3 3 else BitVec.ofNat 3 2) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 5).toNat) then (if s.montprod_ready then BitVec.ofNat 3 3 else BitVec.ofNat 3 0) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 6).toNat) then BitVec.ofNat 3 0 else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 7).toNat) then (if !(s.last_iteration) then BitVec.ofNat 3 0 else BitVec.ofNat 3 4) else BitVec.ofNat 3 0))))))))
  { s with
    montprod_select_new := montprod_select_new
  }

/-- 组合逻辑：proc_alwayscomb_29__assignment_8 -/
def proc_alwayscomb_29__assignment_8 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let montprod_select_we := (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 0).toNat) then (if i.start then (if s.residue_valid_reg then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 1).toNat) then (if s.residue_ready then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 2).toNat) then (if s.montprod_ready then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 3).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 4).toNat) then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 5).toNat) then (if s.montprod_ready then BitVec.getLsbD (BitVec.ofNat 32 1) 0 else BitVec.getLsbD (BitVec.ofNat 32 0) 0) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 6).toNat) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 7).toNat) then (if !(s.last_iteration) then BitVec.getLsbD (BitVec.ofNat 32 0) 0 else BitVec.getLsbD (BitVec.ofNat 32 1) 0) else BitVec.getLsbD (BitVec.ofNat 32 0) 0))))))))
  { s with
    montprod_select_we := montprod_select_we
  }

/-- 组合逻辑：proc_alwayscomb_29__assignment_9 -/
def proc_alwayscomb_29__assignment_9 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let ready_new := (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 0).toNat) then false else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 1).toNat) then false else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 2).toNat) then false else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 3).toNat) then false else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 4).toNat) then false else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 5).toNat) then false else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 6).toNat) then false else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 7).toNat) then false else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 8).toNat) then false else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 9).toNat) then true else false))))))))))
  { s with
    ready_new := ready_new
  }

/-- 组合逻辑：proc_alwayscomb_29__assignment_10 -/
def proc_alwayscomb_29__assignment_10 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let ready_we := (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 0).toNat) then (if i.start then true else false) else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 1).toNat) then false else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 2).toNat) then false else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 3).toNat) then false else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 4).toNat) then false else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 5).toNat) then false else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 6).toNat) then false else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 7).toNat) then false else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 8).toNat) then false else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 9).toNat) then true else false))))))))))
  { s with
    ready_we := ready_we
  }

/-- 组合逻辑：proc_alwayscomb_29__assignment_11 -/
def proc_alwayscomb_29__assignment_11 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_calculate := (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 0).toNat) then (if i.start then (if s.residue_valid_reg then false else true) else false) else false)
  { s with
    residue_calculate := residue_calculate
  }

/-- 组合逻辑：proc_alwayscomb_29__assignment_12 -/
def proc_alwayscomb_29__assignment_12 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let residue_valid_int_validated := (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 0).toNat) then false else (if decide ((s.modexp_ctrl_reg).toNat = (BitVec.ofNat 4 1).toNat) then (if s.residue_ready then true else false) else false))
  { s with
    residue_valid_int_validated := residue_valid_int_validated
  }

private def _rtl_comb_block_0 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let result :=
    assign_ready s i
    |> (fun s' => assign_cycles s' i)
    |> (fun s' => assign_length_m1 s' i)
    |> (fun s' => assign_montprod_inst__clk s' i)
    |> (fun s' => assign_montprod_inst__reset_n s' i)
    |> (fun s' => assign_montprod_inst__ready s' i)
    |> (fun s' => assign_montprod_inst__s_mem__wr s' i)
    |> (fun s' => assign_montprod_inst__s_mem__write_addr s' i)
    |> (fun s' => assign_montprod_inst__s_mem__read_data s' i)
    |> (fun s' => assign_montprod_inst__s_adder_sa__carry_in s' i)
    |> (fun s' => assign_montprod_inst__s_adder_sm__carry_in s' i)
    |> (fun s' => assign_montprod_inst__shifter__carry_in s' i)
    |> (fun s' => assign_residue_inst__clk s' i)
    |> (fun s' => assign_residue_inst__reset_n s' i)
    |> (fun s' => assign_residue_inst__ready s' i)
    |> (fun s' => assign_residue_inst__subcmp__carry_in s' i)
    |> (fun s' => assign_residue_inst__shl__carry_in s' i)
    |> (fun s' => assign_residue_mem__clk s' i)
    |> (fun s' => assign_residue_mem__read_data0 s' i)
    |> (fun s' => assign_residue_mem__read_data1 s' i)
    |> (fun s' => assign_p_mem__clk s' i)
    |> (fun s' => assign_p_mem__read_data0 s' i)
    |> (fun s' => assign_p_mem__read_data1 s' i)
    |> (fun s' => assign_exponent_mem__clk s' i)
    |> (fun s' => assign_exponent_mem__reset_n s' i)
    |> (fun s' => assign_exponent_mem__rst s' i)
    |> (fun s' => assign_exponent_mem__cs s' i)
    |> (fun s' => assign_exponent_mem__wr s' i)
    |> (fun s' => assign_exponent_mem__write_data s' i)
    |> (fun s' => assign_exponent_mem__read_data0 s' i)
    |> (fun s' => assign_exponent_mem__read_data1 s' i)
    |> (fun s' => assign_modulus_mem__clk s' i)

  result

private def _rtl_comb_block_1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let result :=
    assign_modulus_mem__reset_n s i
    |> (fun s' => assign_modulus_mem__rst s' i)
    |> (fun s' => assign_modulus_mem__cs s' i)
    |> (fun s' => assign_modulus_mem__wr s' i)
    |> (fun s' => assign_modulus_mem__write_data s' i)
    |> (fun s' => assign_modulus_mem__read_data0 s' i)
    |> (fun s' => assign_modulus_mem__read_data1 s' i)
    |> (fun s' => assign_message_mem__clk s' i)
    |> (fun s' => assign_message_mem__reset_n s' i)
    |> (fun s' => assign_message_mem__rst s' i)
    |> (fun s' => assign_message_mem__cs s' i)
    |> (fun s' => assign_message_mem__wr s' i)
    |> (fun s' => assign_message_mem__write_data s' i)
    |> (fun s' => assign_message_mem__read_data0 s' i)
    |> (fun s' => assign_message_mem__read_data1 s' i)
    |> (fun s' => assign_result_mem__clk s' i)
    |> (fun s' => assign_result_mem__reset_n s' i)
    |> (fun s' => assign_result_mem__rst s' i)
    |> (fun s' => assign_result_mem__cs s' i)
    |> (fun s' => assign_result_mem__read_data0 s' i)
    |> (fun s' => assign_result_mem__read_data1 s' i)
    |> (fun s' => proc_alwayscomb_4__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_4__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_4__assignment_3 s' i)
    |> (fun s' => proc_alwayscomb_5__assignment_2 s' i)
    |> (fun s' => proc_alwayscomb_5__assignment_3 s' i)
    |> (fun s' => proc_alwayscomb_5__assignment_6 s' i)
    |> (fun s' => proc_alwayscomb_6__assignment_2 s' i)
    |> (fun s' => proc_alwayscomb_6__assignment_3 s' i)
    |> (fun s' => proc_alwayscomb_7__assignment_3 s' i)
    |> (fun s' => proc_alwayscomb_7__assignment_5 s' i)
    |> (fun s' => proc_alwayscomb_10__assignment_1 s' i)

  result

private def _rtl_comb_block_2 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let result :=
    proc_alwayscomb_11__assignment_0 s i
    |> (fun s' => proc_alwayscomb_11__assignment_2 s' i)
    |> (fun s' => proc_alwayscomb_14 s' i)
    |> (fun s' => proc_alwayscomb_15__assignment_3 s' i)
    |> (fun s' => proc_alwayscomb_15__assignment_5 s' i)
    |> (fun s' => proc_alwayscomb_20__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_20__assignment_2 s' i)
    |> (fun s' => proc_alwayscomb_23__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_23__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_25__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_27__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_27__assignment_2 s' i)
    |> (fun s' => proc_alwayscomb_28__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_28__assignment_3 s' i)
    |> (fun s' => proc_alwayscomb_29__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_29__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_29__assignment_9 s' i)
    |> (fun s' => proc_alwayscomb_29__assignment_10 s' i)
    |> (fun s' => proc_alwayscomb_29__assignment_11 s' i)
    |> (fun s' => assign_montprod_ready s' i)
    |> (fun s' => assign_montprod_inst__length s' i)
    |> (fun s' => assign_montprod_inst__opm_addr s' i)
    |> (fun s' => assign_montprod_inst__result_addr s' i)
    |> (fun s' => assign_montprod_inst__result_we s' i)
    |> (fun s' => assign_montprod_inst__s_mem__clk s' i)
    |> (fun s' => assign_montprod_inst__s_mem_read_data s' i)
    |> (fun s' => assign_residue_inst__calculate s' i)
    |> (fun s' => assign_residue_ready s' i)
    |> (fun s' => assign_residue_inst__nn s' i)
    |> (fun s' => assign_residue_inst__length s' i)
    |> (fun s' => assign_residue_inst__opa_wr_addr s' i)
    |> (fun s' => assign_residue_inst__opa_wr_we s' i)

  result

private def _rtl_comb_block_3 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let result :=
    assign_residue_opa_rd_data s i
    |> (fun s' => assign_residue_mem_montprod_read_data s' i)
    |> (fun s' => assign_p_mem_rd0_data s' i)
    |> (fun s' => assign_p_mem_rd1_data s' i)
    |> (fun s' => assign_exponent_mem_int_rd_data s' i)
    |> (fun s' => assign_exponent_mem_api_read_data s' i)
    |> (fun s' => assign_modulus_mem_int_rd_data s' i)
    |> (fun s' => assign_modulus_mem_api_read_data s' i)
    |> (fun s' => assign_message_mem_int_rd_data s' i)
    |> (fun s' => assign_message_mem_api_read_data s' i)
    |> (fun s' => assign_result_mem_int_rd_data s' i)
    |> (fun s' => assign_result_mem_api_read_data s' i)
    |> (fun s' => proc_alwayscomb_5__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_9__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_9__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_16__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_16__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_17__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_17__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_18__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_18__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_19__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_19__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_20__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_20__assignment_3 s' i)
    |> (fun s' => proc_alwayscomb_20__assignment_4 s' i)
    |> (fun s' => proc_alwayscomb_20__assignment_5 s' i)
    |> (fun s' => proc_alwayscomb_27__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_28__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_28__assignment_4 s' i)
    |> (fun s' => assign_montprod_opm_addr s' i)
    |> (fun s' => assign_montprod_result_addr s' i)

  result

private def _rtl_comb_block_4 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let result :=
    assign_montprod_result_we s i
    |> (fun s' => assign_montprod_inst__opb_addr s' i)
    |> (fun s' => assign_montprod_inst__s_adder_sa__a s' i)
    |> (fun s' => assign_montprod_inst__s_adder_sm__a s' i)
    |> (fun s' => assign_montprod_inst__shifter__a s' i)
    |> (fun s' => assign_residue_inst__opa_rd_data s' i)
    |> (fun s' => assign_residue_opa_wr_addr s' i)
    |> (fun s' => assign_residue_opa_wr_we s' i)
    |> (fun s' => assign_exponent_mem__read_addr0 s' i)
    |> (fun s' => proc_alwayscomb_4__assignment_2 s' i)
    |> (fun s' => proc_alwayscomb_4__assignment_4 s' i)
    |> (fun s' => proc_alwayscomb_5__assignment_4 s' i)
    |> (fun s' => proc_alwayscomb_15__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_15__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_15__assignment_2 s' i)
    |> (fun s' => proc_alwayscomb_15__assignment_4 s' i)
    |> (fun s' => proc_alwayscomb_15__assignment_6 s' i)
    |> (fun s' => proc_alwayscomb_15__assignment_7 s' i)
    |> (fun s' => proc_alwayscomb_15__assignment_8 s' i)
    |> (fun s' => proc_alwayscomb_23__assignment_2 s' i)
    |> (fun s' => proc_alwayscomb_25__assignment_2 s' i)
    |> (fun s' => proc_alwayscomb_25__assignment_3 s' i)
    |> (fun s' => proc_alwayscomb_25__assignment_4 s' i)
    |> (fun s' => proc_alwayscomb_28__assignment_2 s' i)
    |> (fun s' => proc_alwayscomb_29__assignment_3 s' i)
    |> (fun s' => proc_alwayscomb_29__assignment_4 s' i)
    |> (fun s' => proc_alwayscomb_29__assignment_6 s' i)
    |> (fun s' => proc_alwayscomb_29__assignment_8 s' i)
    |> (fun s' => proc_alwayscomb_29__assignment_12 s' i)
    |> (fun s' => assign_montprod_inst__calculate s' i)
    |> (fun s' => assign_montprod_inst__opa_data s' i)
    |> (fun s' => assign_montprod_opb_addr s' i)

  result

private def _rtl_comb_block_5 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let result :=
    assign_montprod_inst__opb_data s i
    |> (fun s' => assign_montprod_inst__opm_data s' i)
    |> (fun s' => assign_montprod_inst__result_data s' i)
    |> (fun s' => assign_montprod_inst__shifter__adiv2 s' i)
    |> (fun s' => assign_montprod_inst__shifter__carry_out s' i)
    |> (fun s' => assign_residue_inst__opm_data s' i)
    |> (fun s' => assign_residue_inst__subcmp__a s' i)
    |> (fun s' => assign_residue_inst__shl__a s' i)
    |> (fun s' => assign_residue_mem__wr s' i)
    |> (fun s' => assign_residue_mem__write_addr s' i)
    |> (fun s' => proc_alwayscomb_5__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_5__assignment_5 s' i)
    |> (fun s' => proc_alwayscomb_10__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_24 s' i)
    |> (fun s' => proc_alwayscomb_26__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_26__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_26__assignment_3 s' i)
    |> (fun s' => proc_alwayscomb_26__assignment_4 s' i)
    |> (fun s' => proc_alwayscomb_29__assignment_2 s' i)
    |> (fun s' => proc_alwayscomb_29__assignment_5 s' i)
    |> (fun s' => proc_alwayscomb_29__assignment_7 s' i)
    |> (fun s' => assign_montprod_result_data s' i)
    |> (fun s' => assign_montprod_inst__opa_addr s' i)
    |> (fun s' => assign_montprod_inst__s_mem__read_addr s' i)
    |> (fun s' => assign_montprod_inst__s_adder_sa__b s' i)
    |> (fun s' => assign_montprod_inst__s_adder_sm__b s' i)
    |> (fun s' => assign_montprod_inst__shr_adiv2 s' i)
    |> (fun s' => assign_montprod_inst__shr_carry_out s' i)
    |> (fun s' => assign_residue_inst__subcmp__b s' i)
    |> (fun s' => assign_residue_inst__shl__amul2 s' i)
    |> (fun s' => assign_residue_inst__shl__carry_out s' i)
    |> (fun s' => assign_p_mem__wr s' i)

  result

private def _rtl_comb_block_6 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let result :=
    assign_p_mem__write_addr s i
    |> (fun s' => assign_result_mem__wr s' i)
    |> (fun s' => assign_result_mem__write_addr s' i)
    |> (fun s' => proc_alwayscomb_3__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_3__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_7__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_7__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_7__assignment_2 s' i)
    |> (fun s' => proc_alwayscomb_7__assignment_4 s' i)
    |> (fun s' => proc_alwayscomb_12__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_12__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_21__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_25__assignment_6 s' i)
    |> (fun s' => proc_alwayscomb_25__assignment_7 s' i)
    |> (fun s' => assign_montprod_opa_addr s' i)
    |> (fun s' => assign_residue_inst__opa_rd_addr s' i)
    |> (fun s' => assign_residue_inst__opm_addr s' i)
    |> (fun s' => assign_residue_inst__shl_data s' i)
    |> (fun s' => assign_residue_inst__shl_carry_out s' i)
    |> (fun s' => assign_residue_mem__read_addr1 s' i)
    |> (fun s' => assign_p_mem__read_addr1 s' i)
    |> (fun s' => proc_alwayscomb s' i)
    |> (fun s' => proc_alwayscomb_1 s' i)
    |> (fun s' => proc_alwayscomb_5__assignment_7 s' i)
    |> (fun s' => proc_alwayscomb_6__assignment_4 s' i)
    |> (fun s' => proc_alwayscomb_8 s' i)
    |> (fun s' => proc_alwayscomb_26__assignment_2 s' i)
    |> (fun s' => proc_alwayscomb_26__assignment_5 s' i)
    |> (fun s' => assign_montprod_inst__s_adder_sa__sum s' i)
    |> (fun s' => assign_montprod_inst__s_adder_sa__carry_out s' i)
    |> (fun s' => assign_montprod_inst__s_adder_sm__sum s' i)
    |> (fun s' => assign_montprod_inst__s_adder_sm__carry_out s' i)

  result

private def _rtl_comb_block_7 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let result :=
    assign_residue_opa_rd_addr s i
    |> (fun s' => assign_residue_opm_addr s' i)
    |> (fun s' => assign_residue_inst__subcmp__sum s' i)
    |> (fun s' => assign_residue_inst__subcmp__carry_out s' i)
    |> (fun s' => assign_p_mem__write_data s' i)
    |> (fun s' => assign_result_mem__write_data s' i)
    |> (fun s' => proc_alwayscomb_13__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_21__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_25__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_25__assignment_5 s' i)
    |> (fun s' => proc_alwayscomb_25__assignment_8 s' i)
    |> (fun s' => assign_montprod_inst__add_result_sa s' i)
    |> (fun s' => assign_montprod_inst__add_carry_out_sa s' i)
    |> (fun s' => assign_montprod_inst__add_result_sm s' i)
    |> (fun s' => assign_montprod_inst__add_carry_out_sm s' i)
    |> (fun s' => assign_residue_inst__sub_data s' i)
    |> (fun s' => assign_residue_inst__sub_carry_out s' i)
    |> (fun s' => assign_residue_mem__read_addr0 s' i)
    |> (fun s' => assign_p_mem__read_addr0 s' i)
    |> (fun s' => assign_message_mem__read_addr0 s' i)
    |> (fun s' => assign_result_mem__read_addr0 s' i)
    |> (fun s' => proc_alwayscomb_22 s' i)
    |> (fun s' => assign_modulus_mem__read_addr0 s' i)
    |> (fun s' => proc_alwayscomb_2 s' i)
    |> (fun s' => proc_alwayscomb_6__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_6__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_11__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_13__assignment_1 s' i)
    |> (fun s' => assign_montprod_inst__s_mem__write_data s' i)
    |> (fun s' => assign_residue_inst__opa_wr_data s' i)
    |> (fun s' => assign_residue_opa_wr_data s' i)
    |> (fun s' => assign_residue_mem__write_data s' i)

  result

/-- Combinational fixed-point schedule derived from IR dependencies -/
def comb (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let result :=
    _rtl_comb_block_0 s i
    |> (fun s' => _rtl_comb_block_1 s' i)
    |> (fun s' => _rtl_comb_block_2 s' i)
    |> (fun s' => _rtl_comb_block_3 s' i)
    |> (fun s' => _rtl_comb_block_4 s' i)
    |> (fun s' => _rtl_comb_block_5 s' i)
    |> (fun s' => _rtl_comb_block_6 s' i)
    |> (fun s' => _rtl_comb_block_7 s' i)

  result

/-- 时序逻辑: proc_alwaysff (clk=clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  { s with
    montprod_inst__s_mem__mem := (if s.montprod_inst__s_mem__wr then bvArrayWrite 32 256 0 255 (s.montprod_inst__s_mem__mem) ((s.montprod_inst__s_mem__write_addr).toNat) (s.montprod_inst__s_mem__write_data) else s.montprod_inst__s_mem__mem)
    montprod_inst__s_mem__tmp_read_data := bvArrayRead 32 256 0 255 (s.montprod_inst__s_mem__mem) ((s.montprod_inst__s_mem__read_addr).toNat)
  }

/-- 时序逻辑: proc_alwaysff_1 (clk=clk, rst=reset_n) — 复位由 step 顶层处理 -/
def proc_alwaysff_1 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  { s with
    montprod_inst__B_bit_index_reg := (if !(s.montprod_inst__reset_n) then BitVec.ofNat 5 0 else s.montprod_inst__B_bit_index)
    montprod_inst__add_carry_in_sa := (if !(s.montprod_inst__reset_n) then false else s.montprod_inst__add_carry_new_sa)
    montprod_inst__add_carry_in_sm := (if !(s.montprod_inst__reset_n) then false else s.montprod_inst__add_carry_new_sm)
    montprod_inst__b_reg := (if !(s.montprod_inst__reset_n) then false else s.montprod_inst__b)
    montprod_inst__loop_counter := (if !(s.montprod_inst__reset_n) then BitVec.ofNat 13 0 else s.montprod_inst__loop_counter_new)
    montprod_inst__montprod_ctrl_reg := (if !(s.montprod_inst__reset_n) then BitVec.ofNat 4 0 else (if s.montprod_inst__montprod_ctrl_we then s.montprod_inst__montprod_ctrl_new else s.montprod_inst__montprod_ctrl_reg))
    montprod_inst__q_reg := (if !(s.montprod_inst__reset_n) then false else s.montprod_inst__q)
    montprod_inst__ready_reg := (if !(s.montprod_inst__reset_n) then false else (if s.montprod_inst__ready_we then s.montprod_inst__ready_new else s.montprod_inst__ready_reg))
    montprod_inst__s_mem_we := (if !(s.montprod_inst__reset_n) then false else s.montprod_inst__s_mem_we_new)
    montprod_inst__s_mem_wr_addr := (if !(s.montprod_inst__reset_n) then BitVec.ofNat 8 0 else s.montprod_inst__s_mem_addr)
    montprod_inst__s_mux_reg := (if !(s.montprod_inst__reset_n) then BitVec.ofNat 2 0 else s.montprod_inst__s_mux_new)
    montprod_inst__shr_carry_in := (if !(s.montprod_inst__reset_n) then false else s.montprod_inst__shr_carry_new)
    montprod_inst__word_index := (if !(s.montprod_inst__reset_n) then BitVec.ofNat 8 0 else s.montprod_inst__word_index_new)
    montprod_inst__word_index_prev := (if !(s.montprod_inst__reset_n) then BitVec.ofNat 8 0 else s.montprod_inst__word_index)
  }

/-- 时序逻辑: proc_alwaysff_2 (clk=clk, rst=reset_n) — 复位由 step 顶层处理 -/
def proc_alwaysff_2 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  { s with
    residue_inst__length_m1_reg := (if !(s.residue_inst__reset_n) then BitVec.ofNat 8 0 else (if s.residue_inst__length_m1_we then s.residue_inst__length_m1_new else s.residue_inst__length_m1_reg))
    residue_inst__loop_counter_1_to_nn_reg := (if !(s.residue_inst__reset_n) then BitVec.ofNat 15 0 else (if s.residue_inst__loop_counter_1_to_nn_we then s.residue_inst__loop_counter_1_to_nn_new else s.residue_inst__loop_counter_1_to_nn_reg))
    residue_inst__nn_reg := (if !(s.residue_inst__reset_n) then BitVec.ofNat 15 0 else (if s.residue_inst__nn_we then s.residue_inst__nn else s.residue_inst__nn_reg))
    residue_inst__ready_reg := (if !(s.residue_inst__reset_n) then true else (if s.residue_inst__ready_we then s.residue_inst__ready_new else s.residue_inst__ready_reg))
    residue_inst__residue_ctrl_reg := (if !(s.residue_inst__reset_n) then BitVec.ofNat 4 0 else (if s.residue_inst__residue_ctrl_we then s.residue_inst__residue_ctrl_new else s.residue_inst__residue_ctrl_reg))
    residue_inst__shl_carry_in_reg := (if !(s.residue_inst__reset_n) then false else s.residue_inst__shl_carry_in_new)
    residue_inst__sub_carry_in_reg := (if !(s.residue_inst__reset_n) then false else s.residue_inst__sub_carry_in_new)
    residue_inst__word_index_reg := (if !(s.residue_inst__reset_n) then BitVec.ofNat 8 0 else (if s.residue_inst__word_index_we then s.residue_inst__word_index_new else s.residue_inst__word_index_reg))
  }

/-- 时序逻辑: proc_alwaysff_3 (clk=clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_3 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  { s with
    residue_mem__mem := (if s.residue_mem__wr then bvArrayWrite 32 256 0 255 (s.residue_mem__mem) ((s.residue_mem__write_addr).toNat) (s.residue_mem__write_data) else s.residue_mem__mem)
    residue_mem__tmp_read_data0 := bvArrayRead 32 256 0 255 (s.residue_mem__mem) ((s.residue_mem__read_addr0).toNat)
    residue_mem__tmp_read_data1 := bvArrayRead 32 256 0 255 (s.residue_mem__mem) ((s.residue_mem__read_addr1).toNat)
  }

/-- 时序逻辑: proc_alwaysff_4 (clk=clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_4 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  { s with
    p_mem__mem := (if s.p_mem__wr then bvArrayWrite 32 256 0 255 (s.p_mem__mem) ((s.p_mem__write_addr).toNat) (s.p_mem__write_data) else s.p_mem__mem)
    p_mem__tmp_read_data0 := bvArrayRead 32 256 0 255 (s.p_mem__mem) ((s.p_mem__read_addr0).toNat)
    p_mem__tmp_read_data1 := bvArrayRead 32 256 0 255 (s.p_mem__mem) ((s.p_mem__read_addr1).toNat)
  }

/-- 时序逻辑: proc_alwaysff_5 (clk=clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_5 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  { s with
    exponent_mem__mem := (if s.exponent_mem__wr then bvArrayWrite 32 256 0 255 (s.exponent_mem__mem) ((s.exponent_mem__ptr_reg).toNat) (s.exponent_mem__write_data) else s.exponent_mem__mem)
    exponent_mem__tmp_read_data0 := bvArrayRead 32 256 0 255 (s.exponent_mem__mem) ((s.exponent_mem__read_addr0).toNat)
    exponent_mem__tmp_read_data1 := bvArrayRead 32 256 0 255 (s.exponent_mem__mem) ((s.exponent_mem__ptr_reg).toNat)
  }

/-- 时序逻辑: proc_alwaysff_6 (clk=clk, rst=reset_n) — 复位由 step 顶层处理 -/
def proc_alwaysff_6 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  { s with
    exponent_mem__ptr_reg := (if !(s.exponent_mem__reset_n) then BitVec.ofNat 8 0 else (if s.exponent_mem__ptr_we then s.exponent_mem__ptr_new else s.exponent_mem__ptr_reg))
  }

/-- 时序逻辑: proc_alwaysff_7 (clk=clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_7 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  { s with
    modulus_mem__mem := (if s.modulus_mem__wr then bvArrayWrite 32 256 0 255 (s.modulus_mem__mem) ((s.modulus_mem__ptr_reg).toNat) (s.modulus_mem__write_data) else s.modulus_mem__mem)
    modulus_mem__tmp_read_data0 := bvArrayRead 32 256 0 255 (s.modulus_mem__mem) ((s.modulus_mem__read_addr0).toNat)
    modulus_mem__tmp_read_data1 := bvArrayRead 32 256 0 255 (s.modulus_mem__mem) ((s.modulus_mem__ptr_reg).toNat)
  }

/-- 时序逻辑: proc_alwaysff_8 (clk=clk, rst=reset_n) — 复位由 step 顶层处理 -/
def proc_alwaysff_8 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  { s with
    modulus_mem__ptr_reg := (if !(s.modulus_mem__reset_n) then BitVec.ofNat 8 0 else (if s.modulus_mem__ptr_we then s.modulus_mem__ptr_new else s.modulus_mem__ptr_reg))
  }

/-- 时序逻辑: proc_alwaysff_9 (clk=clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_9 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  { s with
    message_mem__mem := (if s.message_mem__wr then bvArrayWrite 32 256 0 255 (s.message_mem__mem) ((s.message_mem__ptr_reg).toNat) (s.message_mem__write_data) else s.message_mem__mem)
    message_mem__tmp_read_data0 := bvArrayRead 32 256 0 255 (s.message_mem__mem) ((s.message_mem__read_addr0).toNat)
    message_mem__tmp_read_data1 := bvArrayRead 32 256 0 255 (s.message_mem__mem) ((s.message_mem__ptr_reg).toNat)
  }

/-- 时序逻辑: proc_alwaysff_10 (clk=clk, rst=reset_n) — 复位由 step 顶层处理 -/
def proc_alwaysff_10 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  { s with
    message_mem__ptr_reg := (if !(s.message_mem__reset_n) then BitVec.ofNat 8 0 else (if s.message_mem__ptr_we then s.message_mem__ptr_new else s.message_mem__ptr_reg))
  }

/-- 时序逻辑: proc_alwaysff_11 (clk=clk, rst=rst) — 复位由 step 顶层处理 -/
def proc_alwaysff_11 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  { s with
    result_mem__mem := (if s.result_mem__wr then bvArrayWrite 32 256 0 255 (s.result_mem__mem) ((s.result_mem__write_addr).toNat) (s.result_mem__write_data) else s.result_mem__mem)
    result_mem__tmp_read_data0 := bvArrayRead 32 256 0 255 (s.result_mem__mem) ((s.result_mem__read_addr0).toNat)
    result_mem__tmp_read_data1 := bvArrayRead 32 256 0 255 (s.result_mem__mem) ((s.result_mem__ptr_reg).toNat)
  }

/-- 时序逻辑: proc_alwaysff_12 (clk=clk, rst=reset_n) — 复位由 step 顶层处理 -/
def proc_alwaysff_12 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  { s with
    result_mem__ptr_reg := (if !(s.result_mem__reset_n) then BitVec.ofNat 8 0 else (if s.result_mem__ptr_we then s.result_mem__ptr_new else s.result_mem__ptr_reg))
  }

/-- 时序逻辑: proc_alwaysff_13 (clk=clk, rst=reset_n) — 复位由 step 顶层处理 -/
def proc_alwaysff_13 (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  { s with
    b_one_reg := (if !(i.reset_n) then BitVec.ofNat 32 0 else s.b_one_new)
    cycle_ctr_high_reg := (if !(i.reset_n) then BitVec.ofNat 32 0 else (if s.cycle_ctr_high_we then s.cycle_ctr_high_new else s.cycle_ctr_high_reg))
    cycle_ctr_low_reg := (if !(i.reset_n) then BitVec.ofNat 32 0 else (if s.cycle_ctr_low_we then s.cycle_ctr_low_new else s.cycle_ctr_low_reg))
    cycle_ctr_state_reg := (if !(i.reset_n) then false else (if s.cycle_ctr_state_we then s.cycle_ctr_state_new else s.cycle_ctr_state_reg))
    ei_reg := (if !(i.reset_n) then false else (if s.ei_we then s.ei_new else s.ei_reg))
    exponation_mode_reg := (if !(i.reset_n) then false else (if i.exponation_mode_we then i.exponation_mode_new else s.exponation_mode_reg))
    loop_counter_reg := (if !(i.reset_n) then BitVec.ofNat 13 0 else (if s.loop_counter_we then s.loop_counter_new else s.loop_counter_reg))
    modexp_ctrl_reg := (if !(i.reset_n) then BitVec.ofNat 4 0 else (if s.modexp_ctrl_we then s.modexp_ctrl_new else s.modexp_ctrl_reg))
    montprod_dest_reg := (if !(i.reset_n) then BitVec.ofNat 2 2 else (if s.montprod_dest_we then s.montprod_dest_new else s.montprod_dest_reg))
    montprod_select_reg := (if !(i.reset_n) then BitVec.ofNat 3 0 else (if s.montprod_select_we then s.montprod_select_new else s.montprod_select_reg))
    one_reg := (if !(i.reset_n) then BitVec.ofNat 32 0 else s.one_new)
    ready_reg := (if !(i.reset_n) then true else (if s.ready_we then s.ready_new else s.ready_reg))
    residue_valid_reg := (if !(i.reset_n) then false else s.residue_valid_new)
  }

/-- Parallel nonblocking commit for the single clock domain -/
def commit (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
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
  let result := {
    b_one_reg := s14.b_one_reg
    cycle_ctr_high_reg := s14.cycle_ctr_high_reg
    cycle_ctr_low_reg := s14.cycle_ctr_low_reg
    cycle_ctr_state_reg := s14.cycle_ctr_state_reg
    ei_reg := s14.ei_reg
    exponation_mode_reg := s14.exponation_mode_reg
    exponent_mem__mem := s6.exponent_mem__mem
    exponent_mem__ptr_reg := s7.exponent_mem__ptr_reg
    exponent_mem__tmp_read_data0 := s6.exponent_mem__tmp_read_data0
    exponent_mem__tmp_read_data1 := s6.exponent_mem__tmp_read_data1
    loop_counter_reg := s14.loop_counter_reg
    message_mem__mem := s10.message_mem__mem
    message_mem__ptr_reg := s11.message_mem__ptr_reg
    message_mem__tmp_read_data0 := s10.message_mem__tmp_read_data0
    message_mem__tmp_read_data1 := s10.message_mem__tmp_read_data1
    modexp_ctrl_reg := s14.modexp_ctrl_reg
    modulus_mem__mem := s8.modulus_mem__mem
    modulus_mem__ptr_reg := s9.modulus_mem__ptr_reg
    modulus_mem__tmp_read_data0 := s8.modulus_mem__tmp_read_data0
    modulus_mem__tmp_read_data1 := s8.modulus_mem__tmp_read_data1
    montprod_dest_reg := s14.montprod_dest_reg
    montprod_inst__B_bit_index_reg := s2.montprod_inst__B_bit_index_reg
    montprod_inst__add_carry_in_sa := s2.montprod_inst__add_carry_in_sa
    montprod_inst__add_carry_in_sm := s2.montprod_inst__add_carry_in_sm
    montprod_inst__b_reg := s2.montprod_inst__b_reg
    montprod_inst__loop_counter := s2.montprod_inst__loop_counter
    montprod_inst__montprod_ctrl_reg := s2.montprod_inst__montprod_ctrl_reg
    montprod_inst__q_reg := s2.montprod_inst__q_reg
    montprod_inst__ready_reg := s2.montprod_inst__ready_reg
    montprod_inst__s_mem__mem := s1.montprod_inst__s_mem__mem
    montprod_inst__s_mem__tmp_read_data := s1.montprod_inst__s_mem__tmp_read_data
    montprod_inst__s_mem_we := s2.montprod_inst__s_mem_we
    montprod_inst__s_mem_wr_addr := s2.montprod_inst__s_mem_wr_addr
    montprod_inst__s_mux_reg := s2.montprod_inst__s_mux_reg
    montprod_inst__shr_carry_in := s2.montprod_inst__shr_carry_in
    montprod_inst__word_index := s2.montprod_inst__word_index
    montprod_inst__word_index_prev := s2.montprod_inst__word_index_prev
    montprod_select_reg := s14.montprod_select_reg
    one_reg := s14.one_reg
    p_mem__mem := s5.p_mem__mem
    p_mem__tmp_read_data0 := s5.p_mem__tmp_read_data0
    p_mem__tmp_read_data1 := s5.p_mem__tmp_read_data1
    ready_reg := s14.ready_reg
    residue_inst__length_m1_reg := s3.residue_inst__length_m1_reg
    residue_inst__loop_counter_1_to_nn_reg := s3.residue_inst__loop_counter_1_to_nn_reg
    residue_inst__nn_reg := s3.residue_inst__nn_reg
    residue_inst__ready_reg := s3.residue_inst__ready_reg
    residue_inst__residue_ctrl_reg := s3.residue_inst__residue_ctrl_reg
    residue_inst__shl_carry_in_reg := s3.residue_inst__shl_carry_in_reg
    residue_inst__sub_carry_in_reg := s3.residue_inst__sub_carry_in_reg
    residue_inst__word_index_reg := s3.residue_inst__word_index_reg
    residue_mem__mem := s4.residue_mem__mem
    residue_mem__tmp_read_data0 := s4.residue_mem__tmp_read_data0
    residue_mem__tmp_read_data1 := s4.residue_mem__tmp_read_data1
    residue_valid_reg := s14.residue_valid_reg
    result_mem__mem := s12.result_mem__mem
    result_mem__ptr_reg := s13.result_mem__ptr_reg
    result_mem__tmp_read_data0 := s12.result_mem__tmp_read_data0
    result_mem__tmp_read_data1 := s12.result_mem__tmp_read_data1
    modulus_mem_int_rd_data := s.modulus_mem_int_rd_data
    message_mem_int_rd_data := s.message_mem_int_rd_data
    exponent_mem_int_rd_data := s.exponent_mem_int_rd_data
    result_mem_int_rd_data := s.result_mem_int_rd_data
    p_mem_rd0_data := s.p_mem_rd0_data
    p_mem_rd1_data := s.p_mem_rd1_data
    montprod_ready := s.montprod_ready
    montprod_opa_addr := s.montprod_opa_addr
    montprod_opb_addr := s.montprod_opb_addr
    montprod_opm_addr := s.montprod_opm_addr
    montprod_result_addr := s.montprod_result_addr
    montprod_result_data := s.montprod_result_data
    montprod_result_we := s.montprod_result_we
    residue_ready := s.residue_ready
    residue_opa_rd_addr := s.residue_opa_rd_addr
    residue_opa_rd_data := s.residue_opa_rd_data
    residue_opa_wr_addr := s.residue_opa_wr_addr
    residue_opa_wr_data := s.residue_opa_wr_data
    residue_opa_wr_we := s.residue_opa_wr_we
    residue_opm_addr := s.residue_opm_addr
    residue_mem_montprod_read_data := s.residue_mem_montprod_read_data
    length_m1 := s.length_m1
    montprod_inst__clk := s.montprod_inst__clk
    montprod_inst__reset_n := s.montprod_inst__reset_n
    montprod_inst__calculate := s.montprod_inst__calculate
    montprod_inst__ready := s.montprod_inst__ready
    montprod_inst__length := s.montprod_inst__length
    montprod_inst__opa_addr := s.montprod_inst__opa_addr
    montprod_inst__opa_data := s.montprod_inst__opa_data
    montprod_inst__opb_addr := s.montprod_inst__opb_addr
    montprod_inst__opb_data := s.montprod_inst__opb_data
    montprod_inst__opm_addr := s.montprod_inst__opm_addr
    montprod_inst__opm_data := s.montprod_inst__opm_data
    montprod_inst__result_addr := s.montprod_inst__result_addr
    montprod_inst__result_data := s.montprod_inst__result_data
    montprod_inst__result_we := s.montprod_inst__result_we
    montprod_inst__s_mem_read_data := s.montprod_inst__s_mem_read_data
    montprod_inst__add_result_sa := s.montprod_inst__add_result_sa
    montprod_inst__add_carry_out_sa := s.montprod_inst__add_carry_out_sa
    montprod_inst__add_result_sm := s.montprod_inst__add_result_sm
    montprod_inst__add_carry_out_sm := s.montprod_inst__add_carry_out_sm
    montprod_inst__shr_carry_out := s.montprod_inst__shr_carry_out
    montprod_inst__shr_adiv2 := s.montprod_inst__shr_adiv2
    montprod_inst__s_mem__clk := s.montprod_inst__s_mem__clk
    montprod_inst__s_mem__read_addr := s.montprod_inst__s_mem__read_addr
    montprod_inst__s_mem__read_data := s.montprod_inst__s_mem__read_data
    montprod_inst__s_mem__wr := s.montprod_inst__s_mem__wr
    montprod_inst__s_mem__write_addr := s.montprod_inst__s_mem__write_addr
    montprod_inst__s_mem__write_data := s.montprod_inst__s_mem__write_data
    montprod_inst__s_adder_sa__a := s.montprod_inst__s_adder_sa__a
    montprod_inst__s_adder_sa__b := s.montprod_inst__s_adder_sa__b
    montprod_inst__s_adder_sa__carry_in := s.montprod_inst__s_adder_sa__carry_in
    montprod_inst__s_adder_sa__sum := s.montprod_inst__s_adder_sa__sum
    montprod_inst__s_adder_sa__carry_out := s.montprod_inst__s_adder_sa__carry_out
    montprod_inst__s_adder_sm__a := s.montprod_inst__s_adder_sm__a
    montprod_inst__s_adder_sm__b := s.montprod_inst__s_adder_sm__b
    montprod_inst__s_adder_sm__carry_in := s.montprod_inst__s_adder_sm__carry_in
    montprod_inst__s_adder_sm__sum := s.montprod_inst__s_adder_sm__sum
    montprod_inst__s_adder_sm__carry_out := s.montprod_inst__s_adder_sm__carry_out
    montprod_inst__shifter__a := s.montprod_inst__shifter__a
    montprod_inst__shifter__carry_in := s.montprod_inst__shifter__carry_in
    montprod_inst__shifter__adiv2 := s.montprod_inst__shifter__adiv2
    montprod_inst__shifter__carry_out := s.montprod_inst__shifter__carry_out
    residue_inst__clk := s.residue_inst__clk
    residue_inst__reset_n := s.residue_inst__reset_n
    residue_inst__calculate := s.residue_inst__calculate
    residue_inst__ready := s.residue_inst__ready
    residue_inst__nn := s.residue_inst__nn
    residue_inst__length := s.residue_inst__length
    residue_inst__opa_rd_addr := s.residue_inst__opa_rd_addr
    residue_inst__opa_rd_data := s.residue_inst__opa_rd_data
    residue_inst__opa_wr_addr := s.residue_inst__opa_wr_addr
    residue_inst__opa_wr_data := s.residue_inst__opa_wr_data
    residue_inst__opa_wr_we := s.residue_inst__opa_wr_we
    residue_inst__opm_addr := s.residue_inst__opm_addr
    residue_inst__opm_data := s.residue_inst__opm_data
    residue_inst__sub_data := s.residue_inst__sub_data
    residue_inst__shl_data := s.residue_inst__shl_data
    residue_inst__sub_carry_out := s.residue_inst__sub_carry_out
    residue_inst__shl_carry_out := s.residue_inst__shl_carry_out
    residue_inst__subcmp__a := s.residue_inst__subcmp__a
    residue_inst__subcmp__b := s.residue_inst__subcmp__b
    residue_inst__subcmp__carry_in := s.residue_inst__subcmp__carry_in
    residue_inst__subcmp__sum := s.residue_inst__subcmp__sum
    residue_inst__subcmp__carry_out := s.residue_inst__subcmp__carry_out
    residue_inst__shl__a := s.residue_inst__shl__a
    residue_inst__shl__carry_in := s.residue_inst__shl__carry_in
    residue_inst__shl__amul2 := s.residue_inst__shl__amul2
    residue_inst__shl__carry_out := s.residue_inst__shl__carry_out
    residue_mem__clk := s.residue_mem__clk
    residue_mem__read_addr0 := s.residue_mem__read_addr0
    residue_mem__read_data0 := s.residue_mem__read_data0
    residue_mem__read_addr1 := s.residue_mem__read_addr1
    residue_mem__read_data1 := s.residue_mem__read_data1
    residue_mem__wr := s.residue_mem__wr
    residue_mem__write_addr := s.residue_mem__write_addr
    residue_mem__write_data := s.residue_mem__write_data
    p_mem__clk := s.p_mem__clk
    p_mem__read_addr0 := s.p_mem__read_addr0
    p_mem__read_data0 := s.p_mem__read_data0
    p_mem__read_addr1 := s.p_mem__read_addr1
    p_mem__read_data1 := s.p_mem__read_data1
    p_mem__wr := s.p_mem__wr
    p_mem__write_addr := s.p_mem__write_addr
    p_mem__write_data := s.p_mem__write_data
    exponent_mem__clk := s.exponent_mem__clk
    exponent_mem__reset_n := s.exponent_mem__reset_n
    exponent_mem__read_addr0 := s.exponent_mem__read_addr0
    exponent_mem__read_data0 := s.exponent_mem__read_data0
    exponent_mem__read_data1 := s.exponent_mem__read_data1
    exponent_mem__rst := s.exponent_mem__rst
    exponent_mem__cs := s.exponent_mem__cs
    exponent_mem__wr := s.exponent_mem__wr
    exponent_mem__write_data := s.exponent_mem__write_data
    modulus_mem__clk := s.modulus_mem__clk
    modulus_mem__reset_n := s.modulus_mem__reset_n
    modulus_mem__read_addr0 := s.modulus_mem__read_addr0
    modulus_mem__read_data0 := s.modulus_mem__read_data0
    modulus_mem__read_data1 := s.modulus_mem__read_data1
    modulus_mem__rst := s.modulus_mem__rst
    modulus_mem__cs := s.modulus_mem__cs
    modulus_mem__wr := s.modulus_mem__wr
    modulus_mem__write_data := s.modulus_mem__write_data
    message_mem__clk := s.message_mem__clk
    message_mem__reset_n := s.message_mem__reset_n
    message_mem__read_addr0 := s.message_mem__read_addr0
    message_mem__read_data0 := s.message_mem__read_data0
    message_mem__read_data1 := s.message_mem__read_data1
    message_mem__rst := s.message_mem__rst
    message_mem__cs := s.message_mem__cs
    message_mem__wr := s.message_mem__wr
    message_mem__write_data := s.message_mem__write_data
    result_mem__clk := s.result_mem__clk
    result_mem__reset_n := s.result_mem__reset_n
    result_mem__read_addr0 := s.result_mem__read_addr0
    result_mem__read_data0 := s.result_mem__read_data0
    result_mem__read_data1 := s.result_mem__read_data1
    result_mem__rst := s.result_mem__rst
    result_mem__cs := s.result_mem__cs
    result_mem__wr := s.result_mem__wr
    result_mem__write_addr := s.result_mem__write_addr
    result_mem__write_data := s.result_mem__write_data
    ready := s.ready
    cycles := s.cycles
    exponent_mem_api_read_data := s.exponent_mem_api_read_data
    modulus_mem_api_read_data := s.modulus_mem_api_read_data
    message_mem_api_read_data := s.message_mem_api_read_data
    result_mem_api_read_data := s.result_mem_api_read_data
    E_bit_index := s.E_bit_index
    E_word_index := s.E_word_index
    b_one_new := s.b_one_new
    cycle_ctr_high_new := s.cycle_ctr_high_new
    cycle_ctr_high_we := s.cycle_ctr_high_we
    cycle_ctr_low_new := s.cycle_ctr_low_new
    cycle_ctr_low_we := s.cycle_ctr_low_we
    cycle_ctr_start := s.cycle_ctr_start
    cycle_ctr_state_new := s.cycle_ctr_state_new
    cycle_ctr_state_we := s.cycle_ctr_state_we
    cycle_ctr_stop := s.cycle_ctr_stop
    ei_new := s.ei_new
    ei_we := s.ei_we
    exponent_mem__ptr_new := s.exponent_mem__ptr_new
    exponent_mem__ptr_we := s.exponent_mem__ptr_we
    exponent_mem_int_rd_addr := s.exponent_mem_int_rd_addr
    last_iteration := s.last_iteration
    loop_counter_new := s.loop_counter_new
    loop_counter_we := s.loop_counter_we
    message_mem__ptr_new := s.message_mem__ptr_new
    message_mem__ptr_we := s.message_mem__ptr_we
    message_mem_int_rd_addr := s.message_mem_int_rd_addr
    modexp_ctrl_new := s.modexp_ctrl_new
    modexp_ctrl_we := s.modexp_ctrl_we
    modulus_mem__ptr_new := s.modulus_mem__ptr_new
    modulus_mem__ptr_we := s.modulus_mem__ptr_we
    modulus_mem_int_rd_addr := s.modulus_mem_int_rd_addr
    montprod_calc := s.montprod_calc
    montprod_dest_new := s.montprod_dest_new
    montprod_dest_we := s.montprod_dest_we
    montprod_inst__B_bit_index := s.montprod_inst__B_bit_index
    montprod_inst__B_word_index := s.montprod_inst__B_word_index
    montprod_inst__add_carry_new_sa := s.montprod_inst__add_carry_new_sa
    montprod_inst__add_carry_new_sm := s.montprod_inst__add_carry_new_sm
    montprod_inst__b := s.montprod_inst__b
    montprod_inst__length_m1 := s.montprod_inst__length_m1
    montprod_inst__loop_counter_dec := s.montprod_inst__loop_counter_dec
    montprod_inst__loop_counter_new := s.montprod_inst__loop_counter_new
    montprod_inst__montprod_ctrl_new := s.montprod_inst__montprod_ctrl_new
    montprod_inst__montprod_ctrl_we := s.montprod_inst__montprod_ctrl_we
    montprod_inst__opa_addr_reg := s.montprod_inst__opa_addr_reg
    montprod_inst__opb_addr_reg := s.montprod_inst__opb_addr_reg
    montprod_inst__opm_addr_reg := s.montprod_inst__opm_addr_reg
    montprod_inst__q := s.montprod_inst__q
    montprod_inst__ready_new := s.montprod_inst__ready_new
    montprod_inst__ready_we := s.montprod_inst__ready_we
    montprod_inst__reset_word_index_LSW := s.montprod_inst__reset_word_index_LSW
    montprod_inst__reset_word_index_MSW := s.montprod_inst__reset_word_index_MSW
    montprod_inst__result_addr_reg := s.montprod_inst__result_addr_reg
    montprod_inst__result_data_reg := s.montprod_inst__result_data_reg
    montprod_inst__s_adder_sa__adder_result := s.montprod_inst__s_adder_sa__adder_result
    montprod_inst__s_adder_sm__adder_result := s.montprod_inst__s_adder_sm__adder_result
    montprod_inst__s_mem_addr := s.montprod_inst__s_mem_addr
    montprod_inst__s_mem_new := s.montprod_inst__s_mem_new
    montprod_inst__s_mem_we_new := s.montprod_inst__s_mem_we_new
    montprod_inst__s_mux_new := s.montprod_inst__s_mux_new
    montprod_inst__shr_carry_new := s.montprod_inst__shr_carry_new
    montprod_inst__tmp_result_we := s.montprod_inst__tmp_result_we
    montprod_inst__word_index_new := s.montprod_inst__word_index_new
    montprod_length := s.montprod_length
    montprod_opa_data := s.montprod_opa_data
    montprod_opb_data := s.montprod_opb_data
    montprod_opm_data := s.montprod_opm_data
    montprod_select_new := s.montprod_select_new
    montprod_select_we := s.montprod_select_we
    one_new := s.one_new
    p_mem_rd0_addr := s.p_mem_rd0_addr
    p_mem_rd1_addr := s.p_mem_rd1_addr
    p_mem_we := s.p_mem_we
    p_mem_wr_addr := s.p_mem_wr_addr
    p_mem_wr_data := s.p_mem_wr_data
    ready_new := s.ready_new
    ready_we := s.ready_we
    residue_calculate := s.residue_calculate
    residue_inst__length_m1_new := s.residue_inst__length_m1_new
    residue_inst__length_m1_we := s.residue_inst__length_m1_we
    residue_inst__loop_counter_1_to_nn_new := s.residue_inst__loop_counter_1_to_nn_new
    residue_inst__loop_counter_1_to_nn_we := s.residue_inst__loop_counter_1_to_nn_we
    residue_inst__nn_we := s.residue_inst__nn_we
    residue_inst__one_data := s.residue_inst__one_data
    residue_inst__opa_rd_addr_reg := s.residue_inst__opa_rd_addr_reg
    residue_inst__opa_wr_addr_reg := s.residue_inst__opa_wr_addr_reg
    residue_inst__opa_wr_data_reg := s.residue_inst__opa_wr_data_reg
    residue_inst__opa_wr_we_reg := s.residue_inst__opa_wr_we_reg
    residue_inst__opm_addr_reg := s.residue_inst__opm_addr_reg
    residue_inst__ready_new := s.residue_inst__ready_new
    residue_inst__ready_we := s.residue_inst__ready_we
    residue_inst__reset_n_counter := s.residue_inst__reset_n_counter
    residue_inst__reset_word_index := s.residue_inst__reset_word_index
    residue_inst__residue_ctrl_new := s.residue_inst__residue_ctrl_new
    residue_inst__residue_ctrl_we := s.residue_inst__residue_ctrl_we
    residue_inst__shl_carry_in_new := s.residue_inst__shl_carry_in_new
    residue_inst__sub_carry_in_new := s.residue_inst__sub_carry_in_new
    residue_inst__subcmp__adder_result := s.residue_inst__subcmp__adder_result
    residue_inst__word_index_new := s.residue_inst__word_index_new
    residue_inst__word_index_we := s.residue_inst__word_index_we
    residue_length := s.residue_length
    residue_mem_montprod_read_addr := s.residue_mem_montprod_read_addr
    residue_nn := s.residue_nn
    residue_opm_data := s.residue_opm_data
    residue_valid_int_validated := s.residue_valid_int_validated
    residue_valid_new := s.residue_valid_new
    result_mem__ptr_new := s.result_mem__ptr_new
    result_mem__ptr_we := s.result_mem__ptr_we
    result_mem_int_rd_addr := s.result_mem_int_rd_addr
    result_mem_int_we := s.result_mem_int_we
    result_mem_int_wr_addr := s.result_mem_int_wr_addr
    result_mem_int_wr_data := s.result_mem_int_wr_data
  }
  result

/-- step: pre-comb → parallel next-state commit → post-comb settle -/
def step (s : modexp_coreState) (i : modexp_coreInputs) : modexp_coreState :=
  let s_pre := comb s i
  let s_next := commit s_pre i
  let s_settled := comb s_next i
  s_settled

/-- Output helper -/
def outputs (s : modexp_coreState) : modexp_coreOutputs :=
  {
    ready := s.ready
    cycles := s.cycles
    exponent_mem_api_read_data := s.exponent_mem_api_read_data
    modulus_mem_api_read_data := s.modulus_mem_api_read_data
    message_mem_api_read_data := s.message_mem_api_read_data
    result_mem_api_read_data := s.result_mem_api_read_data
  }


end modexp_core
