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
    VO_Publication_Valid : BOOL;
END_VAR

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
VO_Phase_Event.Status_Code := VI_Runtime_Status_Code;
VO_Phase_Event.Status_Text := VI_Runtime_Status_Text;
VO_Phase_Event.Diagnostics_Visible := TRUE;
VO_Phase_Event.Explainability_Visible := TRUE;
VO_Phase_Event.Safety_Integrity_Valid := VI_Runtime_Context.Safety_Isolation_Valid;
VO_Phase_Event.OpenTherm_Ownership_Valid := VI_Runtime_Context.OpenTherm_Ownership_Valid;
VO_Phase_Event.Cascade_Ownership_Valid := VI_Runtime_Context.Cascade_Ownership_Valid;

// Anomaly
VO_Anomaly.Anomaly_Active := VI_Runtime_Observer_Fault;
VO_Anomaly.Anomaly_Acknowledged := FALSE;
VO_Anomaly.Anomaly_Cleared := NOT VI_Runtime_Observer_Fault;
VO_Anomaly.Runtime_Jitter_Detected := FALSE;
VO_Anomaly.Runtime_Latency_Detected := FALSE;
VO_Anomaly.Runtime_Degraded := VI_Runtime_Observer_Fault;
VO_Anomaly.Cascade_Degraded := FALSE;
VO_Anomaly.Cascade_Boiler_Loss_Detected := FALSE;
VO_Anomaly.OpenTherm_Transport_Degraded := FALSE;
VO_Anomaly.OpenTherm_Command_Invalid := FALSE;
VO_Anomaly.Diagnostics_Degraded := NOT VI_Runtime_Context.Diagnostics_Isolation_Valid;
VO_Anomaly.Explainability_Degraded := FALSE;
VO_Anomaly.Sequencing_Invalid := NOT VI_Runtime_Context.DHW_Before_Heating_Valid;
VO_Anomaly.Ownership_Invalid := NOT VI_Runtime_Context.OpenTherm_Ownership_Valid;
VO_Anomaly.Synchronization_Invalid := NOT VI_Runtime_Context.Output_Projection_Last_Valid;
VO_Anomaly.Severity_Level := SEL(VI_Runtime_Observer_Fault, 1, 900);
VO_Anomaly.Critical_Anomaly := VI_Runtime_Observer_Fault;
VO_Anomaly.Status_Code := VI_Runtime_Status_Code;
VO_Anomaly.Status_Text := VI_Runtime_Status_Text;

// Blackbox event
VO_Blackbox_Event.Event_ID := VI_System_Time_MS;
VO_Blackbox_Event.Event_Active := VI_Enable;
VO_Blackbox_Event.Runtime_Phase := VI_Runtime_Context.Current_Phase;
VO_Blackbox_Event.Event_Start_MS := VI_System_Time_MS;
VO_Blackbox_Event.Event_End_MS := VI_System_Time_MS;
VO_Blackbox_Event.Event_Duration_MS := 0;
VO_Blackbox_Event.Runtime_Degraded := VI_Runtime_Observer_Fault;
VO_Blackbox_Event.Runtime_Fault := VI_Runtime_Observer_Fault;
VO_Blackbox_Event.Cascade_Degraded := FALSE;
VO_Blackbox_Event.Cascade_Boiler_Loss := FALSE;
VO_Blackbox_Event.OpenTherm_Degraded := FALSE;
VO_Blackbox_Event.OpenTherm_Command_Invalid := FALSE;
VO_Blackbox_Event.Sequencing_Invalid := NOT VI_Runtime_Context.DHW_Before_Heating_Valid;
VO_Blackbox_Event.Ownership_Invalid := NOT VI_Runtime_Context.OpenTherm_Ownership_Valid;
VO_Blackbox_Event.Synchronization_Invalid := NOT VI_Runtime_Context.Output_Projection_Last_Valid;
VO_Blackbox_Event.Root_Cause_Candidate := VI_Runtime_Observer_Fault;
VO_Blackbox_Event.Critical_Path := VI_Runtime_Observer_Fault;
VO_Blackbox_Event.Status_Code := VI_Runtime_Status_Code;
VO_Blackbox_Event.Status_Text := VI_Runtime_Status_Text;

