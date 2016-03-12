( Generated from test_042_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
lvar foo::ltuaa
: foo::abc[ _a -- ret ]
    foo::ltuaa @ _a @ + exit
    0
;
: foo::def[ _a -- ret ]
    _a @ 2 * foo::abc exit
    0
;
: _main[ _arg -- ret ]
    3 foo::def exit
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    42 foo::ltuaa !
    _main
;
