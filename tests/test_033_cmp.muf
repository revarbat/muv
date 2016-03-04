( Generated from test_033_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _main[ _arg -- ret ]
    var _a
    { 42 13 7 }list
    dup _a ! pop
    _a @ 1 [] exit
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
