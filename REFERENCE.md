Language Syntax
===============


Comments
--------

Comments can use either of the following syntaxes:

    // Single line comment.

or

    /*
    multiple
    line
    comment
    */


Literals
--------

Decimal integers are simple:

    123456789

Hexadecimal integers are prefixed with `0x`:

    0x7ffc

Octal integers are prefixed with `0o`:

    0o1234567

Binary integers are prefixed with `0b`:

    0b11010100

Floating point numbers are given like:

    3.14
    0.1
    3.
    1e9
    6.022e23
    1.6e-35

DataBase References (dbrefs) are given like:

    #12345
    #-1

String literals are given like:

    "Hello!"

List arrays can be declared like this:

    ["first", "second", "third"]

or

    [1, 2, 4, 8]


Global Variables
----------------

You can declare global variables at the toplevel scope like:

    var myglobal;
    var firstvar, secondvar, third;
    var foo = 23, bar = 72;

The global variables `me` and `loc` are pre-defined for all programs.


Functions
---------

You can declare a function like this:

    func helloworld() {
        return "Hello World!";
    }

or

    func concatenate(var1, var2) {
        return strcat(var1, var2);
    }


If you need a variable number of arguments for a function, you can put a `*`
after the last argument, to indicate that all extra arguments will by passed
as a list in the last argument variable.

    func concat(args*) {
        return array_interpret(args);
    }

Functions return the value given to the `return` command.  ie: `return 42;`
will return the integer value `42` from the function.  If the end of the
function is reached with no `return` executing, then the function will return
the integer `0`.


Function Variables
----------------

You can declare extra variables in function scope like this:

    func myfunction() {
        var myvar;
        var firstvar, secondvar, third;
        var forth = "Sally";
        var fifth = "5th", sixth = 6;
        ...
    }

Calls
-----

You can call functions you have declared, and many builtin MUF primitives in
this way:

    myvar = myfunction(5, "John Doe");

    notify(me, "Hello World!");

If a primitive returns more than one argument on the stack normally, then all
items it would return are returned in a list array.


Expressions
-----------

Basic Math:
- Addition: `2 + 3`
- Subtraction: `5 - 2`
- Multiplication: `5 * 2`
- Division: `10 / 2`
- Modulo: `7 % 3`

Numeric Comparisons:
- Equals: `x == 2`
- Not Equals: `x != 2`
- Greater Than: `x > 2`
- Less Than: `x < 2`
- Greater Than or Equals: `x >= 2`
- Less Than or Equals: `x <= 2`

Bitwise Math:
- Bitwise AND: `6 & 4`
- Bitwise OR: `8 | 4`
- Bitwise XOR: `6 ^ 4`
- Bitwise NOT: `~10`
- BitShift Left: `1 << 4`
- BitShift Right: `128 >> 3`

Logical Operations:
- Logical OR: `x == 2 || x == 10`
- Logical AND: `x > 2 && x < 10`
- Logical XOR: `x > 2 ^^ x < 10`
- Logical NOT: `!x`

**WARNING: There is no shortcutting in logical expressions!**

Assignment:
- Simple assignment: `x = 23`
- Add and assign: `x += 2` is the same as `x = x + 2`
- Subtract and assign: `x -= 2` is the same as `x = x - 2`
- Multiply and assign: `x *= 2` is the same as `x = x * 2`
- Divide and assign: `x /= 2` is the same as `x = x / 2`
- Modulo and assign: `x %= 2` is the same as `x = x % 2`
- Bitwise AND and assign: `x &= 2` is the same as `x = x & 2`
- Bitwise OR and assign: `x |= 2` is the same as `x = x | 2`
- Bitwise XOR and assign: `x ^= 2` is the same as `x = x ^ 2`
- BitShift Left and assign: `x <<= 2` is the same as `x = x << 2`
- BitShift Right and assign: `x >>= 2` is the same as `x = x >> 2`

Miscellaneous:
- Grouping: `2 * (3 + 4)`
- Array subscript: `x[2]` returns the third item of the given array in `x`.
- Array subscript assignment: `x[2] = 42` sets the third element of the array in `x` to `42`.

These expressions can be combined in surprising ways:

    var x, y = [[4, 5, 6], 3], z = 1;
    x = y[0][1] = 43 * (z += 1 << 3);


Arrays
------

Declaring a list array is easy:

    var listvar = ["First", "Second", "Third", "Forth!"];


You can fetch an element from a list using a subscript:

    var a = listvar[2];

