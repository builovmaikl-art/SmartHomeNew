FUNCTION_BLOCK FB_Rule_Engine_STAGING_BRIDGE_DRAFT
VAR_INPUT
    VI_System_Time_MS : UDINT;
    VI_IsActivePLC : BOOL;
    VI_Security_Armed : BOOL;
    VI_Current_Time : TOD;
    VI_Day_Of_Week : INT;
END_VAR
VAR_IN_OUT
    VI_Rules : ARRAY[1..GVL_CONSTANTS.C_MAX_RULES] OF ST_User_Rule;
    VI_Indoor_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_CLIMATE_ZONES] OF REAL;
    VI_Floor_Temps : ARRAY[1..GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS] OF REAL;
    VI_Humidities : ARRAY[1..GVL_CONSTANTS.C_MAX_CLIMATE_ZONES] OF REAL;
    VI_CO2_Levels : ARRAY[1..GVL_CONSTANTS.C_MAX_CLIMATE_ZONES] OF REAL;
    VI_Motion_Sensors : ARRAY[1..GVL_CONSTANTS.C_MAX_CLIMATE_ZONES] OF BOOL;
    VI_Door_Sensors : ARRAY[1..GVL_CONSTANTS.C_MAX_DOOR_SENSORS] OF BOOL;
    VI_Window_Sensors : ARRAY[1..GVL_CONSTANTS.C_MAX_CLIMATE_ZONES] OF BOOL;
    VI_Water_Sensors : ARRAY[1..GVL_CONSTANTS.C_MAX_FLOOD_SENSORS] OF BOOL;
    VI_Smoke_Sensors : ARRAY[1..GVL_CONSTANTS.C_MAX_SMOKE_SENSORS] OF BOOL;
    VI_Methane_Sensors : ARRAY[1..GVL_CONSTANTS.C_MAX_METHANE_SENSORS] OF REAL;
    VI_CO_Sensors : ARRAY[1..GVL_CONSTANTS.C_MAX_CO_SENSORS] OF REAL;
END_VAR
VAR_OUTPUT
    VO_Actions : ARRAY[1..GVL_CONSTANTS.C_MAX_RULES] OF ST_Rule_Action;
    VO_Adapter_OK : BOOL;
    VO_First_Warning : STRING(255);
END_VAR
VAR
    L_i : INT;
    fbCompat : ARRAY[1..GVL_CONSTANTS.C_MAX_RULES] OF FB_Rule_Compatibility_Package_DRAFT;
    L_All_OK : BOOL;
    L_First_Warning_Latched : BOOL;
END_VAR

IF NOT VI_IsActivePLC THEN
    RETURN;
END_IF;

L_All_OK := TRUE;
VO_First_Warning := '';
L_First_Warning_Latched := FALSE;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_RULES DO
    fbCompat[L_i](VI_Rule_Legacy := VI_Rules[L_i]);

    IF NOT fbCompat[L_i].VO_Forward_OK OR NOT fbCompat[L_i].VO_Reverse_OK THEN
        L_All_OK := FALSE;
    END_IF;

    IF (NOT L_First_Warning_Latched) AND (fbCompat[L_i].VO_Warning_Text <> '') THEN
        VO_First_Warning := fbCompat[L_i].VO_Warning_Text;
        L_First_Warning_Latched := TRUE;
    END_IF;

    // Staging behavior only:
    // preserve current runtime contract by round-tripping rules,
    // but do not change active action-generation algorithm here.
    VO_Actions[L_i].Active := FALSE;
    VO_Actions[L_i].Triggered := FALSE;
    VO_Actions[L_i].Action_Type := fbCompat[L_i].VO_Rule_Legacy_Roundtrip.Action_Type;
    VO_Actions[L_i].Target_ID := fbCompat[L_i].VO_Rule_Legacy_Roundtrip.Action_Target_ID;
    VO_Actions[L_i].Value := fbCompat[L_i].VO_Rule_Legacy_Roundtrip.Action_Value;
END_FOR;

VO_Adapter_OK := L_All_OK;
END_FUNCTION_BLOCK
