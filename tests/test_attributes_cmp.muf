( Generated from test_attributes_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _sub[ _a _b _c -- ret ]
    { _a @ _b @ _c @ }list array_interpret
;
: _main[ _arg -- ret ]
    var _arr var _b
    {
        "foo" { "fee" 2 "fie" 8 "foe" 7 "fum" 42 }dict
        "bar" { "blah" 1 "blat" 3 "bloo" 5 "bleh" 7 "boo" '_sub }dict
        "baz" '_sub
    }dict _arr !
    _arr @ { "foo" "fie" }list array_nested_get _b !
    43 dup _arr @ { "bar" "bloo" }list array_nested_set _arr ! pop
    _arr @ { "bar" "blat" }list over over array_nested_get 7
    + rot rot array_nested_set _arr !
    _arr @ { "bar" "blat" }list over over array_nested_get 8
    + rot rot array_nested_set _arr !
    _arr @ { "bar" "blat" }list over over array_nested_get 9
    + rot rot array_nested_set _arr !
    5 4 3 _sub pop
    {
        4 6 2 _arr @ "baz" []
        dup address? if
            execute
        else
            } popn "Tried to execute a non-address in test_attributes_in.muv:30" abort
        then
    }list dup array_count 2 < if 0 [] then pop
    {
        4 6 2 _arr @ { "bar" "boo" }list array_nested_get
        dup address? if
            execute
        else
            } popn "Tried to execute a non-address in test_attributes_in.muv:31" abort
        then
    }list dup array_count 2 < if 0 [] then pop
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
