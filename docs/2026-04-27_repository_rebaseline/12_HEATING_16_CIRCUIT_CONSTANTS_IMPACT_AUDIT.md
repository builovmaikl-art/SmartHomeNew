# 12 - Heating 16 Circuit Constants Impact Audit

Date: 2026-04-28

Purpose: analytical impact audit before changing heating circuit count from 8 to 16 according to the updated technical specification.

---

## Verification mode

```text
Analytical repository verification only
No runtime/build claim in this document
No code change in this document
```

---

## Source facts

From `ТЗ обновлен.txt`:

```text
Heating circuits: 16
Manifolds: 5
```

Distribution:

```text
Manifold 1 basement: 2 circuits
Manifold 2 1F: 4 circuits
Manifold 3 2F: 3 circuits
Manifold 4 2F: 3 circuits
Manifold 5 1F: 4 circuits
Total: 16 circuits
```

Current code fact:

```text
GVL_CONSTANTS.C_MAX_HEATING_CIRCUITS = 8
```

---

## Main conclusion

The project is currently built around an 8-heating-circuit runtime contract.

Changing to 16 is not a single constant edit.

---

## REGRESSION FINDING

```text
FINDING-HC-01:
Heating circuit count regression

Observed:
Code models 8 heating circuits

Required (ТЗ):
16 heating circuits

Conclusion:
This is a regression / drift from original system requirements

Impact:
- Half of system not represented
- Policy works on incomplete topology
- Heating decisions structurally incorrect

Required action:
Restore 16-circuit contract across system

Priority: CRITICAL
```

---

## Current status

```text
16-circuit requirement: confirmed by ТЗ
Current code: 8-circuit contract
Impact: high
Runtime code change: not yet applied
Next: migration changeset plan
```