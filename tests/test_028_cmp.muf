( Generated from test_028_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _main[ _arg -- ret ]
    -42
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
