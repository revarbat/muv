( Generated from test_010_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
  
: _main[ _arg -- ret ]
    "Multi-\rline\rstring" exit
    0
;
  
: __start
    "me" match me !
    me @ location loc !
    trig trigger !
    _main
;
