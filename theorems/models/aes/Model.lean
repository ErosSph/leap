/-
自动生成的 Lean 4 代码
源模块：aes_core
生成时间：Lean 4 RTL 编译器
-/

import Std
set_option linter.unusedVariables false
set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace aes_core

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

structure aes_coreStateBlock0 where
  aes_core_ctrl_reg : BitVec 2
  dec_block__block_w0_reg : BitVec 32
  dec_block__block_w1_reg : BitVec 32
  dec_block__block_w2_reg : BitVec 32
  dec_block__block_w3_reg : BitVec 32
  dec_block__dec_ctrl_reg : BitVec 2
  dec_block__ready_reg : Bool
  dec_block__round_ctr_reg : BitVec 4
  dec_block__sword_ctr_reg : BitVec 2
  enc_block__block_w0_reg : BitVec 32
  enc_block__block_w1_reg : BitVec 32
  enc_block__block_w2_reg : BitVec 32
  enc_block__block_w3_reg : BitVec 32
  enc_block__enc_ctrl_reg : BitVec 2
  enc_block__ready_reg : Bool
  enc_block__round_ctr_reg : BitVec 4
  enc_block__sword_ctr_reg : BitVec 2
  keymem__key_mem : BitVec 1920
  keymem__key_mem_ctrl_reg : BitVec 3
  keymem__prev_key0_reg : BitVec 128
  keymem__prev_key1_reg : BitVec 128
  keymem__rcon_reg : BitVec 8
  keymem__ready_reg : Bool
  keymem__round_ctr_reg : BitVec 4
  ready_reg : Bool
  result_valid_reg : Bool
  round_key : BitVec 128
  key_ready : Bool
  enc_round_nr : BitVec 4
  enc_new_block : BitVec 128
  enc_ready : Bool
  enc_sboxw : BitVec 32
  dec_round_nr : BitVec 4
  dec_new_block : BitVec 128
  dec_ready : Bool
  keymem_sboxw : BitVec 32
  new_sboxw : BitVec 32
  enc_block__clk : Bool
  enc_block__reset_n : Bool
  enc_block__next : Bool
  enc_block__keylen : Bool
  enc_block__round : BitVec 4
  enc_block__round_key : BitVec 128
  enc_block__sboxw : BitVec 32
  enc_block__new_sboxw : BitVec 32
  enc_block__block : BitVec 128
  enc_block__new_block : BitVec 128
  enc_block__ready : Bool
  dec_block__clk : Bool
  dec_block__reset_n : Bool
  dec_block__next : Bool
  dec_block__keylen : Bool
  dec_block__round : BitVec 4
  dec_block__round_key : BitVec 128
  dec_block__block : BitVec 128
  dec_block__new_block : BitVec 128
  dec_block__ready : Bool
  dec_block__new_sboxw : BitVec 32
  dec_block__inv_sbox_inst__sboxw : BitVec 32
  dec_block__inv_sbox_inst__new_sboxw : BitVec 32
  dec_block__inv_sbox_inst__inv_sbox : BitVec 2048
  keymem__clk : Bool
  keymem__reset_n : Bool
  keymem__key : BitVec 256

structure aes_coreStateBlock1 where
  keymem__keylen : Bool
  keymem__init : Bool
  keymem__round : BitVec 4
  keymem__round_key : BitVec 128
  keymem__ready : Bool
  keymem__sboxw : BitVec 32
  keymem__new_sboxw : BitVec 32
  sbox_inst__sboxw : BitVec 32
  sbox_inst__new_sboxw : BitVec 32
  sbox_inst__sbox : BitVec 2048
  ready : Bool
  result : BitVec 128
  result_valid : Bool
  aes_core_ctrl_new : BitVec 2
  aes_core_ctrl_we : Bool
  dec_block__block_new : BitVec 128
  dec_block__block_w0_we : Bool
  dec_block__block_w1_we : Bool
  dec_block__block_w2_we : Bool
  dec_block__block_w3_we : Bool
  dec_block__dec_ctrl_new : BitVec 2
  dec_block__dec_ctrl_we : Bool
  dec_block__ready_new : Bool
  dec_block__ready_we : Bool
  dec_block__round_ctr_dec : Bool
  dec_block__round_ctr_new : BitVec 4
  dec_block__round_ctr_set : Bool
  dec_block__round_ctr_we : Bool
  dec_block__sword_ctr_inc : Bool
  dec_block__sword_ctr_new : BitVec 2
  dec_block__sword_ctr_rst : Bool
  dec_block__sword_ctr_we : Bool
  dec_block__tmp_sboxw : BitVec 32
  dec_block__update_type : BitVec 3
  dec_next : Bool
  enc_block__block_new : BitVec 128
  enc_block__block_w0_we : Bool
  enc_block__block_w1_we : Bool
  enc_block__block_w2_we : Bool
  enc_block__block_w3_we : Bool
  enc_block__enc_ctrl_new : BitVec 2
  enc_block__enc_ctrl_we : Bool
  enc_block__muxed_sboxw : BitVec 32
  enc_block__ready_new : Bool
  enc_block__ready_we : Bool
  enc_block__round_ctr_inc : Bool
  enc_block__round_ctr_new : BitVec 4
  enc_block__round_ctr_rst : Bool
  enc_block__round_ctr_we : Bool
  enc_block__sword_ctr_inc : Bool
  enc_block__sword_ctr_new : BitVec 2
  enc_block__sword_ctr_rst : Bool
  enc_block__sword_ctr_we : Bool
  enc_block__update_type : BitVec 3
  enc_next : Bool
  init_state : Bool
  keymem__key_mem_ctrl_new : BitVec 3
  keymem__key_mem_ctrl_we : Bool
  keymem__key_mem_new : BitVec 128
  keymem__key_mem_we : Bool
  keymem__prev_key0_new : BitVec 128
  keymem__prev_key0_we : Bool
  keymem__prev_key1_new : BitVec 128
  keymem__prev_key1_we : Bool

structure aes_coreStateBlock2 where
  keymem__rcon_new : BitVec 8
  keymem__rcon_next : Bool
  keymem__rcon_set : Bool
  keymem__rcon_we : Bool
  keymem__ready_new : Bool
  keymem__ready_we : Bool
  keymem__round_ctr_inc : Bool
  keymem__round_ctr_new : BitVec 4
  keymem__round_ctr_rst : Bool
  keymem__round_ctr_we : Bool
  keymem__round_key_update : Bool
  keymem__tmp_round_key : BitVec 128
  keymem__tmp_sboxw : BitVec 32
  muxed_new_block : BitVec 128
  muxed_ready : Bool
  muxed_round_nr : BitVec 4
  muxed_sboxw : BitVec 32
  ready_new : Bool
  ready_we : Bool
  result_valid_new : Bool
  result_valid_we : Bool

/-- aes_core 状态结构（保留全部字段的嵌套具体记录） -/
structure aes_coreState extends aes_coreStateBlock0, aes_coreStateBlock1, aes_coreStateBlock2 where

/-- aes_core 输入信号 -/
structure aes_coreInputs where
  clk : Bool
  reset_n : Bool
  encdec : Bool
  init : Bool
  next : Bool
  key : BitVec 256
  keylen : Bool
  block : BitVec 128

/-- aes_core 输出信号 -/
structure aes_coreOutputs where
  ready : Bool
  result : BitVec 128
  result_valid : Bool

/-- aes_core 初始状态 -/
def init : aes_coreState where
  aes_core_ctrl_reg := BitVec.ofNat 2 0
  dec_block__block_w0_reg := BitVec.ofNat 32 0
  dec_block__block_w1_reg := BitVec.ofNat 32 0
  dec_block__block_w2_reg := BitVec.ofNat 32 0
  dec_block__block_w3_reg := BitVec.ofNat 32 0
  dec_block__dec_ctrl_reg := BitVec.ofNat 2 0
  dec_block__ready_reg := false
  dec_block__round_ctr_reg := BitVec.ofNat 4 0
  dec_block__sword_ctr_reg := BitVec.ofNat 2 0
  enc_block__block_w0_reg := BitVec.ofNat 32 0
  enc_block__block_w1_reg := BitVec.ofNat 32 0
  enc_block__block_w2_reg := BitVec.ofNat 32 0
  enc_block__block_w3_reg := BitVec.ofNat 32 0
  enc_block__enc_ctrl_reg := BitVec.ofNat 2 0
  enc_block__ready_reg := false
  enc_block__round_ctr_reg := BitVec.ofNat 4 0
  enc_block__sword_ctr_reg := BitVec.ofNat 2 0
  keymem__key_mem := BitVec.ofNat 1920 0
  keymem__key_mem_ctrl_reg := BitVec.ofNat 3 0
  keymem__prev_key0_reg := BitVec.ofNat 128 0
  keymem__prev_key1_reg := BitVec.ofNat 128 0
  keymem__rcon_reg := BitVec.ofNat 8 0
  keymem__ready_reg := false
  keymem__round_ctr_reg := BitVec.ofNat 4 0
  ready_reg := false
  result_valid_reg := false
  round_key := BitVec.ofNat 128 0
  key_ready := false
  enc_round_nr := BitVec.ofNat 4 0
  enc_new_block := BitVec.ofNat 128 0
  enc_ready := false
  enc_sboxw := BitVec.ofNat 32 0
  dec_round_nr := BitVec.ofNat 4 0
  dec_new_block := BitVec.ofNat 128 0
  dec_ready := false
  keymem_sboxw := BitVec.ofNat 32 0
  new_sboxw := BitVec.ofNat 32 0
  enc_block__clk := false
  enc_block__reset_n := false
  enc_block__next := false
  enc_block__keylen := false
  enc_block__round := BitVec.ofNat 4 0
  enc_block__round_key := BitVec.ofNat 128 0
  enc_block__sboxw := BitVec.ofNat 32 0
  enc_block__new_sboxw := BitVec.ofNat 32 0
  enc_block__block := BitVec.ofNat 128 0
  enc_block__new_block := BitVec.ofNat 128 0
  enc_block__ready := false
  dec_block__clk := false
  dec_block__reset_n := false
  dec_block__next := false
  dec_block__keylen := false
  dec_block__round := BitVec.ofNat 4 0
  dec_block__round_key := BitVec.ofNat 128 0
  dec_block__block := BitVec.ofNat 128 0
  dec_block__new_block := BitVec.ofNat 128 0
  dec_block__ready := false
  dec_block__new_sboxw := BitVec.ofNat 32 0
  dec_block__inv_sbox_inst__sboxw := BitVec.ofNat 32 0
  dec_block__inv_sbox_inst__new_sboxw := BitVec.ofNat 32 0
  dec_block__inv_sbox_inst__inv_sbox := BitVec.ofNat 2048 0
  keymem__clk := false
  keymem__reset_n := false
  keymem__key := BitVec.ofNat 256 0
  keymem__keylen := false
  keymem__init := false
  keymem__round := BitVec.ofNat 4 0
  keymem__round_key := BitVec.ofNat 128 0
  keymem__ready := false
  keymem__sboxw := BitVec.ofNat 32 0
  keymem__new_sboxw := BitVec.ofNat 32 0
  sbox_inst__sboxw := BitVec.ofNat 32 0
  sbox_inst__new_sboxw := BitVec.ofNat 32 0
  sbox_inst__sbox := BitVec.ofNat 2048 0
  ready := false
  result := BitVec.ofNat 128 0
  result_valid := false
  aes_core_ctrl_new := BitVec.ofNat 2 0
  aes_core_ctrl_we := false
  dec_block__block_new := BitVec.ofNat 128 0
  dec_block__block_w0_we := false
  dec_block__block_w1_we := false
  dec_block__block_w2_we := false
  dec_block__block_w3_we := false
  dec_block__dec_ctrl_new := BitVec.ofNat 2 0
  dec_block__dec_ctrl_we := false
  dec_block__ready_new := false
  dec_block__ready_we := false
  dec_block__round_ctr_dec := false
  dec_block__round_ctr_new := BitVec.ofNat 4 0
  dec_block__round_ctr_set := false
  dec_block__round_ctr_we := false
  dec_block__sword_ctr_inc := false
  dec_block__sword_ctr_new := BitVec.ofNat 2 0
  dec_block__sword_ctr_rst := false
  dec_block__sword_ctr_we := false
  dec_block__tmp_sboxw := BitVec.ofNat 32 0
  dec_block__update_type := BitVec.ofNat 3 0
  dec_next := false
  enc_block__block_new := BitVec.ofNat 128 0
  enc_block__block_w0_we := false
  enc_block__block_w1_we := false
  enc_block__block_w2_we := false
  enc_block__block_w3_we := false
  enc_block__enc_ctrl_new := BitVec.ofNat 2 0
  enc_block__enc_ctrl_we := false
  enc_block__muxed_sboxw := BitVec.ofNat 32 0
  enc_block__ready_new := false
  enc_block__ready_we := false
  enc_block__round_ctr_inc := false
  enc_block__round_ctr_new := BitVec.ofNat 4 0
  enc_block__round_ctr_rst := false
  enc_block__round_ctr_we := false
  enc_block__sword_ctr_inc := false
  enc_block__sword_ctr_new := BitVec.ofNat 2 0
  enc_block__sword_ctr_rst := false
  enc_block__sword_ctr_we := false
  enc_block__update_type := BitVec.ofNat 3 0
  enc_next := false
  init_state := false
  keymem__key_mem_ctrl_new := BitVec.ofNat 3 0
  keymem__key_mem_ctrl_we := false
  keymem__key_mem_new := BitVec.ofNat 128 0
  keymem__key_mem_we := false
  keymem__prev_key0_new := BitVec.ofNat 128 0
  keymem__prev_key0_we := false
  keymem__prev_key1_new := BitVec.ofNat 128 0
  keymem__prev_key1_we := false
  keymem__rcon_new := BitVec.ofNat 8 0
  keymem__rcon_next := false
  keymem__rcon_set := false
  keymem__rcon_we := false
  keymem__ready_new := false
  keymem__ready_we := false
  keymem__round_ctr_inc := false
  keymem__round_ctr_new := BitVec.ofNat 4 0
  keymem__round_ctr_rst := false
  keymem__round_ctr_we := false
  keymem__round_key_update := false
  keymem__tmp_round_key := BitVec.ofNat 128 0
  keymem__tmp_sboxw := BitVec.ofNat 32 0
  muxed_new_block := BitVec.ofNat 128 0
  muxed_ready := false
  muxed_round_nr := BitVec.ofNat 4 0
  muxed_sboxw := BitVec.ofNat 32 0
  ready_new := false
  ready_we := false
  result_valid_new := false
  result_valid_we := false

/-- aes_core 默认输入值 -/
def defaultInputs : aes_coreInputs where
  clk := false
  reset_n := true
  encdec := false
  init := false
  next := false
  key := BitVec.ofNat 256 0
  keylen := false
  block := BitVec.ofNat 128 0

/-- 组合逻辑：assign_enc_block__clk -/
def assign_enc_block__clk (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_block__clk := i.clk
  { s with
    enc_block__clk := enc_block__clk
  }

/-- 组合逻辑：assign_enc_block__reset_n -/
def assign_enc_block__reset_n (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_block__reset_n := i.reset_n
  { s with
    enc_block__reset_n := enc_block__reset_n
  }

/-- 组合逻辑：assign_enc_block__next -/
def assign_enc_block__next (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_block__next := s.enc_next
  { s with
    enc_block__next := enc_block__next
  }

/-- 组合逻辑：assign_enc_block__keylen -/
def assign_enc_block__keylen (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_block__keylen := i.keylen
  { s with
    enc_block__keylen := enc_block__keylen
  }

/-- 组合逻辑：assign_enc_round_nr -/
def assign_enc_round_nr (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_round_nr := s.enc_block__round
  { s with
    enc_round_nr := enc_round_nr
  }

/-- 组合逻辑：assign_enc_block__round_key -/
def assign_enc_block__round_key (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_block__round_key := s.round_key
  { s with
    enc_block__round_key := enc_block__round_key
  }

/-- 组合逻辑：assign_enc_sboxw -/
def assign_enc_sboxw (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_sboxw := s.enc_block__sboxw
  { s with
    enc_sboxw := enc_sboxw
  }

/-- 组合逻辑：assign_enc_block__new_sboxw -/
def assign_enc_block__new_sboxw (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_block__new_sboxw := s.new_sboxw
  { s with
    enc_block__new_sboxw := enc_block__new_sboxw
  }

/-- 组合逻辑：assign_enc_block__block -/
def assign_enc_block__block (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_block__block := i.block
  { s with
    enc_block__block := enc_block__block
  }

/-- 组合逻辑：assign_enc_new_block -/
def assign_enc_new_block (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_new_block := s.enc_block__new_block
  { s with
    enc_new_block := enc_new_block
  }

/-- 组合逻辑：assign_enc_ready -/
def assign_enc_ready (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_ready := s.enc_block__ready
  { s with
    enc_ready := enc_ready
  }

/-- 组合逻辑：assign_enc_block__round -/
def assign_enc_block__round (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_block__round := s.enc_block__round_ctr_reg
  { s with
    enc_block__round := enc_block__round
  }

/-- 组合逻辑：assign_enc_block__sboxw -/
def assign_enc_block__sboxw (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_block__sboxw := s.enc_block__muxed_sboxw
  { s with
    enc_block__sboxw := enc_block__sboxw
  }

/-- 组合逻辑：assign_enc_block__new_block -/
def assign_enc_block__new_block (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_block__new_block := BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (s.enc_block__block_w0_reg) (s.enc_block__block_w1_reg)) (BitVec.append (n := 32) (m := 32) (s.enc_block__block_w2_reg) (s.enc_block__block_w3_reg))
  { s with
    enc_block__new_block := enc_block__new_block
  }

/-- 组合逻辑：assign_enc_block__ready -/
def assign_enc_block__ready (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_block__ready := s.enc_block__ready_reg
  { s with
    enc_block__ready := enc_block__ready
  }

/-- 组合逻辑：assign_dec_block__clk -/
def assign_dec_block__clk (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_block__clk := i.clk
  { s with
    dec_block__clk := dec_block__clk
  }

/-- 组合逻辑：assign_dec_block__reset_n -/
def assign_dec_block__reset_n (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_block__reset_n := i.reset_n
  { s with
    dec_block__reset_n := dec_block__reset_n
  }

/-- 组合逻辑：assign_dec_block__next -/
def assign_dec_block__next (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_block__next := s.dec_next
  { s with
    dec_block__next := dec_block__next
  }

/-- 组合逻辑：assign_dec_block__keylen -/
def assign_dec_block__keylen (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_block__keylen := i.keylen
  { s with
    dec_block__keylen := dec_block__keylen
  }

/-- 组合逻辑：assign_dec_round_nr -/
def assign_dec_round_nr (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_round_nr := s.dec_block__round
  { s with
    dec_round_nr := dec_round_nr
  }

/-- 组合逻辑：assign_dec_block__round_key -/
def assign_dec_block__round_key (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_block__round_key := s.round_key
  { s with
    dec_block__round_key := dec_block__round_key
  }

/-- 组合逻辑：assign_dec_block__block -/
def assign_dec_block__block (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_block__block := i.block
  { s with
    dec_block__block := dec_block__block
  }

/-- 组合逻辑：assign_dec_new_block -/
def assign_dec_new_block (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_new_block := s.dec_block__new_block
  { s with
    dec_new_block := dec_new_block
  }

/-- 组合逻辑：assign_dec_ready -/
def assign_dec_ready (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_ready := s.dec_block__ready
  { s with
    dec_ready := dec_ready
  }

/-- 组合逻辑：assign_dec_block__inv_sbox_inst__sboxw -/
def assign_dec_block__inv_sbox_inst__sboxw (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_block__inv_sbox_inst__sboxw := s.dec_block__tmp_sboxw
  { s with
    dec_block__inv_sbox_inst__sboxw := dec_block__inv_sbox_inst__sboxw
  }

/-- 组合逻辑：assign_dec_block__new_sboxw -/
def assign_dec_block__new_sboxw (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_block__new_sboxw := s.dec_block__inv_sbox_inst__new_sboxw
  { s with
    dec_block__new_sboxw := dec_block__new_sboxw
  }

/-- 组合逻辑：assign_dec_block__inv_sbox_inst__new_sboxw -/
def assign_dec_block__inv_sbox_inst__new_sboxw (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_block__inv_sbox_inst__new_sboxw := BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (bvArrayRead 8 256 0 255 (s.dec_block__inv_sbox_inst__inv_sbox) ((BitVec.extractLsb 31 24 (s.dec_block__inv_sbox_inst__sboxw)).toNat)) (bvArrayRead 8 256 0 255 (s.dec_block__inv_sbox_inst__inv_sbox) ((BitVec.extractLsb 23 16 (s.dec_block__inv_sbox_inst__sboxw)).toNat))) (BitVec.append (n := 8) (m := 8) (bvArrayRead 8 256 0 255 (s.dec_block__inv_sbox_inst__inv_sbox) ((BitVec.extractLsb 15 8 (s.dec_block__inv_sbox_inst__sboxw)).toNat)) (bvArrayRead 8 256 0 255 (s.dec_block__inv_sbox_inst__inv_sbox) ((BitVec.extractLsb 7 0 (s.dec_block__inv_sbox_inst__sboxw)).toNat)))
  { s with
    dec_block__inv_sbox_inst__new_sboxw := dec_block__inv_sbox_inst__new_sboxw
  }

/-- 组合逻辑：assign_dec_block__inv_sbox_inst__inv_sbox -/
def assign_dec_block__inv_sbox_inst__inv_sbox (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_block__inv_sbox_inst__inv_sbox := BitVec.append (n := 1024) (m := 1024) (BitVec.append (n := 512) (m := 512) (BitVec.append (n := 256) (m := 256) (BitVec.append (n := 128) (m := 128) (BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 125) (BitVec.ofNat 8 12)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 33) (BitVec.ofNat 8 85))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 99) (BitVec.ofNat 8 20)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 105) (BitVec.ofNat 8 225)))) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 38) (BitVec.ofNat 8 214)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 119) (BitVec.ofNat 8 186))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 126) (BitVec.ofNat 8 4)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 43) (BitVec.ofNat 8 23))))) (BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 97) (BitVec.ofNat 8 153)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 83) (BitVec.ofNat 8 131))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 60) (BitVec.ofNat 8 187)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 235) (BitVec.ofNat 8 200)))) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 176) (BitVec.ofNat 8 245)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 42) (BitVec.ofNat 8 174))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 77) (BitVec.ofNat 8 59)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 224) (BitVec.ofNat 8 160)))))) (BitVec.append (n := 128) (m := 128) (BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 239) (BitVec.ofNat 8 156)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 201) (BitVec.ofNat 8 147))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 159) (BitVec.ofNat 8 122)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 229) (BitVec.ofNat 8 45)))) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 13) (BitVec.ofNat 8 74)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 181) (BitVec.ofNat 8 25))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 169) (BitVec.ofNat 8 127)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 81) (BitVec.ofNat 8 96))))) (BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 95) (BitVec.ofNat 8 236)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 128) (BitVec.ofNat 8 39))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 89) (BitVec.ofNat 8 16)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 18) (BitVec.ofNat 8 177)))) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 49) (BitVec.ofNat 8 199)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 7) (BitVec.ofNat 8 136))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 51) (BitVec.ofNat 8 168)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 221) (BitVec.ofNat 8 31))))))) (BitVec.append (n := 256) (m := 256) (BitVec.append (n := 128) (m := 128) (BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 244) (BitVec.ofNat 8 90)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 205) (BitVec.ofNat 8 120))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 254) (BitVec.ofNat 8 192)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 219) (BitVec.ofNat 8 154)))) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 32) (BitVec.ofNat 8 121)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 210) (BitVec.ofNat 8 198))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 75) (BitVec.ofNat 8 62)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 86) (BitVec.ofNat 8 252))))) (BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 27) (BitVec.ofNat 8 190)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 24) (BitVec.ofNat 8 170))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 14) (BitVec.ofNat 8 98)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 183) (BitVec.ofNat 8 111)))) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 137) (BitVec.ofNat 8 197)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 41) (BitVec.ofNat 8 29))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 113) (BitVec.ofNat 8 26)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 241) (BitVec.ofNat 8 71)))))) (BitVec.append (n := 128) (m := 128) (BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 110) (BitVec.ofNat 8 223)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 117) (BitVec.ofNat 8 28))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 232) (BitVec.ofNat 8 55)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 249) (BitVec.ofNat 8 226)))) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 133) (BitVec.ofNat 8 53)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 173) (BitVec.ofNat 8 231))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 34) (BitVec.ofNat 8 116)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 172) (BitVec.ofNat 8 150))))) (BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 115) (BitVec.ofNat 8 230)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 180) (BitVec.ofNat 8 240))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 206) (BitVec.ofNat 8 207)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 242) (BitVec.ofNat 8 151)))) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 234) (BitVec.ofNat 8 220)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 103) (BitVec.ofNat 8 79))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 65) (BitVec.ofNat 8 17)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 145) (BitVec.ofNat 8 58)))))))) (BitVec.append (n := 512) (m := 512) (BitVec.append (n := 256) (m := 256) (BitVec.append (n := 128) (m := 128) (BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 107) (BitVec.ofNat 8 138)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 19) (BitVec.ofNat 8 1))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 3) (BitVec.ofNat 8 189)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 175) (BitVec.ofNat 8 193)))) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 2) (BitVec.ofNat 8 15)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 63) (BitVec.ofNat 8 202))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 143) (BitVec.ofNat 8 30)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 44) (BitVec.ofNat 8 208))))) (BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 6) (BitVec.ofNat 8 69)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 179) (BitVec.ofNat 8 184))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 5) (BitVec.ofNat 8 88)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 228) (BitVec.ofNat 8 247)))) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 10) (BitVec.ofNat 8 211)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 188) (BitVec.ofNat 8 140))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 0) (BitVec.ofNat 8 171)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 216) (BitVec.ofNat 8 144)))))) (BitVec.append (n := 128) (m := 128) (BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 132) (BitVec.ofNat 8 157)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 141) (BitVec.ofNat 8 167))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 87) (BitVec.ofNat 8 70)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 21) (BitVec.ofNat 8 94)))) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 218) (BitVec.ofNat 8 185)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 237) (BitVec.ofNat 8 253))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 80) (BitVec.ofNat 8 72)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 112) (BitVec.ofNat 8 108))))) (BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 146) (BitVec.ofNat 8 182)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 101) (BitVec.ofNat 8 93))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 204) (BitVec.ofNat 8 92)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 164) (BitVec.ofNat 8 212)))) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 22) (BitVec.ofNat 8 152)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 104) (BitVec.ofNat 8 134))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 100) (BitVec.ofNat 8 246)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 248) (BitVec.ofNat 8 114))))))) (BitVec.append (n := 256) (m := 256) (BitVec.append (n := 128) (m := 128) (BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 37) (BitVec.ofNat 8 209)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 139) (BitVec.ofNat 8 109))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 73) (BitVec.ofNat 8 162)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 91) (BitVec.ofNat 8 118)))) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 178) (BitVec.ofNat 8 36)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 217) (BitVec.ofNat 8 40))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 102) (BitVec.ofNat 8 161)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 46) (BitVec.ofNat 8 8))))) (BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 78) (BitVec.ofNat 8 195)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 250) (BitVec.ofNat 8 66))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 11) (BitVec.ofNat 8 149)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 76) (BitVec.ofNat 8 238)))) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 61) (BitVec.ofNat 8 35)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 194) (BitVec.ofNat 8 166))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 50) (BitVec.ofNat 8 148)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 123) (BitVec.ofNat 8 84)))))) (BitVec.append (n := 128) (m := 128) (BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 203) (BitVec.ofNat 8 233)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 222) (BitVec.ofNat 8 196))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 68) (BitVec.ofNat 8 67)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 142) (BitVec.ofNat 8 52)))) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 135) (BitVec.ofNat 8 255)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 47) (BitVec.ofNat 8 155))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 130) (BitVec.ofNat 8 57)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 227) (BitVec.ofNat 8 124))))) (BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 251) (BitVec.ofNat 8 215)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 243) (BitVec.ofNat 8 129))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 158) (BitVec.ofNat 8 163)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 64) (BitVec.ofNat 8 191)))) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 56) (BitVec.ofNat 8 165)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 54) (BitVec.ofNat 8 48))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 213) (BitVec.ofNat 8 106)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 9) (BitVec.ofNat 8 82))))))))
  { s with
    dec_block__inv_sbox_inst__inv_sbox := dec_block__inv_sbox_inst__inv_sbox
  }

/-- 组合逻辑：assign_dec_block__round -/
def assign_dec_block__round (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_block__round := s.dec_block__round_ctr_reg
  { s with
    dec_block__round := dec_block__round
  }

/-- 组合逻辑：assign_dec_block__new_block -/
def assign_dec_block__new_block (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_block__new_block := BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (s.dec_block__block_w0_reg) (s.dec_block__block_w1_reg)) (BitVec.append (n := 32) (m := 32) (s.dec_block__block_w2_reg) (s.dec_block__block_w3_reg))
  { s with
    dec_block__new_block := dec_block__new_block
  }

/-- 组合逻辑：assign_dec_block__ready -/
def assign_dec_block__ready (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_block__ready := s.dec_block__ready_reg
  { s with
    dec_block__ready := dec_block__ready
  }

/-- 组合逻辑：assign_keymem__clk -/
def assign_keymem__clk (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let keymem__clk := i.clk
  { s with
    keymem__clk := keymem__clk
  }

/-- 组合逻辑：assign_keymem__reset_n -/
def assign_keymem__reset_n (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let keymem__reset_n := i.reset_n
  { s with
    keymem__reset_n := keymem__reset_n
  }

/-- 组合逻辑：assign_keymem__key -/
def assign_keymem__key (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let keymem__key := i.key
  { s with
    keymem__key := keymem__key
  }

/-- 组合逻辑：assign_keymem__keylen -/
def assign_keymem__keylen (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let keymem__keylen := i.keylen
  { s with
    keymem__keylen := keymem__keylen
  }

/-- 组合逻辑：assign_keymem__init -/
def assign_keymem__init (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let keymem__init := i.init
  { s with
    keymem__init := keymem__init
  }

/-- 组合逻辑：assign_keymem__round -/
def assign_keymem__round (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let keymem__round := s.muxed_round_nr
  { s with
    keymem__round := keymem__round
  }

/-- 组合逻辑：assign_round_key -/
def assign_round_key (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let round_key := s.keymem__round_key
  { s with
    round_key := round_key
  }

/-- 组合逻辑：assign_key_ready -/
def assign_key_ready (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let key_ready := s.keymem__ready
  { s with
    key_ready := key_ready
  }

/-- 组合逻辑：assign_keymem_sboxw -/
def assign_keymem_sboxw (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let keymem_sboxw := s.keymem__sboxw
  { s with
    keymem_sboxw := keymem_sboxw
  }

/-- 组合逻辑：assign_keymem__new_sboxw -/
def assign_keymem__new_sboxw (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let keymem__new_sboxw := s.new_sboxw
  { s with
    keymem__new_sboxw := keymem__new_sboxw
  }

/-- 组合逻辑：assign_keymem__round_key -/
def assign_keymem__round_key (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let keymem__round_key := s.keymem__tmp_round_key
  { s with
    keymem__round_key := keymem__round_key
  }

/-- 组合逻辑：assign_keymem__ready -/
def assign_keymem__ready (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let keymem__ready := s.keymem__ready_reg
  { s with
    keymem__ready := keymem__ready
  }

/-- 组合逻辑：assign_keymem__sboxw -/
def assign_keymem__sboxw (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let keymem__sboxw := s.keymem__tmp_sboxw
  { s with
    keymem__sboxw := keymem__sboxw
  }

/-- 组合逻辑：assign_sbox_inst__sboxw -/
def assign_sbox_inst__sboxw (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let sbox_inst__sboxw := s.muxed_sboxw
  { s with
    sbox_inst__sboxw := sbox_inst__sboxw
  }

/-- 组合逻辑：assign_new_sboxw -/
def assign_new_sboxw (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let new_sboxw := s.sbox_inst__new_sboxw
  { s with
    new_sboxw := new_sboxw
  }

/-- 组合逻辑：assign_sbox_inst__new_sboxw -/
def assign_sbox_inst__new_sboxw (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let sbox_inst__new_sboxw := BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (bvArrayRead 8 256 0 255 (s.sbox_inst__sbox) ((BitVec.extractLsb 31 24 (s.sbox_inst__sboxw)).toNat)) (bvArrayRead 8 256 0 255 (s.sbox_inst__sbox) ((BitVec.extractLsb 23 16 (s.sbox_inst__sboxw)).toNat))) (BitVec.append (n := 8) (m := 8) (bvArrayRead 8 256 0 255 (s.sbox_inst__sbox) ((BitVec.extractLsb 15 8 (s.sbox_inst__sboxw)).toNat)) (bvArrayRead 8 256 0 255 (s.sbox_inst__sbox) ((BitVec.extractLsb 7 0 (s.sbox_inst__sboxw)).toNat)))
  { s with
    sbox_inst__new_sboxw := sbox_inst__new_sboxw
  }

/-- 组合逻辑：assign_sbox_inst__sbox -/
def assign_sbox_inst__sbox (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let sbox_inst__sbox := BitVec.append (n := 1024) (m := 1024) (BitVec.append (n := 512) (m := 512) (BitVec.append (n := 256) (m := 256) (BitVec.append (n := 128) (m := 128) (BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 22) (BitVec.ofNat 8 187)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 84) (BitVec.ofNat 8 176))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 15) (BitVec.ofNat 8 45)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 153) (BitVec.ofNat 8 65)))) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 104) (BitVec.ofNat 8 66)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 230) (BitVec.ofNat 8 191))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 13) (BitVec.ofNat 8 137)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 161) (BitVec.ofNat 8 140))))) (BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 223) (BitVec.ofNat 8 40)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 85) (BitVec.ofNat 8 206))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 233) (BitVec.ofNat 8 135)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 30) (BitVec.ofNat 8 155)))) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 148) (BitVec.ofNat 8 142)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 217) (BitVec.ofNat 8 105))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 17) (BitVec.ofNat 8 152)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 248) (BitVec.ofNat 8 225)))))) (BitVec.append (n := 128) (m := 128) (BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 158) (BitVec.ofNat 8 29)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 193) (BitVec.ofNat 8 134))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 185) (BitVec.ofNat 8 87)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 53) (BitVec.ofNat 8 97)))) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 14) (BitVec.ofNat 8 246)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 3) (BitVec.ofNat 8 72))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 102) (BitVec.ofNat 8 181)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 62) (BitVec.ofNat 8 112))))) (BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 138) (BitVec.ofNat 8 139)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 189) (BitVec.ofNat 8 75))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 31) (BitVec.ofNat 8 116)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 221) (BitVec.ofNat 8 232)))) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 198) (BitVec.ofNat 8 180)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 166) (BitVec.ofNat 8 28))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 46) (BitVec.ofNat 8 37)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 120) (BitVec.ofNat 8 186))))))) (BitVec.append (n := 256) (m := 256) (BitVec.append (n := 128) (m := 128) (BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 8) (BitVec.ofNat 8 174)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 122) (BitVec.ofNat 8 101))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 234) (BitVec.ofNat 8 244)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 86) (BitVec.ofNat 8 108)))) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 169) (BitVec.ofNat 8 78)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 213) (BitVec.ofNat 8 141))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 109) (BitVec.ofNat 8 55)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 200) (BitVec.ofNat 8 231))))) (BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 121) (BitVec.ofNat 8 228)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 149) (BitVec.ofNat 8 145))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 98) (BitVec.ofNat 8 172)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 211) (BitVec.ofNat 8 194)))) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 92) (BitVec.ofNat 8 36)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 6) (BitVec.ofNat 8 73))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 10) (BitVec.ofNat 8 58)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 50) (BitVec.ofNat 8 224)))))) (BitVec.append (n := 128) (m := 128) (BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 219) (BitVec.ofNat 8 11)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 94) (BitVec.ofNat 8 222))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 20) (BitVec.ofNat 8 184)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 238) (BitVec.ofNat 8 70)))) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 136) (BitVec.ofNat 8 144)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 42) (BitVec.ofNat 8 34))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 220) (BitVec.ofNat 8 79)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 129) (BitVec.ofNat 8 96))))) (BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 115) (BitVec.ofNat 8 25)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 93) (BitVec.ofNat 8 100))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 61) (BitVec.ofNat 8 126)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 167) (BitVec.ofNat 8 196)))) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 23) (BitVec.ofNat 8 68)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 151) (BitVec.ofNat 8 95))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 236) (BitVec.ofNat 8 19)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 12) (BitVec.ofNat 8 205)))))))) (BitVec.append (n := 512) (m := 512) (BitVec.append (n := 256) (m := 256) (BitVec.append (n := 128) (m := 128) (BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 210) (BitVec.ofNat 8 243)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 255) (BitVec.ofNat 8 16))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 33) (BitVec.ofNat 8 218)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 182) (BitVec.ofNat 8 188)))) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 245) (BitVec.ofNat 8 56)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 157) (BitVec.ofNat 8 146))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 143) (BitVec.ofNat 8 64)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 163) (BitVec.ofNat 8 81))))) (BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 168) (BitVec.ofNat 8 159)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 60) (BitVec.ofNat 8 80))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 127) (BitVec.ofNat 8 2)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 249) (BitVec.ofNat 8 69)))) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 133) (BitVec.ofNat 8 51)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 77) (BitVec.ofNat 8 67))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 251) (BitVec.ofNat 8 170)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 239) (BitVec.ofNat 8 208)))))) (BitVec.append (n := 128) (m := 128) (BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 207) (BitVec.ofNat 8 88)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 76) (BitVec.ofNat 8 74))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 57) (BitVec.ofNat 8 190)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 203) (BitVec.ofNat 8 106)))) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 91) (BitVec.ofNat 8 177)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 252) (BitVec.ofNat 8 32))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 237) (BitVec.ofNat 8 0)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 209) (BitVec.ofNat 8 83))))) (BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 132) (BitVec.ofNat 8 47)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 227) (BitVec.ofNat 8 41))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 179) (BitVec.ofNat 8 214)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 59) (BitVec.ofNat 8 82)))) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 160) (BitVec.ofNat 8 90)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 110) (BitVec.ofNat 8 27))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 26) (BitVec.ofNat 8 44)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 131) (BitVec.ofNat 8 9))))))) (BitVec.append (n := 256) (m := 256) (BitVec.append (n := 128) (m := 128) (BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 117) (BitVec.ofNat 8 178)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 39) (BitVec.ofNat 8 235))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 226) (BitVec.ofNat 8 128)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 18) (BitVec.ofNat 8 7)))) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 154) (BitVec.ofNat 8 5)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 150) (BitVec.ofNat 8 24))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 195) (BitVec.ofNat 8 35)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 199) (BitVec.ofNat 8 4))))) (BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 21) (BitVec.ofNat 8 49)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 216) (BitVec.ofNat 8 113))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 241) (BitVec.ofNat 8 229)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 165) (BitVec.ofNat 8 52)))) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 204) (BitVec.ofNat 8 247)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 63) (BitVec.ofNat 8 54))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 38) (BitVec.ofNat 8 147)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 253) (BitVec.ofNat 8 183)))))) (BitVec.append (n := 128) (m := 128) (BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 192) (BitVec.ofNat 8 114)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 164) (BitVec.ofNat 8 156))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 175) (BitVec.ofNat 8 162)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 212) (BitVec.ofNat 8 173)))) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 240) (BitVec.ofNat 8 71)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 89) (BitVec.ofNat 8 250))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 125) (BitVec.ofNat 8 201)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 130) (BitVec.ofNat 8 202))))) (BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 118) (BitVec.ofNat 8 171)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 215) (BitVec.ofNat 8 254))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 43) (BitVec.ofNat 8 103)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 1) (BitVec.ofNat 8 48)))) (BitVec.append (n := 32) (m := 32) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 197) (BitVec.ofNat 8 111)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 107) (BitVec.ofNat 8 242))) (BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 123) (BitVec.ofNat 8 119)) (BitVec.append (n := 8) (m := 8) (BitVec.ofNat 8 124) (BitVec.ofNat 8 99))))))))
  { s with
    sbox_inst__sbox := sbox_inst__sbox
  }

/-- 组合逻辑：assign_ready -/
def assign_ready (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let ready := s.ready_reg
  { s with
    ready := ready
  }

/-- 组合逻辑：assign_result -/
def assign_result (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let result := s.muxed_new_block
  { s with
    result := result
  }

/-- 组合逻辑：assign_result_valid -/
def assign_result_valid (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let result_valid := s.result_valid_reg
  { s with
    result_valid := result_valid
  }

private def _rtl_eval_block_0 (s : aes_coreState) (i : aes_coreInputs) (env : Unit) : (((Bool × BitVec 128) × (BitVec 128 × (Bool × BitVec 128))) × ((Bool × (BitVec 128 × BitVec 32)) × (BitVec 8 × (BitVec 8 × BitVec 8)))) :=
  let _rtl_expr_0 : Bool := decide ((s.enc_block__update_type).toNat = (BitVec.ofNat 3 1).toNat)
  let _rtl_expr_1 : BitVec 128 := BitVec.extractLsb 127 0 (s.enc_block__block)
  let _rtl_expr_2 : BitVec 128 := BitVec.extractLsb 127 0 (s.enc_block__round_key)
  let _rtl_expr_3 : BitVec 128 := (_rtl_expr_1 ^^^ _rtl_expr_2)
  let _rtl_expr_4 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_3)
  let _rtl_expr_5 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_4)
  let _rtl_expr_6 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_5)
  let _rtl_expr_7 : Bool := decide ((s.enc_block__update_type).toNat = (BitVec.ofNat 3 2).toNat)
  let _rtl_expr_8 : BitVec 128 := BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (s.enc_block__new_sboxw) (s.enc_block__new_sboxw)) (BitVec.append (n := 32) (m := 32) (s.enc_block__new_sboxw) (s.enc_block__new_sboxw))
  let _rtl_expr_9 : Bool := decide ((s.enc_block__update_type).toNat = (BitVec.ofNat 3 3).toNat)
  let _rtl_expr_10 : BitVec 128 := BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (s.enc_block__block_w0_reg) (s.enc_block__block_w1_reg)) (BitVec.append (n := 32) (m := 32) (s.enc_block__block_w2_reg) (s.enc_block__block_w3_reg))
  let _rtl_expr_11 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_10)
  let _rtl_expr_12 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_11)
  let _rtl_expr_13 : BitVec 32 := BitVec.extractLsb 127 96 (_rtl_expr_12)
  let _rtl_expr_14 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_13)
  let _rtl_expr_15 : BitVec 8 := BitVec.extractLsb 31 24 (_rtl_expr_14)
  let _rtl_expr_16 : BitVec 32 := BitVec.extractLsb 95 64 (_rtl_expr_12)
  let _rtl_expr_17 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_16)
  let _rtl_expr_18 : BitVec 8 := BitVec.extractLsb 23 16 (_rtl_expr_17)
  let _rtl_expr_19 : BitVec 32 := BitVec.extractLsb 63 32 (_rtl_expr_12)
  let _rtl_expr_20 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_19)
  let _rtl_expr_21 : BitVec 8 := BitVec.extractLsb 15 8 (_rtl_expr_20)
  let _rtl_expr_22 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_12)
  let _rtl_expr_23 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_22)
  let _rtl_expr_24 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_23)
  let _rtl_expr_25 : BitVec 32 := BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (_rtl_expr_15) (_rtl_expr_18)) (BitVec.append (n := 8) (m := 8) (_rtl_expr_21) (_rtl_expr_24))
  let _rtl_expr_26 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_25)
  let _rtl_expr_27 : BitVec 8 := BitVec.extractLsb 31 24 (_rtl_expr_17)
  let _rtl_expr_28 : BitVec 8 := BitVec.extractLsb 23 16 (_rtl_expr_20)
  let _rtl_expr_29 : BitVec 8 := BitVec.extractLsb 15 8 (_rtl_expr_23)
  let _rtl_expr_30 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_14)
  let _rtl_expr_31 : BitVec 32 := BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (_rtl_expr_27) (_rtl_expr_28)) (BitVec.append (n := 8) (m := 8) (_rtl_expr_29) (_rtl_expr_30))
  let _rtl_expr_32 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_31)
  let _rtl_expr_33 : BitVec 8 := BitVec.extractLsb 31 24 (_rtl_expr_20)
  let _rtl_expr_34 : BitVec 8 := BitVec.extractLsb 23 16 (_rtl_expr_23)
  let _rtl_expr_35 : BitVec 8 := BitVec.extractLsb 15 8 (_rtl_expr_14)
  let _rtl_expr_36 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_17)
  let _rtl_expr_37 : BitVec 32 := BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (_rtl_expr_33) (_rtl_expr_34)) (BitVec.append (n := 8) (m := 8) (_rtl_expr_35) (_rtl_expr_36))
  let _rtl_expr_38 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_37)
  let _rtl_expr_39 : BitVec 8 := BitVec.extractLsb 31 24 (_rtl_expr_23)
  let _rtl_expr_40 : BitVec 8 := BitVec.extractLsb 23 16 (_rtl_expr_14)
  let _rtl_expr_41 : BitVec 8 := BitVec.extractLsb 15 8 (_rtl_expr_17)
  let _rtl_expr_42 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_20)
  let _rtl_expr_43 : BitVec 32 := BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (_rtl_expr_39) (_rtl_expr_40)) (BitVec.append (n := 8) (m := 8) (_rtl_expr_41) (_rtl_expr_42))
  let _rtl_expr_44 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_43)
  let _rtl_expr_45 : BitVec 128 := BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (_rtl_expr_26) (_rtl_expr_32)) (BitVec.append (n := 32) (m := 32) (_rtl_expr_38) (_rtl_expr_44))
  let _rtl_expr_46 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_45)
  let _rtl_expr_47 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_46)
  let _rtl_expr_48 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_47)
  let _rtl_expr_49 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_48)
  let _rtl_expr_50 : BitVec 32 := BitVec.extractLsb 127 96 (_rtl_expr_49)
  let _rtl_expr_51 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_50)
  let _rtl_expr_52 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_51)
  let _rtl_expr_53 : BitVec 8 := BitVec.extractLsb 31 24 (_rtl_expr_52)
  let _rtl_expr_54 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_53)
  let _rtl_expr_55 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_54)
  let _rtl_expr_56 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_55)
  let _rtl_expr_57 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_56) (boolToBitVec (false))
  let _rtl_expr_58 : Bool := BitVec.getLsbD (_rtl_expr_55) 7
  let _rtl_expr_59 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_58)) (boolToBitVec (_rtl_expr_58))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_58)) (boolToBitVec (_rtl_expr_58)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_58)) (boolToBitVec (_rtl_expr_58))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_58)) (boolToBitVec (_rtl_expr_58))))
  let _rtl_expr_60 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_59)
  let _rtl_expr_61 : BitVec 8 := (_rtl_expr_57 ^^^ _rtl_expr_60)
  let _rtl_expr_62 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_61)
  let _rtl_expr_63 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_62)
  (((_rtl_expr_0, _rtl_expr_2), (_rtl_expr_6, (_rtl_expr_7, _rtl_expr_8))), ((_rtl_expr_9, (_rtl_expr_49, _rtl_expr_52)), (_rtl_expr_54, (_rtl_expr_55, _rtl_expr_63))))

private def _rtl_eval_block_1 (s : aes_coreState) (i : aes_coreInputs) (env : (((Bool × BitVec 128) × (BitVec 128 × (Bool × BitVec 128))) × ((Bool × (BitVec 128 × BitVec 32)) × (BitVec 8 × (BitVec 8 × BitVec 8))))) : ((((Bool × BitVec 128) × (BitVec 128 × Bool)) × ((BitVec 128 × Bool) × (BitVec 128 × BitVec 8))) × (((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8)))) :=
  let _rtl_expr_64 : BitVec 8 := BitVec.extractLsb 23 16 (((((env).2).1).2).2)
  let _rtl_expr_65 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_64)
  let _rtl_expr_66 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_65)
  let _rtl_expr_67 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_66)
  let _rtl_expr_68 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_67)
  let _rtl_expr_69 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_68) (boolToBitVec (false))
  let _rtl_expr_70 : Bool := BitVec.getLsbD (_rtl_expr_67) 7
  let _rtl_expr_71 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_70)) (boolToBitVec (_rtl_expr_70))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_70)) (boolToBitVec (_rtl_expr_70)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_70)) (boolToBitVec (_rtl_expr_70))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_70)) (boolToBitVec (_rtl_expr_70))))
  let _rtl_expr_72 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_71)
  let _rtl_expr_73 : BitVec 8 := (_rtl_expr_69 ^^^ _rtl_expr_72)
  let _rtl_expr_74 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_73)
  let _rtl_expr_75 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_74)
  let _rtl_expr_76 : BitVec 8 := (_rtl_expr_75 ^^^ _rtl_expr_66)
  let _rtl_expr_77 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_76)
  let _rtl_expr_78 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_77)
  let _rtl_expr_79 : BitVec 8 := (((((env).2).2).2).2 ^^^ _rtl_expr_78)
  let _rtl_expr_80 : BitVec 8 := BitVec.extractLsb 15 8 (((((env).2).1).2).2)
  let _rtl_expr_81 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_80)
  let _rtl_expr_82 : BitVec 8 := (_rtl_expr_79 ^^^ _rtl_expr_81)
  let _rtl_expr_83 : BitVec 8 := BitVec.extractLsb 7 0 (((((env).2).1).2).2)
  let _rtl_expr_84 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_83)
  let _rtl_expr_85 : BitVec 8 := (_rtl_expr_82 ^^^ _rtl_expr_84)
  let _rtl_expr_86 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_85)
  let _rtl_expr_87 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_66)
  let _rtl_expr_88 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_87) (boolToBitVec (false))
  let _rtl_expr_89 : Bool := BitVec.getLsbD (_rtl_expr_66) 7
  let _rtl_expr_90 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_89)) (boolToBitVec (_rtl_expr_89))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_89)) (boolToBitVec (_rtl_expr_89)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_89)) (boolToBitVec (_rtl_expr_89))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_89)) (boolToBitVec (_rtl_expr_89))))
  let _rtl_expr_91 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_90)
  let _rtl_expr_92 : BitVec 8 := (_rtl_expr_88 ^^^ _rtl_expr_91)
  let _rtl_expr_93 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_92)
  let _rtl_expr_94 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_93)
  let _rtl_expr_95 : BitVec 8 := ((((env).2).2).1 ^^^ _rtl_expr_94)
  let _rtl_expr_96 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_81)
  let _rtl_expr_97 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_96)
  let _rtl_expr_98 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_97)
  let _rtl_expr_99 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_98) (boolToBitVec (false))
  let _rtl_expr_100 : Bool := BitVec.getLsbD (_rtl_expr_97) 7
  let _rtl_expr_101 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_100)) (boolToBitVec (_rtl_expr_100))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_100)) (boolToBitVec (_rtl_expr_100)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_100)) (boolToBitVec (_rtl_expr_100))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_100)) (boolToBitVec (_rtl_expr_100))))
  let _rtl_expr_102 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_101)
  let _rtl_expr_103 : BitVec 8 := (_rtl_expr_99 ^^^ _rtl_expr_102)
  let _rtl_expr_104 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_103)
  let _rtl_expr_105 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_104)
  let _rtl_expr_106 : BitVec 8 := (_rtl_expr_105 ^^^ _rtl_expr_96)
  let _rtl_expr_107 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_106)
  let _rtl_expr_108 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_107)
  let _rtl_expr_109 : BitVec 8 := (_rtl_expr_95 ^^^ _rtl_expr_108)
  let _rtl_expr_110 : BitVec 8 := (_rtl_expr_109 ^^^ _rtl_expr_84)
  let _rtl_expr_111 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_110)
  let _rtl_expr_112 : BitVec 8 := ((((env).2).2).1 ^^^ _rtl_expr_65)
  let _rtl_expr_113 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_96)
  let _rtl_expr_114 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_113) (boolToBitVec (false))
  let _rtl_expr_115 : Bool := BitVec.getLsbD (_rtl_expr_96) 7
  let _rtl_expr_116 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_115)) (boolToBitVec (_rtl_expr_115))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_115)) (boolToBitVec (_rtl_expr_115)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_115)) (boolToBitVec (_rtl_expr_115))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_115)) (boolToBitVec (_rtl_expr_115))))
  let _rtl_expr_117 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_116)
  let _rtl_expr_118 : BitVec 8 := (_rtl_expr_114 ^^^ _rtl_expr_117)
  let _rtl_expr_119 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_118)
  let _rtl_expr_120 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_119)
  let _rtl_expr_121 : BitVec 8 := (_rtl_expr_112 ^^^ _rtl_expr_120)
  let _rtl_expr_122 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_84)
  let _rtl_expr_123 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_122)
  let _rtl_expr_124 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_123)
  let _rtl_expr_125 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_124) (boolToBitVec (false))
  let _rtl_expr_126 : Bool := BitVec.getLsbD (_rtl_expr_123) 7
  let _rtl_expr_127 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_126)) (boolToBitVec (_rtl_expr_126))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_126)) (boolToBitVec (_rtl_expr_126)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_126)) (boolToBitVec (_rtl_expr_126))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_126)) (boolToBitVec (_rtl_expr_126))))
  (((((((env).1).1).1, (((env).1).1).2), ((((env).1).2).1, ((((env).1).2).2).1)), ((((((env).1).2).2).2, (((env).2).1).1), (((((env).2).1).2).1, ((((env).2).2).2).1))), (((_rtl_expr_65, _rtl_expr_81), (_rtl_expr_86, _rtl_expr_111)), ((_rtl_expr_121, _rtl_expr_122), (_rtl_expr_125, _rtl_expr_127))))

private def _rtl_eval_block_2 (s : aes_coreState) (i : aes_coreInputs) (env : ((((Bool × BitVec 128) × (BitVec 128 × Bool)) × ((BitVec 128 × Bool) × (BitVec 128 × BitVec 8))) × (((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8))))) : (((Bool × (BitVec 128 × BitVec 128)) × ((Bool × BitVec 128) × (Bool × BitVec 128))) × (((BitVec 32 × BitVec 32) × (BitVec 8 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8)))) :=
  let _rtl_expr_128 : BitVec 8 := (BitVec.ofNat 8 27 &&& ((((env).2).2).2).2)
  let _rtl_expr_129 : BitVec 8 := (((((env).2).2).2).1 ^^^ _rtl_expr_128)
  let _rtl_expr_130 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_129)
  let _rtl_expr_131 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_130)
  let _rtl_expr_132 : BitVec 8 := (_rtl_expr_131 ^^^ ((((env).2).2).1).2)
  let _rtl_expr_133 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_132)
  let _rtl_expr_134 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_133)
  let _rtl_expr_135 : BitVec 8 := (((((env).2).2).1).1 ^^^ _rtl_expr_134)
  let _rtl_expr_136 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_135)
  let _rtl_expr_137 : BitVec 8 := BitVec.extractLsb 7 0 (((((env).1).2).2).2)
  let _rtl_expr_138 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_137)
  let _rtl_expr_139 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_138) (boolToBitVec (false))
  let _rtl_expr_140 : Bool := BitVec.getLsbD (_rtl_expr_137) 7
  let _rtl_expr_141 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_140)) (boolToBitVec (_rtl_expr_140))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_140)) (boolToBitVec (_rtl_expr_140)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_140)) (boolToBitVec (_rtl_expr_140))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_140)) (boolToBitVec (_rtl_expr_140))))
  let _rtl_expr_142 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_141)
  let _rtl_expr_143 : BitVec 8 := (_rtl_expr_139 ^^^ _rtl_expr_142)
  let _rtl_expr_144 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_143)
  let _rtl_expr_145 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_144)
  let _rtl_expr_146 : BitVec 8 := (_rtl_expr_145 ^^^ ((((env).1).2).2).2)
  let _rtl_expr_147 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_146)
  let _rtl_expr_148 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_147)
  let _rtl_expr_149 : BitVec 8 := (_rtl_expr_148 ^^^ ((((env).2).1).1).1)
  let _rtl_expr_150 : BitVec 8 := (_rtl_expr_149 ^^^ ((((env).2).1).1).2)
  let _rtl_expr_151 : BitVec 7 := BitVec.extractLsb 6 0 (((((env).2).2).1).2)
  let _rtl_expr_152 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_151) (boolToBitVec (false))
  let _rtl_expr_153 : Bool := BitVec.getLsbD (((((env).2).2).1).2) 7
  let _rtl_expr_154 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_153)) (boolToBitVec (_rtl_expr_153))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_153)) (boolToBitVec (_rtl_expr_153)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_153)) (boolToBitVec (_rtl_expr_153))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_153)) (boolToBitVec (_rtl_expr_153))))
  let _rtl_expr_155 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_154)
  let _rtl_expr_156 : BitVec 8 := (_rtl_expr_152 ^^^ _rtl_expr_155)
  let _rtl_expr_157 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_156)
  let _rtl_expr_158 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_157)
  let _rtl_expr_159 : BitVec 8 := (_rtl_expr_150 ^^^ _rtl_expr_158)
  let _rtl_expr_160 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_159)
  let _rtl_expr_161 : BitVec 32 := BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (((((env).2).1).2).1) (((((env).2).1).2).2)) (BitVec.append (n := 8) (m := 8) (_rtl_expr_136) (_rtl_expr_160))
  let _rtl_expr_162 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_161)
  let _rtl_expr_163 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_162)
  let _rtl_expr_164 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_163)
  let _rtl_expr_165 : BitVec 32 := BitVec.extractLsb 95 64 (((((env).1).2).2).1)
  let _rtl_expr_166 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_165)
  let _rtl_expr_167 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_166)
  let _rtl_expr_168 : BitVec 8 := BitVec.extractLsb 31 24 (_rtl_expr_167)
  let _rtl_expr_169 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_168)
  let _rtl_expr_170 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_169)
  let _rtl_expr_171 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_170)
  let _rtl_expr_172 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_171) (boolToBitVec (false))
  let _rtl_expr_173 : Bool := BitVec.getLsbD (_rtl_expr_170) 7
  let _rtl_expr_174 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_173)) (boolToBitVec (_rtl_expr_173))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_173)) (boolToBitVec (_rtl_expr_173)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_173)) (boolToBitVec (_rtl_expr_173))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_173)) (boolToBitVec (_rtl_expr_173))))
  let _rtl_expr_175 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_174)
  let _rtl_expr_176 : BitVec 8 := (_rtl_expr_172 ^^^ _rtl_expr_175)
  let _rtl_expr_177 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_176)
  let _rtl_expr_178 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_177)
  let _rtl_expr_179 : BitVec 8 := BitVec.extractLsb 23 16 (_rtl_expr_167)
  let _rtl_expr_180 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_179)
  let _rtl_expr_181 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_180)
  let _rtl_expr_182 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_181)
  let _rtl_expr_183 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_182)
  let _rtl_expr_184 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_183) (boolToBitVec (false))
  let _rtl_expr_185 : Bool := BitVec.getLsbD (_rtl_expr_182) 7
  let _rtl_expr_186 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_185)) (boolToBitVec (_rtl_expr_185))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_185)) (boolToBitVec (_rtl_expr_185)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_185)) (boolToBitVec (_rtl_expr_185))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_185)) (boolToBitVec (_rtl_expr_185))))
  let _rtl_expr_187 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_186)
  let _rtl_expr_188 : BitVec 8 := (_rtl_expr_184 ^^^ _rtl_expr_187)
  let _rtl_expr_189 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_188)
  let _rtl_expr_190 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_189)
  let _rtl_expr_191 : BitVec 8 := (_rtl_expr_190 ^^^ _rtl_expr_181)
  (((((((env).1).1).1).1, (((((env).1).1).1).2, ((((env).1).1).2).1)), ((((((env).1).1).2).2, ((((env).1).2).1).1), (((((env).1).2).1).2, ((((env).1).2).2).1))), (((_rtl_expr_164, _rtl_expr_167), (_rtl_expr_169, _rtl_expr_170)), ((_rtl_expr_178, _rtl_expr_180), (_rtl_expr_181, _rtl_expr_191))))

private def _rtl_eval_block_3 (s : aes_coreState) (i : aes_coreInputs) (env : (((Bool × (BitVec 128 × BitVec 128)) × ((Bool × BitVec 128) × (Bool × BitVec 128))) × (((BitVec 32 × BitVec 32) × (BitVec 8 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8))))) : ((((Bool × BitVec 128) × (BitVec 128 × Bool)) × ((BitVec 128 × Bool) × (BitVec 128 × BitVec 32))) × (((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × (BitVec 8 × Bool))))) :=
  let _rtl_expr_192 : BitVec 8 := BitVec.extractLsb 7 0 (((((env).2).2).2).2)
  let _rtl_expr_193 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_192)
  let _rtl_expr_194 : BitVec 8 := (((((env).2).2).1).1 ^^^ _rtl_expr_193)
  let _rtl_expr_195 : BitVec 8 := BitVec.extractLsb 15 8 (((((env).2).1).1).2)
  let _rtl_expr_196 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_195)
  let _rtl_expr_197 : BitVec 8 := (_rtl_expr_194 ^^^ _rtl_expr_196)
  let _rtl_expr_198 : BitVec 8 := BitVec.extractLsb 7 0 (((((env).2).1).1).2)
  let _rtl_expr_199 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_198)
  let _rtl_expr_200 : BitVec 8 := (_rtl_expr_197 ^^^ _rtl_expr_199)
  let _rtl_expr_201 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_200)
  let _rtl_expr_202 : BitVec 7 := BitVec.extractLsb 6 0 (((((env).2).2).2).1)
  let _rtl_expr_203 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_202) (boolToBitVec (false))
  let _rtl_expr_204 : Bool := BitVec.getLsbD (((((env).2).2).2).1) 7
  let _rtl_expr_205 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_204)) (boolToBitVec (_rtl_expr_204))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_204)) (boolToBitVec (_rtl_expr_204)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_204)) (boolToBitVec (_rtl_expr_204))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_204)) (boolToBitVec (_rtl_expr_204))))
  let _rtl_expr_206 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_205)
  let _rtl_expr_207 : BitVec 8 := (_rtl_expr_203 ^^^ _rtl_expr_206)
  let _rtl_expr_208 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_207)
  let _rtl_expr_209 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_208)
  let _rtl_expr_210 : BitVec 8 := (((((env).2).1).2).1 ^^^ _rtl_expr_209)
  let _rtl_expr_211 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_196)
  let _rtl_expr_212 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_211)
  let _rtl_expr_213 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_212)
  let _rtl_expr_214 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_213) (boolToBitVec (false))
  let _rtl_expr_215 : Bool := BitVec.getLsbD (_rtl_expr_212) 7
  let _rtl_expr_216 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_215)) (boolToBitVec (_rtl_expr_215))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_215)) (boolToBitVec (_rtl_expr_215)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_215)) (boolToBitVec (_rtl_expr_215))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_215)) (boolToBitVec (_rtl_expr_215))))
  let _rtl_expr_217 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_216)
  let _rtl_expr_218 : BitVec 8 := (_rtl_expr_214 ^^^ _rtl_expr_217)
  let _rtl_expr_219 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_218)
  let _rtl_expr_220 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_219)
  let _rtl_expr_221 : BitVec 8 := (_rtl_expr_220 ^^^ _rtl_expr_211)
  let _rtl_expr_222 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_221)
  let _rtl_expr_223 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_222)
  let _rtl_expr_224 : BitVec 8 := (_rtl_expr_210 ^^^ _rtl_expr_223)
  let _rtl_expr_225 : BitVec 8 := (_rtl_expr_224 ^^^ _rtl_expr_199)
  let _rtl_expr_226 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_225)
  let _rtl_expr_227 : BitVec 8 := (((((env).2).1).2).1 ^^^ ((((env).2).2).1).2)
  let _rtl_expr_228 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_211)
  let _rtl_expr_229 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_228) (boolToBitVec (false))
  let _rtl_expr_230 : Bool := BitVec.getLsbD (_rtl_expr_211) 7
  let _rtl_expr_231 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_230)) (boolToBitVec (_rtl_expr_230))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_230)) (boolToBitVec (_rtl_expr_230)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_230)) (boolToBitVec (_rtl_expr_230))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_230)) (boolToBitVec (_rtl_expr_230))))
  let _rtl_expr_232 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_231)
  let _rtl_expr_233 : BitVec 8 := (_rtl_expr_229 ^^^ _rtl_expr_232)
  let _rtl_expr_234 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_233)
  let _rtl_expr_235 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_234)
  let _rtl_expr_236 : BitVec 8 := (_rtl_expr_227 ^^^ _rtl_expr_235)
  let _rtl_expr_237 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_199)
  let _rtl_expr_238 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_237)
  let _rtl_expr_239 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_238)
  let _rtl_expr_240 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_239) (boolToBitVec (false))
  let _rtl_expr_241 : Bool := BitVec.getLsbD (_rtl_expr_238) 7
  let _rtl_expr_242 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_241)) (boolToBitVec (_rtl_expr_241))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_241)) (boolToBitVec (_rtl_expr_241)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_241)) (boolToBitVec (_rtl_expr_241))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_241)) (boolToBitVec (_rtl_expr_241))))
  let _rtl_expr_243 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_242)
  let _rtl_expr_244 : BitVec 8 := (_rtl_expr_240 ^^^ _rtl_expr_243)
  let _rtl_expr_245 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_244)
  let _rtl_expr_246 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_245)
  let _rtl_expr_247 : BitVec 8 := (_rtl_expr_246 ^^^ _rtl_expr_237)
  let _rtl_expr_248 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_247)
  let _rtl_expr_249 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_248)
  let _rtl_expr_250 : BitVec 8 := (_rtl_expr_236 ^^^ _rtl_expr_249)
  let _rtl_expr_251 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_250)
  let _rtl_expr_252 : BitVec 8 := BitVec.extractLsb 7 0 (((((env).2).1).2).2)
  let _rtl_expr_253 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_252)
  let _rtl_expr_254 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_253) (boolToBitVec (false))
  let _rtl_expr_255 : Bool := BitVec.getLsbD (_rtl_expr_252) 7
  (((((((env).1).1).1, ((((env).1).1).2).1), (((((env).1).1).2).2, ((((env).1).2).1).1)), ((((((env).1).2).1).2, ((((env).1).2).2).1), (((((env).1).2).2).2, ((((env).2).1).1).1))), (((((((env).2).1).2).2, ((((env).2).2).1).2), (_rtl_expr_196, _rtl_expr_201)), ((_rtl_expr_226, _rtl_expr_237), (_rtl_expr_251, (_rtl_expr_254, _rtl_expr_255)))))

private def _rtl_eval_block_4 (s : aes_coreState) (i : aes_coreInputs) (env : ((((Bool × BitVec 128) × (BitVec 128 × Bool)) × ((BitVec 128 × Bool) × (BitVec 128 × BitVec 32))) × (((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × (BitVec 8 × Bool)))))) : ((((Bool × BitVec 128) × (BitVec 128 × Bool)) × ((BitVec 128 × Bool) × (BitVec 128 × BitVec 32))) × (((BitVec 32 × BitVec 8) × (BitVec 8 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × (BitVec 8 × Bool))))) :=
  let _rtl_expr_256 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec ((((((env).2).2).2).2).2)) (boolToBitVec ((((((env).2).2).2).2).2))) (BitVec.append (n := 1) (m := 1) (boolToBitVec ((((((env).2).2).2).2).2)) (boolToBitVec ((((((env).2).2).2).2).2)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec ((((((env).2).2).2).2).2)) (boolToBitVec ((((((env).2).2).2).2).2))) (BitVec.append (n := 1) (m := 1) (boolToBitVec ((((((env).2).2).2).2).2)) (boolToBitVec ((((((env).2).2).2).2).2))))
  let _rtl_expr_257 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_256)
  let _rtl_expr_258 : BitVec 8 := ((((((env).2).2).2).2).1 ^^^ _rtl_expr_257)
  let _rtl_expr_259 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_258)
  let _rtl_expr_260 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_259)
  let _rtl_expr_261 : BitVec 8 := (_rtl_expr_260 ^^^ ((((env).2).1).1).1)
  let _rtl_expr_262 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_261)
  let _rtl_expr_263 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_262)
  let _rtl_expr_264 : BitVec 8 := (_rtl_expr_263 ^^^ ((((env).2).1).1).2)
  let _rtl_expr_265 : BitVec 8 := (_rtl_expr_264 ^^^ ((((env).2).1).2).1)
  let _rtl_expr_266 : BitVec 7 := BitVec.extractLsb 6 0 (((((env).2).2).1).2)
  let _rtl_expr_267 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_266) (boolToBitVec (false))
  let _rtl_expr_268 : Bool := BitVec.getLsbD (((((env).2).2).1).2) 7
  let _rtl_expr_269 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_268)) (boolToBitVec (_rtl_expr_268))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_268)) (boolToBitVec (_rtl_expr_268)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_268)) (boolToBitVec (_rtl_expr_268))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_268)) (boolToBitVec (_rtl_expr_268))))
  let _rtl_expr_270 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_269)
  let _rtl_expr_271 : BitVec 8 := (_rtl_expr_267 ^^^ _rtl_expr_270)
  let _rtl_expr_272 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_271)
  let _rtl_expr_273 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_272)
  let _rtl_expr_274 : BitVec 8 := (_rtl_expr_265 ^^^ _rtl_expr_273)
  let _rtl_expr_275 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_274)
  let _rtl_expr_276 : BitVec 32 := BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (((((env).2).1).2).2) (((((env).2).2).1).1)) (BitVec.append (n := 8) (m := 8) (((((env).2).2).2).1) (_rtl_expr_275))
  let _rtl_expr_277 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_276)
  let _rtl_expr_278 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_277)
  let _rtl_expr_279 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_278)
  let _rtl_expr_280 : BitVec 32 := BitVec.extractLsb 63 32 (((((env).1).2).2).1)
  let _rtl_expr_281 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_280)
  let _rtl_expr_282 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_281)
  let _rtl_expr_283 : BitVec 8 := BitVec.extractLsb 31 24 (_rtl_expr_282)
  let _rtl_expr_284 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_283)
  let _rtl_expr_285 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_284)
  let _rtl_expr_286 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_285)
  let _rtl_expr_287 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_286) (boolToBitVec (false))
  let _rtl_expr_288 : Bool := BitVec.getLsbD (_rtl_expr_285) 7
  let _rtl_expr_289 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_288)) (boolToBitVec (_rtl_expr_288))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_288)) (boolToBitVec (_rtl_expr_288)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_288)) (boolToBitVec (_rtl_expr_288))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_288)) (boolToBitVec (_rtl_expr_288))))
  let _rtl_expr_290 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_289)
  let _rtl_expr_291 : BitVec 8 := (_rtl_expr_287 ^^^ _rtl_expr_290)
  let _rtl_expr_292 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_291)
  let _rtl_expr_293 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_292)
  let _rtl_expr_294 : BitVec 8 := BitVec.extractLsb 23 16 (_rtl_expr_282)
  let _rtl_expr_295 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_294)
  let _rtl_expr_296 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_295)
  let _rtl_expr_297 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_296)
  let _rtl_expr_298 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_297)
  let _rtl_expr_299 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_298) (boolToBitVec (false))
  let _rtl_expr_300 : Bool := BitVec.getLsbD (_rtl_expr_297) 7
  let _rtl_expr_301 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_300)) (boolToBitVec (_rtl_expr_300))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_300)) (boolToBitVec (_rtl_expr_300)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_300)) (boolToBitVec (_rtl_expr_300))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_300)) (boolToBitVec (_rtl_expr_300))))
  let _rtl_expr_302 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_301)
  let _rtl_expr_303 : BitVec 8 := (_rtl_expr_299 ^^^ _rtl_expr_302)
  let _rtl_expr_304 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_303)
  let _rtl_expr_305 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_304)
  let _rtl_expr_306 : BitVec 8 := (_rtl_expr_305 ^^^ _rtl_expr_296)
  let _rtl_expr_307 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_306)
  let _rtl_expr_308 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_307)
  let _rtl_expr_309 : BitVec 8 := (_rtl_expr_293 ^^^ _rtl_expr_308)
  let _rtl_expr_310 : BitVec 8 := BitVec.extractLsb 15 8 (_rtl_expr_282)
  let _rtl_expr_311 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_310)
  let _rtl_expr_312 : BitVec 8 := (_rtl_expr_309 ^^^ _rtl_expr_311)
  let _rtl_expr_313 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_282)
  let _rtl_expr_314 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_313)
  let _rtl_expr_315 : BitVec 8 := (_rtl_expr_312 ^^^ _rtl_expr_314)
  let _rtl_expr_316 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_315)
  let _rtl_expr_317 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_296)
  let _rtl_expr_318 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_317) (boolToBitVec (false))
  let _rtl_expr_319 : Bool := BitVec.getLsbD (_rtl_expr_296) 7
  ((((((((env).1).1).1).1, ((((env).1).1).1).2), (((((env).1).1).2).1, ((((env).1).1).2).2)), ((((((env).1).2).1).1, ((((env).1).2).1).2), (((((env).1).2).2).1, ((((env).1).2).2).2))), (((_rtl_expr_279, _rtl_expr_284), (_rtl_expr_285, _rtl_expr_295)), ((_rtl_expr_311, _rtl_expr_314), (_rtl_expr_316, (_rtl_expr_318, _rtl_expr_319)))))

private def _rtl_eval_block_5 (s : aes_coreState) (i : aes_coreInputs) (env : ((((Bool × BitVec 128) × (BitVec 128 × Bool)) × ((BitVec 128 × Bool) × (BitVec 128 × BitVec 32))) × (((BitVec 32 × BitVec 8) × (BitVec 8 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × (BitVec 8 × Bool)))))) : (((Bool × (BitVec 128 × BitVec 128)) × ((Bool × BitVec 128) × (Bool × BitVec 128))) × (((BitVec 32 × BitVec 32) × (BitVec 8 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × Bool)))) :=
  let _rtl_expr_320 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec ((((((env).2).2).2).2).2)) (boolToBitVec ((((((env).2).2).2).2).2))) (BitVec.append (n := 1) (m := 1) (boolToBitVec ((((((env).2).2).2).2).2)) (boolToBitVec ((((((env).2).2).2).2).2)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec ((((((env).2).2).2).2).2)) (boolToBitVec ((((((env).2).2).2).2).2))) (BitVec.append (n := 1) (m := 1) (boolToBitVec ((((((env).2).2).2).2).2)) (boolToBitVec ((((((env).2).2).2).2).2))))
  let _rtl_expr_321 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_320)
  let _rtl_expr_322 : BitVec 8 := ((((((env).2).2).2).2).1 ^^^ _rtl_expr_321)
  let _rtl_expr_323 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_322)
  let _rtl_expr_324 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_323)
  let _rtl_expr_325 : BitVec 8 := (((((env).2).1).1).2 ^^^ _rtl_expr_324)
  let _rtl_expr_326 : BitVec 8 := BitVec.extractLsb 7 0 (((((env).2).2).1).1)
  let _rtl_expr_327 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_326)
  let _rtl_expr_328 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_327)
  let _rtl_expr_329 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_328) (boolToBitVec (false))
  let _rtl_expr_330 : Bool := BitVec.getLsbD (_rtl_expr_327) 7
  let _rtl_expr_331 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_330)) (boolToBitVec (_rtl_expr_330))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_330)) (boolToBitVec (_rtl_expr_330)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_330)) (boolToBitVec (_rtl_expr_330))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_330)) (boolToBitVec (_rtl_expr_330))))
  let _rtl_expr_332 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_331)
  let _rtl_expr_333 : BitVec 8 := (_rtl_expr_329 ^^^ _rtl_expr_332)
  let _rtl_expr_334 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_333)
  let _rtl_expr_335 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_334)
  let _rtl_expr_336 : BitVec 8 := (_rtl_expr_335 ^^^ _rtl_expr_326)
  let _rtl_expr_337 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_336)
  let _rtl_expr_338 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_337)
  let _rtl_expr_339 : BitVec 8 := (_rtl_expr_325 ^^^ _rtl_expr_338)
  let _rtl_expr_340 : BitVec 8 := (_rtl_expr_339 ^^^ ((((env).2).2).1).2)
  let _rtl_expr_341 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_340)
  let _rtl_expr_342 : BitVec 8 := (((((env).2).1).1).2 ^^^ ((((env).2).1).2).2)
  let _rtl_expr_343 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_326)
  let _rtl_expr_344 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_343) (boolToBitVec (false))
  let _rtl_expr_345 : Bool := BitVec.getLsbD (_rtl_expr_326) 7
  let _rtl_expr_346 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_345)) (boolToBitVec (_rtl_expr_345))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_345)) (boolToBitVec (_rtl_expr_345)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_345)) (boolToBitVec (_rtl_expr_345))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_345)) (boolToBitVec (_rtl_expr_345))))
  let _rtl_expr_347 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_346)
  let _rtl_expr_348 : BitVec 8 := (_rtl_expr_344 ^^^ _rtl_expr_347)
  let _rtl_expr_349 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_348)
  let _rtl_expr_350 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_349)
  let _rtl_expr_351 : BitVec 8 := (_rtl_expr_342 ^^^ _rtl_expr_350)
  let _rtl_expr_352 : BitVec 8 := BitVec.extractLsb 7 0 (((((env).2).2).1).2)
  let _rtl_expr_353 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_352)
  let _rtl_expr_354 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_353)
  let _rtl_expr_355 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_354) (boolToBitVec (false))
  let _rtl_expr_356 : Bool := BitVec.getLsbD (_rtl_expr_353) 7
  let _rtl_expr_357 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_356)) (boolToBitVec (_rtl_expr_356))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_356)) (boolToBitVec (_rtl_expr_356)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_356)) (boolToBitVec (_rtl_expr_356))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_356)) (boolToBitVec (_rtl_expr_356))))
  let _rtl_expr_358 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_357)
  let _rtl_expr_359 : BitVec 8 := (_rtl_expr_355 ^^^ _rtl_expr_358)
  let _rtl_expr_360 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_359)
  let _rtl_expr_361 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_360)
  let _rtl_expr_362 : BitVec 8 := (_rtl_expr_361 ^^^ _rtl_expr_352)
  let _rtl_expr_363 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_362)
  let _rtl_expr_364 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_363)
  let _rtl_expr_365 : BitVec 8 := (_rtl_expr_351 ^^^ _rtl_expr_364)
  let _rtl_expr_366 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_365)
  let _rtl_expr_367 : BitVec 8 := BitVec.extractLsb 7 0 (((((env).2).1).2).1)
  let _rtl_expr_368 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_367)
  let _rtl_expr_369 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_368) (boolToBitVec (false))
  let _rtl_expr_370 : Bool := BitVec.getLsbD (_rtl_expr_367) 7
  let _rtl_expr_371 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_370)) (boolToBitVec (_rtl_expr_370))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_370)) (boolToBitVec (_rtl_expr_370)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_370)) (boolToBitVec (_rtl_expr_370))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_370)) (boolToBitVec (_rtl_expr_370))))
  let _rtl_expr_372 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_371)
  let _rtl_expr_373 : BitVec 8 := (_rtl_expr_369 ^^^ _rtl_expr_372)
  let _rtl_expr_374 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_373)
  let _rtl_expr_375 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_374)
  let _rtl_expr_376 : BitVec 8 := (_rtl_expr_375 ^^^ ((((env).2).1).2).1)
  let _rtl_expr_377 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_376)
  let _rtl_expr_378 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_377)
  let _rtl_expr_379 : BitVec 8 := (_rtl_expr_378 ^^^ ((((env).2).1).2).2)
  let _rtl_expr_380 : BitVec 8 := (_rtl_expr_379 ^^^ ((((env).2).2).1).1)
  let _rtl_expr_381 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_352)
  let _rtl_expr_382 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_381) (boolToBitVec (false))
  let _rtl_expr_383 : Bool := BitVec.getLsbD (_rtl_expr_352) 7
  (((((((env).1).1).1).1, (((((env).1).1).1).2, ((((env).1).1).2).1)), ((((((env).1).1).2).2, ((((env).1).2).1).1), (((((env).1).2).1).2, ((((env).1).2).2).1))), (((((((env).1).2).2).2, ((((env).2).1).1).1), (((((env).2).2).2).1, _rtl_expr_341)), ((_rtl_expr_366, _rtl_expr_380), (_rtl_expr_382, _rtl_expr_383))))

private def _rtl_eval_block_6 (s : aes_coreState) (i : aes_coreInputs) (env : (((Bool × (BitVec 128 × BitVec 128)) × ((Bool × BitVec 128) × (Bool × BitVec 128))) × (((BitVec 32 × BitVec 32) × (BitVec 8 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × Bool))))) : ((((Bool × BitVec 128) × (BitVec 128 × (Bool × BitVec 128))) × ((Bool × BitVec 128) × (BitVec 32 × (BitVec 32 × BitVec 32)))) × (((BitVec 8 × BitVec 8) × (BitVec 8 × (BitVec 8 × BitVec 8))) × ((BitVec 8 × BitVec 8) × (BitVec 8 × (BitVec 8 × BitVec 8))))) :=
  let _rtl_expr_384 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (((((env).2).2).2).2)) (boolToBitVec (((((env).2).2).2).2))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (((((env).2).2).2).2)) (boolToBitVec (((((env).2).2).2).2)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (((((env).2).2).2).2)) (boolToBitVec (((((env).2).2).2).2))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (((((env).2).2).2).2)) (boolToBitVec (((((env).2).2).2).2))))
  let _rtl_expr_385 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_384)
  let _rtl_expr_386 : BitVec 8 := (((((env).2).2).2).1 ^^^ _rtl_expr_385)
  let _rtl_expr_387 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_386)
  let _rtl_expr_388 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_387)
  let _rtl_expr_389 : BitVec 8 := (((((env).2).2).1).2 ^^^ _rtl_expr_388)
  let _rtl_expr_390 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_389)
  let _rtl_expr_391 : BitVec 32 := BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (((((env).2).1).2).1) (((((env).2).1).2).2)) (BitVec.append (n := 8) (m := 8) (((((env).2).2).1).1) (_rtl_expr_390))
  let _rtl_expr_392 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_391)
  let _rtl_expr_393 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_392)
  let _rtl_expr_394 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_393)
  let _rtl_expr_395 : BitVec 32 := BitVec.extractLsb 31 0 (((((env).1).2).2).2)
  let _rtl_expr_396 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_395)
  let _rtl_expr_397 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_396)
  let _rtl_expr_398 : BitVec 8 := BitVec.extractLsb 31 24 (_rtl_expr_397)
  let _rtl_expr_399 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_398)
  let _rtl_expr_400 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_399)
  let _rtl_expr_401 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_400)
  let _rtl_expr_402 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_401) (boolToBitVec (false))
  let _rtl_expr_403 : Bool := BitVec.getLsbD (_rtl_expr_400) 7
  let _rtl_expr_404 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_403)) (boolToBitVec (_rtl_expr_403))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_403)) (boolToBitVec (_rtl_expr_403)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_403)) (boolToBitVec (_rtl_expr_403))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_403)) (boolToBitVec (_rtl_expr_403))))
  let _rtl_expr_405 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_404)
  let _rtl_expr_406 : BitVec 8 := (_rtl_expr_402 ^^^ _rtl_expr_405)
  let _rtl_expr_407 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_406)
  let _rtl_expr_408 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_407)
  let _rtl_expr_409 : BitVec 8 := BitVec.extractLsb 23 16 (_rtl_expr_397)
  let _rtl_expr_410 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_409)
  let _rtl_expr_411 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_410)
  let _rtl_expr_412 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_411)
  let _rtl_expr_413 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_412)
  let _rtl_expr_414 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_413) (boolToBitVec (false))
  let _rtl_expr_415 : Bool := BitVec.getLsbD (_rtl_expr_412) 7
  let _rtl_expr_416 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_415)) (boolToBitVec (_rtl_expr_415))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_415)) (boolToBitVec (_rtl_expr_415)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_415)) (boolToBitVec (_rtl_expr_415))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_415)) (boolToBitVec (_rtl_expr_415))))
  let _rtl_expr_417 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_416)
  let _rtl_expr_418 : BitVec 8 := (_rtl_expr_414 ^^^ _rtl_expr_417)
  let _rtl_expr_419 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_418)
  let _rtl_expr_420 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_419)
  let _rtl_expr_421 : BitVec 8 := (_rtl_expr_420 ^^^ _rtl_expr_411)
  let _rtl_expr_422 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_421)
  let _rtl_expr_423 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_422)
  let _rtl_expr_424 : BitVec 8 := (_rtl_expr_408 ^^^ _rtl_expr_423)
  let _rtl_expr_425 : BitVec 8 := BitVec.extractLsb 15 8 (_rtl_expr_397)
  let _rtl_expr_426 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_425)
  let _rtl_expr_427 : BitVec 8 := (_rtl_expr_424 ^^^ _rtl_expr_426)
  let _rtl_expr_428 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_397)
  let _rtl_expr_429 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_428)
  let _rtl_expr_430 : BitVec 8 := (_rtl_expr_427 ^^^ _rtl_expr_429)
  let _rtl_expr_431 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_430)
  let _rtl_expr_432 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_411)
  let _rtl_expr_433 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_432) (boolToBitVec (false))
  let _rtl_expr_434 : Bool := BitVec.getLsbD (_rtl_expr_411) 7
  let _rtl_expr_435 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_434)) (boolToBitVec (_rtl_expr_434))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_434)) (boolToBitVec (_rtl_expr_434)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_434)) (boolToBitVec (_rtl_expr_434))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_434)) (boolToBitVec (_rtl_expr_434))))
  let _rtl_expr_436 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_435)
  let _rtl_expr_437 : BitVec 8 := (_rtl_expr_433 ^^^ _rtl_expr_436)
  let _rtl_expr_438 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_437)
  let _rtl_expr_439 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_438)
  let _rtl_expr_440 : BitVec 8 := (_rtl_expr_399 ^^^ _rtl_expr_439)
  let _rtl_expr_441 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_426)
  let _rtl_expr_442 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_441)
  let _rtl_expr_443 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_442)
  let _rtl_expr_444 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_443) (boolToBitVec (false))
  let _rtl_expr_445 : Bool := BitVec.getLsbD (_rtl_expr_442) 7
  let _rtl_expr_446 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_445)) (boolToBitVec (_rtl_expr_445))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_445)) (boolToBitVec (_rtl_expr_445)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_445)) (boolToBitVec (_rtl_expr_445))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_445)) (boolToBitVec (_rtl_expr_445))))
  let _rtl_expr_447 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_446)
  (((((((env).1).1).1, ((((env).1).1).2).1), (((((env).1).1).2).2, (((((env).1).2).1).1, ((((env).1).2).1).2))), ((((((env).1).2).2).1, ((((env).1).2).2).2), (((((env).2).1).1).1, (((((env).2).1).1).2, _rtl_expr_394)))), (((_rtl_expr_399, _rtl_expr_400), (_rtl_expr_410, (_rtl_expr_426, _rtl_expr_429))), ((_rtl_expr_431, _rtl_expr_440), (_rtl_expr_441, (_rtl_expr_444, _rtl_expr_447)))))

private def _rtl_eval_block_7 (s : aes_coreState) (i : aes_coreInputs) (env : ((((Bool × BitVec 128) × (BitVec 128 × (Bool × BitVec 128))) × ((Bool × BitVec 128) × (BitVec 32 × (BitVec 32 × BitVec 32)))) × (((BitVec 8 × BitVec 8) × (BitVec 8 × (BitVec 8 × BitVec 8))) × ((BitVec 8 × BitVec 8) × (BitVec 8 × (BitVec 8 × BitVec 8)))))) : (((Bool × BitVec 128) × (BitVec 128 × Bool)) × ((BitVec 128 × Bool) × (BitVec 128 × BitVec 128))) :=
  let _rtl_expr_448 : BitVec 8 := ((((((env).2).2).2).2).1 ^^^ (((((env).2).2).2).2).2)
  let _rtl_expr_449 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_448)
  let _rtl_expr_450 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_449)
  let _rtl_expr_451 : BitVec 8 := (_rtl_expr_450 ^^^ ((((env).2).2).2).1)
  let _rtl_expr_452 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_451)
  let _rtl_expr_453 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_452)
  let _rtl_expr_454 : BitVec 8 := (((((env).2).2).1).2 ^^^ _rtl_expr_453)
  let _rtl_expr_455 : BitVec 8 := (_rtl_expr_454 ^^^ (((((env).2).1).2).2).2)
  let _rtl_expr_456 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_455)
  let _rtl_expr_457 : BitVec 8 := (((((env).2).1).1).1 ^^^ ((((env).2).1).2).1)
  let _rtl_expr_458 : BitVec 7 := BitVec.extractLsb 6 0 (((((env).2).2).2).1)
  let _rtl_expr_459 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_458) (boolToBitVec (false))
  let _rtl_expr_460 : Bool := BitVec.getLsbD (((((env).2).2).2).1) 7
  let _rtl_expr_461 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_460)) (boolToBitVec (_rtl_expr_460))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_460)) (boolToBitVec (_rtl_expr_460)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_460)) (boolToBitVec (_rtl_expr_460))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_460)) (boolToBitVec (_rtl_expr_460))))
  let _rtl_expr_462 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_461)
  let _rtl_expr_463 : BitVec 8 := (_rtl_expr_459 ^^^ _rtl_expr_462)
  let _rtl_expr_464 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_463)
  let _rtl_expr_465 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_464)
  let _rtl_expr_466 : BitVec 8 := (_rtl_expr_457 ^^^ _rtl_expr_465)
  let _rtl_expr_467 : BitVec 8 := BitVec.extractLsb 7 0 ((((((env).2).1).2).2).2)
  let _rtl_expr_468 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_467)
  let _rtl_expr_469 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_468)
  let _rtl_expr_470 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_469) (boolToBitVec (false))
  let _rtl_expr_471 : Bool := BitVec.getLsbD (_rtl_expr_468) 7
  let _rtl_expr_472 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_471)) (boolToBitVec (_rtl_expr_471))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_471)) (boolToBitVec (_rtl_expr_471)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_471)) (boolToBitVec (_rtl_expr_471))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_471)) (boolToBitVec (_rtl_expr_471))))
  let _rtl_expr_473 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_472)
  let _rtl_expr_474 : BitVec 8 := (_rtl_expr_470 ^^^ _rtl_expr_473)
  let _rtl_expr_475 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_474)
  let _rtl_expr_476 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_475)
  let _rtl_expr_477 : BitVec 8 := (_rtl_expr_476 ^^^ _rtl_expr_467)
  let _rtl_expr_478 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_477)
  let _rtl_expr_479 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_478)
  let _rtl_expr_480 : BitVec 8 := (_rtl_expr_466 ^^^ _rtl_expr_479)
  let _rtl_expr_481 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_480)
  let _rtl_expr_482 : BitVec 8 := BitVec.extractLsb 7 0 (((((env).2).1).1).2)
  let _rtl_expr_483 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_482)
  let _rtl_expr_484 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_483) (boolToBitVec (false))
  let _rtl_expr_485 : Bool := BitVec.getLsbD (_rtl_expr_482) 7
  let _rtl_expr_486 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_485)) (boolToBitVec (_rtl_expr_485))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_485)) (boolToBitVec (_rtl_expr_485)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_485)) (boolToBitVec (_rtl_expr_485))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_485)) (boolToBitVec (_rtl_expr_485))))
  let _rtl_expr_487 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_486)
  let _rtl_expr_488 : BitVec 8 := (_rtl_expr_484 ^^^ _rtl_expr_487)
  let _rtl_expr_489 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_488)
  let _rtl_expr_490 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_489)
  let _rtl_expr_491 : BitVec 8 := (_rtl_expr_490 ^^^ ((((env).2).1).1).2)
  let _rtl_expr_492 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_491)
  let _rtl_expr_493 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_492)
  let _rtl_expr_494 : BitVec 8 := (_rtl_expr_493 ^^^ ((((env).2).1).2).1)
  let _rtl_expr_495 : BitVec 8 := (_rtl_expr_494 ^^^ (((((env).2).1).2).2).1)
  let _rtl_expr_496 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_467)
  let _rtl_expr_497 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_496) (boolToBitVec (false))
  let _rtl_expr_498 : Bool := BitVec.getLsbD (_rtl_expr_467) 7
  let _rtl_expr_499 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_498)) (boolToBitVec (_rtl_expr_498))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_498)) (boolToBitVec (_rtl_expr_498)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_498)) (boolToBitVec (_rtl_expr_498))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_498)) (boolToBitVec (_rtl_expr_498))))
  let _rtl_expr_500 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_499)
  let _rtl_expr_501 : BitVec 8 := (_rtl_expr_497 ^^^ _rtl_expr_500)
  let _rtl_expr_502 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_501)
  let _rtl_expr_503 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_502)
  let _rtl_expr_504 : BitVec 8 := (_rtl_expr_495 ^^^ _rtl_expr_503)
  let _rtl_expr_505 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_504)
  let _rtl_expr_506 : BitVec 32 := BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (((((env).2).2).1).1) (_rtl_expr_456)) (BitVec.append (n := 8) (m := 8) (_rtl_expr_481) (_rtl_expr_505))
  let _rtl_expr_507 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_506)
  let _rtl_expr_508 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_507)
  let _rtl_expr_509 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_508)
  let _rtl_expr_510 : BitVec 128 := BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (((((env).1).2).2).1) ((((((env).1).2).2).2).1)) (BitVec.append (n := 32) (m := 32) ((((((env).1).2).2).2).2) (_rtl_expr_509))
  let _rtl_expr_511 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_510)
  (((((((env).1).1).1).1, ((((env).1).1).1).2), (((((env).1).1).2).1, (((((env).1).1).2).2).1)), (((((((env).1).1).2).2).2, ((((env).1).2).1).1), (((((env).1).2).1).2, _rtl_expr_511)))

private def _rtl_eval_block_8 (s : aes_coreState) (i : aes_coreInputs) (env : (((Bool × BitVec 128) × (BitVec 128 × Bool)) × ((BitVec 128 × Bool) × (BitVec 128 × BitVec 128)))) : BitVec 128 :=
  let _rtl_expr_512 : BitVec 128 := BitVec.extractLsb 127 0 ((((env).2).2).2)
  let _rtl_expr_513 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_512)
  let _rtl_expr_514 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_513)
  let _rtl_expr_515 : BitVec 128 := (_rtl_expr_514 ^^^ (((env).1).1).2)
  let _rtl_expr_516 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_515)
  let _rtl_expr_517 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_516)
  let _rtl_expr_518 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_517)
  let _rtl_expr_519 : Bool := decide ((s.enc_block__update_type).toNat = (BitVec.ofNat 3 4).toNat)
  let _rtl_expr_520 : BitVec 128 := ((((env).2).2).1 ^^^ (((env).1).1).2)
  let _rtl_expr_521 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_520)
  let _rtl_expr_522 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_521)
  let _rtl_expr_523 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_522)
  let _rtl_expr_524 : BitVec 128 := (if _rtl_expr_519 then _rtl_expr_523 else BitVec.ofNat 128 0)
  let _rtl_expr_525 : BitVec 128 := (if (((env).2).1).2 then _rtl_expr_518 else _rtl_expr_524)
  let _rtl_expr_526 : BitVec 128 := (if (((env).1).2).2 then (((env).2).1).1 else _rtl_expr_525)
  let _rtl_expr_527 : BitVec 128 := (if (((env).1).1).1 then (((env).1).2).1 else _rtl_expr_526)
  _rtl_expr_527

/-- 组合逻辑：proc_alwayscomb__assignment_0 -/
def proc_alwayscomb__assignment_0 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_block__block_new := _rtl_eval_block_8 s i (_rtl_eval_block_7 s i (_rtl_eval_block_6 s i (_rtl_eval_block_5 s i (_rtl_eval_block_4 s i (_rtl_eval_block_3 s i (_rtl_eval_block_2 s i (_rtl_eval_block_1 s i (_rtl_eval_block_0 s i (())))))))))
  { s with
    enc_block__block_new := enc_block__block_new
  }

/-- 组合逻辑：proc_alwayscomb__assignment_1 -/
def proc_alwayscomb__assignment_1 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_block__block_w0_we := (if decide ((s.enc_block__update_type).toNat = (BitVec.ofNat 3 1).toNat) then true else (if decide ((s.enc_block__update_type).toNat = (BitVec.ofNat 3 2).toNat) then (if decide ((s.enc_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 0).toNat) then true else false) else (if decide ((s.enc_block__update_type).toNat = (BitVec.ofNat 3 3).toNat) then true else (if decide ((s.enc_block__update_type).toNat = (BitVec.ofNat 3 4).toNat) then true else false))))
  { s with
    enc_block__block_w0_we := enc_block__block_w0_we
  }

/-- 组合逻辑：proc_alwayscomb__assignment_2 -/
def proc_alwayscomb__assignment_2 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_block__block_w1_we := (if decide ((s.enc_block__update_type).toNat = (BitVec.ofNat 3 1).toNat) then true else (if decide ((s.enc_block__update_type).toNat = (BitVec.ofNat 3 2).toNat) then (if decide ((s.enc_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 0).toNat) then false else (if decide ((s.enc_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 1).toNat) then true else false)) else (if decide ((s.enc_block__update_type).toNat = (BitVec.ofNat 3 3).toNat) then true else (if decide ((s.enc_block__update_type).toNat = (BitVec.ofNat 3 4).toNat) then true else false))))
  { s with
    enc_block__block_w1_we := enc_block__block_w1_we
  }

/-- 组合逻辑：proc_alwayscomb__assignment_3 -/
def proc_alwayscomb__assignment_3 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_block__block_w2_we := (if decide ((s.enc_block__update_type).toNat = (BitVec.ofNat 3 1).toNat) then true else (if decide ((s.enc_block__update_type).toNat = (BitVec.ofNat 3 2).toNat) then (if decide ((s.enc_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 0).toNat) then false else (if decide ((s.enc_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 1).toNat) then false else (if decide ((s.enc_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 2).toNat) then true else false))) else (if decide ((s.enc_block__update_type).toNat = (BitVec.ofNat 3 3).toNat) then true else (if decide ((s.enc_block__update_type).toNat = (BitVec.ofNat 3 4).toNat) then true else false))))
  { s with
    enc_block__block_w2_we := enc_block__block_w2_we
  }

/-- 组合逻辑：proc_alwayscomb__assignment_4 -/
def proc_alwayscomb__assignment_4 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_block__block_w3_we := (if decide ((s.enc_block__update_type).toNat = (BitVec.ofNat 3 1).toNat) then true else (if decide ((s.enc_block__update_type).toNat = (BitVec.ofNat 3 2).toNat) then (if decide ((s.enc_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 0).toNat) then false else (if decide ((s.enc_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 1).toNat) then false else (if decide ((s.enc_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 2).toNat) then false else (if decide ((s.enc_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 3).toNat) then true else false)))) else (if decide ((s.enc_block__update_type).toNat = (BitVec.ofNat 3 3).toNat) then true else (if decide ((s.enc_block__update_type).toNat = (BitVec.ofNat 3 4).toNat) then true else false))))
  { s with
    enc_block__block_w3_we := enc_block__block_w3_we
  }

/-- 组合逻辑：proc_alwayscomb__assignment_5 -/
def proc_alwayscomb__assignment_5 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_block__muxed_sboxw := (if decide ((s.enc_block__update_type).toNat = (BitVec.ofNat 3 1).toNat) then BitVec.ofNat 32 0 else (if decide ((s.enc_block__update_type).toNat = (BitVec.ofNat 3 2).toNat) then (if decide ((s.enc_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 0).toNat) then s.enc_block__block_w0_reg else (if decide ((s.enc_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 1).toNat) then s.enc_block__block_w1_reg else (if decide ((s.enc_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 2).toNat) then s.enc_block__block_w2_reg else (if decide ((s.enc_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 3).toNat) then s.enc_block__block_w3_reg else BitVec.ofNat 32 0)))) else BitVec.ofNat 32 0))
  { s with
    enc_block__muxed_sboxw := enc_block__muxed_sboxw
  }

/-- 组合逻辑：proc_alwayscomb_1__assignment_0 -/
def proc_alwayscomb_1__assignment_0 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_block__sword_ctr_new := (if s.enc_block__sword_ctr_rst then BitVec.ofNat 2 0 else (if s.enc_block__sword_ctr_inc then (s.enc_block__sword_ctr_reg + BitVec.ofNat 2 1) else BitVec.ofNat 2 0))
  { s with
    enc_block__sword_ctr_new := enc_block__sword_ctr_new
  }

/-- 组合逻辑：proc_alwayscomb_1__assignment_1 -/
def proc_alwayscomb_1__assignment_1 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_block__sword_ctr_we := (if s.enc_block__sword_ctr_rst then true else (if s.enc_block__sword_ctr_inc then true else false))
  { s with
    enc_block__sword_ctr_we := enc_block__sword_ctr_we
  }

/-- 组合逻辑：proc_alwayscomb_2__assignment_0 -/
def proc_alwayscomb_2__assignment_0 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_block__round_ctr_new := (if s.enc_block__round_ctr_rst then BitVec.ofNat 4 0 else (if s.enc_block__round_ctr_inc then (s.enc_block__round_ctr_reg + BitVec.ofNat 4 1) else BitVec.ofNat 4 0))
  { s with
    enc_block__round_ctr_new := enc_block__round_ctr_new
  }

/-- 组合逻辑：proc_alwayscomb_2__assignment_1 -/
def proc_alwayscomb_2__assignment_1 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_block__round_ctr_we := (if s.enc_block__round_ctr_rst then true else (if s.enc_block__round_ctr_inc then true else false))
  { s with
    enc_block__round_ctr_we := enc_block__round_ctr_we
  }

/-- 组合逻辑：proc_alwayscomb_3__assignment_0 -/
def proc_alwayscomb_3__assignment_0 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_block__enc_ctrl_new := (if decide ((s.enc_block__enc_ctrl_reg).toNat = (BitVec.ofNat 2 0).toNat) then (if s.enc_block__next then BitVec.ofNat 2 1 else BitVec.ofNat 2 0) else (if decide ((s.enc_block__enc_ctrl_reg).toNat = (BitVec.ofNat 2 1).toNat) then BitVec.ofNat 2 2 else (if decide ((s.enc_block__enc_ctrl_reg).toNat = (BitVec.ofNat 2 2).toNat) then (if decide ((s.enc_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 3).toNat) then BitVec.ofNat 2 3 else BitVec.ofNat 2 0) else (if decide ((s.enc_block__enc_ctrl_reg).toNat = (BitVec.ofNat 2 3).toNat) then (if decide ((s.enc_block__round_ctr_reg).toNat < ((if decide (boolToNat (s.enc_block__keylen) = boolToNat (true)) then BitVec.extractLsb 3 0 (BitVec.ofNat 4 14) else BitVec.extractLsb 3 0 (BitVec.ofNat 4 10))).toNat) then BitVec.ofNat 2 2 else BitVec.ofNat 2 0) else BitVec.ofNat 2 0))))
  { s with
    enc_block__enc_ctrl_new := enc_block__enc_ctrl_new
  }

/-- 组合逻辑：proc_alwayscomb_3__assignment_1 -/
def proc_alwayscomb_3__assignment_1 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_block__enc_ctrl_we := (if decide ((s.enc_block__enc_ctrl_reg).toNat = (BitVec.ofNat 2 0).toNat) then (if s.enc_block__next then true else false) else (if decide ((s.enc_block__enc_ctrl_reg).toNat = (BitVec.ofNat 2 1).toNat) then true else (if decide ((s.enc_block__enc_ctrl_reg).toNat = (BitVec.ofNat 2 2).toNat) then (if decide ((s.enc_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 3).toNat) then true else false) else (if decide ((s.enc_block__enc_ctrl_reg).toNat = (BitVec.ofNat 2 3).toNat) then true else false))))
  { s with
    enc_block__enc_ctrl_we := enc_block__enc_ctrl_we
  }

/-- 组合逻辑：proc_alwayscomb_3__assignment_2 -/
def proc_alwayscomb_3__assignment_2 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_block__ready_new := (if decide ((s.enc_block__enc_ctrl_reg).toNat = (BitVec.ofNat 2 0).toNat) then false else (if decide ((s.enc_block__enc_ctrl_reg).toNat = (BitVec.ofNat 2 1).toNat) then false else (if decide ((s.enc_block__enc_ctrl_reg).toNat = (BitVec.ofNat 2 2).toNat) then false else (if decide ((s.enc_block__enc_ctrl_reg).toNat = (BitVec.ofNat 2 3).toNat) then (if decide ((s.enc_block__round_ctr_reg).toNat < ((if decide (boolToNat (s.enc_block__keylen) = boolToNat (true)) then BitVec.extractLsb 3 0 (BitVec.ofNat 4 14) else BitVec.extractLsb 3 0 (BitVec.ofNat 4 10))).toNat) then false else true) else false))))
  { s with
    enc_block__ready_new := enc_block__ready_new
  }

/-- 组合逻辑：proc_alwayscomb_3__assignment_3 -/
def proc_alwayscomb_3__assignment_3 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_block__ready_we := (if decide ((s.enc_block__enc_ctrl_reg).toNat = (BitVec.ofNat 2 0).toNat) then (if s.enc_block__next then true else false) else (if decide ((s.enc_block__enc_ctrl_reg).toNat = (BitVec.ofNat 2 1).toNat) then false else (if decide ((s.enc_block__enc_ctrl_reg).toNat = (BitVec.ofNat 2 2).toNat) then false else (if decide ((s.enc_block__enc_ctrl_reg).toNat = (BitVec.ofNat 2 3).toNat) then (if decide ((s.enc_block__round_ctr_reg).toNat < ((if decide (boolToNat (s.enc_block__keylen) = boolToNat (true)) then BitVec.extractLsb 3 0 (BitVec.ofNat 4 14) else BitVec.extractLsb 3 0 (BitVec.ofNat 4 10))).toNat) then false else true) else false))))
  { s with
    enc_block__ready_we := enc_block__ready_we
  }

/-- 组合逻辑：proc_alwayscomb_3__assignment_4 -/
def proc_alwayscomb_3__assignment_4 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_block__round_ctr_inc := (if decide ((s.enc_block__enc_ctrl_reg).toNat = (BitVec.ofNat 2 0).toNat) then false else (if decide ((s.enc_block__enc_ctrl_reg).toNat = (BitVec.ofNat 2 1).toNat) then true else (if decide ((s.enc_block__enc_ctrl_reg).toNat = (BitVec.ofNat 2 2).toNat) then false else (if decide ((s.enc_block__enc_ctrl_reg).toNat = (BitVec.ofNat 2 3).toNat) then true else false))))
  { s with
    enc_block__round_ctr_inc := enc_block__round_ctr_inc
  }

/-- 组合逻辑：proc_alwayscomb_3__assignment_5 -/
def proc_alwayscomb_3__assignment_5 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_block__round_ctr_rst := (if decide ((s.enc_block__enc_ctrl_reg).toNat = (BitVec.ofNat 2 0).toNat) then (if s.enc_block__next then true else false) else false)
  { s with
    enc_block__round_ctr_rst := enc_block__round_ctr_rst
  }

/-- 组合逻辑：proc_alwayscomb_3__assignment_6 -/
def proc_alwayscomb_3__assignment_6 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_block__sword_ctr_inc := (if decide ((s.enc_block__enc_ctrl_reg).toNat = (BitVec.ofNat 2 0).toNat) then false else (if decide ((s.enc_block__enc_ctrl_reg).toNat = (BitVec.ofNat 2 1).toNat) then false else (if decide ((s.enc_block__enc_ctrl_reg).toNat = (BitVec.ofNat 2 2).toNat) then true else false)))
  { s with
    enc_block__sword_ctr_inc := enc_block__sword_ctr_inc
  }

/-- 组合逻辑：proc_alwayscomb_3__assignment_7 -/
def proc_alwayscomb_3__assignment_7 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_block__sword_ctr_rst := (if decide ((s.enc_block__enc_ctrl_reg).toNat = (BitVec.ofNat 2 0).toNat) then false else (if decide ((s.enc_block__enc_ctrl_reg).toNat = (BitVec.ofNat 2 1).toNat) then true else (if decide ((s.enc_block__enc_ctrl_reg).toNat = (BitVec.ofNat 2 2).toNat) then false else (if decide ((s.enc_block__enc_ctrl_reg).toNat = (BitVec.ofNat 2 3).toNat) then true else false))))
  { s with
    enc_block__sword_ctr_rst := enc_block__sword_ctr_rst
  }

/-- 组合逻辑：proc_alwayscomb_3__assignment_8 -/
def proc_alwayscomb_3__assignment_8 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_block__update_type := (if decide ((s.enc_block__enc_ctrl_reg).toNat = (BitVec.ofNat 2 0).toNat) then BitVec.ofNat 3 0 else (if decide ((s.enc_block__enc_ctrl_reg).toNat = (BitVec.ofNat 2 1).toNat) then BitVec.ofNat 3 1 else (if decide ((s.enc_block__enc_ctrl_reg).toNat = (BitVec.ofNat 2 2).toNat) then BitVec.ofNat 3 2 else (if decide ((s.enc_block__enc_ctrl_reg).toNat = (BitVec.ofNat 2 3).toNat) then (if decide ((s.enc_block__round_ctr_reg).toNat < ((if decide (boolToNat (s.enc_block__keylen) = boolToNat (true)) then BitVec.extractLsb 3 0 (BitVec.ofNat 4 14) else BitVec.extractLsb 3 0 (BitVec.ofNat 4 10))).toNat) then BitVec.ofNat 3 3 else BitVec.ofNat 3 4) else BitVec.ofNat 3 0))))
  { s with
    enc_block__update_type := enc_block__update_type
  }

private def _rtl_eval_block_9 (s : aes_coreState) (i : aes_coreInputs) (env : Unit) : (((Bool × BitVec 128) × (Bool × (BitVec 128 × Bool))) × ((BitVec 128 × (BitVec 128 × BitVec 32)) × (BitVec 8 × (BitVec 8 × BitVec 8)))) :=
  let _rtl_expr_0 : Bool := decide ((s.dec_block__update_type).toNat = (BitVec.ofNat 3 1).toNat)
  let _rtl_expr_1 : BitVec 128 := BitVec.extractLsb 127 0 (s.dec_block__block)
  let _rtl_expr_2 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_1)
  let _rtl_expr_3 : BitVec 128 := BitVec.extractLsb 127 0 (s.dec_block__round_key)
  let _rtl_expr_4 : BitVec 128 := (_rtl_expr_2 ^^^ _rtl_expr_3)
  let _rtl_expr_5 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_4)
  let _rtl_expr_6 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_5)
  let _rtl_expr_7 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_6)
  let _rtl_expr_8 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_7)
  let _rtl_expr_9 : BitVec 32 := BitVec.extractLsb 127 96 (_rtl_expr_8)
  let _rtl_expr_10 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_9)
  let _rtl_expr_11 : BitVec 8 := BitVec.extractLsb 31 24 (_rtl_expr_10)
  let _rtl_expr_12 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_8)
  let _rtl_expr_13 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_12)
  let _rtl_expr_14 : BitVec 8 := BitVec.extractLsb 23 16 (_rtl_expr_13)
  let _rtl_expr_15 : BitVec 32 := BitVec.extractLsb 63 32 (_rtl_expr_8)
  let _rtl_expr_16 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_15)
  let _rtl_expr_17 : BitVec 8 := BitVec.extractLsb 15 8 (_rtl_expr_16)
  let _rtl_expr_18 : BitVec 32 := BitVec.extractLsb 95 64 (_rtl_expr_8)
  let _rtl_expr_19 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_18)
  let _rtl_expr_20 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_19)
  let _rtl_expr_21 : BitVec 32 := BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (_rtl_expr_11) (_rtl_expr_14)) (BitVec.append (n := 8) (m := 8) (_rtl_expr_17) (_rtl_expr_20))
  let _rtl_expr_22 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_21)
  let _rtl_expr_23 : BitVec 8 := BitVec.extractLsb 31 24 (_rtl_expr_19)
  let _rtl_expr_24 : BitVec 8 := BitVec.extractLsb 23 16 (_rtl_expr_10)
  let _rtl_expr_25 : BitVec 8 := BitVec.extractLsb 15 8 (_rtl_expr_13)
  let _rtl_expr_26 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_16)
  let _rtl_expr_27 : BitVec 32 := BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (_rtl_expr_23) (_rtl_expr_24)) (BitVec.append (n := 8) (m := 8) (_rtl_expr_25) (_rtl_expr_26))
  let _rtl_expr_28 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_27)
  let _rtl_expr_29 : BitVec 8 := BitVec.extractLsb 31 24 (_rtl_expr_16)
  let _rtl_expr_30 : BitVec 8 := BitVec.extractLsb 23 16 (_rtl_expr_19)
  let _rtl_expr_31 : BitVec 8 := BitVec.extractLsb 15 8 (_rtl_expr_10)
  let _rtl_expr_32 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_13)
  let _rtl_expr_33 : BitVec 32 := BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (_rtl_expr_29) (_rtl_expr_30)) (BitVec.append (n := 8) (m := 8) (_rtl_expr_31) (_rtl_expr_32))
  let _rtl_expr_34 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_33)
  let _rtl_expr_35 : BitVec 8 := BitVec.extractLsb 31 24 (_rtl_expr_13)
  let _rtl_expr_36 : BitVec 8 := BitVec.extractLsb 23 16 (_rtl_expr_16)
  let _rtl_expr_37 : BitVec 8 := BitVec.extractLsb 15 8 (_rtl_expr_19)
  let _rtl_expr_38 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_10)
  let _rtl_expr_39 : BitVec 32 := BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (_rtl_expr_35) (_rtl_expr_36)) (BitVec.append (n := 8) (m := 8) (_rtl_expr_37) (_rtl_expr_38))
  let _rtl_expr_40 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_39)
  let _rtl_expr_41 : BitVec 128 := BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (_rtl_expr_22) (_rtl_expr_28)) (BitVec.append (n := 32) (m := 32) (_rtl_expr_34) (_rtl_expr_40))
  let _rtl_expr_42 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_41)
  let _rtl_expr_43 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_42)
  let _rtl_expr_44 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_43)
  let _rtl_expr_45 : Bool := decide ((s.dec_block__update_type).toNat = (BitVec.ofNat 3 2).toNat)
  let _rtl_expr_46 : BitVec 128 := BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (s.dec_block__new_sboxw) (s.dec_block__new_sboxw)) (BitVec.append (n := 32) (m := 32) (s.dec_block__new_sboxw) (s.dec_block__new_sboxw))
  let _rtl_expr_47 : Bool := decide ((s.dec_block__update_type).toNat = (BitVec.ofNat 3 3).toNat)
  let _rtl_expr_48 : BitVec 128 := BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (s.dec_block__block_w0_reg) (s.dec_block__block_w1_reg)) (BitVec.append (n := 32) (m := 32) (s.dec_block__block_w2_reg) (s.dec_block__block_w3_reg))
  let _rtl_expr_49 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_48)
  let _rtl_expr_50 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_49)
  let _rtl_expr_51 : BitVec 128 := (_rtl_expr_50 ^^^ _rtl_expr_3)
  let _rtl_expr_52 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_51)
  let _rtl_expr_53 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_52)
  let _rtl_expr_54 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_53)
  let _rtl_expr_55 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_54)
  let _rtl_expr_56 : BitVec 32 := BitVec.extractLsb 127 96 (_rtl_expr_55)
  let _rtl_expr_57 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_56)
  let _rtl_expr_58 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_57)
  let _rtl_expr_59 : BitVec 8 := BitVec.extractLsb 31 24 (_rtl_expr_58)
  let _rtl_expr_60 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_59)
  let _rtl_expr_61 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_60)
  let _rtl_expr_62 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_61)
  let _rtl_expr_63 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_62)
  (((_rtl_expr_0, _rtl_expr_44), (_rtl_expr_45, (_rtl_expr_46, _rtl_expr_47))), ((_rtl_expr_53, (_rtl_expr_55, _rtl_expr_58)), (_rtl_expr_61, (_rtl_expr_62, _rtl_expr_63))))

private def _rtl_eval_block_10 (s : aes_coreState) (i : aes_coreInputs) (env : (((Bool × BitVec 128) × (Bool × (BitVec 128 × Bool))) × ((BitVec 128 × (BitVec 128 × BitVec 32)) × (BitVec 8 × (BitVec 8 × BitVec 8))))) : (((Bool × (BitVec 128 × Bool)) × ((BitVec 128 × Bool) × (BitVec 128 × BitVec 128))) × ((BitVec 32 × (BitVec 8 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8)))) :=
  let _rtl_expr_64 : BitVec 8 := BitVec.extractLsb 7 0 (((((env).2).2).2).2)
  let _rtl_expr_65 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_64)
  let _rtl_expr_66 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_65) (boolToBitVec (false))
  let _rtl_expr_67 : Bool := BitVec.getLsbD (_rtl_expr_64) 7
  let _rtl_expr_68 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_67)) (boolToBitVec (_rtl_expr_67))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_67)) (boolToBitVec (_rtl_expr_67)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_67)) (boolToBitVec (_rtl_expr_67))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_67)) (boolToBitVec (_rtl_expr_67))))
  let _rtl_expr_69 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_68)
  let _rtl_expr_70 : BitVec 8 := (_rtl_expr_66 ^^^ _rtl_expr_69)
  let _rtl_expr_71 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_70)
  let _rtl_expr_72 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_71)
  let _rtl_expr_73 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_72)
  let _rtl_expr_74 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_73)
  let _rtl_expr_75 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_74) (boolToBitVec (false))
  let _rtl_expr_76 : Bool := BitVec.getLsbD (_rtl_expr_73) 7
  let _rtl_expr_77 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_76)) (boolToBitVec (_rtl_expr_76))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_76)) (boolToBitVec (_rtl_expr_76)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_76)) (boolToBitVec (_rtl_expr_76))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_76)) (boolToBitVec (_rtl_expr_76))))
  let _rtl_expr_78 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_77)
  let _rtl_expr_79 : BitVec 8 := (_rtl_expr_75 ^^^ _rtl_expr_78)
  let _rtl_expr_80 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_79)
  let _rtl_expr_81 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_80)
  let _rtl_expr_82 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_81)
  let _rtl_expr_83 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_82)
  let _rtl_expr_84 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_83)
  let _rtl_expr_85 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_84)
  let _rtl_expr_86 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_85) (boolToBitVec (false))
  let _rtl_expr_87 : Bool := BitVec.getLsbD (_rtl_expr_84) 7
  let _rtl_expr_88 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_87)) (boolToBitVec (_rtl_expr_87))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_87)) (boolToBitVec (_rtl_expr_87)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_87)) (boolToBitVec (_rtl_expr_87))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_87)) (boolToBitVec (_rtl_expr_87))))
  let _rtl_expr_89 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_88)
  let _rtl_expr_90 : BitVec 8 := (_rtl_expr_86 ^^^ _rtl_expr_89)
  let _rtl_expr_91 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_90)
  let _rtl_expr_92 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_91)
  let _rtl_expr_93 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_92)
  let _rtl_expr_94 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_93)
  let _rtl_expr_95 : BitVec 7 := BitVec.extractLsb 6 0 (((((env).2).2).2).2)
  let _rtl_expr_96 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_95) (boolToBitVec (false))
  let _rtl_expr_97 : Bool := BitVec.getLsbD (((((env).2).2).2).2) 7
  let _rtl_expr_98 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_97)) (boolToBitVec (_rtl_expr_97))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_97)) (boolToBitVec (_rtl_expr_97)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_97)) (boolToBitVec (_rtl_expr_97))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_97)) (boolToBitVec (_rtl_expr_97))))
  let _rtl_expr_99 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_98)
  let _rtl_expr_100 : BitVec 8 := (_rtl_expr_96 ^^^ _rtl_expr_99)
  let _rtl_expr_101 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_100)
  let _rtl_expr_102 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_101)
  let _rtl_expr_103 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_102)
  let _rtl_expr_104 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_103)
  let _rtl_expr_105 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_104) (boolToBitVec (false))
  let _rtl_expr_106 : Bool := BitVec.getLsbD (_rtl_expr_103) 7
  let _rtl_expr_107 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_106)) (boolToBitVec (_rtl_expr_106))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_106)) (boolToBitVec (_rtl_expr_106)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_106)) (boolToBitVec (_rtl_expr_106))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_106)) (boolToBitVec (_rtl_expr_106))))
  let _rtl_expr_108 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_107)
  let _rtl_expr_109 : BitVec 8 := (_rtl_expr_105 ^^^ _rtl_expr_108)
  let _rtl_expr_110 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_109)
  let _rtl_expr_111 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_110)
  let _rtl_expr_112 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_111)
  let _rtl_expr_113 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_112)
  let _rtl_expr_114 : BitVec 8 := (_rtl_expr_94 ^^^ _rtl_expr_113)
  let _rtl_expr_115 : BitVec 7 := BitVec.extractLsb 6 0 (((((env).2).2).2).1)
  let _rtl_expr_116 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_115) (boolToBitVec (false))
  let _rtl_expr_117 : Bool := BitVec.getLsbD (((((env).2).2).2).1) 7
  let _rtl_expr_118 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_117)) (boolToBitVec (_rtl_expr_117))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_117)) (boolToBitVec (_rtl_expr_117)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_117)) (boolToBitVec (_rtl_expr_117))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_117)) (boolToBitVec (_rtl_expr_117))))
  let _rtl_expr_119 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_118)
  let _rtl_expr_120 : BitVec 8 := (_rtl_expr_116 ^^^ _rtl_expr_119)
  let _rtl_expr_121 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_120)
  let _rtl_expr_122 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_121)
  let _rtl_expr_123 : BitVec 8 := (_rtl_expr_114 ^^^ _rtl_expr_122)
  let _rtl_expr_124 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_123)
  let _rtl_expr_125 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_124)
  let _rtl_expr_126 : BitVec 8 := BitVec.extractLsb 23 16 (((((env).2).1).2).2)
  let _rtl_expr_127 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_126)
  ((((((env).1).1).1, ((((env).1).1).2, (((env).1).2).1)), ((((((env).1).2).2).1, ((((env).1).2).2).2), ((((env).2).1).1, ((((env).2).1).2).1))), ((((((env).2).1).2).2, ((((env).2).2).1, _rtl_expr_94)), ((_rtl_expr_114, _rtl_expr_122), (_rtl_expr_125, _rtl_expr_127))))

private def _rtl_eval_block_11 (s : aes_coreState) (i : aes_coreInputs) (env : (((Bool × (BitVec 128 × Bool)) × ((BitVec 128 × Bool) × (BitVec 128 × BitVec 128))) × ((BitVec 32 × (BitVec 8 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8))))) : ((((Bool × BitVec 128) × (Bool × (BitVec 128 × Bool))) × ((BitVec 128 × (BitVec 128 × BitVec 32)) × (BitVec 8 × (BitVec 8 × BitVec 8)))) × (((BitVec 8 × BitVec 8) × (BitVec 8 × (BitVec 8 × BitVec 8))) × ((BitVec 8 × (BitVec 8 × BitVec 8)) × (BitVec 8 × (BitVec 8 × BitVec 8))))) :=
  let _rtl_expr_128 : BitVec 8 := BitVec.extractLsb 7 0 (((((env).2).2).2).2)
  let _rtl_expr_129 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_128)
  let _rtl_expr_130 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_129)
  let _rtl_expr_131 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_130)
  let _rtl_expr_132 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_131)
  let _rtl_expr_133 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_132) (boolToBitVec (false))
  let _rtl_expr_134 : Bool := BitVec.getLsbD (_rtl_expr_131) 7
  let _rtl_expr_135 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_134)) (boolToBitVec (_rtl_expr_134))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_134)) (boolToBitVec (_rtl_expr_134)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_134)) (boolToBitVec (_rtl_expr_134))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_134)) (boolToBitVec (_rtl_expr_134))))
  let _rtl_expr_136 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_135)
  let _rtl_expr_137 : BitVec 8 := (_rtl_expr_133 ^^^ _rtl_expr_136)
  let _rtl_expr_138 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_137)
  let _rtl_expr_139 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_138)
  let _rtl_expr_140 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_139)
  let _rtl_expr_141 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_140)
  let _rtl_expr_142 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_141) (boolToBitVec (false))
  let _rtl_expr_143 : Bool := BitVec.getLsbD (_rtl_expr_140) 7
  let _rtl_expr_144 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_143)) (boolToBitVec (_rtl_expr_143))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_143)) (boolToBitVec (_rtl_expr_143)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_143)) (boolToBitVec (_rtl_expr_143))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_143)) (boolToBitVec (_rtl_expr_143))))
  let _rtl_expr_145 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_144)
  let _rtl_expr_146 : BitVec 8 := (_rtl_expr_142 ^^^ _rtl_expr_145)
  let _rtl_expr_147 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_146)
  let _rtl_expr_148 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_147)
  let _rtl_expr_149 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_148)
  let _rtl_expr_150 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_149)
  let _rtl_expr_151 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_150)
  let _rtl_expr_152 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_151)
  let _rtl_expr_153 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_152) (boolToBitVec (false))
  let _rtl_expr_154 : Bool := BitVec.getLsbD (_rtl_expr_151) 7
  let _rtl_expr_155 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_154)) (boolToBitVec (_rtl_expr_154))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_154)) (boolToBitVec (_rtl_expr_154)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_154)) (boolToBitVec (_rtl_expr_154))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_154)) (boolToBitVec (_rtl_expr_154))))
  let _rtl_expr_156 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_155)
  let _rtl_expr_157 : BitVec 8 := (_rtl_expr_153 ^^^ _rtl_expr_156)
  let _rtl_expr_158 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_157)
  let _rtl_expr_159 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_158)
  let _rtl_expr_160 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_159)
  let _rtl_expr_161 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_160)
  let _rtl_expr_162 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_129)
  let _rtl_expr_163 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_162) (boolToBitVec (false))
  let _rtl_expr_164 : Bool := BitVec.getLsbD (_rtl_expr_129) 7
  let _rtl_expr_165 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_164)) (boolToBitVec (_rtl_expr_164))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_164)) (boolToBitVec (_rtl_expr_164)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_164)) (boolToBitVec (_rtl_expr_164))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_164)) (boolToBitVec (_rtl_expr_164))))
  let _rtl_expr_166 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_165)
  let _rtl_expr_167 : BitVec 8 := (_rtl_expr_163 ^^^ _rtl_expr_166)
  let _rtl_expr_168 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_167)
  let _rtl_expr_169 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_168)
  let _rtl_expr_170 : BitVec 8 := (_rtl_expr_161 ^^^ _rtl_expr_169)
  let _rtl_expr_171 : BitVec 8 := (_rtl_expr_170 ^^^ _rtl_expr_128)
  let _rtl_expr_172 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_171)
  let _rtl_expr_173 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_172)
  let _rtl_expr_174 : BitVec 8 := (((((env).2).2).2).1 ^^^ _rtl_expr_173)
  let _rtl_expr_175 : BitVec 8 := BitVec.extractLsb 15 8 ((((env).2).1).1)
  let _rtl_expr_176 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_175)
  let _rtl_expr_177 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_176)
  let _rtl_expr_178 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_177)
  let _rtl_expr_179 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_178)
  let _rtl_expr_180 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_179)
  let _rtl_expr_181 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_180)
  let _rtl_expr_182 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_181) (boolToBitVec (false))
  let _rtl_expr_183 : Bool := BitVec.getLsbD (_rtl_expr_180) 7
  let _rtl_expr_184 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_183)) (boolToBitVec (_rtl_expr_183))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_183)) (boolToBitVec (_rtl_expr_183)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_183)) (boolToBitVec (_rtl_expr_183))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_183)) (boolToBitVec (_rtl_expr_183))))
  let _rtl_expr_185 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_184)
  let _rtl_expr_186 : BitVec 8 := (_rtl_expr_182 ^^^ _rtl_expr_185)
  let _rtl_expr_187 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_186)
  let _rtl_expr_188 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_187)
  let _rtl_expr_189 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_188)
  let _rtl_expr_190 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_189)
  let _rtl_expr_191 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_190) (boolToBitVec (false))
  (((((((env).1).1).1, ((((env).1).1).2).1), (((((env).1).1).2).2, (((((env).1).2).1).1, ((((env).1).2).1).2))), ((((((env).1).2).2).1, (((((env).1).2).2).2, (((env).2).1).1)), (((((env).2).1).2).1, (((((env).2).1).2).2, ((((env).2).2).1).1)))), (((((((env).2).2).1).2, _rtl_expr_128), (_rtl_expr_130, (_rtl_expr_161, _rtl_expr_169))), ((_rtl_expr_174, (_rtl_expr_177, _rtl_expr_178)), (_rtl_expr_179, (_rtl_expr_189, _rtl_expr_191)))))

private def _rtl_eval_block_12 (s : aes_coreState) (i : aes_coreInputs) (env : ((((Bool × BitVec 128) × (Bool × (BitVec 128 × Bool))) × ((BitVec 128 × (BitVec 128 × BitVec 32)) × (BitVec 8 × (BitVec 8 × BitVec 8)))) × (((BitVec 8 × BitVec 8) × (BitVec 8 × (BitVec 8 × BitVec 8))) × ((BitVec 8 × (BitVec 8 × BitVec 8)) × (BitVec 8 × (BitVec 8 × BitVec 8)))))) : ((((Bool × (BitVec 128 × Bool)) × (BitVec 128 × (Bool × BitVec 128))) × ((BitVec 128 × (BitVec 8 × BitVec 8)) × (BitVec 8 × (BitVec 8 × BitVec 8)))) × (((BitVec 8 × (BitVec 8 × BitVec 8)) × (BitVec 8 × (BitVec 8 × BitVec 8))) × ((BitVec 8 × (BitVec 8 × BitVec 8)) × (BitVec 8 × (BitVec 8 × BitVec 8))))) :=
  let _rtl_expr_192 : Bool := BitVec.getLsbD ((((((env).2).2).2).2).1) 7
  let _rtl_expr_193 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_192)) (boolToBitVec (_rtl_expr_192))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_192)) (boolToBitVec (_rtl_expr_192)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_192)) (boolToBitVec (_rtl_expr_192))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_192)) (boolToBitVec (_rtl_expr_192))))
  let _rtl_expr_194 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_193)
  let _rtl_expr_195 : BitVec 8 := ((((((env).2).2).2).2).2 ^^^ _rtl_expr_194)
  let _rtl_expr_196 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_195)
  let _rtl_expr_197 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_196)
  let _rtl_expr_198 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_197)
  let _rtl_expr_199 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_198)
  let _rtl_expr_200 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_199)
  let _rtl_expr_201 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_200)
  let _rtl_expr_202 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_201) (boolToBitVec (false))
  let _rtl_expr_203 : Bool := BitVec.getLsbD (_rtl_expr_200) 7
  let _rtl_expr_204 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_203)) (boolToBitVec (_rtl_expr_203))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_203)) (boolToBitVec (_rtl_expr_203)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_203)) (boolToBitVec (_rtl_expr_203))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_203)) (boolToBitVec (_rtl_expr_203))))
  let _rtl_expr_205 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_204)
  let _rtl_expr_206 : BitVec 8 := (_rtl_expr_202 ^^^ _rtl_expr_205)
  let _rtl_expr_207 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_206)
  let _rtl_expr_208 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_207)
  let _rtl_expr_209 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_208)
  let _rtl_expr_210 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_209)
  let _rtl_expr_211 : BitVec 7 := BitVec.extractLsb 6 0 (((((env).2).2).2).1)
  let _rtl_expr_212 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_211) (boolToBitVec (false))
  let _rtl_expr_213 : Bool := BitVec.getLsbD (((((env).2).2).2).1) 7
  let _rtl_expr_214 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_213)) (boolToBitVec (_rtl_expr_213))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_213)) (boolToBitVec (_rtl_expr_213)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_213)) (boolToBitVec (_rtl_expr_213))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_213)) (boolToBitVec (_rtl_expr_213))))
  let _rtl_expr_215 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_214)
  let _rtl_expr_216 : BitVec 8 := (_rtl_expr_212 ^^^ _rtl_expr_215)
  let _rtl_expr_217 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_216)
  let _rtl_expr_218 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_217)
  let _rtl_expr_219 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_218)
  let _rtl_expr_220 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_219)
  let _rtl_expr_221 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_220) (boolToBitVec (false))
  let _rtl_expr_222 : Bool := BitVec.getLsbD (_rtl_expr_219) 7
  let _rtl_expr_223 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_222)) (boolToBitVec (_rtl_expr_222))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_222)) (boolToBitVec (_rtl_expr_222)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_222)) (boolToBitVec (_rtl_expr_222))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_222)) (boolToBitVec (_rtl_expr_222))))
  let _rtl_expr_224 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_223)
  let _rtl_expr_225 : BitVec 8 := (_rtl_expr_221 ^^^ _rtl_expr_224)
  let _rtl_expr_226 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_225)
  let _rtl_expr_227 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_226)
  let _rtl_expr_228 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_227)
  let _rtl_expr_229 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_228)
  let _rtl_expr_230 : BitVec 8 := (_rtl_expr_210 ^^^ _rtl_expr_229)
  let _rtl_expr_231 : BitVec 8 := (_rtl_expr_230 ^^^ (((((env).2).2).1).2).1)
  let _rtl_expr_232 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_231)
  let _rtl_expr_233 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_232)
  let _rtl_expr_234 : BitVec 8 := (((((env).2).2).1).1 ^^^ _rtl_expr_233)
  let _rtl_expr_235 : BitVec 8 := BitVec.extractLsb 7 0 ((((((env).1).2).1).2).2)
  let _rtl_expr_236 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_235)
  let _rtl_expr_237 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_236)
  let _rtl_expr_238 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_237)
  let _rtl_expr_239 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_238)
  let _rtl_expr_240 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_239)
  let _rtl_expr_241 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_240)
  let _rtl_expr_242 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_241) (boolToBitVec (false))
  let _rtl_expr_243 : Bool := BitVec.getLsbD (_rtl_expr_240) 7
  let _rtl_expr_244 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_243)) (boolToBitVec (_rtl_expr_243))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_243)) (boolToBitVec (_rtl_expr_243)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_243)) (boolToBitVec (_rtl_expr_243))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_243)) (boolToBitVec (_rtl_expr_243))))
  let _rtl_expr_245 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_244)
  let _rtl_expr_246 : BitVec 8 := (_rtl_expr_242 ^^^ _rtl_expr_245)
  let _rtl_expr_247 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_246)
  let _rtl_expr_248 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_247)
  let _rtl_expr_249 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_248)
  let _rtl_expr_250 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_249)
  let _rtl_expr_251 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_250) (boolToBitVec (false))
  let _rtl_expr_252 : Bool := BitVec.getLsbD (_rtl_expr_249) 7
  let _rtl_expr_253 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_252)) (boolToBitVec (_rtl_expr_252))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_252)) (boolToBitVec (_rtl_expr_252)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_252)) (boolToBitVec (_rtl_expr_252))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_252)) (boolToBitVec (_rtl_expr_252))))
  let _rtl_expr_254 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_253)
  let _rtl_expr_255 : BitVec 8 := (_rtl_expr_251 ^^^ _rtl_expr_254)
  ((((((((env).1).1).1).1, (((((env).1).1).1).2, ((((env).1).1).2).1)), ((((((env).1).1).2).2).1, ((((((env).1).1).2).2).2, ((((env).1).2).1).1))), (((((((env).1).2).1).2).1, (((((env).1).2).2).1, (((((env).1).2).2).2).1)), ((((((env).1).2).2).2).2, (((((env).2).1).1).1, ((((env).2).1).1).2)))), (((((((env).2).1).2).1, ((((((env).2).1).2).2).1, (((((env).2).1).2).2).2)), ((((((env).2).2).1).2).1, ((((((env).2).2).1).2).2, _rtl_expr_210))), ((_rtl_expr_230, (_rtl_expr_234, _rtl_expr_237)), (_rtl_expr_238, (_rtl_expr_239, _rtl_expr_255)))))

private def _rtl_eval_block_13 (s : aes_coreState) (i : aes_coreInputs) (env : ((((Bool × (BitVec 128 × Bool)) × (BitVec 128 × (Bool × BitVec 128))) × ((BitVec 128 × (BitVec 8 × BitVec 8)) × (BitVec 8 × (BitVec 8 × BitVec 8)))) × (((BitVec 8 × (BitVec 8 × BitVec 8)) × (BitVec 8 × (BitVec 8 × BitVec 8))) × ((BitVec 8 × (BitVec 8 × BitVec 8)) × (BitVec 8 × (BitVec 8 × BitVec 8)))))) : ((((Bool × (BitVec 128 × Bool)) × (BitVec 128 × (Bool × BitVec 128))) × ((BitVec 128 × (BitVec 8 × BitVec 8)) × (BitVec 8 × (BitVec 8 × BitVec 8)))) × (((BitVec 8 × (BitVec 8 × BitVec 8)) × (BitVec 8 × (BitVec 8 × BitVec 8))) × ((BitVec 8 × (BitVec 8 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8))))) :=
  let _rtl_expr_256 : BitVec 8 := BitVec.extractLsb 7 0 ((((((env).2).2).2).2).2)
  let _rtl_expr_257 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_256)
  let _rtl_expr_258 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_257)
  let _rtl_expr_259 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_258)
  let _rtl_expr_260 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_259)
  let _rtl_expr_261 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_260)
  let _rtl_expr_262 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_261) (boolToBitVec (false))
  let _rtl_expr_263 : Bool := BitVec.getLsbD (_rtl_expr_260) 7
  let _rtl_expr_264 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_263)) (boolToBitVec (_rtl_expr_263))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_263)) (boolToBitVec (_rtl_expr_263)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_263)) (boolToBitVec (_rtl_expr_263))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_263)) (boolToBitVec (_rtl_expr_263))))
  let _rtl_expr_265 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_264)
  let _rtl_expr_266 : BitVec 8 := (_rtl_expr_262 ^^^ _rtl_expr_265)
  let _rtl_expr_267 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_266)
  let _rtl_expr_268 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_267)
  let _rtl_expr_269 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_268)
  let _rtl_expr_270 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_269)
  let _rtl_expr_271 : BitVec 8 := (_rtl_expr_270 ^^^ (((((env).2).2).1).2).2)
  let _rtl_expr_272 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_271)
  let _rtl_expr_273 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_272)
  let _rtl_expr_274 : BitVec 8 := ((((((env).2).2).1).2).1 ^^^ _rtl_expr_273)
  let _rtl_expr_275 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_274)
  let _rtl_expr_276 : BitVec 8 := ((((((env).1).2).1).2).2 ^^^ (((((env).1).2).1).2).1)
  let _rtl_expr_277 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_276)
  let _rtl_expr_278 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_277)
  let _rtl_expr_279 : BitVec 7 := BitVec.extractLsb 6 0 (((((env).2).1).1).1)
  let _rtl_expr_280 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_279) (boolToBitVec (false))
  let _rtl_expr_281 : Bool := BitVec.getLsbD (((((env).2).1).1).1) 7
  let _rtl_expr_282 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_281)) (boolToBitVec (_rtl_expr_281))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_281)) (boolToBitVec (_rtl_expr_281)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_281)) (boolToBitVec (_rtl_expr_281))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_281)) (boolToBitVec (_rtl_expr_281))))
  let _rtl_expr_283 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_282)
  let _rtl_expr_284 : BitVec 8 := (_rtl_expr_280 ^^^ _rtl_expr_283)
  let _rtl_expr_285 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_284)
  let _rtl_expr_286 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_285)
  let _rtl_expr_287 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_286)
  let _rtl_expr_288 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_287)
  let _rtl_expr_289 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_288) (boolToBitVec (false))
  let _rtl_expr_290 : Bool := BitVec.getLsbD (_rtl_expr_287) 7
  let _rtl_expr_291 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_290)) (boolToBitVec (_rtl_expr_290))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_290)) (boolToBitVec (_rtl_expr_290)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_290)) (boolToBitVec (_rtl_expr_290))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_290)) (boolToBitVec (_rtl_expr_290))))
  let _rtl_expr_292 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_291)
  let _rtl_expr_293 : BitVec 8 := (_rtl_expr_289 ^^^ _rtl_expr_292)
  let _rtl_expr_294 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_293)
  let _rtl_expr_295 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_294)
  let _rtl_expr_296 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_295)
  let _rtl_expr_297 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_296)
  let _rtl_expr_298 : BitVec 8 := ((((((env).2).1).1).2).1 ^^^ _rtl_expr_297)
  let _rtl_expr_299 : BitVec 8 := (_rtl_expr_298 ^^^ (((((env).2).1).1).2).2)
  let _rtl_expr_300 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_299)
  let _rtl_expr_301 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_300)
  let _rtl_expr_302 : BitVec 8 := (_rtl_expr_278 ^^^ _rtl_expr_301)
  let _rtl_expr_303 : BitVec 7 := BitVec.extractLsb 6 0 ((((((env).2).1).2).2).1)
  let _rtl_expr_304 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_303) (boolToBitVec (false))
  let _rtl_expr_305 : Bool := BitVec.getLsbD ((((((env).2).1).2).2).1) 7
  let _rtl_expr_306 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_305)) (boolToBitVec (_rtl_expr_305))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_305)) (boolToBitVec (_rtl_expr_305)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_305)) (boolToBitVec (_rtl_expr_305))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_305)) (boolToBitVec (_rtl_expr_305))))
  let _rtl_expr_307 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_306)
  let _rtl_expr_308 : BitVec 8 := (_rtl_expr_304 ^^^ _rtl_expr_307)
  let _rtl_expr_309 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_308)
  let _rtl_expr_310 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_309)
  let _rtl_expr_311 : BitVec 8 := ((((((env).2).1).2).2).2 ^^^ _rtl_expr_310)
  let _rtl_expr_312 : BitVec 8 := (_rtl_expr_311 ^^^ ((((env).2).1).2).1)
  let _rtl_expr_313 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_312)
  let _rtl_expr_314 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_313)
  let _rtl_expr_315 : BitVec 8 := (_rtl_expr_302 ^^^ _rtl_expr_314)
  let _rtl_expr_316 : BitVec 7 := BitVec.extractLsb 6 0 ((((((env).2).2).2).2).1)
  let _rtl_expr_317 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_316) (boolToBitVec (false))
  let _rtl_expr_318 : Bool := BitVec.getLsbD ((((((env).2).2).2).2).1) 7
  let _rtl_expr_319 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_318)) (boolToBitVec (_rtl_expr_318))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_318)) (boolToBitVec (_rtl_expr_318)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_318)) (boolToBitVec (_rtl_expr_318))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_318)) (boolToBitVec (_rtl_expr_318))))
  ((((((((env).1).1).1).1, ((((((env).1).1).1).2).1, (((((env).1).1).1).2).2)), (((((env).1).1).2).1, ((((((env).1).1).2).2).1, (((((env).1).1).2).2).2))), ((((((env).1).2).1).1, ((((((env).1).2).1).2).1, (((((env).1).2).1).2).2)), (((((env).1).2).2).1, ((((((env).1).2).2).2).1, (((((env).1).2).2).2).2)))), ((((((((env).2).1).1).2).1, (((((env).2).1).2).1, (((((env).2).1).2).2).2)), (((((env).2).2).1).1, ((((((env).2).2).1).2).2, ((((env).2).2).2).1))), ((_rtl_expr_270, (_rtl_expr_275, _rtl_expr_298)), ((_rtl_expr_310, _rtl_expr_315), (_rtl_expr_317, _rtl_expr_319)))))

private def _rtl_eval_block_14 (s : aes_coreState) (i : aes_coreInputs) (env : ((((Bool × (BitVec 128 × Bool)) × (BitVec 128 × (Bool × BitVec 128))) × ((BitVec 128 × (BitVec 8 × BitVec 8)) × (BitVec 8 × (BitVec 8 × BitVec 8)))) × (((BitVec 8 × (BitVec 8 × BitVec 8)) × (BitVec 8 × (BitVec 8 × BitVec 8))) × ((BitVec 8 × (BitVec 8 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8)))))) : (((Bool × BitVec 128) × (Bool × BitVec 128)) × ((Bool × BitVec 128) × (BitVec 128 × BitVec 32))) :=
  let _rtl_expr_320 : BitVec 8 := (BitVec.ofNat 8 27 &&& (((((env).2).2).2).2).2)
  let _rtl_expr_321 : BitVec 8 := ((((((env).2).2).2).2).1 ^^^ _rtl_expr_320)
  let _rtl_expr_322 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_321)
  let _rtl_expr_323 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_322)
  let _rtl_expr_324 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_323)
  let _rtl_expr_325 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_324)
  let _rtl_expr_326 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_325) (boolToBitVec (false))
  let _rtl_expr_327 : Bool := BitVec.getLsbD (_rtl_expr_324) 7
  let _rtl_expr_328 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_327)) (boolToBitVec (_rtl_expr_327))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_327)) (boolToBitVec (_rtl_expr_327)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_327)) (boolToBitVec (_rtl_expr_327))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_327)) (boolToBitVec (_rtl_expr_327))))
  let _rtl_expr_329 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_328)
  let _rtl_expr_330 : BitVec 8 := (_rtl_expr_326 ^^^ _rtl_expr_329)
  let _rtl_expr_331 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_330)
  let _rtl_expr_332 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_331)
  let _rtl_expr_333 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_332)
  let _rtl_expr_334 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_333)
  let _rtl_expr_335 : BitVec 8 := (((((env).2).2).1).1 ^^^ _rtl_expr_334)
  let _rtl_expr_336 : BitVec 8 := (_rtl_expr_335 ^^^ (((((env).2).1).2).2).1)
  let _rtl_expr_337 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_336)
  let _rtl_expr_338 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_337)
  let _rtl_expr_339 : BitVec 8 := ((((((env).2).2).2).1).2 ^^^ _rtl_expr_338)
  let _rtl_expr_340 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_339)
  let _rtl_expr_341 : BitVec 8 := (((((env).1).2).2).1 ^^^ (((((env).1).2).1).2).1)
  let _rtl_expr_342 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_341)
  let _rtl_expr_343 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_342)
  let _rtl_expr_344 : BitVec 8 := (((((env).2).1).1).1 ^^^ (((((env).1).2).2).2).2)
  let _rtl_expr_345 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_344)
  let _rtl_expr_346 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_345)
  let _rtl_expr_347 : BitVec 8 := (_rtl_expr_343 ^^^ _rtl_expr_346)
  let _rtl_expr_348 : BitVec 8 := (((((env).2).1).2).1 ^^^ (((((env).2).2).2).1).1)
  let _rtl_expr_349 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_348)
  let _rtl_expr_350 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_349)
  let _rtl_expr_351 : BitVec 8 := (_rtl_expr_347 ^^^ _rtl_expr_350)
  let _rtl_expr_352 : BitVec 7 := BitVec.extractLsb 6 0 ((((((env).2).1).2).2).2)
  let _rtl_expr_353 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_352) (boolToBitVec (false))
  let _rtl_expr_354 : Bool := BitVec.getLsbD ((((((env).2).1).2).2).2) 7
  let _rtl_expr_355 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_354)) (boolToBitVec (_rtl_expr_354))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_354)) (boolToBitVec (_rtl_expr_354)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_354)) (boolToBitVec (_rtl_expr_354))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_354)) (boolToBitVec (_rtl_expr_354))))
  let _rtl_expr_356 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_355)
  let _rtl_expr_357 : BitVec 8 := (_rtl_expr_353 ^^^ _rtl_expr_356)
  let _rtl_expr_358 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_357)
  let _rtl_expr_359 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_358)
  let _rtl_expr_360 : BitVec 8 := (((((env).2).2).1).1 ^^^ _rtl_expr_359)
  let _rtl_expr_361 : BitVec 8 := (_rtl_expr_360 ^^^ (((((env).2).1).2).2).1)
  let _rtl_expr_362 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_361)
  let _rtl_expr_363 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_362)
  let _rtl_expr_364 : BitVec 8 := (_rtl_expr_351 ^^^ _rtl_expr_363)
  let _rtl_expr_365 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_364)
  let _rtl_expr_366 : BitVec 8 := ((((((env).1).2).1).2).2 ^^^ (((((env).1).2).2).2).1)
  let _rtl_expr_367 : BitVec 8 := (_rtl_expr_366 ^^^ (((((env).1).2).1).2).1)
  let _rtl_expr_368 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_367)
  let _rtl_expr_369 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_368)
  let _rtl_expr_370 : BitVec 8 := ((((((env).2).2).1).2).2 ^^^ (((((env).1).2).2).2).2)
  let _rtl_expr_371 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_370)
  let _rtl_expr_372 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_371)
  let _rtl_expr_373 : BitVec 8 := (_rtl_expr_369 ^^^ _rtl_expr_372)
  let _rtl_expr_374 : BitVec 8 := ((((((env).2).1).1).2).2 ^^^ (((((env).2).1).1).2).1)
  let _rtl_expr_375 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_374)
  let _rtl_expr_376 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_375)
  let _rtl_expr_377 : BitVec 8 := (_rtl_expr_373 ^^^ _rtl_expr_376)
  let _rtl_expr_378 : BitVec 8 := (_rtl_expr_335 ^^^ _rtl_expr_359)
  let _rtl_expr_379 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_378)
  let _rtl_expr_380 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_379)
  let _rtl_expr_381 : BitVec 8 := (_rtl_expr_377 ^^^ _rtl_expr_380)
  let _rtl_expr_382 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_381)
  let _rtl_expr_383 : BitVec 32 := BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) ((((((env).2).2).1).2).1) (_rtl_expr_340)) (BitVec.append (n := 8) (m := 8) (_rtl_expr_365) (_rtl_expr_382))
  (((((((env).1).1).1).1, (((((env).1).1).1).2).1), ((((((env).1).1).1).2).2, ((((env).1).1).2).1)), (((((((env).1).1).2).2).1, (((((env).1).1).2).2).2), (((((env).1).2).1).1, _rtl_expr_383)))

private def _rtl_eval_block_15 (s : aes_coreState) (i : aes_coreInputs) (env : (((Bool × BitVec 128) × (Bool × BitVec 128)) × ((Bool × BitVec 128) × (BitVec 128 × BitVec 32)))) : (((Bool × (BitVec 128 × Bool)) × ((BitVec 128 × Bool) × (BitVec 128 × BitVec 128))) × ((BitVec 32 × (BitVec 32 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8)))) :=
  let _rtl_expr_384 : BitVec 32 := BitVec.extractLsb 31 0 ((((env).2).2).2)
  let _rtl_expr_385 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_384)
  let _rtl_expr_386 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_385)
  let _rtl_expr_387 : BitVec 32 := BitVec.extractLsb 95 64 ((((env).2).2).1)
  let _rtl_expr_388 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_387)
  let _rtl_expr_389 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_388)
  let _rtl_expr_390 : BitVec 8 := BitVec.extractLsb 31 24 (_rtl_expr_389)
  let _rtl_expr_391 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_390)
  let _rtl_expr_392 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_391)
  let _rtl_expr_393 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_392)
  let _rtl_expr_394 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_393)
  let _rtl_expr_395 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_394)
  let _rtl_expr_396 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_395)
  let _rtl_expr_397 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_396) (boolToBitVec (false))
  let _rtl_expr_398 : Bool := BitVec.getLsbD (_rtl_expr_395) 7
  let _rtl_expr_399 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_398)) (boolToBitVec (_rtl_expr_398))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_398)) (boolToBitVec (_rtl_expr_398)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_398)) (boolToBitVec (_rtl_expr_398))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_398)) (boolToBitVec (_rtl_expr_398))))
  let _rtl_expr_400 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_399)
  let _rtl_expr_401 : BitVec 8 := (_rtl_expr_397 ^^^ _rtl_expr_400)
  let _rtl_expr_402 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_401)
  let _rtl_expr_403 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_402)
  let _rtl_expr_404 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_403)
  let _rtl_expr_405 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_404)
  let _rtl_expr_406 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_405) (boolToBitVec (false))
  let _rtl_expr_407 : Bool := BitVec.getLsbD (_rtl_expr_404) 7
  let _rtl_expr_408 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_407)) (boolToBitVec (_rtl_expr_407))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_407)) (boolToBitVec (_rtl_expr_407)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_407)) (boolToBitVec (_rtl_expr_407))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_407)) (boolToBitVec (_rtl_expr_407))))
  let _rtl_expr_409 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_408)
  let _rtl_expr_410 : BitVec 8 := (_rtl_expr_406 ^^^ _rtl_expr_409)
  let _rtl_expr_411 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_410)
  let _rtl_expr_412 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_411)
  let _rtl_expr_413 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_412)
  let _rtl_expr_414 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_413)
  let _rtl_expr_415 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_414)
  let _rtl_expr_416 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_415)
  let _rtl_expr_417 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_416) (boolToBitVec (false))
  let _rtl_expr_418 : Bool := BitVec.getLsbD (_rtl_expr_415) 7
  let _rtl_expr_419 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_418)) (boolToBitVec (_rtl_expr_418))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_418)) (boolToBitVec (_rtl_expr_418)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_418)) (boolToBitVec (_rtl_expr_418))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_418)) (boolToBitVec (_rtl_expr_418))))
  let _rtl_expr_420 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_419)
  let _rtl_expr_421 : BitVec 8 := (_rtl_expr_417 ^^^ _rtl_expr_420)
  let _rtl_expr_422 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_421)
  let _rtl_expr_423 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_422)
  let _rtl_expr_424 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_423)
  let _rtl_expr_425 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_424)
  let _rtl_expr_426 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_394)
  let _rtl_expr_427 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_426) (boolToBitVec (false))
  let _rtl_expr_428 : Bool := BitVec.getLsbD (_rtl_expr_394) 7
  let _rtl_expr_429 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_428)) (boolToBitVec (_rtl_expr_428))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_428)) (boolToBitVec (_rtl_expr_428)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_428)) (boolToBitVec (_rtl_expr_428))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_428)) (boolToBitVec (_rtl_expr_428))))
  let _rtl_expr_430 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_429)
  let _rtl_expr_431 : BitVec 8 := (_rtl_expr_427 ^^^ _rtl_expr_430)
  let _rtl_expr_432 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_431)
  let _rtl_expr_433 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_432)
  let _rtl_expr_434 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_433)
  let _rtl_expr_435 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_434)
  let _rtl_expr_436 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_435) (boolToBitVec (false))
  let _rtl_expr_437 : Bool := BitVec.getLsbD (_rtl_expr_434) 7
  let _rtl_expr_438 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_437)) (boolToBitVec (_rtl_expr_437))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_437)) (boolToBitVec (_rtl_expr_437)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_437)) (boolToBitVec (_rtl_expr_437))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_437)) (boolToBitVec (_rtl_expr_437))))
  let _rtl_expr_439 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_438)
  let _rtl_expr_440 : BitVec 8 := (_rtl_expr_436 ^^^ _rtl_expr_439)
  let _rtl_expr_441 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_440)
  let _rtl_expr_442 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_441)
  let _rtl_expr_443 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_442)
  let _rtl_expr_444 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_443)
  let _rtl_expr_445 : BitVec 8 := (_rtl_expr_425 ^^^ _rtl_expr_444)
  let _rtl_expr_446 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_393)
  let _rtl_expr_447 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_446) (boolToBitVec (false))
  ((((((env).1).1).1, ((((env).1).1).2, (((env).1).2).1)), (((((env).1).2).2, (((env).2).1).1), ((((env).2).1).2, (((env).2).2).1))), ((_rtl_expr_386, (_rtl_expr_389, _rtl_expr_392)), ((_rtl_expr_393, _rtl_expr_425), (_rtl_expr_445, _rtl_expr_447))))

private def _rtl_eval_block_16 (s : aes_coreState) (i : aes_coreInputs) (env : (((Bool × (BitVec 128 × Bool)) × ((BitVec 128 × Bool) × (BitVec 128 × BitVec 128))) × ((BitVec 32 × (BitVec 32 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8))))) : ((((Bool × BitVec 128) × (Bool × (BitVec 128 × Bool))) × ((BitVec 128 × (BitVec 128 × BitVec 32)) × (BitVec 32 × (BitVec 8 × BitVec 8)))) × (((BitVec 8 × BitVec 8) × (BitVec 8 × (BitVec 8 × BitVec 8))) × ((BitVec 8 × (BitVec 8 × BitVec 8)) × (BitVec 8 × (BitVec 8 × BitVec 8))))) :=
  let _rtl_expr_448 : Bool := BitVec.getLsbD (((((env).2).2).1).1) 7
  let _rtl_expr_449 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_448)) (boolToBitVec (_rtl_expr_448))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_448)) (boolToBitVec (_rtl_expr_448)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_448)) (boolToBitVec (_rtl_expr_448))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_448)) (boolToBitVec (_rtl_expr_448))))
  let _rtl_expr_450 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_449)
  let _rtl_expr_451 : BitVec 8 := (((((env).2).2).2).2 ^^^ _rtl_expr_450)
  let _rtl_expr_452 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_451)
  let _rtl_expr_453 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_452)
  let _rtl_expr_454 : BitVec 8 := (((((env).2).2).2).1 ^^^ _rtl_expr_453)
  let _rtl_expr_455 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_454)
  let _rtl_expr_456 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_455)
  let _rtl_expr_457 : BitVec 8 := BitVec.extractLsb 23 16 (((((env).2).1).2).1)
  let _rtl_expr_458 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_457)
  let _rtl_expr_459 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_458)
  let _rtl_expr_460 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_459)
  let _rtl_expr_461 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_460)
  let _rtl_expr_462 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_461)
  let _rtl_expr_463 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_462)
  let _rtl_expr_464 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_463) (boolToBitVec (false))
  let _rtl_expr_465 : Bool := BitVec.getLsbD (_rtl_expr_462) 7
  let _rtl_expr_466 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_465)) (boolToBitVec (_rtl_expr_465))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_465)) (boolToBitVec (_rtl_expr_465)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_465)) (boolToBitVec (_rtl_expr_465))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_465)) (boolToBitVec (_rtl_expr_465))))
  let _rtl_expr_467 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_466)
  let _rtl_expr_468 : BitVec 8 := (_rtl_expr_464 ^^^ _rtl_expr_467)
  let _rtl_expr_469 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_468)
  let _rtl_expr_470 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_469)
  let _rtl_expr_471 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_470)
  let _rtl_expr_472 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_471)
  let _rtl_expr_473 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_472) (boolToBitVec (false))
  let _rtl_expr_474 : Bool := BitVec.getLsbD (_rtl_expr_471) 7
  let _rtl_expr_475 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_474)) (boolToBitVec (_rtl_expr_474))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_474)) (boolToBitVec (_rtl_expr_474)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_474)) (boolToBitVec (_rtl_expr_474))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_474)) (boolToBitVec (_rtl_expr_474))))
  let _rtl_expr_476 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_475)
  let _rtl_expr_477 : BitVec 8 := (_rtl_expr_473 ^^^ _rtl_expr_476)
  let _rtl_expr_478 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_477)
  let _rtl_expr_479 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_478)
  let _rtl_expr_480 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_479)
  let _rtl_expr_481 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_480)
  let _rtl_expr_482 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_481)
  let _rtl_expr_483 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_482)
  let _rtl_expr_484 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_483) (boolToBitVec (false))
  let _rtl_expr_485 : Bool := BitVec.getLsbD (_rtl_expr_482) 7
  let _rtl_expr_486 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_485)) (boolToBitVec (_rtl_expr_485))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_485)) (boolToBitVec (_rtl_expr_485)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_485)) (boolToBitVec (_rtl_expr_485))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_485)) (boolToBitVec (_rtl_expr_485))))
  let _rtl_expr_487 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_486)
  let _rtl_expr_488 : BitVec 8 := (_rtl_expr_484 ^^^ _rtl_expr_487)
  let _rtl_expr_489 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_488)
  let _rtl_expr_490 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_489)
  let _rtl_expr_491 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_490)
  let _rtl_expr_492 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_491)
  let _rtl_expr_493 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_460)
  let _rtl_expr_494 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_493) (boolToBitVec (false))
  let _rtl_expr_495 : Bool := BitVec.getLsbD (_rtl_expr_460) 7
  let _rtl_expr_496 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_495)) (boolToBitVec (_rtl_expr_495))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_495)) (boolToBitVec (_rtl_expr_495)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_495)) (boolToBitVec (_rtl_expr_495))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_495)) (boolToBitVec (_rtl_expr_495))))
  let _rtl_expr_497 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_496)
  let _rtl_expr_498 : BitVec 8 := (_rtl_expr_494 ^^^ _rtl_expr_497)
  let _rtl_expr_499 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_498)
  let _rtl_expr_500 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_499)
  let _rtl_expr_501 : BitVec 8 := (_rtl_expr_492 ^^^ _rtl_expr_500)
  let _rtl_expr_502 : BitVec 8 := (_rtl_expr_501 ^^^ _rtl_expr_459)
  let _rtl_expr_503 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_502)
  let _rtl_expr_504 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_503)
  let _rtl_expr_505 : BitVec 8 := (_rtl_expr_456 ^^^ _rtl_expr_504)
  let _rtl_expr_506 : BitVec 8 := BitVec.extractLsb 15 8 (((((env).2).1).2).1)
  let _rtl_expr_507 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_506)
  let _rtl_expr_508 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_507)
  let _rtl_expr_509 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_508)
  let _rtl_expr_510 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_509)
  let _rtl_expr_511 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_510)
  (((((((env).1).1).1, ((((env).1).1).2).1), (((((env).1).1).2).2, (((((env).1).2).1).1, ((((env).1).2).1).2))), ((((((env).1).2).2).1, (((((env).1).2).2).2, (((env).2).1).1)), (((((env).2).1).2).1, (((((env).2).1).2).2, ((((env).2).2).1).2)))), (((((((env).2).2).2).1, _rtl_expr_453), (_rtl_expr_459, (_rtl_expr_461, _rtl_expr_492))), ((_rtl_expr_500, (_rtl_expr_505, _rtl_expr_508)), (_rtl_expr_509, (_rtl_expr_510, _rtl_expr_511)))))

private def _rtl_eval_block_17 (s : aes_coreState) (i : aes_coreInputs) (env : ((((Bool × BitVec 128) × (Bool × (BitVec 128 × Bool))) × ((BitVec 128 × (BitVec 128 × BitVec 32)) × (BitVec 32 × (BitVec 8 × BitVec 8)))) × (((BitVec 8 × BitVec 8) × (BitVec 8 × (BitVec 8 × BitVec 8))) × ((BitVec 8 × (BitVec 8 × BitVec 8)) × (BitVec 8 × (BitVec 8 × BitVec 8)))))) : ((((Bool × (BitVec 128 × Bool)) × (BitVec 128 × (Bool × BitVec 128))) × ((BitVec 128 × (BitVec 32 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8)))) × (((BitVec 8 × (BitVec 8 × BitVec 8)) × (BitVec 8 × (BitVec 8 × BitVec 8))) × ((BitVec 8 × (BitVec 8 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8))))) :=
  let _rtl_expr_512 : BitVec 7 := BitVec.extractLsb 6 0 ((((((env).2).2).2).2).2)
  let _rtl_expr_513 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_512) (boolToBitVec (false))
  let _rtl_expr_514 : Bool := BitVec.getLsbD ((((((env).2).2).2).2).2) 7
  let _rtl_expr_515 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_514)) (boolToBitVec (_rtl_expr_514))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_514)) (boolToBitVec (_rtl_expr_514)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_514)) (boolToBitVec (_rtl_expr_514))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_514)) (boolToBitVec (_rtl_expr_514))))
  let _rtl_expr_516 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_515)
  let _rtl_expr_517 : BitVec 8 := (_rtl_expr_513 ^^^ _rtl_expr_516)
  let _rtl_expr_518 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_517)
  let _rtl_expr_519 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_518)
  let _rtl_expr_520 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_519)
  let _rtl_expr_521 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_520)
  let _rtl_expr_522 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_521) (boolToBitVec (false))
  let _rtl_expr_523 : Bool := BitVec.getLsbD (_rtl_expr_520) 7
  let _rtl_expr_524 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_523)) (boolToBitVec (_rtl_expr_523))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_523)) (boolToBitVec (_rtl_expr_523)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_523)) (boolToBitVec (_rtl_expr_523))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_523)) (boolToBitVec (_rtl_expr_523))))
  let _rtl_expr_525 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_524)
  let _rtl_expr_526 : BitVec 8 := (_rtl_expr_522 ^^^ _rtl_expr_525)
  let _rtl_expr_527 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_526)
  let _rtl_expr_528 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_527)
  let _rtl_expr_529 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_528)
  let _rtl_expr_530 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_529)
  let _rtl_expr_531 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_530)
  let _rtl_expr_532 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_531)
  let _rtl_expr_533 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_532) (boolToBitVec (false))
  let _rtl_expr_534 : Bool := BitVec.getLsbD (_rtl_expr_531) 7
  let _rtl_expr_535 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_534)) (boolToBitVec (_rtl_expr_534))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_534)) (boolToBitVec (_rtl_expr_534)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_534)) (boolToBitVec (_rtl_expr_534))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_534)) (boolToBitVec (_rtl_expr_534))))
  let _rtl_expr_536 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_535)
  let _rtl_expr_537 : BitVec 8 := (_rtl_expr_533 ^^^ _rtl_expr_536)
  let _rtl_expr_538 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_537)
  let _rtl_expr_539 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_538)
  let _rtl_expr_540 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_539)
  let _rtl_expr_541 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_540)
  let _rtl_expr_542 : BitVec 7 := BitVec.extractLsb 6 0 ((((((env).2).2).2).2).1)
  let _rtl_expr_543 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_542) (boolToBitVec (false))
  let _rtl_expr_544 : Bool := BitVec.getLsbD ((((((env).2).2).2).2).1) 7
  let _rtl_expr_545 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_544)) (boolToBitVec (_rtl_expr_544))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_544)) (boolToBitVec (_rtl_expr_544)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_544)) (boolToBitVec (_rtl_expr_544))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_544)) (boolToBitVec (_rtl_expr_544))))
  let _rtl_expr_546 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_545)
  let _rtl_expr_547 : BitVec 8 := (_rtl_expr_543 ^^^ _rtl_expr_546)
  let _rtl_expr_548 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_547)
  let _rtl_expr_549 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_548)
  let _rtl_expr_550 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_549)
  let _rtl_expr_551 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_550)
  let _rtl_expr_552 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_551) (boolToBitVec (false))
  let _rtl_expr_553 : Bool := BitVec.getLsbD (_rtl_expr_550) 7
  let _rtl_expr_554 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_553)) (boolToBitVec (_rtl_expr_553))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_553)) (boolToBitVec (_rtl_expr_553)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_553)) (boolToBitVec (_rtl_expr_553))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_553)) (boolToBitVec (_rtl_expr_553))))
  let _rtl_expr_555 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_554)
  let _rtl_expr_556 : BitVec 8 := (_rtl_expr_552 ^^^ _rtl_expr_555)
  let _rtl_expr_557 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_556)
  let _rtl_expr_558 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_557)
  let _rtl_expr_559 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_558)
  let _rtl_expr_560 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_559)
  let _rtl_expr_561 : BitVec 8 := (_rtl_expr_541 ^^^ _rtl_expr_560)
  let _rtl_expr_562 : BitVec 8 := (_rtl_expr_561 ^^^ (((((env).2).2).1).2).2)
  let _rtl_expr_563 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_562)
  let _rtl_expr_564 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_563)
  let _rtl_expr_565 : BitVec 8 := ((((((env).2).2).1).2).1 ^^^ _rtl_expr_564)
  let _rtl_expr_566 : BitVec 8 := BitVec.extractLsb 7 0 (((((env).1).2).2).1)
  let _rtl_expr_567 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_566)
  let _rtl_expr_568 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_567)
  let _rtl_expr_569 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_568)
  let _rtl_expr_570 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_569)
  let _rtl_expr_571 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_570)
  let _rtl_expr_572 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_571)
  let _rtl_expr_573 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_572) (boolToBitVec (false))
  let _rtl_expr_574 : Bool := BitVec.getLsbD (_rtl_expr_571) 7
  let _rtl_expr_575 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_574)) (boolToBitVec (_rtl_expr_574))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_574)) (boolToBitVec (_rtl_expr_574)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_574)) (boolToBitVec (_rtl_expr_574))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_574)) (boolToBitVec (_rtl_expr_574))))
  ((((((((env).1).1).1).1, (((((env).1).1).1).2, ((((env).1).1).2).1)), ((((((env).1).1).2).2).1, ((((((env).1).1).2).2).2, ((((env).1).2).1).1))), (((((((env).1).2).1).2).1, ((((((env).1).2).1).2).2, (((((env).1).2).2).2).1)), (((((((env).1).2).2).2).2, ((((env).2).1).1).1), (((((env).2).1).1).2, ((((env).2).1).2).1)))), ((((((((env).2).1).2).2).1, ((((((env).2).1).2).2).2, ((((env).2).2).1).1)), ((((((env).2).2).1).2).2, (((((env).2).2).2).1, _rtl_expr_541))), ((_rtl_expr_561, (_rtl_expr_565, _rtl_expr_568)), ((_rtl_expr_569, _rtl_expr_570), (_rtl_expr_573, _rtl_expr_575)))))

private def _rtl_eval_block_18 (s : aes_coreState) (i : aes_coreInputs) (env : ((((Bool × (BitVec 128 × Bool)) × (BitVec 128 × (Bool × BitVec 128))) × ((BitVec 128 × (BitVec 32 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8)))) × (((BitVec 8 × (BitVec 8 × BitVec 8)) × (BitVec 8 × (BitVec 8 × BitVec 8))) × ((BitVec 8 × (BitVec 8 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8)))))) : ((((Bool × (BitVec 128 × Bool)) × (BitVec 128 × (Bool × BitVec 128))) × ((BitVec 128 × (BitVec 32 × BitVec 8)) × (BitVec 8 × (BitVec 8 × BitVec 8)))) × (((BitVec 8 × (BitVec 8 × BitVec 8)) × (BitVec 8 × (BitVec 8 × BitVec 8))) × ((BitVec 8 × (BitVec 8 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8))))) :=
  let _rtl_expr_576 : BitVec 8 := (BitVec.ofNat 8 27 &&& (((((env).2).2).2).2).2)
  let _rtl_expr_577 : BitVec 8 := ((((((env).2).2).2).2).1 ^^^ _rtl_expr_576)
  let _rtl_expr_578 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_577)
  let _rtl_expr_579 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_578)
  let _rtl_expr_580 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_579)
  let _rtl_expr_581 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_580)
  let _rtl_expr_582 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_581) (boolToBitVec (false))
  let _rtl_expr_583 : Bool := BitVec.getLsbD (_rtl_expr_580) 7
  let _rtl_expr_584 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_583)) (boolToBitVec (_rtl_expr_583))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_583)) (boolToBitVec (_rtl_expr_583)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_583)) (boolToBitVec (_rtl_expr_583))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_583)) (boolToBitVec (_rtl_expr_583))))
  let _rtl_expr_585 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_584)
  let _rtl_expr_586 : BitVec 8 := (_rtl_expr_582 ^^^ _rtl_expr_585)
  let _rtl_expr_587 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_586)
  let _rtl_expr_588 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_587)
  let _rtl_expr_589 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_588)
  let _rtl_expr_590 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_589)
  let _rtl_expr_591 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_590)
  let _rtl_expr_592 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_591)
  let _rtl_expr_593 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_592) (boolToBitVec (false))
  let _rtl_expr_594 : Bool := BitVec.getLsbD (_rtl_expr_591) 7
  let _rtl_expr_595 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_594)) (boolToBitVec (_rtl_expr_594))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_594)) (boolToBitVec (_rtl_expr_594)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_594)) (boolToBitVec (_rtl_expr_594))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_594)) (boolToBitVec (_rtl_expr_594))))
  let _rtl_expr_596 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_595)
  let _rtl_expr_597 : BitVec 8 := (_rtl_expr_593 ^^^ _rtl_expr_596)
  let _rtl_expr_598 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_597)
  let _rtl_expr_599 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_598)
  let _rtl_expr_600 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_599)
  let _rtl_expr_601 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_600)
  let _rtl_expr_602 : BitVec 8 := (_rtl_expr_601 ^^^ (((((env).2).2).1).2).2)
  let _rtl_expr_603 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_602)
  let _rtl_expr_604 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_603)
  let _rtl_expr_605 : BitVec 8 := ((((((env).2).2).1).2).1 ^^^ _rtl_expr_604)
  let _rtl_expr_606 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_605)
  let _rtl_expr_607 : BitVec 8 := ((((((env).1).2).2).1).1 ^^^ (((((env).1).2).1).2).2)
  let _rtl_expr_608 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_607)
  let _rtl_expr_609 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_608)
  let _rtl_expr_610 : BitVec 7 := BitVec.extractLsb 6 0 (((((env).2).1).1).1)
  let _rtl_expr_611 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_610) (boolToBitVec (false))
  let _rtl_expr_612 : Bool := BitVec.getLsbD (((((env).2).1).1).1) 7
  let _rtl_expr_613 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_612)) (boolToBitVec (_rtl_expr_612))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_612)) (boolToBitVec (_rtl_expr_612)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_612)) (boolToBitVec (_rtl_expr_612))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_612)) (boolToBitVec (_rtl_expr_612))))
  let _rtl_expr_614 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_613)
  let _rtl_expr_615 : BitVec 8 := (_rtl_expr_611 ^^^ _rtl_expr_614)
  let _rtl_expr_616 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_615)
  let _rtl_expr_617 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_616)
  let _rtl_expr_618 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_617)
  let _rtl_expr_619 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_618)
  let _rtl_expr_620 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_619) (boolToBitVec (false))
  let _rtl_expr_621 : Bool := BitVec.getLsbD (_rtl_expr_618) 7
  let _rtl_expr_622 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_621)) (boolToBitVec (_rtl_expr_621))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_621)) (boolToBitVec (_rtl_expr_621)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_621)) (boolToBitVec (_rtl_expr_621))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_621)) (boolToBitVec (_rtl_expr_621))))
  let _rtl_expr_623 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_622)
  let _rtl_expr_624 : BitVec 8 := (_rtl_expr_620 ^^^ _rtl_expr_623)
  let _rtl_expr_625 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_624)
  let _rtl_expr_626 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_625)
  let _rtl_expr_627 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_626)
  let _rtl_expr_628 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_627)
  let _rtl_expr_629 : BitVec 8 := ((((((env).2).1).1).2).1 ^^^ _rtl_expr_628)
  let _rtl_expr_630 : BitVec 8 := (_rtl_expr_629 ^^^ (((((env).2).1).1).2).2)
  let _rtl_expr_631 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_630)
  let _rtl_expr_632 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_631)
  let _rtl_expr_633 : BitVec 8 := (_rtl_expr_609 ^^^ _rtl_expr_632)
  let _rtl_expr_634 : BitVec 7 := BitVec.extractLsb 6 0 ((((((env).2).1).2).2).1)
  let _rtl_expr_635 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_634) (boolToBitVec (false))
  let _rtl_expr_636 : Bool := BitVec.getLsbD ((((((env).2).1).2).2).1) 7
  let _rtl_expr_637 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_636)) (boolToBitVec (_rtl_expr_636))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_636)) (boolToBitVec (_rtl_expr_636)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_636)) (boolToBitVec (_rtl_expr_636))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_636)) (boolToBitVec (_rtl_expr_636))))
  let _rtl_expr_638 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_637)
  let _rtl_expr_639 : BitVec 8 := (_rtl_expr_635 ^^^ _rtl_expr_638)
  ((((((((env).1).1).1).1, ((((((env).1).1).1).2).1, (((((env).1).1).1).2).2)), (((((env).1).1).2).1, ((((((env).1).1).2).2).1, (((((env).1).1).2).2).2))), ((((((env).1).2).1).1, ((((((env).1).2).1).2).1, (((((env).1).2).1).2).2)), ((((((env).1).2).2).1).1, ((((((env).1).2).2).1).2, (((((env).1).2).2).2).1)))), ((((((((env).1).2).2).2).2, ((((((env).2).1).1).2).1, ((((env).2).1).2).1)), ((((((env).2).1).2).2).2, (((((env).2).2).1).1, (((((env).2).2).1).2).2))), (((((((env).2).2).2).1).1, ((((((env).2).2).2).1).2, _rtl_expr_601)), ((_rtl_expr_606, _rtl_expr_629), (_rtl_expr_633, _rtl_expr_639)))))

private def _rtl_eval_block_19 (s : aes_coreState) (i : aes_coreInputs) (env : ((((Bool × (BitVec 128 × Bool)) × (BitVec 128 × (Bool × BitVec 128))) × ((BitVec 128 × (BitVec 32 × BitVec 8)) × (BitVec 8 × (BitVec 8 × BitVec 8)))) × (((BitVec 8 × (BitVec 8 × BitVec 8)) × (BitVec 8 × (BitVec 8 × BitVec 8))) × ((BitVec 8 × (BitVec 8 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8)))))) : ((((Bool × BitVec 128) × (Bool × BitVec 128)) × ((Bool × BitVec 128) × (BitVec 128 × BitVec 32))) × (((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × (BitVec 8 × BitVec 8))))) :=
  let _rtl_expr_640 : BitVec 8 := BitVec.extractLsb 7 0 ((((((env).2).2).2).2).2)
  let _rtl_expr_641 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_640)
  let _rtl_expr_642 : BitVec 8 := (((((env).2).1).2).1 ^^^ _rtl_expr_641)
  let _rtl_expr_643 : BitVec 8 := (_rtl_expr_642 ^^^ (((((env).2).1).1).2).2)
  let _rtl_expr_644 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_643)
  let _rtl_expr_645 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_644)
  let _rtl_expr_646 : BitVec 8 := ((((((env).2).2).2).2).1 ^^^ _rtl_expr_645)
  let _rtl_expr_647 : BitVec 7 := BitVec.extractLsb 6 0 ((((((env).2).2).1).2).1)
  let _rtl_expr_648 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_647) (boolToBitVec (false))
  let _rtl_expr_649 : Bool := BitVec.getLsbD ((((((env).2).2).1).2).1) 7
  let _rtl_expr_650 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_649)) (boolToBitVec (_rtl_expr_649))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_649)) (boolToBitVec (_rtl_expr_649)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_649)) (boolToBitVec (_rtl_expr_649))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_649)) (boolToBitVec (_rtl_expr_649))))
  let _rtl_expr_651 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_650)
  let _rtl_expr_652 : BitVec 8 := (_rtl_expr_648 ^^^ _rtl_expr_651)
  let _rtl_expr_653 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_652)
  let _rtl_expr_654 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_653)
  let _rtl_expr_655 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_654)
  let _rtl_expr_656 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_655)
  let _rtl_expr_657 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_656) (boolToBitVec (false))
  let _rtl_expr_658 : Bool := BitVec.getLsbD (_rtl_expr_655) 7
  let _rtl_expr_659 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_658)) (boolToBitVec (_rtl_expr_658))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_658)) (boolToBitVec (_rtl_expr_658)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_658)) (boolToBitVec (_rtl_expr_658))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_658)) (boolToBitVec (_rtl_expr_658))))
  let _rtl_expr_660 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_659)
  let _rtl_expr_661 : BitVec 8 := (_rtl_expr_657 ^^^ _rtl_expr_660)
  let _rtl_expr_662 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_661)
  let _rtl_expr_663 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_662)
  let _rtl_expr_664 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_663)
  let _rtl_expr_665 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_664)
  let _rtl_expr_666 : BitVec 8 := ((((((env).2).2).1).2).2 ^^^ _rtl_expr_665)
  let _rtl_expr_667 : BitVec 8 := (_rtl_expr_666 ^^^ (((((env).2).1).2).2).2)
  let _rtl_expr_668 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_667)
  let _rtl_expr_669 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_668)
  let _rtl_expr_670 : BitVec 8 := (_rtl_expr_646 ^^^ _rtl_expr_669)
  let _rtl_expr_671 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_670)
  let _rtl_expr_672 : BitVec 8 := ((((((env).1).2).2).2).1 ^^^ (((((env).1).2).1).2).2)
  let _rtl_expr_673 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_672)
  let _rtl_expr_674 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_673)
  let _rtl_expr_675 : BitVec 8 := ((((((env).2).1).1).2).1 ^^^ ((((env).2).1).1).1)
  let _rtl_expr_676 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_675)
  let _rtl_expr_677 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_676)
  let _rtl_expr_678 : BitVec 8 := (_rtl_expr_674 ^^^ _rtl_expr_677)
  let _rtl_expr_679 : BitVec 8 := ((((((env).2).1).2).2).1 ^^^ _rtl_expr_641)
  let _rtl_expr_680 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_679)
  let _rtl_expr_681 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_680)
  let _rtl_expr_682 : BitVec 8 := (_rtl_expr_678 ^^^ _rtl_expr_681)
  let _rtl_expr_683 : BitVec 7 := BitVec.extractLsb 6 0 (((((env).2).2).1).1)
  let _rtl_expr_684 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_683) (boolToBitVec (false))
  let _rtl_expr_685 : Bool := BitVec.getLsbD (((((env).2).2).1).1) 7
  let _rtl_expr_686 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_685)) (boolToBitVec (_rtl_expr_685))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_685)) (boolToBitVec (_rtl_expr_685)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_685)) (boolToBitVec (_rtl_expr_685))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_685)) (boolToBitVec (_rtl_expr_685))))
  let _rtl_expr_687 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_686)
  let _rtl_expr_688 : BitVec 8 := (_rtl_expr_684 ^^^ _rtl_expr_687)
  let _rtl_expr_689 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_688)
  let _rtl_expr_690 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_689)
  let _rtl_expr_691 : BitVec 8 := ((((((env).2).2).1).2).2 ^^^ _rtl_expr_690)
  let _rtl_expr_692 : BitVec 8 := (_rtl_expr_691 ^^^ (((((env).2).1).2).2).2)
  let _rtl_expr_693 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_692)
  let _rtl_expr_694 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_693)
  let _rtl_expr_695 : BitVec 8 := (_rtl_expr_682 ^^^ _rtl_expr_694)
  let _rtl_expr_696 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_695)
  let _rtl_expr_697 : BitVec 8 := (((((env).1).2).2).1 ^^^ (((((env).1).2).2).2).2)
  let _rtl_expr_698 : BitVec 8 := (_rtl_expr_697 ^^^ (((((env).1).2).1).2).2)
  let _rtl_expr_699 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_698)
  let _rtl_expr_700 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_699)
  let _rtl_expr_701 : BitVec 8 := ((((((env).2).2).2).1).2 ^^^ ((((env).2).1).1).1)
  let _rtl_expr_702 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_701)
  let _rtl_expr_703 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_702)
  ((((((((env).1).1).1).1, (((((env).1).1).1).2).1), ((((((env).1).1).1).2).2, ((((env).1).1).2).1)), (((((((env).1).1).2).2).1, (((((env).1).1).2).2).2), (((((env).1).2).1).1, (((((env).1).2).1).2).1))), ((((((((env).2).1).1).2).2, ((((env).2).1).2).1), ((((((env).2).2).2).1).1, _rtl_expr_666)), ((_rtl_expr_671, _rtl_expr_690), (_rtl_expr_696, (_rtl_expr_700, _rtl_expr_703)))))

private def _rtl_eval_block_20 (s : aes_coreState) (i : aes_coreInputs) (env : ((((Bool × BitVec 128) × (Bool × BitVec 128)) × ((Bool × BitVec 128) × (BitVec 128 × BitVec 32))) × (((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × (BitVec 8 × BitVec 8)))))) : (((Bool × (BitVec 128 × Bool)) × ((BitVec 128 × Bool) × (BitVec 128 × BitVec 128))) × (((BitVec 32 × BitVec 32) × (BitVec 32 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8)))) :=
  let _rtl_expr_704 : BitVec 8 := ((((((env).2).2).2).2).1 ^^^ (((((env).2).2).2).2).2)
  let _rtl_expr_705 : BitVec 8 := (((((env).2).1).1).2 ^^^ ((((env).2).1).1).1)
  let _rtl_expr_706 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_705)
  let _rtl_expr_707 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_706)
  let _rtl_expr_708 : BitVec 8 := (_rtl_expr_704 ^^^ _rtl_expr_707)
  let _rtl_expr_709 : BitVec 8 := (((((env).2).1).2).2 ^^^ ((((env).2).2).1).2)
  let _rtl_expr_710 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_709)
  let _rtl_expr_711 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_710)
  let _rtl_expr_712 : BitVec 8 := (_rtl_expr_708 ^^^ _rtl_expr_711)
  let _rtl_expr_713 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_712)
  let _rtl_expr_714 : BitVec 32 := BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (((((env).2).1).2).1) (((((env).2).2).1).1)) (BitVec.append (n := 8) (m := 8) (((((env).2).2).2).1) (_rtl_expr_713))
  let _rtl_expr_715 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_714)
  let _rtl_expr_716 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_715)
  let _rtl_expr_717 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_716)
  let _rtl_expr_718 : BitVec 32 := BitVec.extractLsb 63 32 (((((env).1).2).2).1)
  let _rtl_expr_719 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_718)
  let _rtl_expr_720 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_719)
  let _rtl_expr_721 : BitVec 8 := BitVec.extractLsb 31 24 (_rtl_expr_720)
  let _rtl_expr_722 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_721)
  let _rtl_expr_723 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_722)
  let _rtl_expr_724 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_723)
  let _rtl_expr_725 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_724)
  let _rtl_expr_726 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_725)
  let _rtl_expr_727 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_726)
  let _rtl_expr_728 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_727) (boolToBitVec (false))
  let _rtl_expr_729 : Bool := BitVec.getLsbD (_rtl_expr_726) 7
  let _rtl_expr_730 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_729)) (boolToBitVec (_rtl_expr_729))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_729)) (boolToBitVec (_rtl_expr_729)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_729)) (boolToBitVec (_rtl_expr_729))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_729)) (boolToBitVec (_rtl_expr_729))))
  let _rtl_expr_731 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_730)
  let _rtl_expr_732 : BitVec 8 := (_rtl_expr_728 ^^^ _rtl_expr_731)
  let _rtl_expr_733 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_732)
  let _rtl_expr_734 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_733)
  let _rtl_expr_735 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_734)
  let _rtl_expr_736 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_735)
  let _rtl_expr_737 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_736) (boolToBitVec (false))
  let _rtl_expr_738 : Bool := BitVec.getLsbD (_rtl_expr_735) 7
  let _rtl_expr_739 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_738)) (boolToBitVec (_rtl_expr_738))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_738)) (boolToBitVec (_rtl_expr_738)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_738)) (boolToBitVec (_rtl_expr_738))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_738)) (boolToBitVec (_rtl_expr_738))))
  let _rtl_expr_740 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_739)
  let _rtl_expr_741 : BitVec 8 := (_rtl_expr_737 ^^^ _rtl_expr_740)
  let _rtl_expr_742 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_741)
  let _rtl_expr_743 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_742)
  let _rtl_expr_744 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_743)
  let _rtl_expr_745 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_744)
  let _rtl_expr_746 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_745)
  let _rtl_expr_747 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_746)
  let _rtl_expr_748 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_747) (boolToBitVec (false))
  let _rtl_expr_749 : Bool := BitVec.getLsbD (_rtl_expr_746) 7
  let _rtl_expr_750 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_749)) (boolToBitVec (_rtl_expr_749))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_749)) (boolToBitVec (_rtl_expr_749)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_749)) (boolToBitVec (_rtl_expr_749))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_749)) (boolToBitVec (_rtl_expr_749))))
  let _rtl_expr_751 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_750)
  let _rtl_expr_752 : BitVec 8 := (_rtl_expr_748 ^^^ _rtl_expr_751)
  let _rtl_expr_753 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_752)
  let _rtl_expr_754 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_753)
  let _rtl_expr_755 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_754)
  let _rtl_expr_756 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_755)
  let _rtl_expr_757 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_725)
  let _rtl_expr_758 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_757) (boolToBitVec (false))
  let _rtl_expr_759 : Bool := BitVec.getLsbD (_rtl_expr_725) 7
  let _rtl_expr_760 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_759)) (boolToBitVec (_rtl_expr_759))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_759)) (boolToBitVec (_rtl_expr_759)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_759)) (boolToBitVec (_rtl_expr_759))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_759)) (boolToBitVec (_rtl_expr_759))))
  let _rtl_expr_761 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_760)
  let _rtl_expr_762 : BitVec 8 := (_rtl_expr_758 ^^^ _rtl_expr_761)
  let _rtl_expr_763 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_762)
  let _rtl_expr_764 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_763)
  let _rtl_expr_765 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_764)
  let _rtl_expr_766 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_765)
  let _rtl_expr_767 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_766) (boolToBitVec (false))
  (((((((env).1).1).1).1, (((((env).1).1).1).2, ((((env).1).1).2).1)), ((((((env).1).1).2).2, ((((env).1).2).1).1), (((((env).1).2).1).2, ((((env).1).2).2).1))), (((((((env).1).2).2).2, _rtl_expr_717), (_rtl_expr_720, _rtl_expr_723)), ((_rtl_expr_724, _rtl_expr_756), (_rtl_expr_765, _rtl_expr_767))))

private def _rtl_eval_block_21 (s : aes_coreState) (i : aes_coreInputs) (env : (((Bool × (BitVec 128 × Bool)) × ((BitVec 128 × Bool) × (BitVec 128 × BitVec 128))) × (((BitVec 32 × BitVec 32) × (BitVec 32 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8))))) : ((((Bool × BitVec 128) × (Bool × BitVec 128)) × ((Bool × BitVec 128) × (BitVec 128 × (BitVec 32 × BitVec 32)))) × (((BitVec 32 × BitVec 8) × (BitVec 8 × (BitVec 8 × BitVec 8))) × ((BitVec 8 × BitVec 8) × (BitVec 8 × (BitVec 8 × BitVec 8))))) :=
  let _rtl_expr_768 : Bool := BitVec.getLsbD (((((env).2).2).2).1) 7
  let _rtl_expr_769 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_768)) (boolToBitVec (_rtl_expr_768))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_768)) (boolToBitVec (_rtl_expr_768)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_768)) (boolToBitVec (_rtl_expr_768))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_768)) (boolToBitVec (_rtl_expr_768))))
  let _rtl_expr_770 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_769)
  let _rtl_expr_771 : BitVec 8 := (((((env).2).2).2).2 ^^^ _rtl_expr_770)
  let _rtl_expr_772 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_771)
  let _rtl_expr_773 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_772)
  let _rtl_expr_774 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_773)
  let _rtl_expr_775 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_774)
  let _rtl_expr_776 : BitVec 8 := (((((env).2).2).1).2 ^^^ _rtl_expr_775)
  let _rtl_expr_777 : BitVec 7 := BitVec.extractLsb 6 0 (((((env).2).2).1).1)
  let _rtl_expr_778 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_777) (boolToBitVec (false))
  let _rtl_expr_779 : Bool := BitVec.getLsbD (((((env).2).2).1).1) 7
  let _rtl_expr_780 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_779)) (boolToBitVec (_rtl_expr_779))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_779)) (boolToBitVec (_rtl_expr_779)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_779)) (boolToBitVec (_rtl_expr_779))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_779)) (boolToBitVec (_rtl_expr_779))))
  let _rtl_expr_781 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_780)
  let _rtl_expr_782 : BitVec 8 := (_rtl_expr_778 ^^^ _rtl_expr_781)
  let _rtl_expr_783 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_782)
  let _rtl_expr_784 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_783)
  let _rtl_expr_785 : BitVec 8 := (_rtl_expr_776 ^^^ _rtl_expr_784)
  let _rtl_expr_786 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_785)
  let _rtl_expr_787 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_786)
  let _rtl_expr_788 : BitVec 8 := BitVec.extractLsb 23 16 (((((env).2).1).2).1)
  let _rtl_expr_789 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_788)
  let _rtl_expr_790 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_789)
  let _rtl_expr_791 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_790)
  let _rtl_expr_792 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_791)
  let _rtl_expr_793 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_792)
  let _rtl_expr_794 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_793)
  let _rtl_expr_795 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_794) (boolToBitVec (false))
  let _rtl_expr_796 : Bool := BitVec.getLsbD (_rtl_expr_793) 7
  let _rtl_expr_797 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_796)) (boolToBitVec (_rtl_expr_796))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_796)) (boolToBitVec (_rtl_expr_796)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_796)) (boolToBitVec (_rtl_expr_796))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_796)) (boolToBitVec (_rtl_expr_796))))
  let _rtl_expr_798 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_797)
  let _rtl_expr_799 : BitVec 8 := (_rtl_expr_795 ^^^ _rtl_expr_798)
  let _rtl_expr_800 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_799)
  let _rtl_expr_801 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_800)
  let _rtl_expr_802 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_801)
  let _rtl_expr_803 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_802)
  let _rtl_expr_804 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_803) (boolToBitVec (false))
  let _rtl_expr_805 : Bool := BitVec.getLsbD (_rtl_expr_802) 7
  let _rtl_expr_806 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_805)) (boolToBitVec (_rtl_expr_805))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_805)) (boolToBitVec (_rtl_expr_805)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_805)) (boolToBitVec (_rtl_expr_805))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_805)) (boolToBitVec (_rtl_expr_805))))
  let _rtl_expr_807 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_806)
  let _rtl_expr_808 : BitVec 8 := (_rtl_expr_804 ^^^ _rtl_expr_807)
  let _rtl_expr_809 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_808)
  let _rtl_expr_810 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_809)
  let _rtl_expr_811 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_810)
  let _rtl_expr_812 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_811)
  let _rtl_expr_813 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_812)
  let _rtl_expr_814 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_813)
  let _rtl_expr_815 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_814) (boolToBitVec (false))
  let _rtl_expr_816 : Bool := BitVec.getLsbD (_rtl_expr_813) 7
  let _rtl_expr_817 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_816)) (boolToBitVec (_rtl_expr_816))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_816)) (boolToBitVec (_rtl_expr_816)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_816)) (boolToBitVec (_rtl_expr_816))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_816)) (boolToBitVec (_rtl_expr_816))))
  let _rtl_expr_818 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_817)
  let _rtl_expr_819 : BitVec 8 := (_rtl_expr_815 ^^^ _rtl_expr_818)
  let _rtl_expr_820 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_819)
  let _rtl_expr_821 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_820)
  let _rtl_expr_822 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_821)
  let _rtl_expr_823 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_822)
  let _rtl_expr_824 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_791)
  let _rtl_expr_825 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_824) (boolToBitVec (false))
  let _rtl_expr_826 : Bool := BitVec.getLsbD (_rtl_expr_791) 7
  let _rtl_expr_827 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_826)) (boolToBitVec (_rtl_expr_826))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_826)) (boolToBitVec (_rtl_expr_826)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_826)) (boolToBitVec (_rtl_expr_826))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_826)) (boolToBitVec (_rtl_expr_826))))
  let _rtl_expr_828 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_827)
  let _rtl_expr_829 : BitVec 8 := (_rtl_expr_825 ^^^ _rtl_expr_828)
  let _rtl_expr_830 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_829)
  let _rtl_expr_831 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_830)
  (((((((env).1).1).1, ((((env).1).1).2).1), (((((env).1).1).2).2, ((((env).1).2).1).1)), ((((((env).1).2).1).2, ((((env).1).2).2).1), (((((env).1).2).2).2, (((((env).2).1).1).1, ((((env).2).1).1).2)))), (((((((env).2).1).2).1, ((((env).2).1).2).2), (((((env).2).2).1).2, (_rtl_expr_776, _rtl_expr_784))), ((_rtl_expr_787, _rtl_expr_790), (_rtl_expr_792, (_rtl_expr_823, _rtl_expr_831)))))

private def _rtl_eval_block_22 (s : aes_coreState) (i : aes_coreInputs) (env : ((((Bool × BitVec 128) × (Bool × BitVec 128)) × ((Bool × BitVec 128) × (BitVec 128 × (BitVec 32 × BitVec 32)))) × (((BitVec 32 × BitVec 8) × (BitVec 8 × (BitVec 8 × BitVec 8))) × ((BitVec 8 × BitVec 8) × (BitVec 8 × (BitVec 8 × BitVec 8)))))) : ((((Bool × (BitVec 128 × Bool)) × (BitVec 128 × (Bool × BitVec 128))) × ((BitVec 128 × (BitVec 32 × BitVec 32)) × (BitVec 32 × (BitVec 8 × BitVec 8)))) × (((BitVec 8 × (BitVec 8 × BitVec 8)) × (BitVec 8 × (BitVec 8 × BitVec 8))) × ((BitVec 8 × (BitVec 8 × BitVec 8)) × (BitVec 8 × (BitVec 8 × BitVec 8))))) :=
  let _rtl_expr_832 : BitVec 8 := ((((((env).2).2).2).2).1 ^^^ (((((env).2).2).2).2).2)
  let _rtl_expr_833 : BitVec 8 := (_rtl_expr_832 ^^^ ((((env).2).2).1).2)
  let _rtl_expr_834 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_833)
  let _rtl_expr_835 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_834)
  let _rtl_expr_836 : BitVec 8 := (((((env).2).2).1).1 ^^^ _rtl_expr_835)
  let _rtl_expr_837 : BitVec 8 := BitVec.extractLsb 15 8 (((((env).2).1).1).1)
  let _rtl_expr_838 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_837)
  let _rtl_expr_839 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_838)
  let _rtl_expr_840 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_839)
  let _rtl_expr_841 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_840)
  let _rtl_expr_842 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_841)
  let _rtl_expr_843 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_842)
  let _rtl_expr_844 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_843) (boolToBitVec (false))
  let _rtl_expr_845 : Bool := BitVec.getLsbD (_rtl_expr_842) 7
  let _rtl_expr_846 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_845)) (boolToBitVec (_rtl_expr_845))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_845)) (boolToBitVec (_rtl_expr_845)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_845)) (boolToBitVec (_rtl_expr_845))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_845)) (boolToBitVec (_rtl_expr_845))))
  let _rtl_expr_847 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_846)
  let _rtl_expr_848 : BitVec 8 := (_rtl_expr_844 ^^^ _rtl_expr_847)
  let _rtl_expr_849 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_848)
  let _rtl_expr_850 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_849)
  let _rtl_expr_851 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_850)
  let _rtl_expr_852 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_851)
  let _rtl_expr_853 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_852) (boolToBitVec (false))
  let _rtl_expr_854 : Bool := BitVec.getLsbD (_rtl_expr_851) 7
  let _rtl_expr_855 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_854)) (boolToBitVec (_rtl_expr_854))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_854)) (boolToBitVec (_rtl_expr_854)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_854)) (boolToBitVec (_rtl_expr_854))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_854)) (boolToBitVec (_rtl_expr_854))))
  let _rtl_expr_856 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_855)
  let _rtl_expr_857 : BitVec 8 := (_rtl_expr_853 ^^^ _rtl_expr_856)
  let _rtl_expr_858 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_857)
  let _rtl_expr_859 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_858)
  let _rtl_expr_860 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_859)
  let _rtl_expr_861 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_860)
  let _rtl_expr_862 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_861)
  let _rtl_expr_863 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_862)
  let _rtl_expr_864 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_863) (boolToBitVec (false))
  let _rtl_expr_865 : Bool := BitVec.getLsbD (_rtl_expr_862) 7
  let _rtl_expr_866 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_865)) (boolToBitVec (_rtl_expr_865))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_865)) (boolToBitVec (_rtl_expr_865)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_865)) (boolToBitVec (_rtl_expr_865))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_865)) (boolToBitVec (_rtl_expr_865))))
  let _rtl_expr_867 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_866)
  let _rtl_expr_868 : BitVec 8 := (_rtl_expr_864 ^^^ _rtl_expr_867)
  let _rtl_expr_869 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_868)
  let _rtl_expr_870 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_869)
  let _rtl_expr_871 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_870)
  let _rtl_expr_872 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_871)
  let _rtl_expr_873 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_841)
  let _rtl_expr_874 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_873) (boolToBitVec (false))
  let _rtl_expr_875 : Bool := BitVec.getLsbD (_rtl_expr_841) 7
  let _rtl_expr_876 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_875)) (boolToBitVec (_rtl_expr_875))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_875)) (boolToBitVec (_rtl_expr_875)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_875)) (boolToBitVec (_rtl_expr_875))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_875)) (boolToBitVec (_rtl_expr_875))))
  let _rtl_expr_877 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_876)
  let _rtl_expr_878 : BitVec 8 := (_rtl_expr_874 ^^^ _rtl_expr_877)
  let _rtl_expr_879 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_878)
  let _rtl_expr_880 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_879)
  let _rtl_expr_881 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_880)
  let _rtl_expr_882 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_881)
  let _rtl_expr_883 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_882) (boolToBitVec (false))
  let _rtl_expr_884 : Bool := BitVec.getLsbD (_rtl_expr_881) 7
  let _rtl_expr_885 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_884)) (boolToBitVec (_rtl_expr_884))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_884)) (boolToBitVec (_rtl_expr_884)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_884)) (boolToBitVec (_rtl_expr_884))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_884)) (boolToBitVec (_rtl_expr_884))))
  let _rtl_expr_886 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_885)
  let _rtl_expr_887 : BitVec 8 := (_rtl_expr_883 ^^^ _rtl_expr_886)
  let _rtl_expr_888 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_887)
  let _rtl_expr_889 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_888)
  let _rtl_expr_890 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_889)
  let _rtl_expr_891 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_890)
  let _rtl_expr_892 : BitVec 8 := (_rtl_expr_872 ^^^ _rtl_expr_891)
  let _rtl_expr_893 : BitVec 8 := (_rtl_expr_892 ^^^ _rtl_expr_839)
  let _rtl_expr_894 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_893)
  let _rtl_expr_895 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_894)
  ((((((((env).1).1).1).1, (((((env).1).1).1).2, ((((env).1).1).2).1)), (((((env).1).1).2).2, (((((env).1).2).1).1, ((((env).1).2).1).2))), ((((((env).1).2).2).1, ((((((env).1).2).2).2).1, (((((env).1).2).2).2).2)), (((((env).2).1).1).1, (((((env).2).1).1).2, ((((env).2).1).2).1)))), ((((((((env).2).1).2).2).1, ((((((env).2).1).2).2).2, ((((env).2).2).1).2)), (((((env).2).2).2).1, ((((((env).2).2).2).2).1, (((((env).2).2).2).2).2))), ((_rtl_expr_836, (_rtl_expr_839, _rtl_expr_840)), (_rtl_expr_872, (_rtl_expr_892, _rtl_expr_895)))))

private def _rtl_eval_block_23 (s : aes_coreState) (i : aes_coreInputs) (env : ((((Bool × (BitVec 128 × Bool)) × (BitVec 128 × (Bool × BitVec 128))) × ((BitVec 128 × (BitVec 32 × BitVec 32)) × (BitVec 32 × (BitVec 8 × BitVec 8)))) × (((BitVec 8 × (BitVec 8 × BitVec 8)) × (BitVec 8 × (BitVec 8 × BitVec 8))) × ((BitVec 8 × (BitVec 8 × BitVec 8)) × (BitVec 8 × (BitVec 8 × BitVec 8)))))) : ((((Bool × (BitVec 128 × Bool)) × (BitVec 128 × (Bool × BitVec 128))) × ((BitVec 128 × (BitVec 32 × BitVec 32)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8)))) × (((BitVec 8 × (BitVec 8 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8))) × ((BitVec 8 × (BitVec 8 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8))))) :=
  let _rtl_expr_896 : BitVec 8 := (((((env).2).2).1).1 ^^^ (((((env).2).2).2).2).2)
  let _rtl_expr_897 : BitVec 8 := BitVec.extractLsb 7 0 (((((env).1).2).2).1)
  let _rtl_expr_898 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_897)
  let _rtl_expr_899 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_898)
  let _rtl_expr_900 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_899)
  let _rtl_expr_901 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_900)
  let _rtl_expr_902 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_901)
  let _rtl_expr_903 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_902)
  let _rtl_expr_904 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_903) (boolToBitVec (false))
  let _rtl_expr_905 : Bool := BitVec.getLsbD (_rtl_expr_902) 7
  let _rtl_expr_906 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_905)) (boolToBitVec (_rtl_expr_905))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_905)) (boolToBitVec (_rtl_expr_905)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_905)) (boolToBitVec (_rtl_expr_905))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_905)) (boolToBitVec (_rtl_expr_905))))
  let _rtl_expr_907 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_906)
  let _rtl_expr_908 : BitVec 8 := (_rtl_expr_904 ^^^ _rtl_expr_907)
  let _rtl_expr_909 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_908)
  let _rtl_expr_910 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_909)
  let _rtl_expr_911 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_910)
  let _rtl_expr_912 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_911)
  let _rtl_expr_913 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_912) (boolToBitVec (false))
  let _rtl_expr_914 : Bool := BitVec.getLsbD (_rtl_expr_911) 7
  let _rtl_expr_915 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_914)) (boolToBitVec (_rtl_expr_914))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_914)) (boolToBitVec (_rtl_expr_914)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_914)) (boolToBitVec (_rtl_expr_914))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_914)) (boolToBitVec (_rtl_expr_914))))
  let _rtl_expr_916 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_915)
  let _rtl_expr_917 : BitVec 8 := (_rtl_expr_913 ^^^ _rtl_expr_916)
  let _rtl_expr_918 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_917)
  let _rtl_expr_919 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_918)
  let _rtl_expr_920 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_919)
  let _rtl_expr_921 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_920)
  let _rtl_expr_922 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_921)
  let _rtl_expr_923 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_922)
  let _rtl_expr_924 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_923) (boolToBitVec (false))
  let _rtl_expr_925 : Bool := BitVec.getLsbD (_rtl_expr_922) 7
  let _rtl_expr_926 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_925)) (boolToBitVec (_rtl_expr_925))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_925)) (boolToBitVec (_rtl_expr_925)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_925)) (boolToBitVec (_rtl_expr_925))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_925)) (boolToBitVec (_rtl_expr_925))))
  let _rtl_expr_927 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_926)
  let _rtl_expr_928 : BitVec 8 := (_rtl_expr_924 ^^^ _rtl_expr_927)
  let _rtl_expr_929 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_928)
  let _rtl_expr_930 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_929)
  let _rtl_expr_931 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_930)
  let _rtl_expr_932 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_931)
  let _rtl_expr_933 : BitVec 8 := (_rtl_expr_932 ^^^ _rtl_expr_899)
  let _rtl_expr_934 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_933)
  let _rtl_expr_935 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_934)
  let _rtl_expr_936 : BitVec 8 := (_rtl_expr_896 ^^^ _rtl_expr_935)
  let _rtl_expr_937 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_936)
  let _rtl_expr_938 : BitVec 8 := ((((((env).1).2).2).2).2 ^^^ (((((env).1).2).2).2).1)
  let _rtl_expr_939 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_938)
  let _rtl_expr_940 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_939)
  let _rtl_expr_941 : BitVec 7 := BitVec.extractLsb 6 0 (((((env).2).1).2).1)
  let _rtl_expr_942 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_941) (boolToBitVec (false))
  let _rtl_expr_943 : Bool := BitVec.getLsbD (((((env).2).1).2).1) 7
  let _rtl_expr_944 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_943)) (boolToBitVec (_rtl_expr_943))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_943)) (boolToBitVec (_rtl_expr_943)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_943)) (boolToBitVec (_rtl_expr_943))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_943)) (boolToBitVec (_rtl_expr_943))))
  let _rtl_expr_945 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_944)
  let _rtl_expr_946 : BitVec 8 := (_rtl_expr_942 ^^^ _rtl_expr_945)
  let _rtl_expr_947 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_946)
  let _rtl_expr_948 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_947)
  let _rtl_expr_949 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_948)
  let _rtl_expr_950 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_949)
  let _rtl_expr_951 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_950) (boolToBitVec (false))
  let _rtl_expr_952 : Bool := BitVec.getLsbD (_rtl_expr_949) 7
  let _rtl_expr_953 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_952)) (boolToBitVec (_rtl_expr_952))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_952)) (boolToBitVec (_rtl_expr_952)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_952)) (boolToBitVec (_rtl_expr_952))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_952)) (boolToBitVec (_rtl_expr_952))))
  let _rtl_expr_954 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_953)
  let _rtl_expr_955 : BitVec 8 := (_rtl_expr_951 ^^^ _rtl_expr_954)
  let _rtl_expr_956 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_955)
  let _rtl_expr_957 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_956)
  let _rtl_expr_958 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_957)
  let _rtl_expr_959 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_958)
  ((((((((env).1).1).1).1, ((((((env).1).1).1).2).1, (((((env).1).1).1).2).2)), (((((env).1).1).2).1, ((((((env).1).1).2).2).1, (((((env).1).1).2).2).2))), ((((((env).1).2).1).1, ((((((env).1).2).1).2).1, (((((env).1).2).1).2).2)), (((((((env).1).2).2).2).1, (((((env).1).2).2).2).2), (((((env).2).1).1).1, (((((env).2).1).1).2).1)))), ((((((((env).2).1).1).2).2, ((((((env).2).1).2).2).1, (((((env).2).1).2).2).2)), (((((((env).2).2).1).2).1, (((((env).2).2).1).2).2), (((((env).2).2).2).1, (((((env).2).2).2).2).1))), ((_rtl_expr_899, (_rtl_expr_900, _rtl_expr_901)), ((_rtl_expr_932, _rtl_expr_937), (_rtl_expr_940, _rtl_expr_959)))))

private def _rtl_eval_block_24 (s : aes_coreState) (i : aes_coreInputs) (env : ((((Bool × (BitVec 128 × Bool)) × (BitVec 128 × (Bool × BitVec 128))) × ((BitVec 128 × (BitVec 32 × BitVec 32)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8)))) × (((BitVec 8 × (BitVec 8 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8))) × ((BitVec 8 × (BitVec 8 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8)))))) : ((((Bool × BitVec 128) × (Bool × (BitVec 128 × Bool))) × ((BitVec 128 × (BitVec 128 × BitVec 32)) × (BitVec 32 × (BitVec 8 × BitVec 8)))) × (((BitVec 8 × BitVec 8) × (BitVec 8 × (BitVec 8 × BitVec 8))) × ((BitVec 8 × (BitVec 8 × BitVec 8)) × (BitVec 8 × (BitVec 8 × BitVec 8))))) :=
  let _rtl_expr_960 : BitVec 8 := ((((((env).2).1).1).2).1 ^^^ (((((env).2).2).2).2).2)
  let _rtl_expr_961 : BitVec 8 := (_rtl_expr_960 ^^^ (((((env).2).1).1).2).2)
  let _rtl_expr_962 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_961)
  let _rtl_expr_963 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_962)
  let _rtl_expr_964 : BitVec 8 := ((((((env).2).2).2).2).1 ^^^ _rtl_expr_963)
  let _rtl_expr_965 : BitVec 7 := BitVec.extractLsb 6 0 ((((((env).2).1).2).1).2)
  let _rtl_expr_966 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_965) (boolToBitVec (false))
  let _rtl_expr_967 : Bool := BitVec.getLsbD ((((((env).2).1).2).1).2) 7
  let _rtl_expr_968 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_967)) (boolToBitVec (_rtl_expr_967))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_967)) (boolToBitVec (_rtl_expr_967)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_967)) (boolToBitVec (_rtl_expr_967))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_967)) (boolToBitVec (_rtl_expr_967))))
  let _rtl_expr_969 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_968)
  let _rtl_expr_970 : BitVec 8 := (_rtl_expr_966 ^^^ _rtl_expr_969)
  let _rtl_expr_971 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_970)
  let _rtl_expr_972 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_971)
  let _rtl_expr_973 : BitVec 8 := ((((((env).2).1).2).2).1 ^^^ _rtl_expr_972)
  let _rtl_expr_974 : BitVec 8 := (_rtl_expr_973 ^^^ (((((env).2).1).2).1).1)
  let _rtl_expr_975 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_974)
  let _rtl_expr_976 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_975)
  let _rtl_expr_977 : BitVec 8 := (_rtl_expr_964 ^^^ _rtl_expr_976)
  let _rtl_expr_978 : BitVec 7 := BitVec.extractLsb 6 0 ((((((env).2).2).1).2).2)
  let _rtl_expr_979 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_978) (boolToBitVec (false))
  let _rtl_expr_980 : Bool := BitVec.getLsbD ((((((env).2).2).1).2).2) 7
  let _rtl_expr_981 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_980)) (boolToBitVec (_rtl_expr_980))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_980)) (boolToBitVec (_rtl_expr_980)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_980)) (boolToBitVec (_rtl_expr_980))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_980)) (boolToBitVec (_rtl_expr_980))))
  let _rtl_expr_982 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_981)
  let _rtl_expr_983 : BitVec 8 := (_rtl_expr_979 ^^^ _rtl_expr_982)
  let _rtl_expr_984 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_983)
  let _rtl_expr_985 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_984)
  let _rtl_expr_986 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_985)
  let _rtl_expr_987 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_986)
  let _rtl_expr_988 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_987) (boolToBitVec (false))
  let _rtl_expr_989 : Bool := BitVec.getLsbD (_rtl_expr_986) 7
  let _rtl_expr_990 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_989)) (boolToBitVec (_rtl_expr_989))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_989)) (boolToBitVec (_rtl_expr_989)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_989)) (boolToBitVec (_rtl_expr_989))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_989)) (boolToBitVec (_rtl_expr_989))))
  let _rtl_expr_991 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_990)
  let _rtl_expr_992 : BitVec 8 := (_rtl_expr_988 ^^^ _rtl_expr_991)
  let _rtl_expr_993 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_992)
  let _rtl_expr_994 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_993)
  let _rtl_expr_995 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_994)
  let _rtl_expr_996 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_995)
  let _rtl_expr_997 : BitVec 8 := ((((((env).2).2).2).1).1 ^^^ _rtl_expr_996)
  let _rtl_expr_998 : BitVec 8 := (_rtl_expr_997 ^^^ ((((env).2).2).1).1)
  let _rtl_expr_999 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_998)
  let _rtl_expr_1000 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_999)
  let _rtl_expr_1001 : BitVec 8 := (_rtl_expr_977 ^^^ _rtl_expr_1000)
  let _rtl_expr_1002 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1001)
  let _rtl_expr_1003 : BitVec 8 := ((((((env).1).2).2).2).1 ^^^ (((((env).1).2).2).1).1)
  let _rtl_expr_1004 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1003)
  let _rtl_expr_1005 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1004)
  let _rtl_expr_1006 : BitVec 8 := ((((((env).2).1).1).2).1 ^^^ ((((env).2).1).1).1)
  let _rtl_expr_1007 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1006)
  let _rtl_expr_1008 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1007)
  let _rtl_expr_1009 : BitVec 8 := (_rtl_expr_1005 ^^^ _rtl_expr_1008)
  let _rtl_expr_1010 : BitVec 8 := ((((((env).2).1).2).2).2 ^^^ _rtl_expr_972)
  let _rtl_expr_1011 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1010)
  let _rtl_expr_1012 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1011)
  let _rtl_expr_1013 : BitVec 8 := (_rtl_expr_1009 ^^^ _rtl_expr_1012)
  let _rtl_expr_1014 : BitVec 7 := BitVec.extractLsb 6 0 ((((((env).2).2).1).2).1)
  let _rtl_expr_1015 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_1014) (boolToBitVec (false))
  let _rtl_expr_1016 : Bool := BitVec.getLsbD ((((((env).2).2).1).2).1) 7
  let _rtl_expr_1017 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1016)) (boolToBitVec (_rtl_expr_1016))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1016)) (boolToBitVec (_rtl_expr_1016)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1016)) (boolToBitVec (_rtl_expr_1016))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1016)) (boolToBitVec (_rtl_expr_1016))))
  let _rtl_expr_1018 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_1017)
  let _rtl_expr_1019 : BitVec 8 := (_rtl_expr_1015 ^^^ _rtl_expr_1018)
  let _rtl_expr_1020 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1019)
  let _rtl_expr_1021 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1020)
  let _rtl_expr_1022 : BitVec 8 := ((((((env).2).2).2).1).1 ^^^ _rtl_expr_1021)
  let _rtl_expr_1023 : BitVec 8 := (_rtl_expr_1022 ^^^ ((((env).2).2).1).1)
  ((((((((env).1).1).1).1, (((((env).1).1).1).2).1), ((((((env).1).1).1).2).2, (((((env).1).1).2).1, (((((env).1).1).2).2).1))), (((((((env).1).1).2).2).2, (((((env).1).2).1).1, (((((env).1).2).1).2).1)), ((((((env).1).2).1).2).2, ((((((env).1).2).2).1).1, (((((env).1).2).2).1).2)))), ((((((((env).1).2).2).2).2, ((((env).2).1).1).1), ((((((env).2).1).2).1).1, ((((((env).2).1).2).2).1, (((((env).2).2).2).1).2))), ((_rtl_expr_960, (_rtl_expr_997, _rtl_expr_1002)), (_rtl_expr_1013, (_rtl_expr_1021, _rtl_expr_1023)))))

private def _rtl_eval_block_25 (s : aes_coreState) (i : aes_coreInputs) (env : ((((Bool × BitVec 128) × (Bool × (BitVec 128 × Bool))) × ((BitVec 128 × (BitVec 128 × BitVec 32)) × (BitVec 32 × (BitVec 8 × BitVec 8)))) × (((BitVec 8 × BitVec 8) × (BitVec 8 × (BitVec 8 × BitVec 8))) × ((BitVec 8 × (BitVec 8 × BitVec 8)) × (BitVec 8 × (BitVec 8 × BitVec 8)))))) : (((Bool × (BitVec 128 × Bool)) × ((BitVec 128 × Bool) × (BitVec 128 × BitVec 32))) × ((BitVec 32 × (BitVec 32 × BitVec 32)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8)))) :=
  let _rtl_expr_1024 : BitVec 8 := BitVec.extractLsb 7 0 ((((((env).2).2).2).2).2)
  let _rtl_expr_1025 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1024)
  let _rtl_expr_1026 : BitVec 8 := (((((env).2).2).2).1 ^^^ _rtl_expr_1025)
  let _rtl_expr_1027 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1026)
  let _rtl_expr_1028 : BitVec 8 := ((((((env).1).2).2).2).2 ^^^ ((((env).2).1).1).1)
  let _rtl_expr_1029 : BitVec 8 := (_rtl_expr_1028 ^^^ (((((env).1).2).2).2).1)
  let _rtl_expr_1030 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1029)
  let _rtl_expr_1031 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1030)
  let _rtl_expr_1032 : BitVec 8 := (((((env).2).2).1).1 ^^^ ((((env).2).1).1).2)
  let _rtl_expr_1033 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1032)
  let _rtl_expr_1034 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1033)
  let _rtl_expr_1035 : BitVec 8 := (_rtl_expr_1031 ^^^ _rtl_expr_1034)
  let _rtl_expr_1036 : BitVec 8 := ((((((env).2).1).2).2).1 ^^^ ((((env).2).1).2).1)
  let _rtl_expr_1037 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1036)
  let _rtl_expr_1038 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1037)
  let _rtl_expr_1039 : BitVec 8 := (_rtl_expr_1035 ^^^ _rtl_expr_1038)
  let _rtl_expr_1040 : BitVec 8 := ((((((env).2).2).1).2).1 ^^^ (((((env).2).2).2).2).1)
  let _rtl_expr_1041 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1040)
  let _rtl_expr_1042 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1041)
  let _rtl_expr_1043 : BitVec 8 := (_rtl_expr_1039 ^^^ _rtl_expr_1042)
  let _rtl_expr_1044 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1043)
  let _rtl_expr_1045 : BitVec 32 := BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) ((((((env).2).1).2).2).2) ((((((env).2).2).1).2).2)) (BitVec.append (n := 8) (m := 8) (_rtl_expr_1027) (_rtl_expr_1044))
  let _rtl_expr_1046 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_1045)
  let _rtl_expr_1047 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_1046)
  let _rtl_expr_1048 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_1047)
  let _rtl_expr_1049 : BitVec 32 := BitVec.extractLsb 31 0 ((((((env).1).2).1).2).1)
  let _rtl_expr_1050 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_1049)
  let _rtl_expr_1051 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_1050)
  let _rtl_expr_1052 : BitVec 8 := BitVec.extractLsb 31 24 (_rtl_expr_1051)
  let _rtl_expr_1053 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1052)
  let _rtl_expr_1054 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1053)
  let _rtl_expr_1055 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1054)
  let _rtl_expr_1056 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1055)
  let _rtl_expr_1057 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1056)
  let _rtl_expr_1058 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_1057)
  let _rtl_expr_1059 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_1058) (boolToBitVec (false))
  let _rtl_expr_1060 : Bool := BitVec.getLsbD (_rtl_expr_1057) 7
  let _rtl_expr_1061 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1060)) (boolToBitVec (_rtl_expr_1060))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1060)) (boolToBitVec (_rtl_expr_1060)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1060)) (boolToBitVec (_rtl_expr_1060))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1060)) (boolToBitVec (_rtl_expr_1060))))
  let _rtl_expr_1062 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_1061)
  let _rtl_expr_1063 : BitVec 8 := (_rtl_expr_1059 ^^^ _rtl_expr_1062)
  let _rtl_expr_1064 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1063)
  let _rtl_expr_1065 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1064)
  let _rtl_expr_1066 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1065)
  let _rtl_expr_1067 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_1066)
  let _rtl_expr_1068 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_1067) (boolToBitVec (false))
  let _rtl_expr_1069 : Bool := BitVec.getLsbD (_rtl_expr_1066) 7
  let _rtl_expr_1070 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1069)) (boolToBitVec (_rtl_expr_1069))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1069)) (boolToBitVec (_rtl_expr_1069)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1069)) (boolToBitVec (_rtl_expr_1069))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1069)) (boolToBitVec (_rtl_expr_1069))))
  let _rtl_expr_1071 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_1070)
  let _rtl_expr_1072 : BitVec 8 := (_rtl_expr_1068 ^^^ _rtl_expr_1071)
  let _rtl_expr_1073 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1072)
  let _rtl_expr_1074 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1073)
  let _rtl_expr_1075 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1074)
  let _rtl_expr_1076 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1075)
  let _rtl_expr_1077 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1076)
  let _rtl_expr_1078 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_1077)
  let _rtl_expr_1079 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_1078) (boolToBitVec (false))
  let _rtl_expr_1080 : Bool := BitVec.getLsbD (_rtl_expr_1077) 7
  let _rtl_expr_1081 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1080)) (boolToBitVec (_rtl_expr_1080))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1080)) (boolToBitVec (_rtl_expr_1080)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1080)) (boolToBitVec (_rtl_expr_1080))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1080)) (boolToBitVec (_rtl_expr_1080))))
  let _rtl_expr_1082 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_1081)
  let _rtl_expr_1083 : BitVec 8 := (_rtl_expr_1079 ^^^ _rtl_expr_1082)
  let _rtl_expr_1084 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1083)
  let _rtl_expr_1085 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1084)
  let _rtl_expr_1086 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1085)
  let _rtl_expr_1087 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1086)
  (((((((env).1).1).1).1, (((((env).1).1).1).2, ((((env).1).1).2).1)), (((((((env).1).1).2).2).1, (((((env).1).1).2).2).2), (((((env).1).2).1).1, (((((env).1).2).1).2).2))), ((((((env).1).2).2).1, (_rtl_expr_1048, _rtl_expr_1051)), ((_rtl_expr_1054, _rtl_expr_1055), (_rtl_expr_1056, _rtl_expr_1087))))

private def _rtl_eval_block_26 (s : aes_coreState) (i : aes_coreInputs) (env : (((Bool × (BitVec 128 × Bool)) × ((BitVec 128 × Bool) × (BitVec 128 × BitVec 32))) × ((BitVec 32 × (BitVec 32 × BitVec 32)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8))))) : ((((Bool × BitVec 128) × (Bool × BitVec 128)) × ((Bool × BitVec 128) × (BitVec 32 × (BitVec 32 × BitVec 32)))) × (((BitVec 32 × BitVec 8) × (BitVec 8 × (BitVec 8 × BitVec 8))) × ((BitVec 8 × BitVec 8) × (BitVec 8 × (BitVec 8 × BitVec 8))))) :=
  let _rtl_expr_1088 : BitVec 7 := BitVec.extractLsb 6 0 (((((env).2).2).2).1)
  let _rtl_expr_1089 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_1088) (boolToBitVec (false))
  let _rtl_expr_1090 : Bool := BitVec.getLsbD (((((env).2).2).2).1) 7
  let _rtl_expr_1091 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1090)) (boolToBitVec (_rtl_expr_1090))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1090)) (boolToBitVec (_rtl_expr_1090)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1090)) (boolToBitVec (_rtl_expr_1090))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1090)) (boolToBitVec (_rtl_expr_1090))))
  let _rtl_expr_1092 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_1091)
  let _rtl_expr_1093 : BitVec 8 := (_rtl_expr_1089 ^^^ _rtl_expr_1092)
  let _rtl_expr_1094 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1093)
  let _rtl_expr_1095 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1094)
  let _rtl_expr_1096 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1095)
  let _rtl_expr_1097 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_1096)
  let _rtl_expr_1098 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_1097) (boolToBitVec (false))
  let _rtl_expr_1099 : Bool := BitVec.getLsbD (_rtl_expr_1096) 7
  let _rtl_expr_1100 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1099)) (boolToBitVec (_rtl_expr_1099))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1099)) (boolToBitVec (_rtl_expr_1099)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1099)) (boolToBitVec (_rtl_expr_1099))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1099)) (boolToBitVec (_rtl_expr_1099))))
  let _rtl_expr_1101 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_1100)
  let _rtl_expr_1102 : BitVec 8 := (_rtl_expr_1098 ^^^ _rtl_expr_1101)
  let _rtl_expr_1103 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1102)
  let _rtl_expr_1104 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1103)
  let _rtl_expr_1105 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1104)
  let _rtl_expr_1106 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1105)
  let _rtl_expr_1107 : BitVec 8 := (((((env).2).2).2).2 ^^^ _rtl_expr_1106)
  let _rtl_expr_1108 : BitVec 7 := BitVec.extractLsb 6 0 (((((env).2).2).1).2)
  let _rtl_expr_1109 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_1108) (boolToBitVec (false))
  let _rtl_expr_1110 : Bool := BitVec.getLsbD (((((env).2).2).1).2) 7
  let _rtl_expr_1111 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1110)) (boolToBitVec (_rtl_expr_1110))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1110)) (boolToBitVec (_rtl_expr_1110)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1110)) (boolToBitVec (_rtl_expr_1110))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1110)) (boolToBitVec (_rtl_expr_1110))))
  let _rtl_expr_1112 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_1111)
  let _rtl_expr_1113 : BitVec 8 := (_rtl_expr_1109 ^^^ _rtl_expr_1112)
  let _rtl_expr_1114 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1113)
  let _rtl_expr_1115 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1114)
  let _rtl_expr_1116 : BitVec 8 := (_rtl_expr_1107 ^^^ _rtl_expr_1115)
  let _rtl_expr_1117 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1116)
  let _rtl_expr_1118 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1117)
  let _rtl_expr_1119 : BitVec 8 := BitVec.extractLsb 23 16 (((((env).2).1).2).2)
  let _rtl_expr_1120 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1119)
  let _rtl_expr_1121 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1120)
  let _rtl_expr_1122 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1121)
  let _rtl_expr_1123 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1122)
  let _rtl_expr_1124 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1123)
  let _rtl_expr_1125 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_1124)
  let _rtl_expr_1126 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_1125) (boolToBitVec (false))
  let _rtl_expr_1127 : Bool := BitVec.getLsbD (_rtl_expr_1124) 7
  let _rtl_expr_1128 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1127)) (boolToBitVec (_rtl_expr_1127))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1127)) (boolToBitVec (_rtl_expr_1127)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1127)) (boolToBitVec (_rtl_expr_1127))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1127)) (boolToBitVec (_rtl_expr_1127))))
  let _rtl_expr_1129 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_1128)
  let _rtl_expr_1130 : BitVec 8 := (_rtl_expr_1126 ^^^ _rtl_expr_1129)
  let _rtl_expr_1131 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1130)
  let _rtl_expr_1132 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1131)
  let _rtl_expr_1133 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1132)
  let _rtl_expr_1134 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_1133)
  let _rtl_expr_1135 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_1134) (boolToBitVec (false))
  let _rtl_expr_1136 : Bool := BitVec.getLsbD (_rtl_expr_1133) 7
  let _rtl_expr_1137 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1136)) (boolToBitVec (_rtl_expr_1136))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1136)) (boolToBitVec (_rtl_expr_1136)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1136)) (boolToBitVec (_rtl_expr_1136))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1136)) (boolToBitVec (_rtl_expr_1136))))
  let _rtl_expr_1138 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_1137)
  let _rtl_expr_1139 : BitVec 8 := (_rtl_expr_1135 ^^^ _rtl_expr_1138)
  let _rtl_expr_1140 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1139)
  let _rtl_expr_1141 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1140)
  let _rtl_expr_1142 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1141)
  let _rtl_expr_1143 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1142)
  let _rtl_expr_1144 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1143)
  let _rtl_expr_1145 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_1144)
  let _rtl_expr_1146 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_1145) (boolToBitVec (false))
  let _rtl_expr_1147 : Bool := BitVec.getLsbD (_rtl_expr_1144) 7
  let _rtl_expr_1148 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1147)) (boolToBitVec (_rtl_expr_1147))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1147)) (boolToBitVec (_rtl_expr_1147)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1147)) (boolToBitVec (_rtl_expr_1147))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1147)) (boolToBitVec (_rtl_expr_1147))))
  let _rtl_expr_1149 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_1148)
  let _rtl_expr_1150 : BitVec 8 := (_rtl_expr_1146 ^^^ _rtl_expr_1149)
  let _rtl_expr_1151 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1150)
  (((((((env).1).1).1, ((((env).1).1).2).1), (((((env).1).1).2).2, ((((env).1).2).1).1)), ((((((env).1).2).1).2, ((((env).1).2).2).1), (((((env).1).2).2).2, ((((env).2).1).1, ((((env).2).1).2).1)))), (((((((env).2).1).2).2, ((((env).2).2).1).1), (((((env).2).2).2).2, (_rtl_expr_1107, _rtl_expr_1115))), ((_rtl_expr_1118, _rtl_expr_1121), (_rtl_expr_1122, (_rtl_expr_1123, _rtl_expr_1151)))))

private def _rtl_eval_block_27 (s : aes_coreState) (i : aes_coreInputs) (env : ((((Bool × BitVec 128) × (Bool × BitVec 128)) × ((Bool × BitVec 128) × (BitVec 32 × (BitVec 32 × BitVec 32)))) × (((BitVec 32 × BitVec 8) × (BitVec 8 × (BitVec 8 × BitVec 8))) × ((BitVec 8 × BitVec 8) × (BitVec 8 × (BitVec 8 × BitVec 8)))))) : ((((Bool × (BitVec 128 × Bool)) × (BitVec 128 × (Bool × BitVec 128))) × ((BitVec 32 × (BitVec 32 × BitVec 32)) × (BitVec 32 × (BitVec 8 × BitVec 8)))) × (((BitVec 8 × (BitVec 8 × BitVec 8)) × (BitVec 8 × (BitVec 8 × BitVec 8))) × ((BitVec 8 × (BitVec 8 × BitVec 8)) × (BitVec 8 × (BitVec 8 × Bool))))) :=
  let _rtl_expr_1152 : BitVec 8 := BitVec.extractLsb 7 0 ((((((env).2).2).2).2).2)
  let _rtl_expr_1153 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1152)
  let _rtl_expr_1154 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1153)
  let _rtl_expr_1155 : BitVec 7 := BitVec.extractLsb 6 0 (((((env).2).2).2).1)
  let _rtl_expr_1156 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_1155) (boolToBitVec (false))
  let _rtl_expr_1157 : Bool := BitVec.getLsbD (((((env).2).2).2).1) 7
  let _rtl_expr_1158 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1157)) (boolToBitVec (_rtl_expr_1157))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1157)) (boolToBitVec (_rtl_expr_1157)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1157)) (boolToBitVec (_rtl_expr_1157))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1157)) (boolToBitVec (_rtl_expr_1157))))
  let _rtl_expr_1159 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_1158)
  let _rtl_expr_1160 : BitVec 8 := (_rtl_expr_1156 ^^^ _rtl_expr_1159)
  let _rtl_expr_1161 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1160)
  let _rtl_expr_1162 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1161)
  let _rtl_expr_1163 : BitVec 8 := (_rtl_expr_1154 ^^^ _rtl_expr_1162)
  let _rtl_expr_1164 : BitVec 8 := (_rtl_expr_1163 ^^^ ((((env).2).2).1).2)
  let _rtl_expr_1165 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1164)
  let _rtl_expr_1166 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1165)
  let _rtl_expr_1167 : BitVec 8 := (((((env).2).2).1).1 ^^^ _rtl_expr_1166)
  let _rtl_expr_1168 : BitVec 8 := BitVec.extractLsb 15 8 (((((env).2).1).1).1)
  let _rtl_expr_1169 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1168)
  let _rtl_expr_1170 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1169)
  let _rtl_expr_1171 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1170)
  let _rtl_expr_1172 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1171)
  let _rtl_expr_1173 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1172)
  let _rtl_expr_1174 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_1173)
  let _rtl_expr_1175 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_1174) (boolToBitVec (false))
  let _rtl_expr_1176 : Bool := BitVec.getLsbD (_rtl_expr_1173) 7
  let _rtl_expr_1177 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1176)) (boolToBitVec (_rtl_expr_1176))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1176)) (boolToBitVec (_rtl_expr_1176)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1176)) (boolToBitVec (_rtl_expr_1176))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1176)) (boolToBitVec (_rtl_expr_1176))))
  let _rtl_expr_1178 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_1177)
  let _rtl_expr_1179 : BitVec 8 := (_rtl_expr_1175 ^^^ _rtl_expr_1178)
  let _rtl_expr_1180 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1179)
  let _rtl_expr_1181 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1180)
  let _rtl_expr_1182 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1181)
  let _rtl_expr_1183 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_1182)
  let _rtl_expr_1184 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_1183) (boolToBitVec (false))
  let _rtl_expr_1185 : Bool := BitVec.getLsbD (_rtl_expr_1182) 7
  let _rtl_expr_1186 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1185)) (boolToBitVec (_rtl_expr_1185))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1185)) (boolToBitVec (_rtl_expr_1185)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1185)) (boolToBitVec (_rtl_expr_1185))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1185)) (boolToBitVec (_rtl_expr_1185))))
  let _rtl_expr_1187 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_1186)
  let _rtl_expr_1188 : BitVec 8 := (_rtl_expr_1184 ^^^ _rtl_expr_1187)
  let _rtl_expr_1189 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1188)
  let _rtl_expr_1190 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1189)
  let _rtl_expr_1191 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1190)
  let _rtl_expr_1192 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1191)
  let _rtl_expr_1193 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1192)
  let _rtl_expr_1194 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_1193)
  let _rtl_expr_1195 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_1194) (boolToBitVec (false))
  let _rtl_expr_1196 : Bool := BitVec.getLsbD (_rtl_expr_1193) 7
  let _rtl_expr_1197 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1196)) (boolToBitVec (_rtl_expr_1196))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1196)) (boolToBitVec (_rtl_expr_1196)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1196)) (boolToBitVec (_rtl_expr_1196))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1196)) (boolToBitVec (_rtl_expr_1196))))
  let _rtl_expr_1198 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_1197)
  let _rtl_expr_1199 : BitVec 8 := (_rtl_expr_1195 ^^^ _rtl_expr_1198)
  let _rtl_expr_1200 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1199)
  let _rtl_expr_1201 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1200)
  let _rtl_expr_1202 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1201)
  let _rtl_expr_1203 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1202)
  let _rtl_expr_1204 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_1172)
  let _rtl_expr_1205 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_1204) (boolToBitVec (false))
  let _rtl_expr_1206 : Bool := BitVec.getLsbD (_rtl_expr_1172) 7
  let _rtl_expr_1207 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1206)) (boolToBitVec (_rtl_expr_1206))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1206)) (boolToBitVec (_rtl_expr_1206)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1206)) (boolToBitVec (_rtl_expr_1206))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1206)) (boolToBitVec (_rtl_expr_1206))))
  let _rtl_expr_1208 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_1207)
  let _rtl_expr_1209 : BitVec 8 := (_rtl_expr_1205 ^^^ _rtl_expr_1208)
  let _rtl_expr_1210 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1209)
  let _rtl_expr_1211 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1210)
  let _rtl_expr_1212 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1211)
  let _rtl_expr_1213 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_1212)
  let _rtl_expr_1214 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_1213) (boolToBitVec (false))
  let _rtl_expr_1215 : Bool := BitVec.getLsbD (_rtl_expr_1212) 7
  ((((((((env).1).1).1).1, (((((env).1).1).1).2, ((((env).1).1).2).1)), (((((env).1).1).2).2, (((((env).1).2).1).1, ((((env).1).2).1).2))), ((((((env).1).2).2).1, ((((((env).1).2).2).2).1, (((((env).1).2).2).2).2)), (((((env).2).1).1).1, (((((env).2).1).1).2, ((((env).2).1).2).1)))), ((((((((env).2).1).2).2).1, ((((((env).2).1).2).2).2, ((((env).2).2).1).2)), ((((((env).2).2).2).2).1, (_rtl_expr_1154, _rtl_expr_1162))), ((_rtl_expr_1167, (_rtl_expr_1170, _rtl_expr_1171)), (_rtl_expr_1203, (_rtl_expr_1214, _rtl_expr_1215)))))

private def _rtl_eval_block_28 (s : aes_coreState) (i : aes_coreInputs) (env : ((((Bool × (BitVec 128 × Bool)) × (BitVec 128 × (Bool × BitVec 128))) × ((BitVec 32 × (BitVec 32 × BitVec 32)) × (BitVec 32 × (BitVec 8 × BitVec 8)))) × (((BitVec 8 × (BitVec 8 × BitVec 8)) × (BitVec 8 × (BitVec 8 × BitVec 8))) × ((BitVec 8 × (BitVec 8 × BitVec 8)) × (BitVec 8 × (BitVec 8 × Bool)))))) : ((((Bool × (BitVec 128 × Bool)) × (BitVec 128 × (Bool × BitVec 128))) × ((BitVec 32 × (BitVec 32 × BitVec 32)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8)))) × (((BitVec 8 × (BitVec 8 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8))) × ((BitVec 8 × (BitVec 8 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8))))) :=
  let _rtl_expr_1216 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec ((((((env).2).2).2).2).2)) (boolToBitVec ((((((env).2).2).2).2).2))) (BitVec.append (n := 1) (m := 1) (boolToBitVec ((((((env).2).2).2).2).2)) (boolToBitVec ((((((env).2).2).2).2).2)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec ((((((env).2).2).2).2).2)) (boolToBitVec ((((((env).2).2).2).2).2))) (BitVec.append (n := 1) (m := 1) (boolToBitVec ((((((env).2).2).2).2).2)) (boolToBitVec ((((((env).2).2).2).2).2))))
  let _rtl_expr_1217 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_1216)
  let _rtl_expr_1218 : BitVec 8 := ((((((env).2).2).2).2).1 ^^^ _rtl_expr_1217)
  let _rtl_expr_1219 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1218)
  let _rtl_expr_1220 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1219)
  let _rtl_expr_1221 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1220)
  let _rtl_expr_1222 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1221)
  let _rtl_expr_1223 : BitVec 8 := (((((env).2).2).2).1 ^^^ _rtl_expr_1222)
  let _rtl_expr_1224 : BitVec 8 := (_rtl_expr_1223 ^^^ (((((env).2).2).1).2).1)
  let _rtl_expr_1225 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1224)
  let _rtl_expr_1226 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1225)
  let _rtl_expr_1227 : BitVec 8 := (((((env).2).2).1).1 ^^^ _rtl_expr_1226)
  let _rtl_expr_1228 : BitVec 8 := BitVec.extractLsb 7 0 (((((env).1).2).2).1)
  let _rtl_expr_1229 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1228)
  let _rtl_expr_1230 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1229)
  let _rtl_expr_1231 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1230)
  let _rtl_expr_1232 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1231)
  let _rtl_expr_1233 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1232)
  let _rtl_expr_1234 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_1233)
  let _rtl_expr_1235 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_1234) (boolToBitVec (false))
  let _rtl_expr_1236 : Bool := BitVec.getLsbD (_rtl_expr_1233) 7
  let _rtl_expr_1237 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1236)) (boolToBitVec (_rtl_expr_1236))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1236)) (boolToBitVec (_rtl_expr_1236)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1236)) (boolToBitVec (_rtl_expr_1236))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1236)) (boolToBitVec (_rtl_expr_1236))))
  let _rtl_expr_1238 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_1237)
  let _rtl_expr_1239 : BitVec 8 := (_rtl_expr_1235 ^^^ _rtl_expr_1238)
  let _rtl_expr_1240 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1239)
  let _rtl_expr_1241 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1240)
  let _rtl_expr_1242 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1241)
  let _rtl_expr_1243 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_1242)
  let _rtl_expr_1244 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_1243) (boolToBitVec (false))
  let _rtl_expr_1245 : Bool := BitVec.getLsbD (_rtl_expr_1242) 7
  let _rtl_expr_1246 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1245)) (boolToBitVec (_rtl_expr_1245))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1245)) (boolToBitVec (_rtl_expr_1245)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1245)) (boolToBitVec (_rtl_expr_1245))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1245)) (boolToBitVec (_rtl_expr_1245))))
  let _rtl_expr_1247 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_1246)
  let _rtl_expr_1248 : BitVec 8 := (_rtl_expr_1244 ^^^ _rtl_expr_1247)
  let _rtl_expr_1249 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1248)
  let _rtl_expr_1250 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1249)
  let _rtl_expr_1251 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1250)
  let _rtl_expr_1252 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1251)
  let _rtl_expr_1253 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1252)
  let _rtl_expr_1254 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_1253)
  let _rtl_expr_1255 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_1254) (boolToBitVec (false))
  let _rtl_expr_1256 : Bool := BitVec.getLsbD (_rtl_expr_1253) 7
  let _rtl_expr_1257 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1256)) (boolToBitVec (_rtl_expr_1256))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1256)) (boolToBitVec (_rtl_expr_1256)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1256)) (boolToBitVec (_rtl_expr_1256))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1256)) (boolToBitVec (_rtl_expr_1256))))
  let _rtl_expr_1258 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_1257)
  let _rtl_expr_1259 : BitVec 8 := (_rtl_expr_1255 ^^^ _rtl_expr_1258)
  let _rtl_expr_1260 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1259)
  let _rtl_expr_1261 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1260)
  let _rtl_expr_1262 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1261)
  let _rtl_expr_1263 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1262)
  let _rtl_expr_1264 : BitVec 8 := (_rtl_expr_1263 ^^^ _rtl_expr_1230)
  let _rtl_expr_1265 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1264)
  let _rtl_expr_1266 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1265)
  let _rtl_expr_1267 : BitVec 8 := (_rtl_expr_1227 ^^^ _rtl_expr_1266)
  let _rtl_expr_1268 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1267)
  let _rtl_expr_1269 : BitVec 8 := ((((((env).1).2).2).2).2 ^^^ (((((env).1).2).2).2).1)
  let _rtl_expr_1270 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1269)
  let _rtl_expr_1271 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1270)
  let _rtl_expr_1272 : BitVec 7 := BitVec.extractLsb 6 0 (((((env).2).1).2).1)
  let _rtl_expr_1273 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_1272) (boolToBitVec (false))
  let _rtl_expr_1274 : Bool := BitVec.getLsbD (((((env).2).1).2).1) 7
  let _rtl_expr_1275 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1274)) (boolToBitVec (_rtl_expr_1274))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1274)) (boolToBitVec (_rtl_expr_1274)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1274)) (boolToBitVec (_rtl_expr_1274))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1274)) (boolToBitVec (_rtl_expr_1274))))
  let _rtl_expr_1276 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_1275)
  let _rtl_expr_1277 : BitVec 8 := (_rtl_expr_1273 ^^^ _rtl_expr_1276)
  let _rtl_expr_1278 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1277)
  let _rtl_expr_1279 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1278)
  ((((((((env).1).1).1).1, ((((((env).1).1).1).2).1, (((((env).1).1).1).2).2)), (((((env).1).1).2).1, ((((((env).1).1).2).2).1, (((((env).1).1).2).2).2))), ((((((env).1).2).1).1, ((((((env).1).2).1).2).1, (((((env).1).2).1).2).2)), (((((((env).1).2).2).2).1, (((((env).1).2).2).2).2), (((((env).2).1).1).1, (((((env).2).1).1).2).1)))), ((((((((env).2).1).1).2).2, ((((((env).2).1).2).2).1, (((((env).2).1).2).2).2)), (((((((env).2).2).1).2).1, (((((env).2).2).1).2).2), (((((env).2).2).2).1, _rtl_expr_1223))), ((_rtl_expr_1230, (_rtl_expr_1231, _rtl_expr_1232)), ((_rtl_expr_1263, _rtl_expr_1268), (_rtl_expr_1271, _rtl_expr_1279)))))

private def _rtl_eval_block_29 (s : aes_coreState) (i : aes_coreInputs) (env : ((((Bool × (BitVec 128 × Bool)) × (BitVec 128 × (Bool × BitVec 128))) × ((BitVec 32 × (BitVec 32 × BitVec 32)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8)))) × (((BitVec 8 × (BitVec 8 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8))) × ((BitVec 8 × (BitVec 8 × BitVec 8)) × ((BitVec 8 × BitVec 8) × (BitVec 8 × BitVec 8)))))) : ((((Bool × (BitVec 128 × Bool)) × (BitVec 128 × (Bool × BitVec 128))) × ((BitVec 32 × (BitVec 32 × BitVec 32)) × (BitVec 8 × (BitVec 8 × BitVec 8)))) × (((BitVec 8 × (BitVec 8 × BitVec 8)) × (BitVec 8 × (BitVec 8 × BitVec 8))) × ((BitVec 8 × (BitVec 8 × BitVec 8)) × (BitVec 8 × (BitVec 8 × BitVec 8))))) :=
  let _rtl_expr_1280 : BitVec 8 := BitVec.extractLsb 7 0 ((((((env).2).2).2).2).2)
  let _rtl_expr_1281 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_1280)
  let _rtl_expr_1282 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_1281) (boolToBitVec (false))
  let _rtl_expr_1283 : Bool := BitVec.getLsbD (_rtl_expr_1280) 7
  let _rtl_expr_1284 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1283)) (boolToBitVec (_rtl_expr_1283))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1283)) (boolToBitVec (_rtl_expr_1283)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1283)) (boolToBitVec (_rtl_expr_1283))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1283)) (boolToBitVec (_rtl_expr_1283))))
  let _rtl_expr_1285 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_1284)
  let _rtl_expr_1286 : BitVec 8 := (_rtl_expr_1282 ^^^ _rtl_expr_1285)
  let _rtl_expr_1287 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1286)
  let _rtl_expr_1288 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1287)
  let _rtl_expr_1289 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1288)
  let _rtl_expr_1290 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1289)
  let _rtl_expr_1291 : BitVec 8 := ((((((env).2).1).1).2).1 ^^^ _rtl_expr_1290)
  let _rtl_expr_1292 : BitVec 8 := (_rtl_expr_1291 ^^^ (((((env).2).1).1).2).2)
  let _rtl_expr_1293 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1292)
  let _rtl_expr_1294 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1293)
  let _rtl_expr_1295 : BitVec 8 := ((((((env).2).2).2).2).1 ^^^ _rtl_expr_1294)
  let _rtl_expr_1296 : BitVec 7 := BitVec.extractLsb 6 0 ((((((env).2).1).2).1).2)
  let _rtl_expr_1297 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_1296) (boolToBitVec (false))
  let _rtl_expr_1298 : Bool := BitVec.getLsbD ((((((env).2).1).2).1).2) 7
  let _rtl_expr_1299 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1298)) (boolToBitVec (_rtl_expr_1298))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1298)) (boolToBitVec (_rtl_expr_1298)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1298)) (boolToBitVec (_rtl_expr_1298))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1298)) (boolToBitVec (_rtl_expr_1298))))
  let _rtl_expr_1300 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_1299)
  let _rtl_expr_1301 : BitVec 8 := (_rtl_expr_1297 ^^^ _rtl_expr_1300)
  let _rtl_expr_1302 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1301)
  let _rtl_expr_1303 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1302)
  let _rtl_expr_1304 : BitVec 8 := ((((((env).2).1).2).2).1 ^^^ _rtl_expr_1303)
  let _rtl_expr_1305 : BitVec 8 := (_rtl_expr_1304 ^^^ (((((env).2).1).2).1).1)
  let _rtl_expr_1306 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1305)
  let _rtl_expr_1307 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1306)
  let _rtl_expr_1308 : BitVec 8 := (_rtl_expr_1295 ^^^ _rtl_expr_1307)
  let _rtl_expr_1309 : BitVec 7 := BitVec.extractLsb 6 0 ((((((env).2).2).1).2).2)
  let _rtl_expr_1310 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_1309) (boolToBitVec (false))
  let _rtl_expr_1311 : Bool := BitVec.getLsbD ((((((env).2).2).1).2).2) 7
  let _rtl_expr_1312 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1311)) (boolToBitVec (_rtl_expr_1311))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1311)) (boolToBitVec (_rtl_expr_1311)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1311)) (boolToBitVec (_rtl_expr_1311))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1311)) (boolToBitVec (_rtl_expr_1311))))
  let _rtl_expr_1313 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_1312)
  let _rtl_expr_1314 : BitVec 8 := (_rtl_expr_1310 ^^^ _rtl_expr_1313)
  let _rtl_expr_1315 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1314)
  let _rtl_expr_1316 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1315)
  let _rtl_expr_1317 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1316)
  let _rtl_expr_1318 : BitVec 7 := BitVec.extractLsb 6 0 (_rtl_expr_1317)
  let _rtl_expr_1319 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_1318) (boolToBitVec (false))
  let _rtl_expr_1320 : Bool := BitVec.getLsbD (_rtl_expr_1317) 7
  let _rtl_expr_1321 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1320)) (boolToBitVec (_rtl_expr_1320))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1320)) (boolToBitVec (_rtl_expr_1320)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1320)) (boolToBitVec (_rtl_expr_1320))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1320)) (boolToBitVec (_rtl_expr_1320))))
  let _rtl_expr_1322 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_1321)
  let _rtl_expr_1323 : BitVec 8 := (_rtl_expr_1319 ^^^ _rtl_expr_1322)
  let _rtl_expr_1324 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1323)
  let _rtl_expr_1325 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1324)
  let _rtl_expr_1326 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1325)
  let _rtl_expr_1327 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1326)
  let _rtl_expr_1328 : BitVec 8 := ((((((env).2).2).2).1).1 ^^^ _rtl_expr_1327)
  let _rtl_expr_1329 : BitVec 8 := (_rtl_expr_1328 ^^^ ((((env).2).2).1).1)
  let _rtl_expr_1330 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1329)
  let _rtl_expr_1331 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1330)
  let _rtl_expr_1332 : BitVec 8 := (_rtl_expr_1308 ^^^ _rtl_expr_1331)
  let _rtl_expr_1333 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1332)
  let _rtl_expr_1334 : BitVec 8 := ((((((env).1).2).2).2).1 ^^^ (((((env).1).2).2).1).1)
  let _rtl_expr_1335 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1334)
  let _rtl_expr_1336 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1335)
  let _rtl_expr_1337 : BitVec 8 := ((((((env).2).1).1).2).1 ^^^ ((((env).2).1).1).1)
  let _rtl_expr_1338 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1337)
  let _rtl_expr_1339 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1338)
  let _rtl_expr_1340 : BitVec 8 := (_rtl_expr_1336 ^^^ _rtl_expr_1339)
  let _rtl_expr_1341 : BitVec 8 := ((((((env).2).1).2).2).2 ^^^ _rtl_expr_1303)
  let _rtl_expr_1342 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1341)
  let _rtl_expr_1343 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1342)
  ((((((((env).1).1).1).1, ((((((env).1).1).1).2).1, (((((env).1).1).1).2).2)), (((((env).1).1).2).1, ((((((env).1).1).2).2).1, (((((env).1).1).2).2).2))), ((((((env).1).2).1).1, ((((((env).1).2).1).2).1, (((((env).1).2).1).2).2)), ((((((env).1).2).2).1).1, ((((((env).1).2).2).1).2, (((((env).1).2).2).2).2)))), (((((((env).2).1).1).1, ((((((env).2).1).2).1).1, (((((env).2).1).2).2).1)), (((((env).2).2).1).1, ((((((env).2).2).1).2).1, (((((env).2).2).2).1).1))), (((((((env).2).2).2).1).2, (_rtl_expr_1291, _rtl_expr_1328)), (_rtl_expr_1333, (_rtl_expr_1340, _rtl_expr_1343)))))

private def _rtl_eval_block_30 (s : aes_coreState) (i : aes_coreInputs) (env : ((((Bool × (BitVec 128 × Bool)) × (BitVec 128 × (Bool × BitVec 128))) × ((BitVec 32 × (BitVec 32 × BitVec 32)) × (BitVec 8 × (BitVec 8 × BitVec 8)))) × (((BitVec 8 × (BitVec 8 × BitVec 8)) × (BitVec 8 × (BitVec 8 × BitVec 8))) × ((BitVec 8 × (BitVec 8 × BitVec 8)) × (BitVec 8 × (BitVec 8 × BitVec 8)))))) : (((Bool × (BitVec 128 × Bool)) × ((BitVec 128 × Bool) × (BitVec 128 × BitVec 32))) × (((BitVec 32 × BitVec 32) × (BitVec 32 × BitVec 32)) × ((BitVec 32 × BitVec 8) × (BitVec 8 × BitVec 8)))) :=
  let _rtl_expr_1344 : BitVec 8 := ((((((env).2).2).2).2).1 ^^^ (((((env).2).2).2).2).2)
  let _rtl_expr_1345 : BitVec 7 := BitVec.extractLsb 6 0 ((((((env).2).1).2).2).1)
  let _rtl_expr_1346 : BitVec 8 := BitVec.append (n := 7) (m := 1) (_rtl_expr_1345) (boolToBitVec (false))
  let _rtl_expr_1347 : Bool := BitVec.getLsbD ((((((env).2).1).2).2).1) 7
  let _rtl_expr_1348 : BitVec 8 := BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1347)) (boolToBitVec (_rtl_expr_1347))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1347)) (boolToBitVec (_rtl_expr_1347)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1347)) (boolToBitVec (_rtl_expr_1347))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (_rtl_expr_1347)) (boolToBitVec (_rtl_expr_1347))))
  let _rtl_expr_1349 : BitVec 8 := (BitVec.ofNat 8 27 &&& _rtl_expr_1348)
  let _rtl_expr_1350 : BitVec 8 := (_rtl_expr_1346 ^^^ _rtl_expr_1349)
  let _rtl_expr_1351 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1350)
  let _rtl_expr_1352 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1351)
  let _rtl_expr_1353 : BitVec 8 := ((((((env).2).1).2).2).2 ^^^ _rtl_expr_1352)
  let _rtl_expr_1354 : BitVec 8 := (_rtl_expr_1353 ^^^ ((((env).2).1).2).1)
  let _rtl_expr_1355 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1354)
  let _rtl_expr_1356 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1355)
  let _rtl_expr_1357 : BitVec 8 := (_rtl_expr_1344 ^^^ _rtl_expr_1356)
  let _rtl_expr_1358 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1357)
  let _rtl_expr_1359 : BitVec 8 := ((((((env).1).2).2).2).1 ^^^ (((((env).1).2).2).2).2)
  let _rtl_expr_1360 : BitVec 8 := (_rtl_expr_1359 ^^^ ((((env).1).2).2).1)
  let _rtl_expr_1361 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1360)
  let _rtl_expr_1362 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1361)
  let _rtl_expr_1363 : BitVec 8 := ((((((env).2).2).1).2).1 ^^^ ((((env).2).1).1).1)
  let _rtl_expr_1364 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1363)
  let _rtl_expr_1365 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1364)
  let _rtl_expr_1366 : BitVec 8 := (_rtl_expr_1362 ^^^ _rtl_expr_1365)
  let _rtl_expr_1367 : BitVec 8 := ((((((env).2).1).1).2).2 ^^^ (((((env).2).1).1).2).1)
  let _rtl_expr_1368 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1367)
  let _rtl_expr_1369 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1368)
  let _rtl_expr_1370 : BitVec 8 := (_rtl_expr_1366 ^^^ _rtl_expr_1369)
  let _rtl_expr_1371 : BitVec 8 := ((((((env).2).2).1).2).2 ^^^ _rtl_expr_1352)
  let _rtl_expr_1372 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1371)
  let _rtl_expr_1373 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1372)
  let _rtl_expr_1374 : BitVec 8 := (_rtl_expr_1370 ^^^ _rtl_expr_1373)
  let _rtl_expr_1375 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1374)
  let _rtl_expr_1376 : BitVec 32 := BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (((((env).2).2).1).1) (((((env).2).2).2).1)) (BitVec.append (n := 8) (m := 8) (_rtl_expr_1358) (_rtl_expr_1375))
  let _rtl_expr_1377 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_1376)
  let _rtl_expr_1378 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_1377)
  let _rtl_expr_1379 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_1378)
  let _rtl_expr_1380 : BitVec 128 := BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (((((env).1).2).1).1) ((((((env).1).2).1).2).1)) (BitVec.append (n := 32) (m := 32) ((((((env).1).2).1).2).2) (_rtl_expr_1379))
  let _rtl_expr_1381 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_1380)
  let _rtl_expr_1382 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_1381)
  let _rtl_expr_1383 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_1382)
  let _rtl_expr_1384 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_1383)
  let _rtl_expr_1385 : BitVec 32 := BitVec.extractLsb 127 96 (_rtl_expr_1384)
  let _rtl_expr_1386 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_1385)
  let _rtl_expr_1387 : BitVec 8 := BitVec.extractLsb 31 24 (_rtl_expr_1386)
  let _rtl_expr_1388 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_1384)
  let _rtl_expr_1389 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_1388)
  let _rtl_expr_1390 : BitVec 8 := BitVec.extractLsb 23 16 (_rtl_expr_1389)
  let _rtl_expr_1391 : BitVec 32 := BitVec.extractLsb 63 32 (_rtl_expr_1384)
  let _rtl_expr_1392 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_1391)
  let _rtl_expr_1393 : BitVec 8 := BitVec.extractLsb 15 8 (_rtl_expr_1392)
  let _rtl_expr_1394 : BitVec 32 := BitVec.extractLsb 95 64 (_rtl_expr_1384)
  let _rtl_expr_1395 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_1394)
  let _rtl_expr_1396 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1395)
  let _rtl_expr_1397 : BitVec 32 := BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (_rtl_expr_1387) (_rtl_expr_1390)) (BitVec.append (n := 8) (m := 8) (_rtl_expr_1393) (_rtl_expr_1396))
  let _rtl_expr_1398 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_1397)
  let _rtl_expr_1399 : BitVec 8 := BitVec.extractLsb 31 24 (_rtl_expr_1395)
  let _rtl_expr_1400 : BitVec 8 := BitVec.extractLsb 23 16 (_rtl_expr_1386)
  let _rtl_expr_1401 : BitVec 8 := BitVec.extractLsb 15 8 (_rtl_expr_1389)
  let _rtl_expr_1402 : BitVec 8 := BitVec.extractLsb 7 0 (_rtl_expr_1392)
  let _rtl_expr_1403 : BitVec 32 := BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (_rtl_expr_1399) (_rtl_expr_1400)) (BitVec.append (n := 8) (m := 8) (_rtl_expr_1401) (_rtl_expr_1402))
  let _rtl_expr_1404 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_1403)
  let _rtl_expr_1405 : BitVec 8 := BitVec.extractLsb 31 24 (_rtl_expr_1392)
  let _rtl_expr_1406 : BitVec 8 := BitVec.extractLsb 23 16 (_rtl_expr_1395)
  let _rtl_expr_1407 : BitVec 8 := BitVec.extractLsb 15 8 (_rtl_expr_1386)
  (((((((env).1).1).1).1, ((((((env).1).1).1).2).1, (((((env).1).1).1).2).2)), ((((((env).1).1).2).1, (((((env).1).1).2).2).1), ((((((env).1).1).2).2).2, _rtl_expr_1386))), (((_rtl_expr_1389, _rtl_expr_1392), (_rtl_expr_1395, _rtl_expr_1398)), ((_rtl_expr_1404, _rtl_expr_1405), (_rtl_expr_1406, _rtl_expr_1407))))

private def _rtl_eval_block_31 (s : aes_coreState) (i : aes_coreInputs) (env : (((Bool × (BitVec 128 × Bool)) × ((BitVec 128 × Bool) × (BitVec 128 × BitVec 32))) × (((BitVec 32 × BitVec 32) × (BitVec 32 × BitVec 32)) × ((BitVec 32 × BitVec 8) × (BitVec 8 × BitVec 8))))) : BitVec 128 :=
  let _rtl_expr_1408 : BitVec 8 := BitVec.extractLsb 7 0 (((((env).2).1).1).1)
  let _rtl_expr_1409 : BitVec 32 := BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (((((env).2).2).1).2) (((((env).2).2).2).1)) (BitVec.append (n := 8) (m := 8) (((((env).2).2).2).2) (_rtl_expr_1408))
  let _rtl_expr_1410 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_1409)
  let _rtl_expr_1411 : BitVec 8 := BitVec.extractLsb 31 24 (((((env).2).1).1).1)
  let _rtl_expr_1412 : BitVec 8 := BitVec.extractLsb 23 16 (((((env).2).1).1).2)
  let _rtl_expr_1413 : BitVec 8 := BitVec.extractLsb 15 8 (((((env).2).1).2).1)
  let _rtl_expr_1414 : BitVec 8 := BitVec.extractLsb 7 0 (((((env).1).2).2).2)
  let _rtl_expr_1415 : BitVec 32 := BitVec.append (n := 16) (m := 16) (BitVec.append (n := 8) (m := 8) (_rtl_expr_1411) (_rtl_expr_1412)) (BitVec.append (n := 8) (m := 8) (_rtl_expr_1413) (_rtl_expr_1414))
  let _rtl_expr_1416 : BitVec 32 := BitVec.extractLsb 31 0 (_rtl_expr_1415)
  let _rtl_expr_1417 : BitVec 128 := BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (((((env).2).1).2).2) (((((env).2).2).1).1)) (BitVec.append (n := 32) (m := 32) (_rtl_expr_1410) (_rtl_expr_1416))
  let _rtl_expr_1418 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_1417)
  let _rtl_expr_1419 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_1418)
  let _rtl_expr_1420 : BitVec 128 := BitVec.extractLsb 127 0 (_rtl_expr_1419)
  let _rtl_expr_1421 : Bool := decide ((s.dec_block__update_type).toNat = (BitVec.ofNat 3 4).toNat)
  let _rtl_expr_1422 : BitVec 128 := (if _rtl_expr_1421 then ((((env).1).2).2).1 else BitVec.ofNat 128 0)
  let _rtl_expr_1423 : BitVec 128 := (if ((((env).1).2).1).2 then _rtl_expr_1420 else _rtl_expr_1422)
  let _rtl_expr_1424 : BitVec 128 := (if ((((env).1).1).2).2 then ((((env).1).2).1).1 else _rtl_expr_1423)
  let _rtl_expr_1425 : BitVec 128 := (if (((env).1).1).1 then ((((env).1).1).2).1 else _rtl_expr_1424)
  _rtl_expr_1425

/-- 组合逻辑：proc_alwayscomb_4__assignment_0 -/
def proc_alwayscomb_4__assignment_0 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_block__block_new := _rtl_eval_block_31 s i (_rtl_eval_block_30 s i (_rtl_eval_block_29 s i (_rtl_eval_block_28 s i (_rtl_eval_block_27 s i (_rtl_eval_block_26 s i (_rtl_eval_block_25 s i (_rtl_eval_block_24 s i (_rtl_eval_block_23 s i (_rtl_eval_block_22 s i (_rtl_eval_block_21 s i (_rtl_eval_block_20 s i (_rtl_eval_block_19 s i (_rtl_eval_block_18 s i (_rtl_eval_block_17 s i (_rtl_eval_block_16 s i (_rtl_eval_block_15 s i (_rtl_eval_block_14 s i (_rtl_eval_block_13 s i (_rtl_eval_block_12 s i (_rtl_eval_block_11 s i (_rtl_eval_block_10 s i (_rtl_eval_block_9 s i (())))))))))))))))))))))))
  { s with
    dec_block__block_new := dec_block__block_new
  }

/-- 组合逻辑：proc_alwayscomb_4__assignment_1 -/
def proc_alwayscomb_4__assignment_1 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_block__block_w0_we := (if decide ((s.dec_block__update_type).toNat = (BitVec.ofNat 3 1).toNat) then true else (if decide ((s.dec_block__update_type).toNat = (BitVec.ofNat 3 2).toNat) then (if decide ((s.dec_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 0).toNat) then true else false) else (if decide ((s.dec_block__update_type).toNat = (BitVec.ofNat 3 3).toNat) then true else (if decide ((s.dec_block__update_type).toNat = (BitVec.ofNat 3 4).toNat) then true else false))))
  { s with
    dec_block__block_w0_we := dec_block__block_w0_we
  }

/-- 组合逻辑：proc_alwayscomb_4__assignment_2 -/
def proc_alwayscomb_4__assignment_2 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_block__block_w1_we := (if decide ((s.dec_block__update_type).toNat = (BitVec.ofNat 3 1).toNat) then true else (if decide ((s.dec_block__update_type).toNat = (BitVec.ofNat 3 2).toNat) then (if decide ((s.dec_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 0).toNat) then false else (if decide ((s.dec_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 1).toNat) then true else false)) else (if decide ((s.dec_block__update_type).toNat = (BitVec.ofNat 3 3).toNat) then true else (if decide ((s.dec_block__update_type).toNat = (BitVec.ofNat 3 4).toNat) then true else false))))
  { s with
    dec_block__block_w1_we := dec_block__block_w1_we
  }

/-- 组合逻辑：proc_alwayscomb_4__assignment_3 -/
def proc_alwayscomb_4__assignment_3 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_block__block_w2_we := (if decide ((s.dec_block__update_type).toNat = (BitVec.ofNat 3 1).toNat) then true else (if decide ((s.dec_block__update_type).toNat = (BitVec.ofNat 3 2).toNat) then (if decide ((s.dec_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 0).toNat) then false else (if decide ((s.dec_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 1).toNat) then false else (if decide ((s.dec_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 2).toNat) then true else false))) else (if decide ((s.dec_block__update_type).toNat = (BitVec.ofNat 3 3).toNat) then true else (if decide ((s.dec_block__update_type).toNat = (BitVec.ofNat 3 4).toNat) then true else false))))
  { s with
    dec_block__block_w2_we := dec_block__block_w2_we
  }

/-- 组合逻辑：proc_alwayscomb_4__assignment_4 -/
def proc_alwayscomb_4__assignment_4 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_block__block_w3_we := (if decide ((s.dec_block__update_type).toNat = (BitVec.ofNat 3 1).toNat) then true else (if decide ((s.dec_block__update_type).toNat = (BitVec.ofNat 3 2).toNat) then (if decide ((s.dec_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 0).toNat) then false else (if decide ((s.dec_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 1).toNat) then false else (if decide ((s.dec_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 2).toNat) then false else (if decide ((s.dec_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 3).toNat) then true else false)))) else (if decide ((s.dec_block__update_type).toNat = (BitVec.ofNat 3 3).toNat) then true else (if decide ((s.dec_block__update_type).toNat = (BitVec.ofNat 3 4).toNat) then true else false))))
  { s with
    dec_block__block_w3_we := dec_block__block_w3_we
  }

/-- 组合逻辑：proc_alwayscomb_4__assignment_5 -/
def proc_alwayscomb_4__assignment_5 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_block__tmp_sboxw := (if decide ((s.dec_block__update_type).toNat = (BitVec.ofNat 3 1).toNat) then BitVec.ofNat 32 0 else (if decide ((s.dec_block__update_type).toNat = (BitVec.ofNat 3 2).toNat) then (if decide ((s.dec_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 0).toNat) then s.dec_block__block_w0_reg else (if decide ((s.dec_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 1).toNat) then s.dec_block__block_w1_reg else (if decide ((s.dec_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 2).toNat) then s.dec_block__block_w2_reg else (if decide ((s.dec_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 3).toNat) then s.dec_block__block_w3_reg else BitVec.ofNat 32 0)))) else BitVec.ofNat 32 0))
  { s with
    dec_block__tmp_sboxw := dec_block__tmp_sboxw
  }

/-- 组合逻辑：proc_alwayscomb_5__assignment_0 -/
def proc_alwayscomb_5__assignment_0 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_block__sword_ctr_new := (if s.dec_block__sword_ctr_rst then BitVec.ofNat 2 0 else (if s.dec_block__sword_ctr_inc then (s.dec_block__sword_ctr_reg + BitVec.ofNat 2 1) else BitVec.ofNat 2 0))
  { s with
    dec_block__sword_ctr_new := dec_block__sword_ctr_new
  }

/-- 组合逻辑：proc_alwayscomb_5__assignment_1 -/
def proc_alwayscomb_5__assignment_1 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_block__sword_ctr_we := (if s.dec_block__sword_ctr_rst then true else (if s.dec_block__sword_ctr_inc then true else false))
  { s with
    dec_block__sword_ctr_we := dec_block__sword_ctr_we
  }

/-- 组合逻辑：proc_alwayscomb_6__assignment_0 -/
def proc_alwayscomb_6__assignment_0 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_block__round_ctr_new := (if s.dec_block__round_ctr_set then (if decide (boolToNat (s.dec_block__keylen) = boolToNat (true)) then BitVec.ofNat 4 14 else BitVec.ofNat 4 10) else (if s.dec_block__round_ctr_dec then (s.dec_block__round_ctr_reg - BitVec.ofNat 4 1) else BitVec.ofNat 4 0))
  { s with
    dec_block__round_ctr_new := dec_block__round_ctr_new
  }

/-- 组合逻辑：proc_alwayscomb_6__assignment_1 -/
def proc_alwayscomb_6__assignment_1 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_block__round_ctr_we := (if s.dec_block__round_ctr_set then true else (if s.dec_block__round_ctr_dec then true else false))
  { s with
    dec_block__round_ctr_we := dec_block__round_ctr_we
  }

/-- 组合逻辑：proc_alwayscomb_7__assignment_0 -/
def proc_alwayscomb_7__assignment_0 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_block__dec_ctrl_new := (if decide ((s.dec_block__dec_ctrl_reg).toNat = (BitVec.ofNat 2 0).toNat) then (if s.dec_block__next then BitVec.ofNat 2 1 else BitVec.ofNat 2 0) else (if decide ((s.dec_block__dec_ctrl_reg).toNat = (BitVec.ofNat 2 1).toNat) then BitVec.ofNat 2 2 else (if decide ((s.dec_block__dec_ctrl_reg).toNat = (BitVec.ofNat 2 2).toNat) then (if decide ((s.dec_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 3).toNat) then BitVec.ofNat 2 3 else BitVec.ofNat 2 0) else (if decide ((s.dec_block__dec_ctrl_reg).toNat = (BitVec.ofNat 2 3).toNat) then (if decide ((s.dec_block__round_ctr_reg).toNat > (BitVec.ofNat 32 0).toNat) then BitVec.ofNat 2 2 else BitVec.ofNat 2 0) else BitVec.ofNat 2 0))))
  { s with
    dec_block__dec_ctrl_new := dec_block__dec_ctrl_new
  }

/-- 组合逻辑：proc_alwayscomb_7__assignment_1 -/
def proc_alwayscomb_7__assignment_1 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_block__dec_ctrl_we := (if decide ((s.dec_block__dec_ctrl_reg).toNat = (BitVec.ofNat 2 0).toNat) then (if s.dec_block__next then true else false) else (if decide ((s.dec_block__dec_ctrl_reg).toNat = (BitVec.ofNat 2 1).toNat) then true else (if decide ((s.dec_block__dec_ctrl_reg).toNat = (BitVec.ofNat 2 2).toNat) then (if decide ((s.dec_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 3).toNat) then true else false) else (if decide ((s.dec_block__dec_ctrl_reg).toNat = (BitVec.ofNat 2 3).toNat) then true else false))))
  { s with
    dec_block__dec_ctrl_we := dec_block__dec_ctrl_we
  }

/-- 组合逻辑：proc_alwayscomb_7__assignment_2 -/
def proc_alwayscomb_7__assignment_2 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_block__ready_new := (if decide ((s.dec_block__dec_ctrl_reg).toNat = (BitVec.ofNat 2 0).toNat) then false else (if decide ((s.dec_block__dec_ctrl_reg).toNat = (BitVec.ofNat 2 1).toNat) then false else (if decide ((s.dec_block__dec_ctrl_reg).toNat = (BitVec.ofNat 2 2).toNat) then false else (if decide ((s.dec_block__dec_ctrl_reg).toNat = (BitVec.ofNat 2 3).toNat) then (if decide ((s.dec_block__round_ctr_reg).toNat > (BitVec.ofNat 32 0).toNat) then false else true) else false))))
  { s with
    dec_block__ready_new := dec_block__ready_new
  }

/-- 组合逻辑：proc_alwayscomb_7__assignment_3 -/
def proc_alwayscomb_7__assignment_3 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_block__ready_we := (if decide ((s.dec_block__dec_ctrl_reg).toNat = (BitVec.ofNat 2 0).toNat) then (if s.dec_block__next then true else false) else (if decide ((s.dec_block__dec_ctrl_reg).toNat = (BitVec.ofNat 2 1).toNat) then false else (if decide ((s.dec_block__dec_ctrl_reg).toNat = (BitVec.ofNat 2 2).toNat) then false else (if decide ((s.dec_block__dec_ctrl_reg).toNat = (BitVec.ofNat 2 3).toNat) then (if decide ((s.dec_block__round_ctr_reg).toNat > (BitVec.ofNat 32 0).toNat) then false else true) else false))))
  { s with
    dec_block__ready_we := dec_block__ready_we
  }

/-- 组合逻辑：proc_alwayscomb_7__assignment_4 -/
def proc_alwayscomb_7__assignment_4 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_block__round_ctr_dec := (if decide ((s.dec_block__dec_ctrl_reg).toNat = (BitVec.ofNat 2 0).toNat) then false else (if decide ((s.dec_block__dec_ctrl_reg).toNat = (BitVec.ofNat 2 1).toNat) then false else (if decide ((s.dec_block__dec_ctrl_reg).toNat = (BitVec.ofNat 2 2).toNat) then (if decide ((s.dec_block__sword_ctr_reg).toNat = (BitVec.ofNat 2 3).toNat) then true else false) else false)))
  { s with
    dec_block__round_ctr_dec := dec_block__round_ctr_dec
  }

/-- 组合逻辑：proc_alwayscomb_7__assignment_5 -/
def proc_alwayscomb_7__assignment_5 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_block__round_ctr_set := (if decide ((s.dec_block__dec_ctrl_reg).toNat = (BitVec.ofNat 2 0).toNat) then (if s.dec_block__next then true else false) else false)
  { s with
    dec_block__round_ctr_set := dec_block__round_ctr_set
  }

/-- 组合逻辑：proc_alwayscomb_7__assignment_6 -/
def proc_alwayscomb_7__assignment_6 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_block__sword_ctr_inc := (if decide ((s.dec_block__dec_ctrl_reg).toNat = (BitVec.ofNat 2 0).toNat) then false else (if decide ((s.dec_block__dec_ctrl_reg).toNat = (BitVec.ofNat 2 1).toNat) then false else (if decide ((s.dec_block__dec_ctrl_reg).toNat = (BitVec.ofNat 2 2).toNat) then true else false)))
  { s with
    dec_block__sword_ctr_inc := dec_block__sword_ctr_inc
  }

/-- 组合逻辑：proc_alwayscomb_7__assignment_7 -/
def proc_alwayscomb_7__assignment_7 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_block__sword_ctr_rst := (if decide ((s.dec_block__dec_ctrl_reg).toNat = (BitVec.ofNat 2 0).toNat) then false else (if decide ((s.dec_block__dec_ctrl_reg).toNat = (BitVec.ofNat 2 1).toNat) then true else (if decide ((s.dec_block__dec_ctrl_reg).toNat = (BitVec.ofNat 2 2).toNat) then false else (if decide ((s.dec_block__dec_ctrl_reg).toNat = (BitVec.ofNat 2 3).toNat) then true else false))))
  { s with
    dec_block__sword_ctr_rst := dec_block__sword_ctr_rst
  }

/-- 组合逻辑：proc_alwayscomb_7__assignment_8 -/
def proc_alwayscomb_7__assignment_8 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_block__update_type := (if decide ((s.dec_block__dec_ctrl_reg).toNat = (BitVec.ofNat 2 0).toNat) then BitVec.ofNat 3 0 else (if decide ((s.dec_block__dec_ctrl_reg).toNat = (BitVec.ofNat 2 1).toNat) then BitVec.ofNat 3 1 else (if decide ((s.dec_block__dec_ctrl_reg).toNat = (BitVec.ofNat 2 2).toNat) then BitVec.ofNat 3 2 else (if decide ((s.dec_block__dec_ctrl_reg).toNat = (BitVec.ofNat 2 3).toNat) then (if decide ((s.dec_block__round_ctr_reg).toNat > (BitVec.ofNat 32 0).toNat) then BitVec.ofNat 3 3 else BitVec.ofNat 3 4) else BitVec.ofNat 3 0))))
  { s with
    dec_block__update_type := dec_block__update_type
  }

/-- 组合逻辑：proc_alwayscomb_8 -/
def proc_alwayscomb_8 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let keymem__tmp_round_key := bvArrayRead 128 15 0 14 (s.keymem__key_mem) ((s.keymem__round).toNat)
  { s with
    keymem__tmp_round_key := keymem__tmp_round_key
  }

/-- 组合逻辑：proc_alwayscomb_9__assignment_0 -/
def proc_alwayscomb_9__assignment_0 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let keymem__key_mem_new := (if s.keymem__round_key_update then (if decide (boolToNat (s.keymem__keylen) = boolToNat (false)) then (if decide ((s.keymem__round_ctr_reg).toNat = (BitVec.ofNat 32 0).toNat) then BitVec.extractLsb 255 128 (s.keymem__key) else BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.extractLsb 31 0 ((BitVec.extractLsb 31 0 (BitVec.extractLsb 127 96 (s.keymem__prev_key1_reg)) ^^^ BitVec.extractLsb 31 0 ((BitVec.extractLsb 31 0 (BitVec.append (n := 24) (m := 8) (BitVec.extractLsb 23 0 (s.keymem__new_sboxw)) (BitVec.extractLsb 31 24 (s.keymem__new_sboxw))) ^^^ BitVec.extractLsb 31 0 (BitVec.append (n := 8) (m := 24) (s.keymem__rcon_reg) (BitVec.ofNat 24 0))))))) (BitVec.extractLsb 31 0 (((BitVec.extractLsb 31 0 (BitVec.extractLsb 95 64 (s.keymem__prev_key1_reg)) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 127 96 (s.keymem__prev_key1_reg))) ^^^ BitVec.extractLsb 31 0 ((BitVec.extractLsb 31 0 (BitVec.append (n := 24) (m := 8) (BitVec.extractLsb 23 0 (s.keymem__new_sboxw)) (BitVec.extractLsb 31 24 (s.keymem__new_sboxw))) ^^^ BitVec.extractLsb 31 0 (BitVec.append (n := 8) (m := 24) (s.keymem__rcon_reg) (BitVec.ofNat 24 0)))))))) (BitVec.append (n := 32) (m := 32) (BitVec.extractLsb 31 0 ((((BitVec.extractLsb 31 0 (BitVec.extractLsb 63 32 (s.keymem__prev_key1_reg)) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 95 64 (s.keymem__prev_key1_reg))) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 127 96 (s.keymem__prev_key1_reg))) ^^^ BitVec.extractLsb 31 0 ((BitVec.extractLsb 31 0 (BitVec.append (n := 24) (m := 8) (BitVec.extractLsb 23 0 (s.keymem__new_sboxw)) (BitVec.extractLsb 31 24 (s.keymem__new_sboxw))) ^^^ BitVec.extractLsb 31 0 (BitVec.append (n := 8) (m := 24) (s.keymem__rcon_reg) (BitVec.ofNat 24 0))))))) (BitVec.extractLsb 31 0 (((((BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (s.keymem__prev_key1_reg)) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 63 32 (s.keymem__prev_key1_reg))) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 95 64 (s.keymem__prev_key1_reg))) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 127 96 (s.keymem__prev_key1_reg))) ^^^ BitVec.extractLsb 31 0 ((BitVec.extractLsb 31 0 (BitVec.append (n := 24) (m := 8) (BitVec.extractLsb 23 0 (s.keymem__new_sboxw)) (BitVec.extractLsb 31 24 (s.keymem__new_sboxw))) ^^^ BitVec.extractLsb 31 0 (BitVec.append (n := 8) (m := 24) (s.keymem__rcon_reg) (BitVec.ofNat 24 0))))))))) else (if decide (boolToNat (s.keymem__keylen) = boolToNat (true)) then (if decide ((s.keymem__round_ctr_reg).toNat = (BitVec.ofNat 32 0).toNat) then BitVec.extractLsb 255 128 (s.keymem__key) else (if decide ((s.keymem__round_ctr_reg).toNat = (BitVec.ofNat 32 1).toNat) then BitVec.extractLsb 127 0 (s.keymem__key) else BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) ((if decide (boolToNat (BitVec.getLsbD (s.keymem__round_ctr_reg) 0) = (BitVec.ofNat 32 0).toNat) then BitVec.extractLsb 31 0 ((BitVec.extractLsb 31 0 (BitVec.extractLsb 127 96 (s.keymem__prev_key0_reg)) ^^^ BitVec.extractLsb 31 0 ((BitVec.extractLsb 31 0 (BitVec.append (n := 24) (m := 8) (BitVec.extractLsb 23 0 (s.keymem__new_sboxw)) (BitVec.extractLsb 31 24 (s.keymem__new_sboxw))) ^^^ BitVec.extractLsb 31 0 (BitVec.append (n := 8) (m := 24) (s.keymem__rcon_reg) (BitVec.ofNat 24 0)))))) else BitVec.extractLsb 31 0 ((BitVec.extractLsb 31 0 (BitVec.extractLsb 127 96 (s.keymem__prev_key0_reg)) ^^^ BitVec.extractLsb 31 0 (s.keymem__new_sboxw))))) ((if decide (boolToNat (BitVec.getLsbD (s.keymem__round_ctr_reg) 0) = (BitVec.ofNat 32 0).toNat) then BitVec.extractLsb 31 0 (((BitVec.extractLsb 31 0 (BitVec.extractLsb 95 64 (s.keymem__prev_key0_reg)) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 127 96 (s.keymem__prev_key0_reg))) ^^^ BitVec.extractLsb 31 0 ((BitVec.extractLsb 31 0 (BitVec.append (n := 24) (m := 8) (BitVec.extractLsb 23 0 (s.keymem__new_sboxw)) (BitVec.extractLsb 31 24 (s.keymem__new_sboxw))) ^^^ BitVec.extractLsb 31 0 (BitVec.append (n := 8) (m := 24) (s.keymem__rcon_reg) (BitVec.ofNat 24 0)))))) else BitVec.extractLsb 31 0 (((BitVec.extractLsb 31 0 (BitVec.extractLsb 95 64 (s.keymem__prev_key0_reg)) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 127 96 (s.keymem__prev_key0_reg))) ^^^ BitVec.extractLsb 31 0 (s.keymem__new_sboxw)))))) (BitVec.append (n := 32) (m := 32) ((if decide (boolToNat (BitVec.getLsbD (s.keymem__round_ctr_reg) 0) = (BitVec.ofNat 32 0).toNat) then BitVec.extractLsb 31 0 ((((BitVec.extractLsb 31 0 (BitVec.extractLsb 63 32 (s.keymem__prev_key0_reg)) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 95 64 (s.keymem__prev_key0_reg))) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 127 96 (s.keymem__prev_key0_reg))) ^^^ BitVec.extractLsb 31 0 ((BitVec.extractLsb 31 0 (BitVec.append (n := 24) (m := 8) (BitVec.extractLsb 23 0 (s.keymem__new_sboxw)) (BitVec.extractLsb 31 24 (s.keymem__new_sboxw))) ^^^ BitVec.extractLsb 31 0 (BitVec.append (n := 8) (m := 24) (s.keymem__rcon_reg) (BitVec.ofNat 24 0)))))) else BitVec.extractLsb 31 0 ((((BitVec.extractLsb 31 0 (BitVec.extractLsb 63 32 (s.keymem__prev_key0_reg)) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 95 64 (s.keymem__prev_key0_reg))) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 127 96 (s.keymem__prev_key0_reg))) ^^^ BitVec.extractLsb 31 0 (s.keymem__new_sboxw))))) ((if decide (boolToNat (BitVec.getLsbD (s.keymem__round_ctr_reg) 0) = (BitVec.ofNat 32 0).toNat) then BitVec.extractLsb 31 0 (((((BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (s.keymem__prev_key0_reg)) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 63 32 (s.keymem__prev_key0_reg))) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 95 64 (s.keymem__prev_key0_reg))) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 127 96 (s.keymem__prev_key0_reg))) ^^^ BitVec.extractLsb 31 0 ((BitVec.extractLsb 31 0 (BitVec.append (n := 24) (m := 8) (BitVec.extractLsb 23 0 (s.keymem__new_sboxw)) (BitVec.extractLsb 31 24 (s.keymem__new_sboxw))) ^^^ BitVec.extractLsb 31 0 (BitVec.append (n := 8) (m := 24) (s.keymem__rcon_reg) (BitVec.ofNat 24 0)))))) else BitVec.extractLsb 31 0 (((((BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (s.keymem__prev_key0_reg)) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 63 32 (s.keymem__prev_key0_reg))) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 95 64 (s.keymem__prev_key0_reg))) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 127 96 (s.keymem__prev_key0_reg))) ^^^ BitVec.extractLsb 31 0 (s.keymem__new_sboxw)))))))) else BitVec.ofNat 128 0)) else BitVec.ofNat 128 0)
  { s with
    keymem__key_mem_new := keymem__key_mem_new
  }

/-- 组合逻辑：proc_alwayscomb_9__assignment_1 -/
def proc_alwayscomb_9__assignment_1 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let keymem__key_mem_we := (if s.keymem__round_key_update then true else false)
  { s with
    keymem__key_mem_we := keymem__key_mem_we
  }

/-- 组合逻辑：proc_alwayscomb_9__assignment_2 -/
def proc_alwayscomb_9__assignment_2 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let keymem__prev_key0_new := (if s.keymem__round_key_update then (if decide (boolToNat (s.keymem__keylen) = boolToNat (false)) then BitVec.ofNat 128 0 else (if decide (boolToNat (s.keymem__keylen) = boolToNat (true)) then (if decide ((s.keymem__round_ctr_reg).toNat = (BitVec.ofNat 32 0).toNat) then BitVec.extractLsb 255 128 (s.keymem__key) else (if decide ((s.keymem__round_ctr_reg).toNat = (BitVec.ofNat 32 1).toNat) then BitVec.ofNat 128 0 else s.keymem__prev_key1_reg)) else BitVec.ofNat 128 0)) else BitVec.ofNat 128 0)
  { s with
    keymem__prev_key0_new := keymem__prev_key0_new
  }

/-- 组合逻辑：proc_alwayscomb_9__assignment_3 -/
def proc_alwayscomb_9__assignment_3 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let keymem__prev_key0_we := (if s.keymem__round_key_update then (if decide (boolToNat (s.keymem__keylen) = boolToNat (false)) then false else (if decide (boolToNat (s.keymem__keylen) = boolToNat (true)) then (if decide ((s.keymem__round_ctr_reg).toNat = (BitVec.ofNat 32 0).toNat) then true else (if decide ((s.keymem__round_ctr_reg).toNat = (BitVec.ofNat 32 1).toNat) then false else true)) else false)) else false)
  { s with
    keymem__prev_key0_we := keymem__prev_key0_we
  }

/-- 组合逻辑：proc_alwayscomb_9__assignment_4 -/
def proc_alwayscomb_9__assignment_4 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let keymem__prev_key1_new := (if s.keymem__round_key_update then (if decide (boolToNat (s.keymem__keylen) = boolToNat (false)) then (if decide ((s.keymem__round_ctr_reg).toNat = (BitVec.ofNat 32 0).toNat) then BitVec.extractLsb 255 128 (s.keymem__key) else BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) (BitVec.extractLsb 31 0 ((BitVec.extractLsb 31 0 (BitVec.extractLsb 127 96 (s.keymem__prev_key1_reg)) ^^^ BitVec.extractLsb 31 0 ((BitVec.extractLsb 31 0 (BitVec.append (n := 24) (m := 8) (BitVec.extractLsb 23 0 (s.keymem__new_sboxw)) (BitVec.extractLsb 31 24 (s.keymem__new_sboxw))) ^^^ BitVec.extractLsb 31 0 (BitVec.append (n := 8) (m := 24) (s.keymem__rcon_reg) (BitVec.ofNat 24 0))))))) (BitVec.extractLsb 31 0 (((BitVec.extractLsb 31 0 (BitVec.extractLsb 95 64 (s.keymem__prev_key1_reg)) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 127 96 (s.keymem__prev_key1_reg))) ^^^ BitVec.extractLsb 31 0 ((BitVec.extractLsb 31 0 (BitVec.append (n := 24) (m := 8) (BitVec.extractLsb 23 0 (s.keymem__new_sboxw)) (BitVec.extractLsb 31 24 (s.keymem__new_sboxw))) ^^^ BitVec.extractLsb 31 0 (BitVec.append (n := 8) (m := 24) (s.keymem__rcon_reg) (BitVec.ofNat 24 0)))))))) (BitVec.append (n := 32) (m := 32) (BitVec.extractLsb 31 0 ((((BitVec.extractLsb 31 0 (BitVec.extractLsb 63 32 (s.keymem__prev_key1_reg)) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 95 64 (s.keymem__prev_key1_reg))) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 127 96 (s.keymem__prev_key1_reg))) ^^^ BitVec.extractLsb 31 0 ((BitVec.extractLsb 31 0 (BitVec.append (n := 24) (m := 8) (BitVec.extractLsb 23 0 (s.keymem__new_sboxw)) (BitVec.extractLsb 31 24 (s.keymem__new_sboxw))) ^^^ BitVec.extractLsb 31 0 (BitVec.append (n := 8) (m := 24) (s.keymem__rcon_reg) (BitVec.ofNat 24 0))))))) (BitVec.extractLsb 31 0 (((((BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (s.keymem__prev_key1_reg)) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 63 32 (s.keymem__prev_key1_reg))) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 95 64 (s.keymem__prev_key1_reg))) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 127 96 (s.keymem__prev_key1_reg))) ^^^ BitVec.extractLsb 31 0 ((BitVec.extractLsb 31 0 (BitVec.append (n := 24) (m := 8) (BitVec.extractLsb 23 0 (s.keymem__new_sboxw)) (BitVec.extractLsb 31 24 (s.keymem__new_sboxw))) ^^^ BitVec.extractLsb 31 0 (BitVec.append (n := 8) (m := 24) (s.keymem__rcon_reg) (BitVec.ofNat 24 0))))))))) else (if decide (boolToNat (s.keymem__keylen) = boolToNat (true)) then (if decide ((s.keymem__round_ctr_reg).toNat = (BitVec.ofNat 32 0).toNat) then BitVec.ofNat 128 0 else (if decide ((s.keymem__round_ctr_reg).toNat = (BitVec.ofNat 32 1).toNat) then BitVec.extractLsb 127 0 (s.keymem__key) else BitVec.append (n := 64) (m := 64) (BitVec.append (n := 32) (m := 32) ((if decide (boolToNat (BitVec.getLsbD (s.keymem__round_ctr_reg) 0) = (BitVec.ofNat 32 0).toNat) then BitVec.extractLsb 31 0 ((BitVec.extractLsb 31 0 (BitVec.extractLsb 127 96 (s.keymem__prev_key0_reg)) ^^^ BitVec.extractLsb 31 0 ((BitVec.extractLsb 31 0 (BitVec.append (n := 24) (m := 8) (BitVec.extractLsb 23 0 (s.keymem__new_sboxw)) (BitVec.extractLsb 31 24 (s.keymem__new_sboxw))) ^^^ BitVec.extractLsb 31 0 (BitVec.append (n := 8) (m := 24) (s.keymem__rcon_reg) (BitVec.ofNat 24 0)))))) else BitVec.extractLsb 31 0 ((BitVec.extractLsb 31 0 (BitVec.extractLsb 127 96 (s.keymem__prev_key0_reg)) ^^^ BitVec.extractLsb 31 0 (s.keymem__new_sboxw))))) ((if decide (boolToNat (BitVec.getLsbD (s.keymem__round_ctr_reg) 0) = (BitVec.ofNat 32 0).toNat) then BitVec.extractLsb 31 0 (((BitVec.extractLsb 31 0 (BitVec.extractLsb 95 64 (s.keymem__prev_key0_reg)) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 127 96 (s.keymem__prev_key0_reg))) ^^^ BitVec.extractLsb 31 0 ((BitVec.extractLsb 31 0 (BitVec.append (n := 24) (m := 8) (BitVec.extractLsb 23 0 (s.keymem__new_sboxw)) (BitVec.extractLsb 31 24 (s.keymem__new_sboxw))) ^^^ BitVec.extractLsb 31 0 (BitVec.append (n := 8) (m := 24) (s.keymem__rcon_reg) (BitVec.ofNat 24 0)))))) else BitVec.extractLsb 31 0 (((BitVec.extractLsb 31 0 (BitVec.extractLsb 95 64 (s.keymem__prev_key0_reg)) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 127 96 (s.keymem__prev_key0_reg))) ^^^ BitVec.extractLsb 31 0 (s.keymem__new_sboxw)))))) (BitVec.append (n := 32) (m := 32) ((if decide (boolToNat (BitVec.getLsbD (s.keymem__round_ctr_reg) 0) = (BitVec.ofNat 32 0).toNat) then BitVec.extractLsb 31 0 ((((BitVec.extractLsb 31 0 (BitVec.extractLsb 63 32 (s.keymem__prev_key0_reg)) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 95 64 (s.keymem__prev_key0_reg))) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 127 96 (s.keymem__prev_key0_reg))) ^^^ BitVec.extractLsb 31 0 ((BitVec.extractLsb 31 0 (BitVec.append (n := 24) (m := 8) (BitVec.extractLsb 23 0 (s.keymem__new_sboxw)) (BitVec.extractLsb 31 24 (s.keymem__new_sboxw))) ^^^ BitVec.extractLsb 31 0 (BitVec.append (n := 8) (m := 24) (s.keymem__rcon_reg) (BitVec.ofNat 24 0)))))) else BitVec.extractLsb 31 0 ((((BitVec.extractLsb 31 0 (BitVec.extractLsb 63 32 (s.keymem__prev_key0_reg)) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 95 64 (s.keymem__prev_key0_reg))) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 127 96 (s.keymem__prev_key0_reg))) ^^^ BitVec.extractLsb 31 0 (s.keymem__new_sboxw))))) ((if decide (boolToNat (BitVec.getLsbD (s.keymem__round_ctr_reg) 0) = (BitVec.ofNat 32 0).toNat) then BitVec.extractLsb 31 0 (((((BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (s.keymem__prev_key0_reg)) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 63 32 (s.keymem__prev_key0_reg))) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 95 64 (s.keymem__prev_key0_reg))) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 127 96 (s.keymem__prev_key0_reg))) ^^^ BitVec.extractLsb 31 0 ((BitVec.extractLsb 31 0 (BitVec.append (n := 24) (m := 8) (BitVec.extractLsb 23 0 (s.keymem__new_sboxw)) (BitVec.extractLsb 31 24 (s.keymem__new_sboxw))) ^^^ BitVec.extractLsb 31 0 (BitVec.append (n := 8) (m := 24) (s.keymem__rcon_reg) (BitVec.ofNat 24 0)))))) else BitVec.extractLsb 31 0 (((((BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (s.keymem__prev_key0_reg)) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 63 32 (s.keymem__prev_key0_reg))) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 95 64 (s.keymem__prev_key0_reg))) ^^^ BitVec.extractLsb 31 0 (BitVec.extractLsb 127 96 (s.keymem__prev_key0_reg))) ^^^ BitVec.extractLsb 31 0 (s.keymem__new_sboxw)))))))) else BitVec.ofNat 128 0)) else BitVec.ofNat 128 0)
  { s with
    keymem__prev_key1_new := keymem__prev_key1_new
  }

/-- 组合逻辑：proc_alwayscomb_9__assignment_5 -/
def proc_alwayscomb_9__assignment_5 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let keymem__prev_key1_we := (if s.keymem__round_key_update then (if decide (boolToNat (s.keymem__keylen) = boolToNat (false)) then true else (if decide (boolToNat (s.keymem__keylen) = boolToNat (true)) then (if decide ((s.keymem__round_ctr_reg).toNat = (BitVec.ofNat 32 0).toNat) then false else true) else false)) else false)
  { s with
    keymem__prev_key1_we := keymem__prev_key1_we
  }

/-- 组合逻辑：proc_alwayscomb_9__assignment_6 -/
def proc_alwayscomb_9__assignment_6 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let keymem__rcon_next := (if s.keymem__round_key_update then (if decide (boolToNat (s.keymem__keylen) = boolToNat (false)) then true else (if decide (boolToNat (s.keymem__keylen) = boolToNat (true)) then (if decide ((s.keymem__round_ctr_reg).toNat = (BitVec.ofNat 32 0).toNat) then false else (if decide ((s.keymem__round_ctr_reg).toNat = (BitVec.ofNat 32 1).toNat) then true else (if decide (boolToNat (BitVec.getLsbD (s.keymem__round_ctr_reg) 0) = (BitVec.ofNat 32 0).toNat) then false else true))) else false)) else false)
  { s with
    keymem__rcon_next := keymem__rcon_next
  }

/-- 组合逻辑：proc_alwayscomb_9__assignment_7 -/
def proc_alwayscomb_9__assignment_7 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let keymem__rcon_set := (if s.keymem__round_key_update then false else true)
  { s with
    keymem__rcon_set := keymem__rcon_set
  }

/-- 组合逻辑：proc_alwayscomb_9__assignment_8 -/
def proc_alwayscomb_9__assignment_8 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let keymem__tmp_sboxw := BitVec.extractLsb 31 0 (BitVec.extractLsb 31 0 (s.keymem__prev_key1_reg))
  { s with
    keymem__tmp_sboxw := keymem__tmp_sboxw
  }

/-- 组合逻辑：proc_alwayscomb_10__assignment_0 -/
def proc_alwayscomb_10__assignment_0 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let keymem__rcon_new := (if s.keymem__rcon_next then BitVec.extractLsb 7 0 (BitVec.extractLsb 7 0 ((BitVec.append (n := 7) (m := 1) (BitVec.extractLsb 6 0 (s.keymem__rcon_reg)) (boolToBitVec (false)) ^^^ (BitVec.ofNat 8 27 &&& BitVec.append (n := 4) (m := 4) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.keymem__rcon_reg) 7)) (boolToBitVec (BitVec.getLsbD (s.keymem__rcon_reg) 7))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.keymem__rcon_reg) 7)) (boolToBitVec (BitVec.getLsbD (s.keymem__rcon_reg) 7)))) (BitVec.append (n := 2) (m := 2) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.keymem__rcon_reg) 7)) (boolToBitVec (BitVec.getLsbD (s.keymem__rcon_reg) 7))) (BitVec.append (n := 1) (m := 1) (boolToBitVec (BitVec.getLsbD (s.keymem__rcon_reg) 7)) (boolToBitVec (BitVec.getLsbD (s.keymem__rcon_reg) 7)))))))) else (if s.keymem__rcon_set then BitVec.ofNat 8 141 else BitVec.ofNat 8 0))
  { s with
    keymem__rcon_new := keymem__rcon_new
  }

/-- 组合逻辑：proc_alwayscomb_10__assignment_1 -/
def proc_alwayscomb_10__assignment_1 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let keymem__rcon_we := (if s.keymem__rcon_next then true else (if s.keymem__rcon_set then true else false))
  { s with
    keymem__rcon_we := keymem__rcon_we
  }

/-- 组合逻辑：proc_alwayscomb_11__assignment_0 -/
def proc_alwayscomb_11__assignment_0 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let keymem__round_ctr_new := (if s.keymem__round_ctr_rst then BitVec.ofNat 4 0 else (if s.keymem__round_ctr_inc then (s.keymem__round_ctr_reg + BitVec.ofNat 4 1) else BitVec.ofNat 4 0))
  { s with
    keymem__round_ctr_new := keymem__round_ctr_new
  }

/-- 组合逻辑：proc_alwayscomb_11__assignment_1 -/
def proc_alwayscomb_11__assignment_1 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let keymem__round_ctr_we := (if s.keymem__round_ctr_rst then true else (if s.keymem__round_ctr_inc then true else false))
  { s with
    keymem__round_ctr_we := keymem__round_ctr_we
  }

/-- 组合逻辑：proc_alwayscomb_12__assignment_0 -/
def proc_alwayscomb_12__assignment_0 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let keymem__key_mem_ctrl_new := (if decide ((s.keymem__key_mem_ctrl_reg).toNat = (BitVec.ofNat 3 0).toNat) then (if s.keymem__init then BitVec.ofNat 3 1 else BitVec.ofNat 3 0) else (if decide ((s.keymem__key_mem_ctrl_reg).toNat = (BitVec.ofNat 3 1).toNat) then BitVec.ofNat 3 2 else (if decide ((s.keymem__key_mem_ctrl_reg).toNat = (BitVec.ofNat 3 2).toNat) then (if decide ((s.keymem__round_ctr_reg).toNat = ((if decide (boolToNat (s.keymem__keylen) = boolToNat (false)) then BitVec.extractLsb 3 0 (BitVec.extractLsb 3 0 (BitVec.ofNat 32 10)) else BitVec.extractLsb 3 0 (BitVec.extractLsb 3 0 (BitVec.ofNat 32 14)))).toNat) then BitVec.ofNat 3 3 else BitVec.ofNat 3 0) else BitVec.ofNat 3 0)))
  { s with
    keymem__key_mem_ctrl_new := keymem__key_mem_ctrl_new
  }

/-- 组合逻辑：proc_alwayscomb_12__assignment_1 -/
def proc_alwayscomb_12__assignment_1 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let keymem__key_mem_ctrl_we := (if decide ((s.keymem__key_mem_ctrl_reg).toNat = (BitVec.ofNat 3 0).toNat) then (if s.keymem__init then true else false) else (if decide ((s.keymem__key_mem_ctrl_reg).toNat = (BitVec.ofNat 3 1).toNat) then true else (if decide ((s.keymem__key_mem_ctrl_reg).toNat = (BitVec.ofNat 3 2).toNat) then (if decide ((s.keymem__round_ctr_reg).toNat = ((if decide (boolToNat (s.keymem__keylen) = boolToNat (false)) then BitVec.extractLsb 3 0 (BitVec.extractLsb 3 0 (BitVec.ofNat 32 10)) else BitVec.extractLsb 3 0 (BitVec.extractLsb 3 0 (BitVec.ofNat 32 14)))).toNat) then true else false) else (if decide ((s.keymem__key_mem_ctrl_reg).toNat = (BitVec.ofNat 3 3).toNat) then true else false))))
  { s with
    keymem__key_mem_ctrl_we := keymem__key_mem_ctrl_we
  }

/-- 组合逻辑：proc_alwayscomb_12__assignment_2 -/
def proc_alwayscomb_12__assignment_2 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let keymem__ready_new := (if decide ((s.keymem__key_mem_ctrl_reg).toNat = (BitVec.ofNat 3 0).toNat) then false else (if decide ((s.keymem__key_mem_ctrl_reg).toNat = (BitVec.ofNat 3 1).toNat) then false else (if decide ((s.keymem__key_mem_ctrl_reg).toNat = (BitVec.ofNat 3 2).toNat) then false else (if decide ((s.keymem__key_mem_ctrl_reg).toNat = (BitVec.ofNat 3 3).toNat) then true else false))))
  { s with
    keymem__ready_new := keymem__ready_new
  }

/-- 组合逻辑：proc_alwayscomb_12__assignment_3 -/
def proc_alwayscomb_12__assignment_3 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let keymem__ready_we := (if decide ((s.keymem__key_mem_ctrl_reg).toNat = (BitVec.ofNat 3 0).toNat) then (if s.keymem__init then true else false) else (if decide ((s.keymem__key_mem_ctrl_reg).toNat = (BitVec.ofNat 3 1).toNat) then false else (if decide ((s.keymem__key_mem_ctrl_reg).toNat = (BitVec.ofNat 3 2).toNat) then false else (if decide ((s.keymem__key_mem_ctrl_reg).toNat = (BitVec.ofNat 3 3).toNat) then true else false))))
  { s with
    keymem__ready_we := keymem__ready_we
  }

/-- 组合逻辑：proc_alwayscomb_12__assignment_4 -/
def proc_alwayscomb_12__assignment_4 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let keymem__round_ctr_inc := (if decide ((s.keymem__key_mem_ctrl_reg).toNat = (BitVec.ofNat 3 0).toNat) then false else (if decide ((s.keymem__key_mem_ctrl_reg).toNat = (BitVec.ofNat 3 1).toNat) then false else (if decide ((s.keymem__key_mem_ctrl_reg).toNat = (BitVec.ofNat 3 2).toNat) then true else false)))
  { s with
    keymem__round_ctr_inc := keymem__round_ctr_inc
  }

/-- 组合逻辑：proc_alwayscomb_12__assignment_5 -/
def proc_alwayscomb_12__assignment_5 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let keymem__round_ctr_rst := (if decide ((s.keymem__key_mem_ctrl_reg).toNat = (BitVec.ofNat 3 0).toNat) then false else (if decide ((s.keymem__key_mem_ctrl_reg).toNat = (BitVec.ofNat 3 1).toNat) then true else false))
  { s with
    keymem__round_ctr_rst := keymem__round_ctr_rst
  }

/-- 组合逻辑：proc_alwayscomb_12__assignment_6 -/
def proc_alwayscomb_12__assignment_6 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let keymem__round_key_update := (if decide ((s.keymem__key_mem_ctrl_reg).toNat = (BitVec.ofNat 3 0).toNat) then false else (if decide ((s.keymem__key_mem_ctrl_reg).toNat = (BitVec.ofNat 3 1).toNat) then false else (if decide ((s.keymem__key_mem_ctrl_reg).toNat = (BitVec.ofNat 3 2).toNat) then true else false)))
  { s with
    keymem__round_key_update := keymem__round_key_update
  }

/-- 组合逻辑：proc_alwayscomb_13 -/
def proc_alwayscomb_13 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let muxed_sboxw := (if s.init_state then s.keymem_sboxw else s.enc_sboxw)
  { s with
    muxed_sboxw := muxed_sboxw
  }

/-- 组合逻辑：proc_alwayscomb_14__assignment_0 -/
def proc_alwayscomb_14__assignment_0 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let dec_next := (if i.encdec then false else i.next)
  { s with
    dec_next := dec_next
  }

/-- 组合逻辑：proc_alwayscomb_14__assignment_1 -/
def proc_alwayscomb_14__assignment_1 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let enc_next := (if i.encdec then i.next else false)
  { s with
    enc_next := enc_next
  }

/-- 组合逻辑：proc_alwayscomb_14__assignment_2 -/
def proc_alwayscomb_14__assignment_2 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let muxed_new_block := (if i.encdec then s.enc_new_block else s.dec_new_block)
  { s with
    muxed_new_block := muxed_new_block
  }

/-- 组合逻辑：proc_alwayscomb_14__assignment_3 -/
def proc_alwayscomb_14__assignment_3 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let muxed_ready := (if i.encdec then s.enc_ready else s.dec_ready)
  { s with
    muxed_ready := muxed_ready
  }

/-- 组合逻辑：proc_alwayscomb_14__assignment_4 -/
def proc_alwayscomb_14__assignment_4 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let muxed_round_nr := (if i.encdec then s.enc_round_nr else s.dec_round_nr)
  { s with
    muxed_round_nr := muxed_round_nr
  }

/-- 组合逻辑：proc_alwayscomb_15__assignment_0 -/
def proc_alwayscomb_15__assignment_0 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let aes_core_ctrl_new := (if decide ((s.aes_core_ctrl_reg).toNat = (BitVec.ofNat 2 0).toNat) then (if i.init then BitVec.ofNat 2 1 else (if i.next then BitVec.ofNat 2 2 else BitVec.ofNat 2 0)) else BitVec.ofNat 2 0)
  { s with
    aes_core_ctrl_new := aes_core_ctrl_new
  }

/-- 组合逻辑：proc_alwayscomb_15__assignment_1 -/
def proc_alwayscomb_15__assignment_1 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let aes_core_ctrl_we := (if decide ((s.aes_core_ctrl_reg).toNat = (BitVec.ofNat 2 0).toNat) then (if i.init then true else (if i.next then true else false)) else (if decide ((s.aes_core_ctrl_reg).toNat = (BitVec.ofNat 2 1).toNat) then (if s.key_ready then true else false) else (if decide ((s.aes_core_ctrl_reg).toNat = (BitVec.ofNat 2 2).toNat) then (if s.muxed_ready then true else false) else false)))
  { s with
    aes_core_ctrl_we := aes_core_ctrl_we
  }

/-- 组合逻辑：proc_alwayscomb_15__assignment_2 -/
def proc_alwayscomb_15__assignment_2 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let init_state := (if decide ((s.aes_core_ctrl_reg).toNat = (BitVec.ofNat 2 0).toNat) then (if i.init then true else false) else (if decide ((s.aes_core_ctrl_reg).toNat = (BitVec.ofNat 2 1).toNat) then true else false))
  { s with
    init_state := init_state
  }

/-- 组合逻辑：proc_alwayscomb_15__assignment_3 -/
def proc_alwayscomb_15__assignment_3 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let ready_new := (if decide ((s.aes_core_ctrl_reg).toNat = (BitVec.ofNat 2 0).toNat) then false else (if decide ((s.aes_core_ctrl_reg).toNat = (BitVec.ofNat 2 1).toNat) then (if s.key_ready then true else false) else (if decide ((s.aes_core_ctrl_reg).toNat = (BitVec.ofNat 2 2).toNat) then (if s.muxed_ready then true else false) else false)))
  { s with
    ready_new := ready_new
  }

/-- 组合逻辑：proc_alwayscomb_15__assignment_4 -/
def proc_alwayscomb_15__assignment_4 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let ready_we := (if decide ((s.aes_core_ctrl_reg).toNat = (BitVec.ofNat 2 0).toNat) then (if i.init then true else (if i.next then true else false)) else (if decide ((s.aes_core_ctrl_reg).toNat = (BitVec.ofNat 2 1).toNat) then (if s.key_ready then true else false) else (if decide ((s.aes_core_ctrl_reg).toNat = (BitVec.ofNat 2 2).toNat) then (if s.muxed_ready then true else false) else false)))
  { s with
    ready_we := ready_we
  }

/-- 组合逻辑：proc_alwayscomb_15__assignment_5 -/
def proc_alwayscomb_15__assignment_5 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let result_valid_new := (if decide ((s.aes_core_ctrl_reg).toNat = (BitVec.ofNat 2 0).toNat) then false else (if decide ((s.aes_core_ctrl_reg).toNat = (BitVec.ofNat 2 1).toNat) then false else (if decide ((s.aes_core_ctrl_reg).toNat = (BitVec.ofNat 2 2).toNat) then (if s.muxed_ready then true else false) else false)))
  { s with
    result_valid_new := result_valid_new
  }

/-- 组合逻辑：proc_alwayscomb_15__assignment_6 -/
def proc_alwayscomb_15__assignment_6 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let result_valid_we := (if decide ((s.aes_core_ctrl_reg).toNat = (BitVec.ofNat 2 0).toNat) then (if i.init then true else (if i.next then true else false)) else (if decide ((s.aes_core_ctrl_reg).toNat = (BitVec.ofNat 2 1).toNat) then false else (if decide ((s.aes_core_ctrl_reg).toNat = (BitVec.ofNat 2 2).toNat) then (if s.muxed_ready then true else false) else false)))
  { s with
    result_valid_we := result_valid_we
  }

private def _rtl_comb_block_32 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let result :=
    assign_enc_block__clk s i
    |> (fun s' => assign_enc_block__reset_n s' i)
    |> (fun s' => assign_enc_block__keylen s' i)
    |> (fun s' => assign_enc_block__block s' i)
    |> (fun s' => assign_enc_block__round s' i)
    |> (fun s' => assign_enc_block__new_block s' i)
    |> (fun s' => assign_enc_block__ready s' i)
    |> (fun s' => assign_dec_block__clk s' i)
    |> (fun s' => assign_dec_block__reset_n s' i)
    |> (fun s' => assign_dec_block__keylen s' i)
    |> (fun s' => assign_dec_block__block s' i)
    |> (fun s' => assign_dec_block__inv_sbox_inst__inv_sbox s' i)
    |> (fun s' => assign_dec_block__round s' i)
    |> (fun s' => assign_dec_block__new_block s' i)
    |> (fun s' => assign_dec_block__ready s' i)
    |> (fun s' => assign_keymem__clk s' i)
    |> (fun s' => assign_keymem__reset_n s' i)
    |> (fun s' => assign_keymem__key s' i)
    |> (fun s' => assign_keymem__keylen s' i)
    |> (fun s' => assign_keymem__init s' i)
    |> (fun s' => assign_keymem__ready s' i)
    |> (fun s' => assign_sbox_inst__sbox s' i)
    |> (fun s' => assign_ready s' i)
    |> (fun s' => assign_result_valid s' i)
    |> (fun s' => proc_alwayscomb_3__assignment_4 s' i)
    |> (fun s' => proc_alwayscomb_3__assignment_6 s' i)
    |> (fun s' => proc_alwayscomb_3__assignment_7 s' i)
    |> (fun s' => proc_alwayscomb_7__assignment_2 s' i)
    |> (fun s' => proc_alwayscomb_7__assignment_4 s' i)
    |> (fun s' => proc_alwayscomb_7__assignment_6 s' i)
    |> (fun s' => proc_alwayscomb_7__assignment_7 s' i)
    |> (fun s' => proc_alwayscomb_7__assignment_8 s' i)

  result

private def _rtl_comb_block_33 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let result :=
    proc_alwayscomb_9__assignment_8 s i
    |> (fun s' => proc_alwayscomb_12__assignment_2 s' i)
    |> (fun s' => proc_alwayscomb_12__assignment_4 s' i)
    |> (fun s' => proc_alwayscomb_12__assignment_5 s' i)
    |> (fun s' => proc_alwayscomb_12__assignment_6 s' i)
    |> (fun s' => proc_alwayscomb_14__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_14__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_15__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_15__assignment_2 s' i)
    |> (fun s' => assign_enc_block__next s' i)
    |> (fun s' => assign_enc_round_nr s' i)
    |> (fun s' => assign_enc_new_block s' i)
    |> (fun s' => assign_enc_ready s' i)
    |> (fun s' => assign_dec_block__next s' i)
    |> (fun s' => assign_dec_round_nr s' i)
    |> (fun s' => assign_dec_new_block s' i)
    |> (fun s' => assign_dec_ready s' i)
    |> (fun s' => assign_key_ready s' i)
    |> (fun s' => assign_keymem__sboxw s' i)
    |> (fun s' => proc_alwayscomb_1__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_1__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_3__assignment_2 s' i)
    |> (fun s' => proc_alwayscomb_3__assignment_8 s' i)
    |> (fun s' => proc_alwayscomb_4__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_4__assignment_2 s' i)
    |> (fun s' => proc_alwayscomb_4__assignment_3 s' i)
    |> (fun s' => proc_alwayscomb_4__assignment_4 s' i)
    |> (fun s' => proc_alwayscomb_4__assignment_5 s' i)
    |> (fun s' => proc_alwayscomb_5__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_5__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_9__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_9__assignment_2 s' i)

  result

private def _rtl_comb_block_34 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let result :=
    proc_alwayscomb_9__assignment_3 s i
    |> (fun s' => proc_alwayscomb_9__assignment_5 s' i)
    |> (fun s' => proc_alwayscomb_9__assignment_6 s' i)
    |> (fun s' => proc_alwayscomb_9__assignment_7 s' i)
    |> (fun s' => proc_alwayscomb_11__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_11__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_12__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_12__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_12__assignment_3 s' i)
    |> (fun s' => assign_dec_block__inv_sbox_inst__sboxw s' i)
    |> (fun s' => assign_keymem_sboxw s' i)
    |> (fun s' => proc_alwayscomb__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb__assignment_2 s' i)
    |> (fun s' => proc_alwayscomb__assignment_3 s' i)
    |> (fun s' => proc_alwayscomb__assignment_4 s' i)
    |> (fun s' => proc_alwayscomb__assignment_5 s' i)
    |> (fun s' => proc_alwayscomb_3__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_3__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_3__assignment_3 s' i)
    |> (fun s' => proc_alwayscomb_3__assignment_5 s' i)
    |> (fun s' => proc_alwayscomb_7__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_7__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_7__assignment_3 s' i)
    |> (fun s' => proc_alwayscomb_7__assignment_5 s' i)
    |> (fun s' => proc_alwayscomb_10__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_10__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_14__assignment_2 s' i)
    |> (fun s' => proc_alwayscomb_14__assignment_3 s' i)
    |> (fun s' => proc_alwayscomb_14__assignment_4 s' i)
    |> (fun s' => assign_enc_block__sboxw s' i)
    |> (fun s' => assign_dec_block__inv_sbox_inst__new_sboxw s' i)
    |> (fun s' => assign_keymem__round s' i)

  result

private def _rtl_comb_block_35 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let result :=
    assign_result s i
    |> (fun s' => proc_alwayscomb_2__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_2__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_6__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_6__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_15__assignment_1 s' i)
    |> (fun s' => proc_alwayscomb_15__assignment_3 s' i)
    |> (fun s' => proc_alwayscomb_15__assignment_4 s' i)
    |> (fun s' => proc_alwayscomb_15__assignment_5 s' i)
    |> (fun s' => proc_alwayscomb_15__assignment_6 s' i)
    |> (fun s' => assign_enc_sboxw s' i)
    |> (fun s' => assign_dec_block__new_sboxw s' i)
    |> (fun s' => proc_alwayscomb_8 s' i)
    |> (fun s' => assign_keymem__round_key s' i)
    |> (fun s' => proc_alwayscomb_13 s' i)
    |> (fun s' => assign_round_key s' i)
    |> (fun s' => assign_sbox_inst__sboxw s' i)
    |> (fun s' => assign_enc_block__round_key s' i)
    |> (fun s' => assign_dec_block__round_key s' i)
    |> (fun s' => assign_sbox_inst__new_sboxw s' i)
    |> (fun s' => assign_new_sboxw s' i)
    |> (fun s' => proc_alwayscomb_4__assignment_0 s' i)
    |> (fun s' => assign_enc_block__new_sboxw s' i)
    |> (fun s' => assign_keymem__new_sboxw s' i)
    |> (fun s' => proc_alwayscomb__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_9__assignment_0 s' i)
    |> (fun s' => proc_alwayscomb_9__assignment_4 s' i)

  result

/-- Combinational fixed-point schedule derived from IR dependencies -/
def comb (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let result :=
    _rtl_comb_block_32 s i
    |> (fun s' => _rtl_comb_block_33 s' i)
    |> (fun s' => _rtl_comb_block_34 s' i)
    |> (fun s' => _rtl_comb_block_35 s' i)

  result

/-- 时序逻辑: proc_alwaysff (clk=clk, rst=reset_n) — 复位由 step 顶层处理 -/
def proc_alwaysff (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  { s with
    enc_block__block_w0_reg := (if !(s.enc_block__reset_n) then BitVec.ofNat 32 0 else (if s.enc_block__block_w0_we then BitVec.extractLsb 127 96 (s.enc_block__block_new) else s.enc_block__block_w0_reg))
    enc_block__block_w1_reg := (if !(s.enc_block__reset_n) then BitVec.ofNat 32 0 else (if s.enc_block__block_w1_we then BitVec.extractLsb 95 64 (s.enc_block__block_new) else s.enc_block__block_w1_reg))
    enc_block__block_w2_reg := (if !(s.enc_block__reset_n) then BitVec.ofNat 32 0 else (if s.enc_block__block_w2_we then BitVec.extractLsb 63 32 (s.enc_block__block_new) else s.enc_block__block_w2_reg))
    enc_block__block_w3_reg := (if !(s.enc_block__reset_n) then BitVec.ofNat 32 0 else (if s.enc_block__block_w3_we then BitVec.extractLsb 31 0 (s.enc_block__block_new) else s.enc_block__block_w3_reg))
    enc_block__enc_ctrl_reg := (if !(s.enc_block__reset_n) then BitVec.ofNat 2 0 else (if s.enc_block__enc_ctrl_we then s.enc_block__enc_ctrl_new else s.enc_block__enc_ctrl_reg))
    enc_block__ready_reg := (if !(s.enc_block__reset_n) then true else (if s.enc_block__ready_we then s.enc_block__ready_new else s.enc_block__ready_reg))
    enc_block__round_ctr_reg := (if !(s.enc_block__reset_n) then BitVec.ofNat 4 0 else (if s.enc_block__round_ctr_we then s.enc_block__round_ctr_new else s.enc_block__round_ctr_reg))
    enc_block__sword_ctr_reg := (if !(s.enc_block__reset_n) then BitVec.ofNat 2 0 else (if s.enc_block__sword_ctr_we then s.enc_block__sword_ctr_new else s.enc_block__sword_ctr_reg))
  }

/-- 时序逻辑: proc_alwaysff_1 (clk=clk, rst=reset_n) — 复位由 step 顶层处理 -/
def proc_alwaysff_1 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  { s with
    dec_block__block_w0_reg := (if !(s.dec_block__reset_n) then BitVec.ofNat 32 0 else (if s.dec_block__block_w0_we then BitVec.extractLsb 127 96 (s.dec_block__block_new) else s.dec_block__block_w0_reg))
    dec_block__block_w1_reg := (if !(s.dec_block__reset_n) then BitVec.ofNat 32 0 else (if s.dec_block__block_w1_we then BitVec.extractLsb 95 64 (s.dec_block__block_new) else s.dec_block__block_w1_reg))
    dec_block__block_w2_reg := (if !(s.dec_block__reset_n) then BitVec.ofNat 32 0 else (if s.dec_block__block_w2_we then BitVec.extractLsb 63 32 (s.dec_block__block_new) else s.dec_block__block_w2_reg))
    dec_block__block_w3_reg := (if !(s.dec_block__reset_n) then BitVec.ofNat 32 0 else (if s.dec_block__block_w3_we then BitVec.extractLsb 31 0 (s.dec_block__block_new) else s.dec_block__block_w3_reg))
    dec_block__dec_ctrl_reg := (if !(s.dec_block__reset_n) then BitVec.ofNat 2 0 else (if s.dec_block__dec_ctrl_we then s.dec_block__dec_ctrl_new else s.dec_block__dec_ctrl_reg))
    dec_block__ready_reg := (if !(s.dec_block__reset_n) then true else (if s.dec_block__ready_we then s.dec_block__ready_new else s.dec_block__ready_reg))
    dec_block__round_ctr_reg := (if !(s.dec_block__reset_n) then BitVec.ofNat 4 0 else (if s.dec_block__round_ctr_we then s.dec_block__round_ctr_new else s.dec_block__round_ctr_reg))
    dec_block__sword_ctr_reg := (if !(s.dec_block__reset_n) then BitVec.ofNat 2 0 else (if s.dec_block__sword_ctr_we then s.dec_block__sword_ctr_new else s.dec_block__sword_ctr_reg))
  }

/-- 时序逻辑: proc_alwaysff_2 (clk=clk, rst=reset_n) — 复位由 step 顶层处理 -/
def proc_alwaysff_2 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  { s with
    keymem__key_mem := (if !(s.keymem__reset_n) then bvArrayWrite 128 15 0 14 (bvArrayWrite 128 15 0 14 (bvArrayWrite 128 15 0 14 (bvArrayWrite 128 15 0 14 (bvArrayWrite 128 15 0 14 (bvArrayWrite 128 15 0 14 (bvArrayWrite 128 15 0 14 (bvArrayWrite 128 15 0 14 (bvArrayWrite 128 15 0 14 (bvArrayWrite 128 15 0 14 (bvArrayWrite 128 15 0 14 (bvArrayWrite 128 15 0 14 (bvArrayWrite 128 15 0 14 (bvArrayWrite 128 15 0 14 (bvArrayWrite 128 15 0 14 (s.keymem__key_mem) ((BitVec.ofNat 32 0).toNat) (BitVec.ofNat 128 0)) ((BitVec.ofNat 32 1).toNat) (BitVec.ofNat 128 0)) ((BitVec.ofNat 32 2).toNat) (BitVec.ofNat 128 0)) ((BitVec.ofNat 32 3).toNat) (BitVec.ofNat 128 0)) ((BitVec.ofNat 32 4).toNat) (BitVec.ofNat 128 0)) ((BitVec.ofNat 32 5).toNat) (BitVec.ofNat 128 0)) ((BitVec.ofNat 32 6).toNat) (BitVec.ofNat 128 0)) ((BitVec.ofNat 32 7).toNat) (BitVec.ofNat 128 0)) ((BitVec.ofNat 32 8).toNat) (BitVec.ofNat 128 0)) ((BitVec.ofNat 32 9).toNat) (BitVec.ofNat 128 0)) ((BitVec.ofNat 32 10).toNat) (BitVec.ofNat 128 0)) ((BitVec.ofNat 32 11).toNat) (BitVec.ofNat 128 0)) ((BitVec.ofNat 32 12).toNat) (BitVec.ofNat 128 0)) ((BitVec.ofNat 32 13).toNat) (BitVec.ofNat 128 0)) ((BitVec.ofNat 32 14).toNat) (BitVec.ofNat 128 0) else (if s.keymem__key_mem_we then bvArrayWrite 128 15 0 14 (s.keymem__key_mem) ((s.keymem__round_ctr_reg).toNat) (s.keymem__key_mem_new) else s.keymem__key_mem))
    keymem__key_mem_ctrl_reg := (if !(s.keymem__reset_n) then BitVec.ofNat 3 0 else (if s.keymem__key_mem_ctrl_we then s.keymem__key_mem_ctrl_new else s.keymem__key_mem_ctrl_reg))
    keymem__prev_key0_reg := (if !(s.keymem__reset_n) then BitVec.ofNat 128 0 else (if s.keymem__prev_key0_we then s.keymem__prev_key0_new else s.keymem__prev_key0_reg))
    keymem__prev_key1_reg := (if !(s.keymem__reset_n) then BitVec.ofNat 128 0 else (if s.keymem__prev_key1_we then s.keymem__prev_key1_new else s.keymem__prev_key1_reg))
    keymem__rcon_reg := (if !(s.keymem__reset_n) then BitVec.ofNat 8 0 else (if s.keymem__rcon_we then s.keymem__rcon_new else s.keymem__rcon_reg))
    keymem__ready_reg := (if !(s.keymem__reset_n) then true else (if s.keymem__ready_we then s.keymem__ready_new else s.keymem__ready_reg))
    keymem__round_ctr_reg := (if !(s.keymem__reset_n) then BitVec.ofNat 4 0 else (if s.keymem__round_ctr_we then s.keymem__round_ctr_new else s.keymem__round_ctr_reg))
  }

/-- 时序逻辑: proc_alwaysff_3 (clk=clk, rst=reset_n) — 复位由 step 顶层处理 -/
def proc_alwaysff_3 (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  { s with
    aes_core_ctrl_reg := (if !(i.reset_n) then BitVec.ofNat 2 0 else (if s.aes_core_ctrl_we then s.aes_core_ctrl_new else s.aes_core_ctrl_reg))
    ready_reg := (if !(i.reset_n) then true else (if s.ready_we then s.ready_new else s.ready_reg))
    result_valid_reg := (if !(i.reset_n) then false else (if s.result_valid_we then s.result_valid_new else s.result_valid_reg))
  }

/-- Parallel nonblocking commit for the single clock domain -/
def commit (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let s1 := proc_alwaysff s i
  let s2 := proc_alwaysff_1 s i
  let s3 := proc_alwaysff_2 s i
  let s4 := proc_alwaysff_3 s i
  let result := {
    aes_core_ctrl_reg := s4.aes_core_ctrl_reg
    dec_block__block_w0_reg := s2.dec_block__block_w0_reg
    dec_block__block_w1_reg := s2.dec_block__block_w1_reg
    dec_block__block_w2_reg := s2.dec_block__block_w2_reg
    dec_block__block_w3_reg := s2.dec_block__block_w3_reg
    dec_block__dec_ctrl_reg := s2.dec_block__dec_ctrl_reg
    dec_block__ready_reg := s2.dec_block__ready_reg
    dec_block__round_ctr_reg := s2.dec_block__round_ctr_reg
    dec_block__sword_ctr_reg := s2.dec_block__sword_ctr_reg
    enc_block__block_w0_reg := s1.enc_block__block_w0_reg
    enc_block__block_w1_reg := s1.enc_block__block_w1_reg
    enc_block__block_w2_reg := s1.enc_block__block_w2_reg
    enc_block__block_w3_reg := s1.enc_block__block_w3_reg
    enc_block__enc_ctrl_reg := s1.enc_block__enc_ctrl_reg
    enc_block__ready_reg := s1.enc_block__ready_reg
    enc_block__round_ctr_reg := s1.enc_block__round_ctr_reg
    enc_block__sword_ctr_reg := s1.enc_block__sword_ctr_reg
    keymem__key_mem := s3.keymem__key_mem
    keymem__key_mem_ctrl_reg := s3.keymem__key_mem_ctrl_reg
    keymem__prev_key0_reg := s3.keymem__prev_key0_reg
    keymem__prev_key1_reg := s3.keymem__prev_key1_reg
    keymem__rcon_reg := s3.keymem__rcon_reg
    keymem__ready_reg := s3.keymem__ready_reg
    keymem__round_ctr_reg := s3.keymem__round_ctr_reg
    ready_reg := s4.ready_reg
    result_valid_reg := s4.result_valid_reg
    round_key := s.round_key
    key_ready := s.key_ready
    enc_round_nr := s.enc_round_nr
    enc_new_block := s.enc_new_block
    enc_ready := s.enc_ready
    enc_sboxw := s.enc_sboxw
    dec_round_nr := s.dec_round_nr
    dec_new_block := s.dec_new_block
    dec_ready := s.dec_ready
    keymem_sboxw := s.keymem_sboxw
    new_sboxw := s.new_sboxw
    enc_block__clk := s.enc_block__clk
    enc_block__reset_n := s.enc_block__reset_n
    enc_block__next := s.enc_block__next
    enc_block__keylen := s.enc_block__keylen
    enc_block__round := s.enc_block__round
    enc_block__round_key := s.enc_block__round_key
    enc_block__sboxw := s.enc_block__sboxw
    enc_block__new_sboxw := s.enc_block__new_sboxw
    enc_block__block := s.enc_block__block
    enc_block__new_block := s.enc_block__new_block
    enc_block__ready := s.enc_block__ready
    dec_block__clk := s.dec_block__clk
    dec_block__reset_n := s.dec_block__reset_n
    dec_block__next := s.dec_block__next
    dec_block__keylen := s.dec_block__keylen
    dec_block__round := s.dec_block__round
    dec_block__round_key := s.dec_block__round_key
    dec_block__block := s.dec_block__block
    dec_block__new_block := s.dec_block__new_block
    dec_block__ready := s.dec_block__ready
    dec_block__new_sboxw := s.dec_block__new_sboxw
    dec_block__inv_sbox_inst__sboxw := s.dec_block__inv_sbox_inst__sboxw
    dec_block__inv_sbox_inst__new_sboxw := s.dec_block__inv_sbox_inst__new_sboxw
    dec_block__inv_sbox_inst__inv_sbox := s.dec_block__inv_sbox_inst__inv_sbox
    keymem__clk := s.keymem__clk
    keymem__reset_n := s.keymem__reset_n
    keymem__key := s.keymem__key
    keymem__keylen := s.keymem__keylen
    keymem__init := s.keymem__init
    keymem__round := s.keymem__round
    keymem__round_key := s.keymem__round_key
    keymem__ready := s.keymem__ready
    keymem__sboxw := s.keymem__sboxw
    keymem__new_sboxw := s.keymem__new_sboxw
    sbox_inst__sboxw := s.sbox_inst__sboxw
    sbox_inst__new_sboxw := s.sbox_inst__new_sboxw
    sbox_inst__sbox := s.sbox_inst__sbox
    ready := s.ready
    result := s.result
    result_valid := s.result_valid
    aes_core_ctrl_new := s.aes_core_ctrl_new
    aes_core_ctrl_we := s.aes_core_ctrl_we
    dec_block__block_new := s.dec_block__block_new
    dec_block__block_w0_we := s.dec_block__block_w0_we
    dec_block__block_w1_we := s.dec_block__block_w1_we
    dec_block__block_w2_we := s.dec_block__block_w2_we
    dec_block__block_w3_we := s.dec_block__block_w3_we
    dec_block__dec_ctrl_new := s.dec_block__dec_ctrl_new
    dec_block__dec_ctrl_we := s.dec_block__dec_ctrl_we
    dec_block__ready_new := s.dec_block__ready_new
    dec_block__ready_we := s.dec_block__ready_we
    dec_block__round_ctr_dec := s.dec_block__round_ctr_dec
    dec_block__round_ctr_new := s.dec_block__round_ctr_new
    dec_block__round_ctr_set := s.dec_block__round_ctr_set
    dec_block__round_ctr_we := s.dec_block__round_ctr_we
    dec_block__sword_ctr_inc := s.dec_block__sword_ctr_inc
    dec_block__sword_ctr_new := s.dec_block__sword_ctr_new
    dec_block__sword_ctr_rst := s.dec_block__sword_ctr_rst
    dec_block__sword_ctr_we := s.dec_block__sword_ctr_we
    dec_block__tmp_sboxw := s.dec_block__tmp_sboxw
    dec_block__update_type := s.dec_block__update_type
    dec_next := s.dec_next
    enc_block__block_new := s.enc_block__block_new
    enc_block__block_w0_we := s.enc_block__block_w0_we
    enc_block__block_w1_we := s.enc_block__block_w1_we
    enc_block__block_w2_we := s.enc_block__block_w2_we
    enc_block__block_w3_we := s.enc_block__block_w3_we
    enc_block__enc_ctrl_new := s.enc_block__enc_ctrl_new
    enc_block__enc_ctrl_we := s.enc_block__enc_ctrl_we
    enc_block__muxed_sboxw := s.enc_block__muxed_sboxw
    enc_block__ready_new := s.enc_block__ready_new
    enc_block__ready_we := s.enc_block__ready_we
    enc_block__round_ctr_inc := s.enc_block__round_ctr_inc
    enc_block__round_ctr_new := s.enc_block__round_ctr_new
    enc_block__round_ctr_rst := s.enc_block__round_ctr_rst
    enc_block__round_ctr_we := s.enc_block__round_ctr_we
    enc_block__sword_ctr_inc := s.enc_block__sword_ctr_inc
    enc_block__sword_ctr_new := s.enc_block__sword_ctr_new
    enc_block__sword_ctr_rst := s.enc_block__sword_ctr_rst
    enc_block__sword_ctr_we := s.enc_block__sword_ctr_we
    enc_block__update_type := s.enc_block__update_type
    enc_next := s.enc_next
    init_state := s.init_state
    keymem__key_mem_ctrl_new := s.keymem__key_mem_ctrl_new
    keymem__key_mem_ctrl_we := s.keymem__key_mem_ctrl_we
    keymem__key_mem_new := s.keymem__key_mem_new
    keymem__key_mem_we := s.keymem__key_mem_we
    keymem__prev_key0_new := s.keymem__prev_key0_new
    keymem__prev_key0_we := s.keymem__prev_key0_we
    keymem__prev_key1_new := s.keymem__prev_key1_new
    keymem__prev_key1_we := s.keymem__prev_key1_we
    keymem__rcon_new := s.keymem__rcon_new
    keymem__rcon_next := s.keymem__rcon_next
    keymem__rcon_set := s.keymem__rcon_set
    keymem__rcon_we := s.keymem__rcon_we
    keymem__ready_new := s.keymem__ready_new
    keymem__ready_we := s.keymem__ready_we
    keymem__round_ctr_inc := s.keymem__round_ctr_inc
    keymem__round_ctr_new := s.keymem__round_ctr_new
    keymem__round_ctr_rst := s.keymem__round_ctr_rst
    keymem__round_ctr_we := s.keymem__round_ctr_we
    keymem__round_key_update := s.keymem__round_key_update
    keymem__tmp_round_key := s.keymem__tmp_round_key
    keymem__tmp_sboxw := s.keymem__tmp_sboxw
    muxed_new_block := s.muxed_new_block
    muxed_ready := s.muxed_ready
    muxed_round_nr := s.muxed_round_nr
    muxed_sboxw := s.muxed_sboxw
    ready_new := s.ready_new
    ready_we := s.ready_we
    result_valid_new := s.result_valid_new
    result_valid_we := s.result_valid_we
  }
  result

/-- step: pre-comb → parallel next-state commit → post-comb settle -/
def step (s : aes_coreState) (i : aes_coreInputs) : aes_coreState :=
  let s_pre := comb s i
  let s_next := commit s_pre i
  let s_settled := comb s_next i
  s_settled

/-- Output helper -/
def outputs (s : aes_coreState) : aes_coreOutputs :=
  {
    ready := s.ready
    result := s.result
    result_valid := s.result_valid
  }


end aes_core
