local lexer = require "lang.lexer"

---@class Parser
---@field code string
---@field lexer Lexer
local parser = {}
parser.__index = parser

function parser.new(code)
  local self = setmetatable({
    code = code,
    lexer = lexer.new(code)
  }, parser)

  self:nextToken()

  return self
end

function parser:nextToken()
  self.curToken = self.lexer:nextToken()
end

function parser:expect(type)
  if self.curToken.type ~= type then
    error(("expected %s, got %s"):format(type, self.curToken.type), 0)
  end
  self:nextToken()
end

function parser:parseValue()
  local t = self.curToken

  if t.type == "number" then
    if t.value == nil then
      error("malformed number", 0)
    end
    self:nextToken()
    return { type = "number", value = t.value }
  end

  if t.type == "name" then
    self:nextToken()
    return { type = "name", value = t.value }
  end

  if t.type == "lparen" then
    self:nextToken()
    local value = self:parseValueList()
    self:expect("rparen")
    return value
  end
end

function parser:parseValueList()
  local values = {}

  local v = self:parseValue()
  while v do
    table.insert(values, v)
    v = self:parseValue()
  end

  return { type = "list", value = values }
end

return parser
