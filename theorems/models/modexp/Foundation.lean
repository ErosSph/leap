import Model

set_option linter.unusedVariables false
set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace modexp_coreVerification
open modexp_core

def run (s : modexp_coreState) (inputs : List modexp_coreInputs) : modexp_coreState :=
  inputs.foldl step s

inductive Reachable : modexp_coreState → Prop where
  | init : Reachable init
  | next {s : modexp_coreState} : Reachable s → (i : modexp_coreInputs) → Reachable (step s i)

def StateWidthInvariant (s : modexp_coreState) : Prop :=
  s.loop_counter_reg.toNat < 2 ^ 13

end modexp_coreVerification
