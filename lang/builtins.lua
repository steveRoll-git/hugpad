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

for name, func in pairs(builtins) do
  if func.type == "function" or func.type == "form" then
    func.name = name
  end
end

return builtins
