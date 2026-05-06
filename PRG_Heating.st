PROGRAM PRG_Heating
VAR
    fbHeatingManager : FB_Heating_System_Manager;
    fbDHWManager : FB_DHW_Manager;
    fbOutputProjection : FB_Heating_Output_Projection;
    fbRootCauseDiagnostics : FB_Heating_RootCause_Diagnostics;
    fbRuntimeObserver : FB_Heating_Runtime_Observer;
    fbRuntimeObserverAuthorization : FB_Heating_Runtime_Observer_Authorization;

    L_Runtime_Context : ST_Heating_Runtime_Context;

    L_Runtime_Observer_Enable_Last : BOOL := FALSE;
    L_Runtime_Observer_Activation_Stabilized : BOOL := FALSE;

    L_i : INT;
    L_Current_Hour : UINT;
    L_Boiler_Modulation_REAL : ARRAY[1..GVL_CONSTANTS.C_MAX_BOILERS] OF REAL;

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

// ======================================================
// GOVERNED OBSERVER AUTHORIZATION EVALUATION
// ======================================================
GVL_Heating_Runtime_Observer.G_Runtime_Observer_Lifecycle_State :=
    E_Runtime_Observer_Lifecycle_State.ROS_AUTHORIZATION_PENDING;

fbRuntimeObserverAuthorization(
    VI_Enable_Request := GVL_Heating_Runtime_Observer.G_Runtime_Observer_Enable_Request,
    VI_Bootstrap_Mode := GVL_Heating_Runtime_Observer.G_Runtime_Observer_Bootstrap_Mode,
    VI_Passive_Mode := GVL_Heating_Runtime_Observer.G_Runtime_Observer_Passive_Mode,
    VI_ReadOnly_Mode := GVL_Heating_Runtime_Observer.G_Runtime_Observer_ReadOnly_Mode,
    VI_Governance_Locked := GVL_Heating_Runtime_Observer.G_Runtime_Observer_Governance_Locked,
    VI_Runtime_Authority_Disabled := GVL_Heating_Runtime_Observer.G_Runtime_Observer_Runtime_Authority_Disabled,
    VI_Writable_Exports_Disabled := GVL_Heating_Runtime_Observer.G_Runtime_Observer_Writable_Exports_Disabled
);

GVL_Heating_Runtime_Observer.G_Runtime_Observer_Enable_Authorized :=
    fbRuntimeObserverAuthorization.VO_Enable_Authorized;

GVL_Heating_Runtime_Observer.G_Runtime_Observer_Enable_Effective :=
    fbRuntimeObserverAuthorization.VO_Enable_Effective;

GVL_Heating_Runtime_Observer.G_Runtime_Observer_Authorization_Valid :=
    fbRuntimeObserverAuthorization.VO_Authorization_Valid;

GVL_Heating_Runtime_Observer.G_Runtime_Observer_Authorization_Status_Code :=
    fbRuntimeObserverAuthorization.VO_Status_Code;

GVL_Heating_Runtime_Observer.G_Runtime_Observer_Authorization_Status_Text :=
    fbRuntimeObserverAuthorization.VO_Status_Text;

IF NOT GVL_Heating_Runtime_Observer.G_Runtime_Observer_Enable_Request THEN
    GVL_Heating_Runtime_Observer.G_Runtime_Observer_Lifecycle_State :=
        E_Runtime_Observer_Lifecycle_State.ROS_INACTIVE;
ELSIF NOT GVL_Heating_Runtime_Observer.G_Runtime_Observer_Enable_Effective THEN
    GVL_Heating_Runtime_Observer.G_Runtime_Observer_Lifecycle_State :=
        E_Runtime_Observer_Lifecycle_State.ROS_AUTHORIZATION_DENIED;
END_IF;

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
    VI_Outdoor_Temp := GVL_STATE.G_Outdoor_Temp,
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
    VI_Floor_Temps := GVL_STATE.G_Floor_Temps,
    VI_Room_Temps := GVL_STATE.G_Room_Temps,
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

GVL_STATUS.G_Diagnostics.Backup_Pump_Out_Of_Service := NOT GVL_CONFIG.G_Backup_Circulation_Pump_In_Service;
GVL_STATUS.G_Diagnostics.Electric_Heater_Out_Of_Service := NOT GVL_CONFIG.G_Electric_Heater_In_Service;

IF NOT GVL_CONFIG.G_Backup_Circulation_Pump_In_Service THEN
    L_Backup_Circulation_Pump := FALSE;
END_IF;

IF NOT GVL_CONFIG.G_Electric_Heater_In_Service THEN
    L_Electric_Heater_Enable := FALSE;
