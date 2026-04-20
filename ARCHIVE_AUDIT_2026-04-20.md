# ARCHIVE AUDIT — 2026-04-20

Purpose: preserve a root-level working memory of what was moved into `archive/` during cleanup, so the repository does not lose track of potentially valuable blocks.

This file is intentionally stored in the repository root to stay visible during future refactor sessions.

## Summary
- Total archived `.st` blocks reviewed: **12**
- Unintegrated controllers: **6**
- Good ideas not integrated: **5**
- Needs manual review: **1**

## 1. Unintegrated controllers
- `archive/fb_unintegrated_controllers/FB_Exhaust_Ventilation_Controller.st` — Function block `FB_Exhaust_Ventilation_Controller` archived after cleanup; has explicit FB-style interface
- `archive/fb_unintegrated_controllers/FB_Gas_Valve_Controller.st` — Function block `FB_Gas_Valve_Controller` archived after cleanup; has explicit FB-style interface
- `archive/fb_unintegrated_controllers/FB_Manifold_Pump_Controller.st` — Function block `FB_Manifold_Pump_Controller` archived after cleanup; has explicit FB-style interface
- `archive/fb_unintegrated_controllers/FB_Outdoor_Lighting_Controller.st` — Function block `FB_Outdoor_Lighting_Controller` archived after cleanup; has explicit FB-style interface
- `archive/fb_unintegrated_controllers/FB_Supply_Ventilation_Controller.st` — Function block `FB_Supply_Ventilation_Controller` archived after cleanup; has explicit FB-style interface
- `archive/fb_unintegrated_controllers/FB_Water_Valve_Controller.st` — Function block `FB_Water_Valve_Controller` archived after cleanup; has explicit FB-style interface

## 2. Good ideas / not integrated yet
- `archive/fb_ideas/FB_Maintenance_Access.st` — Function block `FB_Maintenance_Access` archived after cleanup; has explicit FB-style interface
- `archive/fb_ideas/FB_Presence_Simulator.st` — Function block `FB_Presence_Simulator` archived after cleanup; has explicit FB-style interface
- `archive/fb_ideas/FB_Sensor_Distribution.st` — Function block `FB_Sensor_Distribution` archived after cleanup; has explicit FB-style interface
- `archive/fb_ideas/FB_State_Snapshot_NVRAM.st` — Function block `FB_State_Snapshot_NVRAM` archived after cleanup; has explicit FB-style interface
- `archive/fb_ideas/FB_Zone_Access_Manager.st` — Function block `FB_Zone_Access_Manager` archived after cleanup; has explicit FB-style interface

## 3. Needs manual review
- `archive/fb_ideas/FB_Pre_Departure_Heating.st` — Function block `FB_Pre_Departure_Heating` archived after cleanup; has explicit FB-style interface

## 4. Recommended interpretation
- `unintegrated_controller`: do not restore directly into the root; reintroduce only through manager/policy orchestration.
- `good_idea_not_integrated`: preserve as a feature shortlist for future controlled integration.
- `needs_manual_review`: inspect individually before any delete/restore decision.

## 5. Current recommendation
- Keep `archive/` as a quarantine zone, not as live code.
- Use this file as the single visible entry point for archived design assets.
- Any future resurrection must happen through a deterministic step with compile verification.

