---@alias Direction 'up'|'down'|'left'|'right' -- union type aliases
---@alias DirectionKey '>'|'<'|'^'|'v' -- good, but it's better to tag variants

-- classic ADT would be horrible here. { One(1), Two(2), ... } ???
---@alias DirectionNumericKey 1|2|3|4

-- generics are great. Angle brackets are not. Use square brackets instead.
-- union type formed from union types inside a generic is horrible.
-- good luck understanding that type a week after.
---@type table<DirectionKey|DirectionNumericKey, Direction>
local directions <const> = {
  ['<'] = 'left',
  ['>'] = 'right',
  ['^'] = 'up',
  ['v'] = 'down',
  [1]   = 'left',
  [2]   = 'right',
  [3]   = 'up',
  [4]   = 'down',
}
-- really need static compile-time checked `tables`

-- function types are great, functions themselves not that much.
-- may just use tables instead
---@alias BinOp fun(a: integer, b: integer): integer
---@alias BinOpKey '+'|'-'|'*'|'/'|'%'|'`'
---@type table<BinOpKey, BinOp>
local binops <const> = {
  ['+'] = function (a, b) return a + b end,
  ['-'] = function (a, b) return b - a end,
  ['*'] = function (a, b) return a * b end,
  ['/'] = function (a, b) return a == 0 and 0 or b // a end,
  ['%'] = function (a, b) return math.fmod(b, a) end,
  ['`'] = function (a, b) return b > a and 1 or 0 end
}

---@alias Status
---| 'going'
---| 'finished'
---| 'outofbounds'
---| 'badchar'
---| 'badinput'

-- type `Module` is declared within type `Befunge`, may use this for enums/ADTs
---@class Befunge.Module
local Befunge = {
  ROWS = 25,
  COLS = 80
}

-- type is defined independently of data, which is great. the syntax is not.
-- also had to declare fields as a part of public contract. fields are a good
-- candidate for type inference. only public API should be exposed in contracts
---@class Befunge: Befunge.Module
---@field stack integer[]
---@field grid string[][]
---@field direction Direction
---@field status Status
---@field asciiMode boolean
---@field x integer
---@field y integer

---@param code string
---@return Befunge
function Befunge.new(code)
  local grid = {}
  for i = 1, Befunge.ROWS do -- need iterators, even Java has those
    local row = {}
    for j = 1, Befunge.COLS do row[j] = ' ' end
    -- square brackets are redundant for calls and may be used for generics
    grid[i] = row
  end

  local i = 1
  for line in code:gmatch '[^\n]+' do -- ugh
    local j = 1
    for ch in line:gmatch '.' do
      grid[i][j] = ch
      j = j + 1
    end
    i = i + 1
  end

  -- this typecheck should be made automatically since `t` is returned from
  -- the function
  ---@type Befunge
  local t = {
    stack     = {},
    grid      = grid,
    direction = 'right',
    status    = 'going',
    asciiMode = false,
    x         = 1,
    y         = 1
  }
  -- metatables are great. need to emulate their power somehow. maybe replace
  -- with compile time code generaion
  setmetatable(t, {
    __index = Befunge
  })
  -- don't need explicit `return` before the last expression
  return t
end

---@param self Befunge
function Befunge.move(self)
  -- typical Lua problem: `direction` is guaranteed to always be valid, have the
  -- same memory location and return a value of `Direction` type. but since Lua
  -- is so dynamic, each time we descent into the table, calculate `direction`
  -- hash and it always may be `nil`.
  --
  -- we may cache the value in a local variable, but we wont be able to update
  -- it or read updates.
  local d = self.direction
  if d == 'up' then self.x = self.x - 1 end -- need pattern matching here
  if d == 'down' then self.x = self.x + 1 end
  if d == 'left' then self.y = self.y - 1 end
  if d == 'right' then self.y = self.y + 1 end
  if self.x > Befunge.ROWS then self.x = 1 end
  if self.x < 1 then self.x = Befunge.ROWS end
  if self.y > Befunge.COLS then self.y = 1 end
  if self.y < 1 then self.y = Befunge.COLS end
end

