MUV 2.0
=======
A C-like language to MUF translator.  Rewritten from the ground up, based
on the 1990's-era code from Nightfall.

Creating MUF programs is an ugly, painful, nearly write-only experience,
and that's coming from the coder who designed most of the language.  Why
spend massive amounts of time debugging and keeping track of stack items,
when you can write code in a more modern, readable language?

Instead of writing cryptic code like:

    : showspecies[  -- ret ]
        var obj
        loc @ contents_array
        foreach obj ! pop
            obj @ player? if
                obj @ "species" getpropstr dup not if pop "Unknown" then
                obj @ "sex" getpropstr dup not if pop "Unknown" then
                obj @
                "%-30D %-10s %-30s"
                fmtstring
                me @ swap notify
            then
        repeat
    ;

You can write:

    func showspecies() {
        for (var obj in contents_array(loc)) {
            if (player?(obj)) {
                tell(
		    fmtstring(
			"%-30D %-10s %-30s", obj,
			getpropstr(obj, "sex") || "Unknown",
			getpropstr(obj, "species") || "Unknown"
		    )
                );
            }
        }
    }


Code Status
-----------
This code is in Beta.  It compiles and runs cleanly on 32bit and 64bit
systems, and the language is pretty much stable.


Compiling
---------
Requires a minimum of `make`, `cc` and `yacc`.

To build:

    make

To install under `/usr/local`:

    sudo make install

To install under `/usr` instead:

    sudo make install ROOT=/usr


Usage
-----
The `muv` program expects the input MUV source file to be given on the
command-line.  The MUF output will, by default, be written to `STDOUT`.
Error messages will be printed to `STDERR`, and the return code will be
non-zero if errors were found.

    muv sourcefile.muv >outfile.muf

You can use `-w PROGNAME` to wrap the output in MUF editor commands.

    muv -w cmd-whospecies whospecies.muv >whospecies.muf

Using `-o OUTFILE` will write the output MUF code to OUTFILE instead
of STDOUT.

    muv -o whospecies.muf whospecies.muv

Adding a `-d` to the command-line will add debugging code to the MUF output.
Each line of MUV will add code like: `"foo.muv:23" pop` to the MUF output.

    muv -d -o whospecies.muf whospecies.muv


Links
-----
- Language reference: <https://github.com/revarbat/muv/blob/master/REFERENCE.md>
- TODO List: <https://github.com/revarbat/muv/blob/master/TODO.md>


