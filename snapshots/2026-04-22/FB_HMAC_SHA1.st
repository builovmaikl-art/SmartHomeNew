FUNCTION_BLOCK FB_HMAC_SHA1
VAR_INPUT
    KeyLength : INT;
    MessageLength : INT;
END_VAR
VAR_IN_OUT
    Key : ARRAY[0..63] OF BYTE;
    Message : ARRAY[0..7] OF BYTE;
END_VAR
VAR_OUTPUT
    Hash : ARRAY[0..19] OF BYTE;
    Done : BOOL;
END_VAR
VAR
    i : INT;
    K_ipad : ARRAY[0..63] OF BYTE;
    K_opad : ARRAY[0..63] OF BYTE;
    InnerData : ARRAY[0..127] OF BYTE; // 64 (ipad) + 8 (msg)
    OuterData : ARRAY[0..127] OF BYTE; // 64 (opad) + 20 (inner hash)
    InnerHash : ARRAY[0..19] OF BYTE;
    FB_SHA1_Inner : FB_SHA1;
    FB_SHA1_Outer : FB_SHA1;
END_VAR

// 1. Prepare K_ipad and K_opad
FOR i := 0 TO 63 DO
    IF i < KeyLength THEN
        K_ipad[i] := Key[i] XOR 16#36;
        K_opad[i] := Key[i] XOR 16#5C;
    ELSE
        K_ipad[i] := 16#36;
        K_opad[i] := 16#5C;
    END_IF;
END_FOR;

// 2. Inner Hash: SHA1(K_ipad || Message)
FOR i := 0 TO 63 DO
    InnerData[i] := K_ipad[i];
END_FOR;
FOR i := 0 TO MessageLength - 1 DO
    InnerData[64 + i] := Message[i];
END_FOR;

FB_SHA1_Inner(Data := InnerData, Length := 64 + MessageLength, Hash => InnerHash);

// 3. Outer Hash: SHA1(K_opad || InnerHash)
FOR i := 0 TO 63 DO
    OuterData[i] := K_opad[i];
END_FOR;
FOR i := 0 TO 19 DO
    OuterData[64 + i] := InnerHash[i];
END_FOR;

FB_SHA1_Outer(Data := OuterData, Length := 84, Hash => Hash);

Done := TRUE;