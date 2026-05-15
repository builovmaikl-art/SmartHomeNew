PROGRAM PRG_Heating
VAR
    fbHeatingManager : FB_Heating_System_Manager;
    fbDHWManager : FB_DHW_Manager;
    fbDiagnosticsPhase : FB_Heating_Runtime_Diagnostics_Phase;
    fbObserverPhase : FB_Heating_Runtime_Observer_Phase;
    fbMetaSupervisionPublisher : FB_Heating_Runtime_Meta_Supervision_Publisher;
    fbExplainabilityPublisher : FB_Heating_Runtime_Explainability_Publisher;
    fbServiceGatingPhase : FB_Heating_Runtime_Service_Gating_Phase;
    fbStatePublicationPhase : FB_Heating_Runtime_State_Publication_Phase;
    fbOutputProjectionPhase : FB_Heating_Runtime_Output_Projection_Phase;

    L_Runtime_Context : ST_Heating_Runtime_Context;

    L_i : INT;
    L_Current_Hour : UINT;
    L_Boiler_Modulation_REAL : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF REAL;
    L_Room_Temps_Normalized : ARRAY[1..GVL_CONSTANTS.C_MAX_ZONES] OF REAL;
    L_Floor_Temps_Normalized : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF REAL;
    L_Outdoor_Temp_Normalized : REAL;

    L_Heating_Emergency_Stop : BOOL;
    L_Heating_Gas_Safety_Stop : BOOL;

    L_Zone_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF BOOL;
    L_Manifold_Pumps : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    L_Manifold_Valves : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF REAL;
    L_Boiler_OT_Enable : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF BOOL;
    L_Boiler_OT_Setpoint : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF REAL;
    L_Backup_Circulation_Pump : BOOL;
    L_Electric_Heater_Enable : BOOL;
    L_Freeze_Risk_Status : BOOL;
    L_Manifold_Status : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF ST_Manifold_Status;
    L_Boiler_Status : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF ST_Boiler_Status;
    L_DHW_Heating_Pump : BOOL;
    L_DHW_Circ_Pump : BOOL;
    L_DHW_Status : ST_DHW_Status;
END_VAR

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    L_Boiler_Modulation_REAL[L_i] := TO_REAL(GVL_IO.AI_Boiler_Modulation[L_i]);
END_FOR;

L_Current_Hour := TO_UINT(GVL_TIME_SERVICE.G_Time_Of_Day_MS / 3600000);

// Heating runtime reads temperatures through the normalized INPUT read-model.
// Local copies are intentionally used because FB_Heating_System_Manager still
// exposes these signals as VAR_IN_OUT; GVL_INPUT must remain a read-model surface,
// not a mutable domain-runtime surface.
L_Outdoor_Temp_Normalized := GVL_INPUT.IN_Outdoor_Temp;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_ZONES DO
    L_Room_Temps_Normalized[L_i] := GVL_INPUT.IN_Room_Temps[L_i];
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    L_Floor_Temps_Normalized[L_i] := GVL_INPUT.IN_Floor_Temps[L_i];
END_FOR;

L_Heating_Emergency_Stop := GVL_COMMAND_SHADOW.G_Heating_Emergency_Stop;
L_Heating_Gas_Safety_Stop := GVL_COMMAND_SHADOW.G_Heating_Gas_Safety_Stop OR GVL_STATE.G_Safety_Gas_Latched;

L_Runtime_Context.Runtime_Enabled := TRUE;
L_Runtime_Context.Runtime_Ready := TRUE;
L_Runtime_Context.Runtime_Fault := FALSE;
L_Runtime_Context.Current_Phase := E_Heating_Runtime_Phase.HRP_IDLE;

L_Runtime_Context.Allow_DHW_Phase := TRUE;
L_Runtime_Context.Allow_Heating_Phase := TRUE;
L_Runtime_Context.Allow_Service_Gating_Phase := TRUE;
L_Runtime_Context.Allow_State_Publication_Phase := TRUE;
L_Runtime_Context.Allow_Diagnostics_Phase := TRUE;
L_Runtime_Context.Allow_Output_Projection_Phase := TRUE;

L_Runtime_Context.DHW_Executed := FALSE;
L_Runtime_Context.Heating_Executed := FALSE;
L_Runtime_Context.Service_Gating_Executed := FALSE;
L_Runtime_Context.State_Publication_Executed := FALSE;
L_Runtime_Context.Diagnostics_Executed := FALSE;
L_Runtime_Context.Output_Projection_Executed := FALSE;

