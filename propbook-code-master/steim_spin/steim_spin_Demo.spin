{* -*- Spin -*- *}
{* spin_template.spin *}

CON ' Clock mode settings
  _CLKMODE = XTAL1 + PLL16X
  _XINFREQ = 6_250_000

  FULL_SPEED  = ((_clkmode - xtal1) >> 6) * _xinfreq  ' system freq as a constant
  ONE_MS      = FULL_SPEED / 1_000                    ' ticks in 1ms
  ONE_US      = FULL_SPEED / 1_000_000                 ' ticks in 1us

CON ' Pin map

  DEBUG_TX_TO   = 30
  DEBUG_RX_FROM = 31

CON ' UART ports
  DEBUG             =      0
  DEBUG_BAUD        = 115200

  UART_SIZE         =    100
  CR                =     13
  LF                =     10
  SPACE             =     32
  TAB               =      9
  COLON             =     58
  COMMA             =     44
  
OBJ
  UARTS     : "FullDuplexSerial4portPlus_0v3"       '1 COG for 3 serial ports
  NUM       : "Numbers"     'Object for writing numbers to debug
  STEIM : "steim_spin"
  TDD : "TestDrivenDevelopment"

CON
  NSAMPS_MAX = 128

VAR
  byte mainCogId, serialCogId, comprCogId
  byte nsamps, ncompr

  byte packBuf[NSAMPS_MAX << 2]
  long sampsBuf[NSAMPS_MAX]
  long comprCodeBuf[NSAMPS_MAX >> 4]

PUB MAIN | d, t0, dt, nc, j
    
    mainCogId     := cogid
    LAUNCH_SERIAL_COG
    PAUSE_MS(500)
    
    UARTS.STR(DEBUG, string(CR, "Compression", CR, LF))
    UARTS.STR(DEBUG, string("mainCogId:     "))
    UARTS.DEC(DEBUG, mainCogId)
    UARTS.PUTC(DEBUG, CR)  
    UARTS.PUTC(DEBUG, LF)  
      
    STEIM.INIT(NSAMPS_MAX, DEBUG)
    TDD.INIT(DEBUG)
{    TEST_THAT_SAMP0_IS_PROPERLY_PACKED
    TEST_THAT_SAMP0_SETS_NCOMPR_CORRECTLY
    TEST_THAT_SAMP0_SETS_COMPRCODE_CORRECTLY
    TEST_THAT_COMPRESSOR_FAILS_FOR_NSAMPS_WRONG
    TEST_THAT_SAMP1_IS_PROPERLY_PACKED_ONE_BYTE
    TEST_THAT_SAMP1_IS_PROPERLY_PACKED_TWO_BYTES
    'TEST_THAT_SAMP1_IS_PROPERLY_PACKED_THREE_BYTES
    TEST_THAT_SAMP1_SETS_COMPRCODE_CORRECTLY
    TEST_THAT_SAMP1_SETS_COMPRCODE_CORRECTLY_TWO_BYTES
    TEST_THAT_SAMP15_PACKS_PROPERLY
    TEST_THAT_SAMP16_PACKS_PROPERLY
    TEST_THAT_SAMP127_PACKS_PROPERLY

    TEST_THAT_SAMP0_IS_PROPERLY_UNPACKED
    TEST_THAT_SAMP1_IS_PROPERLY_UNPACKED
    TEST_THAT_128_SAMPS_PROPERLY_COMPRESS_AND_DECOMPRESS_1000_TIMES
    
    TDD.SUMMARIZE
}
    ' time
    nsamps := 128
    longfill(@sampsBuf, 0, 128)

    repeat j from 0 to nsamps-1
      sampsBuf[j] := j * 50000

    sampsBuf[126] := $AB
    d := -42
    sampsBuf[127] := $AB + d 

    t0 := cnt
    nc := STEIM.COMPRESS(@sampsBuf, nsamps, @packBuf, @comprCodeBuf)
    dt := cnt - t0
    repeat j from 0 to nc-1
      UARTS.DEC(DEBUG, j)
      UARTS.PUTC(DEBUG, COLON)
      UARTS.HEX(DEBUG, packBuf[j], 2)
      UARTS.PUTC(DEBUG, CR)
    UARTS.STR(DEBUG, string("nc=  "))
    UARTS.DEC(DEBUG, nc)
    UARTS.PUTC(DEBUG, CR)
    UARTS.STR(DEBUG, string("dt=  "))
    UARTS.DEC(DEBUG, dt)
    UARTS.PUTC(DEBUG, CR)
    UARTS.STR(DEBUG, string("dt (ms) ~  "))
    UARTS.DEC(DEBUG, dt / ONE_MS)
    UARTS.PUTC(DEBUG, CR)


    repeat
      PAUSE_MS(1000)
    
