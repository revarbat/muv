( Generated from test_035_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )

: _main[ _arg -- ret ]
    var _a
    {
        "foo" "FOO"
        "bar" "BAR"
        "baz" "BAZ"
    }dict
    dup _a ! pop

    _a @ "bar" [] exit 0
;

: __start
    "me" match me !
    me @ location loc !
    trig trigger !
    _main
;
