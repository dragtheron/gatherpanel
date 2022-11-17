local addonName, addon = ...;

local L = addon;

-- Testing Types

---@enum ItemGoalType
local ITEM_GOAL_TYPES = {
  min = "min",
  max = "max",
}

---@enum ItemType
local ITEM_TYPE = {
  item = "ITEM",
  group = "GROUP"
}

---@class Item
---@field parent integer | nil
---@field type ItemType
---@field id integer
---@field name string
---@field itemQuality number
---@field itemTexture string
---@field goalType ItemGoalType
---@field itemCount integer
---@field itemCountTmp integer
---@field goal integer
---@field min integer
---@field max integer
---@field progressPercentage number
---@field progressPercentageMax number
---@field isCollapsed boolean
---@field tracked boolean
---@field tracker integer The index of the tracker entry.

GATHERPANEL_ITEMBAR_HEIGHT = 26;
GATHERPANEL_NUM_ITEMS_DISPLAYED = 15;
GATHERPANEL_NUM_TRACKERS_ENABLED = 0;
GATHERPANEL_NUM_TRACKERS_CREATED = 1;
GATHERPANEL_LOADED = false;

GATHERPANEL_DEFAULT_GROUP_COLLAPSED = false;

GATHERPANEL_ITEMLISTS = {};
GATHERPANEL_ITEM_LIST_SELECTION = nil;

GATHERPANEL_VERSION = nil;
CURRENT_GATHERPANEL_VERSION = nil

-- setup localization
local function L_Default(L, key)
  return key;
end
setmetatable(L.T, { __index=L_Default });
GATHERPANEL_L = L.T;

local sortedHierarchy = {};
local defaultGroup = {
  name = L.T["UNCATEGORIZED"],
  type = "GROUP",
  parent = nil,
  isCollapsed = GATHERPANEL_DEFAULT_GROUP_COLLAPSED
};

---@param realm string
---@param characterName string
local function GetItemlistId(realm, characterName)
  return realm .. ":" .. characterName;
end


function addon:GetOptionName(enum, value, prefix)
  for key, val in pairs(enum) do
    if val == value then
      return L[prefix .. "_" .. key];
    end
  end
  return L.T["NOT_FOUND"]
end

local function traverse(tab, objectId, object, depth)
  table.insert(tab, {
    id = objectId,
    level = depth
  });
  if object.children ~= nil then
    for childId, child in pairs(object.children) do
      traverse(tab, childId, child, depth + 1);
    end
  end
end

local function flatToHierarchy(objects)
  -- Uncatogorized Group
  local elements = {
    [0] = {
      children = {}
    }
  };

  local roots = {
    [0] = elements[0]
  };

  local keys = {};
  for objectId, object in pairs(objects) do
    table.insert(keys, objectId);
  end
  table.sort(keys);

  -- populate elements list
  for _, objectId in ipairs(keys) do
    if objects[objectId].type == nil then
      objects[objectId].type = "ITEM";
    end
    elements[objectId] = {
      children = nil
    };
  end

  for objectId, object in pairs(objects) do
    local element = elements[objectId];
    if object.parent == nil then
      object.parent = 0;
    end
    if object.parent == 0 and object["type"] == "GROUP" then
      roots[objectId] = element;
    else
      local parent = elements[object.parent];
      if parent == nil then
        parent = elements[0]
        object.parent = 0;
      end
      if parent.children == nil then
        parent.children = {};
      end
      parent.children[objectId] = element;
    end
  end

  -- now sort the groups according to their name.
  local groupIds = {};
  for groupId, group in pairs(roots) do
    table.insert(groupIds, groupId);
  end
  local function compareByName(a, b)
    -- skip comparisons with virtual object
    if a == 0 or b == 0 then
      return false;
    end
    return objects[a]["name"] < objects[b]["name"]
  end
  table.sort(groupIds, compareByName);


  local linearized = {};
  for i, groupId in ipairs(groupIds) do
    traverse(linearized, groupId, roots[groupId], 0);
  end

  return linearized;
end

---@param itemListId string
local function decodeItemListId(itemListId)
  local t = {};
  for str in string.gmatch(itemListId, "([^:]+)") do
    table.insert(t, str)
  end
  local realm = t[1];
  local characterName = t[2]
  return realm, characterName;
end

---@return table<integer, Item>
function GatherPanel_GetItemList()
  if GATHERPANEL_CURRENT_ITEM_LIST == nil then
    return {}
  end
  return GATHERPANEL_CURRENT_ITEM_LIST;
end


local function getItemlist()
  return GatherPanel_GetItemList();
end


local function iterSortedItemList()
  local index = 1;
  local elements = getItemlist();
  return function()
    while index <= #sortedHierarchy do
      local elementKey = sortedHierarchy[index].id;
      index = index + 1;
      if elementKey ~= 0 then
        return elementKey, elements[elementKey]
      end
    end
    return nil
  end
end

local function setItemList()
  if GATHERPANEL_ITEM_LIST_SELECTION == GetItemlistId("X-Internal", "Combined") then
    local itemList = {};
    for realm, characterTable in pairs(GATHERPANEL_ITEMLISTS) do
      if realm == GetRealmName() then
        for _, itemTable in pairs(characterTable) do
          for itemId, item in pairs(itemTable) do
            -- skip other types then ITEM in the combined list
            if item.type == "ITEM" then
              if itemList[itemId] ~= nil then
                itemList[itemId]["min"] = itemList[itemId]["min"] + item["min"];
                itemList[itemId]["max"] = itemList[itemId]["max"] + item["max"];
              else
                itemList[itemId] = {};
                for k, v in pairs(item) do
                  itemList[itemId][k] = v;
                end
              end
            end
          end
        end
      end
    end
    GATHERPANEL_CURRENT_ITEM_LIST = itemList;
    return;
  elseif GATHERPANEL_ITEM_LIST_SELECTION ~= nil then
    local realm, characterName = decodeItemListId(GATHERPANEL_ITEM_LIST_SELECTION);
    if GATHERPANEL_ITEMLISTS[realm] ~= nil and GATHERPANEL_ITEMLISTS[realm][characterName] ~= nil then
      GATHERPANEL_CURRENT_ITEM_LIST = GATHERPANEL_ITEMLISTS[realm][characterName];
      return;
    end
  end
  -- Fallback to personal list. generate if not exists.
  local realm = GetRealmName();
  local characterName = UnitName("player");
  GATHERPANEL_ITEM_LIST_SELECTION = GetItemlistId(realm, characterName);
  if GATHERPANEL_ITEMLISTS[realm] == nil then
    GATHERPANEL_ITEMLISTS[realm] = {};
  end
  if GATHERPANEL_ITEMLISTS[realm][characterName] == nil then
    GATHERPANEL_ITEMLISTS[realm][characterName] = {};
  end
  GATHERPANEL_CURRENT_ITEM_LIST = GATHERPANEL_ITEMLISTS[realm][characterName];
end

StaticPopupDialogs["GATHERPANEL_CREATE_GROUP"] = {
  text = "New Group",
  button1 = ACCEPT,
  button2 = CANCEL,
  OnAccept = function(self)
    GatherPanel_CreateGroup(self.editBox:GetText());
  end,
  OnShow = function(self)
    self.editBox:SetFocus();
  end,
  OnHide = function(self)
    self.editBox:SetText("");
  end,
  EditBoxOnEnterPressed = function(self)
    local parent = self:GetParent();
    GatherPanel_CreateGroup(self:GetText());
    parent:Hide();
  end,
  EditBoxOnEscapePressed = function(self)
    self:GetParent():Hide();
  end,
  hideOnEscape = 1,
  hasEditBox = 1
}

StaticPopupDialogs["GATHERPANEL_GROUP_EDIT_NAME"] = {
  text = "Rename Group '%s'",
  button1 = ACCEPT,
  button2 = CANCEL,
  OnAccept = function(self, group)
    GatherPanel_EditGroup(group, self.editBox:GetText());
  end,
  OnShow = function(self, group)
    self.editBox:SetText(group.name);
    self.editBox:SetFocus();
  end,
  OnHide = function(self)
    self.editBox:SetText("");
  end,
  EditBoxOnEnterPressed = function(self, group)
    local parent = self:GetParent();
    GatherPanel_EditGroup(group, self:GetText());
    parent:Hide();
  end,
  EditBoxOnEscapePressed = function(self)
    self:GetParent():Hide();
  end,
  hideOnEscape = 1,
  hasEditBox = 1
}


