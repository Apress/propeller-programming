{* -*- Spin -*- *}
{* tdd_0.spin 
 * demo tdd
 *}

CON ' Clock mode settings
  _CLKMODE = XTAL1 + PLL16X
  _XINFREQ = 6_250_000

  FULL_SPEED  = ((_clkmode - xtal1) >> 6) * _xinfreq  ' system freq as a constant
  ONE_MS      = FULL_SPEED / 1_000                    ' ticks in 1ms
  ONE_US      = FULL_SPEED / 1_000_00                 ' ticks in 1us

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
  TDD : "TestDrivenDevelopment"

VAR
  byte mainCogId, serialCogId, logCogId
  long nTest, nPass, nFail
  long s

PUB MAIN

  mainCogId     := cogid
  LAUNCH_SERIAL_COG
  PAUSE_MS(500)
  
  TDD.INIT(DEBUG)
  TEST_THAT_SQR_2_IS_4
  TEST_THAT_SQR_BIG_IS_NEG1
  TEST_THAT_SQR_NEG_BIG_IS_NEG1
  TDD.SUMMARIZE

PUB SQR(x) | t
  t := x ** x ' multiply and return high
  if t
     return -1
  return x*x       

PUB TEST_THAT_SQR_2_IS_4 | t0
  t0 := 4 == SQR(2)
  return TDD.ASSERT_TRUTHY(t0, string("Test that SQR(2) == 4"))

PUB TEST_THAT_SQR_BIG_IS_NEG1 | t0, sq
  t0 := -1 == SQR(1<<30)
  return TDD.ASSERT_TRUTHY(t0, string("Test that SQR(big) == -1"))

PUB TEST_THAT_SQR_NEG_BIG_IS_NEG1 | t0, sq
  t0 := -1 == SQR(-(1<<30))
  return TDD.ASSERT_TRUTHY(t0, string("Test that SQR(-big) == -1"))

PRI LAUNCH_SERIAL_COG
'' method that sets up the serial ports
  NUM.INIT
  UARTS.INIT
  UARTS.ADDPORT(DEBUG, DEBUG_RX_FROM, DEBUG_TX_TO, -1, -1, 0, %000000, DEBUG_BAUD)    'Add DEBUG port
  UARTS.START
  serialCogId    := UARTS.GETCOGID                                               'Start the ports
  PAUSE_MS(300)

PRI PAUSE_MS(mS)
  waitcnt(clkfreq/1000 * mS + cnt)

' Program ends here
