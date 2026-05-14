FUNCTION_BLOCK FB_Heating_Runtime_Explainability_Publisher
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
    VI_Runtime_Context : ST_Heating_Runtime_Context;
    VI_Runtime_Observation_Valid : BOOL;
    VI_Runtime_Observer_Fault : BOOL;
    VI_Runtime_Status_Code : UINT;
    VI_Runtime_Status_Text : STRING(128);
END_VAR
VAR_OUTPUT
    VO_Phase_Event : ST_Heating_Runtime_Phase_Event;
    VO_Anomaly : ST_Heating_Runtime_Anomaly;
    VO_Blackbox_Event : ST_Heating_Runtime_Blackbox_Event;
    VO_Adaptive_Intelligence : ST_Heating_Runtime_Adaptive_Intelligence;
    VO_Causality_Graph : ST_Heating_Runtime_Causality_Graph;
    VO_Integration_Bridge : ST_Heating_Runtime_Integration_Bridge;
    VO_Predictive_State : ST_Heating_Runtime_Predictive_State;
    VO_Execution_Timeline : ST_Heating_Runtime_Execution_Timeline;
    VO_Phase_Transition : ST_Heating_Runtime_Phase_Transition;
    VO_Publication_Valid : BOOL;
END_VAR
VAR
    L_Sequencing_Valid : BOOL;
    L_Ownership_Valid : BOOL;
    L_Synchronization_Valid : BOOL;
    L_Runtime_Degraded : BOOL;
    L_Status_Code : UINT;
END_VAR

L_Sequencing_Valid := VI_Runtime_Context.DHW_Before_Heating_Valid AND VI_Runtime_Context.State_Publication_Before_Diagnostics_Valid;
L_Ownership_Valid := VI_Runtime_Context.OpenTherm_Ownership_Valid AND VI_Runtime_Context.Cascade_Ownership_Valid AND VI_Runtime_Context.Safety_Isolation_Valid;
L_Synchronization_Valid := VI_Runtime_Context.Output_Projection_Last_Valid;
L_Runtime_Degraded := VI_Runtime_Observer_Fault OR NOT VI_Runtime_Observation_Valid;
L_Status_Code := VI_Runtime_Status_Code;

// Phase event
VO_Phase_Event.Phase := VI_Runtime_Context.Current_Phase;
VO_Phase_Event.Event_Active := VI_Enable;
VO_Phase_Event.Event_Completed := VI_Runtime_Observation_Valid;
VO_Phase_Event.Event_Failed := VI_Runtime_Observer_Fault;
VO_Phase_Event.Start_Time_MS := VI_System_Time_MS;
VO_Phase_Event.End_Time_MS := VI_System_Time_MS;
VO_Phase_Event.Duration_MS := 0;
VO_Phase_Event.Ordering_Valid := VI_Runtime_Context.DHW_Before_Heating_Valid;
VO_Phase_Event.Isolation_Valid := VI_Runtime_Context.Diagnostics_Isolation_Valid;
VO_Phase_Event.Status_Code := L_Status_Code;
VO_Phase_Event.Status_Text := VI_Runtime_Status_Text;
VO_Phase_Event.Diagnostics_Visible := TRUE;
VO_Phase_Event.Explainability_Visible := TRUE;
VO_Phase_Event.Safety_Integrity_Valid := VI_Runtime_Context.Safety_Isolation_Valid;
VO_Phase_Event.OpenTherm_Ownership_Valid := VI_Runtime_Context.OpenTherm_Ownership_Valid;
VO_Phase_Event.Cascade_Ownership_Valid := VI_Runtime_Context.Cascade_Ownership_Valid;

