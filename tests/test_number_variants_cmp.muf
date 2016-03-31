( Generated from test_number_variants_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _main[ _arg -- ret ]
    var _valid_numbers var _num
    {
        99 98 97 96 95. 94.0 93 92.e0 91.0e0 9.0e1 890.e-1 8.8e+1 0.0
        0. 0 195935983 12345678 12345678 668
    }list _valid_numbers !
    _valid_numbers @ foreach
        _num ! pop
        { _num @ " bottles of beer on the wall!" }list
        array_interpret me @ swap notify 
    repeat
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
