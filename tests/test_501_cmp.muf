( Generated from test_501_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _dump[ _arr _indent -- ret ]
    var _key var _val var _out
    _key @ pop
    _val @ pop
    ""
    dup _out ! pop
    _arr @
    foreach _val ! _key !
        _val @ array? _val @ dictionary? or if
            _key @ _indent @ "%s%~ => [" fmtstring me @ swap notify 0 pop
            _val @ { _indent @ "  " }list array_interpret _dump pop
            _indent @ "%s]" fmtstring me @ swap notify 0 pop
        else
            _val @ _key @ _indent @ "%s%~ => %~" fmtstring
            me @ swap notify 0 pop
        then
    repeat
    0
;
: _dictfunc[  -- ret ]
    var _mydict var _myvar
    { "one" "First" "two" "Second" "three" "Third" }dict
    dup _mydict ! pop
    _mydict @ "" _dump pop
    _mydict @ "two" []
    dup _myvar ! pop
    _myvar @ me @ swap notify 0 pop
    "Fifth"
    dup _mydict @ "five" ->[] _mydict ! pop
    _mydict @ "three" array_delitem _mydict ! 0 pop
    0
;
: _main[  -- ret ]
    var _arr var _idx var _word var _empty var _nested
    {
        "First" "Second" "Third" "Forth" "Fifth" "Sixth" "Seventh"
        "Eighth" "Ninth" "Tenth" "Eleventh"
    }list
    dup _arr ! pop
    _idx @ pop
    _word @ pop
    _arr @
    foreach _word ! pop
        _arr @ _idx @ [] me @ swap notify 0 pop
    repeat
    { }list
    dup _empty ! pop
    _arr @
    foreach _word ! _idx !
        me @ _word @ _idx @ "%d: %s" fmtstring notify 0 pop
    repeat
    {
        { 1 2 3 4 }list { "a" "b" "c" "d" }list
        { "One" "Two" "Three" "Four" }list
        { { 3 1 4 }list { 9 1 16 }list { 81 1 256 }list }list
    }list
    dup _nested ! pop
    _nested @ { 2 1 }list array_nested_get me @ swap notify 0 pop
    { "Fee" "Fie" "Foe" "Fum" }list
    dup _nested @ 1 ->[] _nested ! pop
    23
    dup _nested @ { 0 3 }list array_nested_set _nested ! pop
    _nested @ { 0 3 }list over over array_nested_get
    2 +
    dup 4 rotate 4 rotate array_nested_set _nested ! pop
    _nested @ 0 over over []
    "foo" dup rot []<-
    4 rotate 4 rotate ->[] _nested ! pop
    _nested @ { 3 1 }list over over array_nested_get
    "foo" dup rot []<-
    4 rotate 4 rotate array_nested_set _nested ! pop
    _nested @ 2 array_delitem _nested ! 0 pop
    _nested @ "" _dump pop
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
