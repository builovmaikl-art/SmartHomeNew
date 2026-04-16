FUNCTION_BLOCK FB_Water_Valve_Controller IMPLEMENTS IValveController
VAR_INPUT
    VI_System_Time : UDINT;
    VI_IsActivePLC : BOOL;
    VI_Flood_Alarm : BOOL;
END_VAR
VAR_OUTPUT
    VO_Valve_Closed : BOOL;
    VO_Status_Msg   : STRING(200);
END_VAR

IF VI_Flood_Alarm AND VI_IsActivePLC THEN
    VO_Valve_Closed := TRUE;
    VO_Status_Msg := 'КЛАПАН ЗАКРЫТ ПО ПРОТЕЧКЕ';
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