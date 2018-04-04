{* 
 * steim_pasm2 - complete compress/decompress
 *}

CON
    CODE08 = %01
    CODE16 = %10
    CODE24 = %11

OBJ
  UARTS     : "FullDuplexSerial4portPlus_0v3"       '1 COG for 3 serial ports

VAR
 byte ccogid

 long mymax
 long myns, myncompr, sampsBufAddr, packBufAddr, comprCodeBufAddr

PUB INIT(nsmax)
    mymax := nsmax
    ccogid := -1

PUB START
    STOP
    ' myns <> 0 controls when the compression is started
    myns := 0
    ccogid := cognew(@STEIM, @myns)
    return ccogid
    
PUB STOP
     if ccogid <> -1
        cogstop(ccogid)
       
PUB COMPRESS(psampsBuf, ns, ppackBuf, pcomprCodeBuf) : ncompr | j
'' Inputs: psampsBuf - address of long array of samples (max len mymax)
''         ns - number of samples to compress
''         ppackBuf - address of byte array of packed data
''         pcomprCodeBuf - address of long array of compression codes
'' Output: ncompr - number of bytes in packBuf
'' 
'' Modified: packBuf and comprCodeBuf are changed

    myns := 0
    myncompr := 0

    sampsBufAddr := psampsBuf
    packBufAddr := ppackBuf
    comprCodeBufAddr := pcomprCodeBuf

    ' this will start the compression
    myns := ns
   
    ' when ncompr is non-zero, the compression is complete
    repeat until myncompr > 0

    return myncompr

PUB DECOMPRESS(psampsBuf, ns, ppackBuf, ncompr, pcomprcodeBuf) | j
    myns := 0
    myncompr := 0

  sampsBufAddr := psampsBuf
  packBufAddr := ppackBuf
  comprCodeBufAddr := pcomprCodeBuf

    ' this will start the decompression
    ' set to negative ns to trigger decompression
    myns := -ns

    ' when myns is zero, the decompression is complete
    repeat until myns == 0

    return myncompr
     
DAT 'steim
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

  ' check for compression or decompression?
  abs r0, _cns wc ' C set if nsamps < 0
  if_c jmp #:decompress

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

:decompress ' _cns negative
  
  rdlong _ccomprcode, _ccomprcodebufptr
  mov _cncompr, #0
  mov _cj, #0
  
  call #MK_SAMP0
  call #PUT_SAMPLE
    
  add _cj, #1 'sample number j
  add _cns, #1 wz
  if_z jmp #:donedecomp

' and the rest of the samps
:loopdecompns
  call #MK_SAMPJ 
  call #PUT_SAMPLE
  add _cj, #1
  add _cns, #1

  ' every 16th sample, read a new comprcode long
  test _cj, #15 wz
  if_nz jmp #:testns
  add _ccomprcodebufptr, #4
  rdlong _ccomprcode, _ccomprcodebufptr

:testns
  tjnz _cns, #:loopdecompns

:donedecomp
  wrlong _cncompr, _cncomprPtr
  ' signal decompression complete
  wrlong _cns, _cnsPtr
  jmp #:mainLoop    

PUT_SAMPLE
'' put a sample to HUB sampsBuf
    wrlong _csamp, _csampsbufPtr
    add _csampsbufPtr, #4
PUT_SAMPLE_ret ret

MK_SAMP0 ' decompress samp 0
'' read from HUB packbuf to _csamp for samp0 (3 bytes)
    mov r0, #0
    mov _csamp, #0
:read3
    rdbyte r1, _cpackbufPtr
    shl r1, r0 
    or _csamp, r1
    add _cpackbufPtr, #1
    add r0, #8
    cmp r0, #24 wz
    if_nz jmp #:read3

    rol _csamp, #8 ' sign extend
    sar _csamp, #8

    ' update ncompr and code
    add _cncompr, #3
    shr _ccomprcode, #2 ' remove samp0 code...
MK_SAMP0_ret ret

MK_SAMPJ
    mov r0, #0  ' number of bytes
    mov _cdiff, #0
    mov r1, _ccomprcode
    and r1, #3 ' get compr code for this samp. (2 low bits)
    shr _ccomprcode, #2 ' and prep for next loop...
  
    '  byte 0 - right most
    rdbyte r2, _cpackbufPtr
    add _cpackbufPtr, #1
    mov _cdiff, r2
    add r0, #1
    cmp r1, _ccode08 wz  ' check r1 (code) 

    if_z jmp #:shiftde

    ' byte 1
    rdbyte r2, _cpackbufPtr
    add _cpackbufPtr, #1
    rol r2, #8
    or _cdiff, r2
    add r0, #1

    cmp r1, _ccode16 wz
    if_z jmp #:shiftde

    ' byte 2
    rdbyte r2, _cpackbufPtr
    add _cpackbufPtr, #1
    rol r2, #16
    or _cdiff, r2
    add r0, #1

:shiftde
    ' set the sign of the diff correctly by sign extending...
    ' 1 byte diff...
    cmp r0, #1 wz
    if_nz jmp #:sh2
    rol _cdiff, #24 ' sign extend 
    sar _cdiff, #24
    jmp #: donede

    ' 2 byte diff...
:sh2
    cmp r0, #2 wz
    if_nz jmp #:sh3
    rol _cdiff, #16 ' sign extend 
    sar _cdiff, #16
    jmp #: donede

    ' 3 byte diff...
:sh3
    rol _cdiff, #8 ' sign extend 
    sar _cdiff, #8

:donede
    ' add sample to prev
    add _csamp, _cdiff
    ' now mask off the high byte and sign extend the 3 lower
    rol _csamp, #8
    sar _csamp, #8
    add _cncompr, r0 ' update ncompr
MK_SAMPJ_ret ret

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
t0 res 1

    FIT 496
