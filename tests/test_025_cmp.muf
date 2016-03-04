( Generated from test_025_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _main[ _arg -- ret ]
    { "abc" "def" "ghi" }list exit
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
