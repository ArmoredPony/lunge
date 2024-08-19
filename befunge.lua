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

---@alias Status 'going'|'finished'|'outofbounds'|'badchar'|'notsupported'

-- type `Module` is declared within type `Befunge`, may use this for enums/ADTs
---@class Befunge.Module
local Befunge = {
  ROWS = 25,
  COLS = 80
}

-- type is defined independently of data, which is great. the syntax is not
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
  return t
end

---@param self Befunge
function Befunge.move(self)
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
  if #self.stack > 0 then
    return self.stack[#self.stack]
  end
end

---@param self Befunge
---@return integer
function Befunge.pop(self)
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
---@return 'outofbounds'?
---@nodiscard
function Befunge.putchar(self, x, y, c)
  x, y = x + 1, y + 1 -- why Lua, why arrays are indexing from 1?
  if y < 1 or x < 1 or y > Befunge.ROWS or x > Befunge.COLS then
    return 'outofbounds'
  end
  self.grid[y][x] = c
end

---@param self Befunge
---@param x integer
---@param y integer
---@return string|'outofbounds'
function Befunge.getchar(self, x, y)
  x, y = x + 1, y + 1 -- ugh
  if y < 1 or x < 1 or y > Befunge.ROWS or x > Befunge.COLS then
    return 'outofbounds'
  end
  return self.grid[y][x]
end

---@param self Befunge
---@param c string
---@return Status
---@nodiscard
function Befunge.interpretchar(self, c)
  if c == '"' then
    self.asciiMode = not self.asciiMode
  elseif self.asciiMode then
    self:push(string.byte(c))
  elseif c == '@' then
    return 'finished'
  elseif c == ' ' then
    return 'going'
  elseif c >= '0' and c <= '9' then
    local v = tonumber(c) or error 'bad num conversion'
    self:push(v)
  elseif directions[c] then
    self.direction = directions[c]
  elseif binops[c] then
    local a, b = self:pop(), self:pop()
    local v = binops[c](a, b)
    self:push(v)
  elseif c == '!' then
    self:push(self:pop() == 0 and 1 or 0)
  elseif c == '?' then
    self.direction = directions[math.random(4)] or error 'bad direction index'
  elseif c == '_' then
    if self:pop() == 0 then
      self.direction = 'right'
    else
      self.direction = 'left'
    end
  elseif c == '|' then
    if self:pop() == 0 then
      self.direction = 'down'
    else
      self.direction = 'up'
    end
  elseif c == ':' then -- elseif ':' then
    local v = self:peek()
    if v then self:push(v) end
  elseif c == '\\' then
    local a, b = self:pop(), self:pop()
    self:push(a)
    self:push(b)
  elseif c == '$' then
    self:pop()
  elseif c == '.' then
    print(tonumber(self:pop()))
  elseif c == ',' then
    print(string.char(self:pop()))
  elseif c == '#' then
    self:move()
  elseif c == 'p' then
    local y = self:pop()
    local x = self:pop()
    local v = self:pop()
    local e = self:putchar(x, y, string.char(v))
    if e then return e end
  elseif c == 'g' then
    local y = self:pop()
    local x = self:pop()
    local ch = self:getchar(x, y)
    if ch == 'outofbounds' then return ch end
    self:push(string.byte(ch))
  elseif c == '&' or c == '~' then
    return 'notsupported'
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
