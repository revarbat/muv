( Generated from test_013_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _main[ _arg -- ret ]
    42 0 2 - bitshift
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
