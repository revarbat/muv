( Generated from test_029_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _main[ _arg -- ret ]
    13 -1 bitxor exit
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
