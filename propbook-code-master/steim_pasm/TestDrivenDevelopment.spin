{ Test Driven Development }

VAR
    byte debug, nTest, nPass, nFail

OBJ
  UARTS     : "FullDuplexSerial4portPlus_0v3"       '1 COG for 3 serial ports

DAT
  OK byte "...ok", 13, 10, 0
  FAIL byte "***FAIL", 13, 10, 0

PUB INIT(debugport)
    debug := debugport
    nTest := nPass := nFail := 0

PUB ASSERT_TRUTHY(condition, msg)
    nTest++
    UARTS.PUTC(debug, 13)
    UARTS.PUTC(debug, 10)
    UARTS.STR(debug, msg)
    UARTS.PUTC(debug, 13)
    UARTS.PUTC(debug, 10)
    'UARTS.DEC(debug, t)
    if condition <> 0
       UARTS.STR(debug, @OK)
       nPass++
       return TRUE
    else
       UARTS.STR(debug, @FAIL)
       nFail++
       return FALSE

PUB SUMMARIZE
  UARTS.STR(DEBUG, string("Tests Run: "))
  UARTS.DEC(DEBUG, nTest)
  UARTS.PUTC(DEBUG, 13)  
  UARTS.PUTC(DEBUG, 10)  
  UARTS.STR(DEBUG, string("Tests Passed: "))
  UARTS.DEC(DEBUG, nPass)
  UARTS.PUTC(DEBUG, 13)  
  UARTS.PUTC(DEBUG, 10)  
  UARTS.STR(DEBUG, string("Tests Failed: "))
  UARTS.DEC(DEBUG, nFail)
  UARTS.PUTC(DEBUG, 13)  
  UARTS.PUTC(DEBUG, 10)  
