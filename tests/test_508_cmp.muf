( Generated from test_508_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
  
: _loopy[ _count -- ret ]
    var _i
    var _val
    var _key
    1
    dup _i ! pop
    begin
        _i @ _count @ > not
    while
        _i @ intostr me @ swap notify 0 pop
        _i @ dup 1 + _i ! pop
    repeat
    1
    dup _i ! pop
    begin
        _i @ _count @ <=
    while
        _i @ intostr me @ swap notify 0 pop
        _i @ dup 1 + _i ! pop
    repeat
    1
    dup _i ! pop
    begin
        _i @ intostr me @ swap notify 0 pop
        _i @ dup 1 + _i ! pop
    (conditional follows)
        _i @ _count @ <= not
    until
    1
    dup _i ! pop
    begin
        _i @ intostr me @ swap notify 0 pop
        _i @ dup 1 + _i ! pop
    (conditional follows)
        _i @ _count @ >
    until
    online_array
    foreach _val ! pop
        _val @ me @ swap notify 0 pop
    repeat
    online_array
    foreach _val ! _key !
        {
            _key @
            " = "
            _val @
        }list array_interpret me @ swap notify 0 pop
    repeat
    0
;
  
: __start
    "me" match me !
    me @ location loc !
    trig trigger !
    _loopy
;
