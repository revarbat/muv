( Generated from test_oper_bitshiftleftequals_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _main[ _arg -- ret ]
    var _a
    42 _a !
    _a @ 3 bitshift _a !
    _a @
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
