# Redundancy Shadow Scope

## Goal
Prepare the first real CoreKernel logic slice as a shadow-only extraction.

## Source
PRG_System core kernel mapping:
- fbRedundancy call region
- synced state application region

## Rules
- no runtime integration
- no GVL writes in this step
- capture structure only
