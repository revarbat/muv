( Generated from test_510_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _wall[ _msg -- ret ]
    var _d
    #-1 firstdescr dup _d ! pop
    begin
        _d @
    while
        _d @ _msg @ descrnotify 0 pop
        _d @ nextdescr dup _d ! pop
    repeat
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _wall
;
