( Generated from test_042_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
lvar _foo::ltuaa
: _foo::abc[ _a -- ret ]
    _foo::ltuaa @ _a @ + exit
    0
;
: _foo::def[ _a -- ret ]
    _a @ 2 * _foo::abc exit
    0
;
: _main[ _arg -- ret ]
    3 _foo::def exit
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    42 _foo::ltuaa !
    _main
;
