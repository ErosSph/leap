import Model

set_option linter.unusedVariables false
set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace aes_coreVerification
open aes_core

def run (s : aes_coreState) (inputs : List aes_coreInputs) : aes_coreState :=
  inputs.foldl step s

inductive Reachable : aes_coreState → Prop where
  | init : Reachable init
  | next {s : aes_coreState} : Reachable s → (i : aes_coreInputs) → Reachable (step s i)

def StateWidthInvariant (s : aes_coreState) : Prop :=
  s.aes_core_ctrl_reg.toNat < 2 ^ 2

end aes_coreVerification
