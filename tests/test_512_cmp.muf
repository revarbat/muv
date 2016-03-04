( Generated from test_512_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _bass[  -- ret ]
    "THUMP!" exit
    0
;
: _foof[ _arg -- ret ]
    _bass exit
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _foof
;
