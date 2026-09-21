import R16Support

set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace modexp_coreVerification
open modexp_core

def R17Pair12 (s : modexp_coreState) (i : modexp_coreInputs) : Prop :=
  r16Pred01 s i ∧ r16Pred02 s i

def R17Pair23 (s : modexp_coreState) (i : modexp_coreInputs) : Prop :=
  r16Pred02 s i ∧ r16Pred03 s i

def R17Pair34 (s : modexp_coreState) (i : modexp_coreInputs) : Prop :=
  r16Pred03 s i ∧ r16Pred04 s i

def R17Pair14 (s : modexp_coreState) (i : modexp_coreInputs) : Prop :=
  r16Pred01 s i ∧ r16Pred04 s i

def R17All (s : modexp_coreState) (i : modexp_coreInputs) : Prop :=
  R17Pair12 s i ∧ R17Pair34 s i

end modexp_coreVerification
