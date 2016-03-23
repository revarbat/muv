( Generated from test_039_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _sub[ _a _b -- ret ]
    { _b @ _a @ }list
;
: _main[ _arg -- ret ]
    "Foo" "Bar" _sub
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
