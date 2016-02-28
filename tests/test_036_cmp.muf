( Generated from test_036_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
  
: _main[ _arg -- ret ]
    var _a
    { }list
    dup _a ! pop
    "FOO"
    dup _a @ "foo" ->[] _a ! pop
    _a @ "foo" [] exit
    0
;
  
: __start
    "me" match me !
    me @ location loc !
    trig trigger !
    _main
;