END_IF;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    GVL_STATUS.G_Diagnostics.Manifold_Pump_Out_Of_Service[L_i] := NOT GVL_CONFIG.G_Manifold_Pump_In_Service[L_i];
    IF NOT GVL_CONFIG.G_Manifold_Pump_In_Service[L_i] THEN
        L_Manifold_Pumps[L_i] := FALSE;
    END_IF;
END_FOR;

GVL_STATUS.G_Diagnostics.DHW_Heating_Pump_Out_Of_Service := NOT GVL_CONFIG.G_DHW_Heating_Pump_In_Service;
IF NOT GVL_CONFIG.G_DHW_Heating_Pump_In_Service THEN
    L_DHW_Heating_Pump := FALSE;
    L_DHW_Status.Heating_Pump_On := FALSE;
END_IF;

GVL_STATUS.G_Diagnostics.DHW_Circ_Pump_Out_Of_Service := NOT GVL_CONFIG.G_DHW_Circ_Pump_In_Service;
IF NOT GVL_CONFIG.G_DHW_Circ_Pump_In_Service THEN
    L_DHW_Circ_Pump := FALSE;
    L_DHW_Status.Circ_Pump_On := FALSE;
END_IF;

GVL_STATE.G_Freeze_Hardware_Degraded := GVL_STATUS.G_Diagnostics.Backup_Pump_Fault OR GVL_STATUS.G_Diagnostics.Electric_Heater_Fault;
GVL_STATE.G_Freeze_Hardware_Failed := GVL_STATUS.G_Diagnostics.Backup_Pump_Fault AND GVL_STATUS.G_Diagnostics.Electric_Heater_Fault;

IF GVL_STATE.G_Freeze_Hardware_Failed THEN
    L_Backup_Circulation_Pump := FALSE;
    L_Electric_Heater_Enable := FALSE;
    L_Freeze_Risk_Status := TRUE;
END_IF;

L_Runtime_Context.Service_Gating_Executed := TRUE;

L_Runtime_Context.Current_Phase := E_Heating_Runtime_Phase.HRP_STATE_PUBLICATION;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS DO
    GVL_STATE.G_Zone_Valves[L_i] := L_Zone_Valves[L_i];
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    GVL_STATE.G_Manifold_Pumps[L_i] := L_Manifold_Pumps[L_i];
    GVL_STATE.G_Manifold_Valves[L_i] := L_Manifold_Valves[L_i];
    GVL_STATUS.G_Manifold_Status[L_i] := L_Manifold_Status[L_i];
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_BOILERS DO
    GVL_STATE.G_Boiler_OT_Enable[L_i] := L_Boiler_OT_Enable[L_i];
    GVL_STATE.G_Boiler_OT_Setpoint[L_i] := L_Boiler_OT_Setpoint[L_i];
    GVL_STATUS.G_Boiler_Status[L_i] := L_Boiler_Status[L_i];
END_FOR;

GVL_STATE.G_Backup_Circulation_Pump := L_Backup_Circulation_Pump;
GVL_STATE.G_Electric_Heater_Enable := L_Electric_Heater_Enable;
GVL_STATE.G_Safety_Freeze_Risk := L_Freeze_Risk_Status;
GVL_STATE.G_DHW_Heating_Pump := L_DHW_Heating_Pump;
GVL_STATE.G_DHW_Circ_Pump := L_DHW_Circ_Pump;
GVL_STATUS.G_DHW_Status := L_DHW_Status;

L_Runtime_Context.State_Publication_Executed := TRUE;

L_Runtime_Context.Current_Phase := E_Heating_Runtime_Phase.HRP_DIAGNOSTICS;

fbRootCauseDiagnostics(
    VI_Enable := TRUE
);

L_Runtime_Context.Diagnostics_Executed := TRUE;

