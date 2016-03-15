( Generated from test_047_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _main[ _arg -- ret ]
    { 2 3 4 5 }list 3 array_findval exit
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
