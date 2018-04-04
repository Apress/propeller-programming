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

' set a local variable to the max num of samps possible.
PUB INIT(nsmax)
    mymax := nsmax
    ccogid := -1

' start a new cog - stop an old one if necessary.
PUB START
    STOP
    ' myns <> 0 controls when the compression is started
    myns := 0

    {** Here is where the new cog is started.  @STEIM is the
     ** address of the pasm code and @myns is the address of the
     ** variable to be passed to steim through par...
     **}
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

' this does nothing for now...
PUB DECOMPRESS(psampsBuf, ns, ppackBuf, ncompr, pcomprCodesBuf) : ndecomp 
    return 0
     
DAT 'steim
''
''

'' pasm code here
STEIM org 0
  ' copy the param addresses
  mov _cnsPtr, par
  mov _cncomprPtr, par
  add _cncomprPtr, #4
   
:mainLoop
  ' the signal for starting the compression is when ns <> 0
  rdlong _cns, _cnsPtr wz
  if_z jmp #:mainLoop


  ' signal completion
  mov _cncompr, #3
  wrlong _cncompr, _cncomprPtr      
    
  ' wait for another compression request  
  jmp #:mainLoop

' const
_ccode24 long CODE24
_ccode16 long CODE16
_ccode08 long CODE08
    
_cnsPtr res 1
_cncomprPtr res 1

_cns res 1
_cncompr res 1

r0 res 1

    FIT 496
