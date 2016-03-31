( Generated from test_array_append_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _main[ _arg -- ret ]
    var _arr
    { "a" "b" "c" }list _arr !
    _arr @ "d" swap []<- _arr !
    _arr @
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
