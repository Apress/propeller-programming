{* -*- Spin -*- *}
{* steim_pasm0_Demo.spin *}

CON ' Clock mode settings
  _CLKMODE = XTAL1 + PLL16X
  _XINFREQ = 6_250_000

  ' system freq as a constant
  FULL_SPEED  = ((_clkmode - xtal1) >> 6) * _xinfreq
  ONE_MS      = FULL_SPEED / 1_000      ' ticks in 1ms
  ONE_US      = FULL_SPEED / 1_000_000  ' ticks in 1us

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
  '1 COG for 3 serial ports
  UARTS     : "FullDuplexSerial4portPlus_0v3" 
  NUM       : "Numbers"     'Object for writing numbers to debug
  COMPR     : "steim_pasm0"

CON
  NSAMPS_MAX = 128

VAR
  long nsamps, ncompr
  long sampsBuf[NSAMPS_MAX]
  long comprCodeBuf[NSAMPS_MAX >> 4]

  byte mainCogId, serialCogId, comprCogId
  byte packBuf[NSAMPS_MAX << 2]

PUB MAIN

    ' main cog
    mainCogId     := cogid

    ' uart cog
    LAUNCH_SERIAL_COG
    PAUSE_MS(500)
    
    UARTS.STR(DEBUG, string(CR, "Compression", CR, LF))
    UARTS.STR(DEBUG, string("mainCogId:     "))
    UARTS.DEC(DEBUG, mainCogId)
    UARTS.PUTC(DEBUG, CR)  
    UARTS.PUTC(DEBUG, LF)  

    ' compression cog
    COMPR.INIT(NSAMPS_MAX)
    comprCogId := COMPR.START

    UARTS.STR(DEBUG, string("comprCogId:     "))
    UARTS.DEC(DEBUG, comprCogId)
    UARTS.PUTC(DEBUG, CR)  
    UARTS.PUTC(DEBUG, LF)  

    nsamps := 1
    ncompr := COMPR.COMPRESS(@sampsBuf, nsamps, @packBuf, @comprCodeBuf)
    
    UARTS.STR(DEBUG, string("ncompr:     "))
    UARTS.DEC(DEBUG, ncompr)
    UARTS.PUTC(DEBUG, CR)  
    UARTS.PUTC(DEBUG, LF)  
    repeat
      PAUSE_MS(1000)

PRI LAUNCH_SERIAL_COG
'' method that sets up the serial ports
  NUM.INIT
  UARTS.INIT
  UARTS.ADDPORT(DEBUG,    DEBUG_RX_FROM, DEBUG_TX_TO, -1, -1, 0, %000000, DEBUG_BAUD)    'Add DEBUG port
  UARTS.START
  serialCogId    := UARTS.GETCOGID 'Start the serial ports
  PAUSE_MS(300)

PRI PAUSE_MS(mS)
  waitcnt(clkfreq/1000 * mS + cnt)

' Program ends here
