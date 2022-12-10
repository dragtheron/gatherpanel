local _, Addon = ...;

local Store = Addon:LoadModule("Store");

local loaded = false;

local function onEvent(event)
  if event == "ADDON_LOADED" and not loaded then
    Store:Validate();
    Addon:InitModules();
  end
end
