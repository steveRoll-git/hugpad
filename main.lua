local love = love
local lg = love.graphics

local eval = require "lang.eval"
local parser = require "lang.parser"

love.keyboard.setKeyRepeat(true)

local nextCursor

function SetCursor(cursor)
  nextCursor = cursor
end

local codeEditor = require "windows.codeEditor"

local editor = codeEditor.new()
editor.windowWidth = love.graphics.getWidth() / 2
editor.windowHeight = love.graphics.getHeight()
editor:resize(editor.windowWidth, editor.windowHeight)

local compiledComposition

local function compileComposition()
  local code = editor.editor:getString()
  local p = parser.new(code)
  local succ, tree = pcall(parser.parseValueList, p)
  if not succ then
    return
  end
  local succ, c = pcall(eval.evalFile, tree)
  if succ then
    compiledComposition = c
  end
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

function love.draw()
  editor:draw()

  if compiledComposition then
    lg.push()
    lg.translate(editor.windowWidth, 0)
    lg.setScissor(editor.windowWidth, 0, lg.getWidth() - editor.windowWidth, lg.getHeight())
    lg.setColor(1, 1, 1)
    eval.luaEvalRun(compiledComposition)
    lg.setScissor()
    lg.pop()
  end
end
