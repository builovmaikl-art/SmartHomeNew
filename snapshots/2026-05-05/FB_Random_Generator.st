FUNCTION_BLOCK FB_Random_Generator
VAR
    L_seed : UDINT := 1;
    L_Is_Seeded : BOOL := FALSE;
END_VAR
VAR CONSTANT
    C_LCG_MULTIPLIER : UDINT := 1664525;
    C_LCG_INCREMENT  : UDINT := 1013904223;
    C_LCG_MODULUS    : LREAL := 4294967296.0;
END_VAR

METHOD Seed : BOOL
VAR_INPUT
    VI_Seed_Value : UDINT;
END_VAR
L_seed := VI_Seed_Value;
L_Is_Seeded := TRUE;
Seed := TRUE;
END_METHOD

METHOD Random_Int_Range : UDINT
VAR_INPUT
    VI_min : UDINT;
    VI_max : UDINT;
    VI_System_Time_MS : UDINT; // Для автоматического сидирования
END_VAR
VAR
    L_range : UDINT;
    L_rand_factor : LREAL;
END_VAR

IF NOT L_Is_Seeded AND VI_System_Time_MS > 0 THEN
    L_seed := VI_System_Time_MS;
    L_Is_Seeded := TRUE;
END_IF;

L_seed := (C_LCG_MULTIPLIER * L_seed) + C_LCG_INCREMENT;

IF VI_max > VI_min THEN
        L_range := VI_max - VI_min;
        // Используем LREAL для точности и исключения выхода за границу
        L_rand_factor := TO_LREAL(L_seed) / C_LCG_MODULUS;
        Random_Int_Range := VI_min + TO_UDINT(L_rand_factor * TO_LREAL(L_range + 1));
        
        // Финальная защита от переполнения
        IF Random_Int_Range > VI_max THEN
            Random_Int_Range := VI_max;
        END_IF;
    ELSE
        Random_Int_Range := VI_min;
    END_IF;
END_FUNCTION_BLOCK
