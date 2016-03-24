( Generated from test_017_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _main[ _arg -- ret ]
    1 dup if pop 1 then
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
