( Generated from test_049_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _main[ _arg -- ret ]
    var _arr
    { "foo" 3 "bar" 7 "baz" 9 }dict dup _arr ! pop
    "bar" _arr @ swap 1 array_make array_extract exit
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
