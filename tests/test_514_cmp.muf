( Generated from test_514_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )
lvar argparse::current_mode
lvar argparse::modes_list
lvar argparse::flags_map
lvar argparse::posargs_map
lvar argparse::remainder_map
: argparse::init[  -- ret ]
    "" dup argparse::current_mode ! pop
    { }list dup argparse::modes_list ! pop
    { }dict dup argparse::flags_map ! pop
    { }dict dup argparse::posargs_map ! pop
    { "" "remainder" }dict dup argparse::remainder_map ! pop
    0
;
: argparse::parse_posargs[ _mode _posargs -- ret ]
    var _tok
    begin
        { _posargs @ "^([a-z0-9_]*)([^a-z0-9_])(.*)$" 1 regexp }list 0 []
        dup _tok ! pop
        _tok @ if
            argparse::posargs_map @ _mode @ [] not if
                { }list
                dup argparse::posargs_map @ _mode @ ->[] argparse::posargs_map ! pop
            then
            argparse::posargs_map @ _mode @ over over []
            { _tok @ 1 [] tolower _tok @ 2 [] }list dup rot []<-
            4 rotate 4 rotate ->[] argparse::posargs_map ! pop
            _tok @ 3 [] dup _posargs ! pop
        else
            _posargs @ tolower
            dup argparse::remainder_map @ _mode @ ->[] argparse::remainder_map ! pop
            break
        then
    repeat
    0
;
: argparse::set_mode[ _name -- ret ]
    _name @ tolower dup _name ! pop
    _name @ dup argparse::current_mode ! pop
    0
;
: argparse::add_mode[ _name _flags _posargs -- ret ]
    var _flag
    _name @ tolower dup _name ! pop
    argparse::modes_list @ _name @ dup rot []<-
    argparse::modes_list ! pop
    { }list
    dup argparse::flags_map @ _name @ ->[] argparse::flags_map ! pop
    { }list
    dup argparse::posargs_map @ _name @ ->[] argparse::posargs_map ! pop
    _flags @ foreach
        _flag ! pop
        argparse::flags_map @ _name @ [] not if
            { }list
            dup argparse::flags_map @ _name @ ->[] argparse::flags_map ! pop
        then
        argparse::flags_map @ _name @ over over [] _flag @ tolower
        dup rot []<- 4 rotate 4 rotate ->[] argparse::flags_map ! pop
    repeat
    _name @ _posargs @ argparse::parse_posargs pop
    0
;
: argparse::add_flag[ _name -- ret ]
    var _mode
    _name @ tolower dup _name ! pop
    argparse::modes_list @ foreach
        _mode ! pop
        _mode @ tolower dup _mode ! pop
        argparse::modes_list @ _mode @ array_findval not if
            _mode @ _name @
            "ArgParse: Option '%s' declared as part of non-existent mode '%s'!"
            fmtstring abort 0 pop
        then
        argparse::flags_map @ _mode @ [] not if
            { }list
            dup argparse::flags_map @ _mode @ ->[] argparse::flags_map ! pop
        then
        argparse::flags_map @ _mode @ over over [] _name @
        dup rot []<- 4 rotate 4 rotate ->[] argparse::flags_map ! pop
    repeat
    0
;
: argparse::add_posargs[ _posargs -- ret ]
    var _mode
    argparse::modes_list @ foreach
        _mode ! pop
        _mode @ tolower dup _mode ! pop
        argparse::modes_list @ _mode @ array_findval not if
            _mode @ _mode @
            "ArgParse: Option '%s' declared as part of non-existent mode '%s'!"
            fmtstring abort 0 pop
        then
        _mode @ _posargs @ argparse::parse_posargs pop
    repeat
    0
;
: argparse::show_usage[  -- ret ]
    var _cmd var _mode var _flags var _flag var _posargs
    var _posarg var _line
    trig name ";" split pop strip dup _cmd ! pop
    "Usage:" me @ swap notify 0 pop
    argparse::modes_list @ foreach
        _mode ! pop
        { }list argparse::flags_map @ _mode @ []
        foreach _flag ! pop
            { "[#" _flag @ "]" }list array_interpret swap []<-
        repeat dup _flags ! pop
        { }list argparse::posargs_map @ _mode @ []
        foreach _posarg ! pop
            { _posarg @ 0 [] toupper _posarg @ 1 [] }list array_interpret swap []<-
        repeat dup _posargs ! pop
        argparse::remainder_map @ _mode @ [] toupper
        _posargs @ "" array_join _flags @ if " " else "" then
        _flags @ " " array_join _mode @ _mode @ if "#" else "" then
        _cmd @ "%s %s%s %s%s%s%s" fmtstring dup _line ! pop
        _line @ me @ swap notify 0 pop
    repeat
    0
