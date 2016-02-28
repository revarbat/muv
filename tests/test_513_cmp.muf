( Generated from test_513_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
  
: _main[ _arg -- ret ]
    var _arr
    var _b
    {
        "foo" {
            "fee" 2
            "fie" 8
            "foe" 7
            "fum" 42
        }dict
        "bar" {
            "blah" 1
            "blat" 3
            "bloo" 5
            "bleh" 7
        }dict
    }dict
    dup _arr ! pop
    _arr @ { "foo" "fie" }list array_nested_get
    dup _b ! pop
    43
    dup _arr @ { "bar" "bloo" }list array_nested_set _arr ! pop
    _arr @ { "bar" "blat" }list over over array_nested_get
    7 +
    dup 4 rotate 4 rotate array_nested_set _arr ! pop
    0
;
  
: __start
    "me" match me !
    me @ location loc !
    trig trigger !
    _main
;
