( Generated from test_515_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _gen[  -- ret ]
    var _i var _out
    0 dup _i ! pop
    { }list dup _out ! pop
    begin
        _i @ 4 <
    while
        _out @ { "Fee" "Fie" "Foe" "Fum" }list _i @ [] dup rot []<-
        _out ! pop
        _i @ dup ++ _i ! pop
    repeat
    _out @ exit
    0
;
: _listgen[  -- ret ]
    var _out var _i
    { }list dup _out ! pop
    0 dup _i ! pop
    begin
        _i @ dup ++ _i ! 10 <
    while
        _out @ _gen dup rot []<- _out ! pop
    repeat
    _out @ exit
    0
;
: tuple_check[ arr expect pos -- ]
    arr @ array? not if
        "Cannot unpack from non-array in " pos @ strcat abort
    then
    arr @ array_count expect @ = not if
        "Wrong number of values to unpack in " pos @ strcat abort
    then
;
: _main[ _arg -- ret ]
    var _a var _b var _c var _d
    _gen dup dup 4 "test_515_in.muv:25" tuple_check dup 0 [] _a !
    dup 1 [] _b ! dup 2 [] _c ! dup 3 [] _d ! pop pop
    _gen dup dup 4 "test_515_in.muv:26" tuple_check dup 0 [] _d !
    dup 1 [] _c ! dup 2 [] _b ! dup 3 [] _a ! pop pop
    _listgen foreach
        dup 4 "test_515_in.muv:27" tuple_check dup 0 [] _a !
        dup 1 [] _b ! dup 2 [] _c ! dup 3 [] _d ! pop pop
        { _a @ _b @ }list array_interpret me @ swap notify 0 pop
    repeat
    { }list _listgen
    foreach
        dup 4 "test_515_in.muv:30" tuple_check dup 0 [] _a !
        dup 1 [] _b ! dup 2 [] _c ! dup 3 [] _d ! pop pop
        _a @ _b @ strcmp
        if
            { _c @ _d @ }list array_interpret swap []<-
        then
    repeat exit
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
