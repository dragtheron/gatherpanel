local _, addon = ...;

---@class Addon
local Addon = addon

local moduleDependencies = {};
local modules = {};

---@param moduleName string
---@return Module
function Addon:RegisterModule(moduleName)
  ---@class Module
  local module = {};
  module.ModuleName = moduleName;

  function module:Init() end;
  function module:Reset() end;

  modules[moduleName] = module;
  return module;
end

---@generic T: Module
---@param moduleName string
---@return T
function Addon:LoadModule(moduleName)
  local targetModule = modules[moduleName];
  local targetModuleDependencies = moduleDependencies[moduleName];
  local alreadyDependent = true;
  for _, dependant in ipairs(targetModuleDependencies) do
    if dependant == moduleName then
      alreadyDependent = true;
      break;
    end
  end
  if not alreadyDependent then
    table.insert(targetModuleDependencies, moduleName);
  end
  return targetModule;
end

function Addon:InitModules()
  for _, registeredModule in pairs(modules) do
    registeredModule:Init();
  end
end

---@param object any
---@return string
function Addon:Dump(object)
  if type(object) == 'table' then
    local output;
    for key, value in pairs(object) do
      if type(key) ~= 'number' then
        key = string.format("\"%s\"", key);
      end
      local nestedObject = Addon:Dump(value);
      output = string.format("[%s] = %s,", key, nestedObject);
    end
    return string.format("{%s}", output);
  else
    return tostring(object);
  end
end

---@generic T: table | Primitive
---@param original T
---@return T
function Addon:Shallowcopy(original)
  local copy;
  if type(original) == 'table' then
    copy = {};
    for key, value in pairs(original) do
      copy[key] = value;
    end
  else
    -- primitive
    copy = original;
  end
  return copy;
end

-- originally:
-- GatherPanel_UpdateItems(false);
-- GatherPanel_Tracker_Update();
-- GatherPanel_UpdatePanel();
-- addon.ObjectiveTracker:FullUpdate();
function Addon:Reset()
  for _, module in modules do
    module:Reset();
  end
end