// Phase transition snapshot
VO_Phase_Transition.Previous_Phase := VI_Runtime_Context.Current_Phase;
VO_Phase_Transition.Current_Phase := VI_Runtime_Context.Current_Phase;
VO_Phase_Transition.Next_Phase := VI_Runtime_Context.Current_Phase;
VO_Phase_Transition.Transition_Active := VI_Enable;
VO_Phase_Transition.Transition_Completed := VI_Runtime_Observation_Valid;
VO_Phase_Transition.Transition_Failed := VI_Runtime_Observer_Fault;
VO_Phase_Transition.Transition_Start_MS := VI_System_Time_MS;
VO_Phase_Transition.Transition_End_MS := VI_System_Time_MS;
VO_Phase_Transition.Transition_Duration_MS := 0;
VO_Phase_Transition.Sequencing_Valid := L_Sequencing_Valid;
VO_Phase_Transition.Ownership_Valid := L_Ownership_Valid;
VO_Phase_Transition.Synchronization_Valid := L_Synchronization_Valid;
VO_Phase_Transition.Status_Code := L_Status_Code;
VO_Phase_Transition.Status_Text := VI_Runtime_Status_Text;

// Anomaly
VO_Anomaly.Anomaly_Active := VI_Runtime_Observer_Fault;
VO_Anomaly.Anomaly_Acknowledged := FALSE;
VO_Anomaly.Anomaly_Cleared := NOT VI_Runtime_Observer_Fault;
VO_Anomaly.Runtime_Jitter_Detected := FALSE;
VO_Anomaly.Runtime_Latency_Detected := FALSE;
VO_Anomaly.Runtime_Degraded := L_Runtime_Degraded;
VO_Anomaly.Cascade_Degraded := NOT VI_Runtime_Context.Cascade_Ownership_Valid;
VO_Anomaly.Cascade_Boiler_Loss_Detected := FALSE;
VO_Anomaly.OpenTherm_Transport_Degraded := NOT VI_Runtime_Context.OpenTherm_Ownership_Valid;
VO_Anomaly.OpenTherm_Command_Invalid := FALSE;
VO_Anomaly.Diagnostics_Degraded := NOT VI_Runtime_Context.Diagnostics_Isolation_Valid;
VO_Anomaly.Explainability_Degraded := NOT VI_Runtime_Context.Explainability_Isolation_Valid;
VO_Anomaly.Sequencing_Invalid := NOT L_Sequencing_Valid;
VO_Anomaly.Ownership_Invalid := NOT L_Ownership_Valid;
VO_Anomaly.Synchronization_Invalid := NOT L_Synchronization_Valid;
VO_Anomaly.Severity_Level := SEL(VI_Runtime_Observer_Fault, 1, 900);
VO_Anomaly.Critical_Anomaly := VI_Runtime_Observer_Fault;
VO_Anomaly.Status_Code := L_Status_Code;
VO_Anomaly.Status_Text := VI_Runtime_Status_Text;

// Blackbox event
VO_Blackbox_Event.Event_ID := VI_System_Time_MS;
VO_Blackbox_Event.Event_Active := VI_Enable;
VO_Blackbox_Event.Runtime_Phase := VI_Runtime_Context.Current_Phase;
VO_Blackbox_Event.Event_Start_MS := VI_System_Time_MS;
VO_Blackbox_Event.Event_End_MS := VI_System_Time_MS;
VO_Blackbox_Event.Event_Duration_MS := 0;
VO_Blackbox_Event.Runtime_Degraded := L_Runtime_Degraded;
VO_Blackbox_Event.Runtime_Fault := VI_Runtime_Observer_Fault;
VO_Blackbox_Event.Cascade_Degraded := NOT VI_Runtime_Context.Cascade_Ownership_Valid;
VO_Blackbox_Event.Cascade_Boiler_Loss := FALSE;
VO_Blackbox_Event.OpenTherm_Degraded := NOT VI_Runtime_Context.OpenTherm_Ownership_Valid;
VO_Blackbox_Event.OpenTherm_Command_Invalid := FALSE;
VO_Blackbox_Event.Sequencing_Invalid := NOT L_Sequencing_Valid;
VO_Blackbox_Event.Ownership_Invalid := NOT L_Ownership_Valid;
VO_Blackbox_Event.Synchronization_Invalid := NOT L_Synchronization_Valid;
VO_Blackbox_Event.Root_Cause_Candidate := VI_Runtime_Observer_Fault;
VO_Blackbox_Event.Critical_Path := VI_Runtime_Observer_Fault;
VO_Blackbox_Event.Status_Code := L_Status_Code;
VO_Blackbox_Event.Status_Text := VI_Runtime_Status_Text;

