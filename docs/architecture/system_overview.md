# System Architecture Overview

## Current State

System implements centralized policy-driven architecture with diagnostics layer.

Flow:
Subsystems → FB_System_Health → FB_State_Manager → Policy → Subsystems

## Key Components

### FB_System_Health
- Aggregates faults
- Provides root cause (type + source)
- Supports latch and reset

### FB_State_Manager
- Determines system mode
- Consumes only abstract health signals

### Policy Layer
- Implemented in each subsystem
- Reacts to System Mode

## Operating Modes
- NORMAL
- DEGRADED
- FREEZE_PROTECTION
- SAFE_STOP

## Diagnostics Capabilities
- Fault type classification
- Fault source identification
- First fault latching
- Manual and automatic reset
