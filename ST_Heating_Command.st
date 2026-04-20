TYPE ST_Heating_Command :
STRUCT
    Enable              : BOOL;
    Target_Temperature  : REAL;
    Priority            : INT; // higher = stronger
END_STRUCT
END_TYPE
