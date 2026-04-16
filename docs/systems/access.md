# Access

## Role
Access control is subordinate to `System Mode` and contributes communication-related degradation upward.

## Behavioral Rules
- `NORMAL`: normal operator commands allowed per access policy.
- `DEGRADED`: dangerous actions remain restricted by system policy.
- `SAFE_STOP`: opening actions are blocked; protective actions remain subject to design rules.

## Diagnostics Contract
- Access may publish communication/auth-related degradation upward.
- Access does not arbitrate global mode.
