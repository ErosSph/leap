import Framework

set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace serv_rf_topVerification
open serv_rf_top

def R16Run (trans : serv_rf_topState → serv_rf_topInputs → serv_rf_topState) (s : serv_rf_topState) (xs : List serv_rf_topInputs) : serv_rf_topState := xs.foldl trans s

def R16Always (trans : serv_rf_topState → serv_rf_topInputs → serv_rf_topState) (P : serv_rf_topState → serv_rf_topInputs → Prop) : serv_rf_topState → List serv_rf_topInputs → Prop
  | _, [] => True
  | s, i :: xs => P s i ∧ R16Always trans P (trans s i) xs

def R16Eventually (trans : serv_rf_topState → serv_rf_topInputs → serv_rf_topState) (P : serv_rf_topState → serv_rf_topInputs → Prop) : serv_rf_topState → List serv_rf_topInputs → Prop
  | _, [] => False
  | s, i :: xs => P s i ∨ R16Eventually trans P (trans s i) xs

def R16Until (trans : serv_rf_topState → serv_rf_topInputs → serv_rf_topState) (P Q : serv_rf_topState → serv_rf_topInputs → Prop) : serv_rf_topState → List serv_rf_topInputs → Prop
  | _, [] => False
  | s, i :: xs => Q s i ∨ (P s i ∧ R16Until trans P Q (trans s i) xs)

def R16BoundedUntil (trans : serv_rf_topState → serv_rf_topInputs → serv_rf_topState) (P Q : serv_rf_topState → serv_rf_topInputs → Prop) : Nat → serv_rf_topState → List serv_rf_topInputs → Prop
  | 0, _, _ => False
  | _ + 1, _, [] => False
  | n + 1, s, i :: xs => Q s i ∨ (P s i ∧ R16BoundedUntil trans P Q n (trans s i) xs)

def R16Next (trans : serv_rf_topState → serv_rf_topInputs → serv_rf_topState) (P : serv_rf_topState → serv_rf_topInputs → Prop) (s : serv_rf_topState) (i : serv_rf_topInputs) : Prop := P s i

def R16Reachable (trans : serv_rf_topState → serv_rf_topInputs → serv_rf_topState) (s t : serv_rf_topState) : Prop := ∃ xs, R16Run trans s xs = t

def r16Pred01 (s : serv_rf_topState) (i : serv_rf_topInputs) : Prop :=
  (assign_rf_ram_if__i_clk s i).rf_ram_if__i_clk = i.clk

def r16Pred02 (s : serv_rf_topState) (i : serv_rf_topInputs) : Prop :=
  (assign_rf_ram_if__i_clk s i).cpu__alu__add_cy_r = s.cpu__alu__add_cy_r

def r16Pred03 (s : serv_rf_topState) (i : serv_rf_topInputs) : Prop :=
  (assign_rf_ram_if__i_rst s i).rf_ram_if__i_rst = i.i_rst

def r16Pred04 (s : serv_rf_topState) (i : serv_rf_topInputs) : Prop :=
  (assign_rf_ram_if__i_rst s i).cpu__alu__add_cy_r = s.cpu__alu__add_cy_r

end serv_rf_topVerification
