PROGRAM PRG_Behavior_Adapt_Profile

// Centralized tuning profile controller.
// This block enforces consistent adaptive behavior settings.

CASE GVL_BEHAVIOR_ADAPT.G_Adapt_Profile OF

    ADAPT_PROFILE_STABLE:
        GVL_BEHAVIOR_ADAPT.G_Adapt_Learning_Rate := 0.03;
        GVL_BEHAVIOR_ADAPT.G_Confidence_Learning_Rate := 0.03;
        GVL_BEHAVIOR_ADAPT.G_Decay_Factor := 0.998;
        GVL_BEHAVIOR_ADAPT.G_Adapt_Update_Threshold := 7;

        GVL_BEHAVIOR_ADAPT.G_Behavior_Weight_Comfort := 1.0;
        GVL_BEHAVIOR_ADAPT.G_Behavior_Weight_Night := 1.0;
        GVL_BEHAVIOR_ADAPT.G_Behavior_Weight_Preheat := 1.0;
        GVL_BEHAVIOR_ADAPT.G_Behavior_Weight_VentBoost := 0.9;
        GVL_BEHAVIOR_ADAPT.G_Behavior_Weight_AccessSecure := 1.0;

    ADAPT_PROFILE_BALANCED:
        GVL_BEHAVIOR_ADAPT.G_Adapt_Learning_Rate := 0.05;
        GVL_BEHAVIOR_ADAPT.G_Confidence_Learning_Rate := 0.05;
        GVL_BEHAVIOR_ADAPT.G_Decay_Factor := 0.995;
        GVL_BEHAVIOR_ADAPT.G_Adapt_Update_Threshold := 5;

        GVL_BEHAVIOR_ADAPT.G_Behavior_Weight_Comfort := 1.0;
        GVL_BEHAVIOR_ADAPT.G_Behavior_Weight_Night := 1.0;
        GVL_BEHAVIOR_ADAPT.G_Behavior_Weight_Preheat := 1.0;
        GVL_BEHAVIOR_ADAPT.G_Behavior_Weight_VentBoost := 1.0;
        GVL_BEHAVIOR_ADAPT.G_Behavior_Weight_AccessSecure := 1.0;

    ADAPT_PROFILE_AGGRESSIVE:
        GVL_BEHAVIOR_ADAPT.G_Adapt_Learning_Rate := 0.08;
        GVL_BEHAVIOR_ADAPT.G_Confidence_Learning_Rate := 0.08;
        GVL_BEHAVIOR_ADAPT.G_Decay_Factor := 0.990;
        GVL_BEHAVIOR_ADAPT.G_Adapt_Update_Threshold := 3;

        GVL_BEHAVIOR_ADAPT.G_Behavior_Weight_Comfort := 1.0;
        GVL_BEHAVIOR_ADAPT.G_Behavior_Weight_Night := 1.0;
        GVL_BEHAVIOR_ADAPT.G_Behavior_Weight_Preheat := 1.0;
        GVL_BEHAVIOR_ADAPT.G_Behavior_Weight_VentBoost := 1.1;
        GVL_BEHAVIOR_ADAPT.G_Behavior_Weight_AccessSecure := 1.0;

ELSE
        // No fallback required
END_CASE;

// >>> BULK_SYNC_ANCHOR: PRG_Behavior_Adapt_Profile <<<
END_PROGRAM
