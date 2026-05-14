FUNCTION_BLOCK FB_Heating_Runtime_Meta_Supervision_Publisher
VAR_INPUT
    VI_Enable : BOOL;
    VI_Runtime_Observation_Valid : BOOL;
    VI_Runtime_Observer_Ready : BOOL;
    VI_Runtime_Observer_Fault : BOOL;
    VI_Runtime_Status_Code : UINT;
    VI_Runtime_Status_Text : STRING(128);
END_VAR
VAR_OUTPUT
    VO_Meta : ST_Heating_Runtime_Meta_Supervision;
    VO_Publication_Valid : BOOL;
END_VAR

VO_Meta.Meta_Analytics_Visible := FALSE;
VO_Meta.Meta_Analytics_Degraded := FALSE;
VO_Meta.Meta_Analytics_Attention := FALSE;

VO_Meta.Supervision_Integrity_Visible := FALSE;
VO_Meta.Supervision_Integrity_Observation := 0;

VO_Meta.Adaptive_Drift_Visible := FALSE;
VO_Meta.Adaptive_Drift_Observation := 0;

VO_Meta.Confidence_Degradation_Visible := FALSE;
VO_Meta.Confidence_Degradation_Observation := 0;

VO_Meta.Analytics_Consistency_Visible := FALSE;
VO_Meta.Analytics_Consistency_Observation := 0;

VO_Meta.Sequencing_Meta_Observation := FALSE;
VO_Meta.Ownership_Meta_Observation := FALSE;
VO_Meta.Synchronization_Meta_Observation := FALSE;

VO_Meta.Status_Code := 0;
VO_Meta.Status_Text := 'Heating runtime meta supervision inactive';

VO_Publication_Valid := FALSE;

IF NOT VI_Enable THEN
    RETURN;
END_IF;

VO_Meta.Meta_Analytics_Visible := TRUE;
VO_Meta.Supervision_Integrity_Visible := TRUE;
VO_Meta.Adaptive_Drift_Visible := TRUE;
VO_Meta.Confidence_Degradation_Visible := TRUE;
VO_Meta.Analytics_Consistency_Visible := TRUE;

VO_Meta.Sequencing_Meta_Observation := VI_Runtime_Observation_Valid;
VO_Meta.Ownership_Meta_Observation := VI_Runtime_Observer_Ready;
VO_Meta.Synchronization_Meta_Observation := NOT VI_Runtime_Observer_Fault;

IF VI_Runtime_Observer_Fault THEN
    VO_Meta.Meta_Analytics_Degraded := TRUE;
    VO_Meta.Meta_Analytics_Attention := TRUE;
    VO_Meta.Supervision_Integrity_Observation := 900;
ELSIF NOT VI_Runtime_Observation_Valid THEN
    VO_Meta.Meta_Analytics_Attention := TRUE;
    VO_Meta.Supervision_Integrity_Observation := 200;
ELSE
    VO_Meta.Supervision_Integrity_Observation := 1;
END_IF;

VO_Meta.Status_Code := VI_Runtime_Status_Code;
VO_Meta.Status_Text := VI_Runtime_Status_Text;

VO_Publication_Valid := TRUE;

END_FUNCTION_BLOCK
// >>> BULK_SYNC_ANCHOR: FB_Heating_Runtime_Meta_Supervision_Publisher <<<
