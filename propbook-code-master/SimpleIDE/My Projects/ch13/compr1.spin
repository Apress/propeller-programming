CON
    CODE08 = %01
    CODE16 = %10
    CODE24 = %11

PUB START(locker)
  cognew(@STEIM, locker)
  
DAT 'STEIM
''
''
     
STEIM org 0
  ' copy the param addresses
  mov _cnsPtr, par
  mov _cncomprPtr, par
  add _cncomprPtr, #4
   
:mainLoop
  ' the signal for starting the compression is when ns <> 0
  rdlong _cns, _cnsPtr wz
  if_z jmp #:mainLoop

  ' get the array start addresses
  mov r0, par
  add r0, #8
  rdlong _csampsbufPtr, r0

  mov r0, par
  add r0, #12
  rdlong _cpackbufPtr, r0

  mov r0, par
  add r0, #16
  rdlong _ccomprcodebufPtr, r0

  mov _cj, #0 ' j-th samp
  ' there are 16 codes in each code word
  ' there are NSAMPS_LONG/16 code longs (e.g., 8 codelongs for 128 samps)
  ' samps 0-15 have their codes in _ccodebufptr[0], 
  ' samps 16-31 have their codes in _ccodebufptr[1], etc
  ' _ccodebitidx is the location within a long (0, 2, 4, ... 30)
  ' _ccodelongidx is the idx of the long in the code array 
  mov _ccodebitidx, #0 
  mov _ccodelongidx, #0 

  call #GET_SAMPLE
  mov _cprev, _csamp  ' save sample for diff
  call #HANDLE_SAMP0
  add _ccodebitidx, #2

  sub _cns, #1 wz
  if_z jmp #:done

:loopns
  call #GET_SAMPLE
  call #HANDLE_SAMPJ
  mov _cprev, _csamp
  add _cj, #1

  add _ccodebitidx, #2
  test _ccodebitidx, #31 wz
  if_nz jmp #:samelong

  wrlong _ccomprcode, _ccomprcodebufPtr
  add _ccomprcodebufPtr, #4
  mov _ccomprcode, #0

:samelong
  djnz _cns, #:loopns

:done
  wrlong _ccomprcode, _ccomprcodebufPtr
  ' signal completion
  wrlong _cncompr, _cncomprPtr      
    
  ' wait for another compression request
  wrlong _cns, _cnsPtr
  jmp #:mainLoop

GET_SAMPLE
'' read a sample from sampsBuf
'' modifies samp
'' increments sampsbufPtr to next sample
  rdlong _csamp, _csampsbufPtr
  add _csampsbufPtr, #4
GET_SAMPLE_ret ret

HANDLE_SAMP0
'' write the three bytes of samp to packbuf
'' write code24 to comprcodebuf[0]
'' destroys samp
'' modifies ncompr

  mov r0, #3
:s0loop
  wrbyte _csamp, _cpackbufPtr
  add _cpackbufPtr, #1
  shr _csamp, #8
  djnz r0, #:s0loop
  mov _cncompr, #3
  mov _ccomprcode, _ccode24
  wrlong _ccomprcode, _ccomprcodebufPtr
HANDLE_SAMP0_ret ret

HANDLE_SAMPJ
'' form difference between j and j-1 samps
'' determine byte-length of diff
'' save diff to packbuf
'' increment ncompr appropriately
'' modify comprcode appropriately
    ' subtract: samp - prev
    mov _cdiff, _csamp
    sub _cdiff, _cprev

    ' write a byte and check if more need to be written
    ' repeat as necessary
    ' r0 - running count of number of bytes used by diff
    ' r1 - compr code - updated as more bytes are used
    ' r2 - abs value of cdiff
    wrbyte _cdiff, _cpackbufptr
    add _cpackbufptr, #1
    mov r0, #1
    mov r1, _ccode08
    ' is  -127 < cdiff < 127
    abs r2, _cdiff    
    cmp r2, _onebyte wc,wz
    if_c_or_z jmp #:donej

    ' write 2nd byte
    shr _cdiff, #8	
    wrbyte _cdiff, _cpackbufptr
    add _cpackbufptr, #1
    add r0, #1
    mov r1, _ccode16
    ' is -32K < cdiff < 32k
    cmp r2, _twobyte wc,wz
    if_c_or_z jmp #:donej

    ' must be 3 bytes long...	
    shr _cdiff, #8
    wrbyte _cdiff, _cpackbufptr
    add _cpackbufptr, #1
    add r0, #1
    mov r1, _ccode24

:donej
    add _cncompr, r0 ' add number of bytes seen here to ncompr
    rol r1, _ccodebitidx
    or _ccomprcode, r1
    
HANDLE_SAMPJ_ret ret


' const
_ccode24 long CODE24
_ccode16 long CODE16
_ccode08 long CODE08
_onebyte long $7F
_twobyte long $7F_FF
    
_cnsPtr res 1
_cncomprPtr res 1
_csampsbufPtr res 1
_cpackbufPtr res 1
_ccomprcodebufPtr res 1

_cns res 1
_cncompr res 1
_csamp res 1
_ccomprcode res 1
_cj res 1
_cprev res 1
_cdiff res 1
_ccodebitidx res 1
_ccodelongidx res 1

r0 res 1
r1 res 1
r2 res 1

FIT 496
