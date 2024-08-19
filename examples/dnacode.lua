local Befunge = require 'befunge'

local dna = Befunge.new [[
7^DN>vA
v_#v? v
7^<""""
3  ACGT
90!""""
4*:>>>v
+8^-1,<
> ,+,@)
]]
assert(dna:run() == 'finished')
