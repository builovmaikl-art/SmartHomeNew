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

    VO_Deny_Reason : E_Runtime_Observer_Deny_Reason;
    VO_Deny_Text : STRING(128);

    VO_Status_Code : UINT;
    VO_Status_Text : STRING(128);
END_VAR

// ======================================================
// DEFAULTS
// ======================================================
VO_Enable_Authorized := FALSE;
VO_Enable_Effective := FALSE;
VO_Authorization_Valid := FALSE;

VO_Deny_Reason := E_Runtime_Observer_Deny_Reason.RODR_NONE;
VO_Deny_Text := 'No deny reason';

VO_Status_Code := 0;
VO_Status_Text := 'Heating runtime observer authorization inactive';

// ======================================================
// REQUEST VALIDATION
// ======================================================
IF NOT VI_Enable_Request THEN
    VO_Deny_Reason := E_Runtime_Observer_Deny_Reason.RODR_NO_ENABLE_REQUEST;
    VO_Deny_Text := 'Observer enable request is not active';
    RETURN;
END_IF;

// ======================================================
// GOVERNANCE VALIDATION
// ======================================================
IF NOT VI_Bootstrap_Mode THEN
    VO_Deny_Reason := E_Runtime_Observer_Deny_Reason.RODR_BOOTSTRAP_DISABLED;
    VO_Deny_Text := 'Bootstrap mode required for observer authorization';
    VO_Status_Code := 100;
    VO_Status_Text := 'Bootstrap mode required for observer authorization';
    RETURN;
END_IF;

IF NOT VI_Passive_Mode THEN
    VO_Deny_Reason := E_Runtime_Observer_Deny_Reason.RODR_PASSIVE_MODE_DISABLED;
    VO_Deny_Text := 'Passive mode required for observer authorization';
    VO_Status_Code := 110;
    VO_Status_Text := 'Passive mode required for observer authorization';
    RETURN;
END_IF;

IF NOT VI_ReadOnly_Mode THEN
    VO_Deny_Reason := E_Runtime_Observer_Deny_Reason.RODR_READONLY_MODE_DISABLED;
    VO_Deny_Text := 'Read-only mode required for observer authorization';
    VO_Status_Code := 120;
    VO_Status_Text := 'Read-only mode required for observer authorization';
    RETURN;
END_IF;

IF NOT VI_Governance_Locked THEN
    VO_Deny_Reason := E_Runtime_Observer_Deny_Reason.RODR_GOVERNANCE_UNLOCKED;
    VO_Deny_Text := 'Governance lock required for observer authorization';
    VO_Status_Code := 130;
    VO_Status_Text := 'Governance lock required for observer authorization';
    RETURN;
END_IF;

IF NOT VI_Runtime_Authority_Disabled THEN
    VO_Deny_Reason := E_Runtime_Observer_Deny_Reason.RODR_RUNTIME_AUTHORITY_ENABLED;
    VO_Deny_Text := 'Runtime authority isolation required';
    VO_Status_Code := 140;
    VO_Status_Text := 'Runtime authority isolation required';
    RETURN;
END_IF;

IF NOT VI_Writable_Exports_Disabled THEN
    VO_Deny_Reason := E_Runtime_Observer_Deny_Reason.RODR_WRITABLE_EXPORTS_ENABLED;
    VO_Deny_Text := 'Writable exports must remain disabled';
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

VO_Deny_Reason := E_Runtime_Observer_Deny_Reason.RODR_NONE;
VO_Deny_Text := 'No deny reason';

VO_Status_Code := 1;
VO_Status_Text := 'Heating runtime observer authorization granted';

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Observer_Authorization <<<
