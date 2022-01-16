local addonName, L = ...;

GATHERPANEL_ITEMBAR_HEIGHT = 26;
GATHERPANEL_NUM_ITEMS_DISPLAYED = 15;
GATHERPANEL_NUM_TRACKERS_ENABLED = 0;
GATHERPANEL_NUM_TRACKERS_CREATED = 1;
GATHERPANEL_LOADED = false;
GATHERPANEL_SETTINGS = {
  trackerVisible = true,
  includeAllFromRealm = false,
  includeCurrentCharacter = true,
  minimapPosition = { -18, -100 },
}

GATHERPANEL_COUNT_FORMAT = {
  PERCENT = 0,            -- " 32% "
  ABSOLUTE = 1,           -- "16/50"
  NONE = 2,               -- "     "
}

GATHERPANEL_PROGRESS_FORMAT = {
  FILL_TO_GOAL = 0,       -- reputation style: first min, then max
  FILL_TO_MAXIMUM = 1,    -- show progress directly to the max goal
}

GATHERPANEL_SETTINGS_GLOBAL = {
  panelCountFormat = GATHERPANEL_COUNT_FORMAT.PERCENT,
  panelProgressFormat = GATHERPANEL_PROGRESS_FORMAT.FILL_TO_GOAL,
  trackerCountFormat = GATHERPANEL_COUNT_FORMAT.PERCENT,
  trackerProgressFormat = GATHERPANEL_PROGRESS_FORMAT.FILL_TO_MAXIMUM,
}

GATHERPANEL_DEFAULT_GROUP_COLLAPSED = false;

GATHERPANEL_ITEMLISTS = {};
GATHERPANEL_ITEM_LIST_SELECTION = nil;

GATHERPANEL_VERSION = {
  ["major"] = 2,
  ["minor"] = 0,
  ["patch"] = 0 
}

-- setup localization
local function L_Default(L, key)
  return key;
end
setmetatable(L, { __index=L_Default });
GATHERPANEL_L = L;

local sortedHierarchy = {};
local defaultGroup = {
  name = L["UNCATEGORIZED"],
  type = "GROUP",
  parent = nil,
  isCollapsed = GATHERPANEL_DEFAULT_GROUP_COLLAPSED
};

local function GetItemlistId(realm, characterName)
  return realm .. ":" .. characterName;
end

local function getOptionName(enum, value, prefix)
  for key, val in pairs(enum) do
    if val == value then
      return L[prefix .. "_" .. key];
    end
  end
  return L["NOT_FOUND"]
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

  local linearized = {};
  for rootId, root in pairs(roots) do
    traverse(linearized, rootId, root, 0);
  end

  return linearized;
end

local function decodeItemListId(itemListId)
  local t = {};
  for str in string.gmatch(itemListId, "([^:]+)") do
    table.insert(t, str)
  end
  realm = t[1];
  characterName = t[2]
  return realm, characterName;
end

function GatherPanel_GetItemList()
  if GATHERPANEL_CURRENT_ITEM_LIST == nil then
    return {}
  end
  return GATHERPANEL_CURRENT_ITEM_LIST;
end

local function getItemlist()
  return GatherPanel_GetItemList();
end

local function getGroups()
  local realm, characterName = decodeItemListId(GATHERPANEL_ITEM_LIST_SELECTION)
  if GATHERPANEL_ITEM_GROUPS[realm] ~= nil and GATHERPANEL_ITEM_GROUPS[realm][characterName] ~= nil then
    return GATHERPANEL_ITEM_GROUPS[realm][characterName];
  end
  return {};
end

local function setItemList()
  if GATHERPANEL_ITEM_LIST_SELECTION == GetItemlistId("X-Internal", "Combined") then
    local itemList = {};
    for realm, characterTable in pairs(GATHERPANEL_ITEMLISTS) do
      if realm == GetRealmName() then
        for characterName, itemTable in pairs(characterTable) do
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
    realm, characterName = decodeItemListId(GATHERPANEL_ITEM_LIST_SELECTION);
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
  return;
end

local function getItemlistLength()
  local c = 0;
  for i, v in pairs(getItemlist()) do
    c = c + 1;
  end
  return c;
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



local function AddCharacter()
  local realm = GetRealmName();
  local player = UnitName("player");
  if GATHERPANEL_ITEMLISTS[realm][player] == nil then
    GATHERPANEL_ITEMLISTS[realm][player] = {};
  end
end

