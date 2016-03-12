( Generated from test_043_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
lvar foo::fee
: foo::abc[ _a -- ret ]
    foo::fee @ _a @ + exit
    0
;
: bar::abc[ _a -- ret ]
    13 _a @ + exit
    0
;
: _main[ _arg -- ret ]
    3 foo::abc bar::abc pop
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    42 foo::fee !
    _main
;
