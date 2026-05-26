PROGRAM PRG_Ventilation
VAR
    fbVentilationManager : FB_Ventilation_System_Manager;
    fbVentProjection : FB_Vent_Output_Projection;

    L_i : INT;

    L_Supply_Fans_Byte : ARRAY[1..GVL_CONSTANTS.C_MAX_SUPPLY_FANS] OF BYTE;
    L_Exhaust_Fans_Byte : ARRAY[1..GVL_CONSTANTS.C_MAX_EXHAUST_FANS] OF BYTE;

    L_Wet_Zone_Active : ARRAY[1..GVL_CONSTANTS.C_MAX_WET_ZONES] OF BOOL;

    L_Vent_PV3_Boost_Req : BOOL;
    L_Supply_100_Req : BOOL;
    L_Exhaust_100_Req : BOOL;
    L_Supply_80_Req : BOOL;
    L_Vent_Stop_Req : BOOL;

    L_Distributed_Execute_Allowed : BOOL;
    L_Distributed_Projection_Allowed : BOOL;

    L_Fire_Smoke_Override : BOOL;
    L_Gas_Vent_Override : BOOL;
    L_Safety_Vent_Override : BOOL;
    L_Fire_Exhaust_Targeted : BOOL;
END_VAR

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SUPPLY_FANS DO
    L_Supply_Fans_Byte[L_i] := 0;
END_FOR;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_EXHAUST_FANS DO
    L_Exhaust_Fans_Byte[L_i] := 0;
END_FOR;

L_Distributed_Execute_Allowed :=
    GVL_Distributed_Execution_Gates.G_Can_Execute;

L_Distributed_Projection_Allowed :=
    GVL_Distributed_Execution_Gates.G_Can_Own_Projection;

L_Fire_Smoke_Override :=
    GVL_COMMAND_SHADOW.G_Vent_Smoke_Exhaust;

L_Gas_Vent_Override :=
    (GVL_SAFETY_SHUTDOWN.G_Safety_Mode = GAS)
    OR GVL_COMMAND_SHADOW.G_Vent_PV3_Boost
    OR GVL_COMMAND_SHADOW.G_Supply_100_Req;

L_Vent_PV3_Boost_Req := GVL_COMMAND_SHADOW.G_Vent_PV3_Boost;
L_Supply_100_Req := GVL_COMMAND_SHADOW.G_Supply_100_Req;
L_Exhaust_100_Req := GVL_COMMAND_SHADOW.G_Exhaust_100_Req;
L_Supply_80_Req := GVL_COMMAND_SHADOW.G_Supply_80_Req;
L_Vent_Stop_Req := GVL_COMMAND_SHADOW.G_Vent_Stop;

L_Safety_Vent_Override :=
    L_Fire_Smoke_Override
    OR L_Gas_Vent_Override
    OR L_Supply_80_Req
    OR L_Exhaust_100_Req;

FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_WET_ZONES DO
    L_Wet_Zone_Active[L_i] := FALSE;
END_FOR;

IF GVL_STATUS.G_Wet_Zone_Light_Active THEN
    L_Wet_Zone_Active[1] := TRUE;
END_IF;

IF L_Distributed_Execute_Allowed THEN
    fbVentilationManager(
        VI_System_Time_MS := GVL_STATUS.G_System_Time_MS,
        VI_IsActivePLC := GVL_STATUS.G_Is_Active_PLC,
        VI_Outdoor_Temp := GVL_STATE.G_Outdoor_Temp,
        VI_Supply_Temps := GVL_STATE.G_Supply_Temps,
        VI_Room_Temps := GVL_STATE.G_Room_Temps,
        VI_Room_Humidities := GVL_STATE.G_Room_Hum,
        VI_Room_CO2 := GVL_STATE.G_Room_CO2,
        VI_Current_Scenario := GVL_STATUS.G_Current_Scenario,
        VI_System_Mode := GVL_STATE.G_System_Mode,
        VI_Config := GVL_CONFIG.G_HMI_Vent_Global_Config,
        VI_Fire_Alarm := GVL_STATE.G_Safety_Smoke_Latched,
        VI_Gas_Alarm := GVL_STATE.G_Safety_Gas_Latched,
        VI_PV3_Boost_Req := L_Vent_PV3_Boost_Req,
        VI_Supply_100_Req := L_Supply_100_Req,
        VI_Exhaust_100_Req := L_Exhaust_100_Req,
        VI_Supply_80_Req := L_Supply_80_Req,
        VI_Vent_Stop := L_Vent_Stop_Req,
        VI_IO_Modules_Online := GVL_STATUS.G_IO_Modules_Online,
        VI_Wet_Zone_Active := L_Wet_Zone_Active,
        VI_Rule_Actions := GVL_STATE.G_Rule_Actions,
        VO_Supply_Fans => L_Supply_Fans_Byte,
        VO_Exhaust_Fans => L_Exhaust_Fans_Byte,
        VO_Heater_Power => GVL_STATE.G_Vent_Heater_Power,
        VO_Status_Msg => GVL_STATUS.G_Vent_Status_Msg,
        VO_Ventilation_IO_Fault => GVL_STATE.G_Ventilation_IO_Fault,
        VO_Ventilation_Subsystem_Degraded => GVL_STATE.G_Ventilation_Subsystem_Degraded
    );