L_Runtime_Context.DHW_Before_Heating_Valid := TRUE;
L_Runtime_Context.State_Publication_Before_Diagnostics_Valid := TRUE;
L_Runtime_Context.Output_Projection_Last_Valid := TRUE;

L_Runtime_Context.Diagnostics_Isolation_Valid := TRUE;
L_Runtime_Context.Explainability_Isolation_Valid := TRUE;
L_Runtime_Context.Safety_Isolation_Valid := TRUE;
L_Runtime_Context.OpenTherm_Ownership_Valid := TRUE;
L_Runtime_Context.Cascade_Ownership_Valid := TRUE;

L_Runtime_Context.Runtime_Status_Code := 1;
L_Runtime_Context.Runtime_Status_Text := 'Heating runtime nominal';

L_Runtime_Context.Current_Phase := E_Heating_Runtime_Phase.HRP_IDLE;

fbObserverPhase(
    VI_Authorization_Stage := TRUE,
    VI_Finalization_Stage := FALSE,
    VI_Runtime_Context := L_Runtime_Context,
    VI_Diagnostics_Valid := TRUE
);

L_Runtime_Context.Current_Phase := E_Heating_Runtime_Phase.HRP_DHW;

fbDHWManager(
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Current_TOD := GVL_STATUS.G_Current_TOD,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_Temp := GVL_STATE.G_DHW_Temp,
    VI_Pressure := GVL_STATE.G_DHW_Pressure,
    VI_Config := GVL_CONFIG.G_DHW_Config,
    VI_Current_Day_Of_Week := GVL_STATUS.G_Current_Day,
    VI_IO_Modules_Online := GVL_STATUS.G_IO_Modules_Online,
    VI_Reset_Errors := GVL_INTENT_USER.I_Reset_Errors,
    VI_Emergency_Stop := L_Heating_Emergency_Stop,
    VI_System_Mode := GVL_STATE.G_System_Mode,
    VO_Status => L_DHW_Status,
    VO_Heating_Pump => L_DHW_Heating_Pump,
    VO_Circ_Pump => L_DHW_Circ_Pump
);

L_Runtime_Context.DHW_Executed := TRUE;

IF L_Heating_Gas_Safety_Stop THEN
    L_DHW_Heating_Pump := FALSE;
    L_DHW_Status.Heating_Pump_On := FALSE;
END_IF;

L_Runtime_Context.Current_Phase := E_Heating_Runtime_Phase.HRP_HEATING;

fbHeatingManager(
    VI_System_Mode := GVL_STATE.G_System_Mode,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
    VI_Outdoor_Temp := L_Outdoor_Temp_Normalized,
    VI_Config := GVL_CONFIG.G_Heating_Config,
    VI_Tariff := GVL_CONFIG.G_HMI_Tariff_Settings,
    VI_Current_Hour := L_Current_Hour,
    VI_DHW_Heating_Demand := L_DHW_Heating_Pump,
    VI_DHW_Target_Temp := GVL_CONFIG.G_DHW_Config.Target_Temp,
    VI_Emergency_Stop := L_Heating_Emergency_Stop,
    VI_Gas_Safety_Stop := L_Heating_Gas_Safety_Stop,
    VI_Boiler_Error_Status := GVL_STATE.G_Boiler_Error,
    VI_Boiler_OT_Online := GVL_STATE.G_Boiler_OT_Online,
    VI_Boiler_Modulation := L_Boiler_Modulation_REAL,
    VI_Floor_Temps := L_Floor_Temps_Normalized,
    VI_Room_Temps := L_Room_Temps_Normalized,
    VI_Manifold_Pressures := GVL_STATE.G_Manifold_Pressures,
    VI_Manifold_Currents := GVL_STATE.G_Manifold_Currents,
    VI_Manifold_Temps_Supply := GVL_STATE.G_Manifold_T_Supply,
    VI_Manifold_Temps_Return := GVL_STATE.G_Manifold_T_Return,
    VI_Boiler_Flame_Status := GVL_STATE.G_Boiler_Flame,
    VI_Zone_Configs := GVL_CONFIG.G_HMI_FloorHeating_Configs,
    VI_Rule_Actions := GVL_STATE.G_Rule_Actions,
    VI_IO_Modules_Online := GVL_STATUS.G_IO_Modules_Online,
    VI_Manifold_End_Switches := GVL_STATE.G_Manifold_End_Switches,
    VI_Valve_Test_Config := GVL_CONFIG.G_Valve_Test_Config,
    VO_Manifold_Valves => L_Manifold_Valves,
    VO_Manifold_Pumps => L_Manifold_Pumps,
    VO_Zone_Valves => L_Zone_Valves,
    VO_Boiler_OT_Enable => L_Boiler_OT_Enable,
    VO_Boiler_OT_Setpoint => L_Boiler_OT_Setpoint,
    VO_Backup_Circulation_Pump => L_Backup_Circulation_Pump,
    VO_Electric_Heater_Enable => L_Electric_Heater_Enable,
    VO_Freeze_Risk_Status => L_Freeze_Risk_Status,
    VO_Status => L_Manifold_Status,
    VO_Boiler_Status => L_Boiler_Status
);

