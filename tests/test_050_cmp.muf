( Generated from test_050_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _quotes[ _arg -- ret ]
    var _a var _b var _c var _d var _e var _f var _g var _h
    var _i var _j var _k
    "Test('')" dup _a ! pop
    "Test(\"\")" dup _b ! pop
    "Test(\"\")" dup _c ! pop
    "Test(\"\")" dup _d ! pop
    "it's" dup _e ! pop
    "it's" dup _f ! pop
    "a\"b" dup _g ! pop
    "a'b" dup _h ! pop
    "abc\"def" dup _i ! pop
    "abc\r               def" dup _j ! pop
    "abc'def" dup _k ! pop
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _quotes
;
