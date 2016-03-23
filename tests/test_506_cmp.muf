( Generated from test_506_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
lvar _foo
: _arrrr[  -- ret ]
    var _bar var _key var _val
    { "one" "two" "three" "four" "five" }list _bar !
    _bar @ 3 [] me @ swap notify
    _bar @ foreach
        _val ! _key !
        { _key @ " = " _val @ }list array_interpret me @ swap notify
    repeat
    0
;
: _trys[  -- ret ]
    var _bar var _err
    0 try
        me @ desc _bar !
    catch_detailed _err !
        _err @ me @ swap notify
    endcatch
    0 try me @ osucc _bar ! endcatch
    0
;
: _loopy[ _count -- ret ]
    var _i
    _count @ intostr me @ swap notify
    _count @ _foo !
    1 _i !
    begin
        _i @ _count @ <=
    while
        _i @ dup ++ _i ! intostr me @ swap notify
    repeat
    1 _i !
    begin
        _i @ intostr me @ swap notify
        _i @ ++ _i ! _i @ _count @ >
    until
    1 _i !
    begin
        _i @ intostr me @ swap notify
        _i @ ++ _i ! _i @ _count @ <= not
    until
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    72 _foo !
    _loopy
;