PRI TEST_THAT_SAMP0_IS_PROPERLY_PACKED | t0, nc
  nsamps := 1
  sampsBuf[0] := $AB_CD_EF  
  nc := STEIM.COMPRESS(@sampsBuf, nsamps, @packBuf, @comprCodeBuf)
  t0 := nc <> -1 
  t0 &= (packBuf[0] == sampsBuf[0] & $FF)
  t0 &= (packBuf[1] == sampsBuf[0] >> 8 & $FF) 
  t0 &= (packBuf[2] == sampsBuf[0] >> 16 & $FF)
  TDD.ASSERT_TRUTHY(t0, string("Test that sample 0 is properly packed to packBuf"))

PRI TEST_THAT_SAMP0_IS_PROPERLY_UNPACKED | t0, nc, ns, d
  nsamps := 1
  d := $FF_FF_AB_CD
  sampsBuf[0] := d
  nc := STEIM.COMPRESS(@sampsBuf, nsamps, @packBuf, @comprCodeBuf)
  sampsBuf[0] := 0

  UARTS.PUTC(DEBUG, 13)
  UARTS.PUTC(DEBUG, 10)
  UARTS.HEX(DEBUG, packBuf[0], 2)
  UARTS.HEX(DEBUG, packBuf[1], 2)
  UARTS.HEX(DEBUG, packBuf[2], 2)

  ns := STEIM.DECOMPRESS(@sampsBuf, nsamps, @packBuf, nc, @comprCodeBuf)
  UARTS.PUTC(DEBUG, 13)
  UARTS.PUTC(DEBUG, 10)
  UARTS.HEX(DEBUG, sampsBuf[0], 8)

  t0 := (ns == 1) & (sampsBuf[0] == d)
  TDD.ASSERT_TRUTHY(t0, string("Test that sample 0 is properly unpacked from packBuf"))

PRI TEST_THAT_SAMP1_IS_PROPERLY_UNPACKED | t0, nc, ns, d
  nsamps := 2
  d := $FA_4F_2E
  sampsBuf[0] := $FA_09_19
  sampsBuf[1] := d
  nc := STEIM.COMPRESS(@sampsBuf, nsamps, @packBuf, @comprCodeBuf)
  sampsBuf[0] := 0
  sampsBuf[1] := 0

  UARTS.PUTC(DEBUG, 13)
  UARTS.PUTC(DEBUG, 10)
  UARTS.HEX(DEBUG, packBuf[0], 2)
  UARTS.HEX(DEBUG, packBuf[1], 2)
  UARTS.HEX(DEBUG, packBuf[2], 2)
  UARTS.HEX(DEBUG, packBuf[3], 2)
  UARTS.HEX(DEBUG, packBuf[4], 2)
  UARTS.HEX(DEBUG, packBuf[5], 2)

  ns := STEIM.DECOMPRESS(@sampsBuf, nsamps, @packBuf, nc, @comprCodeBuf)
  UARTS.PUTC(DEBUG, 13)
  UARTS.PUTC(DEBUG, 10)
  UARTS.HEX(DEBUG, sampsBuf[0], 8)
  UARTS.PUTC(DEBUG, 13)
  UARTS.PUTC(DEBUG, 10)
  UARTS.HEX(DEBUG, sampsBuf[1], 8)

  t0 := (ns == 2) & ((sampsBuf[1] & $FF_FF_FF) == $FA_4F_2E)
  TDD.ASSERT_TRUTHY(t0, string("Test that sample 1 is properly unpacked from packBuf"))


