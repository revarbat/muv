( Generated from test_array_subscript_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _main[ _arg -- ret ]
    var _a
    { 42 13 7 }list _a !
    _a @ 1 []
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
