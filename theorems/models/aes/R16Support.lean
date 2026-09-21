import Framework

set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace aes_coreVerification
open aes_core

def R16Run (trans : aes_coreState → aes_coreInputs → aes_coreState) (s : aes_coreState) (xs : List aes_coreInputs) : aes_coreState := xs.foldl trans s

def R16Always (trans : aes_coreState → aes_coreInputs → aes_coreState) (P : aes_coreState → aes_coreInputs → Prop) : aes_coreState → List aes_coreInputs → Prop
  | _, [] => True
  | s, i :: xs => P s i ∧ R16Always trans P (trans s i) xs

def R16Eventually (trans : aes_coreState → aes_coreInputs → aes_coreState) (P : aes_coreState → aes_coreInputs → Prop) : aes_coreState → List aes_coreInputs → Prop
  | _, [] => False
  | s, i :: xs => P s i ∨ R16Eventually trans P (trans s i) xs

def R16Until (trans : aes_coreState → aes_coreInputs → aes_coreState) (P Q : aes_coreState → aes_coreInputs → Prop) : aes_coreState → List aes_coreInputs → Prop
  | _, [] => False
  | s, i :: xs => Q s i ∨ (P s i ∧ R16Until trans P Q (trans s i) xs)

def R16BoundedUntil (trans : aes_coreState → aes_coreInputs → aes_coreState) (P Q : aes_coreState → aes_coreInputs → Prop) : Nat → aes_coreState → List aes_coreInputs → Prop
  | 0, _, _ => False
  | _ + 1, _, [] => False
  | n + 1, s, i :: xs => Q s i ∨ (P s i ∧ R16BoundedUntil trans P Q n (trans s i) xs)

def R16Next (trans : aes_coreState → aes_coreInputs → aes_coreState) (P : aes_coreState → aes_coreInputs → Prop) (s : aes_coreState) (i : aes_coreInputs) : Prop := P s i

def R16Reachable (trans : aes_coreState → aes_coreInputs → aes_coreState) (s t : aes_coreState) : Prop := ∃ xs, R16Run trans s xs = t

def r16Pred01 (s : aes_coreState) (i : aes_coreInputs) : Prop :=
  (assign_enc_block__clk s i).enc_block__clk = i.clk

def r16Pred02 (s : aes_coreState) (i : aes_coreInputs) : Prop :=
  (assign_enc_block__clk s i).aes_core_ctrl_reg = s.aes_core_ctrl_reg

def r16Pred03 (s : aes_coreState) (i : aes_coreInputs) : Prop :=
  (assign_enc_block__reset_n s i).enc_block__reset_n = i.reset_n

def r16Pred04 (s : aes_coreState) (i : aes_coreInputs) : Prop :=
  (assign_enc_block__reset_n s i).aes_core_ctrl_reg = s.aes_core_ctrl_reg

end aes_coreVerification
