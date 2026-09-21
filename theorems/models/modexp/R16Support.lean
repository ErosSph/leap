import Framework

set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace modexp_coreVerification
open modexp_core

def R16Run (trans : modexp_coreState → modexp_coreInputs → modexp_coreState) (s : modexp_coreState) (xs : List modexp_coreInputs) : modexp_coreState := xs.foldl trans s

def R16Always (trans : modexp_coreState → modexp_coreInputs → modexp_coreState) (P : modexp_coreState → modexp_coreInputs → Prop) : modexp_coreState → List modexp_coreInputs → Prop
  | _, [] => True
  | s, i :: xs => P s i ∧ R16Always trans P (trans s i) xs

def R16Eventually (trans : modexp_coreState → modexp_coreInputs → modexp_coreState) (P : modexp_coreState → modexp_coreInputs → Prop) : modexp_coreState → List modexp_coreInputs → Prop
  | _, [] => False
  | s, i :: xs => P s i ∨ R16Eventually trans P (trans s i) xs

def R16Until (trans : modexp_coreState → modexp_coreInputs → modexp_coreState) (P Q : modexp_coreState → modexp_coreInputs → Prop) : modexp_coreState → List modexp_coreInputs → Prop
  | _, [] => False
  | s, i :: xs => Q s i ∨ (P s i ∧ R16Until trans P Q (trans s i) xs)

def R16BoundedUntil (trans : modexp_coreState → modexp_coreInputs → modexp_coreState) (P Q : modexp_coreState → modexp_coreInputs → Prop) : Nat → modexp_coreState → List modexp_coreInputs → Prop
  | 0, _, _ => False
  | _ + 1, _, [] => False
  | n + 1, s, i :: xs => Q s i ∨ (P s i ∧ R16BoundedUntil trans P Q n (trans s i) xs)

def R16Next (trans : modexp_coreState → modexp_coreInputs → modexp_coreState) (P : modexp_coreState → modexp_coreInputs → Prop) (s : modexp_coreState) (i : modexp_coreInputs) : Prop := P s i

def R16Reachable (trans : modexp_coreState → modexp_coreInputs → modexp_coreState) (s t : modexp_coreState) : Prop := ∃ xs, R16Run trans s xs = t

def r16Pred01 (s : modexp_coreState) (i : modexp_coreInputs) : Prop :=
  (assign_ready s i).ready = s.ready_reg

def r16Pred02 (s : modexp_coreState) (i : modexp_coreInputs) : Prop :=
  (assign_ready s i).b_one_reg = s.b_one_reg

def r16Pred03 (s : modexp_coreState) (i : modexp_coreInputs) : Prop :=
  (assign_cycles s i).cycles = BitVec.append (n := 32) (m := 32) (s.cycle_ctr_high_reg) (s.cycle_ctr_low_reg)

def r16Pred04 (s : modexp_coreState) (i : modexp_coreInputs) : Prop :=
  (assign_cycles s i).b_one_reg = s.b_one_reg

end modexp_coreVerification
