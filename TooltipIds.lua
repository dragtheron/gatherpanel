local _, addon = ...;
local module = addon:RegisterModule("TooltipIds");

local function hook(table, func, callback)
  if table and table[func] then
    hooksecurefunc(table, func, callback);
  end
end


local function hookScript(table, func, callback)
  if table and table:HasScript(func) then
    table:HookScript(func, callback);
  end
end


local kinds = {
  item = "Item ID",
  currency = "Currency ID",
  unknown = "Unknown",
}


local function addLine(tooltip, id, kind)
  if not addon.Variables.global.showIds then
    return;
  end

  if kind == kinds.unknown then
    tooltip:AddLine("Unknown ID");
    tooltip:Show();
    return;
  end

  if not id or id == "" or not tooltip or not tooltip.GetName then
    return;
  end

  if type(id) == "table" and #id == 1 then
    id = id[1]
  end

  local left, right;

  if type(id) == "table" then
    left = NORMAL_FONT_COLOR_CODE .. kind .. "s" .. FONT_COLOR_CODE_CLOSE;
    right = HIGHLIGHT_FONT_COLOR_CODE .. table.concat(id, ", ") .. FONT_COLOR_CODE_CLOSE;
  else
    left = NORMAL_FONT_COLOR_CODE .. kind .. FONT_COLOR_CODE_CLOSE;
    right = HIGHLIGHT_FONT_COLOR_CODE .. id .. FONT_COLOR_CODE_CLOSE;
  end

  tooltip:AddDoubleLine(left, right);
  tooltip:Show();
end


local function getItemIdFromRecipe()
  local selectedRecipe = TradeSkillFrame.RecipeList:GetSelectedRecipeID();

  for i = 1, 8 do
    if GetMouseFocus().reagentIndex == i then
      return C_TradeSkillUI.GetRecipeReagentItemLink(selectedRecipe, i):match("item:(%d*)") or nil;
    end
  end
end


local function attachItemTooltip(self)
  local link = select(2, self:GetItem());

  if not link then
    return;
  end

  local itemString = string.match(link, "item:([%-?%d:]+)");

  if not itemString then
    return;
  end

  local id = string.match(link, "item:(%d*)");

  if (id == "" or id == "0")
    and TradeSkillFrame ~= nil
    and TradeSkillFrame:IsVisible()
    and GetMouseFocus().reagentIndex then
      id = getItemIdFromRecipe();
  end

  if id then
    addLine(self, id, kinds.item);
  else
    addLine(self, id, kinds.unknown);
  end
end

hookScript(GameTooltip, "OnTooltipSetItem", attachItemTooltip);
hookScript(ItemRefTooltip, "OnTooltipSetItem", attachItemTooltip);
hookScript(ItemRefShoppingTooltip1, "OnTooltipSetItem", attachItemTooltip);
hookScript(ItemRefShoppingTooltip2, "OnTooltipSetItem", attachItemTooltip);
hookScript(ShoppingTooltip1, "OnTooltipSetItem", attachItemTooltip);
hookScript(ShoppingTooltip2, "OnTooltipSetItem", attachItemTooltip);

hook(GameTooltip, "SetBagItem", function(self, bagId, slotId)
  local info = C_Container.GetContainerItemInfo(bagId, slotId);
	local id = info and info.itemID;
  addLine(self, id, kinds.item);
end)

hook(GameTooltip, "SetToyByItemID", function(self, id)
  addLine(self, id, kinds.item);
end)

hook(GameTooltip, "SetRecipeReagentItem", function(self, id)
  addLine(self, id, kinds.item);
end)

hook(GameTooltip, "SetCurrencyToken", function(self, index)
  local id = tonumber(string.match(C_CurrencyInfo.GetCurrencyListLink(index), "currency:(%d+)"));
  addLine(self, id, kinds.currency);
end)

hook(GameTooltip, "SetCurrencyByID", function(self, id)
  addLine(self, id, kinds.currency);
end)

hook(GameTooltip, "SetCurrencyTokenByID", function(self, id)
  addLine(self, id, kinds.currency);
end)
