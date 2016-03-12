( Generated from test_046_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _main[ _arg -- ret ]
    3.14159 2.71828 / exit
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
