{* -*- Spin -*- *}
{* io2-pasm.spin - toggle an output pin with PASM code *}

CON ' Clock mode settings
  _CLKMODE = XTAL1 + PLL16X
  _XINFREQ = 6_250_000

  ' system freq as a constant
  FULL_SPEED  = ((_clkmode - xtal1) >> 6) * _xinfreq
  ONE_SEC     = _CLKFREQ
  ONE_MS      = FULL_SPEED / 1_000    ' ticks in 1ms
  ONE_US      = FULL_SPEED / 1_000_00 ' ticks in 1us

CON ' Pin map

  DEBUG_TX_TO   = 30
  DEBUG_RX_FROM = 31

  BLUE = 10 ' blue led
  SW = 11   ' normally open, high
  SWMASK = |< SW  ' set pin <SW> high 
  INPIN = 12

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
  byte rdpinCogId
  
PUB MAIN

  mainCogId     := cogid
  LAUNCH_SERIAL_COG
  PAUSE_MS(500)

  UARTS.STR(DEBUG, string("PASM Read", CR, LF))
  UARTS.STR(DEBUG, string("mainCogId:     "))
  UARTS.DEC(DEBUG, mainCogId)
  UARTS.PUTC(DEBUG, CR)  
  UARTS.PUTC(DEBUG, LF)

  rdpinCogId := cognew(@RDPIN, 0)
  UARTS.STR(DEBUG, string("rdpinCogId:     "))
  UARTS.DEC(DEBUG, rdpinCogId)
  UARTS.PUTC(DEBUG, CR)  
  UARTS.PUTC(DEBUG, LF)
  
  
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

DAT '' RDPIN

RDPIN ORG 0
  mov dira, #0 wz ' set all pins to input
  muxnz outa, _cblueMask ' set pin low 
  muxz dira, _cblueMask ' set led pin to output

  mov r0, cnt
  add r0, _coneSec
:loop
  waitcnt r0, _coneSec
  xor outa, _cblueMask
  jmp #:loop

_cblueMask long |<BLUE
_cswMask long |<SW
_coneSec long ONESEC
r0 res 1
FIT 496

' Program ends here
