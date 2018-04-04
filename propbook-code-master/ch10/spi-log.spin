{* -*- Spin -*- *}
{* spi-log.spin - worker file for spi logging from PASM *}
CON
  _CLKMODE = XTAL1 + PLL16X
  _XINFREQ = 6_250_000

  ONE_SEC  = ((_clkmode - xtal1) >> 6) * _xinfreq  ' system freq as a constan
  ONE_MS      = ONE_SEC / 1_000                    ' ticks in 1ms
  ONE_US      = ONE_SEC / 1_000_000                 ' ticks in 1us

CON ' Pin map
  REQ = 0
  CS  = 1
  CLK = 2
  MOSI = 3
  MISO = 4

  CSMASK = |<CS
  CLKMASK = |<CLK

VAR
  byte lcogid

PUB INIT
  lcogid := -1

PUB START
  STOP
  lcogid := cognew(@SPILOG, 0)
  return lcogid

PUB STOP
  if lcogid <> -1
     cogstop(lcogid)
  
DAT 'spilog
SPILOG ORG 0

  call #SETUP_PINS
  mov _clogVal, #42
  call #WRITE_SPI
:loop
  jmp #:loop

SETUP_PINS
  mov dira, #0
  mov r0, #0 wz
  muxz outa, _ccsMask ' raise cs
  muxz dira, _ccsMask ' set to output

  muxnz outa, _cclkMask
  muxz dira, _cclkMask

  muxnz outa, _cmosiMask
  muxz dira, _cmosiMask
SETUP_PINS_ret ret

WRITE_SPI
  waitpeq _creqMask, _creqMask
  mov r0, #32 wz
  mov _cdt, cnt
  add _cdt, _cEighthMS
  waitcnt _cdt, _cEighthMS

  ' lower cs
  xor outa, _ccsMask 

  ' tx 32 bits, lsb first
:spiloop
  rol _clogVal, #1 wc   ' set C
  muxc outa, _cmosiMask ' set mosi

  muxnz outa, _cclkMask ' raise clock
  waitcnt _cdt, _cEighthMS
  xor outa, _cclkMask   ' lower clock
  waitcnt _cdt, _cEighthMS
  djnz r0, #:spiloop

  ' raise cs
  xor outa, _ccsMask
WRITE_SPI_ret ret

_cdt long 0
_cOneSec long ONE_SEC
_cOneMS long ONE_MS
_cOneUS long ONE_US
_cEighthMS long ONE_MS >> 3

_creqMask long |<REQ
_ccsMask long |<CS
_cclkMask long |<CLK
_cmosiMask long |<MOSI

_clogVal res 1

_cx0 res 1
_cx1 res 1
_cf res 1
r0 res 1
r1 res 1
tmp res 1