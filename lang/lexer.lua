---@class Lexer
---@field code string
---@field index number
---@field column number
---@field line number
---@field finished boolean
local lexer = {}
lexer.__index = lexer

function lexer.new(code)
  return setmetatable({
    code = code,
    index = 1,
    column = 1,
    line = 1,
    finished = #code == 0,
  }, lexer)
end

function lexer:advance(count)
  count = count or 1
  for i = 1, count do
    self.index = self.index + 1
    if self:curChar() == "\n" then
      self.line = self.line + 1
      self.column = 0
    else
      self.column = self.column + 1
    end
  end
  self.finished = self.index > #self.code
end

---@return string
function lexer:charAt(i)
  return self.code:sub(i, i)
end

---@return string
function lexer:curChar()
  return self:charAt(self.index)
end

function lexer:nextToken()
  -- skip whitespace and comments
  while self:curChar():match("[%s%;]") and not self.finished do
    if self:curChar() == ";" then
      while self:curChar() ~= "\n" and not self.finished do
        self:advance()
      end
    end
    self:advance()
  end

  if self.finished then
    return { type = "EOF" }
  end

  if self:curChar() == "(" then
    self:advance()
    return { type = "lparen" }
  end

  if self:curChar() == ")" then
    self:advance()
    return { type = "rparen" }
  end

  if self:curChar():match("%d") or (self:curChar() == "-" and self:charAt(self.index + 1):match("%d")) then
    local start = self.index
    if self:curChar() == "-" then
      self:advance()
    end
    while self:curChar():match("[%d%.]") do
      self:advance()
    end
    return { type = "number", value = tonumber(self.code:sub(start, self.index - 1)) }
  end

  -- any other token
  local start = self.index
  while self:curChar():match("[^%s%;%(%)]") and not self.finished do
    self:advance()
  end
  return { type = "name", value = self.code:sub(start, self.index - 1) }
end

return lexer
