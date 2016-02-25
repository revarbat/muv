( Generated from test_502_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )

: _main[ _arg -- ret ]
    var _foo
    "This\ris\ra\rtest"
    dup _foo ! pop

    {
        _foo @
        "Hello \\World!\r"
        "\[[1;"
        "Hello, \""
        _arg @
        "\"!"
        "\[[0;\r"
        "Hello All!"
    }list array_interpret me @ swap notify 0 pop 0
;

: __start
    "me" match me !
    me @ location loc !
    trig trigger !
    _main
;
