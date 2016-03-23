( Generated from test_507_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
: _helloworld[  -- ret ]
    "Hello World!"
;
: _arraydemo[  -- ret ]
    var _myarr
    { }list _myarr !
    42 dup _myarr @ 23 ->[] _myarr ! pop
    _myarr @ 23 [] me @ swap notify
    0
;
: _first_word[ _thing -- ret ]
    var _words
    { _thing @ " " split }list _words !
    _words @ 0 []
;
: _submit[ _arg -- ret ]
    var _newobj var _word var _newname
    _arg @ "" strcmp not if
        "Enter your submission here:" me @ swap notify
        read _arg !
    then
    #1981 copyobj _newobj !
    _arg @ _first_word _word !
    { me @ name "'s submission (" _word @ ")" }list
    array_interpret _newname !
    _newobj @ _newname @ setname
    _newobj @ _arg @ setdesc
    _newobj @ #1976 moveto
    "Thank you for the submission." me @ swap notify
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    _submit
;