// Adaptive intelligence (passive only)
VO_Adaptive_Intelligence.Adaptive_Analytics_Visible := TRUE;
VO_Adaptive_Intelligence.Adaptive_Analytics_Degraded := VI_Runtime_Observer_Fault;
VO_Adaptive_Intelligence.Adaptive_Analytics_Attention := NOT VI_Runtime_Observation_Valid;
VO_Adaptive_Intelligence.Supervision_Confidence_Observation := SEL(VI_Runtime_Observer_Fault, 100, 900);
VO_Adaptive_Intelligence.Confidence_Degradation_Visible := VI_Runtime_Observer_Fault;
VO_Adaptive_Intelligence.Adaptive_Runtime_Observation := 1;
VO_Adaptive_Intelligence.Adaptive_Runtime_Stability_Observation := SEL(VI_Runtime_Observer_Fault, 100, 900);
VO_Adaptive_Intelligence.Runtime_Anomaly_Observation_Weight := 1;
VO_Adaptive_Intelligence.Cascade_Anomaly_Observation_Weight := 1;
VO_Adaptive_Intelligence.OpenTherm_Anomaly_Observation_Weight := 1;
VO_Adaptive_Intelligence.Diagnostics_Anomaly_Observation_Weight := 1;
VO_Adaptive_Intelligence.Predictive_Correlation_Observation := 1;
VO_Adaptive_Intelligence.Predictive_Correlation_Visible := TRUE;
VO_Adaptive_Intelligence.Sequencing_Confidence_Observation := SEL(VI_Runtime_Context.DHW_Before_Heating_Valid, 100, 900);
VO_Adaptive_Intelligence.Ownership_Confidence_Observation := SEL(VI_Runtime_Context.OpenTherm_Ownership_Valid, 100, 900);
VO_Adaptive_Intelligence.Synchronization_Confidence_Observation := SEL(VI_Runtime_Context.Output_Projection_Last_Valid, 100, 900);
VO_Adaptive_Intelligence.Status_Code := VI_Runtime_Status_Code;
VO_Adaptive_Intelligence.Status_Text := VI_Runtime_Status_Text;

// Minimal causality graph snapshot
VO_Causality_Graph.Node_Count := 1;
VO_Causality_Graph.Edge_Count := 0;
VO_Causality_Graph.Graph_Active := TRUE;
VO_Causality_Graph.Graph_Degraded := VI_Runtime_Observer_Fault;
VO_Causality_Graph.Graph_Critical := VI_Runtime_Observer_Fault;
VO_Causality_Graph.Sequencing_Valid := VI_Runtime_Context.DHW_Before_Heating_Valid;
VO_Causality_Graph.Ownership_Valid := VI_Runtime_Context.OpenTherm_Ownership_Valid;
VO_Causality_Graph.Synchronization_Valid := VI_Runtime_Context.Output_Projection_Last_Valid;
VO_Causality_Graph.Nodes[1].Node_ID := 1;
VO_Causality_Graph.Nodes[1].Node_Active := TRUE;
VO_Causality_Graph.Nodes[1].Runtime_Degraded := VI_Runtime_Observer_Fault;
VO_Causality_Graph.Nodes[1].Runtime_Fault := VI_Runtime_Observer_Fault;
VO_Causality_Graph.Nodes[1].Severity_Level := SEL(VI_Runtime_Observer_Fault, 1, 900);
VO_Causality_Graph.Nodes[1].Root_Cause_Candidate := VI_Runtime_Observer_Fault;
VO_Causality_Graph.Nodes[1].Status_Code := VI_Runtime_Status_Code;
VO_Causality_Graph.Nodes[1].Status_Text := VI_Runtime_Status_Text;
VO_Causality_Graph.Status_Code := VI_Runtime_Status_Code;
VO_Causality_Graph.Status_Text := VI_Runtime_Status_Text;

VO_Publication_Valid := VI_Enable;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Explainability_Publisher <<<
