( Generated from test_507_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )

: _helloworld[  -- ret ]
    "Hello World!" exit 0
;

: _arraydemo[  -- ret ]
    var _myarr
    { }list
    dup _myarr ! pop

    42
    dup _myarr @ 23 ->[] _myarr ! pop

    _myarr @ 23 [] me @ swap notify 0 pop 0
;

: _first_word[ _thing -- ret ]
    var _words
    { _thing @ " " split }list
    dup _words ! pop

    _words @ 0 [] exit 0
;

: _submit[ _arg -- ret ]
    var _new
    var _word
    var _newname
    _arg @ "" strcmp not if
        "Enter your submission here:" me @ swap notify 0 pop

        read
        dup _arg ! pop
    then

    #1981 copyobj
    dup _new ! pop

    _arg @ _first_word
    dup _word ! pop

    {
        me @ name
        "'s submission ("
        _word @
        ")"
    }list array_interpret
    dup _newname ! pop

    _new @ _newname @ setname 0 pop

    _new @ _arg @ setdesc 0 pop

    _new @ #1976 moveto 0 pop

    "Thank you for the submission." me @ swap notify 0 pop 0
;

: __start
    "me" match me !
    me @ location loc !
    trig trigger !
    _submit
;
