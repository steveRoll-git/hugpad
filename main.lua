local love = love
local lg = love.graphics

local eval = require "lang.eval"
local parser = require "lang.parser"
local builtins = require "lang.builtins"
local shallowCopy = require "util.shallowCopy"
local codeEditor = require "windows.codeEditor"

love.keyboard.setKeyRepeat(true)

local nextCursor

function SetCursor(cursor)
  nextCursor = cursor
end

local errorBoxHeight = 48
local errorFont = lg.getFont()

local editor = codeEditor.new()
editor.windowWidth = love.graphics.getWidth() / 2
editor.windowHeight = love.graphics.getHeight() - errorBoxHeight
editor:resize(editor.windowWidth, editor.windowHeight)

local compiledComposition
local compilationError

local function evalFile(tree)
  if tree.type ~= "list" then
    error("the value of a file should be a list")
  end

  tree = {
    type = "list",
    value = { { type = "name", value = "compose" }, unpack(tree.value) }
  }

  local scope = shallowCopy(builtins)

  return eval.eval(tree, scope)
end

local function compileComposition()
  compilationError = nil
  local code = editor.editor:getString()
  local p = parser.new(code)
  local succ, tree = pcall(parser.parseValueList, p)
  if not succ then
    compilationError = tree
    return
  end
  local succ, c = pcall(evalFile, tree)
  if succ then
    compiledComposition = c
  else
    compilationError = c
  end
end

local compositionActions = {}

local function runComposition(c)
  compositionActions[c.action](c)
end

function compositionActions:compose()
  lg.push()
  for _, c in ipairs(self.body) do
    runComposition(c)
  end
  lg.pop()
end

function compositionActions:setColor()
  lg.setColor(self.color)
end

function compositionActions:translate()
  lg.translate(self.x, self.y)
end

function compositionActions:circle()
  lg.circle(self.drawMode, self.x, self.y, self.radius)
end

editor.onActivity = function()
  compileComposition()
end

compileComposition()

function love.mousemoved(x, y, dx, dy)
  local prevCursor = love.mouse.getCursor()
  nextCursor = nil
  editor:mousemoved(x, y, dx, dy)
  if nextCursor and nextCursor ~= prevCursor then
    love.mouse.setCursor(nextCursor)
  elseif nextCursor == nil then
    love.mouse.setCursor()
  end
end

function love.mousepressed(x, y, b)
  editor:mousepressed(x, y, b)
end

function love.mousereleased(x, y, b)
  editor:mousereleased(x, y, b)
end

function love.wheelmoved(x, y)
  editor:wheelmoved(x, y)
end

function love.keypressed(key)
  editor:keypressed(key)
end

function love.textinput(t)
  editor:textinput(t)
end

function love.resize(w, h)
  editor.windowWidth = love.graphics.getWidth() / 2
  editor.windowHeight = love.graphics.getHeight() - errorBoxHeight
  editor:resize(editor.windowWidth, editor.windowHeight)
end

function love.draw()
  editor:draw()

  if compilationError then
    local margin = 6
    lg.push()
    lg.translate(0, editor.windowHeight)
    lg.setColor(0.6, 0.1, 0.1)
    lg.rectangle("fill", 0, 0, editor.windowWidth, errorBoxHeight)
    lg.setColor(1, 1, 1)
    local _, t = errorFont:getWrap(compilationError, editor.windowWidth - margin * 2)
    lg.setFont(errorFont)
    for i, l in ipairs(t) do
      lg.print(l, margin, errorBoxHeight / 2 - #t * errorFont:getHeight() / 2 + (i - 1) * errorFont:getHeight())
    end
    lg.pop()
  end

  lg.setColor(1, 1, 1)
  lg.line(editor.windowWidth, 0, editor.windowWidth, lg.getHeight())

  if compiledComposition then
    lg.push()
    lg.translate(editor.windowWidth, 0)
    lg.setScissor(editor.windowWidth, 0, lg.getWidth() - editor.windowWidth, lg.getHeight())
    lg.setColor(1, 1, 1)
    local comp = eval.luaEvalRun(compiledComposition)
    runComposition(comp)
    lg.setScissor()
    lg.pop()
  end
end
