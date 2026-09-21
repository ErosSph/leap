import R16Support

set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace zipcoreVerification
open zipcore

def R17Pair12 (s : zipcoreState) (i : zipcoreInputs) : Prop :=
  r16Pred01 s i ∧ r16Pred02 s i

def R17Pair23 (s : zipcoreState) (i : zipcoreInputs) : Prop :=
  r16Pred02 s i ∧ r16Pred03 s i

def R17Pair34 (s : zipcoreState) (i : zipcoreInputs) : Prop :=
  r16Pred03 s i ∧ r16Pred04 s i

def R17Pair14 (s : zipcoreState) (i : zipcoreInputs) : Prop :=
  r16Pred01 s i ∧ r16Pred04 s i

def R17All (s : zipcoreState) (i : zipcoreInputs) : Prop :=
  R17Pair12 s i ∧ R17Pair34 s i

end zipcoreVerification
