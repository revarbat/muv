TODO
====

Required for Beta
-----------------

- cmd-line declaration of program name for -m muf headers.
- cmd-line declaration of output muf filename via -o.


Would Be Nice
-------------

- Constant declarations.  const pi = 3.14159;
- Array insert.  foo = array_insertitem(foo, "bar") for now.
- Allow var declaration in `for`, `while`, `until`. (harder than it should be!)
- Array slicing (foo[2:4]) or array get/set range.
- Reinstate ternary operator?
- Import/export?
- Multi-line strings

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