END_IF;

IF L_Fire_Smoke_Override THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SUPPLY_FANS DO
        L_Supply_Fans_Byte[L_i] := 0;
    END_FOR;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_EXHAUST_FANS DO
        L_Exhaust_Fans_Byte[L_i] := 0;
    END_FOR;

    L_Fire_Exhaust_Targeted := FALSE;

    CASE GVL_SMOKE_VERIFICATION.G_Verified_Group OF
        2:
            IF GVL_CONSTANTS.C_MAX_EXHAUST_FANS >= 1 THEN
                L_Exhaust_Fans_Byte[1] := 100;
                L_Fire_Exhaust_Targeted := TRUE;
            END_IF;
            IF GVL_CONSTANTS.C_MAX_EXHAUST_FANS >= 5 THEN
                L_Exhaust_Fans_Byte[5] := 100;
                L_Fire_Exhaust_Targeted := TRUE;
            END_IF;
        3:
            IF GVL_CONSTANTS.C_MAX_EXHAUST_FANS >= 2 THEN
                L_Exhaust_Fans_Byte[2] := 100;
                L_Fire_Exhaust_Targeted := TRUE;
            END_IF;
            IF GVL_CONSTANTS.C_MAX_EXHAUST_FANS >= 3 THEN
                L_Exhaust_Fans_Byte[3] := 100;
                L_Fire_Exhaust_Targeted := TRUE;
            END_IF;
    ELSE
            L_Fire_Exhaust_Targeted := FALSE;
    END_CASE;

    IF NOT L_Fire_Exhaust_Targeted THEN
        FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_EXHAUST_FANS DO
            L_Exhaust_Fans_Byte[L_i] := 100;
        END_FOR;
    END_IF;

ELSIF L_Supply_100_Req THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SUPPLY_FANS DO
        L_Supply_Fans_Byte[L_i] := 100;
    END_FOR;
ELSIF L_Supply_80_Req THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SUPPLY_FANS DO
        IF L_Supply_Fans_Byte[L_i] < 80 THEN
            L_Supply_Fans_Byte[L_i] := 80;
        END_IF;
    END_FOR;
END_IF;

IF (NOT L_Fire_Smoke_Override) AND L_Vent_PV3_Boost_Req THEN
    IF GVL_CONSTANTS.C_MAX_SUPPLY_FANS >= 3 THEN
        L_Supply_Fans_Byte[3] := 100;
    ELSE
        L_Supply_Fans_Byte[1] := 100;
    END_IF;
END_IF;

IF (NOT L_Fire_Smoke_Override) AND L_Exhaust_100_Req THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_EXHAUST_FANS DO
        L_Exhaust_Fans_Byte[L_i] := 100;
    END_FOR;
END_IF;

IF L_Vent_Stop_Req AND NOT L_Safety_Vent_Override THEN
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SUPPLY_FANS DO
        L_Supply_Fans_Byte[L_i] := 0;
    END_FOR;
    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_EXHAUST_FANS DO
        L_Exhaust_Fans_Byte[L_i] := 0;
    END_FOR;
END_IF;

IF NOT L_Distributed_Projection_Allowed
   AND NOT L_Safety_Vent_Override THEN

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_EXHAUST_FANS DO
        L_Exhaust_Fans_Byte[L_i] := 0;
    END_FOR;

    FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_SUPPLY_FANS DO
        L_Supply_Fans_Byte[L_i] := 0;
    END_FOR;
END_IF;

fbVentProjection(
    VI_Supply_Fans := L_Supply_Fans_Byte,
    VI_Exhaust_Fans := L_Exhaust_Fans_Byte
);

// >>> BULK_SYNC_ANCHOR: PRG_Ventilation <<<
END_PROGRAM
