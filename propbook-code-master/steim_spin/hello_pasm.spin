{* 
 * pasm template for code in a separate file from main
 *}

VAR
  byte ccogid

PUB INIT
  ccogid := -1
     
PUB START
  STOP
  ccogid := cognew(@HELLO, 0)
  return ccogid
    
PUB STOP
  if ccogid <> -1
    cogstop(ccogid)
    ccogid := -1

DAT ' pasm cog HELLO
HELLO ORG 0

:mainLoop
  jmp #: mainLoop

FIT 496

