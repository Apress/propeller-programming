{* steim_spin_complete.spin 
 * Compress an array of samples by forming differences and packing
 * the differences in the smallest of 1, 2, or 3 bytes
 * Decompress the packed array.
 *}
CON
    CODE08 = %01
    CODE16 = %10
    CODE24 = %11

VAR
    byte _debugPort
    byte _cogid
    
    long _nsmax
    long tmp[16]
OBJ
  UARTS     : "FullDuplexSerial4portPlus_0v3"       '1 COG for 3 serial ports

 
PUB INIT(nsmax, debug)
'' Set the max length of the input samples array
    _nsmax := nsmax
    _debugPort := debug
    
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
    long[pcomprCodesBuf] := %11
        
    if ns == 1
        return ncompr

    repeat j from 1 to ns-1
        diff := long[psampsBuf][j] - long[psampsBuf][j-1]
        adiff := ||diff
        codeIdx := j / 16 
        codeShift := (j // 16) * 2
        if adiff < $7F
            bytemove(ppackBuf + ncompr, @diff, 1) 
            ncompr++
            long[pcomprCodesBuf][codeIdx] |= CODE08 << codeShift
            'UARTS.HEX(_debugPort, byte[ppackBuf][3], 8)
            'UARTS.PUTC(_debugPort, 13)
        elseif adiff < $7FFF
            bytemove(ppackBuf + ncompr, @diff, 2)
            ncompr += 2
            long[pcomprCodesBuf][codeIdx] |= CODE16 << codeShift
            'UARTS.HEX(_debugPort, byte[ppackBuf][3], 8)
            'UARTS.PUTC(_debugPort, 13)
            'UARTS.HEX(_debugPort, byte[ppackBuf][4], 8)
            'UARTS.PUTC(_debugPort, 13)
        else 
            bytemove(ppackBuf + ncompr, @diff, 3)
            ncompr += 3
            long[pcomprCodesBuf][codeIdx] |= CODE24 << codeShift
            'UARTS.HEX(_debugPort, byte[ppackBuf][3], 8)
            'UARTS.PUTC(_debugPort, 13)
            'UARTS.HEX(_debugPort, byte[ppackBuf][4], 8)
            'UARTS.PUTC(_debugPort, 13)
            'UARTS.HEX(_debugPort, byte[ppackBuf][5], 8)
            'UARTS.PUTC(_debugPort, 13)
        
    return ncompr

PUB DECOMPRESS(psampsBuf, ns, ppackBuf, ncompr, pcomprCodesBuf) : ndecomp | diff, pkIdx, codeIdx, codeShift, theComprLong, jcomprCode, pkBytes, shneg, theSamp
'' Inputs:
''   psampsBuf - address of sampsBuf array
''   ns - length of `sampsBuf` (number of samps to decompress)
''   ppackBuf - address of `packBuf` array where samples are packed
''   ncompr - length of packBuf
''   pcomprCodesBuf - array of compresion codes (16 codes per long)
'' Output:
''   ndecomp - number of samples decompressed (should be same as ns)
{
    UARTS.STR(_debugPort, string("ncompr: "))
    UARTS.DEC(_debugPort, ncompr)
    UARTS.PUTC(_debugPort, 13)
    UARTS.PUTC(_debugPort, 10)
    UARTS.DEC(_debugPort, ns)
    UARTS.PUTC(_debugPort, 13)
    UARTS.PUTC(_debugPort, 10)
 }
  
    ' check inputs
    if ns == 0 ' this isn't an error - but do nothing
        return 0

    if (ns < 0) | (ns > _nsmax)
        return -1

    ' init
    ndecomp := 0
    pkIdx := 0

    repeat while ns > ndecomp
        ' codeIdx - index into the comprCodesBuf array where the code for this sample is stored
        ' codeShift - index into the compression code long where the code for this sample is stored
        codeIdx := ndecomp / 16
        codeShift := (ndecomp // 16) * 2

        theComprLong := long[pcomprCodesBuf][codeIdx]
        jcomprCode := (theComprLong >> codeShift) & %11
        'UARTS.BIN(_debugPort, jcomprCode, 2)
        'UARTS.PUTC(_debugPort, 13)
        'UARTS.PUTC(_debugPort, 10)
        case jcomprCode
            CODE08 :
                bytemove(@diff, ppackBuf + pkIdx, 1)
                diff <<=  24 ' sign extend
                diff ~>=  24		
                pkBytes := 1
            CODE16 : 
                bytemove(@diff, ppackBuf + pkIdx, 2)
                diff <<=  16 ' sign extend
                diff ~>=  16		
                pkBytes := 2
            CODE24 : 
                bytemove(@diff, ppackBuf + pkIdx, 3)
                diff <<=  8 ' sign extend
                diff ~>=  8		
                pkBytes := 3

        pkIdx+=pkBytes
        ncompr-=pkBytes

        if ndecomp == 0 ' samp 0 is packed as is - not a difference
            theSamp := diff    
        else 
            theSamp := long[psampsBuf][ndecomp-1] + diff
	theSamp <<= 8
	theSamp ~>= 8
        long[psampsBuf][ndecomp] := theSamp
        ndecomp++
        
        if ncompr < 0 ' error check on ncompr
            return -1
{
    UARTS.HEX(_debugPort, long[psampsBuf][0], 8)
    UARTS.HEX(_debugPort, byte[ppackBuf][1], 2)
    UARTS.HEX(_debugPort, byte[ppackBuf][2], 2)
    UARTS.HEX(_debugPort, byte[ppackBuf][3], 2)
    UARTS.PUTC(_debugPort, 13)
    UARTS.PUTC(_debugPort, 10)   
}
    return ndecomp


' Program ends here
