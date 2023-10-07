local shallowCopy = require "util.shallowCopy"

-- evaluates an expression and runs it
local function luaEvalRun(value)
  if value.type == "nil" then
    return nil
  end

  if value.type == "number" then
    return value.value
  end

  if value.type == "call" then
    if value.func.dontEvaluateLuaArgs then
      return value.func.func(value.args)
    else
      local evaledArgs = {}
      for i, v in ipairs(value.args) do
        evaledArgs[i] = luaEvalRun(v)
      end
      return value.func.func(evaledArgs)
    end
  end

  if value.type == "variable" then
    return value.func()
  end

  if value.type == "list" then
    return value.value
  end

  error(("can't evaluate value of type %q"):format(value.type))
end

local builtins = {
  compose = {
    type = "function",
    minArgs = 0,
    argTypes = { "composition" },
    returnType = "composition",
    dontEvaluateLuaArgs = true,
    func = function(args)
      love.graphics.push("all")

      for _, a in ipairs(args) do
        luaEvalRun(a)
      end

      love.graphics.pop()
    end
  },

  color = {
    type = "function",
    minArgs = 3,
    maxArgs = 4,
    argTypes = { "number", "number", "number", "number" },
    returnType = "composition",
    func = function(args)
      love.graphics.setColor(args)
    end
  },

  translate = {
    type = "function",
    numArgs = 2,
    argTypes = { "number", "number" },
    returnType = "composition",
    func = function(args)
      love.graphics.translate(args[1], args[2])
    end
  },

  circle = {
    type = "function",
    numArgs = 3,
    argTypes = { "number", "number", "number" },
    returnType = "composition",
    func = function(args)
      love.graphics.circle("fill", args[1], args[2], args[3])
    end
  },

  time = {
    type = "variable",
    varType = "number",
    func = function()
      return love.timer.getTime()
    end
  },

  sin = {
    type = "function",
    numArgs = 1,
    argTypes = { "number" },
    returnType = "number",
    func = function(args)
      return math.sin(args[1])
    end
  },

  cos = {
    type = "function",
    numArgs = 1,
    argTypes = { "number" },
    returnType = "number",
    func = function(args)
      return math.cos(args[1])
    end
  },
}

local mathOps = {
  ["+"] = function(a, b)
    return a + b
  end,
  ["-"] = function(a, b)
    return a - b
  end,
  ["*"] = function(a, b)
    return a * b
  end,
  ["/"] = function(a, b)
    return a / b
  end,
}

for operator, func in pairs(mathOps) do
  builtins[operator] = {
    type = "function",
    minArgs = 1,
    argTypes = { "number" },
    returnType = "number",
    func = function(args)
      local total = args[1]
      for i = 2, #args do
        total = func(total, args[i])
      end
      return total
    end,
  }
end

for name, func in pairs(builtins) do
  if func.type == "function" then
    func.name = name
  end
end

-- returns the actual type of the value that this expression gives
local function getValueType(value)
  if value.type == "call" then
    return value.func.returnType
  end
  if value.type == "variable" then
    return value.varType
  end
  return value.type
end

local function eval(value, scope)
  if value.type == "name" then
    if not scope[value.value] then
      error(("name %q not found"):format(value.value), 0)
    end
    return scope[value.value]
  end

  if value.type == "list" then
    local list = value.value

    if #list == 0 then
      return { type = "nil" }
    end

    local calledValue = eval(list[1], scope)
    local calledType = getValueType(calledValue)
    if calledType == "function" then
      local func = calledValue

      local numArgs = #list - 1
      if (func.numArgs and numArgs ~= func.numArgs) or (func.minArgs and numArgs < func.minArgs) or (func.maxArgs and numArgs > func.maxArgs) then
        error(("function %q expected %s arguments, but got %d"):format(
          func.name,
          func.numArgs and
          ("exactly %d"):format(func.numArgs) or (
            func.maxArgs and
            ("betweed %d and %d"):format(func.minArgs, func.maxArgs) or
            ("%d or more"):format(func.minArgs)
          ),
          numArgs), 0)
      end

      local args = {}
      for i = 1, numArgs do
        local v = eval(list[i + 1], scope)
        local valueType = getValueType(v)
        local expectedType = func.argTypes[i] or func.argTypes[#func.argTypes]
        if valueType ~= expectedType then
          error(
            ("argument #%d of %q expected to be of type %q, but got %q"):format(i, func.name, expectedType, valueType), 0)
        end
        args[i] = v
      end

      return {
        type = "call",
        func = func,
        args = args
      }
    else
      error(("value of type %q cannot be called"):format(calledType), 0)
    end
  end

  return value
end

local function evalFile(tree)
  if tree.type ~= "list" then
    error("the value of a file should be a list")
  end

  local scope = shallowCopy(builtins)

  local values = {}

  for i, value in ipairs(tree.value) do
    values[i] = eval(value, scope)
  end

  return {
    type = "call",
    func = builtins.compose,
    args = values
  }
end

return {
  evalFile = evalFile,
  luaEvalRun = luaEvalRun
}
