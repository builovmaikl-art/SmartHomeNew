// ==============================================================================
// Heating runtime observer authorization
// Governed passive-bootstrap authorization only.
// Read-only.
// Deterministic.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Observer_Authorization
VAR_INPUT
    VI_Enable_Request : BOOL;

    VI_Bootstrap_Mode : BOOL;
    VI_Passive_Mode : BOOL;
    VI_ReadOnly_Mode : BOOL;

    VI_Governance_Locked : BOOL;
    VI_Runtime_Authority_Disabled : BOOL;
    VI_Writable_Exports_Disabled : BOOL;
END_VAR
VAR_OUTPUT
    VO_Enable_Authorized : BOOL;
    VO_Enable_Effective : BOOL;

    VO_Authorization_Valid : BOOL;

    VO_Status_Code : UINT;
    VO_Status_Text : STRING(128);
END_VAR

// ======================================================
// DEFAULTS
// ======================================================
VO_Enable_Authorized := FALSE;
VO_Enable_Effective := FALSE;
VO_Authorization_Valid := FALSE;

VO_Status_Code := 0;
VO_Status_Text := 'Heating runtime observer authorization inactive';

// ======================================================
// REQUEST VALIDATION
// ======================================================
IF NOT VI_Enable_Request THEN
    RETURN;
END_IF;

// ======================================================
// GOVERNANCE VALIDATION
// ======================================================
IF NOT VI_Bootstrap_Mode THEN
    VO_Status_Code := 100;
    VO_Status_Text := 'Bootstrap mode required for observer authorization';
    RETURN;
END_IF;

IF NOT VI_Passive_Mode THEN
    VO_Status_Code := 110;
    VO_Status_Text := 'Passive mode required for observer authorization';
    RETURN;
END_IF;

IF NOT VI_ReadOnly_Mode THEN
    VO_Status_Code := 120;
    VO_Status_Text := 'Read-only mode required for observer authorization';
    RETURN;
END_IF;

IF NOT VI_Governance_Locked THEN
    VO_Status_Code := 130;
    VO_Status_Text := 'Governance lock required for observer authorization';
    RETURN;
END_IF;

IF NOT VI_Runtime_Authority_Disabled THEN
    VO_Status_Code := 140;
    VO_Status_Text := 'Runtime authority isolation required';
    RETURN;
END_IF;

IF NOT VI_Writable_Exports_Disabled THEN
    VO_Status_Code := 150;
    VO_Status_Text := 'Writable exports must remain disabled';
    RETURN;
END_IF;

// ======================================================
// AUTHORIZED PASSIVE BOOTSTRAP ACTIVATION
// ======================================================
VO_Enable_Authorized := TRUE;
VO_Enable_Effective := TRUE;
VO_Authorization_Valid := TRUE;

VO_Status_Code := 1;
VO_Status_Text := 'Heating runtime observer authorization granted';

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Observer_Authorization <<<
