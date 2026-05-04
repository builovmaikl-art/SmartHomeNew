FUNCTION IS_REAL_VALID : BOOL
VAR_INPUT
    value : REAL;
END_VAR

// simple NaN / range guard
IS_REAL_VALID := (value > -1.0e6) AND (value < 1.0e6);

END_FUNCTION