// Passive integration bridge
VO_Integration_Bridge.Shell_Ready := VI_Runtime_Observation_Valid;
VO_Integration_Bridge.Shell_Fault := VI_Runtime_Observer_Fault;
VO_Integration_Bridge.Shell_Contract_Valid := VI_Enable AND VI_Runtime_Observation_Valid;
VO_Integration_Bridge.Allow_DHW_Integration := VI_Runtime_Context.Allow_DHW_Phase;
VO_Integration_Bridge.Allow_Heating_Integration := VI_Runtime_Context.Allow_Heating_Phase;
VO_Integration_Bridge.Allow_Diagnostics_Integration := VI_Runtime_Context.Allow_Diagnostics_Phase;
VO_Integration_Bridge.Allow_Output_Projection_Integration := VI_Runtime_Context.Allow_Output_Projection_Phase;
VO_Integration_Bridge.Runtime_Ownership_Valid := TRUE;
VO_Integration_Bridge.Diagnostics_Ownership_Valid := VI_Runtime_Context.Diagnostics_Isolation_Valid;
VO_Integration_Bridge.Explainability_Ownership_Valid := VI_Runtime_Context.Explainability_Isolation_Valid;
VO_Integration_Bridge.OpenTherm_Ownership_Valid := VI_Runtime_Context.OpenTherm_Ownership_Valid;
VO_Integration_Bridge.Cascade_Ownership_Valid := VI_Runtime_Context.Cascade_Ownership_Valid;
VO_Integration_Bridge.Safety_Ownership_Valid := VI_Runtime_Context.Safety_Isolation_Valid;
VO_Integration_Bridge.DHW_Before_Heating_Valid := VI_Runtime_Context.DHW_Before_Heating_Valid;
VO_Integration_Bridge.Diagnostics_After_Publication_Valid := VI_Runtime_Context.State_Publication_Before_Diagnostics_Valid;
VO_Integration_Bridge.Output_Projection_Last_Valid := VI_Runtime_Context.Output_Projection_Last_Valid;
VO_Integration_Bridge.Governance_Locked := TRUE;
VO_Integration_Bridge.Runtime_Attachment_Allowed := FALSE;
VO_Integration_Bridge.Runtime_Attachment_Active := FALSE;
VO_Integration_Bridge.Integration_Status_Code := L_Status_Code;
VO_Integration_Bridge.Integration_Status_Text := VI_Runtime_Status_Text;
VO_Integration_Bridge.Diagnostics_Visible := TRUE;
VO_Integration_Bridge.Explainability_Visible := TRUE;
VO_Integration_Bridge.Current_Phase := VI_Runtime_Context.Current_Phase;
VO_Integration_Bridge.Runtime_Synchronized := L_Synchronization_Valid;

// Predictive state (passive only)
VO_Predictive_State.Predictive_Analytics_Visible := TRUE;
VO_Predictive_State.Predictive_Analytics_Degraded := L_Runtime_Degraded;
VO_Predictive_State.Predictive_Analytics_Attention := NOT VI_Runtime_Observation_Valid;
VO_Predictive_State.Runtime_Stable := NOT L_Runtime_Degraded;
VO_Predictive_State.Runtime_Stability_Score := SEL(L_Runtime_Degraded, 100, 900);
VO_Predictive_State.Runtime_Degradation_Observation := SEL(L_Runtime_Degraded, 0, 900);
VO_Predictive_State.Runtime_Failure_Observation := SEL(VI_Runtime_Observer_Fault, 0, 900);
VO_Predictive_State.Cascade_Degradation_Observation := SEL(VI_Runtime_Context.Cascade_Ownership_Valid, 900, 0);
VO_Predictive_State.Cascade_Degraded_Trend_Visible := TRUE;
VO_Predictive_State.OpenTherm_Instability_Observation := SEL(VI_Runtime_Context.OpenTherm_Ownership_Valid, 900, 0);
VO_Predictive_State.OpenTherm_Degraded_Trend_Visible := TRUE;
VO_Predictive_State.Sequencing_Observation := SEL(L_Sequencing_Valid, 900, 0);
VO_Predictive_State.Ownership_Observation := SEL(L_Ownership_Valid, 900, 0);
VO_Predictive_State.Synchronization_Observation := SEL(L_Synchronization_Valid, 900, 0);
VO_Predictive_State.Status_Code := L_Status_Code;
VO_Predictive_State.Status_Text := VI_Runtime_Status_Text;

