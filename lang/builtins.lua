local shallowCopy = require "util.shallowCopy"

local eval = require "lang.eval".eval
local getValueType = require "lang.eval".getValueType

local builtins = {
  let = {
    type = "form",
    numArgs = 2,
    func = function(args, scope)
      if args[1].type ~= "list" then
        error('first parameter of "let" must be a list of variable declarations')
      end

      local varList = args[1].value
      local newScope = shallowCopy(scope)
      local bindings = {}

      for _, var in ipairs(varList) do
        if var.type ~= "list" or #var.value ~= 2 or var.value[1].type ~= "name" then
          error('variable declarations in "let" must be lists with a name and value')
        end
        local varName = var.value[1].value
        local varValue = eval(var.value[2], scope)
        newScope[varName] = {
          type = "binding",
          name = varName,
          varType = getValueType(varValue)
        }
        table.insert(bindings, {
          name = varName,
          value = varValue
        })
      end

      return {
        type = "bindingScope",
        bindings = bindings,
        body = eval(args[2], newScope)
      }
    end
  },

  ["if"] = {
    type = "form",
    numArgs = 3,
    func = function(args, scope)
      local condition = eval(args[1], scope)
      local t = getValueType(condition)
      if t ~= "boolean" then
        error(('"if" condition must be of type "boolean", but it was %q'):format(t))
      end
      local trueBody = eval(args[2], scope)
      local trueT = getValueType(trueBody)
      local falseBody = eval(args[3], scope)
      local falseT = getValueType(falseBody)
      if trueT ~= falseT then
        error(('"if" return types must match (got %q and %q)'):format(trueT, falseT))
      end
      return {
        type = "if",
        condition = eval(args[1], scope),
        trueBody = trueBody,
        falseBody = falseBody
      }
    end
  },

  compose = {
    type = "function",
    minArgs = 0,
    argTypes = { "composition" },
    returnType = "composition",
    runtimeFunc = function(args)
      return {
        action = "compose",
        body = args
      }
    end
  },

  color = {
    type = "function",
    minArgs = 3,
    maxArgs = 4,
    argTypes = { "number", "number", "number", "number" },
    returnType = "composition",
    runtimeFunc = function(args)
      return {
        action = "setColor",
        color = args
      }
    end
  },

  translate = {
    type = "function",
    numArgs = 2,
    argTypes = { "number", "number" },
    returnType = "composition",
    runtimeFunc = function(args)
      return {
        action = "translate",
        x = args[1],
        y = args[2]
      }
    end
  },

  circle = {
    type = "function",
    numArgs = 3,
    argTypes = { "number", "number", "number" },
    returnType = "composition",
    runtimeFunc = function(args)
      return {
        action = "circle",
        drawMode = "fill",
        x = args[1],
        y = args[2],
        radius = args[3],
      }
    end
  },

  time = {
    type = "variable",
    varType = "number",
    runtimeFunc = function()
      return love.timer.getTime()
    end
  },

  sin = {
    type = "function",
    numArgs = 1,
    argTypes = { "number" },
    returnType = "number",
    runtimeFunc = function(args)
      return math.sin(args[1])
    end
  },

  cos = {
    type = "function",
    numArgs = 1,
    argTypes = { "number" },
    returnType = "number",
    runtimeFunc = function(args)
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
    runtimeFunc = function(args)
      local total = args[1]
      for i = 2, #args do
        total = func(total, args[i])
      end
      return total
    end,
  }
end

local compOps = {
  [">"] = function(a, b)
    return a > b
  end,
  ["<"] = function(a, b)
    return a < b
  end,
  [">="] = function(a, b)
    return a >= b
  end,
  ["<="] = function(a, b)
    return a <= b
  end,
  ["="] = function(a, b)
    return a == b
  end,
}

for operator, func in pairs(compOps) do
  builtins[operator] = {
    type = "function",
    minArgs = 1,
    argTypes = { "number" },
    returnType = "boolean",
    runtimeFunc = function(args)
      for i = 1, #args - 1 do
        if not func(args[i], args[i + 1]) then
          return false
        end
      end
      return true
    end,
  }
end

builtins["not="] = {
  type = "function",
  minArgs = 1,
  argTypes = { "number" },
  returnType = "boolean",
  runtimeFunc = function(args)
    for i = 1, #args - 1 do
      for j = i + 1, #args do
        if args[i] == args[j] then
          return false
        end
      end
    end
    return true
  end
}

for name, func in pairs(builtins) do
  if func.type == "function" or func.type == "form" then
    func.name = name
  end
end

return builtins
