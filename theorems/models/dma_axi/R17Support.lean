import R16Support

set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace dma_axi32_core0_chVerification
open dma_axi32_core0_ch

def R17Pair12 (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs) : Prop :=
  r16Pred01 s i ∧ r16Pred02 s i

def R17Pair23 (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs) : Prop :=
  r16Pred02 s i ∧ r16Pred03 s i

def R17Pair34 (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs) : Prop :=
  r16Pred03 s i ∧ r16Pred04 s i

def R17Pair14 (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs) : Prop :=
  r16Pred01 s i ∧ r16Pred04 s i

def R17All (s : dma_axi32_core0_chState) (i : dma_axi32_core0_chInputs) : Prop :=
  R17Pair12 s i ∧ R17Pair34 s i

end dma_axi32_core0_chVerification