Which will set the newly declared variable `a` to `"Third"`:


Setting a list element uses a similar syntax:

    listvar[3] = "foo";

That will change the 4th element (as list indexes are 0-based) of the list in
listvar to `"foo"`, resulting in listvar containing the list:

    ["First", "Second", "Third", "foo"]


You can append items to an existing list with the `[]` construct:

    listvar[] = "bar";

Resulting in listvar containing the list:

    ["First", "Second", "Third", "foo", "bar"]


Deletion of list elements uses `del()` like this:

    del(listvar[2]);

Which deletes the 3rd element of the list stored in `listvar`, resulting in
`listvar` containing:

    ["First", "Second", "foo", "bar"]


If you need to work with nested lists, ie: lists stored in elements of lists,
you can just add subscripts to the expression.  For example:

    var nest = [
        [8, 7, 6, 5],
        [4, 3, 2],
        ["Foo", "Bar", "Baz"]
    ];

    // Sets a to "Bar", the 2nd element of the list inside the
    // 3rd element of the list in nested.
    var a = nest[2][1];

    // Sets 3rd element of list in the 1st element of nest to 23.
    nest[0][2] = 23;

    // nest now contains:
    // [ [8, 7, 23, 5],  [4, 3, 2],  ["Foo", "Bar", "Baz"] ]

    // Append "baz" to the list in the 3rd element
    // of the list in nest:
    listvar[2][] = "Qux";

    // nest now contains:
    // [ [8, 7, 23, 5],  [4, 3, 2],  ["Foo", "Bar", "Baz", "Qux"] ]

    // Delete the 2nd element of the list in
    // the 3rd element in nest.
    del(nest[2][1]);

    // nest now contains:
    // [ [8, 7, 23, 5],  [4, 3, 2],  ["Foo", "Baz", "Qux"] ]


Dictionaries
------------

Dictionaries are a special type of array, where the keys are not necessarily
numeric, and they don't have to be contiguous.  You can use many of the same
functions and primitives with dictionaries that you use with list arrays.
MUV Dictionaries are functionally like hash tables in other languages.

Defining a dictionary is similar to defining a list array, except you also
specify the keys:

    var mydict = [
        "one" => 1,
        "two" => 2,
        "three" => 3,
        "four" => 4
    ];

Reading, setting and deleting dictionary elements are very similar to doing
the same with a list array:

    var myvar = mydict["three"];
    mydict["six"] = 6;
    del(mydict["one"]);


Conditionals
------------

You can use the `if` statement for conditional code execution:

    if (x > 3)
        tell("Greater!");

Which is the same as:

    if (x > 3) {
        tell("Greater!");
    }

If you need an else clause, you can do this:

    if (x < 0) {
        tell("Negative!");
    } else {
        tell("Positive!");
    }

If you need to compare a value against a lot of options, you can use the
`switch` - `case` statement:

    switch (val) {
        case(1) {
            tell("One!");
        }
        case(2) {
            tell("Two!");
        }
        case(3) {
            tell("Three!");
        }
        default {
            tell("Something else!");
        }
    }

The default clause is optional:

    switch (val) {
        case(1) {
            tell("One!");
        }
        case(2) {
            tell("Two!");
        }
        case(3) {
            tell("Three!");
        }
    }

With the `using` clause, you can specify a primitive or function that takes
two arguments to use for comparisons.  When the comparison function or
primitive returns true, then a match is found.  When `using strcmp` it special
cases the comparison to actually be `strcmp not`.

    switch (val using strcmp) {
        case("one") {
            tell("First!");
        }
        case("two") {
            tell("Second!");
        }
        case("three") {
            tell("Third!");
        }
    }

Unlike in C, `switch` statements do not fall-through from one case clause to
the next. Also, you can actually use expressions in the case, not just
constants.

    switch(name(obj) using strcmp) {
        case(strcat(name(me), "'s Brush")) {
            tell("It's one of your brushes!");
            brushcount += 1;
        }
        case(strcat(name(me), "'s Fiddle")) {
            tell("It's one of your fiddles!");
            fiddlecount += 1;
        }
    }

If you use the `break` statement inside a case clause, you can exit the case
clause early, and execution resumes after the end of the switch.  If you use a
`continue` statement inside a case clause, the entire switch statement is
re-evaluated.  This can be useful for, perhaps, running a looping state machine.

    var FIRST = 1, SECOND = 2, THIRD = 3, FOURTH = 4;
    var state = FIRST;
    switch(state) {
        case(FIRST) {
            state = SECOND;
            do_something();
            continue;
        }
        case(SECOND) {
            state = THIRD;
            do_something_else();
            continue;
        }
        case(THIRD) {
            if (do_something_more()) {
                state = FOURTH;
                continue;
            }
            break;
        }
        case(FOURTH) {
            state = FIRST;
            do_something_special()
            continue;
        }
    }


