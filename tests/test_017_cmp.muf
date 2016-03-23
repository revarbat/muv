( Generated from test_017_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _main[ _arg -- ret ]
    1 dup if 1 and then
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
