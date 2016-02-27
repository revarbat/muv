$def ivar_new  (            v) dup @ dup "idx" [] 1 + dup rot "idx" ->[] rot !
$def ivar_set  (x inst attr v) -4 rotate { rot rot }list 3 pick @ swap ->[] swap !
$def ivar_get  (  inst attr v) { 4 rotate 4 rotate }list swap @ swap array_nested_get
$def ivar_exec (  inst mthd v) ivar_get dup address? if execute else pop "Method not found." abort then


lvar cls_person;


: m_person__init[ self surname givenname -- ]
    surname   @ dup self @ "surname"   cls_person ivar_set pop
    givenname @ dup self @ "givenname" cls_person ivar_set pop
    self @ exit 0
;


: m_person__greet[ self -- ]
    me @
    {
        "Hello "
        self @ "givenname" cls_person ivar_get
        " "
        self @ "surname" cls_person ivar_get
        "!"
    }cat
    notify
    0
;


: classinit_person[ self -- ]
    {
        "idx" 100
        "surname"   ""
        "givenname" ""
        "greet" 'm_person__greet
    }dict cls_person !
;


lvar cls_employee;


: m_employee__init[ self empnum surname givenname ssn account -- ]
    empnum  @ self @ "empnum"  cls_employee ivar_set pop
    ssn     @ self @ "ssn"     cls_employee ivar_set pop
    account @ self @ "account" cls_employee ivar_set pop
    self @ surname @ givenname @ method_person__init
    exit 0
;


: m_employee__welcome[ self -- ]
    {
        self @ "empnum" cls_employee ivar_get
        self @ "surname" cls_employee ivar_get
        self @ "givenname" cls_employee ivar_get
    }list
    "Welcome %s %s, as employee %s."
    fmtstring
    me @ swap notify 0 pop
    0
;


: classinit_employee[ self -- ]
    {
        "idx" 100
        "empnum"  ""
        "ssn"     ""
        "account" ""
        "welcome" 'm_employee__welcome
    }dict cls_employee !
;


: _main[ arg -- ]
    var emp
    12345 "Doe" "John" "123-45-6789" "jdoe" cls_employee ivar_new
    dup emp ! pop
    emp @ "greet" cls_employee ivar_exec pop
    emp @ "welcome" cls_employee ivar_exec pop
    0
;


: __start[ arg -- ret ]
    classinit_person
    classinit_employee
    _main
;



