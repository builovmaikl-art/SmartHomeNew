FUNCTION_BLOCK FB_Gas_Valve_Controller IMPLEMENTS IValveController
VAR_INPUT
    VI_System_Time : UDINT;
    VI_IsActivePLC : BOOL;
    VI_Gas_Alarm   : BOOL;
    VI_Config      : ST_Gas_Valve_Configuration;
END_VAR
VAR_OUTPUT
    VO_Valve_Closed : BOOL;
    VO_Status_Msg   : STRING(200);
END_VAR

// При аварии газа - немедленное закрытие
IF VI_Gas_Alarm AND VI_IsActivePLC THEN
    VO_Valve_Closed := TRUE;
    VO_Status_Msg := 'ГАЗОВЫЙ КЛАПАН ЗАКРЫТ ПО АВАРИИ';
END_IF;

METHOD OpenValve : BOOL
VAR_INPUT
    VI_Operator_ID : STRING(10);
    VI_Force : BOOL;
END_VAR
IF VI_IsActivePLC OR VI_Force THEN
    VO_Valve_Closed := FALSE;
    OpenValve := TRUE;
END_IF;
END_METHOD

METHOD CloseValve : BOOL
VAR_INPUT
    VI_Operator_ID : STRING(10);
    VI_Force : BOOL;
END_VAR
VO_Valve_Closed := TRUE;
CloseValve := TRUE;
END_METHOD

METHOD GetStatus : BYTE
GetStatus := TO_BYTE(SEL(VO_Valve_Closed, 0, 1));
END_METHOD