local function SelectParentGroup(self, parentId)
  local item = _G["ItemDetailFrame"].item;
  item.parent = parentId;
  GatherPanel_InitializeSortedItemList();
  GatherPanel_UpdateItems();
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
  realm, characterName = decodeItemListId(GATHERPANEL_ITEM_LIST_SELECTION);
  if GATHERPANEL_ITEM_LIST_SELECTION == GetItemlistId("X-Internal", "Combined") then
    UIDropDownMenu_SetText(GatherPanel_ItemlistSelection, L["COMBINED"]);
  else
    UIDropDownMenu_SetText(GatherPanel_ItemlistSelection, characterName);
  end
  CloseDropDownMenus();
  GatherPanel_InitializeSortedItemList();
  GatherPanel_ReloadTracker();
  GatherPanel_UpdateItems();
  GatherPanel_UpdatePanel();
end

local function trackItem(self, item)
  GatherPanel_TrackItem(item);
end

local function group_ShowEditPopup(self, item)
  StaticPopup_Show("GATHERPANEL_GROUP_EDIT_NAME", item.name, nil, item);
end



function GatherPanel_ItemDetailDeleteButton_OnClick(frame)
  local itemID = frame:GetParent().item.id;

  for i, item in pairs(getItemlist()) do
    if (item.id == itemID) then
      getItemlist()[i] = nil;
      PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
      frame:GetParent().item = nil;
      GatherPanel_InitializeSortedItemList();
      GatherPanel_UpdateItems();
      GatherPanel_UpdatePanelItems();
      HideParentPanel(frame);
      return;
    end
  end
end

function GatherPanel_Context_ItemDelete(self, itemKey)
  local items = getItemlist();
  items[itemKey] = nil;
  item = nil;
  PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
  GatherPanel_InitializeSortedItemList();
  GatherPanel_UpdateItems();
  GatherPanel_UpdatePanelItems();
end

function GatherPanel_Settings_SetPanelCountFormat(self, format)
  GATHERPANEL_SETTINGS_GLOBAL.panelCountFormat = format;
  GatherPanel_UpdatePanel();
  UIDropDownMenu_SetText(GatherPanel_Panel3.Inset.PanelOptions.CountFormat, getOptionName(GATHERPANEL_COUNT_FORMAT, format, "COUNT_FORMAT"));
end

function GatherPanel_Settings_SetPanelProgressFormat(self, format)
  GATHERPANEL_SETTINGS_GLOBAL.panelProgressFormat = format;
  GatherPanel_UpdatePanel();
  UIDropDownMenu_SetText(GatherPanel_Panel3.Inset.PanelOptions.ProgressFormat, getOptionName(GATHERPANEL_PROGRESS_FORMAT, format, "PROGRESS_FORMAT"));
end

function GatherPanel_Settings_SetTrackerCountFormat(self, format)
  GATHERPANEL_SETTINGS_GLOBAL.trackerCountFormat = format;
  GatherPanel_UpdateItems();
  UIDropDownMenu_SetText(GatherPanel_Panel3.Inset.TrackerOptions.CountFormat, getOptionName(GATHERPANEL_COUNT_FORMAT, format, "COUNT_FORMAT"));
end

function GatherPanel_Settings_SetTrackerProgressFormat(self, format)
  GATHERPANEL_SETTINGS_GLOBAL.trackerProgressFormat = format;
  GatherPanel_UpdateItems();
  UIDropDownMenu_SetText(GatherPanel_Panel3.Inset.TrackerOptions.ProgressFormat, getOptionName(GATHERPANEL_PROGRESS_FORMAT, format, "PROGRESS_FORMAT"));
end


local function generateDropdownOptions_ProgressFormat(func)
  for key, value in pairs(GATHERPANEL_PROGRESS_FORMAT) do
    local info = UIDropDownMenu_CreateInfo();
    info.text = L["PROGRESS_FORMAT_" .. key];
    info.func = func
    info.notCheckable = true;
    info.arg1 = value;
    UIDropDownMenu_AddButton(info);
  end
end


local function generateDropdownOptions_CountFormat(func)
  for key, value in pairs(GATHERPANEL_COUNT_FORMAT) do
    local info = UIDropDownMenu_CreateInfo();
    info.text = L["COUNT_FORMAT_" .. key];
    info.func = func
    info.notCheckable = true;
    info.arg1 = value;
    UIDropDownMenu_AddButton(info);
  end
end

local function initDropdownOptions_PanelCountFormat(self)
  generateDropdownOptions_CountFormat(GatherPanel_Settings_SetPanelCountFormat);
end

local function initDropdownOptions_PanelProgressFormat(self)
  generateDropdownOptions_ProgressFormat(GatherPanel_Settings_SetPanelProgressFormat);
end

local function initDropdownOptions_TrackerCountFormat(self)
  generateDropdownOptions_CountFormat(GatherPanel_Settings_SetTrackerCountFormat);
