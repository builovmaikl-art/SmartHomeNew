PROGRAM PRG_Water_Output_Projection
VAR
    fbWaterOutputProjector : FB_Water_Output_Projector;
END_VAR

// Deterministic output projection runtime boundary.
// Single projection owner.
// No semantic/runtime authority.
// Existing global safety path preserved.

fbWaterOutputProjector(
    VI_Enable := TRUE,
    VI_System_Time_MS := GVL_STATUS.G_System_Time_MS
);

// Future runtime bridge:
// authority projection
//   -> runtime arbitration
//   -> physical outputs
//
// Intentionally NOT directly connected yet.
// Projection stabilization first.

END_PROGRAM