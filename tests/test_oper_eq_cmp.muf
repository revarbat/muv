( Generated from test_oper_eq_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _main[ _arg -- ret ]
    var _s
    "Foo" _s !
    _s @ "bar" strcmp not
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