end

local function initDropdownOptions_TrackerProgressFormat(self)
  generateDropdownOptions_ProgressFormat(GatherPanel_Settings_SetTrackerProgressFormat);
end


local function initDropdownOptions_TrackerBarContext(self)
  local info = UIDropDownMenu_CreateInfo();
  info.text = L["UNTRACK"];
  info.func = trackItem;
  info.notCheckable = true;
  info.arg1 = self:GetParent().item;
  UIDropDownMenu_AddButton(info);
end


local function initDropdownOptions_GroupEdit(self)
  local info = UIDropDownMenu_CreateInfo();
  info.text = L["CHANGE_NAME"];
  info.func = group_ShowEditPopup;
  info.arg1 = self:GetParent().item;
  info.notCheckable = true;
  UIDropDownMenu_AddButton(info);
  info = UIDropDownMenu_CreateInfo();
  info.text = L["REMOVE_GROUP"];
  info.func = GatherPanel_Context_ItemDelete;
  info.notCheckable = true;
  info.arg1 = self:GetParent().itemKey;
  UIDropDownMenu_AddButton(info);
end


local function InitParentSelectionOptions_DetailFrame(self)
  local defaultGroupInfo = UIDropDownMenu_CreateInfo();
  defaultGroupInfo.text = defaultGroup.name;
  defaultGroupInfo.isNotRadio = false;
  defaultGroupInfo.func = SelectParentGroup;
  defaultGroupInfo.arg1 = 0;
  UIDropDownMenu_AddButton(defaultGroupInfo);
  local items = GatherPanel_GetItemList();
  for itemId, item in pairs(items) do
    local info = UIDropDownMenu_CreateInfo();
    if item.type == "GROUP" then
      info.text = item.name;
      info.isNotRadio = false;
      info.func = SelectParentGroup;
      info.arg1 = itemId;
      UIDropDownMenu_AddButton(info);
    end
  end
end


local function InitParentSelectionOptions_CreateFrame(self)
  local defaultGroupInfo = UIDropDownMenu_CreateInfo();
  defaultGroupInfo.text = defaultGroup.name;
  defaultGroupInfo.isNotRadio = false;
  defaultGroupInfo.func = SetParent;
  defaultGroupInfo.arg1 = 0;
  UIDropDownMenu_AddButton(defaultGroupInfo);
  local items = GatherPanel_GetItemList();
  for itemId, item in pairs(items) do
    local info = UIDropDownMenu_CreateInfo();
    if item.type == "GROUP" then
      info.text = item.name;
      info.isNotRadio = false;
      info.func = SetParent;
      info.arg1 = itemId;
      UIDropDownMenu_AddButton(info);
    end
  end
end


local function InitListOptions(self)
  local info = UIDropDownMenu_CreateInfo();
  info.keepShownOnClick = 1;

  info.text = L["COMBINED"];
  info.isNotRadio = false;
  info.func = SelectItemlist;
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
  PlaySound(SOUNDKIT.UI_PROFESSIONS_WINDOW_OPEN);
  GatherPanel_UpdateItems();
  GatherPanel_UpdatePanel();
end

function GatherPanel_OnHide()
  PlaySound(SOUNDKIT.UI_PROFESSIONS_WINDOW_CLOSE);
end

function GatherPanel_Tracker_OnLoad()
  SlashCmdList["GATHERPANEL_TRACKER"] = GatherPanel_ToggleTracker;
  SLASH_GATHERPANEL_TRACKER1 = "/gpt";
end

function GatherPanel_ToggleTracker()
  GATHERPANEL_SETTINGS.trackerVisible = not GATHERPANEL_SETTINGS.trackerVisible;
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

function GatherPanel_OnLoad()
  SlashCmdList["GATHERPANEL"] = function(msg)

    local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)");

    if cmd == "trackall" then
      GatherPanel_TrackAll();
    elseif cmd == "tracker" then
      GatherPanel_ToggleTracker();
    elseif cmd == nil then
      GatherPanel:SetShown(not GatherPanel:IsShown());
    else
      print("GatherPanel Chat Commands:");
      print("/gp - Open Gather Panel");
      print("/gp trackall - Track all items from the current item list");
      print("/gp tracker - Toggle Tracker");
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
  _G['ItemDetailDeleteButton']:SetText(L["REMOVE_FROM_LIST"]);

  PanelTemplates_SetNumTabs(_G['GatherPanel'], 3);
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

