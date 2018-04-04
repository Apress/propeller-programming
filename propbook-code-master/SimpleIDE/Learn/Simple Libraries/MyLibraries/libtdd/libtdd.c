/* c test driven dev */

#include "tdd.h"
#include <stdio.h>

int main() {
  initTDD();
  assertTruthy(1, "Test that TDD prints OK");
  assertTruthy(0, "Test that TDD prints FAIL");
  summarizeTDD();
}      