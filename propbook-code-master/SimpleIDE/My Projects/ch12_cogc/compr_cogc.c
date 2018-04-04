/*
  compr-cog1.c - start a new cog to perform compression.
*/

/* libraries */
#include <stdio.h>
#include <propeller.h>

#include "compr_cogc.h"

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
// reserved space to be passed to startComprCog
struct cogmem_t {
  unsigned int stack[STACK_SIZE_BYTES >> 2];
  volatile struct locker_t locker;
} cogmem;  

// shared vars
volatile int nsamps;
volatile int ncompr;
volatile int sampsBuf[NSAMPS_MAX];
volatile char packBuf[NSAMPS_MAX<<2]; // 128 * 4
volatile int comprCodesBuf[NSAMPS_MAX>>4]; //128 / 16

int startComprCog(volatile void *p) {
  extern unsigned int _load_start_compr_cog[];
  return cognew(_load_start_compr_cog, p);
}  

/* main cog - initializes variables and starts new cogs.
 * don't exit - start infinite loop as the last thing.
 */
int main(void)
{
  int comprCogId = -1;
  int i, t0;
  
  nsamps = 0;
  ncompr = -1;
  
  printf("starting main\n");
  
  /* start a new cog with 
   * (1) address of function to run in the new cog
   * (2) address of the memory to pass to the function
   * (3) address of the stack
   * (4) size of the stack, in bytes
   */
  comprCogId = startComprCog(&cogmem.locker);
  if(comprCogId < 0) {
    printf("error starting compr cog\n");
    while(1) {;}
  }          

  printf("started compression cog %d\n", comprCogId);

  // NEW CODE STARTS HERE >>>
  printf("BEFORE COMPRESSION\n");
  // generate fake data...
  for(i=0; i<NSAMPS_MAX; i++) {
    sampsBuf[i] = 10000*(i+1000);
  }
  
  printf("nsamps = %d, ncompr = %d\n", nsamps, ncompr);
  printf("samp0 = %x, packBuf = %x %x %x\n", sampsBuf[0], packBuf[0], packBuf[1], packBuf[2]);

  ncompr=-1;
  t0 = CNT;
  nsamps=128;
  /* wait until the compression cog sets ncompr to a non-neg number */
  while(ncompr < 0) {
    ;
  }
  t0 = CNT - t0;
  
  printf("\nAFTER COMPRESSION\n");

  printf("nsamps = %d, ncompr = %d\n", nsamps, ncompr);
  printf("samp0 = %x, packBuf = %x %x %x\n", sampsBuf[0], packBuf[0], packBuf[1], packBuf[2]);
  printf("dt = %d\n", t0);
  // NEW CODE ENDS HERE <<<

  while(1)
  {
    ;
  }  
}