// Execution timeline snapshot
VO_Execution_Timeline.Write_Index := 1;
VO_Execution_Timeline.Frame_Count := 1;
VO_Execution_Timeline.Timeline_Overflow := FALSE;
VO_Execution_Timeline.Sequencing_Valid := L_Sequencing_Valid;
VO_Execution_Timeline.Ownership_Valid := L_Ownership_Valid;
VO_Execution_Timeline.Synchronization_Valid := L_Synchronization_Valid;
VO_Execution_Timeline.Runtime_Jitter_Detected := FALSE;
VO_Execution_Timeline.Runtime_Latency_Detected := FALSE;
VO_Execution_Timeline.Runtime_Degraded := L_Runtime_Degraded;
VO_Execution_Timeline.Frames[1].Phase := VI_Runtime_Context.Current_Phase;
VO_Execution_Timeline.Frames[1].Frame_Started := VI_Enable;
VO_Execution_Timeline.Frames[1].Frame_Completed := VI_Runtime_Observation_Valid;
VO_Execution_Timeline.Frames[1].Frame_Failed := VI_Runtime_Observer_Fault;
VO_Execution_Timeline.Frames[1].Frame_Start_MS := VI_System_Time_MS;
VO_Execution_Timeline.Frames[1].Frame_End_MS := VI_System_Time_MS;
VO_Execution_Timeline.Frames[1].Frame_Duration_MS := 0;
VO_Execution_Timeline.Frames[1].Sequencing_Valid := L_Sequencing_Valid;
VO_Execution_Timeline.Frames[1].Ownership_Valid := L_Ownership_Valid;
VO_Execution_Timeline.Frames[1].Synchronization_Valid := L_Synchronization_Valid;
VO_Execution_Timeline.Frames[1].Runtime_Jitter_Detected := FALSE;
VO_Execution_Timeline.Frames[1].Runtime_Latency_Detected := FALSE;
VO_Execution_Timeline.Frames[1].Runtime_Degraded := L_Runtime_Degraded;
VO_Execution_Timeline.Frames[1].Status_Code := L_Status_Code;
VO_Execution_Timeline.Frames[1].Status_Text := VI_Runtime_Status_Text;
VO_Execution_Timeline.Status_Code := L_Status_Code;
VO_Execution_Timeline.Status_Text := VI_Runtime_Status_Text;

// Adaptive intelligence (passive only)
VO_Adaptive_Intelligence.Adaptive_Analytics_Visible := TRUE;
VO_Adaptive_Intelligence.Adaptive_Analytics_Degraded := L_Runtime_Degraded;
VO_Adaptive_Intelligence.Adaptive_Analytics_Attention := NOT VI_Runtime_Observation_Valid;
VO_Adaptive_Intelligence.Supervision_Confidence_Observation := SEL(L_Runtime_Degraded, 100, 900);
VO_Adaptive_Intelligence.Confidence_Degradation_Visible := L_Runtime_Degraded;
VO_Adaptive_Intelligence.Adaptive_Runtime_Observation := 1;
VO_Adaptive_Intelligence.Adaptive_Runtime_Stability_Observation := SEL(L_Runtime_Degraded, 100, 900);
VO_Adaptive_Intelligence.Runtime_Anomaly_Observation_Weight := 1;
VO_Adaptive_Intelligence.Cascade_Anomaly_Observation_Weight := 1;
VO_Adaptive_Intelligence.OpenTherm_Anomaly_Observation_Weight := 1;
VO_Adaptive_Intelligence.Diagnostics_Anomaly_Observation_Weight := 1;
VO_Adaptive_Intelligence.Predictive_Correlation_Observation := 1;
VO_Adaptive_Intelligence.Predictive_Correlation_Visible := TRUE;
VO_Adaptive_Intelligence.Sequencing_Confidence_Observation := SEL(L_Sequencing_Valid, 100, 900);
VO_Adaptive_Intelligence.Ownership_Confidence_Observation := SEL(L_Ownership_Valid, 100, 900);
VO_Adaptive_Intelligence.Synchronization_Confidence_Observation := SEL(L_Synchronization_Valid, 100, 900);
VO_Adaptive_Intelligence.Status_Code := L_Status_Code;
VO_Adaptive_Intelligence.Status_Text := VI_Runtime_Status_Text;

