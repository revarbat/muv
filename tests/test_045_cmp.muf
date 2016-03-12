( Generated from test_045_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: loopy[ _count -- ret ]
    var _l var _v var _l2 var _l3
    { "foo" "bar" "baz" }list dup _l ! pop
    _l @ foreach
        _v ! pop
        _v @ me @ swap notify 0 pop
    repeat
    _l @ foreach
        _l2 ! pop
        _l2 @ dup _l3 ! pop
        _l3 @ me @ swap notify 0 pop
    repeat
    0
;
public loopy
$libdef loopy
: __start
    "me" match me ! me @ location loc ! trig trigger !
    loopy
;
