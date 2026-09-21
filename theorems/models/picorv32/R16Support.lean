import Framework

set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace picorv32Verification
open picorv32

def R16Run (trans : picorv32State → picorv32Inputs → picorv32State) (s : picorv32State) (xs : List picorv32Inputs) : picorv32State := xs.foldl trans s

def R16Always (trans : picorv32State → picorv32Inputs → picorv32State) (P : picorv32State → picorv32Inputs → Prop) : picorv32State → List picorv32Inputs → Prop
  | _, [] => True
  | s, i :: xs => P s i ∧ R16Always trans P (trans s i) xs

def R16Eventually (trans : picorv32State → picorv32Inputs → picorv32State) (P : picorv32State → picorv32Inputs → Prop) : picorv32State → List picorv32Inputs → Prop
  | _, [] => False
  | s, i :: xs => P s i ∨ R16Eventually trans P (trans s i) xs

def R16Until (trans : picorv32State → picorv32Inputs → picorv32State) (P Q : picorv32State → picorv32Inputs → Prop) : picorv32State → List picorv32Inputs → Prop
  | _, [] => False
  | s, i :: xs => Q s i ∨ (P s i ∧ R16Until trans P Q (trans s i) xs)

def R16BoundedUntil (trans : picorv32State → picorv32Inputs → picorv32State) (P Q : picorv32State → picorv32Inputs → Prop) : Nat → picorv32State → List picorv32Inputs → Prop
  | 0, _, _ => False
  | _ + 1, _, [] => False
  | n + 1, s, i :: xs => Q s i ∨ (P s i ∧ R16BoundedUntil trans P Q n (trans s i) xs)

def R16Next (trans : picorv32State → picorv32Inputs → picorv32State) (P : picorv32State → picorv32Inputs → Prop) (s : picorv32State) (i : picorv32Inputs) : Prop := P s i

def R16Reachable (trans : picorv32State → picorv32Inputs → picorv32State) (s t : picorv32State) : Prop := ∃ xs, R16Run trans s xs = t

def r16Pred01 (s : picorv32State) (i : picorv32Inputs) : Prop :=
  (assign_dbg_mem_valid s i).dbg_mem_valid = s.mem_valid

def r16Pred02 (s : picorv32State) (i : picorv32Inputs) : Prop :=
  (assign_dbg_mem_valid s i).alu_out_0_q = s.alu_out_0_q

def r16Pred03 (s : picorv32State) (i : picorv32Inputs) : Prop :=
  (assign_dbg_mem_instr s i).dbg_mem_instr = s.mem_instr

def r16Pred04 (s : picorv32State) (i : picorv32Inputs) : Prop :=
  (assign_dbg_mem_instr s i).alu_out_0_q = s.alu_out_0_q

end picorv32Verification
