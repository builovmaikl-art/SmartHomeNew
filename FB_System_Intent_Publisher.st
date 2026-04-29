// ==============================================================================
// System intent publisher helper
//
// Internal helper for PRG_System.
// Owns publication of system-mode gates into GVL_INTENT_SYSTEM.
// ==============================================================================
FUNCTION_BLOCK FB_System_Intent_Publisher
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_Gateway_Writes_Allowed : BOOL;
END_VAR

GVL_INTENT_SYSTEM.I_Source_Valid := TRUE;
GVL_INTENT_SYSTEM.I_Last_Update_MS := VI_System_Time_MS;
GVL_INTENT_SYSTEM.I_Mode_Safe_Stop_Active := (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_SAFE_STOP);
GVL_INTENT_SYSTEM.I_Mode_Degraded_Active := (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_DEGRADED);
GVL_INTENT_SYSTEM.I_Mode_Freeze_Protection_Active := (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_FREEZE_PROTECTION);
GVL_INTENT_SYSTEM.I_Operator_Scenario_Block := (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_SAFE_STOP);
GVL_INTENT_SYSTEM.I_Lighting_Overrides_Block := (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_SAFE_STOP);
GVL_INTENT_SYSTEM.I_Blinds_Overrides_Block := (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_SAFE_STOP);
GVL_INTENT_SYSTEM.I_Socket_Overrides_Block := (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_SAFE_STOP);
GVL_INTENT_SYSTEM.I_Gateway_Writes_Allowed := VI_Gateway_Writes_Allowed;
GVL_INTENT_SYSTEM.I_Scenario_Request_Allowed := (GVL_STATE.G_System_Mode <> E_System_Operating_Mode.MODE_SAFE_STOP);

// >>> BULK_SYNC_ANCHOR: FB_System_Intent_Publisher <<<
