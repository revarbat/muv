( Generated from test_array_dual_subscript_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _main[ _arg -- ret ]
    var _a
    { { 42 13 }list { 13 7 }list { 7 42 }list }list _a !
    _a @ { 1 0 }list array_nested_get
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
