( Generated from test_510_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _wall[ _msg -- ret ]
    var _d
    #-1 firstdescr _d !
    begin
        _d @
    while
        _d @ _msg @ descrnotify
        _d @ nextdescr _d !
    repeat
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _wall
;
