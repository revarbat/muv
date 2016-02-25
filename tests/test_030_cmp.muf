( Generated from test_030_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )

: _main[ _arg -- ret ]
    var _a
    42
    dup _a ! pop

    _a @ exit 0
;

: __start
    "me" match me !
    me @ location loc !
    trig trigger !
    _main
;
