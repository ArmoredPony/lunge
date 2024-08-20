# What
**Lunge** is a Befunge-93 programming language interpreter written in Lua.

# Why
1. I am bored at midnight
2. I hadn't written anything in Lua for a while
3. I couldn't find Befunge interpreter written in Lua
4. I am looking for ways to improve [LuaLS](https://luals.github.io/) type
   system
5. I am looking for ways to improve Lua in general

This code example features some comments about Lua and type annotations for
the aformentioned language server - just ignore those.

# How
Import `Befunge` module with `require 'befunge'`,reate a new interpreter
instance with `Befunge.new('some code')` and run it with `run` method.
Notice how `[[multiline strings]]` are used - *Lua my beloved* got us covered
here too. When `run` stops, it returns interpreter's status.
You also may advance algorithm execution step by step with `advance` method.

See *examples* folder for more algorithms. You can find them (and more) on
esoteric programming languages wiki - [Esolang](https://esolangs.org/wiki/Befunge).

```lua
local Befunge = require 'befunge'

-- "Hello world"
local hw = Befunge.new [[
>              v
v"Hello World!"<
>:v
^,_@
]]
local hwstatus = hw:run()
print()

-- DNA-code
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
local dnastatus = dna:run()

-- Quine
local quine = Befunge.new [[
01->1# +# :# 0# g# ,# :# 5# 8# *# 4# +# -# _@
]]
local quinestatus = quine:run()
print()

for _, s in ipairs{hwstatus, dnastatus, quinestatus} do
  assert(s == 'finished')
end
```
