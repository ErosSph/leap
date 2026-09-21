import Model

set_option linter.unusedVariables false
set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace ethmacVerification
open ethmac

abbrev EventInput := ethmacInputs × ClockEvent
def run (s : ethmacState) (events : List EventInput) : ethmacState :=
  events.foldl (fun state item => step state item.1 item.2) s

inductive Reachable : ethmacState → Prop where
  | init : Reachable init
  | next {s : ethmacState} : Reachable s → (i : ethmacInputs) →
      (event : ClockEvent) → Reachable (step s i event)

def StateWidthInvariant (s : ethmacState) : Prop :=
  s.ethreg1__CTRLMODER_0__DataOut.toNat < 2 ^ 3

end ethmacVerification
