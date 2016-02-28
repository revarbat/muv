( Generated from test_034_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
  
: _main[ _arg -- ret ]
    var _a
    {
        {
            42 13
        }list {
            13 7
        }list {
            7 42
        }list
    }list
    dup _a ! pop
    _a @ { 1 0 }list array_nested_get exit
    0
;
  
: __start
    "me" match me !
    me @ location loc !
    trig trigger !
    _main
;
