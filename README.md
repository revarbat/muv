MUV 2.0
=======

A C-like language to MUF translator.

Rewritten pretty much from the ground up, based on the code from Nightfall.


Code Status
-----------

Alpha code.  It compiles and runs on 32 and 64bit systems, but the language is
still being developed.  Currently arrat subscripting isn't working.


Compiling
---------
Requires a minimum of `make`, `cc` and `yacc`.

To build:
```bash
make
```

Usage
-----

The muv program expects the input MUV source file to be given on the command-line.  The MUF output will be printed to `STDOUT`, error messages will be printed to `STDERR`, and the return code will be non-zero if errors were found.

```bash
./muv sourcefile.muv >outfile.muf
```

or, using `-h` to force output of MUF editor commands:

```bash
./muv -h sourcefile.muv >outfile.muf
```