// ======================================================
// GOVERNED FINALIZED-STATE RUNTIME OBSERVER
// ======================================================
IF GVL_Heating_Runtime_Observer.G_Runtime_Observer_Enable_Effective THEN

    GVL_Heating_Runtime_Observer.G_Runtime_Observer_Rollback_Validated := FALSE;

    IF NOT L_Runtime_Observer_Enable_Last THEN
        L_Runtime_Observer_Activation_Stabilized := FALSE;

        GVL_Heating_Runtime_Observer.G_Runtime_Observer_Lifecycle_State :=
            E_Runtime_Observer_Lifecycle_State.ROS_STABILIZATION;
        GVL_Heating_Runtime_Observation.G_Runtime_Observer_Lifecycle_State :=
            E_Runtime_Observer_Lifecycle_State.ROS_STABILIZATION;

        GVL_Heating_Runtime_Observation.G_Runtime_Observation_Publication_Valid := FALSE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observation_Stabilization_Complete := FALSE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observation_Operational := FALSE;

        GVL_Heating_Runtime_Observation.G_Runtime_Observation_Valid := FALSE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observer_Ready := FALSE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observer_Fault := FALSE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observation_Status_Code := 100;
        GVL_Heating_Runtime_Observation.G_Runtime_Observation_Status_Text :=
            'Heating runtime observer stabilization cycle active';
    END_IF;

    fbRuntimeObserver(
        VI_Enable := TRUE,
        VI_Runtime_Context := L_Runtime_Context,
        VI_Diagnostics_Valid := TRUE
    );

    GVL_Heating_Runtime_Observation.G_Runtime_Observation :=
        fbRuntimeObserver.VO_Observation;

    IF L_Runtime_Observer_Activation_Stabilized THEN
        GVL_Heating_Runtime_Observer.G_Runtime_Observer_Lifecycle_State :=
            E_Runtime_Observer_Lifecycle_State.ROS_OPERATIONAL;
        GVL_Heating_Runtime_Observation.G_Runtime_Observer_Lifecycle_State :=
            E_Runtime_Observer_Lifecycle_State.ROS_OPERATIONAL;

        GVL_Heating_Runtime_Observation.G_Runtime_Observation_Publication_Valid := TRUE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observation_Stabilization_Complete := TRUE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observation_Operational := TRUE;

        GVL_Heating_Runtime_Observation.G_Runtime_Observation_Valid := TRUE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observer_Ready :=
            fbRuntimeObserver.VO_Observer_Ready;
        GVL_Heating_Runtime_Observation.G_Runtime_Observer_Fault :=
            fbRuntimeObserver.VO_Observer_Fault;
        GVL_Heating_Runtime_Observation.G_Runtime_Observation_Status_Code :=
            fbRuntimeObserver.VO_Status_Code;
        GVL_Heating_Runtime_Observation.G_Runtime_Observation_Status_Text :=
            fbRuntimeObserver.VO_Status_Text;

        GVL_Heating_Runtime_Observer.G_Runtime_Observer_Activation_Validated := TRUE;
        GVL_Heating_Runtime_Observer.G_Runtime_Observer_Sequencing_Validated := TRUE;
        GVL_Heating_Runtime_Observer.G_Runtime_Observer_Publication_Validated := TRUE;
    ELSE
        L_Runtime_Observer_Activation_Stabilized := TRUE;
    END_IF;

