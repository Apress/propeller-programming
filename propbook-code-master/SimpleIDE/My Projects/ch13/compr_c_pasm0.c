#include <stdio.h>
#include <propeller.h>
#include "tdd.h"

/* defines */

// compression constants
#define NSAMPS_MAX 128

/* global variables */
// reserved space to be passed to startComprPASMCog
volatile struct locker_t {
  int nsamps;
  int ncompr;
  int *psampsBuf;  
  unsigned char *ppackBuf;
  int *pcomprCodesBuf;
} locker; 

volatile int sampsBuf[NSAMPS_MAX]; 
volatile unsigned char packBuf[NSAMPS_MAX<<2]; // 128 * 4
volatile int comprCodesBuf[NSAMPS_MAX>>4]; //128 / 16

int startComprPASMCog(unsigned int *parptr) {
  extern unsigned int binary_compr0_dat_start[];
  return cognew(binary_compr0_dat_start, parptr);
}  


void testThatComprCogStarted(int comprCogId) {
  int tst = comprCogId >= 0;
  assertTruthy(tst, "Test that compression cog started");
  if(!tst) {
    printf("error starting compr cog\n");
    while(1) {;}
  }          
}

void testThatncomprIsSetToNonNegative() {
  int tst;
  /* start the compression cog by setting nsamps to 1 */
  sampsBuf[0] = 0xEFCDAB;
  locker.nsamps = 1; //= cogmem.locker.nsamps = 1;
  
  /* wait until the compression cog sets ncompr to a non-neg number */
  while(locker.ncompr < 0) {
    ;
  }
  assertTruthy(locker.ncompr > 0, "Test the nCompr is set to non-negative");
}

void   testThatSamp0IsProperlyPacked() {
  int tst;
  sampsBuf[0] = 0xABCDEF;
  locker.nsamps = 1;
  while(locker.ncompr < 0) {
    ;
  }    
  tst = locker.ncompr==3;
  tst &= (packBuf[0] == (sampsBuf[0] & 0xFF));
  tst &= (packBuf[1] == (sampsBuf[0]>>8 & 0xFF));
  tst &= (packBuf[2] == (sampsBuf[0]>>16 & 0xFF));
  assertTruthy(tst, "Test that Samp0 is properly packed");
}    

  
/* main cog - initializes variables and starts new cogs.
 * don't exit - start infinite loop as the last thing.
 */
int main(void)
{
  int comprCogId = -1;
  int i;
  unsigned int t0;  
  
  locker.nsamps = 0;
  locker.ncompr = -1;
  locker.psampsBuf = sampsBuf;
  locker.ppackBuf = packBuf;
  locker.pcomprCodesBuf = comprCodesBuf;
  
  printf("starting main\n");
  initTDD();
  
  comprCogId = startComprPASMCog(&locker);
  testThatComprCogStarted(comprCogId); 
  testThatncomprIsSetToNonNegative(); 
  testThatSamp0IsProperlyPacked();
   
  while(1)
  {
    // Add main loop code here.
  }  
}
