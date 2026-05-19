PROGRAM PRG_Domain_Execution_Policy_Periodic
// Observational periodic due gates for domain execution policy.
// Does not gate execution and does not write physical outputs.
VAR
    fbAccessDue : FB_Periodic_Due_Gate;
    fbLightingDue : FB_Periodic_Due_Gate;
    fbWaterDue : FB_Periodic_Due_Gate;
    fbHeatingDue : FB_Periodic_Due_Gate;
    fbVentDue : FB_Periodic_Due_Gate;
    fbSimulationDue : FB_Periodic_Due_Gate;
END_VAR

fbAccessDue(
    VI_Enable := GVL_DOMAIN_EXECUTION_POLICY.Access_Periodic_Run,
    VI_Now_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_Interval_MS := GVL_DOMAIN_EXECUTION_POLICY.Access_Periodic_Interval_MS
);
GVL_DOMAIN_EXECUTION_POLICY.Access_Periodic_Due := fbAccessDue.VO_Due;

fbLightingDue(
    VI_Enable := GVL_DOMAIN_EXECUTION_POLICY.Lighting_Periodic_Run,
    VI_Now_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_Interval_MS := GVL_DOMAIN_EXECUTION_POLICY.Lighting_Periodic_Interval_MS
);
GVL_DOMAIN_EXECUTION_POLICY.Lighting_Periodic_Due := fbLightingDue.VO_Due;

fbWaterDue(
    VI_Enable := GVL_DOMAIN_EXECUTION_POLICY.Water_Periodic_Run,
    VI_Now_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_Interval_MS := GVL_DOMAIN_EXECUTION_POLICY.Water_Periodic_Interval_MS
);
GVL_DOMAIN_EXECUTION_POLICY.Water_Periodic_Due := fbWaterDue.VO_Due;

fbHeatingDue(
    VI_Enable := GVL_DOMAIN_EXECUTION_POLICY.Heating_Periodic_Run,
    VI_Now_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_Interval_MS := GVL_DOMAIN_EXECUTION_POLICY.Heating_Periodic_Interval_MS
);
GVL_DOMAIN_EXECUTION_POLICY.Heating_Periodic_Due := fbHeatingDue.VO_Due;

fbVentDue(
    VI_Enable := GVL_DOMAIN_EXECUTION_POLICY.Vent_Periodic_Run,
    VI_Now_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_Interval_MS := GVL_DOMAIN_EXECUTION_POLICY.Vent_Periodic_Interval_MS
);
GVL_DOMAIN_EXECUTION_POLICY.Vent_Periodic_Due := fbVentDue.VO_Due;

fbSimulationDue(
    VI_Enable := GVL_DOMAIN_EXECUTION_POLICY.Simulation_Run_Allowed,
    VI_Now_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_Interval_MS := GVL_DOMAIN_EXECUTION_POLICY.Simulation_Periodic_Interval_MS
);
GVL_DOMAIN_EXECUTION_POLICY.Simulation_Periodic_Due := fbSimulationDue.VO_Due;

GVL_DOMAIN_EXECUTION_POLICY.Any_Periodic_Due :=
    GVL_DOMAIN_EXECUTION_POLICY.Access_Periodic_Due
    OR GVL_DOMAIN_EXECUTION_POLICY.Lighting_Periodic_Due
    OR GVL_DOMAIN_EXECUTION_POLICY.Water_Periodic_Due
    OR GVL_DOMAIN_EXECUTION_POLICY.Heating_Periodic_Due
    OR GVL_DOMAIN_EXECUTION_POLICY.Vent_Periodic_Due
    OR GVL_DOMAIN_EXECUTION_POLICY.Simulation_Periodic_Due;

// >>> BULK_SYNC_ANCHOR: PRG_Domain_Execution_Policy_Periodic <<<
END_PROGRAM
