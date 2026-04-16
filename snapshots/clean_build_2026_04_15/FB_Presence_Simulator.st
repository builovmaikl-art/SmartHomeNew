FUNCTION_BLOCK FB_Presence_Simulator
VAR_INPUT
    VI_Enabled : BOOL;
    VI_Intensity : REAL; 
    VI_System_Time : UDINT;
    VI_Use_Playback : BOOL; // Новый режим воспроизведения
END_VAR
VAR_OUTPUT
    VO_Light_States : ARRAY[1..32] OF BOOL;
END_VAR
VAR
    fbPlayback : FB_Presence_Playback;
END_VAR

IF VI_Enabled THEN
    IF VI_Use_Playback THEN
        fbPlayback(VI_Mode_Record := FALSE, VI_Time_Index := VI_System_Time MOD 604800000, VO_Light_Outputs => VO_Light_States);
    ELSE
        // Старая логика случайной симуляции
        VO_Light_States[1] := (VI_System_Time MOD 100000 > 50000);
    END_IF;
END_IF;