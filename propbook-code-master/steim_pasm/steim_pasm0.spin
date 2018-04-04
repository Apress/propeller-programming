{* 
 * steim_pasm0 - template for compression/decompression
 *}

CON
    CODE08 = %01
    CODE16 = %10
    CODE24 = %11

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
       
PUB COMPRESS(psampsBuf, ns, ppackBuf, pcomprCodeBuf) : ncompr
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

PUB DECOMPRESS(psampsBuf, ns, ppackBuf, ncompr, pcomprCodesBuf) : ndecomp 
    return 0
     
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

  call #GET_SAMPLE
  call #HANDLE_SAMP0

  ' signal completion
  wrlong _cncompr, _cncomprPtr      
    
  ' wait for another compression request  
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


' const
_ccode24 long CODE24
_ccode16 long CODE16
_ccode08 long CODE08
    
_cnsPtr res 1
_cncomprPtr res 1
_csampsbufPtr res 1
_cpackbufPtr res 1
_ccomprcodebufPtr res 1

_cns res 1
_cncompr res 1
_csamp res 1
_ccomprcode res 1

r0 res 1

    FIT 496