local function SelectParentGroup(self, parentId)
  local item = _G["ItemDetailFrame"].item;
  item.parent = parentId;
  GatherPanel_InitializeSortedItemList();
  GatherPanel_UpdateItems(false);
  GatherPanel_UpdatePanel();
end

local function SetParent(self, parentId)
  local parent = getItemlist()[parentId];
  if parent then
    GatherPanel_Panel2.Inset.ParentDropDown.parentId = parentId;
    UIDropDownMenu_SetText(GatherPanel_Panel2.Inset.ParentDropDown, parent.name);
  else
    GatherPanel_Panel2.Inset.ParentDropDown.parentId = 0;
    UIDropDownMenu_SetText(GatherPanel_Panel2.Inset.ParentDropDown, defaultGroup.name);
  end
  UIDropDownMenu_SetWidth(GatherPanel_Panel2.Inset.ParentDropDown, 120);
end

local function SelectItemlist(self, itemListId)
  GATHERPANEL_ITEM_LIST_SELECTION = itemListId;

  -- Check if id exists. gets reset if not.
  setItemList();

  if GATHERPANEL_ITEM_LIST_SELECTION == GetItemlistId("X-Internal", "Combined") then
    -- disable all item list manipulations
    GatherPanel_NewItem_CreateButton:Disable();
    ItemDetailFrame.MinQuantityInput:Disable();
    ItemDetailFrame.MaxQuantityInput:Disable();
    ItemDetailDeleteButton:Disable()
  else
    GatherPanel_NewItem_CreateButton:Enable();
    ItemDetailFrame.MinQuantityInput:Enable();
    ItemDetailFrame.MaxQuantityInput:Enable();
    ItemDetailDeleteButton:Enable();
  end
  local realm, characterName = decodeItemListId(GATHERPANEL_ITEM_LIST_SELECTION);
  if GATHERPANEL_ITEM_LIST_SELECTION == GetItemlistId("X-Internal", "Combined") then
    UIDropDownMenu_SetText(GatherPanel_ItemlistSelection, L.T["COMBINED"]);
  else
    UIDropDownMenu_SetText(GatherPanel_ItemlistSelection, characterName);
  end
  CloseDropDownMenus();
  GatherPanel_InitializeSortedItemList();
  GatherPanel_ReloadTracker();
  GatherPanel_UpdateItems(false);
  GatherPanel_UpdatePanel();
end

---@param item Item
local function trackItem(_, item)
  GatherPanel_TrackItem(item);
end

---@param item Item
local function group_ShowEditPopup(_, item)
  StaticPopup_Show("GATHERPANEL_GROUP_EDIT_NAME", item.name, nil, item);
end


function GatherPanel_ItemDetailDeleteButton_OnClick(frame)
  local itemID = frame:GetParent().item.id;

  for i, item in pairs(getItemlist()) do
    if (item.id == itemID) then
      getItemlist()[i] = nil;
      addon.Sounds:PlayCheckBoxSelect();
      frame:GetParent().item = nil;
      GatherPanel_InitializeSortedItemList();
      GatherPanel_UpdateItems(false);
      GatherPanel_UpdatePanelItems();
      HideParentPanel(frame);
      return;
    end
  end
end


---@param itemKey integer
function GatherPanel_Context_ItemDelete(_, itemKey)
  local items = getItemlist();
  items[itemKey] = nil;
  item = nil;
  addon.Sounds:PlayCheckBoxSelect();
  GatherPanel_InitializeSortedItemList();
  GatherPanel_UpdateItems();
  GatherPanel_UpdatePanelItems();
end


local function initDropdownOptions_TrackerBarContext(frame)
  local info = UIDropDownMenu_CreateInfo();
  info.text = L.T["UNTRACK"];
  info.func = trackItem;
  info.notCheckable = true;
  ---@type Item
  info.arg1 = frame:GetParent().item;
  UIDropDownMenu_AddButton(info);
end


local function initDropdownOptions_GroupEdit(frame)
  local info = UIDropDownMenu_CreateInfo();
  info.text = L.T["CHANGE_NAME"];
  info.func = group_ShowEditPopup;
  ---@type Item
  info.arg1 = frame:GetParent().item;
  info.notCheckable = true;
  UIDropDownMenu_AddButton(info);
  info = UIDropDownMenu_CreateInfo();
  info.text = L.T["REMOVE_GROUP"];
  info.func = GatherPanel_Context_ItemDelete;
  info.notCheckable = true;
  ---@type integer
  info.arg1 = frame:GetParent().itemKey;
  UIDropDownMenu_AddButton(info);
end


local function InitParentSelectionOptions_DetailFrame(_)
  local defaultGroupInfo = UIDropDownMenu_CreateInfo();
  defaultGroupInfo.text = defaultGroup.name;
  defaultGroupInfo.isNotRadio = false;
  defaultGroupInfo.func = SelectParentGroup;
  defaultGroupInfo.arg1 = 0;
  if not _G["ItemDetailFrame"].item or _G["ItemDetailFrame"].item.parent == 0 then
    defaultGroupInfo.checked = 1
  else
    defaultGroupInfo.checked = nil;
  end
  UIDropDownMenu_AddButton(defaultGroupInfo);

  for itemId, item in iterSortedItemList() do
    local info = UIDropDownMenu_CreateInfo();
    if item.type == "GROUP" then
      info.text = item.name;
      info.isNotRadio = false;
      info.func = SelectParentGroup;
      info.arg1 = itemId;
      if _G["ItemDetailFrame"].item and _G["ItemDetailFrame"].item.parent == itemId then
        info.checked = 1
      else
        info.checked = nil;
      end
      UIDropDownMenu_AddButton(info);
    end
  end
end


local function InitParentSelectionOptions_CreateFrame(_)
  local defaultGroupInfo = UIDropDownMenu_CreateInfo();
  defaultGroupInfo.text = defaultGroup.name;
  defaultGroupInfo.isNotRadio = false;
  defaultGroupInfo.func = SetParent;
  defaultGroupInfo.arg1 = 0;
  if not GatherPanel_Panel2.Inset.ParentDropDown.parentId or GatherPanel_Panel2.Inset.ParentDropDown.parentId == 0 then
    defaultGroupInfo.checked = 1
  else
    defaultGroupInfo.checked = nil;
  end
  UIDropDownMenu_AddButton(defaultGroupInfo);
  for itemId, item in iterSortedItemList() do
    local info = UIDropDownMenu_CreateInfo();
    if item.type == "GROUP" then
      info.text = item.name;
      info.isNotRadio = false;
      info.func = SetParent;
      info.arg1 = itemId;
      if GatherPanel_Panel2.Inset.ParentDropDown.parentId == itemId then
        info.checked = 1
      else
        info.checked = nil;
      end
      UIDropDownMenu_AddButton(info);
    end
  end
end


local function InitListOptions(_)
  local info = UIDropDownMenu_CreateInfo();
  info.keepShownOnClick = 1;

  info.text = L.T["COMBINED"];
  info.isNotRadio = false;
  info.func = SelectItemlist;
  info.tooltipTitle = L.T["COMBINED"];
  local itemListId = GetItemlistId("X-Internal", "Combined");
  info.arg1 = itemListId;
  if GATHERPANEL_ITEM_LIST_SELECTION == itemListId then
    info.checked = 1
  else
    info.checked = nil;
  end
  UIDropDownMenu_AddButton(info);

  for realm, characterTable in pairs(GATHERPANEL_ITEMLISTS) do
    if realm == GetRealmName() then

      local characterKeys = {};
      for characterName, character in pairs(characterTable) do
        table.insert(characterKeys, characterName);
      end
      table.sort(characterKeys);

      for i, characterName in ipairs(characterKeys) do
        local itemListId = GetItemlistId(realm, characterName)
        info.text = characterName;
        info.isNotRadio = false;
        info.func = SelectItemlist;
        info.arg1 = itemListId;
        if GATHERPANEL_ITEM_LIST_SELECTION == itemListId then
          info.checked = 1
        else
          info.checked = nil;
        end
        UIDropDownMenu_AddButton(info);
      end
    end
  end
