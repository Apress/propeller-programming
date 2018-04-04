/* c test driven dev */
#include "tdd.h"
int nTest, nPass, nFail;

void initTDD() {
  nTest = nPass = nFail = 0;
  return 0;
}

int assertTruthy(int cond, char *msg) {
  nTest++;
  if(cond != 0) {
    printf("%s\n...ok\n", msg);
    nPass++;
    return(1);
  } else {
    printf("%s\n***FAIL\n", msg);
    nFail++;
    return(0);
  }
}  

void summarizeTDD() {
  printf("Tests Run: %d\n", nTest);   
  printf("Tests Passed: %d\n", nPass);   
  printf("Tests Failed: %d\n", nFail);   
}    