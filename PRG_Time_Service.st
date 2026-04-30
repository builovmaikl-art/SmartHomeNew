PROGRAM PRG_Time_Service
VAR
    fbTimebase : FB_System_Timebase;
    fbTime : FB_Time_Service;
END_VAR

// Central time update point.
// Must run before PRG_IO_Read and all consumers of GVL_TIME_SERVICE.
fbTimebase();
fbTime();

// Step 4.2 compatibility bridge.
// Legacy consumers of GVL_STATUS.G_System_Time_MS receive the same canonical time.
GVL_STATUS.G_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS;
GVL_STATUS.G_Current_TOD := GVL_TIME_SERVICE.G_Current_TOD;
GVL_STATUS.G_Current_Day := GVL_TIME_SERVICE.G_Day_Of_Week;

END_PROGRAM
