PROGRAM PRG_System_Intent
VAR
    fbSystemIntentPublisher : FB_System_Intent_Publisher;
    L_Gateway_Writes_Allowed : BOOL;
END_VAR

// Extracted from PRG_System (Phase 5A).
// Idempotent projection: safe to run while legacy call still exists.
L_Gateway_Writes_Allowed :=
    NOT GVL_STATUS.G_Diagnostics.Dangerous_Action_Pending_Confirm AND
    NOT GVL_STATUS.G_Diagnostics.Operator_Action_Blocked AND
    NOT GVL_STATUS.G_Diagnostics.User_Access_Denied;

fbSystemIntentPublisher(
    VI_System_Time_MS := GVL_TIME_SERVICE.G_Now_MS,
    VI_Gateway_Writes_Allowed := L_Gateway_Writes_Allowed
);

END_PROGRAM
