( Generated from test_literal_int_variants_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _main[ _arg -- ret ]
    var _valid_numbers var _num
    {
        99 98 97 96 95 195935983 195935983 12345678 12345678 668 0
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
