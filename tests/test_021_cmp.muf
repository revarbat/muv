( Generated from test_021_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _main[ _arg -- ret ]
    1 dup not if 2 dup if 3 not and then or then exit
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
