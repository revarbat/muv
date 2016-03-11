( Generated from test_509_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _main[  -- ret ]
    var _v
    voidfoo 0 dup _v ! pop
    singlefoo dup _v ! pop
    { multfoo }list dup _v ! pop
    qux dup _v ! pop
    { "Fee" "Fie" "Foe" }list array_interpret dup _v ! pop
    "%d: %s" { 5 "Fum" }list
    2 try
        array_explode 1 + rotate fmtstring
        depth 0 swap - rotate depth 1 - popn
    catch abort
    endcatch dup _v ! pop
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
