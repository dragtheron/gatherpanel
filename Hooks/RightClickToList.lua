local _, addon = ...;
local module = addon:RegisterModule("Hooks_RightClickToList");

local hook = addon.Hooks_Base.Hook;
local hookScript = addon.Hooks_Base.HockScript;

print("K!");


local function addToListFrameOpen()
  return PanelTemplates_GetSelectedTab(_G["GatherPanel"]) == 2;
end


local function hookClickCurrency()
  hook(_G, "TokenButton_OnClick", function(self, button)
    if not addToListFrameOpen() then
      return;
    end

    local id = tonumber(string.match(C_CurrencyInfo.GetCurrencyListLink(self.index),"currency:(%d+)"));
    GatherPanel_NewItem_InsertCurrency(id);
  end);
end


hookClickCurrency();
