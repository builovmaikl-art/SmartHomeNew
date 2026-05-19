FUNCTION_BLOCK FB_System_Diagnostics_Publisher
VAR_INPUT
    VI_Enable : BOOL;
    VI_System_Time_MS : UDINT;
    VI_Backup_Pump_Out_Of_Service : BOOL;
    VI_Electric_Heater_Out_Of_Service : BOOL;
    VI_Manifold_Pump_Out_Of_Service : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VI_DHW_Heating_Pump_Out_Of_Service : BOOL;
    VI_DHW_Circ_Pump_Out_Of_Service : BOOL;
    VI_User_Access_Level : INT;
    VI_Dangerous_Action_Pending : BOOL;
    VI_Dangerous_Action_Text : STRING(160);
    VI_Sensor_Fault : BOOL;
    VI_IO_Offline : BOOL;
    VI_Subsystem_Degraded : BOOL;
    VI_Manifold_Pressure_Fault : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VI_Manifold_Current_Fault : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
    VI_Manifold_Return_Temp_Fault : ARRAY[1..GVL_CONSTANTS.C_MAX_MANIFOLDS] OF BOOL;
END_VAR
VAR_OUTPUT
    VO_Diagnostics : ST_System_Diagnostics;
    VO_Publication_Valid : BOOL;
    VO_Status_Code : UINT;
    VO_Status_Text : STRING(128);
END_VAR
VAR
    L_i : INT;
    L_Pressure_First : INT;
    L_Current_First : INT;
    L_Return_First : INT;
    L_Any_Manifold_Fault : BOOL;
END_VAR

VO_Diagnostics.Freeze_Hardware_Event_Pending := FALSE;
VO_Diagnostics.Freeze_Hardware_Event_Text := '';
VO_Diagnostics.Backup_Pump_Fault := VI_Backup_Pump_Out_Of_Service;
VO_Diagnostics.Electric_Heater_Fault := VI_Electric_Heater_Out_Of_Service;
VO_Diagnostics.Backup_Pump_Recovered_After_Retry := FALSE;
VO_Diagnostics.Electric_Heater_Recovered_After_Retry := FALSE;
VO_Diagnostics.Backup_Pump_Out_Of_Service := VI_Backup_Pump_Out_Of_Service;
VO_Diagnostics.Electric_Heater_Out_Of_Service := VI_Electric_Heater_Out_Of_Service;

VO_Diagnostics.Pump_Exercise_Active := FALSE;
VO_Diagnostics.Pump_Exercise_Failed := FALSE;
VO_Diagnostics.Pump_Exercise_Last_Equipment := '';
VO_Diagnostics.Pump_Exercise_Last_Result := 'Pump exercise publisher passive';
VO_Diagnostics.Pump_Exercise_No_Feedback_Count := 0;
VO_Diagnostics.DHW_Heating_Pump_Exercise_Count := 0;
VO_Diagnostics.DHW_Circ_Pump_Exercise_Count := 0;
VO_Diagnostics.Backup_Pump_Exercise_Count := 0;
VO_Diagnostics.Pump_Exercise_Event_Seq := VI_System_Time_MS;
VO_Diagnostics.Pump_Exercise_Journal_1 := 'Passive diagnostics publication active';
VO_Diagnostics.Pump_Exercise_Journal_2 := '';
VO_Diagnostics.Pump_Exercise_Journal_3 := '';
VO_Diagnostics.Pump_Exercise_Journal_Last_Seq := VI_System_Time_MS;

VO_Diagnostics.Pump_Maintenance_Required := VI_Backup_Pump_Out_Of_Service OR VI_Electric_Heater_Out_Of_Service;
VO_Diagnostics.Pump_Maintenance_Warning := VO_Diagnostics.Pump_Maintenance_Required;

VO_Diagnostics.DHW_Heating_Pump_Out_Of_Service := VI_DHW_Heating_Pump_Out_Of_Service;
VO_Diagnostics.DHW_Circ_Pump_Out_Of_Service := VI_DHW_Circ_Pump_Out_Of_Service;

VO_Diagnostics.Maintenance_Last_Action := 'Diagnostics publication only';
VO_Diagnostics.Operator_Action_Blocked := FALSE;
VO_Diagnostics.Operator_Block_Reason := '';
VO_Diagnostics.Operator_Last_Forbidden_Action := '';
VO_Diagnostics.Operator_Journal_1 := 'Operator diagnostics passive';
VO_Diagnostics.Operator_Journal_2 := '';
VO_Diagnostics.Operator_Journal_3 := '';
VO_Diagnostics.Operator_Journal_Event_Seq := VI_System_Time_MS;
VO_Diagnostics.Operator_Journal_Last_Seq := VI_System_Time_MS;

