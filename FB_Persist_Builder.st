FUNCTION_BLOCK FB_Persist_Builder
VAR_IN_OUT
    VIO_PersistStruct : ST_Persist;
END_VAR

// === BUILD STRUCT FROM STATE ===
// === NVRAM SNAPSHOT VIA STRUCT ADAPTER ===
VIO_PersistStruct.System_Mode := GVL_STATE.G_System_Mode;

VIO_PersistStruct.Safety_Gas_Latched := GVL_STATE.G_Safety_Gas_Latched;
VIO_PersistStruct.Safety_Smoke_Latched := GVL_STATE.G_Safety_Smoke_Latched;
VIO_PersistStruct.Safety_Leak_Latched := GVL_STATE.G_Safety_Leak_Latched;

VIO_PersistStruct.DHW_Heating_Pump := GVL_STATE.G_DHW_Heating_Pump;
VIO_PersistStruct.Valid := TRUE;

// mirror to legacy persistent variables
GVL_PERSISTENT.P_System_Mode := VIO_PersistStruct.System_Mode;

GVL_PERSISTENT.P_Safety_Gas_Latched := VIO_PersistStruct.Safety_Gas_Latched;
GVL_PERSISTENT.P_Safety_Smoke_Latched := VIO_PersistStruct.Safety_Smoke_Latched;
GVL_PERSISTENT.P_Safety_Leak_Latched := VIO_PersistStruct.Safety_Leak_Latched;

GVL_PERSISTENT.P_DHW_Heating_Active := VIO_PersistStruct.DHW_Heating_Pump;
GVL_PERSISTENT.P_Valid := VIO_PersistStruct.Valid;
END_FUNCTION_BLOCK