PRI TEST_THAT_SAMP0_SETS_NCOMPR_CORRECTLY | t0  
  nsamps := 1
  sampsBuf[0] := $AB_CD_EF  
  t0 := 3 == STEIM.COMPRESS(@sampsBuf, nsamps, @packBuf, @comprCodeBuf)
  TDD.ASSERT_TRUTHY(t0, string("Test that compressor sets ncompr correctly for sample 0"))

PRI TEST_THAT_SAMP0_SETS_COMPRCODE_CORRECTLY | t0, nc  
  nsamps := 1
  sampsBuf[0] := $AB_CD_EF  
  nc := STEIM.COMPRESS(@sampsBuf, nsamps, @packBuf, @comprCodeBuf)
  t0 := nc <> -1 & (comprCodeBuf[0] & %11 == %11)
  TDD.ASSERT_TRUTHY(t0, string("Test that compressor sets compression code correctly for sample 0"))

PUB TEST_THAT_COMPRESSOR_FAILS_FOR_NSAMPS_WRONG | t0
  nsamps := NSAMPS_MAX + 1
  t0 := -1 == STEIM.COMPRESS(@sampsBuf, nsamps, @packBuf, @comprCodeBuf)
  TDD.ASSERT_TRUTHY(t0, string("Test that compressor throws error for nsamps > nsmax"))

PRI TEST_THAT_SAMP1_IS_PROPERLY_PACKED_ONE_BYTE | t0, nc, d
  nsamps := 2
  d := 42
  sampsBuf[0] := $AB_CD_EF
  sampsBuf[1] := sampsBuf[0] + d  
  nc := STEIM.COMPRESS(@sampsBuf, nsamps, @packBuf, @comprCodeBuf)
  t0 := nc <> -1 & (packBuf[3] == d)
  TDD.ASSERT_TRUTHY(t0, string("Test that sample 1 is properly packed to packBuf (1 byte)"))

PRI TEST_THAT_SAMP1_IS_PROPERLY_PACKED_TWO_BYTES | t0, nc,d 
  nsamps := 2
  d := 42
  sampsBuf[0] := $AB_CD_EF
  sampsBuf[1] := sampsBuf[0] + d  
  nc := STEIM.COMPRESS(@sampsBuf, nsamps, @packBuf, @comprCodeBuf)
  t0 := nc <> -1 & (packBuf[3] == d & $FF) & (packBuf[4] == d >> 8 & $FF)
  TDD.ASSERT_TRUTHY(t0, string("Test that sample 1 is properly packed to packBuf (two bytes)"))

PRI TEST_THAT_SAMP1_SETS_COMPRCODE_CORRECTLY | t0, nc  
  nsamps := 2
  sampsBuf[0] := $AB_CD_EF  
  sampsBuf[1] := $AB_CD_EF + $42
  nc := STEIM.COMPRESS(@sampsBuf, nsamps, @packBuf, @comprCodeBuf)
  t0 := nc <> -1 & (comprCodeBuf[1] & %1111 == %0111)
  TDD.ASSERT_TRUTHY(t0, string("Test that compressor sets compression code correctly for sample 1"))

