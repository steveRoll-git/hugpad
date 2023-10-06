local shallowCopy = require "util.shallowCopy"

local luaEvalRun

local builtins = {
  compose = {
    type = "function",
    minArgs = 0,
    returnType = "composition",
    dontEvaluateLuaArgs = true,
    func = function(args)
      love.graphics.push()

      for _, a in ipairs(args) do
        luaEvalRun(a)
      end

      love.graphics.pop()
    end
  },

  translate = {
    type = "function",
    numArgs = 2,
    argTypes = { "number", "number" },
    returnType = "composition",
    func = function(x, y)
      love.graphics.translate(x, y)
    end
  },

  circle = {
    type = "function",
    numArgs = 3,
    argTypes = { "number", "number", "number" },
    returnType = "composition",
    func = function(x, y, r)
      love.graphics.circle("fill", x, y, r)
    end
  }
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
    func = func,
  }
end

for name, func in pairs(builtins) do
  if func.type == "function" then
    func.name = name
  end
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
    if calledValue.type == "function" then
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
        local valueType = v.type == "call" and v.func.returnType or v.type
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
      error(("value of type %q cannot be called"):format(calledValue.type), 0)
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

-- evaluates an expression and runs it
luaEvalRun = function(value)
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
      return value.func.func(unpack(evaledArgs))
    end
  end

  if value.type == "list" then
    return value.value
  end

  error(("can't evaluate value of type %q"):format(value.type))
end

return {
  evalFile = evalFile,
  luaEvalRun = luaEvalRun
}
