import Framework

set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace ethmacVerification
open ethmac

def R16Run (trans : ethmacState → ethmacInputs → ethmacState) (s : ethmacState) (xs : List ethmacInputs) : ethmacState := xs.foldl trans s

def R16Always (trans : ethmacState → ethmacInputs → ethmacState) (P : ethmacState → ethmacInputs → Prop) : ethmacState → List ethmacInputs → Prop
  | _, [] => True
  | s, i :: xs => P s i ∧ R16Always trans P (trans s i) xs

def R16Eventually (trans : ethmacState → ethmacInputs → ethmacState) (P : ethmacState → ethmacInputs → Prop) : ethmacState → List ethmacInputs → Prop
  | _, [] => False
  | s, i :: xs => P s i ∨ R16Eventually trans P (trans s i) xs

def R16Until (trans : ethmacState → ethmacInputs → ethmacState) (P Q : ethmacState → ethmacInputs → Prop) : ethmacState → List ethmacInputs → Prop
  | _, [] => False
  | s, i :: xs => Q s i ∨ (P s i ∧ R16Until trans P Q (trans s i) xs)

def R16BoundedUntil (trans : ethmacState → ethmacInputs → ethmacState) (P Q : ethmacState → ethmacInputs → Prop) : Nat → ethmacState → List ethmacInputs → Prop
  | 0, _, _ => False
  | _ + 1, _, [] => False
  | n + 1, s, i :: xs => Q s i ∨ (P s i ∧ R16BoundedUntil trans P Q n (trans s i) xs)

def R16Next (trans : ethmacState → ethmacInputs → ethmacState) (P : ethmacState → ethmacInputs → Prop) (s : ethmacState) (i : ethmacInputs) : Prop := P s i

def R16Reachable (trans : ethmacState → ethmacInputs → ethmacState) (s t : ethmacState) : Prop := ∃ xs, R16Run trans s xs = t

def r16Pred01 (s : ethmacState) (i : ethmacInputs) : Prop :=
  (assign_miim1__Clk s i).miim1__Clk = i.wb_clk_i

def r16Pred02 (s : ethmacState) (i : ethmacInputs) : Prop :=
  (assign_miim1__Clk s i).CarrierSense_Tx1 = s.CarrierSense_Tx1

def r16Pred03 (s : ethmacState) (i : ethmacInputs) : Prop :=
  (assign_miim1__Reset s i).miim1__Reset = i.wb_rst_i

def r16Pred04 (s : ethmacState) (i : ethmacInputs) : Prop :=
  (assign_miim1__Reset s i).CarrierSense_Tx1 = s.CarrierSense_Tx1

end ethmacVerification
