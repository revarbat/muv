( Generated from test_builtin_haskey_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _main[ _arg -- ret ]
    var _arr
    { "foo" 3 "bar" 7 "baz" 9 }dict _arr !
    "bar" _arr @ swap 1 array_make array_extract
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
