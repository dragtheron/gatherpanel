local _, addon = ...;

local modules = {};

local function createModule(moduleName)
  return {
    name = moduleName,
    Init = function() end
  };
end

function addon:RegisterModule(moduleName)
  local module = createModule(moduleName);
  table.insert(modules, module);
  return modules, module;
end

function addon:InitModules()
  for _, module in pairs(modules) do
    module:Init();
  end
end
