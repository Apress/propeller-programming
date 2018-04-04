{* -*- Spin -*- *}
{* spin_template.spin *}

CON ' Clock mode settings
  _CLKMODE = XTAL1 + PLL16X
  _XINFREQ = 6_250_000

  ' system freq as a constant
  FULL_SPEED  = ((_clkmode - xtal1) >> 6) * _xinfreq  
  ONE_MS      = FULL_SPEED / 1_000    ' ticks in 1ms
  ONE_US      = FULL_SPEED / 1_000_00 ' ticks in 1us

CON ' Pin map

  DEBUG_TX_TO   = 30
  DEBUG_RX_FROM = 31

  BLUE = 10 ' blue led

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

VAR
  byte mainCogId, serialCogId
  
PUB MAIN

  mainCogId     := cogid
  LAUNCH_SERIAL_COG
  PAUSE_MS(500)

  UARTS.STR(DEBUG, string("Toggle", CR, LF))
  UARTS.STR(DEBUG, string("mainCogId:     "))
  UARTS.DEC(DEBUG, mainCogId)
  UARTS.PUTC(DEBUG, CR)  
  UARTS.PUTC(DEBUG, LF)  
  
  DIRA~           ' set all pins low (no output)
  OUTA[BLUE] := 0 ' set pin 10 low
  DIRA[BLUE] := 1 ' set pin 10 to output
  repeat 
    !OUTA[BLUE]   ' toggle pin 10
    PAUSE_MS(1000)
  
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
