( Generated from test_018_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _main[ _arg -- ret ]
    1 1 or exit
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
