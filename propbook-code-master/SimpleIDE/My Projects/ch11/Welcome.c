/*
  Welcome.c
  
  ch11/Welcome.c - first C program.
*/

#include <propeller.h>  // include propeller specific variables and fns.
#include <stdio.h>  // Include printf

int main(void)                                    // Main function
{
  int n=1;
  while (1) {
    printf("Hello %d!\n", n);                            // Display test message
    waitcnt(CNT + CLKFREQ);
    n++;
  }    
  return 0;
}