ELSE
    L_Runtime_Observer_Activation_Stabilized := FALSE;

    IF L_Runtime_Observer_Enable_Last THEN
        GVL_Heating_Runtime_Observer.G_Runtime_Observer_Lifecycle_State :=
            E_Runtime_Observer_Lifecycle_State.ROS_ROLLBACK;
        GVL_Heating_Runtime_Observation.G_Runtime_Observer_Lifecycle_State :=
            E_Runtime_Observer_Lifecycle_State.ROS_ROLLBACK;
    ELSIF GVL_Heating_Runtime_Observer.G_Runtime_Observer_Enable_Request THEN
        GVL_Heating_Runtime_Observer.G_Runtime_Observer_Lifecycle_State :=
            E_Runtime_Observer_Lifecycle_State.ROS_AUTHORIZATION_DENIED;
        GVL_Heating_Runtime_Observation.G_Runtime_Observer_Lifecycle_State :=
            E_Runtime_Observer_Lifecycle_State.ROS_AUTHORIZATION_DENIED;
    ELSE
        GVL_Heating_Runtime_Observer.G_Runtime_Observer_Lifecycle_State :=
            E_Runtime_Observer_Lifecycle_State.ROS_INACTIVE;
        GVL_Heating_Runtime_Observation.G_Runtime_Observer_Lifecycle_State :=
            E_Runtime_Observer_Lifecycle_State.ROS_INACTIVE;
    END_IF;

    GVL_Heating_Runtime_Observation.G_Runtime_Observation.Runtime_Active := FALSE;
    GVL_Heating_Runtime_Observation.G_Runtime_Observation.Runtime_Ready := FALSE;
    GVL_Heating_Runtime_Observation.G_Runtime_Observation.Runtime_Fault := FALSE;
    GVL_Heating_Runtime_Observation.G_Runtime_Observation.Current_Phase := E_Heating_Runtime_Phase.HRP_DISABLED;

    GVL_Heating_Runtime_Observation.G_Runtime_Observation.DHW_Demand_Active := FALSE;
    GVL_Heating_Runtime_Observation.G_Runtime_Observation.DHW_Heating_Active := FALSE;
    GVL_Heating_Runtime_Observation.G_Runtime_Observation.DHW_Circulation_Active := FALSE;

    GVL_Heating_Runtime_Observation.G_Runtime_Observation.Heating_Demand_Active := FALSE;
    GVL_Heating_Runtime_Observation.G_Runtime_Observation.Heating_Runtime_Active := FALSE;
    GVL_Heating_Runtime_Observation.G_Runtime_Observation.Heating_Output_Active := FALSE;

    GVL_Heating_Runtime_Observation.G_Runtime_Observation.Cascade_Available := FALSE;
    GVL_Heating_Runtime_Observation.G_Runtime_Observation.Cascade_Degraded := FALSE;
    GVL_Heating_Runtime_Observation.G_Runtime_Observation.Cascade_Active_Boilers := 0;
    GVL_Heating_Runtime_Observation.G_Runtime_Observation.Cascade_Available_Boilers := 0;

    GVL_Heating_Runtime_Observation.G_Runtime_Observation.OpenTherm_Online := FALSE;
    GVL_Heating_Runtime_Observation.G_Runtime_Observation.OpenTherm_Command_Valid := FALSE;
    GVL_Heating_Runtime_Observation.G_Runtime_Observation.OpenTherm_Transport_Degraded := FALSE;

    GVL_Heating_Runtime_Observation.G_Runtime_Observation.Diagnostics_Active := FALSE;
    GVL_Heating_Runtime_Observation.G_Runtime_Observation.Explainability_Active := FALSE;

    GVL_Heating_Runtime_Observation.G_Runtime_Observation.DHW_Before_Heating_Observed := FALSE;
    GVL_Heating_Runtime_Observation.G_Runtime_Observation.Diagnostics_After_Publication_Observed := FALSE;
    GVL_Heating_Runtime_Observation.G_Runtime_Observation.Output_Projection_Last_Observed := FALSE;

    GVL_Heating_Runtime_Observation.G_Runtime_Observation.Runtime_Ownership_Valid := FALSE;
    GVL_Heating_Runtime_Observation.G_Runtime_Observation.Diagnostics_Ownership_Valid := FALSE;
    GVL_Heating_Runtime_Observation.G_Runtime_Observation.OpenTherm_Ownership_Valid := FALSE;
    GVL_Heating_Runtime_Observation.G_Runtime_Observation.Cascade_Ownership_Valid := FALSE;
    GVL_Heating_Runtime_Observation.G_Runtime_Observation.Safety_Ownership_Valid := FALSE;

    GVL_Heating_Runtime_Observation.G_Runtime_Observation.Observation_Status_Code := 0;
    GVL_Heating_Runtime_Observation.G_Runtime_Observation.Observation_Status_Text :=
        'Heating runtime observation inactive';

    GVL_Heating_Runtime_Observation.G_Runtime_Observation_Publication_Valid := FALSE;
    GVL_Heating_Runtime_Observation.G_Runtime_Observation_Stabilization_Complete := FALSE;
    GVL_Heating_Runtime_Observation.G_Runtime_Observation_Operational := FALSE;

    GVL_Heating_Runtime_Observation.G_Runtime_Observation_Valid := FALSE;
    GVL_Heating_Runtime_Observation.G_Runtime_Observer_Ready := FALSE;
    GVL_Heating_Runtime_Observation.G_Runtime_Observer_Fault := FALSE;
    GVL_Heating_Runtime_Observation.G_Runtime_Observation_Status_Code := 0;
    GVL_Heating_Runtime_Observation.G_Runtime_Observation_Status_Text :=
        'Heating runtime observation inactive';

    GVL_Heating_Runtime_Observer.G_Runtime_Observer_Activation_Validated := FALSE;
    GVL_Heating_Runtime_Observer.G_Runtime_Observer_Sequencing_Validated := FALSE;
    GVL_Heating_Runtime_Observer.G_Runtime_Observer_Publication_Validated := FALSE;
    GVL_Heating_Runtime_Observer.G_Runtime_Observer_Rollback_Validated := TRUE;
END_IF;

L_Runtime_Observer_Enable_Last :=
    GVL_Heating_Runtime_Observer.G_Runtime_Observer_Enable_Effective;

L_Runtime_Context.Current_Phase := E_Heating_Runtime_Phase.HRP_OUTPUT_PROJECTION;

fbOutputProjection(
    VI_Zone_Valves := L_Zone_Valves,
    VI_Manifold_Pumps := L_Manifold_Pumps,
    VI_Manifold_Valves := L_Manifold_Valves,
    VI_DHW_Heating_Pump := L_DHW_Heating_Pump,
    VI_DHW_Circ_Pump := L_DHW_Circ_Pump,
    VI_Backup_Circulation_Pump := L_Backup_Circulation_Pump,
    VI_Electric_Heater_Enable := L_Electric_Heater_Enable
);

L_Runtime_Context.Output_Projection_Executed := TRUE;
L_Runtime_Context.Current_Phase := E_Heating_Runtime_Phase.HRP_COMPLETE;

// >>> BULK_SYNC_ANCHOR: PRG_Heating <<<
END_PROGRAM