function GatherPanel_InitItem(item)
  local itemCount = 0;
  local locale = GetLocale();
  if item.updated == nil then
    item.updated = 0;
  end
  if item.itemName == nil or item.itemTexture == nil or item.itemQuality == nil or item.locale ~= locale then
    -- retry, sometimes heavy load
    item.itemName, _, item.itemQuality, _, _, _, _, _, _, item.itemTexture, _ = GetItemInfo(item.id);
    item.locale = locale;
  end
  local characterItemCount = 0;
  if IsAddOnLoaded("DataStore_Containers") then
    -- only load count from character who is owner of the list, i.e. what is this character missing
    realm, selectedCharacter = decodeItemListId(GATHERPANEL_ITEM_LIST_SELECTION);
    for characterName, character in pairs(DataStore:GetCharacters()) do
      if (characterName == selectedCharacter and characterName ~= UnitName("player")) then
        bagCount, bankCount, voidCount, reagentBankCount = DataStore:GetContainerItemCount(character, item.id);
        characterItemCount = bagCount + bankCount + voidCount + reagentBankCount;
      end
    end
  end

  if GATHERPANEL_SETTINGS.includeCurrentCharacter then
    characterItemCount = characterItemCount + GetItemCount(item.id, true)
  end

  if GATHERPANEL_SETTINGS.includeAllFromRealm then
    if IsAddOnLoaded("Altoholic") then
      local altoholic = _G["Altoholic"]
      item.itemCount = altoholic:GetItemCount(item.id)
    else
      if IsAddOnLoaded("DataStore_Containers") then
        for characterName, character in pairs(DataStore:GetCharacters()) do
          if (characterName ~= UnitName("player")) then
            bagCount, bankCount, voidCount, reagentBankCount = DataStore:GetContainerItemCount(character, item.id);
            itemCount = itemCount + bagCount + bankCount + voidCount + reagentBankCount;
          end
        end
      end
      item.itemCount = itemCount + characterItemCount
    end
  else
    item.itemCount = characterItemCount
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

function GatherPanel_UpdateItems(animate)
  if animate == nil then
    animate = true;
  end
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

local function renderItemBar(itemRow, item, level)

  itemRow.ItemName:SetText(item.itemName);
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
  if GATHERPANEL_PROGRESS_FORMAT.FILL_TO_GOAL == GATHERPANEL_SETTINGS_GLOBAL.panelProgressFormat then
    realGoal = item.goal;
    realPercentage = item.progressPercentage;
  elseif GATHERPANEL_PROGRESS_FORMAT.FILL_TO_MAXIMUM == GATHERPANEL_SETTINGS_GLOBAL.panelProgressFormat then
    realGoal = item.max;
    realPercentage = item.progressPercentageMax;
  end
  itemRow.ItemBar:SetValue(realPercentage);

  if (itemRow.hovered) then
    if GATHERPANEL_COUNT_FORMAT.PERCENT == GATHERPANEL_SETTINGS_GLOBAL.panelCountFormat
        or GATHERPANEL_COUNT_FORMAT.NONE == GATHERPANEL_SETTINGS_GLOBAL.panelCountFormat then
      itemRow.ItemBar.Percentage:SetText(item.itemCount .. "/" .. realGoal);
    elseif GATHERPANEL_COUNT_FORMAT.ABSOLUTE == GATHERPANEL_SETTINGS_GLOBAL.panelCountFormat then
      if (realPercentage >= 1) then
        itemRow.ItemBar.Percentage:SetText(L["FULLY_STOCKED"]);
      else
        itemRow.ItemBar.Percentage:SetFormattedText(PERCENTAGE_STRING, realPercentage * 100);
      end
    end
    -- Update tooltip when scrolled
    GameTooltip:SetItemByID(item.id);
  else
    if GATHERPANEL_COUNT_FORMAT.ABSOLUTE == GATHERPANEL_SETTINGS_GLOBAL.panelCountFormat then
      itemRow.ItemBar.Percentage:SetText(item.itemCount .. "/" .. realGoal);
    elseif GATHERPANEL_COUNT_FORMAT.PERCENT == GATHERPANEL_SETTINGS_GLOBAL.panelCountFormat then
      if (realPercentage >= 1) then
        itemRow.ItemBar.Percentage:SetText(L["FULLY_STOCKED"]);
      else
        itemRow.ItemBar.Percentage:SetFormattedText(PERCENTAGE_STRING, realPercentage * 100);
      end
    elseif GATHERPANEL_COUNT_FORMAT.NONE == GATHERPANEL_SETTINGS_GLOBAL.panelCountFormat then
      itemRow.ItemBar.Percentage:SetText("");
    end
  end

  itemRow.Background:Show();

  itemRow:SetPoint("LEFT", "GatherPanelInset", "LEFT", 46 * level, 0);

  itemRow:Show();
