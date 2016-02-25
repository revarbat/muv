( Generated from test_041_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )

: _sub[ _a _b -- ret ]
    _a @
    dup _b @ []<-
    _b ! pop

    _b @ exit 0
;

: _main[ _arg -- ret ]
    "Foo" {

        "Bar"
        "Baz"
    }list _sub exit 0
;

: __start
    "me" match me !
    me @ location loc !
    trig trigger !
    _main
;
