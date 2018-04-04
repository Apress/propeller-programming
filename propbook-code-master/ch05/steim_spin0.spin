{* steim_spin_start.spin
 * Start the steim compression by setting up...
 *}
CON
    CODE08 = %01
    CODE16 = %10
    CODE24 = %11

VAR
    long _nsmax
 
PUB INIT(nsmax)
'' Set the max length of the input samples array
    _nsmax := nsmax
    
PUB COMPRESS(psampsBuf, ns, ppackBuf, pcomprCodesBuf) : ncompr | j, diff, adiff, codeIdx, codeShift
'' Inputs:
''   psampsBuf - address of sampsBuf array (long array).
''   ns - length of `sampsBuf` (number of samps to compress).
''   ppackBuf - address of `packBuf` array (byte array) where samples are to be packed.
''   pcomprCodesBuf - address of array of compresion codes (long array) - 16 codes per long.
'' Output:
''   ncompr - length of packed array (bytes)
    if ns == 0 ' this isn't an error - but do nothing
        return 0
        
    if (ns < 0) | (ns > _nsmax)
        return -1
    
    ' handle sample0 first - it is always packed to 3 bytes regardless of its size
    bytemove(ppackBuf, psampsBuf, 3)    
    ncompr := 3
    long[pcomprCodesBuf] := CODE24
        
    if ns == 1
        return ncompr

    return -1

' Program ends here
