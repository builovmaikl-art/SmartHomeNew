PROGRAM PRG_Main_Phase_07_Semantic_Governance
// MAIN PHASE 12B — semantic, forensic, recovery, energy and governance integrity.
// Critical: mixed. Safety/authority/physical reality checks run every scan.
// Non-critical semantic, forensic and analytics fabrics are shed in reduced modes.
VAR
    L_Run_Full_Semantic : BOOL;
    L_Run_Extended_Observability : BOOL;
    L_Run_Analytics : BOOL;
END_VAR

GVL_MAIN_PHASE_FEEDBACK.G_Current_Phase := 7;

L_Run_Full_Semantic :=
    GVL_FABRIC_LIFECYCLE_REGISTRY.Runtime_Adaptive_Mode = FULL_SEMANTIC_MODE;

L_Run_Extended_Observability :=
    (GVL_FABRIC_LIFECYCLE_REGISTRY.Runtime_Adaptive_Mode = FULL_SEMANTIC_MODE)
    AND NOT GVL_FABRIC_LIFECYCLE_REGISTRY.Extended_Observability_Shedding_Recommended;

L_Run_Analytics :=
    (GVL_FABRIC_LIFECYCLE_REGISTRY.Runtime_Adaptive_Mode = FULL_SEMANTIC_MODE)
    AND NOT GVL_FABRIC_LIFECYCLE_REGISTRY.NonEssential_Analytics_Shedding_Recommended;

GVL_MAIN_PHASE_FEEDBACK.G_Phase_07_Full_Semantic_Requested := L_Run_Full_Semantic;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_07_Full_Semantic_Executed := FALSE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_07_Full_Semantic_Skipped_By_Design := NOT L_Run_Full_Semantic;

GVL_MAIN_PHASE_FEEDBACK.G_Phase_07_Extended_Observability_Requested := L_Run_Extended_Observability;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_07_Extended_Observability_Executed := FALSE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_07_Extended_Observability_Skipped_By_Design := NOT L_Run_Extended_Observability;

GVL_MAIN_PHASE_FEEDBACK.G_Phase_07_Analytics_Requested := L_Run_Analytics;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_07_Analytics_Executed := FALSE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_07_Analytics_Skipped_By_Design := NOT L_Run_Analytics;

// Critical authority and physical-reality guards: never shed here.
PRG_Authority_Provenance_Governor();
PRG_Provenance_Continuity_Governor();
PRG_Trust_Epoch_Monotonicity_Governor();
PRG_Governance_Publication_Binding_Governor();
PRG_Physical_SafeState_Lattice_Governor();
PRG_CrossDomain_FailSafe_Closure_Governor();
PRG_Deterministic_Recovery_Path_Governor();
PRG_Recovery_Ordering_Integrity_Governor();
PRG_Recovery_Reactivation_Control_Governor();
PRG_Authority_Resurrection_Boundary_Governor();
PRG_Energy_Isolation_Causality_Governor();
PRG_Residual_Energy_State_Governor();
PRG_Power_Domain_Segmentation_Governor();
PRG_Energy_Resurrection_Boundary_Governor();
PRG_Physical_Deadlock_Resolution_Governor();
PRG_Execution_Progress_Causality_Governor();
PRG_Resource_Starvation_Boundary_Governor();
PRG_Distributed_Forward_Progress_Governor();
PRG_Safety_Observability_Truth_Governor();
PRG_Physical_Safety_Projection_Governor();
PRG_Distributed_Safety_Reality_Consensus_Governor();
PRG_Temporal_Causality_Closure_Governor();
PRG_Distributed_Epoch_Linearity_Governor();
PRG_Historical_Ordering_Integrity_Governor();
PRG_Causality_Reversal_Prevention_Governor();
PRG_Runtime_Transition_Validator();
PRG_Physical_Reality_Validation_Governor();
PRG_Survivability_Intelligence_Governor();
PRG_Runtime_Budget_Governor();
PRG_Controlled_Capability_Shedding_Governor();
PRG_Semantic_Execution_Control_Governor();
PRG_Industrial_Maintainability_Governor();
PRG_Observability_Authority_Governor();

// Full semantic fabrics: shed outside FULL_SEMANTIC_MODE.
IF L_Run_Full_Semantic THEN
    PRG_Semantic_Preservation_Governor();
    PRG_Operator_Semantic_Alignment_Governor();
    PRG_Semantic_Federation_Governor();
    PRG_Compliance_Federation_Governor();
    PRG_Epistemic_Integrity_Governor();
    PRG_Meta_Governance_Governor();
    PRG_Semantic_Epoch_Invariance_Governor();
    PRG_Governance_Observer_Consensus_Governor();
    PRG_Governance_Feedback_Integrity_Governor();
    PRG_Governance_Validator_Integrity_Governor();
    PRG_Governance_Liveness_Integrity_Governor();
    PRG_Runtime_Assumption_Integrity_Governor();
    GVL_MAIN_PHASE_FEEDBACK.G_Phase_07_Full_Semantic_Executed := TRUE;
END_IF;

// Extended observability and forensic fabrics: shed when observability budget is constrained.
IF L_Run_Extended_Observability THEN
    PRG_Forensic_Evidence_Governor();
    PRG_Unsafe_Transition_Forensics_Governor();
    PRG_Passive_Runtime_Verification_Governor();
    PRG_Semantic_Drift_Observability_Governor();
    PRG_Proof_Continuity_Audit_Governor();
    PRG_Causal_Narrative_Engine();
    GVL_MAIN_PHASE_FEEDBACK.G_Phase_07_Extended_Observability_Executed := TRUE;
END_IF;

// Non-essential analytics/intelligence fabrics: shed when analytics budget is constrained.
IF L_Run_Analytics THEN
    PRG_Execution_Projection_Integrity_Governor();
    PRG_Operational_Intelligence_Governor();
    PRG_Runtime_Compression_Governor();
    GVL_MAIN_PHASE_FEEDBACK.G_Phase_07_Analytics_Executed := TRUE;
END_IF;

GVL_MAIN_PHASE_FEEDBACK.G_Phase_07_Semantic_Governance_Executed := TRUE;
GVL_MAIN_PHASE_FEEDBACK.G_Phase_07_Semantic_Governance_Valid := TRUE;

IF L_Run_Full_Semantic AND L_Run_Extended_Observability AND L_Run_Analytics THEN
    GVL_MAIN_PHASE_FEEDBACK.G_Phase_07_Semantic_Governance_Status_Text := 'Semantic/governance phase executed';
ELSE
    GVL_MAIN_PHASE_FEEDBACK.G_Phase_07_Semantic_Governance_Status_Text := 'Semantic/governance phase executed with designed shedding';
END_IF;

GVL_MAIN_PHASE_FEEDBACK.G_Last_Update_MS := GVL_TIME_SERVICE.G_Now_MS;

// >>> BULK_SYNC_ANCHOR: PRG_Main_Phase_07_Semantic_Governance <<<
END_PROGRAM
