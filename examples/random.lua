local Befunge = require 'befunge'

local rand = Befunge.new [[
& :v>00g2/.@
v00_^#!`/2g00:<
>0p:1>>:10p` !|
>+00p^?<*2g01:<
^ g00:<
]]

assert(rand:run() == 'finished')
