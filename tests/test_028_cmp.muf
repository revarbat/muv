( Generated from test_028_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _main[ _arg -- ret ]
    0 42 - exit
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