end

function GatherPanel_OnShow()
  addon.Sounds:PlayProfessionWindowOpen();
  GatherPanel_UpdateItems(false);
  GatherPanel_UpdatePanel();
end

function GatherPanel_OnHide()
  addon.Sounds:PlayProfessionWindowClose();
end

function GatherPanel_Tracker_OnLoad()
  SlashCmdList["GATHERPANEL_TRACKER"] = GatherPanel_ToggleTracker;
  SLASH_GATHERPANEL_TRACKER1 = "/gpt";
end

function GatherPanel_ToggleTracker()
  addon.Variables.user.trackerVisible = not addon.Variables.user.trackerVisible;
  -- Hide Tracker
  GatherPanel_Tracker_Update();
  -- Check UI Toggle
  GatherPanel_UpdatePanel();
end

function GatherPanel_TrackAll()

  for itemId, item in pairs(getItemlist()) do
    item.tracked = true;
  end
  GatherPanel_ReloadTracker();

end

function GatherPanel_OnLoad(frame)
  SlashCmdList["GATHERPANEL"] = function(msg)

    local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)");

    if cmd == "trackall" then
      GatherPanel_TrackAll();
    elseif cmd == "tracker" then
      GatherPanel_ToggleTracker();
    elseif cmd == nil then
      frame:SetShown(not frame:IsShown());
    elseif cmd == "options" then
      addon.Settings.Open();
    else
      print("GatherPanel Chat Commands:");
      print("/gp - Open Gather Panel");
      print("/gp trackall - Track all items from the current item list");
      print("/gp tracker - Toggle Tracker");
      print("/gp options - Open Settings");
    end

  end
  SLASH_GATHERPANEL1 = "/gp";

  local container = _G["GatherPanelInset"];
  for i = 1, GATHERPANEL_NUM_ITEMS_DISPLAYED, 1 do
    if (i ~= 1) then
      local bar = CreateFrame("Button", "GatherBar" .. i, container, "GatherBarTemplate");
      bar:SetPoint("TOPRIGHT", "GatherBar" .. (i - 1), "BOTTOMRIGHT", 0, -3);
    end
    _G["GatherBar" .. i].id = i;
    _G["GatherBar" .. i]:SetPoint("LEFT", "GatherPanelInset", "LEFT", 10, 0);
    _G["GatherBar" .. i .. "ItemName"]:SetPoint("LEFT", "GatherBar" .. i, "LEFT", 10, 0);
    _G["GatherBar" .. i .. "ItemName"]:SetPoint("RIGHT", "GatherBar" .. i .. "ItemBar", "LEFT", -3, 0);
    _G["GatherBar" .. i .. "ItemBarHighlight1"]:SetPoint("TOPLEFT", "GatherBar" .. i, "TOPLEFT", -2, 4);
    _G["GatherBar" .. i .. "ItemBarHighlight1"]:SetPoint("BOTTOMRIGHT", "GatherBar" .. i, "BOTTOMRIGHT", -10, -4);
  end
  _G['ItemDetailDeleteButton']:SetText(L.T["REMOVE_FROM_LIST"]);

  PanelTemplates_SetNumTabs(_G['GatherPanel'], 2);
  PanelTemplates_SetTab(_G['GatherPanel'], 1);
end

function GatherPanel_InitializeSortedItemList()
  --[[
    Items can have parents (which are categories or items, e.g. for recipe tracking).
    Rearrange items into the groups in a linear fashion, i.e. span up a tree.
    ]] --
  local items = getItemlist();
  sortedHierarchy = {};
  local linearizedHierarchy = flatToHierarchy(items);
  for _, element in ipairs(linearizedHierarchy) do
    table.insert(sortedHierarchy, element);
  end
end


---@param item Item
function GatherPanel_InitItem(item)
  local itemCount = 0;
  local locale = GetLocale();
  if item.updated == nil then
    item.updated = 0;
  end
  if item.name == nil or item.itemTexture == nil or item.itemQuality == nil or item.locale ~= locale then
    -- retry, sometimes heavy load
    item.name, _, item.itemQuality, _, _, _, _, _, _, item.itemTexture, _ = GetItemInfo(item.id);
    item.locale = locale;
  end
  local characterItemCount = 0;
  if IsAddOnLoaded("DataStore_Containers") then
    -- only load count from character who is owner of the list, i.e. what is this character missing
    local dataStore = _G["DataStore"];
    local _, selectedCharacter = decodeItemListId(GATHERPANEL_ITEM_LIST_SELECTION);
    for characterName, character in pairs(dataStore:GetCharacters()) do
      if (characterName == selectedCharacter and characterName ~= UnitName("player")) then
        local bagCount, bankCount, voidCount, reagentBankCount = dataStore:GetContainerItemCount(character, item.id);
        characterItemCount = bagCount + bankCount + voidCount + reagentBankCount;
      end
    end
  end

  if addon.Variables.user.includeCurrentCharacter then
    characterItemCount = characterItemCount + GetItemCount(item.id, true)
  end

  if addon.Variables.user.includeAllFromRealm then
    if IsAddOnLoaded("Altoholic") then
      local altoholic = _G["Altoholic"]
      item.itemCount = altoholic:GetItemCount(item.id)
    else
      if IsAddOnLoaded("DataStore_Containers") then
        for characterName, character in pairs(DataStore:GetCharacters()) do
          if (characterName ~= UnitName("player")) then
            local bagCount, bankCount, voidCount, reagentBankCount = DataStore:GetContainerItemCount(character, item.id);
            itemCount = itemCount + bagCount + bankCount + voidCount + reagentBankCount;
          end
        end
      end
      item.itemCount = itemCount + characterItemCount
    end
  else
    item.itemCount = characterItemCount
  end

  if item.itemCountTmp == nil then
    item.itemCountTmp = item.itemCount;
  end

  local goal = 0;
  if (item.min > 0) then
    if (item.itemCount < item.min) then
      item.goal = item.min;
      item.goalType = 'min';
    else
      item.goal = item.max;
      item.goalType = 'max';
    end
  else
    item.goal = item.max
    item.goalType = 'max';
  end
  item.progressPercentage = item.itemCount / item.goal;
  if item.max == nil then
    item.max = item.min;
  end
  item.progressPercentageMax = item.itemCount / item.max;
  item.progressPercentageInteger = math.floor(item.progressPercentage * 100);
end


---@param animate boolean
function GatherPanel_UpdateItems(animate)
  local items = getItemlist();
  local locale = GetLocale();
  for i, item in pairs(items) do
    if item.type == "ITEM" then
      GatherPanel_InitItem(item);
      if (item.tracker) then
        GatherPanel_Tracker_UpdateItem(item, animate);
      end
    end
  end
end

local function renderItemGroup(itemRow, group, level, initDropdowns)

  itemRow.ItemName:SetText(group.name);
  itemRow.ItemName:SetPoint("LEFT", itemRow.ExpandOrCollapseButton, "RIGHT", 10, 0);
  itemRow.ItemName:SetPoint("RIGHT", itemRow, "RIGHT", -3, 0);
  itemRow.ItemName:SetFontObject(GameFontNormalLeft);
  local defaultColor = {};
  defaultColor.r, defaultColor.g, defaultColor.b = GameFontNormalLeft:GetTextColor();
  itemRow.ItemName:SetTextColor(defaultColor.r, defaultColor.g, defaultColor.b);

  itemRow.TrackerCheck:Hide();
  itemRow.ExpandOrCollapseButton:Show();
  if group.isCollapsed then
    itemRow.ExpandOrCollapseButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
  else
    itemRow.ExpandOrCollapseButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up");
  end

  itemRow.ItemBar:Hide();

  itemRow.Background:Hide();

  itemRow:SetPoint("LEFT", "GatherPanelInset", "LEFT", 46 * level, 0);

  if initDropdowns and itemRow.item ~= nil then
    UIDropDownMenu_Initialize(itemRow.Context, initDropdownOptions_GroupEdit, "MENU");
  end

  if (itemRow.hovered) then
    itemRow.ItemName:SetTextColor(1, 1, 1);
  else
    itemRow.ItemName:SetTextColor(defaultColor.r, defaultColor.g, defaultColor.b);
  end

  itemRow:Show();

