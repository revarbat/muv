( Generated from test_508_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _loopy[ _count -- ret ]
    var _i var _i2 var _val var _key var _val2
    1 dup _i ! pop
    begin
        _i @ _count @ > not
    while
        _i @ intostr me @ swap notify 0 pop
        _i @ dup ++ _i ! pop
    repeat
    1 dup _i ! pop
    begin
        _i @ _count @ <=
    while
        _i @ intostr me @ swap notify 0 pop
        _i @ dup ++ _i ! pop
    repeat
    1 dup _i ! pop
    begin
        _i @ intostr me @ swap notify 0 pop
        _i @ dup ++ _i ! pop _i @ _count @ <= not
    until
    1 dup _i ! pop
    begin
        _i @ intostr me @ swap notify 0 pop
        _i @ dup ++ _i ! pop _i @ _count @ >
    until
    1 _count @ over over <= if 1 else -1 then for
        _i2 !
        _i2 @ intostr me @ swap notify 0 pop
    repeat
    online_array foreach
        _val ! pop
        _val @ "%D" fmtstring me @ swap notify 0 pop
    repeat
    online_array foreach
        _val2 ! _key !
        { _key @ " = " _val2 @ }list array_interpret me @ swap notify 0 pop
    repeat
    0
;
: _main[  -- ret ]
    10 _loopy pop
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
