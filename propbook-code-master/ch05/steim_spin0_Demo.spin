{* -*- Spin -*- *}
{* steim_spin0_Demo.spin *}

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
  STEIM : "steim_spin0"
  TDD : "TestDrivenDevelopment"

CON
  NSAMPS_MAX = 128

VAR
  byte mainCogId, serialCogId
  byte comprCogId
  byte packBuf[NSAMPS_MAX << 2]
  
  long nsamps, ncompr
  long sampsBuf[NSAMPS_MAX]
  long comprCodeBuf[NSAMPS_MAX >> 4]

PUB MAIN 
    mainCogId     := cogid
    LAUNCH_SERIAL_COG
    PAUSE_MS(500)
    
    UARTS.STR(DEBUG, string(CR, "Compression", CR, LF))
    UARTS.STR(DEBUG, string("mainCogId:     "))
    UARTS.DEC(DEBUG, mainCogId)
    UARTS.PUTC(DEBUG, CR)  
    UARTS.PUTC(DEBUG, LF)  
      
    STEIM.INIT(NSAMPS_MAX)
    TDD.INIT(DEBUG)
    TEST_THAT_SAMP0_IS_PROPERLY_PACKED
    TDD.SUMMARIZE

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
  TDD.ASSERT_TRUTHY(t0, string("Test that samp0 is properly packed"))

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
