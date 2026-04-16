# Migration Checklist

1. Freeze current FB_Rule_Engine behavior
2. Verify both adapters compile in staging
3. Verify roundtrip translation for representative rules
4. Only then decide insertion point in active runtime
5. Keep downstream legacy action contract unchanged at first insertion
