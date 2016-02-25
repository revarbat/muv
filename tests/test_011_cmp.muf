( Generated from test_011_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )

: _main[ _arg -- ret ]
    #42 exit 0
;

: __start
    "me" match me !
    me @ location loc !
    trig trigger !
    _main
;
