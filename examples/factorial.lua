local Befunge = require 'befunge'

local fac = Befunge.new [[
&>:1-:v v *_$.@
 ^    _$>\:^
]]
assert(fac:run() == 'finished')