L_Runtime_Context.Heating_Executed := TRUE;

L_Runtime_Context.Current_Phase := E_Heating_Runtime_Phase.HRP_SERVICE_GATING;

fbServiceGatingPhase(
    VI_Enable := TRUE,
    VIO_Manifold_Pumps := L_Manifold_Pumps,
    VIO_Backup_Circulation_Pump := L_Backup_Circulation_Pump,
    VIO_Electric_Heater_Enable := L_Electric_Heater_Enable,
    VIO_DHW_Heating_Pump := L_DHW_Heating_Pump,
    VIO_DHW_Circ_Pump := L_DHW_Circ_Pump,
    VIO_DHW_Status := L_DHW_Status,
    VIO_Freeze_Risk_Status := L_Freeze_Risk_Status
);

L_Runtime_Context.Service_Gating_Executed := fbServiceGatingPhase.VO_Executed;
L_Runtime_Context.Safety_Isolation_Valid := fbServiceGatingPhase.VO_Valid;

L_Runtime_Context.Current_Phase := E_Heating_Runtime_Phase.HRP_STATE_PUBLICATION;

fbStatePublicationPhase(
    VI_Enable := TRUE,
    VI_Zone_Valves := L_Zone_Valves,
    VI_Manifold_Pumps := L_Manifold_Pumps,
    VI_Manifold_Valves := L_Manifold_Valves,
    VI_Boiler_OT_Enable := L_Boiler_OT_Enable,
    VI_Boiler_OT_Setpoint := L_Boiler_OT_Setpoint,
    VI_Backup_Circulation_Pump := L_Backup_Circulation_Pump,
    VI_Electric_Heater_Enable := L_Electric_Heater_Enable,
    VI_Freeze_Risk_Status := L_Freeze_Risk_Status,
    VI_Manifold_Status := L_Manifold_Status,
    VI_Boiler_Status := L_Boiler_Status,
    VI_DHW_Heating_Pump := L_DHW_Heating_Pump,
    VI_DHW_Circ_Pump := L_DHW_Circ_Pump,
    VI_DHW_Status := L_DHW_Status
);

L_Runtime_Context.State_Publication_Executed := fbStatePublicationPhase.VO_Executed;
L_Runtime_Context.State_Publication_Before_Diagnostics_Valid := fbStatePublicationPhase.VO_Valid;

L_Runtime_Context.Current_Phase := E_Heating_Runtime_Phase.HRP_DIAGNOSTICS;

