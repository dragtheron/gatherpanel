local addonName, L = ...;

local function updatePosition(button)
  local position = GATHERPANEL_SETTINGS.minimapPosition;
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

    GATHERPANEL_SETTINGS.minimapPosition = position;
    updatePosition(button);
  else
  end
end

function GatherPanel_Minimap_ResetButtonPosition(button)
  if GATHERPANEL_SETTINGS.minimapPosition == nil then
    GATHERPANEL_SETTINGS.minimapPosition = 90;
  end
  button:ClearAllPoints()
  updatePosition(button)
end

function GatherPanel_Minimap_OnEvent(button, event)
  if event == 'ADDON_LOADED' then
    GatherPanel_Minimap_ResetButtonPosition(button);
  end
end
