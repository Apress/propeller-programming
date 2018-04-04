#include <stdio.h>
#include <propeller.h>

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
  extern unsigned int binary_compr1_dat_start[];
  return cognew(binary_compr1_dat_start, parptr);
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
  
  comprCogId = startComprPASMCog(&locker);
  if(comprCogId < 0) {
    printf("error starting compr cog\n");
    while(1) {;}
  }          

  printf("started compression cog %d\n", comprCogId);
  
  /* start the compression cog by setting nsamps to 1 */
  sampsBuf[0] = 0xEFCDAB;
  locker.nsamps = 1; //= cogmem.locker.nsamps = 1;
  
  /* wait until the compression cog sets ncompr to a non-neg number */
  while(locker.ncompr < 0) {
    ;
  }
  
  printf("done... nsamps = %d, ncompr = %d\n", locker.nsamps, locker.ncompr);
  printf("samp0 = %x, packBuf = %x %x %x\n", sampsBuf[0], packBuf[0], packBuf[1], packBuf[2]);
 
  for(i=0; i<NSAMPS_MAX; i++) {
    sampsBuf[i] = 100000*(i+1000);
  }
  
  locker.ncompr=-1;
  t0 = CNT;
  locker.nsamps=128;
  /* wait until the compression cog sets ncompr to a non-neg number */
  while(locker.ncompr < 0) {
    ;
  }
  t0 = CNT - t0;
  printf("nsamps = %d, ncompr = %d\n", locker.nsamps, locker.ncompr);
  printf("dt = %d\n", t0);
 
  while(1)
  {
    // Add main loop code here.
    
  }  
}