;
: argparse::parse[ _line -- ret ]
    var _parts var _mode var _flag var _opts var _mode_given
    var _opt var _lc_opt var _found var _posarg
    { }dict dup _opts ! pop
    0 dup _mode_given ! pop
    begin
        _line @ "#" stringpfx
    while
        { { _line @ 1 strcut }list 1 [] " " split }list dup _parts ! pop
        _parts @ 0 [] dup _opt ! pop
        _opt @ tolower dup _lc_opt ! pop
        0 dup _found ! pop
        argparse::modes_list @ foreach
            _mode ! pop
            _mode @ _lc_opt @ stringcmp not if
                _mode @ dup argparse::current_mode ! pop
                _found @ dup ++ _found ! pop
                break
            then
        repeat
        _found @ if
            _mode_given @ dup ++ _mode_given ! pop
            _parts @ 1 [] dup _line ! pop
            continue
        then
        argparse::flags_map @ argparse::current_mode @ [] foreach
            _flag ! pop
            _flag @ _lc_opt @ stringcmp not if
                _opt @ dup _opts @ _flag @ ->[] _opts ! pop
                _found @ dup ++ _found ! pop
                break
            then
        repeat
        _found @ if
            _parts @ 1 [] dup _line ! pop
            continue
        then
        argparse::modes_list @ foreach
            _mode ! pop
            _mode @ _lc_opt @ stringpfx if
                _mode @ dup argparse::current_mode ! pop
                _found @ dup ++ _found ! pop
            then
        repeat
        argparse::flags_map @ argparse::current_mode @ [] foreach
            _flag ! pop
            _flag @ _lc_opt @ stringpfx if
                _opt @ dup _opts @ _flag @ ->[] _opts ! pop
                _found @ dup ++ _found ! pop
            then
        repeat
        _found @ 1 = if
            _parts @ 1 [] dup _line ! pop
            continue
        else
            _found @ 1 > if
                _opt @ "Option #%s is ambiguous." fmtstring me @ swap notify 0 pop
            else
                _opt @ "Option #%s not recognized." fmtstring
                me @ swap notify 0 pop
            then
        then
        argparse::show_usage pop
        { }list exit
    repeat
    _mode_given @ 1 > if
        "Cannot mix modes." me @ swap notify 0 pop
        argparse::show_usage pop
        { }list exit
    then
    argparse::posargs_map @ argparse::current_mode @ [] foreach
        _posarg ! pop
        { _line @ _posarg @ 1 [] split }list dup _parts ! pop
        _parts @ 0 [] dup _opts @ _posarg @ 0 [] ->[] _opts ! pop
        _parts @ 1 [] dup _line ! pop
    repeat
    _line @
    dup _opts @ argparse::remainder_map @ argparse::current_mode @ [] ->[] _opts ! pop
    argparse::current_mode @ dup _opts @ "mode" ->[] _opts ! pop
    _opts @ exit
    0
;
: _verify[ _override _msg -- ret ]
    _override @ if 1 exit then
    { "Are you sure you want to " _msg @ "?" }list
    array_interpret me @ swap notify 0 pop
    { read 1 strcut }list 0 [] "y" stringcmp not if 1 exit then
    "Cancelled." me @ swap notify 0 pop
    0 exit
    0
;
: _handle_mode_list[ _obj _prop -- ret ]
    var _lines var _i var _line
    _obj @ _prop @ array_get_proplist dup _lines ! pop
    _lines @ foreach
        _line ! _i !
        _line @ _i @ 1 + "%3i: %s" fmtstring me @ swap notify 0 pop
    repeat
    "Done." me @ swap notify 0 pop
    0
;
: _handle_mode_append[ _obj _prop _val _force -- ret ]
    var _lines
    _val @ not if
        argparse::show_usage pop
        0 exit
    then
    _force @ "append a line to the list" _verify if
        _obj @ _prop @ array_get_proplist dup _lines ! pop
        _lines @ _val @ dup rot []<- _lines ! pop
        _obj @ _prop @ _lines @ array_put_proplist 0 pop
        "Line appended." me @ swap notify 0 pop
        _obj @ _prop @ _handle_mode_list pop
    then
    0
