import R16Support

set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace serv_rf_topVerification
open serv_rf_top

def R17Pair12 (s : serv_rf_topState) (i : serv_rf_topInputs) : Prop :=
  r16Pred01 s i ∧ r16Pred02 s i

def R17Pair23 (s : serv_rf_topState) (i : serv_rf_topInputs) : Prop :=
  r16Pred02 s i ∧ r16Pred03 s i

def R17Pair34 (s : serv_rf_topState) (i : serv_rf_topInputs) : Prop :=
  r16Pred03 s i ∧ r16Pred04 s i

def R17Pair14 (s : serv_rf_topState) (i : serv_rf_topInputs) : Prop :=
  r16Pred01 s i ∧ r16Pred04 s i

def R17All (s : serv_rf_topState) (i : serv_rf_topInputs) : Prop :=
  R17Pair12 s i ∧ R17Pair34 s i

end serv_rf_topVerification
