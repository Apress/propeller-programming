/* c-spi: SPI master and slave in C */

#include <stdio.h>
#include <propeller.h>

#include "c-hw.h"

struct cogmem_t {
  unsigned int stack[50];
  volatile struct locker_t locker;
};

/* reserve memory for spimaster cog and spislave cog */
struct cogmem_t mcogmem; //master
struct cogmem_t scogmem; //slave

/* functions to start cogc cogs */
int startSPIMaster(volatile void *p) {
  extern unsigned int _load_start_spiMaster_cog[];
  return cognew(_load_start_spiMaster_cog, p);
}  
int startSPISlave(volatile void *p) {
  extern unsigned int _load_start_spiSlave_cog[];
  return cognew(_load_start_spiSlave_cog, p);
} 

/* shared memory with cogs */
volatile unsigned char masterSem;
volatile int data[NSAMPS_MAX];
      
int main()
{
  int masterCogId, slaveCogId, i;
  unsigned int t0;

  masterSem = locknew();
  while(lockset(masterSem)) {;} // obtain lock
  
  /* start both cogs */
  masterCogId = startSPIMaster(&mcogmem.locker);
  slaveCogId = startSPISlave(&scogmem.locker);
  
  printf("master id = %d slave id = %d sem = %d\n", masterCogId, slaveCogId, masterSem);
  t0 = CNT;

  lockclr(masterSem); // release lock, spimaster obtains lock
  // wait for spimaster to release lock, 
  while(lockset(masterSem)) {;} 
  t0 = CNT - t0;
  printf("Time to read 128 longs = %d\n", t0);
  
  // process array
  for(i=0;i<NSAMPS_MAX;i++)
    printf("i=%d data=%x\n", i, data[i]);
  
  DIRA |= LED0Mask;
  
  while(1)
  {
    OUTA ^= LED0Mask;
  }  
}