;
: _handle_mode_delete[ _obj _prop _pos _force -- ret ]
    var _lines
    _pos @ atoi dup _pos ! pop
    _pos @ not if
        argparse::show_usage pop
        0 exit
    then
    _force @ "delete a line from the list" _verify if
        _obj @ _prop @ array_get_proplist dup _lines ! pop
        _lines @ _pos @ 1 - array_delitem dup _lines ! pop
        _obj @ _prop @ _lines @ array_put_proplist 0 pop
        "Line deleted." me @ swap notify 0 pop
        _obj @ _prop @ _handle_mode_list pop
    then
    0
;
: _handle_mode_insert[ _obj _prop _pos _val _force -- ret ]
    var _lines
    _pos @ atoi dup _pos ! pop
    _pos @ not dup not if _val @ not or then if
        argparse::show_usage pop
        0 exit
    then
    _force @ "insert a line into the list" _verify if
        _obj @ _prop @ array_get_proplist dup _lines ! pop
        _val @ _lines @ _pos @ 1 - array_insertitem dup _lines ! pop
        _obj @ _prop @ _lines @ array_put_proplist 0 pop
        "Line inserted." me @ swap notify 0 pop
        _obj @ _prop @ _handle_mode_list pop
    then
    0
;
: _handle_mode_replace[ _obj _prop _pos _val _force -- ret ]
    var _lines
    _pos @ atoi dup _pos ! pop
    _pos @ not dup not if _val @ not or then if
        argparse::show_usage pop
        0 exit
    then
    _force @ "replace a line in the list" _verify if
        _obj @ _prop @ array_get_proplist dup _lines ! pop
        _lines @ _pos @ 1 - array_delitem dup _lines ! pop
        _val @ _lines @ _pos @ 1 - array_insertitem dup _lines ! pop
        _obj @ _prop @ _lines @ array_put_proplist 0 pop
        "Line inserted." me @ swap notify 0 pop
        _obj @ _prop @ _handle_mode_list pop
    then
    0
;
: _main[ _arg -- ret ]
    var _opts var _obj
    argparse::init pop
    "list" argparse::set_mode pop
    "list" { }list "obj=prop" argparse::add_mode pop
    "append" { "force" }list "obj=prop:val" argparse::add_mode pop
    "delete" { "force" }list "obj=prop:pos" argparse::add_mode pop
    "insert" { "force" }list "obj=prop:pos:val"
    argparse::add_mode pop
    "replace" { "force" }list "obj=prop:pos:val"
    argparse::add_mode pop
    "verbose" argparse::add_flag pop
    _arg @ argparse::parse dup _opts ! pop
    _opts @ not if 0 exit then
    _opts @ "obj" [] not dup not if _opts @ "prop" [] not or then if
        argparse::show_usage pop
        0 exit
    then
    _opts @ "obj" [] match
    dup #-1 dbcmp if me @ "I don't see that here!" notify then
    dup #-2 dbcmp if me @ "I don't know which one you mean!" notify then
    dup #-3 dbcmp if pop me @ getlink then
    dup ok? if
        me @ over controls not if
            pop #-1 me @ "Permission denied." notify
        then
    then dup _obj ! pop
    _obj @ 0 < if 0 exit then
    _opts @ "verbose" [] if
        { "Mode = " _opts @ "mode" [] }list array_interpret
        me @ swap notify 0 pop
    then
    0 begin pop (switch)
        _opts @ "mode" []
        dup "list" stringcmp not if
            _obj @ _opts @ "prop" [] _handle_mode_list pop break
        then
        dup "append" stringcmp not if
            _obj @ _opts @ "prop" [] _opts @ "val" [] _opts @ "force" []
            _handle_mode_append pop break
        then
        dup "delete" stringcmp not if
            _obj @ _opts @ "prop" [] _opts @ "pos" [] _opts @ "force" []
            _handle_mode_delete pop break
        then
        dup "insert" stringcmp not if
            _obj @ _opts @ "prop" [] _opts @ "pos" [] _opts @ "val" []
            _opts @ "force" [] _handle_mode_insert pop break
        then
        dup "replace" stringcmp not if
            _obj @ _opts @ "prop" [] _opts @ "pos" [] _opts @ "val" []
            _opts @ "force" [] _handle_mode_replace pop break
        then
        break
    repeat pop
    0
;
: __start
    "me" match me ! me @ location loc ! trig trigger !
    "" argparse::current_mode !
    { }list argparse::modes_list !
    { }dict argparse::flags_map !
    { }dict argparse::posargs_map !
    { "" "remainder" }dict argparse::remainder_map !
    _main
;
