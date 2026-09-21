import Framework

set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace dma_axi32_core0_chVerification
open dma_axi32_core0_ch

def R16Run (trans : dma_axi32_core0_chState → dma_axi32_core0_chInputs → dma_axi32_core0_chState) (s : dma_axi32_core0_chState) (xs : List dma_axi32_core0_chInputs) : dma_axi32_core0_chState := xs.foldl trans s

def R16Always (trans : dma_axi32_core0_chState → dma_axi32_core0_chInputs → dma_axi32_core0_chState) (P : dma_axi32_core0_chState → dma_axi32_core0_chInputs → Prop) : dma_axi32_core0_chState → List dma_axi32_core0_chInputs → Prop
  | _, [] => True
  | s, i :: xs => P s i ∧ R16Always trans P (trans s i) xs

def R16Eventually (trans : dma_axi32_core0_chState → dma_axi32_core0_chInputs → dma_axi32_core0_chState) (P : dma_axi32_core0_chState → dma_axi32_core0_chInputs → Prop) : dma_axi32_core0_chState → List dma_axi32_core0_chInputs → Prop
  | _, [] => False
  | s, i :: xs => P s i ∨ R16Eventually trans P (trans s i) xs

def R16Until (trans : dma_axi32_core0_chState → dma_axi32_core0_chInputs → dma_axi32_core0_chState) (P Q : dma_axi32_core0_chState → dma_axi32_core0_chInputs → Prop) : dma_axi32_core0_chState → List dma_axi32_core0_chInputs → Prop
  | _, [] => False
  | s, i :: xs => Q s i ∨ (P s i ∧ R16Until trans P Q (trans s i) xs)

def R16BoundedUntil (trans : dma_axi32_core0_chState → dma_axi32_core0_chInputs → dma_axi32_core0_chState) (P Q : dma_axi32_core0_chState → dma_axi32_core0_chInputs → Prop) : Nat → dma_axi32_core0_chState → List dma_axi32_core0_chInputs → Prop
  | 0, _, _ => False
  | _ + 1, _, [] => False
  | n + 1, s, i :: xs => Q s i ∨ (P s i ∧ R16BoundedUntil trans P Q n (trans s i) xs)

def R16Next (trans : dma_axi32_core0_chState → dma_axi32_core0_chInputs → dma_axi32_core0_chState) (P : dma_axi32_core0_chState → dma_axi32_core0_chInputs → Prop) (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs) : Prop := P s i

def R16Reachable (trans : dma_axi32_core0_chState → dma_axi32_core0_chInputs → dma_axi32_core0_chState) (s t : dma_axi32_core0_chState) : Prop := ∃ xs, R16Run trans s xs = t

def r16Pred01 (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs) : Prop :=
  (assign_ch_active s i).ch_active = (s.ch_in_prog || s.load_in_prog)

def r16Pred02 (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs) : Prop :=
  (assign_ch_active s i).delay_idle__shift_reg = s.delay_idle__shift_reg

def r16Pred03 (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs) : Prop :=
  (assign_outs_empty s i).outs_empty = (s.rd_outs_empty && s.wr_outs_empty)

def r16Pred04 (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs) : Prop :=
  (assign_outs_empty s i).delay_idle__shift_reg = s.delay_idle__shift_reg

end dma_axi32_core0_chVerification
