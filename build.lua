local lfs = require("lfs")

local arguments = {...}

local version, out
for i = 1, #arguments do
  if arguments[i] == "--version" or arguments[i] == "-v" then
    version = arguments[i + 1]
    i = i + 1
  elseif arguments[i] == "--out" or arguments[i] == "-o" then
    out = arguments[i + 1]
    i = i + 1
  end
end
if not version then
  error("no version specified")
end
if not out then
  out = "out/oc-ramfs-" .. version .. ".lua"
end

local function readFiles(directory, fileTable)
  for file in lfs.dir(directory) do
    local path = directory .. "/" .. file
    if file == "." or file == ".." then
      -- do nothing
    elseif lfs.attributes(path).mode == "directory" then
      fileTable[file] = {}
      readFiles(path, fileTable[file])
    elseif lfs.attributes(path).mode == "file" then
      local handle, err = io.open(path, "r")
      if not handle then
        error("error reading file " .. path .. ": " .. err)
      end
      local code = handle:read("*a")
      handle:close()
      fileTable[file] = code
    end
  end
end

local files = {}
readFiles("files", files)

local function serializeTable(t, indent)
  local result = ""
  for k, v in pairs(t) do
    local key = "[\"" .. k .. "\"]"
    if type(v) == "table" then
      result = result .. indent .. key .. " = {\n" .. serializeTable(v, indent .. "  ") .. indent .. "},\n"
    else
      local numEscapes = 0;
      local escapes = string.rep("=", numEscapes)
      while v:find("%[" .. escapes .. "%[") or v:find("%]" .. escapes .. "%]") do
        numEscapes = numEscapes + 1
        escapes = string.rep("=", numEscapes)
      end
      result = result .. indent .. key .. " = " .. "[" .. escapes .. "[" .. v .. "]" .. escapes .. "],\n"
    end
  end
  return result
end
local buildFiles = serializeTable(files, "  ")

local buildTemplateFile, err = io.open("buildtemplate.lua", "r")
if not buildTemplateFile then
  error("error reading file buildtemplate.lua: " .. err)
end
local buildTemplate = buildTemplateFile:read("*a")
buildTemplateFile:close()

local buildTemplateVariables = {}
buildTemplateVariables["build-info"] = "version = \"" .. version .. "\""
buildTemplateVariables["build-files"] = buildFiles

local nextPos = 1
while true do
  local firstPattern, firstPatternPos, firstPatternEnd = nil, nil, nil
  for k, v in pairs(buildTemplateVariables) do
    local pattern = "--% " .. k
    local start, finish = buildTemplate:find(pattern, nextPos, true)
    if start and (not firstPattern or start < firstPatternPos) then
      firstPattern = pattern
      firstPatternPos = start
      firstPatternEnd = finish
    end
  end
  if not firstPattern then
    break
  end

  local v = buildTemplateVariables[firstPattern:sub(5)]
  buildTemplate = buildTemplate:sub(1, firstPatternPos - 1) .. v .. buildTemplate:sub(firstPatternEnd + 1)
  nextPos = firstPatternPos + #v
end

local outFile, err = io.open(out, "w")
if not outFile then
  error("error writing file " .. out .. ": " .. err)
end
outFile:write(buildTemplate)
outFile:close()

print("Wrote build to " .. out)