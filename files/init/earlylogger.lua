local gpuAddress = component.list("gpu")()
local screenAddress = component.list("screen")()

local gpu, l, h
local x, y = 1, 1
if gpuAddress and screenAddress then
  gpu = component.proxy(gpuAddress)
  gpu.bind(screenAddress)
  gpu.setResolution(gpu.maxResolution())
  gpu.setBackground(0x000000)
  gpu.setForeground(0xFFFFFF)
  gpu.setDepth(gpu.maxDepth())
  l, h = gpu.getResolution()
  gpu.fill(1, 1, l, h, " ")
end

local TRACE_LEVEL = 1
local INFO_LEVEL = 2
local WARN_LEVEL = 3

local messageBuffer = {}
local function recordMessage(level, message)
  table.insert(messageBuffer, {level = level, message = message})
end

local function nextLine()
  y = y + 1
  x = 1
  if y > h then
    gpu.copy(1, 1, l, h, 0, -1)
    gpu.fill(1, h, l, 1, " ")
    y = h
  end
end

local function write(chars)
  for i = 1, #chars do
    if x > l then
      nextLine()
    end
    gpu.set(x, y, chars:sub(i, i))
    x = x + 1
  end
end

local function gpuShow(color, level, message)
  if not gpu then return end
  gpu.setForeground(0xFFFFFF)
  write("[")
  gpu.setForeground(color)
  write(level)
  gpu.setForeground(0xFFFFFF)
  write("] ")
  write(message)
  nextLine()
end

local earlyLogger = {}

function earlyLogger.trace(message)
  gpuShow(0x3388FF, "TRACE", message)
  recordMessage(TRACE_LEVEL, message)
end
function earlyLogger.info(message)
  gpuShow(0x00FF00, "INFO", message)
  recordMessage(INFO_LEVEL, message)
end
function earlyLogger.warn(message)
  gpuShow(0xFFFF00, "WARN", message)
  recordMessage(WARN_LEVEL, message)
end

return earlyLogger