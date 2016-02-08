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

The muv program expects the input MUV source file to by passed via the `STDIN` stream.  The MUF output will be printed to `STDOUT`, error messages will be printed to `STDERR`, and the return code will be non-zero if errors were found.

```bash
./muv <sourcefile.muv >outfile.muf
```


Language Syntax
===============


Comments
--------

Comments can use either of the following syntaxes:

```
// Single line comment.
```
```
/*
multiple
line
comment
*/
```


Literals
--------

Integer values are simply the number: `12345` or `-5`

Floating point numbers are given like: `3.14` or `0.1` or `3.` or `6.022e23`

DataBase Reference literals are given like: `#1234` or `#-1`

String literals are given like: `"Hello!"`

List arrays have the syntax: `["first", "second", "third"]`
or `[1, 2, 4, 8]`

Dictionary literals have the syntax:
```
{
    "name" => "John Doe",
    "ssn" => "123-45-6789",
    "city" => "Smallville"
}
```


Global Variables
----------------

You can declare global variables at the toplevel scope like:

```
var myglobal;
var firstvar, secondvar, third;
```

The global variables `me` and `loc` are pre-defined for all programs.


Functions
---------

You can declare a function like this:
```
func helloworld() {
    return "Hello World!";
}
```
or
```
func concatenate(var1, var2) {
    return strcat(var1, var2);
}
```

If you need a variable number of arguments for a function, you can put a `*`
after the last argument, to indicate that all extra arguments will by passed as a list in the last argument variable.

```
func cat(args*) {
    return array_interpret(args);
}
```

Functions return the value given to the `return` command.  ie: `return 42;` will return the integer value `42` from the function.  If the end of the function is reached with no `return` executing, then the function will return the integer `0`.

Function Variables
----------------

You can declare extra variables in function scope like this:

```
func myfunction() {
    var myvar;
    var firstvar, secondvar, third;
    var forth = "Sally";
    var fifth = "5th", sixth = 6;
    ...
}
```

Calls
-----

You can call functions you have declared, and many builtin MUF primitives in this way:

```
myvar = myfunction(5, "John Doe");
```

```
notify(me, "Hello World!");
```

If a primitive returns more than one argument on the stack normally, then all items it would return are returned in a list array.


Expressions
-----------

Addition: `2 + 3`
Subtraction: `5 - 2`
Multiplication: `5 * 2`
Division: `10 / 2`
Modulo: `7 % 3`

Equals: `x == 2`
Not Equals: `x != 2`
Greater than: `x > 2`
Less than: `x < 2`
Greater than or equal: `x >= 2`
Less than or equal: `x <= 2`

Bitwise AND: `6 & 4`
Bitwise OR: `8 | 4`
Bitwise XOR: `6 ^ 4`
Bitwise NOT: `~10`
Bitshift Left: `1 << 4`
Bitshift Right: `128 >> 3`

Logical OR: `x == 2 || x == 10`
Logical AND: `x > 2 && x < 10`
Logical NOT: `!(x > 2)`

Grouping: `2 * (3 + 4)`

Assignment: `x = 23`

Add and assign: `x += 2` is the same as `x = x + 2`

Subtract and assign: `x -= 2` is the same as `x = x - 2`

Multiply and assign: `x *= 2` is the same as `x = x * 2`

Divide and assign: `x /= 2` is the same as `x = x / 2`

Modulo and assign: `x %= 2` is the same as `x = x % 2`

Bitwise AND and assign: `x &= 2` is the same as `x = x & 2`

Bitwise OR and assign: `x |= 2` is the same as `x = x | 2`

Bitwise XOR and assign: `x ^= 2` is the same as `x = x ^ 2`

Bitshift Left and assign: `x <<= 2` is the same as `x = x << 2`

Bitshift Right and assign: `x >>= 2` is the same as `x = x >> 2`

Array subscript: `x[2]` returns the third item of the given array in `x`.

Array subscript assignment: `x[2] = 42` sets the third element of the array in `x` to `42`.

These subexpressions can be combined in surprising ways:

```
var x, y = [[4, 5, 6], 3], z = 1;
x = y[0][1] = 43 * (z += 1 << 3);
```

Conditionals
------------

You can use the `if` statement for conditional code execution:

```
if (x > 3)
    notify(me, "Greater!");
```

Which is the same as:

```
if (x > 3) {
    notify(me, "Greater!");
}
```

If you need an else clause, you can do this:

```
if (x < 0) {
    notify(me, "Negative!");
} else {
    notify(me, "Positive!");
}
```


Loops
-----

There are several types of loops available:

```
var i;
for (i = 1; i <= 10; i+=1) {
    notify(me, intostr(i));
}
```

```
var i = 10;
while (i > 0) {
    notify(me, intostr(i));
    i -= 1;
}
```

```
var i = 10;
do {
    notify(me, intostr(i));
    i -= 1;
} while(i > 0);
```

```
var i = 10;
do {
    notify(me, intostr(i));
    i -= 1;
} until(i == 0);
```

You can also iterate arrays/lists/dictionaries like this:

```
var idx, letters = ["a", "b", "c", "d", "e"];
foreach (idx in letters)
    notify(me, letters[idx]);
```

or

```
var idx, letter;
foreach (idx => letter in ["a", "b", "c", "d", "e"])
    notify(me, strcat(intostr(idx), letter));
```

MUF Interaction
---------------

Sometimes you need to interact with other MUF programs, by reading or storing data on the MUF stack.  You can do that with the `top` and `push(...)` constructs. Also, you can specify raw MUF code with the `muf("...")` command.
 
The special variable `top` refers to the top of the stack.  You can "pop" the top of the stack and store it in a variable like:

```
var foo = top;
```

You can "push" one or more values onto the top of the stack with the `push(...)` command:

```
push("Hi!");
```

```
push("One", 2, #3, "Fore!");
```

You can specify raw inline MUF code like this:

```
muf("{ \"Hello, \" args @ }list array_interpret out !");
```

which will compile directly into MUF as:

```
{ "Hello, " args @ }list array_interpret out !
```


Externs
-------

If new primitives are added to MUF that MUV doesn't know about, or if you need to call external libraries, you can use an `extern` declaration to let MUV know about how to call it.

```
extern void tell(msg);
```

will tell MUV that a function or primitive named `tell` exists that takes one argument, and returns nothing on the stack.

```
extern single foobar(baz, qux);
```

will tell MUV that a function or primitive named `foobar` exists, that takes two arguments, and returns a single value on the stack.  When you call this function, it will return that single stack item to the caller.

```
extern multiple fleegul();
```
will tell MUV that a function or primitive named `fleegul` exists, that takes no arguments, and returns two or more values on the stack.  When you call this function, it will return list containing those returned stack items, to the caller.