end


---@param item Item
local function renderItemBar(itemRow, item, level)

  itemRow.ItemName:SetText(item.name);
  itemRow.ItemName:SetPoint("LEFT", itemRow, "LEFT", 10, 0);
  itemRow.ItemName:SetPoint("RIGHT", itemRow, "RIGHT", -3, 0);
  itemRow.ItemName:SetFontObject(GameFontHighlightSmall);

  if item.itemQuality ~= nil then
    itemRow.ItemName:SetTextColor(
      ITEM_QUALITY_COLORS[item.itemQuality].r,
      ITEM_QUALITY_COLORS[item.itemQuality].g,
      ITEM_QUALITY_COLORS[item.itemQuality].b
    );
  else
    itemRow.ItemName:SetTextColor(1, 1, 1);
  end

  itemRow.TrackerCheck:Show();
  itemRow.TrackerCheck:SetChecked(item.tracked);
  itemRow.ExpandOrCollapseButton:Hide();

  itemRow.ItemBar:Show();

  if (item.goalType == 'min') then
    itemRow.ItemBar:SetStatusBarColor(0.9, 0.7, 0);
  end
  if (item.goalType == 'max') then
    itemRow.ItemBar:SetStatusBarColor(0.26, 0.42, 1);
  end
  if (item.itemCount >= item.goal) then
    -- r="0.26" g="0.42" b="1"
    itemRow.ItemBar:SetStatusBarColor(0, 0.6, 0.1);
  end

  if (itemRow.hovered or item == _G['ItemDetailFrame'].item) then
    itemRow.ItemBar.Highlight1:Show();
    itemRow.ItemBar.Highlight2:Show();
  else
    itemRow.ItemBar.Highlight1:Hide();
    itemRow.ItemBar.Highlight2:Hide();
  end

  local realGoal, realPercentage;
  if addon.Variables.const.PROGRESS_FORMAT.FILL_TO_GOAL == addon.Variables.global.panelProgressFormat then
    realGoal = item.goal;
    realPercentage = item.progressPercentage;
  elseif addon.Variables.const.PROGRESS_FORMAT.FILL_TO_MAXIMUM == addon.Variables.global.panelProgressFormat then
    realGoal = item.max;
    realPercentage = item.progressPercentageMax;
  end
  itemRow.ItemBar:SetValue(realPercentage);

  if (itemRow.hovered) then
    if addon.Variables.const.COUNT_FORMAT.PERCENT == addon.Variables.global.panelCountFormat
        or addon.Variables.const.COUNT_FORMAT.NONE == addon.Variables.global.panelCountFormat then
      itemRow.ItemBar.Percentage:SetText(item.itemCount .. "/" .. realGoal);
    elseif addon.Variables.const.COUNT_FORMAT.ABSOLUTE == addon.Variables.global.panelCountFormat then
      if (realPercentage >= 1) then
        itemRow.ItemBar.Percentage:SetText(L.T["FULLY_STOCKED"]);
      else
        itemRow.ItemBar.Percentage:SetFormattedText(PERCENTAGE_STRING, realPercentage * 100);
      end
    end
    -- Update tooltip when scrolled
    GameTooltip:SetItemByID(item.id);
  else
    if addon.Variables.const.COUNT_FORMAT.ABSOLUTE == addon.Variables.global.panelCountFormat then
      itemRow.ItemBar.Percentage:SetText(item.itemCount .. "/" .. realGoal);
    elseif addon.Variables.const.COUNT_FORMAT.PERCENT == addon.Variables.global.panelCountFormat then
      if (realPercentage >= 1) then
        itemRow.ItemBar.Percentage:SetText(L.T["FULLY_STOCKED"]);
      else
        itemRow.ItemBar.Percentage:SetFormattedText(PERCENTAGE_STRING, realPercentage * 100);
      end
    elseif addon.Variables.const.COUNT_FORMAT.NONE == addon.Variables.global.panelCountFormat then
      itemRow.ItemBar.Percentage:SetText("");
    end
  end

  itemRow.Background:Show();

  itemRow:SetPoint("LEFT", "GatherPanelInset", "LEFT", 46 * level, 0);

  itemRow:Show();
end

function GatherPanel_UpdatePanel(initDropdowns)
  local itemOffset = FauxScrollFrame_GetOffset(GatherFrameScrollFrame);

  local elements = getItemlist();

  local renderedRows = 0;
  local processedRows = 0;
  local collapsedLevel = 0;

  for i = 1, #sortedHierarchy, 1 do

    local elementKey = sortedHierarchy[i].id;
    local level = sortedHierarchy[i].level;
    local element = elements[elementKey];

    if elementKey == 0 then
      defaultGroup.isCollapsed = GATHERPANEL_DEFAULT_GROUP_COLLAPSED;

      if i+1 <= #sortedHierarchy then
        local nextElement = elements[sortedHierarchy[i+1].id];
        if nextElement and (nextElement.type ~= "GROUP" and nextElement.parent == 0) then
          processedRows = processedRows + 1;
          if (processedRows > itemOffset and renderedRows < GATHERPANEL_NUM_ITEMS_DISPLAYED) then
            local itemRow = _G["GatherBar" .. renderedRows+1];
            itemRow.item = nil;
            itemRow.itemKey = 0;
            renderItemGroup(itemRow, defaultGroup, level, initDropdowns);
            renderedRows = renderedRows + 1;
            itemRow:Show();
          end
          if defaultGroup.isCollapsed then
            collapsedLevel = 0;
          else
            collapsedLevel = 999;
          end
        end
      end
    else
      if element.type == "GROUP" then
        if collapsedLevel >= level then
          processedRows = processedRows + 1;
          if (processedRows > itemOffset and renderedRows < GATHERPANEL_NUM_ITEMS_DISPLAYED) then
            local itemRow = _G["GatherBar" .. renderedRows+1];
            itemRow.item = element;
            itemRow.itemKey = elementKey;
            renderItemGroup(itemRow, element, level, initDropdowns);
            renderedRows = renderedRows + 1;
            itemRow:Show();
          end
          if element.isCollapsed then
            collapsedLevel = level;
          else
            collapsedLevel = 999;
          end
        end
      else
        if collapsedLevel >= level then
          processedRows = processedRows + 1;
          if (processedRows > itemOffset and renderedRows < GATHERPANEL_NUM_ITEMS_DISPLAYED) then
            local itemRow = _G["GatherBar" .. renderedRows+1];
            itemRow.item = element;
            itemRow.itemKey = elementKey;
            renderItemBar(itemRow, element, level);
            renderedRows = renderedRows + 1;
            itemRow:Show();
          end
        end
      end
    end
  end

  for i = renderedRows+1, GATHERPANEL_NUM_ITEMS_DISPLAYED, 1 do
    local itemRow = _G["GatherBar" .. i];
    itemRow:Hide();
  end

  if (not FauxScrollFrame_Update(GatherFrameScrollFrame, processedRows, GATHERPANEL_NUM_ITEMS_DISPLAYED, GATHERPANEL_ITEMBAR_HEIGHT)) then
    GatherFrameScrollFrameScrollBar:SetValue(0);
  end

  GatherPanel_UpdateItemDetails();

end


function GatherPanel_UpdatePanelItems()
  GatherPanel_UpdatePanel(true);
end


function GatherPanel_Tracker_Update()
  if addon.Variables.user.trackerVisible and GATHERPANEL_NUM_TRACKERS_ENABLED > 0 then
    _G["GatherPanel_Tracker"]:Show();
  else
    _G["GatherPanel_Tracker"]:Hide();
  end
end

