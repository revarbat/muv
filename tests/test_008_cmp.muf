( Generated from test_008_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
  
: _main[ _arg -- ret ]
    "A String" exit
    0
;
  
: __start
    "me" match me !
    me @ location loc !
    trig trigger !
    _main
;
