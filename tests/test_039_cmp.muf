( Generated from test_039_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _sub[ _a _b -- ret ]
    { _b @ _a @ }list exit
    0
;
: _main[ _arg -- ret ]
    "Foo" "Bar" _sub exit
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