---@param item Item
---@param animate boolean
function GatherPanel_Tracker_UpdateItem(item, animate)
  local tracker = _G["GatherPanel_Tracker" .. item.tracker];

  local texture = tracker.Bar:GetStatusBarTexture();

  -- Bar Color
  if (item.goalType == 'min') then
    texture:SetAtlas("UI-Frame-Bar-Fill-Yellow");
    tracker.Bar.BarBG:SetVertexColor(0.9, 0.7, 0);
  end
  if (item.goalType == 'max') then
    if (item.goal <= item.itemCount) then
      texture:SetAtlas("UI-Frame-Bar-Fill-Green");
      tracker.Bar.BarBG:SetVertexColor(0, 0.6, 0.1);
    else
      texture:SetAtlas("UI-Frame-Bar-Fill-Blue");
      tracker.Bar.BarBG:SetVertexColor(0.26, 0.42, 1);
    end
  end

  -- Check Mark
  if (item.max <= item.itemCount) then
    tracker.Bar.CheckMarkTexture:Show();
  else
    tracker.Bar.CheckMarkTexture:Hide();
  end

  -- Check Point Marker
  if (addon.Variables.const.PROGRESS_FORMAT.FILL_TO_MAXIMUM == addon.Variables.global.trackerProgressFormat)
      and (item.min > item.itemCount and item.min ~= item.max) then
    tracker.Bar.Checkpoint:Show()
    tracker.Bar.Checkpoint:SetPoint("CENTER", tracker.Bar, "LEFT", item.min/item.max * tracker.Bar:GetWidth(), -1.5);
  else
    tracker.Bar.Checkpoint:Hide()
  end

  -- Progress
  local realGoal, realPercentage;
  if addon.Variables.const.PROGRESS_FORMAT.FILL_TO_GOAL == addon.Variables.global.trackerProgressFormat then
    realGoal = item.goal;
    realPercentage = item.progressPercentage;
  elseif addon.Variables.const.PROGRESS_FORMAT.FILL_TO_MAXIMUM == addon.Variables.global.trackerProgressFormat then
    realGoal = item.max;
    realPercentage = item.progressPercentageMax;
  end
  if (tracker.AnimValue and animate) then
    local delta = realPercentage * 100 - tracker.AnimValue;
    if tracker.AnimValue < 100 and realPercentage >= 1.0 then
      addon.Sounds:PlayQuestComplete();
    end
    local collectedSomething = item.itemCount ~= item.itemCountTmp;
    if collectedSomething and item.itemCountTmp < item.goal then
      local collectedMsg = string.format(
        "%s: %i/%i", item.name, math.min(item.goal, item.itemCount), item.goal
      );
      addon.ObjectiveMessage:Add(collectedMsg);
      GatherPanel_Tracker_PlayFlareAnim(tracker, delta, realPercentage);
    end
    item.itemCountTmp = item.itemCount;
  end
  tracker.AnimValue = realPercentage * 100;
  tracker.Bar:SetValue(realPercentage * 100);

  -- Label
  if addon.Variables.const.COUNT_FORMAT.ABSOLUTE == addon.Variables.global.trackerCountFormat then
    tracker.Bar.Label:SetText(item.itemCount .. "/" .. realGoal);
  elseif addon.Variables.const.COUNT_FORMAT.PERCENT == addon.Variables.global.trackerCountFormat then
    if (realPercentage >= 1) then
      tracker.Bar.Label:SetText(L.T["FULLY_STOCKED"]);
    else
      tracker.Bar.Label:SetFormattedText(PERCENTAGE_STRING, realPercentage * 100);
    end
  elseif addon.Variables.const.COUNT_FORMAT.NONE == addon.Variables.global.trackerCountFormat then
    tracker.Bar.Label:SetText("");
  end
end

function GatherPanel_Tracker_PlayFlareAnim(progressBar, delta, newPercentage)
  if (progressBar.AnimValue >= 100 or delta <= 0) then
    return;
  end

  local animOffset = 14;
  local offset = progressBar.Bar:GetWidth() * newPercentage - animOffset;

  local prefix = "";
  if (delta < 5) then
    prefix = "Small";
  end

  local flare = progressBar[prefix .. "Flare1"];
  if (flare.FlareAnim:IsPlaying()) then
    flare = progressBar[prefix .. "Flare2"];
    if (flare.FlareAnim:IsPlaying()) then
      flare = nil;
    end
  end

  if (flare) then
    flare:SetPoint("LEFT", progressBar.Bar, "LEFT", offset, 0);
    flare.FlareAnim:Play();
  end

  local barFlare = progressBar["FullBarFlare1"];
  if (barFlare.FlareAnim:IsPlaying()) then
    barFlare = progressBar["FullBarFlare2"];
    if (barFlare.FlareAnim:IsPlaying()) then
      barFlare = nil;
    end
  end

  if (barFlare) then
    barFlare.FlareAnim:Play();
  end
end

local function migrate_2_0_0()

  --[[
    Previously saved variables
    - GATHERPANEL_ITEMS_CHARACTER and
    - GATHERPANEL_ITEMS
    are now obsolete and got replaced by the new character
    based item lists.
  ]] --

  local realm = GetRealmName();
  local characterName = UnitName("player");

  if GATHERPANEL_ITEMLISTS[realm] == nil then
    GATHERPANEL_ITEMLISTS[realm] = {};
  end

  if GATHERPANEL_ITEMLISTS[realm][characterName] == nil then
    GATHERPANEL_ITEMLISTS[realm][characterName] = {};
  end

  if GATHERPANEL_ITEMS_CHARACTER and #GATHERPANEL_ITEMS_CHARACTER > 0 then
    for i, item in ipairs(GATHERPANEL_ITEMS_CHARACTER) do
      GATHERPANEL_ITEMLISTS[realm][characterName][item["id"]] = {};
      for k, v in pairs(item) do
        GATHERPANEL_ITEMLISTS[realm][characterName][item["id"]][k] = v;
      end
    end
  end

  if GATHERPANEL_ITEMS and #GATHERPANEL_ITEMS > 0 then
    for i, item in ipairs(GATHERPANEL_ITEMS) do
      GATHERPANEL_ITEMLISTS[realm][characterName][item["id"]] = {};
      for k, v in pairs(item) do
        GATHERPANEL_ITEMLISTS[realm][characterName][item["id"]][k] = v;
      end
    end
  end

  GATHERPANEL_ITEMS_CHARACTER = nil;
  GATHERPANEL_ITEMS = nil;
  print("Gather Panel migrated to 2.0.0");
end

local function migrate_2_1_0()
  --[[
    Not only items are stored in the item lists, we now support parents
    and structural-only items ("groups").
  ]] --
  for realm, characters in pairs(GATHERPANEL_ITEMLISTS) do
    for character, items in pairs(characters) do
      for itemId, item in pairs(items) do
        item.parent = 0;
        item.type = "ITEM";
      end
    end
  end
  print("Gather Panel migrated to 2.1.0");
end

local function meetsVersionRequirement(major, minor, patch)
  -- fresh install: always newest DB version
  if (GATHERPANEL_VERSION == nil) then
    return true;
  end

  if (GATHERPANEL_VERSION.major > major) then
    return true;
  end

  if (GATHERPANEL_VERSION.major == major) then
    if (GATHERPANEL_VERSION.minor > minor) then
      return true;
    end
    if (GATHERPANEL_VERSION.minor == minor) then
      if (GATHERPANEL_VERSION.patch >= patch) then
        return true;
      end
    end
  end

  return false;
end

local function doMigrations()
  -- shortcut if we already are on newest release (speed up reloads)
  if meetsVersionRequirement(
    CURRENT_GATHERPANEL_VERSION.major,
    CURRENT_GATHERPANEL_VERSION.minor,
    CURRENT_GATHERPANEL_VERSION.patch
  ) then
    print("Already up to date.");
    return;
  end

  print("Checking version...");

  if not meetsVersionRequirement(2, 0, 0) then
    migrate_2_0_0();
  end
  if not meetsVersionRequirement(2, 1, 0) then
    migrate_2_1_0();
  end
  if not meetsVersionRequirement(2, 4, 0) then
    GatherPanel_Migrate_2_4_0();
  end
end

local function loadCurrentVersion()
  local version = GetAddOnMetadata("GatherPanel", "VERSION");
  if version == nil then
    version = "0.0.0"
  end

  local major, minor, patch = string.match(version, "(%d+)%.(%d+).(%d+)");
  CURRENT_GATHERPANEL_VERSION = {
    major = tonumber(major),
    minor = tonumber(minor),
    patch = tonumber(patch),
  }
end

local function saveCurrentVersion()
  GATHERPANEL_VERSION = CURRENT_GATHERPANEL_VERSION;