PRI TEST_THAT_SAMP1_SETS_COMPRCODE_CORRECTLY_TWO_BYTES | t0, nc  
  nsamps := 2
  sampsBuf[0] := $AB_CD_EF  
  sampsBuf[1] := $AB_CD_EF + $42_42
  nc := STEIM.COMPRESS(@sampsBuf, nsamps, @packBuf, @comprCodeBuf)
  t0 := nc <> -1 & (comprCodeBuf[1] & %1111 == STEIM#CODE16 << 2 | STEIM#CODE24)
  TDD.ASSERT_TRUTHY(t0, string("Test that compressor sets compression code correctly for sample 1 (2 bytes)"))

PRI TEST_THAT_SAMP15_PACKS_PROPERLY | t0, nc, i, d
  nsamps := 16
  longfill(@sampsBuf, 0, 16)

  sampsBuf[14] := $AB
  d := -42
  sampsBuf[15] := $AB + d 
  nc := STEIM.COMPRESS(@sampsBuf, nsamps, @packBuf, @comprCodeBuf)
  UARTS.BIN(DEBUG, comprCodeBuf[0], 32)
  UARTS.PUTC(DEBUG, 13)
  UARTS.PUTC(DEBUG, 10)
  repeat i from 0 to nc-1
    UARTS.HEX(DEBUG, packBuf[i], 2)
    UARTS.PUTC(DEBUG, SPACE)
  
  t0 := nc == 18
  TDD.ASSERT_TRUTHY(t0, string("Test that compressor sets nc correctly for samp 15"))
  t0 := comprCodeBuf[0] >> 30 == %01 '
  TDD.ASSERT_TRUTHY(t0, string("Test that compressor sets compr code correctly for samp 15"))
  t0 := packBuf[nc-1] == d & $FF
  TDD.ASSERT_TRUTHY(t0, string("Test that compressor sets compr code correctly for samp 15"))

PRI TEST_THAT_SAMP16_PACKS_PROPERLY | t0, nc, i, d
  nsamps := 17
  longfill(@sampsBuf, 0, 17)

  sampsBuf[15] := $AB
  d := -42
  sampsBuf[16] := $AB + d 
  nc := STEIM.COMPRESS(@sampsBuf, nsamps, @packBuf, @comprCodeBuf)
  UARTS.DEC(DEBUG, nc)
  UARTS.PUTC(DEBUG, 13)
  UARTS.PUTC(DEBUG, 10)

  UARTS.BIN(DEBUG, comprCodeBuf[0], 32)
  UARTS.PUTC(DEBUG, 13)
  UARTS.PUTC(DEBUG, 10)
  UARTS.BIN(DEBUG, comprCodeBuf[1], 32)
  UARTS.PUTC(DEBUG, 13)
  UARTS.PUTC(DEBUG, 10)
  repeat i from 0 to nc-1
    UARTS.HEX(DEBUG, packBuf[i], 2)
    UARTS.PUTC(DEBUG, SPACE)
  
  t0 := nc == 19
  TDD.ASSERT_TRUTHY(t0, string("Test that compressor sets nc correctly for samp 16"))
  t0 := comprCodeBuf[1] & %11 == %01 '
  TDD.ASSERT_TRUTHY(t0, string("Test that compressor sets compr code correctly for samp 16"))
  t0 := packBuf[nc-1] == d & $FF
  TDD.ASSERT_TRUTHY(t0, string("Test that compressor sets compr code correctly for samp 16"))

PRI TEST_THAT_SAMP127_PACKS_PROPERLY | t0, nc, i, d
  nsamps := 128
  longfill(@sampsBuf, 0, 128)

  sampsBuf[126] := $AB
  d := -42
  sampsBuf[127] := $AB + d 
  nc := STEIM.COMPRESS(@sampsBuf, nsamps, @packBuf, @comprCodeBuf)
{
  UARTS.DEC(DEBUG, nc)
  UARTS.PUTC(DEBUG, 13)
  UARTS.PUTC(DEBUG, 10)

  UARTS.BIN(DEBUG, comprCodeBuf[0], 32)
  UARTS.PUTC(DEBUG, 13)
  UARTS.PUTC(DEBUG, 10)
  UARTS.BIN(DEBUG, comprCodeBuf[1], 32)
  UARTS.PUTC(DEBUG, 13)
  UARTS.PUTC(DEBUG, 10)
  UARTS.BIN(DEBUG, comprCodeBuf[2], 32)
  UARTS.PUTC(DEBUG, 13)
  UARTS.PUTC(DEBUG, 10)
  UARTS.BIN(DEBUG, comprCodeBuf[3], 32)
  UARTS.PUTC(DEBUG, 13)
  UARTS.PUTC(DEBUG, 10)
  UARTS.BIN(DEBUG, comprCodeBuf[4], 32)
  UARTS.PUTC(DEBUG, 13)
  UARTS.PUTC(DEBUG, 10)
  UARTS.BIN(DEBUG, comprCodeBuf[5], 32)
  UARTS.PUTC(DEBUG, 13)
  UARTS.PUTC(DEBUG, 10)
  UARTS.BIN(DEBUG, comprCodeBuf[6], 32)
  UARTS.PUTC(DEBUG, 13)
  UARTS.PUTC(DEBUG, 10)
  UARTS.BIN(DEBUG, comprCodeBuf[7], 32)
  UARTS.PUTC(DEBUG, 13)
  UARTS.PUTC(DEBUG, 10)
  repeat i from 0 to nc-1
    UARTS.HEX(DEBUG, packBuf[i], 2)
    UARTS.PUTC(DEBUG, SPACE)
}
  t0 := nc == 130
  TDD.ASSERT_TRUTHY(t0, string("Test that compressor sets nc correctly for samp 127"))
  t0 := comprCodeBuf[7] >> 30 == %01 '
  TDD.ASSERT_TRUTHY(t0, string("Test that compressor sets compr code correctly for samp 127"))
  t0 := packBuf[nc-1] == d & $FF
  TDD.ASSERT_TRUTHY(t0, string("Test that compressor sets compr code correctly for samp 127"))

PRI TEST_THAT_128_SAMPS_PROPERLY_COMPRESS_AND_DECOMPRESS_1000_TIMES | t0, t1, j, nc, ns, sav[128]
    nsamps := 128

    
    j := 0
    sampsBuf[j] := cnt ' seed it with counter
    ?sampsBuf[j] ' pseudorandom numbers
    sampsBuf[j] &= $FF_FF_FF ' low 3 bytes only

    sampsBuf[j] <<= 8 ' sign extend 
    sampsBuf[j] ~>= 8
    sav[j] := sampsBuf[j]

    repeat j from 1 to nsamps-1
        sampsBuf[j] := sampsBuf[j-1]
        ?sampsBuf[j] ' pseudorandom numbers
        sampsBuf[j] &= $FF_FF_FF ' low 3 bytes only

        sampsBuf[j] <<= 8 ' sign extend 
	sampsBuf[j] ~>= 8
	    
        sav[j] := sampsBuf[j]
    nc := ns := 0


    nc := STEIM.COMPRESS(@sampsBuf, nsamps, @packBuf, @comprCodeBuf)
    ' clear the presumably unused part of packbuf
    UARTS.PUTC(DEBUG, 13)
    repeat j from 0 to nc-1
        UARTS.DEC(DEBUG, j)
        UARTS.PUTC(DEBUG, COLON)
        UARTS.HEX(DEBUG, packBuf[j], 2)
	UARTS.PUTC(DEBUG, SPACE)
    UARTS.PUTC(DEBUG, 13)
	
    
    repeat j from nc to NSAMPS_MAX * 4 
        packBuf[j] := 0

ns := STEIM.DECOMPRESS(@sampsBuf, nsamps, @packBuf, nc, @comprCodeBuf)
    UARTS.PUTC(DEBUG, 13)
    UARTS.PUTC(DEBUG, 10)

    repeat j from 0 to nsamps-1
        UARTS.PUTC(DEBUG, 13)
        UARTS.PUTC(DEBUG, 10)
        UARTS.DEC(DEBUG, j)
        UARTS.PUTC(DEBUG, COMMA)
        UARTS.HEX(DEBUG, sav[j], 8)
        UARTS.PUTC(DEBUG, COMMA)
        UARTS.HEX(DEBUG, sampsBuf[j], 8)
        
    t0 := (ns == nsamps)
    repeat j from 0 to ns-1
        t1 := (sampsBuf[j] == sav[j])
        if t1 <> TRUE
            UARTS.PUTC(DEBUG, 13)
            UARTS.DEC(DEBUG, j)
            UARTS.PUTC(DEBUG, COMMA)
            UARTS.HEX(DEBUG, sampsBuf[j], 8)

         t0 &= t1
    
    TDD.ASSERT_TRUTHY(t0, string("Test that compression and decompression of 128 random numbers is successful"))
        
  
PRI LAUNCH_SERIAL_COG
'' method that sets up the serial ports
  NUM.INIT
  UARTS.INIT
  UARTS.ADDPORT(DEBUG,    DEBUG_RX_FROM, DEBUG_TX_TO, -1, -1, 0, %000000, DEBUG_BAUD)    'Add DEBUG port
  UARTS.START
  serialCogId    := UARTS.GETCOGID                                               'Start the ports
  PAUSE_MS(300)

PRI PAUSE_MS(mS)
  waitcnt(clkfreq/1000 * mS + cnt)

' Program ends here