// Minimal causality graph snapshot
VO_Causality_Graph.Node_Count := 1;
VO_Causality_Graph.Edge_Count := 1;
VO_Causality_Graph.Graph_Active := TRUE;
VO_Causality_Graph.Graph_Degraded := L_Runtime_Degraded;
VO_Causality_Graph.Graph_Critical := VI_Runtime_Observer_Fault;
VO_Causality_Graph.Sequencing_Valid := L_Sequencing_Valid;
VO_Causality_Graph.Ownership_Valid := L_Ownership_Valid;
VO_Causality_Graph.Synchronization_Valid := L_Synchronization_Valid;
VO_Causality_Graph.Nodes[1].Node_ID := 1;
VO_Causality_Graph.Nodes[1].Node_Active := TRUE;
VO_Causality_Graph.Nodes[1].Runtime_Degraded := L_Runtime_Degraded;
VO_Causality_Graph.Nodes[1].Runtime_Fault := VI_Runtime_Observer_Fault;
VO_Causality_Graph.Nodes[1].Cascade_Degraded := NOT VI_Runtime_Context.Cascade_Ownership_Valid;
VO_Causality_Graph.Nodes[1].OpenTherm_Degraded := NOT VI_Runtime_Context.OpenTherm_Ownership_Valid;
VO_Causality_Graph.Nodes[1].Diagnostics_Degraded := NOT VI_Runtime_Context.Diagnostics_Isolation_Valid;
VO_Causality_Graph.Nodes[1].Explainability_Degraded := NOT VI_Runtime_Context.Explainability_Isolation_Valid;
VO_Causality_Graph.Nodes[1].Sequencing_Invalid := NOT L_Sequencing_Valid;
VO_Causality_Graph.Nodes[1].Ownership_Invalid := NOT L_Ownership_Valid;
VO_Causality_Graph.Nodes[1].Synchronization_Invalid := NOT L_Synchronization_Valid;
VO_Causality_Graph.Nodes[1].Severity_Level := SEL(VI_Runtime_Observer_Fault, 1, 900);
VO_Causality_Graph.Nodes[1].Root_Cause_Candidate := VI_Runtime_Observer_Fault;
VO_Causality_Graph.Nodes[1].Status_Code := L_Status_Code;
VO_Causality_Graph.Nodes[1].Status_Text := VI_Runtime_Status_Text;
VO_Causality_Graph.Edges[1].Source_Node_ID := 1;
VO_Causality_Graph.Edges[1].Target_Node_ID := 1;
VO_Causality_Graph.Edges[1].Edge_Active := TRUE;
VO_Causality_Graph.Edges[1].Propagation_Detected := L_Runtime_Degraded;
VO_Causality_Graph.Edges[1].Runtime_Propagation := L_Runtime_Degraded;
VO_Causality_Graph.Edges[1].Cascade_Propagation := NOT VI_Runtime_Context.Cascade_Ownership_Valid;
VO_Causality_Graph.Edges[1].OpenTherm_Propagation := NOT VI_Runtime_Context.OpenTherm_Ownership_Valid;
VO_Causality_Graph.Edges[1].Diagnostics_Propagation := NOT VI_Runtime_Context.Diagnostics_Isolation_Valid;
VO_Causality_Graph.Edges[1].Sequencing_Propagation := NOT L_Sequencing_Valid;
VO_Causality_Graph.Edges[1].Ownership_Propagation := NOT L_Ownership_Valid;
VO_Causality_Graph.Edges[1].Synchronization_Propagation := NOT L_Synchronization_Valid;
VO_Causality_Graph.Status_Code := L_Status_Code;
VO_Causality_Graph.Status_Text := VI_Runtime_Status_Text;

VO_Publication_Valid := VI_Enable;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Explainability_Publisher <<<
