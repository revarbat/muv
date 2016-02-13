TODO
====

Required
--------

- Declare usable MUF primitive set. (60% done.)
- cmd-line declaration of program name for -m muf headers.
- cmd-line declaration of output muf filename via -o.
- Change MUF editor header code to take program name from command-line.


Would Be Nice
-------------

- Array insert.  foo = array_insertitem(foo, "bar") for now.
- Allow var declaration in `for`, `while`, `until`. (harder than it should be!)
- Array slicing (foo[2:4]) or array get/set range.
- Reinstate ternary operator?
- import/export?
- Multi-line strings:

    ```
    var lines = """first line
    second line
    third line""";
    ```


Someday
-------

- Simple object oriented classes.
- Standard libraries.
- Upload to MUCK using -u:
    `./muv -m cmd-foobar -u muck://John_Doe:mypass@muckhost.com:8888 foobar.muv`