Loops
-----

There are several types of loops available:

    var i;
    for (i = 1; i <= 10; i+=1) {
        tell(intostr(i));
    }

    var i = 10;
    while (i > 0) {
        tell(intostr(i));
        i -= 1;
    }

    var i = 10;
    until (i == 0) {
        tell(intostr(i));
        i -= 1;
    }

    var i = 10;
    do {
        tell(intostr(i));
        i -= 1;
    } while(i > 0);

    var i = 10;
    do {
        tell(intostr(i));
        i -= 1;
    } until(i == 0);

You can also iterate arrays/lists/dictionaries like this:

    var letter, letters = ["a", "b", "c", "d", "e"];
    for (letter in letters)
        tell(letter);

or

    var idx, letter;
    for (idx => letter in ["a", "b", "c", "d", "e"])
        tell(cat(intostr(idx), letter));


Exceptions
----------

You can trap errors with the `try` - `catch` construct:

    try {
        setname(obj, "Foobar");
    } catch (e) {
        tell(e["error"]);
    }

The variable given to the `catch` command will, when an error is received,
have a dictionary stored in it with the following values:

- `error` The error string that was emitted by the MUF instruction that threw
          an error.

- `instr` The name of the MUF instruction that threw the error.

- `line` The MUF line that threw the error.

- `program` The program that the error was thrown in.  This might not be the
            same as the current program, if the error occurred inside a call.

If you don't care about the exception details, you can just not specify the
variable:

    try {
        setname(obj, "Foobar");
    } catch () {
        tell("Could not set the name.");
    }

If you just want to trap any errors without doing anything, you can just do:

    try {
        setname(obj, "Foobar");
    } catch();

If you need to throw your own custom exception, you can do it with the `throw("MyError")` command.


MUF Interaction
---------------

Sometimes you need to interact with other MUF programs, by reading or storing
data on the MUF stack.  You can do that with the `top` and `push(...)`
constructs. Also, you can specify raw MUF code with the `muf("...")` command.

The special variable `top` refers to the top of the stack.  You can "pop" the
top of the stack and store it in a variable like:

    var foo = top;

You can "push" one or more values onto the top of the stack with the
`push(...)` command:

    push("Hi!");

    push("One", 2, #3, "Fore!");

You can specify raw inline MUF code like this:

    muf("{ \"Hello, \" args @ }list array_interpret out !");

which will compile directly into MUF as:

    { "Hello, " args @ }list array_interpret out !


Externs
-------

If new primitives are added to MUF that MUV doesn't know about, or if you need
to call external libraries, you can use an `extern` declaration to let MUV
know about how to call it.

    extern void tell(msg);

will tell MUV that a function or primitive named `tell` exists that takes one
argument, and returns nothing on the stack.

    extern single foobar(baz, qux);

will tell MUV that a function or primitive named `foobar` exists, that takes
two arguments, and returns a single value on the stack.  When you call this
function, it will return that single stack item to the caller.

    extern multiple fleegul();

will tell MUV that a function or primitive named `fleegul` exists, that takes
no arguments, and returns two or more values on the stack.  When you call this
function, it will return a list containing the returned stack items.


Built-Ins
---------
MUV defines some convenience functions that MUF doesn't:

`tell(msg)` simply acts like `notify(me, msg)`

`cat(...)` takes any number of arguments, translates them into a basic
string representation of each, and concatenates them together.

    cat(count, " items belong to ", me)

will return a string like

    "23 items belong to John_Doe"

`join(delim, ...)` will similarly translate and concatenate its arguments,
but it inserts the given `delim` string between each part.

    join("_X_", count, " items belong to ", me)

will return a string like:

    "23_X_ items belong to _X_John_Doe"

`fmtstring(fmt, ...)` roughly implements the functionality of the MUF
primitive `fmtstring`.  The format string is similar to C's printf function.
For full details, see the documentation for the `fmtstring` MUF primitive.

    fmtstring("#%d: %s", int(me), name(me))

will return a string like:

    "#1: Wizard"

`fmttell(fmt, ...)` is roughly the same as `tell(fmtstring(fmt, ...))`

