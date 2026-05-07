// ==============================================================================
// Heating runtime anomaly severity classifier
// Read-only runtime anomaly severity classification layer.
// ==============================================================================
FUNCTION_BLOCK FB_Heating_Runtime_Anomaly_Severity_Classifier
VAR_INPUT
    VI_Enable : BOOL;
    VI_Anomaly : ST_Heating_Runtime_Anomaly;
END_VAR
VAR_OUTPUT
    VO_Severity_Level : UINT;
    VO_Critical_Anomaly : BOOL;

    VO_Status_Code : UINT;
    VO_Status_Text : STRING(128);
END_VAR

VO_Severity_Level := 0;
VO_Critical_Anomaly := FALSE;

VO_Status_Code := 0;
VO_Status_Text := 'Heating runtime anomaly severity classifier disabled';

IF NOT VI_Enable THEN
    RETURN;
END_IF;

IF VI_Anomaly.Ownership_Invalid OR
   VI_Anomaly.Sequencing_Invalid OR
   VI_Anomaly.Synchronization_Invalid THEN

    VO_Severity_Level := 100;
    VO_Critical_Anomaly := TRUE;

    VO_Status_Code := 900;
    VO_Status_Text := 'Heating runtime anomaly critical';

ELSIF VI_Anomaly.Runtime_Degraded OR
       VI_Anomaly.Cascade_Degraded OR
       VI_Anomaly.OpenTherm_Transport_Degraded THEN

    VO_Severity_Level := 50;

    VO_Status_Code := 200;
    VO_Status_Text := 'Heating runtime anomaly degraded';

ELSIF VI_Anomaly.Anomaly_Active THEN

    VO_Severity_Level := 10;

    VO_Status_Code := 100;
    VO_Status_Text := 'Heating runtime anomaly detected';

ELSE
    VO_Severity_Level := 0;

    VO_Status_Code := 1;
    VO_Status_Text := 'Heating runtime anomaly nominal';
END_IF;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Anomaly_Severity_Classifier <<<
