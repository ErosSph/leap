import Model

set_option linter.unusedVariables false
set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace picorv32Verification
open picorv32

def run (s : picorv32State) (inputs : List picorv32Inputs) : picorv32State :=
  inputs.foldl step s

inductive Reachable : picorv32State → Prop where
  | init : Reachable init
  | next {s : picorv32State} : Reachable s → (i : picorv32Inputs) → Reachable (step s i)

def StateWidthInvariant (s : picorv32State) : Prop :=
  s.count_cycle.toNat < 2 ^ 64

end picorv32Verification
