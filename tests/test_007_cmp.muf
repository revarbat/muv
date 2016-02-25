( Generated from test_007_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )

: _main[ _arg -- ret ]
    3 4 5 6 + * + 7 - exit 0
;

: __start
    "me" match me !
    me @ location loc !
    trig trigger !
    _main
;
