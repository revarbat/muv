( Generated from test_048_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _main[ _arg -- ret ]
    var _s
    "Foo" dup _s ! pop
    _s @ "bar" strcmp not exit
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
