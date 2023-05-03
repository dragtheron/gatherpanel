local addonName, addon = ...;
local module = addon:RegisterModule("Minimap");

local function updatePosition(button)
  local position = addon.Variables.user.minimapPosition;
  local angle = math.rad(position or 90);
  local x, y = math.cos(angle), math.sin(angle);
  local radius = 5;
  local width = (Minimap:GetWidth() / 2) + radius;
  local height = (Minimap:GetHeight() / 2) + radius;
  x, y = x * width, y * height;
  button:SetPoint("CENTER", Minimap, "CENTER", x, y);
end

function GatherPanel_Minimap_Update(button)
  if button.dragging then
    local minimap_x, minimap_y = Minimap:GetCenter();
    local pointer_x, pointer_y = GetCursorPosition();
    local scale = Minimap:GetEffectiveScale();
    pointer_x, pointer_y = pointer_x / scale, pointer_y / scale;

    local position = math.deg(
      math.atan2(pointer_y - minimap_y, pointer_x - minimap_x)
    ) % 360;

    addon.Variables.user.minimapPosition = position;
    updatePosition(button);
  else
  end
end

function GatherPanel_Minimap_ResetButtonPosition(button)
  if addon.Variables.user.minimapPosition == nil then
    addon.Variables.user.minimapPosition = 90;
  end
  button:ClearAllPoints()
  updatePosition(button)
end

AddonCompartmentFrame:RegisterAddon({
  text = addonName,
  icon = "Interface\\Icons\\inv_misc_treasurechest05c",
  registerForAnyClick = true,
  func = function(btn, arg1, arg2, checked, mouseButton)
    if mouseButton == "LeftButton" then
      if IsShiftKeyDown() then
        addon.Settings:Open();
      else
        GatherPanel:SetShown(not GatherPanel:IsShown());
      end
    elseif mouseButton == "RightButton" then
      GatherPanel_ToggleTracker();
    end
  end,
  funcOnEnter = function()
    GameTooltip:SetOwner(AddonCompartmentFrame, "ANCHOR_TOPRIGHT")
    GameTooltip:SetText(format("GatherPanel v%i.%i.%i",
      GATHERPANEL_VERSION.major,
      GATHERPANEL_VERSION.minor,
      GATHERPANEL_VERSION.patch
    ))
    GameTooltip:AddLine(
    "Left Click to toggle panel.\nRight click to toggle tracker overlay.\nShift-Left Click to open settings.", 0, 1, 0)
    GameTooltip:Show()
  end,
});
