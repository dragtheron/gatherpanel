local _, addon = ...;
local module = addon:RegisterModule("Tooltip");

local function hasItemsToDisplay(entry)
  if not entry then
    return false;
  end

  local currentEntry = entry;

  while currentEntry do
    if currentEntry.goal > 0 then
      return true;
    end

    currentEntry = currentEntry.lowerItem;
  end

  return false;
end

local function hookScript(table, name, func)
  if table and table:HasScript(name) then
    table:HookScript(name, func);
  end
end

-- function from SharedTooltipTemplates.lua
local function addColoredLine(tooltip, text, color, wrap, leftOffset)
  local r, g, b = color:GetRGB();

  if wrap == nil then
    wrap = true;
  end

  tooltip:AddLine(text, r, g, b, wrap, leftOffset)
end

local function addObjectiveLine(tooltip, entryType, id)
  if not id or id == "" or not tooltip or not tooltip.GetName then
    return;
  end

  if type(id) == "table" and #id == 1 then
    id = id[1];
  end

  local entries = addon.getItemlist();

  if not entries then
    print("Entries not available");
    return;
  end

  local entry = entries[id];

  if not entry then
    return;
  end

  if not hasItemsToDisplay(entry) then
    return;
  end

  tooltip:AddLine(" ");

  local group = entries[entry.parent];

  if group then
    tooltip:AddLine("Gather Panel: " .. group.name);
  else
    tooltip:AddLine("Gather Panel");
  end

  local currentEntry = entry;

  while currentEntry do
    if currentEntry.goal > 0 then
      local progressCount = min(currentEntry.itemCount, currentEntry.goal);
      local entryProgressInfo = string.format("%s: %d/%d", currentEntry.displayName, progressCount, currentEntry.goal);
      local fulfilled = currentEntry.itemCount >= currentEntry.goal;
      local color = fulfilled and GRAY_FONT_COLOR or HIGHLIGHT_FONT_COLOR;
      addColoredLine(tooltip, QUEST_DASH .. " " .. entryProgressInfo, color);
    end
    currentEntry = currentEntry.lowerItem;
  end
end

local function getItemIdFromRecipe()
  if TradeSkillFrame == nil or not TradeSkillFrame:IsVisible() or not GetMouseFocus().reagentIndex then
    return;
  end

  local selectedRecipe = TradeSkillFrame.RecipeList:GetSelectedRecipeID();

  for i = 1, 8 do
    if GetMouseFocus().reagentIndex == i then
      return C_TradeSkillUI.GetRecipeReagentItemLink(selectedRecipe, i):match("item:(%d*)") or nil;
    end
  end
end

local function extendItemTooltip(tooltip)
  local link = select(2, tooltip:GetItem());

  if not link then
    return;
  end

  local itemString = string.match(link, "item:([%-?%d:]+)");

  if not itemString then
    return;
  end

  local id = string.match(link, "item:(%d*)");

  if (id == "" or id == "0") then
    id = getItemIdFromRecipe();
  end

  if id then
    addObjectiveLine(tooltip, addon.EntryTypes.item, id);
  end
end

local function extendTooltipFromItemData(tooltip, data)
  for _, entry in ipairs(data.args) do
    if entry.field == "id" and entry.intVal then
      addObjectiveLine(tooltip, addon.EntryTypes.item, entry.intVal);
    end
  end
end

hooksecurefunc(GameTooltip, "SetRecipeReagentItem", function(tooltip, itemId)
  addObjectiveLine(tooltip, addon.EntryTypes.item, itemId);
end);

hookScript(GameTooltip, "OnTooltipSetItem", extendItemTooltip);
hookScript(ItemRefTooltip, "OnTooltipSetItem", extendItemTooltip);
hookScript(ItemRefShoppingTooltip1, "OnTooltipSetItem", extendItemTooltip);
hookScript(ItemRefShoppingTooltip2, "OnTooltipSetItem", extendItemTooltip);
hookScript(ShoppingTooltip1, "OnTooltipSetItem", extendItemTooltip);
hookScript(ShoppingTooltip2, "OnTooltipSetItem", extendItemTooltip);

if TooltipDataProcessor then
  TooltipDataProcessor.AddTooltipPostCall(TooltipDataProcessor.AllTypes, function(tooltip, data)
    if not data or not data.type then
      return;
    end

    if data.type == Enum.TooltipDataType.Item then
      extendTooltipFromItemData(tooltip, data)
    end
  end);
end
