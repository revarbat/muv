( Generated from test_027_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
  
: _main[ _arg -- ret ]
    #-1 exit
    0
;
  
: __start
    "me" match me !
    me @ location loc !
    trig trigger !
    _main
;
