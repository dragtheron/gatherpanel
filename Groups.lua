local _, addon = ...;
local module = addon:RegisterModule("Groups");

module.defaultGroup = {
  id = 0,
  parent = nil,
  type = addon.Entries.EntryTypes.group,
  name = addon.T["DEFAULT_GROUP"],
  displayName = addon.T["DEFAULT_GROUP"],
};