end

function GatherPanel_UpdatePanel(initDropdowns)
  _G['GatherPanel_Panel3'].Inset.PanelOptions.ShowOfflineButton:SetChecked(GATHERPANEL_SETTINGS.includeAllFromRealm);
  _G['GatherPanel_Panel3'].Inset.PanelOptions.IncludeCurrentCharacterButton:SetChecked(GATHERPANEL_SETTINGS.includeCurrentCharacter);
  _G['GatherPanel_Panel3'].Inset.TrackerOptions.ShowTrackerButton:SetChecked(GATHERPANEL_SETTINGS.trackerVisible);
  local numItems = getItemlistLength();
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
      if i+1 < #sortedHierarchy then
        local nextElement = elements[sortedHierarchy[i+1].id];
        if nextElement and (nextElement.type ~= "GROUP" and nextElement.parent == 0) then
          processedRows = processedRows + 1;
          if (processedRows > itemOffset and renderedRows < GATHERPANEL_NUM_ITEMS_DISPLAYED) then
            local itemRow = _G["GatherBar" .. renderedRows+1];
            local itemBar = _G["GatherBar" .. renderedRows+1 .. "ItemBar"];
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
            local itemBar = _G["GatherBar" .. renderedRows+1 .. "ItemBar"];
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
            local itemBar = _G["GatherBar" .. renderedRows+1 .. "ItemBar"];
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

end


function GatherPanel_UpdatePanelItems()
  GatherPanel_UpdatePanel(true);
end


function GatherPanel_Tracker_Update()
  if GATHERPANEL_SETTINGS.trackerVisible and GATHERPANEL_NUM_TRACKERS_ENABLED > 0 then
    _G["GatherPanel_Tracker"]:Show();
  else
    _G["GatherPanel_Tracker"]:Hide();
  end
end

function GatherPanel_Tracker_UpdateItem(item, animate)
  local tracker = _G["GatherPanel_Tracker" .. item.tracker];

  -- Bar Color
  if (item.goalType == 'min') then
    tracker.Bar:SetStatusBarAtlas("ui-frame-bar-fill-yellow");
    tracker.Bar.BarBG:SetVertexColor(0.9, 0.7, 0);
  end
  if (item.goalType == 'max') then
    if (item.goal <= item.itemCount) then
      tracker.Bar:SetStatusBarAtlas("ui-frame-bar-fill-green");
      tracker.Bar.BarBG:SetVertexColor(0, 0.6, 0.1);
    else
      tracker.Bar:SetStatusBarAtlas("ui-frame-bar-fill-blue");
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
  if (GATHERPANEL_PROGRESS_FORMAT.FILL_TO_MAXIMUM == GATHERPANEL_SETTINGS_GLOBAL.trackerProgressFormat) 
      and (item.min > item.itemCount and item.min ~= item.max) then
    tracker.Bar.Checkpoint:Show()
    tracker.Bar.Checkpoint:SetPoint("CENTER", tracker.Bar, "LEFT", item.min/item.max * tracker.Bar:GetWidth(), -1.5);
  else
    tracker.Bar.Checkpoint:Hide()
  end

  -- Progress
  local realGoal, realPercentage;
  if GATHERPANEL_PROGRESS_FORMAT.FILL_TO_GOAL == GATHERPANEL_SETTINGS_GLOBAL.trackerProgressFormat then
    realGoal = item.goal;
    realPercentage = item.progressPercentage;
  elseif GATHERPANEL_PROGRESS_FORMAT.FILL_TO_MAXIMUM == GATHERPANEL_SETTINGS_GLOBAL.trackerProgressFormat then
    realGoal = item.max;
    realPercentage = item.progressPercentageMax;
  end
  if (tracker.AnimValue and animate) then
    local delta = realPercentage * 100 - tracker.AnimValue;
    if tracker.AnimValue < 100 and realPercentage >= 1.0 then
      PlaySound(SOUNDKIT.IG_QUEST_LIST_COMPLETE)
    end
    GatherPanel_Tracker_PlayFlareAnim(tracker, delta, realPercentage, sparkHorizontalOffset);
  end
  tracker.AnimValue = realPercentage * 100;
  tracker.Bar:SetValue(realPercentage * 100);

  -- Label
  if GATHERPANEL_COUNT_FORMAT.ABSOLUTE == GATHERPANEL_SETTINGS_GLOBAL.trackerCountFormat then
    tracker.Bar.Label:SetText(item.itemCount .. "/" .. realGoal);
  elseif GATHERPANEL_COUNT_FORMAT.PERCENT == GATHERPANEL_SETTINGS_GLOBAL.trackerCountFormat then
    if (realPercentage >= 1) then
      tracker.Bar.Label:SetText(L["FULLY_STOCKED"]);
    else
      tracker.Bar.Label:SetFormattedText(PERCENTAGE_STRING, realPercentage * 100);
    end
  elseif GATHERPANEL_COUNT_FORMAT.NONE == GATHERPANEL_SETTINGS_GLOBAL.trackerCountFormat then
    tracker.Bar.Label:SetText("");
  end
