import Framework

set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace zipcoreVerification
open zipcore

def R16Run (trans : zipcoreState → zipcoreInputs → zipcoreState) (s : zipcoreState) (xs : List zipcoreInputs) : zipcoreState := xs.foldl trans s

def R16Always (trans : zipcoreState → zipcoreInputs → zipcoreState) (P : zipcoreState → zipcoreInputs → Prop) : zipcoreState → List zipcoreInputs → Prop
  | _, [] => True
  | s, i :: xs => P s i ∧ R16Always trans P (trans s i) xs

def R16Eventually (trans : zipcoreState → zipcoreInputs → zipcoreState) (P : zipcoreState → zipcoreInputs → Prop) : zipcoreState → List zipcoreInputs → Prop
  | _, [] => False
  | s, i :: xs => P s i ∨ R16Eventually trans P (trans s i) xs

def R16Until (trans : zipcoreState → zipcoreInputs → zipcoreState) (P Q : zipcoreState → zipcoreInputs → Prop) : zipcoreState → List zipcoreInputs → Prop
  | _, [] => False
  | s, i :: xs => Q s i ∨ (P s i ∧ R16Until trans P Q (trans s i) xs)

def R16BoundedUntil (trans : zipcoreState → zipcoreInputs → zipcoreState) (P Q : zipcoreState → zipcoreInputs → Prop) : Nat → zipcoreState → List zipcoreInputs → Prop
  | 0, _, _ => False
  | _ + 1, _, [] => False
  | n + 1, s, i :: xs => Q s i ∨ (P s i ∧ R16BoundedUntil trans P Q n (trans s i) xs)

def R16Next (trans : zipcoreState → zipcoreInputs → zipcoreState) (P : zipcoreState → zipcoreInputs → Prop) (s : zipcoreState) (i : zipcoreInputs) : Prop := P s i

def R16Reachable (trans : zipcoreState → zipcoreInputs → zipcoreState) (s t : zipcoreState) : Prop := ∃ xs, R16Run trans s xs = t

def r16Pred01 (s : zipcoreState) (i : zipcoreInputs) : Prop :=
  (assign_clear_pipeline s i).clear_pipeline = s.new_pc

def r16Pred02 (s : zipcoreState) (i : zipcoreInputs) : Prop :=
  (assign_clear_pipeline s i).BUSLOCK__r_bus_lock = s.BUSLOCK__r_bus_lock

def r16Pred03 (s : zipcoreState) (i : zipcoreInputs) : Prop :=
  (assign_div_ce s i).div_ce = ((s.op_valid_div && s.adf_ce_unconditional) && s.set_cond)

def r16Pred04 (s : zipcoreState) (i : zipcoreInputs) : Prop :=
  (assign_div_ce s i).BUSLOCK__r_bus_lock = s.BUSLOCK__r_bus_lock

end zipcoreVerification
