( Generated from test_038_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
  
: _sub[ _a -- ret ]
    _a @ exit
    0
;
  
: _main[ _arg -- ret ]
    "Foo" _sub exit
    0
;
  
: __start
    "me" match me !
    me @ location loc !
    trig trigger !
    _main
;