---@param self Befunge
---@return integer?
function Befunge.peek(self)
  return self.stack[#self.stack]
end

---@param self Befunge
---@return integer
function Befunge.pop(self)
  -- `x and y or z` is great, needs implicit trait though, like `Truthy`
  return table.remove(self.stack, #self.stack) or 0
end

---@param self Befunge
---@param v integer
function Befunge.push(self, v)
  self.stack[#self.stack+1] = v
end

---@param self Befunge
---@param x integer
---@param y integer
---@param c string
---@return true?, 'outofbounds'?
---@nodiscard
function Befunge.putchar(self, x, y, c)
  x, y = x + 1, y + 1 -- why Lua, why are arrays indexed from 1?
  if y < 1 or x < 1 or y > Befunge.ROWS or x > Befunge.COLS then
    -- this error handling convention is weird, need ADTs/union types
    return nil, 'outofbounds'
  end
  self.grid[y][x] = c
  return true
end

---@param self Befunge
---@param x integer
---@param y integer
---@return string?, 'outofbounds'?
function Befunge.getchar(self, x, y)
  x, y = x + 1, y + 1 -- ugh
  if y < 1 or x < 1 or y > Befunge.ROWS or x > Befunge.COLS then
    return nil, 'outofbounds'
  end
  return self.grid[y][x]
end

---@param self Befunge
---@param c string
---@return Status
---@nodiscard
function Befunge.interpretchar(self, c)
  -- super need pattern matching here
  -- Lua won't prevent you from doing a silly mistake like `if '"' then ...`
  -- totally need some `Truthy` trait
  if c == '"' then
    self.asciiMode = not self.asciiMode
  elseif self.asciiMode then
    self:push(string.byte(c))
  elseif c == '@' then
    return 'finished'
  elseif c == ' ' then
    return 'going'
  elseif c >= '0' and c <= '9' then
    -- also need to match predicates
    local v = tonumber(c) or error 'bad num conversion'
    self:push(v)
  elseif directions[c] then
    self.direction = directions[c]
  elseif binops[c] then
    -- multiple assignment is good
    local a, b = self:pop(), self:pop()
    local v = binops[c](a, b)
    self:push(v)
  elseif c == '!' then
    self:push(self:pop() == 0 and 1 or 0)
  elseif c == '?' then
    -- `or panic` is a good and readable pattern
    self.direction = directions[math.random(4)] or error 'bad direction index'
  elseif c == '_' then
    self.direction = self:pop() == 0 and 'right' or 'left'
  elseif c == '|' then
    self.direction = self:pop() == 0 and 'down' or 'up'
  elseif c == ':' then
    -- can't cache values in `x and y` expression, must store in local scope
    local v = self:peek()
    if v then self:push(v) end
  elseif c == '\\' then
    local a, b = self:pop(), self:pop()
    self:push(a)
    self:push(b)
  elseif c == '$' then
    self:pop()
  elseif c == '.' then
    -- parenthesis hell can be avoided with piping/mapping values
    io.write(tonumber(self:pop()))
  elseif c == ',' then
    io.write(string.char(self:pop()))
  elseif c == '#' then
    self:move()
  elseif c == 'p' then
    local y = self:pop()
    local x = self:pop()
    local v = self:pop()
    -- multiple return is also good
    local succ, err = self:putchar(x, y, string.char(v))
    -- this error handling style is not
    if not succ then ---@cast err -nil
      return err
    end
  elseif c == 'g' then
    local y = self:pop()
    local x = self:pop()
    local ch, err = self:getchar(x, y)
    if not ch then ---@cast err -nil
      return err
    end
    self:push(string.byte(ch))
  elseif c == '&' then
    local i = io.read('n')
    if not i then return 'badinput' end
    self:push(i)
  elseif c == '~' then
    local ch = io.read(1)
    if not ch then return 'badinput' end
    self:push(string.byte(ch))
  else
    return 'badchar'
  end
  return 'going'
end

---@param self Befunge
---@return Status
function Befunge.advance(self)
  local ch = self.grid[self.x][self.y]
  local s = self:interpretchar(ch)
  self.status = s
  -- calls with `:` are redundant, we can decide if we need `self` at compile time
  self:move()
  return s
end

---@param self Befunge
---@return Status
function Befunge.run(self)
  while self.status == 'going' do
    self:advance()
  end
  return self.status
end

return Befunge
