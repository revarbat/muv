MUV 2.0
=======

A C-like language to MUF translator.  Rewritten from the ground up, based on the 1990's-era code from Nightfall.

Creating MUF programs is an ugly, painful, nearly write-only experience, and that's coming from the
coder who designed most of the language.  Why spend massive amounts of time debugging and keeping
track of stack items, when you can write code in a more modern, readable language?

Instead of writing cryptic code like:

    : showspecies[  -- ret ]
        loc @ contents_array
        foreach swap pop
            dup player? if
                dup "_species" getpropstr
                over name
                "%-30s %30s"
                fmtstring
                me @ swap notify
            then
            pop
        repeat 
    ;

You can write:

    func showspecies() {
        var obj;
        for (obj in contents_array(loc)) {
            if (player?(obj)) {
                fmttell("%-30s %30s",
                    name(obj),
                    getpropstr(obj, "_species")
                );
            }
        }
    }


Code Status
-----------

Alpha code.  It compiles and runs on 32 and 64bit systems, but the language is
still being developed.  Output code could use a lot of optimization.


Compiling
---------
Requires a minimum of `make`, `cc` and `yacc`.

To build:

    make


Usage
-----

The muv program expects the input MUV source file to be given on the command-line.
The MUF output will be printed to `STDOUT`, error messages will be printed to
`STDERR`, and the return code will be non-zero if errors were found.

    ./muv sourcefile.muv >outfile.muf

You can use `-m` to wrap the output in MUF editor commands:

    ./muv -m sourcefile.muv >outfile.muf


Links
-----
- Language reference: <https://github.com/revarbat/muv/blob/master/REFERENCE.md>
- TODO List: <https://github.com/revarbat/muv/blob/master/TODO.md>