end

function GatherPanel_Tracker_PlayFlareAnim(progressBar, delta, newPercentage, sparkHorizontalOffset)
  if (progressBar.AnimValue >= 100 or delta <= 0) then
    return;
  end

  local deltaWidth = progressBar.Bar:GetWidth() * delta;

  animOffset = animOffset or 14;
  local offset = progressBar.Bar:GetWidth() * newPercentage - animOffset;

  local prefix = overridePrefix or "";
  if (delta < 5 and not overridePrefix) then
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

function Migrate_2_0_0()

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

function Migrate_2_1_0()
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

local function doMigrations()
  if GATHERPANEL_VERSION == nil then
    return
  end

  if GATHERPANEL_VERSION.major >= 3 then
    return;
  end
  
  if GATHERPANEL_VERSION.major >= 2 then
    
    if GATHERPANEL_VERSION.major == 2 and GATHERPANEL_VERSION.minor >= 1 then
      return;
    end
    Migrate_2_1_0();

    return;  
  end

  Migrate_2_0_0();
end

function GatherPanel_OnEvent(event)
  if event == 'ADDON_LOADED' and not GATHERPANEL_LOADED then
    GATHERPANEL_LOADED = true;

    doMigrations();
    -- save current data version
    local version = GetAddOnMetadata("GatherPanel", "VERSION");
    if version == nil then
      version = "0.0.0"
    end
    local major, minor, patch = string.match(version, "(%d+)%.(%d+).(%d+)");
    GATHERPANEL_VERSION.major = tonumber(major);
    GATHERPANEL_VERSION.minor = tonumber(minor);
    GATHERPANEL_VERSION.patch = tonumber(patch);

    SelectItemlist(nil, GATHERPANEL_ITEM_LIST_SELECTION);
    UIDropDownMenu_Initialize(GatherPanel_ItemlistSelection, InitListOptions);
    UIDropDownMenu_Initialize(ItemDetailFrame.ParentDropDown, InitParentSelectionOptions_DetailFrame);
    UIDropDownMenu_Initialize(GatherPanel_Panel2.Inset.ParentDropDown, InitParentSelectionOptions_CreateFrame);
    UIDropDownMenu_SetText(GatherPanel_Panel2.Inset.ParentDropDown, defaultGroup.name);
    UIDropDownMenu_Initialize(GatherPanel_Panel3.Inset.PanelOptions.CountFormat, initDropdownOptions_PanelCountFormat);
    UIDropDownMenu_SetText(GatherPanel_Panel3.Inset.PanelOptions.CountFormat, getOptionName(GATHERPANEL_COUNT_FORMAT, GATHERPANEL_SETTINGS_GLOBAL.panelCountFormat, "COUNT_FORMAT"));
    UIDropDownMenu_Initialize(GatherPanel_Panel3.Inset.PanelOptions.ProgressFormat, initDropdownOptions_PanelProgressFormat);
    UIDropDownMenu_SetWidth(GatherPanel_Panel3.Inset.PanelOptions.ProgressFormat, 180);
    UIDropDownMenu_SetText(GatherPanel_Panel3.Inset.PanelOptions.ProgressFormat, getOptionName(GATHERPANEL_PROGRESS_FORMAT, GATHERPANEL_SETTINGS_GLOBAL.panelProgressFormat, "PROGRESS_FORMAT"));
    UIDropDownMenu_Initialize(GatherPanel_Panel3.Inset.TrackerOptions.CountFormat, initDropdownOptions_TrackerCountFormat);
    UIDropDownMenu_SetText(GatherPanel_Panel3.Inset.TrackerOptions.CountFormat, getOptionName(GATHERPANEL_COUNT_FORMAT, GATHERPANEL_SETTINGS_GLOBAL.trackerCountFormat, "COUNT_FORMAT"));
    UIDropDownMenu_Initialize(GatherPanel_Panel3.Inset.TrackerOptions.ProgressFormat, initDropdownOptions_TrackerProgressFormat);
    UIDropDownMenu_SetWidth(GatherPanel_Panel3.Inset.TrackerOptions.ProgressFormat, 180);
    UIDropDownMenu_SetText(GatherPanel_Panel3.Inset.TrackerOptions.ProgressFormat, getOptionName(GATHERPANEL_PROGRESS_FORMAT, GATHERPANEL_SETTINGS_GLOBAL.trackerProgressFormat, "PROGRESS_FORMAT"));

    -- Run Tracker Update once addon loaded saved variable
    GatherPanel_Tracker_Update();
    GatherPanel_UpdatePanel(true);
  end

  if GATHERPANEL_LOADED == true then
    -- Run Item and Bar Updates every event (as most commonly the character received a new item)
    GatherPanel_UpdateItems();
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

