local Befunge = require 'befunge'

local quine = Befunge.new [[
01->1# +# :# 0# g# ,# :# 5# 8# *# 4# +# -# _@
]]
assert(quine:run() == 'finished')
