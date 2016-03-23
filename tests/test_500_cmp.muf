( Generated from test_500_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _main[ _arg -- ret ]
    var _k var _v var _mylist var _squares var _odds var _evens
    var _mydict var _squarevals var _foo var _bar var _obj
    var _listeners
    { 3 4 5 6 7 8 9 }list _mylist !
    { }list _mylist @ foreach
        _v ! pop
        _v @ _v @ * swap []<-
    repeat _squares !
    { }list _mylist @ foreach
        _v ! pop
        _v @ 2 % if _v @ swap []<- then
    repeat _odds !
    { }list _mylist @ foreach
        _v ! pop
        _v @ 2 % not if _v @ swap []<- then
    repeat _evens !
    { "a" 1 "b" 2 "c" 3 "d" 4 }dict _mydict !
    { }dict _mydict @ foreach
        _v ! _k !
        _v @ _v @ * swap
        _k @ ->[]
    repeat _squarevals !
    { }dict _mydict @ foreach
        _v ! _k !
        _k @ "b" strcmp 0 > if
            _v @ _v @ * swap
            _k @ ->[]
        then
    repeat _foo !
    { }dict _mydict @ foreach
        _v ! _k !
        _v @ 2 > not if
            _v @ _v @ * swap
            _k @ ->[]
        then
    repeat _bar !
    { }list loc @ contents_array foreach
        _obj ! pop
        _obj @ player? dup if _obj @ awake? and then if
            _obj @ name swap []<-
        then
    repeat _listeners !
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _main
;
