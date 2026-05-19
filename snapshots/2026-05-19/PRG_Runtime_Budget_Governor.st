PROGRAM PRG_Runtime_Budget_Governor
// RUNTIME BUDGET ENFORCEMENT
// READ-ONLY / NON-INVASIVE

GVL_RUNTIME_BUDGET_ENFORCEMENT.Runtime_Budget_Pressure_Observed :=
    GVL_CANONICAL_RUNTIME_FABRIC_REGISTRY.Runtime_Complexity_Pressure_Observed;

GVL_RUNTIME_BUDGET_ENFORCEMENT.Governance_Runtime_Overhead_Observed :=
    GVL_CANONICAL_RUNTIME_FABRIC_REGISTRY.Governance_Runtime_Cost_Observed;

GVL_RUNTIME_BUDGET_ENFORCEMENT.Verification_Runtime_Budget_Observed :=
    GVL_CANONICAL_RUNTIME_FABRIC_REGISTRY.Verification_Chaining_Limit_Reached;

GVL_RUNTIME_BUDGET_ENFORCEMENT.Observability_Runtime_Budget_Observed :=
    GVL_CANONICAL_RUNTIME_FABRIC_REGISTRY.Observability_Amplification_Limit_Reached;

IF GVL_RUNTIME_BUDGET_ENFORCEMENT.Runtime_Budget_Pressure_Observed THEN
    GVL_RUNTIME_BUDGET_ENFORCEMENT.Runtime_Stability_Budget_At_Risk := TRUE;
END_IF;

IF GVL_RUNTIME_BUDGET_ENFORCEMENT.Verification_Runtime_Budget_Observed THEN
    GVL_RUNTIME_BUDGET_ENFORCEMENT.Verification_Time_Budget_Exceeded := TRUE;
    GVL_RUNTIME_BUDGET_ENFORCEMENT.Verification_Induced_Runtime_Risk := TRUE;
END_IF;

IF GVL_RUNTIME_BUDGET_ENFORCEMENT.Observability_Runtime_Budget_Observed THEN
    GVL_RUNTIME_BUDGET_ENFORCEMENT.Observability_Amplification_Budget_Exceeded := TRUE;
END_IF;

END_PROGRAM