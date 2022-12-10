---@type _, Addon
local _, Addon = ...;

---@class LocalizationModule: Module
local Module = Addon:RegisterModule("Localization");

---@type Dictionary
local activeDictionary;

---@param dictionary Dictionary
function Module:SetDictionary(dictionary)
  activeDictionary = dictionary;
end

---@param key string
---@return string
function Module:Get(key)
  if activeDictionary == nil or activeDictionary[key] == nil then
    return key;
  end

  return activeDictionary[key];
end
