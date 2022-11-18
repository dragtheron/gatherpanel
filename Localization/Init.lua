local _, AddOn = ...;

local module = AddOn:RegisterModule("Localization");

module.TranslationTable = {};

local function L_Default(L, key)
  return key;
end

setmetatable(module.TranslationTable, { __index=L_Default });

---@deprecated Use Lua only translations instead using `AddOn.T`.
GATHERPANEL_T = module.TranslationTable;
