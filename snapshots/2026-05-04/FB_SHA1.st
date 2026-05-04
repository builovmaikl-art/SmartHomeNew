FUNCTION_BLOCK FB_SHA1
VAR_INPUT
    Length : INT;
END_VAR
VAR_IN_OUT
    Data : ARRAY[0..127] OF BYTE;
END_VAR
VAR_OUTPUT
    Hash : ARRAY[0..19] OF BYTE;
END_VAR
VAR
    H0, H1, H2, H3, H4 : DWORD;
    A, B, C, D, E, F, K, Temp : DWORD;
    W : ARRAY[0..79] OF DWORD;
    i, j, t : INT;
    PaddedData : ARRAY[0..127] OF BYTE;
    PaddedLength : INT;
    NumBlocks : INT;
    BlockOffset : INT;
END_VAR

// Initialize variables
H0 := 16#67452301;
H1 := 16#EFCDAB89;
H2 := 16#98BADCFE;
H3 := 16#10325476;
H4 := 16#C3D2E1F0;

// Pre-processing
FOR i := 0 TO Length - 1 DO
    PaddedData[i] := Data[i];
END_FOR;

// Append the bit '1' to the message
PaddedData[Length] := 16#80;

// Append 0 <= k < 512 bits '0', such that the resulting message length in bits
// is congruent to -64 ≡ 448 (mod 512)
PaddedLength := Length + 1;
WHILE (PaddedLength MOD 64) <> 56 DO
    PaddedData[PaddedLength] := 0;
    PaddedLength := PaddedLength + 1;
END_WHILE;

// Append length of message (before pre-processing), in bits, as 64-bit big-endian integer
// Since our message is small (max 127 bytes), we only need the lower 32 bits
Temp := TO_DWORD(Length * 8);
PaddedData[PaddedLength] := 0;
PaddedData[PaddedLength+1] := 0;
PaddedData[PaddedLength+2] := 0;
PaddedData[PaddedLength+3] := 0;
PaddedData[PaddedLength+4] := TO_BYTE(SHR(Temp, 24));
PaddedData[PaddedLength+5] := TO_BYTE(SHR(Temp, 16));
PaddedData[PaddedLength+6] := TO_BYTE(SHR(Temp, 8));
PaddedData[PaddedLength+7] := TO_BYTE(Temp);
PaddedLength := PaddedLength + 8;

NumBlocks := PaddedLength / 64;

// Process the message in successive 512-bit chunks
FOR i := 0 TO NumBlocks - 1 DO
    BlockOffset := i * 64;
    
    // Break chunk into sixteen 32-bit big-endian words w[i], 0 <= i <= 15
    FOR j := 0 TO 15 DO
        W[j] := SHL(TO_DWORD(PaddedData[BlockOffset + j*4]), 24) OR
                SHL(TO_DWORD(PaddedData[BlockOffset + j*4 + 1]), 16) OR
                SHL(TO_DWORD(PaddedData[BlockOffset + j*4 + 2]), 8) OR
                TO_DWORD(PaddedData[BlockOffset + j*4 + 3]);
    END_FOR;
    
    // Message schedule: extend the sixteen 32-bit words into eighty 32-bit words
    FOR j := 16 TO 79 DO
        Temp := W[j-3] XOR W[j-8] XOR W[j-14] XOR W[j-16];
        W[j] := SHL(Temp, 1) OR SHR(Temp, 31); // Left rotate by 1
    END_FOR;
    
    // Initialize hash value for this chunk
    A := H0;
    B := H1;
    C := H2;
    D := H3;
    E := H4;
    
    // Main loop
    FOR j := 0 TO 79 DO
        IF j <= 19 THEN
            F := (B AND C) OR ((NOT B) AND D);
            K := 16#5A827999;
        ELSIF j <= 39 THEN
            F := B XOR C XOR D;
            K := 16#6ED9EBA1;
        ELSIF j <= 59 THEN
            F := (B AND C) OR (B AND D) OR (C AND D);
            K := 16#8F1BBCDC;
        ELSE
            F := B XOR C XOR D;
            K := 16#CA62C1D6;
        END_IF;
        
        Temp := (SHL(A, 5) OR SHR(A, 27)) + F + E + K + W[j];
        E := D;
        D := C;
        C := SHL(B, 30) OR SHR(B, 2);
        B := A;
        A := Temp;
    END_FOR;
    
    // Add this chunk's hash to result so far
    H0 := H0 + A;
    H1 := H1 + B;
    H2 := H2 + C;
    H3 := H3 + D;
    H4 := H4 + E;
END_FOR;

// Produce the final hash value (big-endian)
Hash[0] := TO_BYTE(SHR(H0, 24)); Hash[1] := TO_BYTE(SHR(H0, 16)); Hash[2] := TO_BYTE(SHR(H0, 8)); Hash[3] := TO_BYTE(H0);
Hash[4] := TO_BYTE(SHR(H1, 24)); Hash[5] := TO_BYTE(SHR(H1, 16)); Hash[6] := TO_BYTE(SHR(H1, 8)); Hash[7] := TO_BYTE(H1);
Hash[8] := TO_BYTE(SHR(H2, 24)); Hash[9] := TO_BYTE(SHR(H2, 16)); Hash[10] := TO_BYTE(SHR(H2, 8)); Hash[11] := TO_BYTE(H2);
Hash[12] := TO_BYTE(SHR(H3, 24)); Hash[13] := TO_BYTE(SHR(H3, 16)); Hash[14] := TO_BYTE(SHR(H3, 8)); Hash[15] := TO_BYTE(H3);
Hash[16] := TO_BYTE(SHR(H4, 24)); Hash[17] := TO_BYTE(SHR(H4, 16)); Hash[18] := TO_BYTE(SHR(H4, 8)); Hash[19] := TO_BYTE(H4);
END_FUNCTION_BLOCK