VO_Diagnostics.Dangerous_Action_Pending_Confirm := VI_Dangerous_Action_Pending;
VO_Diagnostics.Dangerous_Action_Confirm_Text := VI_Dangerous_Action_Text;
VO_Diagnostics.Dangerous_Action_Confirm_Deadline_MS := 0;
VO_Diagnostics.User_Access_Level_Active := VI_User_Access_Level;
VO_Diagnostics.User_Access_Denied := FALSE;
VO_Diagnostics.User_Access_Deny_Reason := '';

VO_Diagnostics.Valve_Test_Mode_Active := FALSE;
VO_Diagnostics.Valve_Test_Deadline_MS := 0;
VO_Diagnostics.Valve_Test_Remaining_MS := 0;
VO_Diagnostics.Valve_Test_Validation_OK := TRUE;
VO_Diagnostics.Valve_Test_Validation_Text := 'No generic valve test active';
VO_Diagnostics.Valve_Test_Forced_Close := FALSE;

VO_Diagnostics.Water_Valve_Test_Mode_Active := FALSE;
VO_Diagnostics.Water_Valve_Test_Deadline_MS := 0;
VO_Diagnostics.Water_Valve_Test_Remaining_MS := 0;
VO_Diagnostics.Water_Valve_Test_Validation_OK := TRUE;
VO_Diagnostics.Water_Valve_Test_Validation_Text := 'No water valve test active';
VO_Diagnostics.Water_Valve_Test_Forced_Close := FALSE;
VO_Diagnostics.Gas_Valve_Test_Mode_Active := FALSE;
VO_Diagnostics.Gas_Valve_Test_Deadline_MS := 0;
VO_Diagnostics.Gas_Valve_Test_Remaining_MS := 0;
VO_Diagnostics.Gas_Valve_Test_Validation_OK := TRUE;
VO_Diagnostics.Gas_Valve_Test_Validation_Text := 'No gas valve test active';
VO_Diagnostics.Gas_Valve_Test_Forced_Close := FALSE;

VO_Diagnostics.Active_Leak_Sensor_Index := 0;
VO_Diagnostics.Active_Gas_Sensor_Index := 0;
VO_Diagnostics.Active_Leak_Zone_Name := '';
VO_Diagnostics.Active_Gas_Zone_Name := '';
VO_Diagnostics.Water_Valve_Test_Context := 'Water diagnostics passive';
VO_Diagnostics.Gas_Valve_Test_Context := 'Gas diagnostics passive';

VO_Diagnostics.Water_Recovery_Target_Zone_Index := 0;
VO_Diagnostics.Gas_Recovery_Target_Zone_Index := 0;
VO_Diagnostics.Water_Recovery_Selective_Allowed := FALSE;
VO_Diagnostics.Gas_Recovery_Selective_Allowed := FALSE;
VO_Diagnostics.Water_Recovery_Selective_Text := 'Selective water recovery inactive';
VO_Diagnostics.Gas_Recovery_Selective_Text := 'Selective gas recovery inactive';
VO_Diagnostics.Water_Recovery_Physical_Active := FALSE;
VO_Diagnostics.Water_Recovery_Physical_Zone_Name := '';

VO_Diagnostics.Water_Valve_Exercise_Last_Zone := 0;
VO_Diagnostics.Water_Valve_Exercise_Last_Result := 'Water valve exercise inactive';
VO_Diagnostics.Water_Close_Fault_Active := FALSE;
VO_Diagnostics.Water_Close_Fault_Zone_Name := '';
VO_Diagnostics.Water_Close_Fault_Text := '';
VO_Diagnostics.Water_Localization_Failed := FALSE;
VO_Diagnostics.Water_Main_Shutdown_Recommended := FALSE;
VO_Diagnostics.Water_Escalation_Text := '';
VO_Diagnostics.Alarm_Event_Pulse := FALSE;
VO_Diagnostics.Alarm_Event_Code := 0;
VO_Diagnostics.Alarm_Event_Value := 0.0;
VO_Diagnostics.Sensor_Fault := VI_Sensor_Fault;
VO_Diagnostics.IO_Offline := VI_IO_Offline;
VO_Diagnostics.Subsystem_Degraded := VI_Subsystem_Degraded;