local function item_ExpandOrCollapse(item)
  if item == nil then
    -- Default category does not carry a real data set and thus get not assigned.
    GATHERPANEL_DEFAULT_GROUP_COLLAPSED = not GATHERPANEL_DEFAULT_GROUP_COLLAPSED;
  else
    item.isCollapsed = not item.isCollapsed
  end
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
      item_ExpandOrCollapse(nil);
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
    _G['ItemName']:SetText(frame.item.itemName);
    frame.MinQuantityInput:SetText(frame.item.min);
    frame.MaxQuantityInput:SetText(frame.item.max);
    local items = getItemlist();
    local parent = items[frame.item.parent];
    if parent == nil then
      UIDropDownMenu_SetText(ItemDetailFrame.ParentDropDown, defaultGroup.name);
    else
      UIDropDownMenu_SetText(ItemDetailFrame.ParentDropDown, parent.name);
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
  for itemId, item in pairs(items) do
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
      GatherPanel_Tracker_UpdateItem(item)
    end
  end
  GatherPanel_Tracker_Update();
end

function GatherPanel_TrackItem(item)
  if (item.tracked) then
    if item.itemCount < item.max then  
      PlaySound(SOUNDKIT.IG_QUEST_LOG_ABANDON_QUEST);
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
    PlaySound(618);
    GatherPanel_CreateTrackerForItem(item)
  end
  GatherPanel_UpdateItems(false);
  GatherPanel_UpdatePanel();
  GatherPanel_ReloadTracker();
end

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
  GATHERPANEL_SETTINGS.includeAllFromRealm = checked;
  GatherPanel_UpdateItems();
  GatherPanel_UpdatePanel();
end

function GatherPanel_SetIncludeCurrentCharacter(checked)
  GATHERPANEL_SETTINGS.includeCurrentCharacter = checked;
  GatherPanel_UpdateItems();
  GatherPanel_UpdatePanel();
end

function GatherPanel_SetPanel(id)
  _G['GatherPanel_Panel' .. _G['GatherPanel'].selectedTab]:Hide();
  _G['GatherPanel_Panel' .. id]:Show();
end

function GatherPanel_Tab_OnClick(tab)
  GatherPanel_SetPanel(tab:GetID());
  PanelTemplates_SetTab(_G['GatherPanel'], tab:GetID());
  PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
end

