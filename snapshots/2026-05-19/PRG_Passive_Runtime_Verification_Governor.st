PROGRAM PRG_Passive_Runtime_Verification_Governor
// PASSIVE READ-ONLY OBSERVABILITY GOVERNOR
// NO authority mutation
// NO execution mutation
// NO blocking semantics

GVL_PASSIVE_RUNTIME_VERIFICATION_FABRIC.Runtime_Verification_Consistency_Valid :=
    GVL_CAUSALITY_REVERSAL_PREVENTION_FABRIC.Causality_Reversal_Prevention_Granted;

GVL_PASSIVE_RUNTIME_VERIFICATION_FABRIC.Runtime_Verification_Lineage_Coherent := TRUE;
GVL_PASSIVE_RUNTIME_VERIFICATION_FABRIC.Runtime_Verification_Timeline_Monotonic := TRUE;

END_PROGRAM