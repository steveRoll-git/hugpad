local shallowCopy = require "util.shallowCopy"

local luaEvalRun = require "lang.eval".luaEvalRun

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

return builtins