end

function GatherPanel_OnEvent(event)
  if event == 'ADDON_LOADED' and not GATHERPANEL_LOADED then
    GATHERPANEL_LOADED = true;

    loadCurrentVersion();
    doMigrations();
    saveCurrentVersion();

    addon.Variables.global = GATHERPANEL_VARIABLES_GLOBAL or {};
    GATHERPANEL_VARIABLES_GLOBAL = addon.Variables.global;
    addon.Variables.user = GATHERPANEL_VARIABLES_USER or {};
    GATHERPANEL_VARIABLES_USER = addon.Variables.user;

    addon:LoadModules();

    SelectItemlist(nil, GATHERPANEL_ITEM_LIST_SELECTION);

    --TODO: Initialize them in XML or somewhere where it is not
    -- necessary to use injected global variables from frame names.

    UIDropDownMenu_Initialize(GatherPanel_ItemlistSelection, InitListOptions);
    UIDropDownMenu_SetWidth(GatherPanel_ItemlistSelection, 120);
    UIDropDownMenu_Initialize(ItemDetailFrame.ParentDropDown, InitParentSelectionOptions_DetailFrame);
    UIDropDownMenu_SetWidth(ItemDetailFrame.ParentDropDown, 120);
    UIDropDownMenu_Initialize(GatherPanel_Panel2.Inset.ParentDropDown, InitParentSelectionOptions_CreateFrame);
    UIDropDownMenu_SetText(GatherPanel_Panel2.Inset.ParentDropDown, defaultGroup.name);
    UIDropDownMenu_SetWidth(GatherPanel_Panel2.Inset.ParentDropDown, 120);

    -- Run Tracker Update once addon loaded saved variable
    GatherPanel_Tracker_Update();
    GatherPanel_UpdatePanel(true);
  end

  if GATHERPANEL_LOADED == true then
    -- Run Item and Bar Updates every event (as most commonly the character received a new item)
    GatherPanel_UpdateItems(true);
    GatherPanel_UpdatePanel();
  end
end

function GatherPanel_Bar_OnEnter(frame)
  -- Rollover Text
  frame.hovered = true;
  if frame.item and frame.item.type == "ITEM" then
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT");
    GameTooltip:SetItemByID(frame.item.id);
    GameTooltip:Show();
  end
  GatherPanel_UpdatePanel();
end

function GatherPanel_Bar_OnLeave(frame)
  frame.hovered = false;
  GameTooltip_Hide();
  GatherPanel_UpdatePanel();
end



---@param item Item
local function item_ExpandOrCollapse(item)
  item.isCollapsed = not item.isCollapsed
  GatherPanel_UpdatePanelItems();
end


local function expandOrCollapseDefaultGroup()
  GATHERPANEL_DEFAULT_GROUP_COLLAPSED = not GATHERPANEL_DEFAULT_GROUP_COLLAPSED;
  GatherPanel_UpdatePanelItems();
end

function GatherPanel_Bar_OnClick(frame, button)
  if frame.item and frame.item.type == "ITEM" then
    local item = frame.item;
    if ( IsModifiedClick("CHATLINK") ) then
      local itemName, itemLink = GetItemInfo(frame.itemKey);
      if ( IsModifiedClick("CHATLINK") ) then
        local linkType = string.match(itemLink, "|H([^:]+)");
        if ( linkType == "instancelock" ) then	--People can't re-link instances that aren't their own.
          local guid = string.match(itemLink, "|Hinstancelock:([^:]+)");
          if ( not string.find(UnitGUID("player"), guid) ) then
            return true;
          end
        end
        if ( ChatEdit_InsertLink(itemLink) ) then
          return true;
        elseif ( SocialPostFrame and Social_IsShown() ) then
          Social_InsertLink(itemLink);
          return true;
        end
      end
    else
      _G['ItemDetailFrame'].item = item;
      GatherPanel_UpdateItemDetails();
      _G['ItemDetailFrame']:Show();
    end
  elseif frame.item and frame.item.type == "GROUP" then
    if button == "RightButton" then
      if frame.itemKey ~= 0 then
        ToggleDropDownMenu(1, nil, frame.Context);
      end
    elseif button == "LeftButton" then
      item_ExpandOrCollapse(frame.item);
    end
  elseif frame.itemKey == 0 then
    -- presumably the default category...
    -- should set a flag or something hovered
    if button == "LeftButton" then
      expandOrCollapseDefaultGroup();
    end
  end
end

function GatherPanel_Bar_ExpandOrCollapse_OnClick(self)
  item_ExpandOrCollapse(self:GetParent().item);
end

function GatherPanel_UpdateItemDetails()
  local frame = _G['ItemDetailFrame'];
  if frame.item ~= nil then
    frame.TrackerCheckBox:SetChecked(frame.item.tracked);
    _G['ItemName']:SetText(frame.item.name);
    frame.MinQuantityInput:SetText(frame.item.min);
    frame.MaxQuantityInput:SetText(frame.item.max);
    local items = getItemlist();
    local parent = items[frame.item.parent];
    if parent == nil then
      UIDropDownMenu_SetText(frame.ParentDropDown, defaultGroup.name);
      UIDropDownMenu_SetWidth(frame.ParentDropDown, 120);
    else
      UIDropDownMenu_SetText(frame.ParentDropDown, parent.name);
      UIDropDownMenu_SetWidth(frame.ParentDropDown, 120);
    end
  end
end

function GatherPanel_ReloadTracker()
  -- Remove all trackers
  for i = 1, GATHERPANEL_NUM_TRACKERS_CREATED, 1 do
    _G["GatherPanel_Tracker" .. i].item = nil;
    _G["GatherPanel_Tracker" .. i]:Hide();
  end
  GATHERPANEL_NUM_TRACKERS_ENABLED = 0;

  local items = getItemlist();

  local itemKeys = {};
  for itemId, _ in pairs(items) do
    table.insert(itemKeys, itemId);
  end

  table.sort(itemKeys);

  -- Reinitialize trackers from item list
  for i, itemId in ipairs(itemKeys) do
    local item = items[itemKeys[i]];
    item.tracker = nil;
    if item.tracked == true then
      GatherPanel_InitItem(item)
      GatherPanel_CreateTrackerForItem(item)
      GatherPanel_Tracker_UpdateItem(item, false)
    end
  end
  GatherPanel_Tracker_Update();
end



---@param item Item
function GatherPanel_TrackItem(item)
  if (item.tracked) then
    if item.itemCount < item.max then
      addon.Sounds:PlayAbandonQuest();
    end
    item.tracked = false;
    item.tracker = nil;
    -- Rearrange trackers
    local newTracker = 0;
    for i, item in pairs(getItemlist()) do
      if (item.tracker) then
        newTracker = newTracker + 1;
        item.tracker = newTracker;
        local tracker = _G["GatherPanel_Tracker" .. newTracker];
        tracker.icon = item.itemTexture;
        tracker.item = item;
        tracker.AnimValue = item.progressPercentageMax * 100;
        tracker.Bar.Icon:SetTexture(item.itemTexture);
        if (item.goal <= item.itemCount) then
          tracker.Bar.CheckMarkTexture:Show();
        else
          tracker.Bar.CheckMarkTexture:Hide();
        end
      end
    end
    _G["GatherPanel_Tracker" .. GATHERPANEL_NUM_TRACKERS_ENABLED]:Hide();
    GATHERPANEL_NUM_TRACKERS_ENABLED = GATHERPANEL_NUM_TRACKERS_ENABLED - 1;
  elseif item ~= nil then
    addon.Sounds:PlayQuestAccepted();
    GatherPanel_CreateTrackerForItem(item)
  end
  GatherPanel_UpdateItems(false);
  GatherPanel_UpdatePanel();
  GatherPanel_ReloadTracker();
end

