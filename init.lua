local addonName, Addon = ...;
Addon.T = {};

-- setup localization
local function L_Default(L, key)
  return key;
end

Addon.modules = {}

function Addon:RegisterModule(moduleName)
  local module = {};
  module.moduleName = moduleName;
  function module:Init() end
  table.insert(Addon.modules, module);
  Addon[moduleName] = module;
  return module;
end

function Addon:LoadModules()
  for _, module in pairs(Addon.modules) do
    print("Loading module", module.moduleName);
    module:Init();
  end
end

setmetatable(Addon.T, { __index=L_Default });

-- global var for use in xml's
GATHERPANEL_T = Addon.T
