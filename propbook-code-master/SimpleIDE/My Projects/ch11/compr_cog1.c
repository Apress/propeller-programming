/*
  compr-cog0.c - start a new cog to perform compression.
*/

/* PART 1 - set up global variables */

/* libraries */
#include <stdio.h>
#include <propeller.h>

/* defines */

// size of stack in bytes
#define STACK_SIZE_BYTES 200
// compression constants
#define NSAMPS_MAX 128
#define CODE08 0b01
#define CODE16 0b10
#define CODE24 0b11
#define TWO_BYTES 0x7F // any diff values greater than this are 2 bytes
#define THREE_BYTES 0x7FF // diff valus greater than this are 3 bytes


/* global variables */
// reserved space to be passed to cogstart
static unsigned int comprCogStack[STACK_SIZE_BYTES >> 2];

// shared vars
volatile int nsamps;
volatile int ncompr;
volatile int sampsBuf[NSAMPS_MAX];
volatile char packBuf[NSAMPS_MAX<<2]; // 128 * 4
volatile int comprCodesBuf[NSAMPS_MAX>>4]; //128 / 16

/* PART 2 - worker cog that will be started by the main cog */

  /* cog code - comprCog
   use nsamps and ncompr to signal with main cog
     start compression when nsamps != 0
     signal completion with ncmopr > 0
     signal error with ncompr = 0
   compress sampsBuf to packBuf
   populate comprCodesBuf - NOT YET DONE
   - args: pointer to memory space PAR - UNUSED
   - return: none
 */
void comprCog(void *p) {
  int i, nc, nbytes, codenum, codeshift, code;
  int diff, adiff;

  while(1) {
    if (nsamps == 0) {
      continue; // loop continuously while nsamps is 0
    } else {
      // perform the compression here
      if (nsamps > NSAMPS_MAX || nsamps < -NSAMPS_MAX) {
        ncompr = 0; // signal error
        nsamps = 0;
        continue;
      }
      for(i=0; i<nsamps; i++) {
        if(i==0) { // first samp
          memcpy(packBuf, (char *)sampsBuf, 3);
          nc = 3;
        } else {
          diff = sampsBuf[i] - sampsBuf[i-1];
          adiff = abs(diff);
          if (adiff < TWO_BYTES) {
            nbytes = 1;
          } else if (adiff < THREE_BYTES) {
            nbytes = 2;
          } else {
            nbytes = 3;
          }
          // copy the correct number of bytes from diff
          // to packBuf
          memcpy(packBuf+nc, (char *)diff, nbytes);
          nc += nbytes;
        }
      }
      ncompr = nc; // signal completion
      nsamps = 0;  // prevent another cycle from starting
    }
  }
}                  

/* PART 3 - main cog */

/* main cog - initializes variables and starts new cogs.
 * don't exit - start infinite loop as the last thing.
 */
int main(void)
{
  int comprCogId = -1;
  int i;
  unsigned int t0;
  
  nsamps = 0;
  ncompr = -1;
  
  printf("starting main\n");
  
  /* start a new cog with 
   * (1) address of function to run in the new cog
   * (2) address of the memory to pass to the function
   * (3) address of the stack
   * (4) size of the stack, in bytes
   */
  comprCogId = cogstart(&comprCog, NULL, comprCogStack, STACK_SIZE_BYTES);
  if(comprCogId < 0) {
    printf("error starting compr cog\n");
    while(1) {;}
  }          

  printf("started compression cog %d\n", comprCogId);
  
  /* start the compression cog by setting nsamps to 1 */
  sampsBuf[0] = 0xEFCDAB;
  nsamps = 1;
  
  /* wait until the compression cog sets ncompr to a non-neg number */
  while(ncompr < 0) {
    ;
  }
  
  printf("nsamps = %d, ncompr = %d\n", nsamps, ncompr);
  printf("samp0 = %x, packBuf = %x %x %x\n", sampsBuf[0], packBuf[0], packBuf[1], packBuf[2]);

  /* populate the sampsBuf array with test numbers */
  for(i=0; i<NSAMPS_MAX; i++) {
    sampsBuf[i] = 10000*(i+1000);
  }
  
  ncompr=-1;
  t0 = CNT;
  nsamps=128;
  /* wait until the compression cog sets ncompr to a non-neg number */
  while(ncompr < 0) {
    ;
  }
  t0 = CNT - t0;
  printf("nsamps = %d, ncompr = %d\n", nsamps, ncompr);
  printf("samp0 = %x, packBuf = %x %x %x\n", sampsBuf[0], packBuf[0], packBuf[1], packBuf[2]);
  printf("dt = %d\n", t0);

  while(1)
  {
    ;
  }  
}
