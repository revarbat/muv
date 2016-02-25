( Generated from test_009_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )

: _main[ _arg -- ret ]
    "A string with\rnewlines and \[[1mstuff\[[0m." exit 0
;

: __start
    "me" match me !
    me @ location loc !
    trig trigger !
    _main
;
