---@type _, Addon
local _, Addon = ...;

---@class LocalizationModule_deDE: LocalizationModule
local LocalizationModule = Addon:LoadModule("Localization");

if GetLocale() == "deDE" then
  LocalizationModule:SetDictionary({
    TrackerOptions = "Anzeigeoptionen für die Tracker Overlays",
  });
end