L_Pressure_First := 0;
L_Current_First := 0;
L_Return_First := 0;
L_Any_Manifold_Fault := FALSE;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_MANIFOLDS DO
    VO_Diagnostics.Manifold_Pump_Out_Of_Service[L_i] := VI_Manifold_Pump_Out_Of_Service[L_i];
    VO_Diagnostics.Manifold_Pump_Exercise_Count[L_i] := 0;

    VO_Diagnostics.Manifold_Pressure_Fault[L_i] := VI_Manifold_Pressure_Fault[L_i];
    VO_Diagnostics.Manifold_Pressure_Diag_Code[L_i] := SEL(VI_Manifold_Pressure_Fault[L_i], WORD#0, WORD#16#E004);
    IF VI_Manifold_Pressure_Fault[L_i] AND (L_Pressure_First = 0) THEN
        L_Pressure_First := L_i;
    END_IF;

    VO_Diagnostics.Manifold_Current_Fault[L_i] := VI_Manifold_Current_Fault[L_i];
    VO_Diagnostics.Manifold_Current_Diag_Code[L_i] := SEL(VI_Manifold_Current_Fault[L_i], WORD#0, WORD#16#E00A);
    IF VI_Manifold_Current_Fault[L_i] AND (L_Current_First = 0) THEN
        L_Current_First := L_i;
    END_IF;

    VO_Diagnostics.Manifold_Return_Temp_Fault[L_i] := VI_Manifold_Return_Temp_Fault[L_i];
    VO_Diagnostics.Manifold_Return_Temp_Diag_Code[L_i] := SEL(VI_Manifold_Return_Temp_Fault[L_i], WORD#0, WORD#16#E00D);
    IF VI_Manifold_Return_Temp_Fault[L_i] AND (L_Return_First = 0) THEN
        L_Return_First := L_i;
    END_IF;

    VO_Diagnostics.Manifold_Sensor_Fault_Count[L_i] := 0;
    IF VI_Manifold_Pressure_Fault[L_i] THEN
        VO_Diagnostics.Manifold_Sensor_Fault_Count[L_i] := VO_Diagnostics.Manifold_Sensor_Fault_Count[L_i] + 1;
    END_IF;
    IF VI_Manifold_Current_Fault[L_i] THEN
        VO_Diagnostics.Manifold_Sensor_Fault_Count[L_i] := VO_Diagnostics.Manifold_Sensor_Fault_Count[L_i] + 1;
    END_IF;
    IF VI_Manifold_Return_Temp_Fault[L_i] THEN
        VO_Diagnostics.Manifold_Sensor_Fault_Count[L_i] := VO_Diagnostics.Manifold_Sensor_Fault_Count[L_i] + 1;
    END_IF;

    VO_Diagnostics.Manifold_Sensor_Out_Of_Service[L_i] := VO_Diagnostics.Manifold_Sensor_Fault_Count[L_i] > 0;
    L_Any_Manifold_Fault := L_Any_Manifold_Fault OR VO_Diagnostics.Manifold_Sensor_Out_Of_Service[L_i];
END_FOR;

FOR L_i := 1 TO 32 DO
    VO_Diagnostics.Water_Zone_Open_Fault[L_i] := FALSE;
    VO_Diagnostics.Water_Zone_Close_Fault[L_i] := FALSE;
    VO_Diagnostics.Water_Zone_Critical_Close_Fault[L_i] := FALSE;
    VO_Diagnostics.Water_Zone_Close_Retry_Active[L_i] := FALSE;
    VO_Diagnostics.Water_Zone_Close_Retry_Count[L_i] := 0;
    VO_Diagnostics.Water_Zone_Close_Recovered_After_Retry[L_i] := FALSE;
END_FOR;

VO_Diagnostics.Manifold_Pressure_Fault_Active := L_Pressure_First > 0;
VO_Diagnostics.Manifold_Pressure_First_Fault_Index := L_Pressure_First;
VO_Diagnostics.Manifold_Pressure_Fault_Text := SEL(L_Pressure_First > 0, '', 'Manifold pressure fault active');

VO_Diagnostics.Manifold_Current_Fault_Active := L_Current_First > 0;
VO_Diagnostics.Manifold_Current_First_Fault_Index := L_Current_First;
VO_Diagnostics.Manifold_Current_Fault_Text := SEL(L_Current_First > 0, '', 'Manifold current fault active');

VO_Diagnostics.Manifold_Return_Temp_Fault_Active := L_Return_First > 0;
VO_Diagnostics.Manifold_Return_Temp_First_Fault_Index := L_Return_First;
VO_Diagnostics.Manifold_Return_Temp_Fault_Text := SEL(L_Return_First > 0, '', 'Manifold return temperature fault active');

VO_Diagnostics.Manifold_Sensor_Out_Of_Service_Active := L_Any_Manifold_Fault;
VO_Diagnostics.Manifold_Sensor_First_OOS_Index := SEL(L_Pressure_First > 0, SEL(L_Current_First > 0, L_Return_First, L_Current_First), L_Pressure_First);
VO_Diagnostics.Manifold_Sensor_OOS_Text := SEL(L_Any_Manifold_Fault, '', 'Manifold sensor out of service');

VO_Publication_Valid := VI_Enable;
VO_Status_Code := SEL(VI_Subsystem_Degraded OR VI_IO_Offline OR VI_Sensor_Fault OR L_Any_Manifold_Fault, 1, 900);
VO_Status_Text := SEL(VO_Status_Code = 1, 'System diagnostics nominal', 'System diagnostics degraded');

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_System_Diagnostics_Publisher <<<
