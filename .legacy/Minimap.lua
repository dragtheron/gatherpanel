local _, addon = ...;
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


local frame = CreateFrame("Button", nil, nil, "GatherPanelMinimapButtonTemplate");

function frame:OpenSettings()
  addon.Settings:Open();
end

function module:Init()
  updatePosition(frame);
end
