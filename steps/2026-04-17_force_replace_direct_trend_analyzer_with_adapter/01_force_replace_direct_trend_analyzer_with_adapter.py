from pathlib import Path
import re

path = Path("PRG_System.st")
text = path.read_text(encoding="utf-8")

# 1) Ensure adapter vars exist
anchor = "    L_Trend_Data : ST_Trend_Data;\n"
insert = """    L_Trend_Adapter : FB_Trend_Adapter;
    L_Trend_Avg : REAL;
    L_Trend_Min : REAL;
    L_Trend_Max : REAL;
    L_Trend_Up : BOOL;
    L_Trend_Down : BOOL;
"""
if anchor not in text:
    raise SystemExit("Trend data anchor not found in PRG_System.st")
if "L_Trend_Adapter : FB_Trend_Adapter;" not in text:
    text = text.replace(anchor, anchor + insert, 1)

# 2) Remove any direct broken L_Trend_Analyzer(...) call block
pattern = r"""
L_Trend_Analyzer\s*
\(
.*?
\)
;
"""
new_adapter_call = """L_Trend_Adapter(
    VI_Data := L_Trend_Data,
    VO_Average => L_Trend_Avg,
    VO_Min => L_Trend_Min,
    VO_Max => L_Trend_Max,
    VO_Trend_Up => L_Trend_Up,
    VO_Trend_Down => L_Trend_Down
);
"""
text, n = re.subn(pattern, new_adapter_call, text, flags=re.DOTALL | re.VERBOSE)

# 3) Normalize trend history write to use adapter average
text = text.replace(
    "L_Trend_Event.event_value := L_Trend_Average;",
    "L_Trend_Event.event_value := L_Trend_Avg;"
)
text = text.replace(
    "L_Trend_Event.event_value := L_Trend_Data.sum_values / UDINT_TO_REAL(L_Trend_Data.record_count);",
    "L_Trend_Event.event_value := L_Trend_Avg;"
)

# 4) Ensure no stale direct analyzer result variable names remain in logic
text = text.replace("L_Trend_Average", "L_Trend_Avg")
# keep Min/Max/Up/Down names as adapter outputs

path.write_text(text, encoding="utf-8")
print(f"direct_analyzer_blocks_replaced={n}")
print("OK: PRG_System normalized to adapter-only trend analysis")
