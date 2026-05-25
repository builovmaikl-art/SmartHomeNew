// ==============================================================================
// System diagnostics helper
//
// Legacy compatibility helper.
//
// IMPORTANT:
// This function block must not write aggregated diagnostics fields directly.
// Aggregated diagnostics ownership is centralized in:
//
//   FB_System_Health_Orchestrator
//
// Protected aggregate fields:
//
//   GVL_STATUS.G_Diagnostics.Sensor_Fault
//   GVL_STATUS.G_Diagnostics.IO_Offline
//   GVL_STATUS.G_Diagnostics.Subsystem_Degraded
//
// This stub is intentionally side-effect free to prevent resurrecting duplicate
// diagnostics aggregate writers from legacy call paths.
// ==============================================================================
FUNCTION_BLOCK FB_System_Diagnostics

// Intentionally side-effect free.
// Diagnostics aggregate projection is owned by FB_System_Health_Orchestrator.

// >>> BULK_SYNC_ANCHOR: FB_System_Diagnostics <<<
END_FUNCTION_BLOCK
