--[[

General structure for lists:

Items:
 - id, name, etc.
Currencies:
 - id, name, etc.
Groups:
 - name

These are stored in an array.
With another index which is constructed on reload.

]]

local _, addon = ...;
local module = addon:RegisterModule("Core_Entries");


---@enum Entries.GoalType
module.GoalTypes = {
  min = "min",
  max = "max",
}


---@enum Entries.EntryType
module.EntryTypes = {
  item = "ITEM",
  group = "GROUP",
  currency = "CURRENCY",
};


---@class Entries.Entry
---@field id integer
---@field parent integer | nil
---@field type Entries.EntryType
---@field name string
---@field displayName string
---@field quality number
---@field texture string
---@field goalType Entries.GoalType
---@field count integer
---@field countTmp integer
---@field currentGoal integer
---@field min integer
---@field max integer
---@field percentage number
---@field percentageMax number
---@field tracking boolean
---@field trackerIndex integer



local function initIndices()
  module.indices = {};

  for _, itemType in pairs(module.ItemTypes) do
    module.indices[itemType] = {};
  end
end


local function generateIndices()
  initIndices();
  for key, entry in pairs(module.Entries) do
    module.indices[entry.type][entry.id] = key;
  end
end


function module:GenerateListKey(realm, characterName)
  return string.format("%s:%s", realm, characterName);
end


function module:SelectList(key)
  if module.Variables.global.Entries[key] == nil then
    module.Variables.global.Entries[key] = {};
  end

  module.Entries = module.Variables.global.Entries[key];
end


function module:SelectDefaultList()
  local realm = GetRealmName();
  local characterName = UnitName("player");
  local key = self.GenerateListKey(realm, characterName);
  self:SelectList(key);
end



local function getListKeys()
  local listKeys = {};
  for realm, realmList in pairs(addon.Variables.Entries) do
    for character in pairs(realmList) do
      table.insert(listKeys, module:GenerateListKey(realm, character));
    end
  end
  return listKeys;
end


function module:Init()
  self:SelectDefaultList();
  generateIndices();
  self.listKeys = getListKeys();
end


function module:GetKey(entryType, entryId)
  return module.indices[entryType][entryId];
end


function module:GetById(entryType, entryId)
  local key = self:GetKey(entryType, entryId);
  return module.Entries[key];
end


function module:GetParent(entry)
  if not entry.parent then
    return;
  end
  return self.GetById(addon.Core_Entries.ItemTypes.group, entry.parent);
end


local function track(entry)
  addon.Tracker:Create(entry);
  addon.Sounds:PlayQuestAccepted();
end


local function untrack(entry)
  if item.count < item.max then
    addon.Sounds:PlayAbandonQuest();
  end
  addon.Tracker:Remove(entry);
end


function module:ToggleTracking(entry)
  if item.tracking then
    untrack(entry);
  else
    track(entry);
  end
  addon.Panel.Update();
  addon.Tracker.Update();
end


function module:GetIndex(entryType)
  return self.Entries.indices[entryType];
end
