( Generated from test_funcvar_assigned_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _main[ _arg -- ret ]
    var _a
    42 _a !
    _a @
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
