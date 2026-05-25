FUNCTION_BLOCK FB_HMI_Interface
VAR_INPUT
    VI_Severity   : E_System_Severity;
    VI_RootCause  : E_System_Root_Cause;
    VI_Status_Msg : STRING(200);
END_VAR

VAR_OUTPUT
    VO_HMI_Status_Text : STRING(200);
    VO_HMI_State_Code  : INT;
END_VAR

VO_HMI_Status_Text := VI_Status_Msg;

CASE VI_Severity OF
    E_System_Severity.SEV_NORMAL:
        VO_HMI_State_Code := 0;
    E_System_Severity.SEV_WARNING:
        VO_HMI_State_Code := 1;
    E_System_Severity.SEV_DEGRADED:
        VO_HMI_State_Code := 2;
    E_System_Severity.SEV_CRITICAL:
        VO_HMI_State_Code := 3;
ELSE
        // No fallback required
END_CASE;
// >>> BULK_SYNC_ANCHOR: FB_HMI_Interface <<<
END_FUNCTION_BLOCK
