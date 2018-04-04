#define NSAMPS_MAX 128

#define LED0 16
#define LED0Mask (1U << LED0)

#define CS 10
#define CLK 11
#define MOSI 12
#define MISO 13
#define CSMask (1U << CS)
#define CLKMask (1U << CLK)
#define MOSIMask (1U << MOSI)
#define MISOMask (1U << MISO)

struct locker_t {
};