function GatherPanel_ItemDetailUpdateQuantity(frame)
  local item = frame:GetParent().item;
  item.min = tonumber(frame:GetParent().MinQuantityInput:GetText());
  item.max = tonumber(frame:GetParent().MaxQuantityInput:GetText());
  GatherPanel_UpdateItems();
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
  GatherPanel_UpdateItems();
  GatherPanel_UpdatePanel();
  GatherPanel_TrackItem(items[itemID]);
  frame:GetParent().CreateButton:Disable();
  frame:GetParent().ItemIdInput:SetText('');
  frame:GetParent().MinQuantityInput:SetText('');
  frame:GetParent().MaxQuantityInput:SetText('');
  
  frame:GetParent().ItemButton.Icon:SetTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot");
  frame:GetParent().ItemButton.Name:SetText('');
  frame:GetParent().LabelInstructions:SetText(L["DRAG_ITEM_OR_SET_ITEM_ID"]);
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
  frame:GetParent().LabelInstructions:SetText(L["DRAG_ITEM_OR_SET_ITEM_ID"]);
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
      frame:GetParent().LabelInstructions:SetText(L["ITEM_ALREADY_ON_LIST"]);
      frame:GetParent().CreateButton:Disable();
      frame:GetParent().MinQuantityInput:Disable();
      frame:GetParent().MinQuantityInput.Label:SetTextColor(0.6, 0.6, 0.6);
      frame:GetParent().MaxQuantityInput:Disable();
      frame:GetParent().MaxQuantityInput.Label:SetTextColor(0.6, 0.6, 0.6);
    else
      frame:GetParent().LabelInstructions:SetTextColor(1, 1, 1);
      frame:GetParent().LabelInstructions:SetText(L["DEFINE_STOCK_GOALS"]);
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
  frame:GetParent().LabelInstructions:SetText(L["DRAG_ITEM_OR_SET_ITEM_ID"]);
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
        frame:GetParent().LabelInstructions:SetText(L["ITEM_ALREADY_ON_LIST"]);
        frame:GetParent().CreateButton:Disable();
        frame:GetParent().MinQuantityInput:Disable();
        frame:GetParent().MinQuantityInput.Label:SetTextColor(0.6, 0.6, 0.6);
        frame:GetParent().MaxQuantityInput:Disable();
        frame:GetParent().MaxQuantityInput.Label:SetTextColor(0.6, 0.6, 0.6);
      else
        frame:GetParent().LabelInstructions:SetTextColor(1, 1, 1);
        frame:GetParent().LabelInstructions:SetText(L["DEFINE_STOCK_GOALS"]);
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
  frame:GetParent().ItemButton.Name:SetText(L["ITEM_ID_INVALID"]);
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
  if GATHERPANEL_PROGRESS_FORMAT.FILL_TO_GOAL == GATHERPANEL_SETTINGS_GLOBAL.trackerProgressFormat then
    realGoal = self.item.goal;
    realPercentage = self.item.progressPercentage;
  elseif GATHERPANEL_PROGRESS_FORMAT.FILL_TO_MAXIMUM == GATHERPANEL_SETTINGS_GLOBAL.trackerProgressFormat then
    realGoal = self.item.max;
    realPercentage = self.item.progressPercentageMax;
  end
  if GATHERPANEL_COUNT_FORMAT.PERCENT == GATHERPANEL_SETTINGS_GLOBAL.trackerCountFormat 
      or GATHERPANEL_COUNT_FORMAT.NONE == GATHERPANEL_SETTINGS_GLOBAL.trackerCountFormat then
    self.Bar.Label:SetText(self.item.itemCount .. "/" .. realGoal);
  elseif GATHERPANEL_COUNT_FORMAT.ABSOLUTE == GATHERPANEL_SETTINGS_GLOBAL.trackerCountFormat then
    if (realPercentage >= 1) then
      self.Bar.Label:SetText(L["FULLY_STOCKED"]);
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
  if GATHERPANEL_PROGRESS_FORMAT.FILL_TO_GOAL == GATHERPANEL_SETTINGS_GLOBAL.trackerProgressFormat then
    realGoal = self.item.goal;
    realPercentage = self.item.progressPercentage;
  elseif GATHERPANEL_PROGRESS_FORMAT.FILL_TO_MAXIMUM == GATHERPANEL_SETTINGS_GLOBAL.trackerProgressFormat then
    realGoal = self.item.max;
    realPercentage = self.item.progressPercentageMax;
  end
  if GATHERPANEL_COUNT_FORMAT.ABSOLUTE == GATHERPANEL_SETTINGS_GLOBAL.trackerCountFormat then
    self.Bar.Label:SetText(self.item.itemCount .. "/" .. realGoal);
  elseif GATHERPANEL_COUNT_FORMAT.PERCENT == GATHERPANEL_SETTINGS_GLOBAL.trackerCountFormat then
    if (realPercentage >= 1) then
      self.Bar.Label:SetText(L["FULLY_STOCKED"]);
    else
      self.Bar.Label:SetFormattedText(PERCENTAGE_STRING, realPercentage * 100);
    end
  elseif GATHERPANEL_COUNT_FORMAT.NONE == GATHERPANEL_SETTINGS_GLOBAL.trackerCountFormat then
    self.Bar.Label:SetText("");
  end
  GameTooltip_Hide();
end


function GatherPanel_UpdateMinimap()
  if GatherPanel.draggingMinimapButton == 1 then
    local xpos,ypos = GetCursorPosition();
    local xmin,ymin = Minimap:GetLeft(), Minimap:GetBottom();

    xpos = xmin-xpos/Minimap:GetEffectiveScale()+70;
    ypos = ypos/Minimap:GetEffectiveScale()-ymin-70;

    local angle = math.deg(math.atan2(ypos,xpos));

    GatherPanelMinimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 53-(cos(angle)*81), -55+(sin(angle)*81));
  end
end

function GatherPanel_ResetMinimapButtonPosition()
  if GATHERPANEL_SETTINGS.minimapPosition == nil then
    GATHERPANEL_SETTINGS.minimapPosition = { -13, -100 }
  end
  GatherPanelMinimapButton:ClearAllPoints()
  GatherPanelMinimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", GATHERPANEL_SETTINGS.minimapPosition[1], GATHERPANEL_SETTINGS.minimapPosition[2])
end