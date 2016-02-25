( Generated from test_511_in.muv by the MUV compiler. )
(   https://github.com/revarbat/muv )

: _showspecies[  -- ret ]
    var _obj
    loc @ contents_array
    foreach _obj ! pop
        _obj @ player? if
            "%-30D %-10s %-30s" {

                _obj @
                _obj @ "sex" getpropstr
                _obj @ "species" getpropstr
            }list 
            2 try
                array_explode 1 + rotate fmtstring
                me @ swap notify
                depth popn
            catch abort
            endcatch 0 pop
        then
    repeat 0
;

: __start
    "me" match me !
    me @ location loc !
    trig trigger !
    _showspecies
;