---@param item Item
function GatherPanel_CreateTrackerForItem(item)
  -- Enable Tracker
  local tracker;
  if (GATHERPANEL_NUM_TRACKERS_ENABLED == GATHERPANEL_NUM_TRACKERS_CREATED) then
    local tracker = CreateFrame("Frame", "GatherPanel_Tracker" .. GATHERPANEL_NUM_TRACKERS_CREATED + 1, _G["GatherPanel_Tracker"],
        "GatherPanel_Tracker_Template");
    tracker:SetPoint("TOPLEFT", "GatherPanel_Tracker" .. GATHERPANEL_NUM_TRACKERS_CREATED, "BOTTOMLEFT", 0, 5);
    tracker.animValue = nil;
    GATHERPANEL_NUM_TRACKERS_CREATED = GATHERPANEL_NUM_TRACKERS_CREATED + 1;
  end
  GATHERPANEL_NUM_TRACKERS_ENABLED = GATHERPANEL_NUM_TRACKERS_ENABLED + 1;
  item.tracker = GATHERPANEL_NUM_TRACKERS_ENABLED;
  tracker = _G["GatherPanel_Tracker" .. item.tracker];
  tracker.icon = item.itemTexture;
  tracker.item = item;
  tracker.Bar.Icon:SetTexture(item.itemTexture);
  if item.min ~= item.max and item.min > item.itemCount then
    tracker.Bar.Checkpoint:Show();
    tracker.Bar.Checkpoint:SetPoint("CENTER", tracker.Bar, "LEFT", item.min/item.max * tracker.Bar:GetWidth(), -1.5);
  else
    tracker.Bar.Checkpoint:Hide();
  end
  if (item.goal <= item.itemCount) then
    tracker.Bar.CheckMarkTexture:Show();
  else
    tracker.Bar.CheckMarkTexture:Hide();
  end
  tracker:Show();
  item.tracked = true;
  UIDropDownMenu_Initialize(tracker.Context, initDropdownOptions_TrackerBarContext, "MENU");
end

function GatherPanel_SetAllCharacters(checked)
  addon.Variables.user.includeAllFromRealm = checked;
  GatherPanel_UpdateItems(false);
  GatherPanel_UpdatePanel();
end

function GatherPanel_SetIncludeCurrentCharacter(checked)
  addon.Variables.user.includeCurrentCharacter = checked;
  GatherPanel_UpdateItems(false);
  GatherPanel_UpdatePanel();
end

function GatherPanel_SetPanel(id)
  _G['GatherPanel_Panel' .. _G['GatherPanel'].selectedTab]:Hide();
  _G['GatherPanel_Panel' .. id]:Show();
end

function GatherPanel_Tab_OnClick(tab)
  GatherPanel_SetPanel(tab:GetID());
  PanelTemplates_SetTab(_G['GatherPanel'], tab:GetID());
  addon.Sounds:PlayTabSelect();
end

function GatherPanel_ItemDetailUpdateQuantity(frame)
  local item = frame:GetParent().item;
  item.min = tonumber(frame:GetParent().MinQuantityInput:GetText());
  item.max = tonumber(frame:GetParent().MaxQuantityInput:GetText());
  GatherPanel_UpdateItems(false);
  GatherPanel_UpdatePanel();
end

function GatherPanel_ItemDetailMin_OnEnter(frame)
  GatherPanel_ItemDetailQuantity_Update(frame);
  frame:ClearFocus();
end

function GatherPanel_ItemDetailMin_OnTab(frame)
  GatherPanel_ItemDetailQuantity_Update(frame);
  frame:ClearFocus();
  frame:GetParent().MinQuantityInput:SetFocus();
end

function GatherPanel_ItemDetailMax_OnEnter(frame)
  GatherPanel_ItemDetailQuantity_Update(frame);
  frame:ClearFocus();
end

function GatherPanel_ItemDetailMax_OnTab(frame)
  GatherPanel_ItemDetailQuantity_Update(frame);
  frame:ClearFocus();
end

function GatherPanel_ItemDetailQuantity_Update(frame)
  local amountMin = tonumber(frame:GetParent().MinQuantityInput:GetText());
  local amountMax = tonumber(frame:GetParent().MaxQuantityInput:GetText());
  if amountMin == nil or amountMin <= 0 then
    amountMin = 0;
  end
  if amountMax == nil or amountMax <= 0 then
    amountMax = 0;
  end
  if amountMin > amountMax then
    amountMax = amountMin;
  end
  frame:GetParent().MinQuantityInput:SetText(tostring(amountMin));
  frame:GetParent().MaxQuantityInput:SetText(tostring(amountMax));
end

function GatherPanel_NewItem_CreateButton_OnClick(frame)
  local items = getItemlist();
  local itemID = tonumber(frame:GetParent().ItemIdInput:GetText());

  if itemID == nil then
    return;
  end

  local min = tonumber(frame:GetParent().MinQuantityInput:GetText());
  if (min == nil or min < 0) then
    min = 0;
  end
  local max = tonumber(frame:GetParent().MaxQuantityInput:GetText());
  if (max == nil or max < min) then
    max = min;
  end

  local parent = frame:GetParent().ParentDropDown.parentId;

  items[itemID] = {
    id = itemID,
    min = min,
    max = max,
    parent = parent
  };

  GatherPanel_InitializeSortedItemList();
  GatherPanel_ReloadTracker();
  GatherPanel_UpdateItems(false);
  GatherPanel_UpdatePanel();
  GatherPanel_TrackItem(items[itemID]);
  frame:GetParent().CreateButton:Disable();
  frame:GetParent().ItemIdInput:SetText('');
  frame:GetParent().MinQuantityInput:SetText('');
  frame:GetParent().MaxQuantityInput:SetText('');

  frame:GetParent().ItemButton.Icon:SetTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot");
  frame:GetParent().ItemButton.Name:SetText('');
  frame:GetParent().LabelInstructions:SetText(L.T["DRAG_ITEM_OR_SET_ITEM_ID"]);
end

function GatherPanel_EditGroup(group, newName)
  group.name = newName;
  if group.name == "" then
    group = nil;
  end
  GatherPanel_InitializeSortedItemList();
  GatherPanel_UpdatePanel();
end

function GatherPanel_CreateGroup(groupName)
  local items = GatherPanel_GetItemList();
  local minItemId = 0;
  for elementId, element in pairs(items) do
    if elementId < minItemId then
      minItemId = elementId;
    end
  end

  items[minItemId - 1] = {
    name = groupName,
    type = "GROUP",
    parent = nil,
    isCollapsed = false
  }
  GatherPanel_InitializeSortedItemList();
  GatherPanel_UpdatePanel();
end

function GatherPanel_Group_CreateButton_OnClick()
  StaticPopup_Show("GATHERPANEL_CREATE_GROUP")
end

function GatherPanel_NewItem_ItemButton_OnReceive(frame)
  local infoType, itemId, itemLink = GetCursorInfo();
  frame:GetParent().LabelInstructions:SetText(L.T["DRAG_ITEM_OR_SET_ITEM_ID"]);
  frame:GetParent().LabelInstructions:SetTextColor(1, 1, 1);
  -- frame:GetParent().ItemIdInput:SetText("");
  frame:GetParent().MinQuantityInput:SetText("");
  frame:GetParent().MaxQuantityInput:SetText("");
  if (infoType == 'item') then
    frame:SetText(tonumber(itemId));
    local itemName, _, itemQuality, _, _, _, _, _, _, itemTexture, _, _, _, _, _, _, _ = GetItemInfo(itemId);
    frame.Name:SetText(itemName);
    frame.Name:SetTextColor(ITEM_QUALITY_COLORS[itemQuality].r, ITEM_QUALITY_COLORS[itemQuality].g, ITEM_QUALITY_COLORS[itemQuality].b);
    frame.Icon:SetTexture(itemTexture);
    frame:GetParent().ItemIdInput:SetText(itemId);
    ClearCursor();
    frame:GetParent().MinQuantityInput:SetFocus();
    if GatherPanel_NewItem_IsAlreadyAdded(itemId) then
      frame:GetParent().LabelInstructions:SetTextColor(1, 0, 0);
      frame:GetParent().LabelInstructions:SetText(L.T["ITEM_ALREADY_ON_LIST"]);
      frame:GetParent().CreateButton:Disable();
      frame:GetParent().MinQuantityInput:Disable();
      frame:GetParent().MinQuantityInput.Label:SetTextColor(0.6, 0.6, 0.6);
      frame:GetParent().MaxQuantityInput:Disable();
      frame:GetParent().MaxQuantityInput.Label:SetTextColor(0.6, 0.6, 0.6);
    else
      frame:GetParent().LabelInstructions:SetTextColor(1, 1, 1);
      frame:GetParent().LabelInstructions:SetText(L.T["DEFINE_STOCK_GOALS"]);
      frame:GetParent().CreateButton:Enable();
      frame:GetParent().MinQuantityInput:Enable();
      frame:GetParent().MinQuantityInput.Label:SetTextColor(1, 0.82, 0);
      frame:GetParent().MaxQuantityInput:Enable();
      frame:GetParent().MaxQuantityInput.Label:SetTextColor(1, 0.82, 0);
    end
  end
