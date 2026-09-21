import Model

set_option linter.unusedVariables false
set_option maxRecDepth 100000
set_option maxHeartbeats 8000000

namespace dma_axi32_core0_chVerification
open dma_axi32_core0_ch

abbrev EventInput := dma_axi32_core0_chInputs × ClockEvent
def run (s : dma_axi32_core0_chState) (events : List EventInput) : dma_axi32_core0_chState :=
  events.foldl (fun state item => step state item.1 item.2) s

inductive Reachable : dma_axi32_core0_chState → Prop where
  | init : Reachable init
  | next {s : dma_axi32_core0_chState} : Reachable s → (i : dma_axi32_core0_chInputs) →
      (event : ClockEvent) → Reachable (step s i event)

def StateWidthInvariant (s : dma_axi32_core0_chState) : Prop :=
  s.dma_axi32_ch_fifo_ctrl__dma_axi32_ch_fifo__DOUT.toNat < 2 ^ 32

end dma_axi32_core0_chVerification
