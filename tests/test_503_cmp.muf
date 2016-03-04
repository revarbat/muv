( Generated from test_503_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _complex_match[ _v1 _v2 -- ret ]
    _v1 @ number? _v2 @ number? and if _v1 @ _v2 @ = exit then
    _v1 @ string? _v2 @ int? and if
        _v1 @ _v2 @ intostr strcmp not exit
    then
    _v1 @ type _v2 @ type strcmp not if 0 exit then
    _v1 @ string? if
        _v1 @ tolower _v2 @ tolower strcmp not exit
    then
    0 exit
    0
;
: _main[ _arg -- ret ]
    var _i
    2
    dup _i ! pop
    0 begin pop (switch)
        _i @
        dup 1 = if
            "One." me @ swap notify 0 pop break
        then
        dup 2 = if
            "Two." me @ swap notify 0 pop break
        then
        dup 3 = if
            "Three." me @ swap notify 0 pop break
        then
        break
    repeat pop
    0 begin pop (switch)
        _arg @
        dup "greet" strcmp not if
            "Hello." me @ swap notify 0 pop break
        then
        dup "who" strcmp not if
            "I'm called MUV." me @ swap notify 0 pop break
        then
        dup "what" strcmp not if
            "I'm a nicer language to use than MUF." me @ swap notify 0 pop break
        then
        (default)
        "I don't understand." me @ swap notify 0 pop break
    repeat pop
    0 begin pop (switch)
        _arg @
        dup "fee" _complex_match if
            "Fee selected!" me @ swap notify 0 pop break
        then
        dup 1 _complex_match if
            "One selected!" me @ swap notify 0 pop break
        then
        dup "" _complex_match if
            "None selected!" me @ swap notify 0 pop break
        then
        break
    repeat pop
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
