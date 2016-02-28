( Generated from classes.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
  
lvar classdata_Person


: _Person_init[ _surname _givenname self -- ret ]
    _surname @
    dup self @ "surname" ->[] self ! pop
    _givenname @
    dup self @ "givenname" ->[] self ! pop
    0 self @
;
  

: _Person_greet[  self -- ret ]
    self @ "surname" []
    self @ "givenname" []
    "Hello, %s %s!"
    fmtstring me @ swap notify 0 pop
    0 self @
;
  

: classinit_Person[ -- ]
    {
        "surname" ""
        "givenname" ""
        "init" '_Person_init
        "greet" '_Person_greet
    }dict classdata_Person !
;

: classnew_Person[ -- inst ]
    classdata_Person @
;

lvar classdata_Employee



: _Employee_init[ _empnum _surname _givenname _ssn _account self -- ret ]
    _empnum @
    dup self @ "empnum" ->[] self ! pop
    _ssn @
    dup self @ "ssn" ->[] self ! pop
    _account @
    dup self @ "account" ->[] self ! pop
    self @ _surname @ _givenname @ _Person_init pop
    0 self @
;
  

: _Employee_welcome[ _company self -- ret ]
    self @ "empnum" []
    self @ "surname" []
    self @ "givenname" []
    _company @
    "Welcome to %s, %s %s, as employee %s."
    fmtstring me @ swap notify 0 pop
    0 self @
;
  

: classinit_Employee[ -- ]
    {
        "empnum" 0
        "ssn" ""
        "account" ""
        "init" '_Employee_init
        "welcome" '_Employee_welcome
    }dict
    classdata_Person @ foreach rot rot ->[] repeat
    classdata_Employee !
;

: classnew_Employee[ -- inst ]
    classdata_Employee @
;

: _main[ _arg -- ret ]
    var _emp
    classnew_Employee 12345 "Doe" "John" "123-45-6789" "jdoe" _Employee_init
    dup _emp ! pop
    {
        _emp @ dup "welcome" []
        dup address? if
            execute _emp !
        else
            } popn "Method \"welcome\" not found in classes.muv line 47" abort
        then
    }list
    dup array_count 2 < if 0 [] then pop
    {
        _emp @ dup "greet" []
        dup address? if
            execute _emp !
        else
            } popn "Method \"greet\" not found in classes.muv line 48" abort
        then
    }list
    dup array_count 2 < if 0 [] then pop
    0
;
  
: __start
    "me" match me !
    me @ location loc !
    trig trigger !
    classinit_Person
    classinit_Employee
    _main
;
