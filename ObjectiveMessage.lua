local addonName, addon = ...;
addon.ObjectiveMessage = {};
local module = addon.ObjectiveMessage;


local function displayMessage(message)
  local r, g, b = YELLOW_FONT_COLOR:GetRGB();
  UIErrorsFrame:AddMessage(message, r, g, b, 1.0);
end


function module:Add(message)
  if addon.Variables.global.showObjectiveText then
    displayMessage(message);
  end
end
