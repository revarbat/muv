( Generated from test_004_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )

: _main[ _arg -- ret ]
    42 13 * exit 0
;

: __start
    "me" match me !
    me @ location loc !
    trig trigger !
    _main
;