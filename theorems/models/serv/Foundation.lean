import Model

set_option linter.unusedVariables false
set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace serv_rf_topVerification
open serv_rf_top

def run (s : serv_rf_topState) (inputs : List serv_rf_topInputs) : serv_rf_topState :=
  inputs.foldl step s

inductive Reachable : serv_rf_topState → Prop where
  | init : Reachable init
  | next {s : serv_rf_topState} : Reachable s → (i : serv_rf_topInputs) → Reachable (step s i)

def StateWidthInvariant (s : serv_rf_topState) : Prop :=
  s.cpu__ctrl__o_ibus_adr.toNat < 2 ^ 32

end serv_rf_topVerification
