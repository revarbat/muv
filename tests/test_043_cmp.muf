( Generated from test_043_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
lvar _foo::fee
: _foo::abc[ _a -- ret ]
    _foo::fee @ _a @ + exit
    0
;
: _bar::abc[ _a -- ret ]
    13 _a @ + exit
    0
;
: _main[ _arg -- ret ]
    3 _foo::abc _bar::abc pop
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    42 _foo::fee !
    _main
;
