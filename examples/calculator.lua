local Befunge = require 'befunge'

local calc = Befunge.new [[
"rotaluclaC egnufeB">:v
                    |,<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                    >52*:,,"/4 *3 -2 +1">:v     ^^^^
                                        |,<     ^^^^
                                        >52*:,,v^^^^
                                        v<<<<<<<^^^^
                                        &       ^^^^
                                        :       ^^^^
                                        1       ^^^^
                                        -       ^^^^
                                       v_$&&+.$>^^^^
                                       :         ^^^
                                       2         ^^^
                                       -         ^^^
                                      v_$&&-.$>>>^^^
                                      :           ^^
                                      3           ^^
                                      -           ^^
                                     v_$&&*.$>>>>>^^
                                     :             ^
                                     4             ^
                                     -             ^
                                    @_$&&/.$>>>>>>>^
]]
assert(calc:run() == 'finished')
