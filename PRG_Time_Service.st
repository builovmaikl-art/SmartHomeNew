PROGRAM PRG_Time_Service
VAR
    fbTimebase : FB_System_Timebase;
    fbTime : FB_Time_Service;
END_VAR

// Central time update point.
// Must run before PRG_IO_Read and all consumers of GVL_TIME_SERVICE.
fbTimebase();
fbTime();

END_PROGRAM
