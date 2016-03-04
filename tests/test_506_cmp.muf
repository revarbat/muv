( Generated from test_506_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
lvar _foo
: _arrrr[  -- ret ]
    var _bar
    var _key
    var _val
    { "one" "two" "three" "four" "five" }list
    dup _bar ! pop
    _bar @ 3 [] me @ swap notify 0 pop
    _bar @
    foreach _val ! _key !
        { _key @ " = " _val @ }list array_interpret me @ swap notify 0 pop
    repeat
    0
;
: _trys[  -- ret ]
    var _bar
    var _err
    _bar @ pop
    0 try
        me @ desc
        dup _bar ! pop
    catch_detailed _err !
        _err @ me @ swap notify 0 pop
    endcatch
    0 try
        me @ osucc
        dup _bar ! pop
    catch pop

    endcatch
    0
;
: _loopy[ _count -- ret ]
    var _i
    _i @ pop
    _count @ intostr me @ swap notify 0 pop
    _count @
    dup _foo ! pop
    1
    dup _i ! pop
    begin
        _i @ _count @ <=
    while
        _i @ dup 1 + _i ! intostr me @ swap notify 0 pop
    repeat
    1
    dup _i ! pop
    begin
        _i @ intostr me @ swap notify 0 pop
        _i @ 1 + dup _i ! pop _i @ _count @ >
    until
    1
    dup _i ! pop
    begin
        _i @ intostr me @ swap notify 0 pop
        _i @
        1 +
        dup _i ! pop _i @ _count @ <=
    not until
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger ! 72 _foo !
    _loopy
;
