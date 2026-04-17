from pathlib import Path

content = """FUNCTION_BLOCK FB_Trend_Adapter
VAR_INPUT
    VI_Data : ST_Trend_Data;
END_VAR

VAR_OUTPUT
    VO_Average : REAL;
    VO_Min : REAL;
    VO_Max : REAL;
    VO_Trend_Up : BOOL;
    VO_Trend_Down : BOOL;
END_VAR

VAR
    fbAnalyzer : FB_Trend_Analyzer;
    L_Data_Copy : ARRAY[1..GVL_CONSTANTS.C_MAX_TREND_DATA_POINTS] OF REAL;
    L_Count : INT;
    L_i : INT;
END_VAR

// Normalize count to analyzer bounds
L_Count := UDINT_TO_INT(VI_Data.record_count);
IF L_Count < 0 THEN
    L_Count := 0;
END_IF;
IF L_Count > GVL_CONSTANTS.C_MAX_TREND_DATA_POINTS THEN
    L_Count := GVL_CONSTANTS.C_MAX_TREND_DATA_POINTS;
END_IF;

// Copy source values into analyzer-compatible buffer
FOR L_i := 1 TO GVL_CONSTANTS.C_MAX_TREND_DATA_POINTS DO
    L_Data_Copy[L_i] := 0.0;
END_FOR;

IF L_Count > 0 THEN
    FOR L_i := 1 TO L_Count DO
        L_Data_Copy[L_i] := VI_Data.values[L_i];
    END_FOR;
END_IF;

fbAnalyzer(
    VI_Count := L_Count,
    VI_Data := L_Data_Copy,
    VO_Average => VO_Average,
    VO_Max => VO_Max,
    VO_Min => VO_Min,
    VO_Trend_Up => VO_Trend_Up,
    VO_Trend_Down => VO_Trend_Down
);
"""

Path("FB_Trend_Adapter.st").write_text(content, encoding="utf-8")
print("OK: created FB_Trend_Adapter.st")
