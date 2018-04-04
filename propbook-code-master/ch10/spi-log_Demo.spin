{* -*- Spin -*- *}
{* spi-log_Demo.spin - driver for spi-logging from PASM *}

CON ' Clock mode settings
  _CLKMODE = XTAL1 + PLL16X
  _XINFREQ = 6_250_000

  FULL_SPEED  = ((_clkmode - xtal1) >> 6) * _xinfreq  ' system freq as a constant
  ONE_MS      = FULL_SPEED / 1_000                    ' ticks in 1ms
  ONE_US      = FULL_SPEED / 1_000_000                 ' ticks in 1us

CON ' Pin map

  DEBUG_TX_TO   = 30
  DEBUG_RX_FROM = 31

  REQ = 0
  CS  = 1
  CLK = 2
  MOSI = 3
  MISO = 4

  CSMASK = |<CS
  CLKMASK = |<CLK

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
  SPILOG    : "spi-log"
  
VAR
  byte mainCogId, serialCogId, logCogId
  
PUB MAIN | f, x, x0, logVal

  mainCogId     := cogid
  LAUNCH_SERIAL_COG
  PAUSE_MS(500)

  logCogId := -1
  UARTS.STR(DEBUG, string(CR, LF, "mainCogId:     "))
  UARTS.DEC(DEBUG, mainCogId)
  UARTS.PUTC(DEBUG, CR)
  UARTS.PUTC(DEBUG, LF)

  ' set the REQ line low and then set it to be an output
  outa[REQ] := 0
  dira~~ ' all lines in
  dira[REQ] := 1 ' req out

  SPILOG.INIT
  logCogId := SPILOG.START
  UARTS.STR(DEBUG, string(CR, LF, "logCogId:     "))
  UARTS.DEC(DEBUG, logCogId)
  UARTS.PUTC(DEBUG, CR)
  UARTS.PUTC(DEBUG, LF)

  ' wait here until PASM cog sets CS line high
  waitpeq(CSMASK, CSMASK, 0)

  ' OK ready for SPI
  outa[REQ] := 1 ' assert req
  repeat
    ' wait for cs mask to go low
    waitpne(CSMASK, CSMASK, 0)
    !outa[REQ] ' lower req 
    logVal := READ_SPILOG ' read 32 bits

    ' print out logval
    UARTS.HEX(DEBUG, logVal, 8)
    UARTS.PUTC(DEBUG, CR)
    UARTS.PUTC(DEBUG, LF)

    !outa[REQ] ' raise req

' READ_SPILOG
' Call this as soon as CS goes low
' returns 32 bit long
PUB READ_SPILOG : logVal | i,b
  logVal := 0
  repeat 32
    waitpeq(CLKMASK, CLKMASK, 0)
    b := INA[MOSI]
    waitpne(CLKMASK, CLKMASK, 0)
    logVal <<= 1
    logVal |= b

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
