( Generated from test_literal_float_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _main[ _arg -- ret ]
    {
        0. 1. 2.0 0.3e1 4e0 50e-1 600.e-2 70.0e-1 0 0. - 0 1. -
        0 2.0 - 0 0.3e1 - 0 4e0 - 0 50e-1 - 0 600.e-2 - 0 70.0e-1 -
    }list
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
