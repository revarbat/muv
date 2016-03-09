( Generated from test_032_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _main[ _arg -- ret ]
    var _a var _b
    42 dup _a ! pop
    13 dup _b ! pop
    _a @ _b @ * exit
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
