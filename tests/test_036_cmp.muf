( Generated from test_036_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _main[ _arg -- ret ]
    var _a
    { }list _a !
    "FOO" dup _a @ "foo" ->[] _a ! pop
    _a @ "foo" []
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
