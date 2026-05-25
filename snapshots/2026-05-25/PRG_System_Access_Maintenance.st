PROGRAM PRG_System_Access_Maintenance
VAR
    fbLogEvent : FB_LogEvent;
    L_Dangerous_Action_Armed : BOOL;
    L_Dangerous_Action_Deadline_MS : UDINT;
    L_Maintenance_Apply_Intent : BOOL;
    L_User_Access_Denied_Prev : BOOL;
END_VAR

L_Maintenance_Apply_Intent := FALSE;

// Dangerous action request
IF GVL_COMMAND.CMD_Dangerous_Action_Request AND (GVL_COMMAND.CMD_User_Access_Level >= 2) THEN
    IF NOT L_Dangerous_Action_Armed THEN
        fbLogEvent(
            VI_Event_Type := 8,
            VI_Timestamp := GVL_TIME_SERVICE.G_Now_MS,
            VI_Param1 := TO_UDINT(GVL_COMMAND.CMD_User_Access_Level),
            VI_Param2 := 1
        );
    END_IF;

    L_Dangerous_Action_Armed := TRUE;
    L_Dangerous_Action_Deadline_MS := GVL_TIME_SERVICE.G_Now_MS + 15000;

    GVL_STATUS.G_Diagnostics.Dangerous_Action_Pending_Confirm := TRUE;
    GVL_STATUS.G_Diagnostics.Dangerous_Action_Confirm_Deadline_MS := L_Dangerous_Action_Deadline_MS;
    GVL_STATUS.G_Diagnostics.Dangerous_Action_Confirm_Text := 'Подтвердите опасное действие в течение 15 секунд';
END_IF;

// Timeout
IF L_Dangerous_Action_Armed AND (GVL_TIME_SERVICE.G_Now_MS > L_Dangerous_Action_Deadline_MS) THEN
    L_Dangerous_Action_Armed := FALSE;
    GVL_STATUS.G_Diagnostics.Dangerous_Action_Pending_Confirm := FALSE;
    GVL_STATUS.G_Diagnostics.Dangerous_Action_Confirm_Text := 'Окно подтверждения истекло';
END_IF;

// Confirm
IF GVL_COMMAND.CMD_Dangerous_Action_Confirm AND
   L_Dangerous_Action_Armed AND
   (GVL_COMMAND.CMD_User_Access_Level >= 2) THEN

    L_Maintenance_Apply_Intent := TRUE;

    fbLogEvent(
        VI_Event_Type := 9,
        VI_Timestamp := GVL_TIME_SERVICE.G_Now_MS,
        VI_Param1 := TO_UDINT(GVL_COMMAND.CMD_User_Access_Level),
        VI_Param2 := 1
    );

    L_Dangerous_Action_Armed := FALSE;
    GVL_STATUS.G_Diagnostics.Dangerous_Action_Pending_Confirm := FALSE;
    GVL_STATUS.G_Diagnostics.Dangerous_Action_Confirm_Text := 'Опасное действие подтверждено оператором';
END_IF;

// Apply maintenance
IF L_Maintenance_Apply_Intent THEN
    GVL_CONFIG.G_DHW_Heating_Pump_In_Service := GVL_COMMAND.CMD_Set_DHW_Heating_Pump_In_Service;
    GVL_CONFIG.G_DHW_Circ_Pump_In_Service := GVL_COMMAND.CMD_Set_DHW_Circ_Pump_In_Service;
END_IF;

// Access enforcement
GVL_STATUS.G_Diagnostics.User_Access_Level_Active := GVL_COMMAND.CMD_User_Access_Level;
GVL_STATUS.G_Diagnostics.User_Access_Denied := FALSE;

IF GVL_COMMAND.CMD_Dangerous_Action_Request OR GVL_COMMAND.CMD_Dangerous_Action_Confirm THEN
    IF GVL_COMMAND.CMD_User_Access_Level < 2 THEN
        IF NOT L_User_Access_Denied_Prev THEN
            fbLogEvent(
                VI_Event_Type := 10,
                VI_Timestamp := GVL_TIME_SERVICE.G_Now_MS,
                VI_Param1 := TO_UDINT(GVL_COMMAND.CMD_User_Access_Level),
                VI_Param2 := 2
            );
        END_IF;

        GVL_STATUS.G_Diagnostics.User_Access_Denied := TRUE;
        GVL_STATUS.G_Diagnostics.Operator_Action_Blocked := TRUE;
    END_IF;
END_IF;

L_User_Access_Denied_Prev := GVL_STATUS.G_Diagnostics.User_Access_Denied;

END_PROGRAM