end

function GatherPanel_NewItem_Id_OnReceive(frame)
  GatherPanel_NewItem_ItemButton_OnReceive(frame:GetParent().ItemButton);
end

function GatherPanel_NewItem_IsAlreadyAdded(newItemId)
  for itemId, item in pairs(getItemlist()) do
    if (itemId == newItemId) then
      return true;
    end
  end
  return false;
end

function GatherPanel_NewItem_Id_CheckItem(frame)
  frame:GetParent().LabelInstructions:SetText(L.T["DRAG_ITEM_OR_SET_ITEM_ID"]);
  frame:GetParent().LabelInstructions:SetTextColor(1, 1, 1);
  frame:GetParent().MinQuantityInput:SetText("");
  frame:GetParent().MaxQuantityInput:SetText("");
  local itemId = tonumber(frame:GetText());
  if (itemId) then
    frame:GetParent().ItemButton.Name:SetTextColor(1, 1, 1);
    local itemName, _, itemQuality, _, _, _, _, _, _, itemTexture, _, _, _, _, _, _, _ = GetItemInfo(itemId);
    if itemName then
      frame:GetParent().ItemButton.Name:SetText(itemName);
      frame:GetParent().ItemButton.Name:SetTextColor(
        ITEM_QUALITY_COLORS[itemQuality].r,
        ITEM_QUALITY_COLORS[itemQuality].g,
        ITEM_QUALITY_COLORS[itemQuality].b
      );
      frame:GetParent().ItemButton.Icon:SetTexture(itemTexture);
      frame:GetParent().ItemIdInput:SetText(itemId);
      frame:GetParent().ItemButton.Name:SetText(itemName);

      if GatherPanel_NewItem_IsAlreadyAdded(itemId) then
        frame:GetParent().LabelInstructions:SetTextColor(1, 0, 0);
        frame:GetParent().LabelInstructions:SetText(L.T["ITEM_ALREADY_ON_LIST"]);
        frame:GetParent().CreateButton:Disable();
        frame:GetParent().MinQuantityInput:Disable();
        frame:GetParent().MinQuantityInput.Label:SetTextColor(0.6, 0.6, 0.6);
        frame:GetParent().MaxQuantityInput:Disable();
        frame:GetParent().MaxQuantityInput.Label:SetTextColor(0.6, 0.6, 0.6);
      else
        frame:GetParent().LabelInstructions:SetTextColor(1, 1, 1);
        frame:GetParent().LabelInstructions:SetText(L.T["DEFINE_STOCK_GOALS"]);
        frame:GetParent().CreateButton:Enable();
        frame:GetParent().MinQuantityInput:Enable();
        frame:GetParent().MinQuantityInput.Label:SetTextColor(1, 0.82, 0);
        frame:GetParent().MaxQuantityInput:Enable();
        frame:GetParent().MaxQuantityInput.Label:SetTextColor(1, 0.82, 0);
        ClearCursor();
        frame:ClearFocus();
        frame:GetParent().MinQuantityInput:SetFocus();
      end
      return
    end
  end
  frame:GetParent().ItemButton.Name:SetTextColor(1, 0, 0);
  frame:GetParent().ItemButton.Name:SetText(L.T["ITEM_ID_INVALID"]);
  frame:GetParent().ItemButton.Icon:SetTexture("Interface\\ICONS\\inv_misc_questionmark");
end

function GatherPanel_TrackerX_OnMouseUp(self, button)
  if button == "RightButton" then
    ToggleDropDownMenu(1, nil, self.Context);
  elseif ( IsModifiedClick("CHATLINK") ) then
    if self.item and self.item.type == "ITEM" then
      local itemName, itemLink = GetItemInfo(self.item.id);
      if ( IsModifiedClick("CHATLINK") ) then
        local linkType = string.match(itemLink, "|H([^:]+)");
        if ( linkType == "instancelock" ) then	--People can't re-link instances that aren't their own.
          local guid = string.match(itemLink, "|Hinstancelock:([^:]+)");
          if ( not string.find(UnitGUID("player"), guid) ) then
            return true;
          end
        end
        if ( ChatEdit_InsertLink(itemLink) ) then
          return true;
        elseif ( SocialPostFrame and Social_IsShown() ) then
          Social_InsertLink(itemLink);
          return true;
        end
      end
    end
  end
end

function GatherPanel_TrackerX_OnEnter(self)
  local realGoal, realPercentage;
  if addon.Variables.const.PROGRESS_FORMAT.FILL_TO_GOAL == addon.Variables.global.trackerProgressFormat then
    realGoal = self.item.goal;
    realPercentage = self.item.progressPercentage;
  elseif addon.Variables.const.PROGRESS_FORMAT.FILL_TO_MAXIMUM == addon.Variables.global.trackerProgressFormat then
    realGoal = self.item.max;
    realPercentage = self.item.progressPercentageMax;
  end
  if addon.Variables.const.COUNT_FORMAT.PERCENT == addon.Variables.global.trackerCountFormat
      or addon.Variables.const.COUNT_FORMAT.NONE == addon.Variables.global.trackerCountFormat then
    self.Bar.Label:SetText(self.item.itemCount .. "/" .. realGoal);
  elseif addon.Variables.const.COUNT_FORMAT.ABSOLUTE == addon.Variables.global.trackerCountFormat then
    if (realPercentage >= 1) then
      self.Bar.Label:SetText(L.T["FULLY_STOCKED"]);
    else
      self.Bar.Label:SetFormattedText(PERCENTAGE_STRING, realPercentage * 100);
    end
  end

  local x, y = GetCursorPosition();
  x = x / UIParent:GetEffectiveScale();
  y = y / UIParent:GetEffectiveScale();
  local width = UIParent:GetWidth();
  local height = UIParent:GetHeight();
  local relX = x/width;
  local relY = y/height;

  local anchor;
  if (relX < 0.5) then
    if (relY < 0.5) then
      anchor = "ANCHOR_TOPLEFT";
    else
      anchor = "ANCHOR_BOTTOMRIGHT";
    end
  else
    if (relY < 0.5) then
      anchor = "ANCHOR_TOPRIGHT";
    else
      anchor = "ANCHOR_BOTTOMLEFT";
    end
  end

  GameTooltip:SetOwner(self, anchor);
  GameTooltip:SetItemByID(self.item.id);
  GameTooltip:Show();
end

function GatherPanel_TrackerX_OnLeave(self) local realGoal, realPercentage;
  if addon.Variables.const.PROGRESS_FORMAT.FILL_TO_GOAL == addon.Variables.global.trackerProgressFormat then
    realGoal = self.item.goal;
    realPercentage = self.item.progressPercentage;
  elseif addon.Variables.const.PROGRESS_FORMAT.FILL_TO_MAXIMUM == addon.Variables.global.trackerProgressFormat then
    realGoal = self.item.max;
    realPercentage = self.item.progressPercentageMax;
  end
  if addon.Variables.const.COUNT_FORMAT.ABSOLUTE == addon.Variables.global.trackerCountFormat then
    self.Bar.Label:SetText(self.item.itemCount .. "/" .. realGoal);
  elseif addon.Variables.const.COUNT_FORMAT.PERCENT == addon.Variables.global.trackerCountFormat then
    if (realPercentage >= 1) then
      self.Bar.Label:SetText(L.T["FULLY_STOCKED"]);
    else
      self.Bar.Label:SetFormattedText(PERCENTAGE_STRING, realPercentage * 100);
    end
  elseif addon.Variables.const.COUNT_FORMAT.NONE == addon.Variables.global.trackerCountFormat then
    self.Bar.Label:SetText("");
  end
  GameTooltip_Hide();
end
