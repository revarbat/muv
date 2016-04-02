( Generated from test_literal_string3_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _main[ _arg -- ret ]
    var _foo
    "This\ris\ra\rtest" _foo !
    {
        _foo @ "Hello \\World!\r" "\[[1;" "Hello, \"" _arg @ "\"!"
        "\[[0;\r" "Hello All!"
    }list array_interpret me @ swap notify 
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
