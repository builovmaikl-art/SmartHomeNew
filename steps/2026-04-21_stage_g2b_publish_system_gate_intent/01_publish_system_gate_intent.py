from pathlib import Path

path = Path('PRG_System.st')
text = path.read_text(encoding='utf-8')

anchor = "// 3.6a. Расчёт направленной эвакуации\n"
insert = """// === STAGE G2b: SYSTEM GATE PARALLEL PUBLICATION ===
GVL_INTENT_SYSTEM.I_Source_Valid := TRUE;
GVL_INTENT_SYSTEM.I_Last_Update_MS := GVL_STATUS.G_System_Time_MS;
GVL_INTENT_SYSTEM.I_Mode_Safe_Stop_Active := (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_SAFE_STOP);
GVL_INTENT_SYSTEM.I_Mode_Degraded_Active := (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_DEGRADED);
GVL_INTENT_SYSTEM.I_Mode_Freeze_Protection_Active := (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_FREEZE_PROTECTION);
GVL_INTENT_SYSTEM.I_Operator_Scenario_Block := (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_SAFE_STOP);
GVL_INTENT_SYSTEM.I_Lighting_Overrides_Block := (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_SAFE_STOP);
GVL_INTENT_SYSTEM.I_Blinds_Overrides_Block := (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_SAFE_STOP);
GVL_INTENT_SYSTEM.I_Socket_Overrides_Block := (GVL_STATE.G_System_Mode = E_System_Operating_Mode.MODE_SAFE_STOP);
GVL_INTENT_SYSTEM.I_Gateway_Writes_Allowed := L_Gateway_Writes_Allowed;
GVL_INTENT_SYSTEM.I_Scenario_Request_Allowed := (GVL_STATE.G_System_Mode <> E_System_Operating_Mode.MODE_SAFE_STOP);

"""

if anchor not in text:
    raise SystemExit('Anchor not found for Stage G2b')

path.write_text(text.replace(anchor, insert + anchor, 1), encoding='utf-8')
print('OK: inserted Stage G2b parallel publication block')
