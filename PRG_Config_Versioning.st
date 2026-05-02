PROGRAM PRG_Config_Versioning
VAR
    L_Computed_Checksum : UDINT;
END_VAR

// --- Simple checksum (placeholder sum) ---
L_Computed_Checksum := UDINT_TO_UINT(GVL_CONFIG.G_Active_Zones_Count);
L_Computed_Checksum := L_Computed_Checksum + UDINT_TO_UINT(GVL_CONFIG.Weather_Coef * 100.0);

GVL_Config_Versioning.G_Config_Current_Checksum := L_Computed_Checksum;

// --- Detect invalid config ---
IF GVL_DIAGNOSTICS.G_Config_Error THEN
    GVL_Config_Versioning.G_Config_Invalid_Detected := TRUE;
END_IF;

// --- Trigger rollback ---
IF GVL_Config_Versioning.G_Config_Invalid_Detected THEN
    GVL_Config_Versioning.G_Config_Rollback_Requested := TRUE;
END_IF;

// --- Execute rollback ---
IF GVL_Config_Versioning.G_Config_Rollback_Requested THEN
    GVL_Config_Versioning.G_Config_Rollback_Active := TRUE;

    // Restore last known good version (simplified placeholder)
    GVL_Config_Versioning.G_Config_Current_Version := GVL_Config_Versioning.G_Config_Last_Good_Version;
    GVL_Config_Versioning.G_Config_Current_Checksum := GVL_Config_Versioning.G_Config_Last_Good_Checksum;

    // Reset flags
    GVL_Config_Versioning.G_Config_Rollback_Requested := FALSE;
    GVL_Config_Versioning.G_Config_Invalid_Detected := FALSE;
END_IF;

// --- Update last good config ---
IF NOT GVL_DIAGNOSTICS.G_Config_Error THEN
    GVL_Config_Versioning.G_Config_Last_Good_Version := GVL_Config_Versioning.G_Config_Current_Version;
    GVL_Config_Versioning.G_Config_Last_Good_Checksum := GVL_Config_Versioning.G_Config_Current_Checksum;
END_IF;

END_PROGRAM
