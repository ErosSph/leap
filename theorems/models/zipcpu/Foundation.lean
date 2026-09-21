import Model

set_option linter.unusedVariables false
set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace zipcoreVerification
open zipcore

def run (s : zipcoreState) (inputs : List zipcoreInputs) : zipcoreState :=
  inputs.foldl step s

inductive Reachable : zipcoreState → Prop where
  | init : Reachable init
  | next {s : zipcoreState} : Reachable s → (i : zipcoreInputs) → Reachable (step s i)

def StateWidthInvariant (s : zipcoreState) : Prop :=
  s.BUSLOCK__r_bus_lock.toNat < 2 ^ 2

end zipcoreVerification
