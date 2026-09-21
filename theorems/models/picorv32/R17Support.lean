import R16Support

set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace picorv32Verification
open picorv32

def R17Pair12 (s : picorv32State) (i : picorv32Inputs) : Prop :=
  r16Pred01 s i ∧ r16Pred02 s i

def R17Pair23 (s : picorv32State) (i : picorv32Inputs) : Prop :=
  r16Pred02 s i ∧ r16Pred03 s i

def R17Pair34 (s : picorv32State) (i : picorv32Inputs) : Prop :=
  r16Pred03 s i ∧ r16Pred04 s i

def R17Pair14 (s : picorv32State) (i : picorv32Inputs) : Prop :=
  r16Pred01 s i ∧ r16Pred04 s i

def R17All (s : picorv32State) (i : picorv32Inputs) : Prop :=
  R17Pair12 s i ∧ R17Pair34 s i

end picorv32Verification
