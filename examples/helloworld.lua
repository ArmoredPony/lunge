local Befunge = require 'befunge'

local hw = Befunge.new [[
>              v
v"Hello World!"<
>:v
^,_@
]]
assert(hw:run() == 'finished')
