( Generated from test_500_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )

: _main[ _arg -- ret ]
    var _k
    var _v
    var _mylist
    var _squares
    var _odds
    var _evens
    var _mydict
    var _squarevals
    var _foo
    var _bar
    var _obj
    var _listeners
    _k @ pop

    _v @ pop

    {
        3 4 5 6 7 8 9
    }list
    dup _mylist ! pop

    [] _mylist @
    foreach _v ! pop
        _v @ _v @ * swap []<-
    repeat
    dup _squares ! pop

    [] _mylist @
    foreach _v ! pop
        _v @ 2 %
        if
            _v @ swap []<-
        then
    repeat
    dup _odds ! pop

    [] _mylist @
    foreach _v ! pop
        _v @ 2 %
        not if
            _v @ swap []<-
        then
    repeat
    dup _evens ! pop

    {
        "a" 1
        "b" 2
        "c" 3
        "d" 4
    }dict
    dup _mydict ! pop

    [] _mydict @
    foreach _v ! _k !
        _v @ _v @ * swap
        _k @ ->[]
    repeat
    dup _squarevals ! pop

    [] _mydict @
    foreach _v ! _k !
        _k @ "b" strcmp 0 >
        if
            _v @ _v @ * swap
            _k @ ->[]
        then
    repeat
    dup _foo ! pop

    [] _mydict @
    foreach _v ! _k !
        _v @ 2 >
        not if
            _v @ _v @ * swap
            _k @ ->[]
        then
    repeat
    dup _bar ! pop

    _obj @ pop

    [] loc @ contents_array
    foreach _obj ! pop
        _obj @ player? _obj @ awake? and
        if
            _obj @ name swap []<-
        then
    repeat
    dup _listeners ! pop 0
;

: __start
    "me" match me !
    me @ location loc !
    trig trigger !
    _main
;
