local guessedAddress = computer.getBootAddress()

local tree = {
--% build-files
}

local fs = {}

local function resolvePath(path)
  local parts = {}
  for part in path:gmatch("[^/]+") do
    if part == ".." then
      table.remove(parts)
    elseif part ~= "." then
      table.insert(parts, part)
    end
  end
  return parts
end

local function resolve(tree, path)
  local parts = resolvePath(path)
  local current = tree
  for i = 1, #parts do
    if current[parts[i]] then
      current = current[parts[i]]
    else
      return nil
    end
  end
  return current
end

function fs.read(file)
  local node = resolve(tree, file)
  if type(node) == "string" then
    return node
  elseif type(node) == "table" then
    return nil, "is a directory"
  else
    return nil, "file not found"
  end
end

function fs.list(directory)
  local node = resolve(tree, directory)
  if type(node) == "table" then
    local result = {}
    for k, v in pairs(node) do
      table.insert(result, k)
    end
    return result
  elseif type(node) == "string" then
    return nil, "is a file"
  else
    return nil, "directory not found"
  end
end

function fs.exists(path)
  return resolve(tree, path) ~= nil
end

function fs.isDirectory(path)
  return type(resolve(tree, path)) == "table"
end

function fs.getBuildInfo()
  return {
--% build-info
  }
end

function fs.getName()
  return "OpenComputers initfs " .. fs.getBuildInfo().version
end

fs.guessedRootFs = component.proxy(guessedAddress)

return fs