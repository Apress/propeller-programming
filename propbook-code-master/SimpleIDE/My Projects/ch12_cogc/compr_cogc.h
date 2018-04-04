
// size of stack in bytes
#define STACK_SIZE_BYTES 200
// compression constants
#define NSAMPS_MAX 128
#define CODE08 0b01
#define CODE16 0b10
#define CODE24 0b11
#define TWO_BYTES 0x7F // any diff values greater than this are 2 bytes
#define THREE_BYTES 0x7FF // diff valus greater than this are 3 bytes

/* define the struct for passing data via PAR to the cog -- UNUSED */
struct locker_t {
};  
