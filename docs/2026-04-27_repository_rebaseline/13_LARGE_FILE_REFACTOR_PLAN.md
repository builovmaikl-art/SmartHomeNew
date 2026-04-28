# 13 - Large File Refactor Plan

Date: 2026-04-28

## Problem

Large ST files became an operational risk during the 16 heating circuit migration.

Main candidates:

```text
FB_Heating_System_Manager.st
PRG_System.st
```

## Decision

```text
FB_Heating_System_Manager: active refactor candidate.
PRG_System: do not split yet; only map sections / add anchors when needed.
```

## Principle

```text
Prepare first, connect later.
```

Meaning:

```text
1. Create small helper FB files first.
2. Keep FB_Heating_System_Manager as public facade.
3. Do not change external manager interface during internal refactor.
4. Connect one helper block per changeset.
5. Compile after each connection.
```

## FB_Heating_System_Manager target split

```text
1. FB_Heating_Adaptive_Target
2. FB_Heating_Safety_Gate
3. FB_Heating_Circuit_Control
4. FB_Heating_Manifold_Control
5. FB_Heating_Boiler_Control
6. FB_Heating_Diagnostics_Projector
```

Current status:

```text
FB_Heating_Adaptive_Target.st created.
Not connected yet.
```

## Rules

```text
Do not touch PRG_System during internal FB_Heating refactor.
Do not change GVL_STATE / ST_System_State_Snapshot contracts.
Do not replace large ST files through API if repository output is truncated.
Use narrow terminal patch + migration_logs + immediate re-read for large-file connection steps.
```