fbDiagnosticsPhase(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

L_Runtime_Context.Diagnostics_Executed := fbDiagnosticsPhase.VO_Executed;
L_Runtime_Context.Diagnostics_Isolation_Valid := fbDiagnosticsPhase.VO_Valid;

fbObserverPhase(
    VI_Authorization_Stage := FALSE,
    VI_Finalization_Stage := TRUE,
    VI_Runtime_Context := L_Runtime_Context,
    VI_Diagnostics_Valid := L_Runtime_Context.Diagnostics_Isolation_Valid
);

fbMetaSupervisionPublisher(
    VI_Enable := TRUE,
    VI_Runtime_Observation_Valid := GVL_Heating_Runtime_Observation.G_Runtime_Observation_Valid,
    VI_Runtime_Observer_Ready := GVL_Heating_Runtime_Observation.G_Runtime_Observer_Ready,
    VI_Runtime_Observer_Fault := GVL_Heating_Runtime_Observation.G_Runtime_Observer_Fault,
    VI_Runtime_Status_Code := GVL_Heating_Runtime_Observation.G_Runtime_Observation_Status_Code,
    VI_Runtime_Status_Text := GVL_Heating_Runtime_Observation.G_Runtime_Observation_Status_Text
);

GVL_Heating_Runtime_Meta.G_Runtime_Meta_Supervision :=
    fbMetaSupervisionPublisher.VO_Meta;

GVL_Heating_Runtime_Meta.G_Runtime_Meta_Publication_Valid :=
    fbMetaSupervisionPublisher.VO_Publication_Valid;

GVL_Heating_Runtime_Meta.G_Runtime_Meta_Status_Code :=
    fbMetaSupervisionPublisher.VO_Meta.Status_Code;

GVL_Heating_Runtime_Meta.G_Runtime_Meta_Status_Text :=
    fbMetaSupervisionPublisher.VO_Meta.Status_Text;

fbExplainabilityPublisher(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
    VI_Runtime_Context := L_Runtime_Context,
    VI_Runtime_Observation_Valid := GVL_Heating_Runtime_Observation.G_Runtime_Observation_Valid,
    VI_Runtime_Observer_Fault := GVL_Heating_Runtime_Observation.G_Runtime_Observer_Fault,
    VI_Runtime_Status_Code := GVL_Heating_Runtime_Observation.G_Runtime_Observation_Status_Code,
    VI_Runtime_Status_Text := GVL_Heating_Runtime_Observation.G_Runtime_Observation_Status_Text
);

GVL_Heating_Runtime_Explainability.G_Runtime_Phase_Event :=
    fbExplainabilityPublisher.VO_Phase_Event;

GVL_Heating_Runtime_Explainability.G_Runtime_Anomaly :=
    fbExplainabilityPublisher.VO_Anomaly;

GVL_Heating_Runtime_Explainability.G_Runtime_Blackbox_Event :=
    fbExplainabilityPublisher.VO_Blackbox_Event;

GVL_Heating_Runtime_Explainability.G_Runtime_Blackbox_Timeline :=
    fbExplainabilityPublisher.VO_Blackbox_Timeline;

GVL_Heating_Runtime_Explainability.G_Runtime_Event_Buffer :=
    fbExplainabilityPublisher.VO_Event_Buffer;

GVL_Heating_Runtime_Explainability.G_Runtime_Adaptive_Intelligence :=
    fbExplainabilityPublisher.VO_Adaptive_Intelligence;

GVL_Heating_Runtime_Explainability.G_Runtime_Causality_Graph :=
    fbExplainabilityPublisher.VO_Causality_Graph;

GVL_Heating_Runtime_Explainability.G_Runtime_Explainability_Publication_Valid :=
    fbExplainabilityPublisher.VO_Publication_Valid;

GVL_Heating_Runtime_Explainability.G_Runtime_Explainability_Status_Code :=
    fbExplainabilityPublisher.VO_Phase_Event.Status_Code;

GVL_Heating_Runtime_Explainability.G_Runtime_Explainability_Status_Text :=
    fbExplainabilityPublisher.VO_Phase_Event.Status_Text;

L_Runtime_Context.Current_Phase := E_Heating_Runtime_Phase.HRP_OUTPUT_PROJECTION;

fbOutputProjectionPhase(
    VI_Enable := TRUE,
    VI_Zone_Valves := L_Zone_Valves,
    VI_Manifold_Pumps := L_Manifold_Pumps,
    VI_Manifold_Valves := L_Manifold_Valves,
    VI_DHW_Heating_Pump := L_DHW_Heating_Pump,
    VI_DHW_Circ_Pump := L_DHW_Circ_Pump,
    VI_Backup_Circulation_Pump := L_Backup_Circulation_Pump,
    VI_Electric_Heater_Enable := L_Electric_Heater_Enable
);

L_Runtime_Context.Output_Projection_Executed := fbOutputProjectionPhase.VO_Executed;
L_Runtime_Context.Output_Projection_Last_Valid := fbOutputProjectionPhase.VO_Valid;

L_Runtime_Context.Current_Phase := E_Heating_Runtime_Phase.HRP_COMPLETE;

// >>> BULK_SYNC_ANCHOR: PRG_Heating <<<
END_PROGRAM
