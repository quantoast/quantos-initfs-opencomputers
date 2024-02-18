local filePrototype = {}
local function readAll(self)
  local result = ""
  while true do
    local chunk = self.backing.read(self.handle, math.huge)
    if not chunk then
      break
    end
    result = result .. chunk
  end
  return result
end
local function readLine(self)
  local result = ""
  while true do
    local char = self.backing.read(self.handle, 1)
    if not char then
      break
    end
    if char == "\n" then
      break
    end
    result = result .. char
  end
  return result
end
function filePrototype:read(arg)
  if type(arg) == "number" then
    return self.backing.read(self.handle, arg)
  elseif arg == "a" then
    return readAll(self)
  elseif arg == "l" then
    return readLine(self)
  end
end
function filePrototype:close()
  self.backing.close(self.handle)
end

local rootFsNodePrototype = {}
local function createRootFsNode(backing, path)
  return setmetatable({
    backing = backing,
    path = path
  }, {__index = rootFsNodePrototype})
end

function rootFsNodePrototype:isDirectory()
  return self.backing.isDirectory(self.path)
end
function rootFsNodePrototype:hasChild(name)
  return self.backing.exists(self.path .. "/" .. name)
end
function rootFsNodePrototype:getChild(name)
  local path = self.path .. "/" .. name
  if not self.backing.exists(path) then
    error("File or directory does not exist")
  end
  return createRootFsNode(self.backing, path)
end
function rootFsNodePrototype:createDirectory(name)
  local path = self.path .. "/" .. name
  if self.backing.exists(path) then
    error("File or directory already exists")
  end
  self.backing.makeDirectory(path)
  return createRootFsNode(self.backing, path)
end
function rootFsNodePrototype:createFile(name)
  local path = self.path .. "/" .. name
  if self.backing.exists(path) then
    error("File or directory already exists")
  end
  local handle = self.backing.open(path, "w")
  self.backing.close(handle)
  
  return createRootFsNode(self.backing, path)
end
function rootFsNodePrototype:list()
  return self.backing.list(self.path)
end
function rootFsNodePrototype:delete()
  self.backing.remove(self.path)
end
function rootFsNodePrototype:open(name, mode)
  local handle = self.backing.open(self.path .. "/" .. name, mode)
  return setmetatable({
    backing = self.backing,
    handle = handle
  }, {__index = filePrototype})
end

local function formatRootFs(rootfsRaw)
  if type(rootfsRaw) == "string" then
    rootfsRaw = component.proxy(rootfsRaw)
  end

  return createRootFsNode(rootfsRaw, "/")
end

return {
  load = formatRootFs
}