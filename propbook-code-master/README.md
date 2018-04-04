# Code for propeller pasm tutorial book.

Purchase the book at [Leanpub Propeller Book](https://leanpub.com/propellerassemblerpasmintroduction).

## Compiling and Running Spin

There are two ways to compile and run the code.  In the book I only use 
command line programs (`openspin` and `propeller-load`).  The other way is to use PropTool.exe (on Windows) or PropellerIDE (on all platforms).  However, there is a bug in the Mac version of PropellerIDE that prevents it from running
the code.

### Command line methods

Download the SimpleIDE app from http://learn.parallax.com.  On a mac,
this will install the executables in
`/Applications/SimpleIDE.app/Contents/propeller-gcc/bin`, which should
be added to your path

```
export PROPDIR=/Applications/SimpleIDE.app/Contents/propeller-gcc/
export PATH=$PROPDIR/bin:$PATH
```

## Compiling and running C code

SimpleIDE is the best way to do this.  This is particularly true when you are
linking `.cogc` files or `PASM` files to a main C program.  If you download
this repo you must point your SimpleIDE install (including library files) to this directory.

## Getting this code
You can either download the code as a zip file (see the green button above labeled "Clone or Download") or you can use git as it is intended: a source code management tool (SCM).

In order to use it as an SCM, you will need to install the `git` program or a GUI client (see http://desktop.github.com for one such).

Clone the repository (as this set of files is called):
```
git clone https://github.com/sanandak/propbook-code.git
```
This will create a directory `propbook-code` that is identical to this one.

At any later time, as I make changes to the repository, you can update
your copy:
```
git pull origin master
```


## Board configurations
If your board is not present in `$PROPDIR/propeller-load`, then copy one of the
other ones (for example `quickstart.cfg`) and edit it for your board.  The board we use here has a clock speed of 100MHz, but is otherwise the same as
the quickstart board.

Copy it to a new file and edit it.  In addition, edit the `boards.txt` file 
so that the new board appears as an option in SimpleIDE.
```
> cd $PROPDIR/propeller-load
> sudo cp quickstart.cfg psu.cfg
> vi psu.cfg
> vi boards.txt
```


The quickstart config.
```
# quickstart.cfg
    clkfreq: 80000000
    clkmode: XTAL1+PLL16X
    baudrate: 115200
    rxpin: 31
    txpin: 30
    tvpin: 12   # only used if TV_DEBUG is defined
    cache-driver: eeprom_cache.dat
    cache-size: 8K
    cache-param1: 0
    cache-param2: 0
    eeprom-first: TRUE
```

And the psu config (same as the quickstart, but with a 6.25MHz crystal, for
a 100MHz clock)
```
# psu.cfg
    clkfreq: 100000000
    clkmode: XTAL1+PLL16X
    baudrate: 115200
    rxpin: 31
    txpin: 30
```



## Clock and serial port.

Here is the template in `spin_template.spin`:

```
CON ' Clock mode settings
  _CLKMODE = XTAL1 + PLL16X
  _XINFREQ = 6_250_000

  FULL_SPEED  = ((_clkmode - xtal1) >> 6) * _xinfreq  ' system freq as a constant
  ONE_MS      = FULL_SPEED / 1_000                    ' ticks in 1ms
  ONE_US      = FULL_SPEED / 1_000_00                 ' ticks in 1us

CON ' Pin map

  DEBUG_TX_TO   = 30
  DEBUG_RX_FROM = 31

CON ' UART ports
  DEBUG             =      0
  DEBUG_BAUD        = 115200
```

It expects a 6.25MHz crystal, with a 16x PLL (Phase Locked Loop) that
results in an 100 MHz clock (6.25 x 16).
It specifies that the serial port is on pins 30 and 31 at a speed of
115200 baud.

The other common setting is a 5MHz crystal (for example, the quickstart board).  In that case, set `_XINFREQ = 5_000_000` and use `-b quickstart` in the `propeller-load` command.

**Make sure you check and edit these settings for your board.**

**Both the spin file and the .cfg file must match the board.**

## Compiling and downloading code

The directories refer to the chapters of the book.  The `libs` directory
has needed libraries (serial port, number formatting, and unit-testing).

The board configuration refers to a file in `$PROPDIR/propeller-load`, in this case `psu.cfg`:

```
> cd propbook-code/ch03

# compile the spin code to binary
> openspin -L ../libs hello_Demo.spin 

An open-source compiler for Propeller Spin
Copyright © 2012-2015 Parallax, Inc.

Compiling hello_Demo.spin
|-FullDuplexSerial4portPlus_0v3.spin
|-Numbers.spin
|-hello_pasm.spin
Done.
Program size is 4040 bytes

# download binary file to board, and run the program, and open a terminal 
> propeller-load  -b psu -t -r hello_Demo.binary 
```

Be warned, if you use the wrong board specification file (for example a board spec that expects an 80MHz clock) with a board that actually has a, e.g., 100MHz
clock, you will get gibberish on the screen.

In addition, the baud rate of the terminal has to match the baud rate
in the code.  Generally we use 115200, but if there is a mismatch,
again, you will get gibberish.
