GATHERPANEL_ITEMBAR_HEIGHT = 26;
NUM_ITEMS_DISPLAYED = 15;
NUM_TRACKERS_ENABLED = 0;
NUM_TRACKERS_CREATED = 1;
GATHERPANEL_ALL_CHARACTERS = false;
GATHERPANEL_INCLUDE_CURRENT_CHARACTER = true;
GATHERPANEL_ALL_CHARACTERS_ITEMS = false;
GATHERPANEL_LOADED = false;
GATHERPANEL_TRACKER_VISIBLE = true;

GATHERPANEL_DEFAULT_GROUP_COLLAPSED = false;

GATHERPANEL_ITEMLISTS = {};
GATHERPANEL_ITEM_LIST_SELECTION = nil;

GATHERPANEL_VERSION = {
  ["major"] = 2,
  ["minor"] = 0,
  ["patch"] = 0 
}

local sortedHierarchy = {};
local defaultGroup = {
  name = "Uncategorized",
  type = "GROUP",
  parent = nil,
  isCollapsed = GATHERPANEL_DEFAULT_GROUP_COLLAPSED
};

local function GetItemlistId(realm, characterName)
  return realm .. ":" .. characterName;
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

function GatherPanel_OnShow()
  PlaySound(SOUNDKIT.UI_PROFESSIONS_WINDOW_OPEN);
  GatherPanel_UpdateItems();
  GatherPanel_Update();
end

function GatherPanel_OnHide()
  PlaySound(SOUNDKIT.UI_PROFESSIONS_WINDOW_CLOSE);
end

function GatherPanel_Tracker_OnLoad()
  SlashCmdList["GATHERPANEL_TRACKER"] = GatherPanel_ToggleTracker;
  SLASH_GATHERPANEL_TRACKER1 = "/gpt";
end

function GatherPanel_ToggleTracker()
  GATHERPANEL_TRACKER_VISIBLE = not GATHERPANEL_TRACKER_VISIBLE;
  -- Hide Tracker
  GatherPanel_Tracker_Update();
  -- Check UI Toggle
  GatherPanel_Update();
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
  for i = 1, NUM_ITEMS_DISPLAYED, 1 do
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
  _G['ItemDetailDeleteButton']:SetText('Remove');
  _G['ItemDetailUpdateButton']:SetText('Update');
  _G['ItemDetailUpdateButton']:Disable();

  PanelTemplates_SetNumTabs(_G['GatherPanel'], 2);
  PanelTemplates_SetTab(_G['GatherPanel'], 1);
end

function GatherPanel_InitItems()
  for itemId, item in pairs(getItemlist()) do
    if item.type == "ITEM" then
      item.itemName, _, _, _, _, _, _, _, _, item.itemTexture, _ = GetItemInfo(item.id);
      item.tracked = false;
      item.hovered = false;
    end
  end
end

function GatherPanel_InitializeSortedItemList()
  --[[
    Items can have parents (which are categories or items, e.g. for recipe tracking).
    Rearrange items into the groups in a linear fashion, i.e. span up a tree.
    ]] --
  local items = getItemlist();
  sortedHierarchy = {};
  local linearizedHierarchy = flatToHierarchy(items, "parent");
  for _, element in ipairs(linearizedHierarchy) do
    table.insert(sortedHierarchy, element);
  end
end

function GatherPanel_UpdateItems()
  local items = getItemlist();
  for i, item in pairs(items) do
    if item.type == "ITEM" then
      local itemCount = 0;
      if item.updated == nil then
        item.updated = 0;
      end
      if item.itemName == nil or item.itlemTexture == nil or item.updated < time() + 300 then
        -- retry, sometimes heavy load
        item.itemName, _, _, _, _, _, _, _, _, item.itemTexture, _ = GetItemInfo(item.id);
        item.updated = time()
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

      if GATHERPANEL_INCLUDE_CURRENT_CHARACTER then
        characterItemCount = characterItemCount + GetItemCount(item.id, true)
      end

      if GATHERPANEL_ALL_CHARACTERS then
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
      item.progressPercentageInteger = math.floor(item.progressPercentage * 100);
      if (item.tracker) then
        GatherPanel_Tracker_UpdateItem(item);
      end
    end
  end
end

local function renderItemGroup(itemRow, group, level)

  itemRow.ItemName:SetText(group.name);
  itemRow.ItemName:SetPoint("LEFT", itemRow.ExpandOrCollapseButton, "RIGHT", 10, 0);
  itemRow.ItemName:SetPoint("RIGHT", itemRow, "RIGHT", -3, 0);
  itemRow.ItemName:SetFontObject(GameFontNormalLeft);

  itemRow.ExpandOrCollapseButton:Show();
  if group.isCollapsed then
    itemRow.ExpandOrCollapseButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
  else
    itemRow.ExpandOrCollapseButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up");
  end

  itemRow.ItemBar:Hide();
  itemRow.itemKey = nil;

  itemRow.Background:Hide();

  itemRow:SetPoint("LEFT", "GatherPanelInset", "LEFT", 34 * level, 0);

  itemRow:Show();

end

local function renderItemBar(itemRow, item, level)

  itemRow.ItemName:SetText(item.itemName);
  itemRow.ItemName:SetPoint("LEFT", itemRow, "LEFT", 10, 0);
  itemRow.ItemName:SetPoint("RIGHT", itemRow.ItemBar, "LEFT", -3, 0);
  itemRow.ItemName:SetFontObject(GameFontHighlightSmall);

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

  if (itemRow.hovered) then
    itemRow.ItemBar.Percentage:SetText(item.itemCount .. "/" .. item.goal);
    -- Update tooltip when scrolled
    GameTooltip:SetItemByID(item.id);
  else
    if (item.progressPercentage >= 1) then
      itemRow.ItemBar.Percentage:SetText("Fully Stocked");
    else
      itemRow.ItemBar.Percentage:SetFormattedText(PERCENTAGE_STRING, item.progressPercentage * 100);
    end
  end
  itemRow.ItemBar:SetValue(item.progressPercentage);

  itemRow.Background:Show();

  itemRow:SetPoint("LEFT", "GatherPanelInset", "LEFT", 34 * level, 0);

  itemRow:Show();
end

function GatherPanel_Update()
  _G['GatherPanel_Panel1'].ShowOfflineButton:SetChecked(GATHERPANEL_ALL_CHARACTERS);
  _G['GatherPanel_Panel1'].IncludeCurrentCharacterButton:SetChecked(GATHERPANEL_INCLUDE_CURRENT_CHARACTER);
  _G['GatherPanel_Panel2'].ShowTrackerButton:SetChecked(GATHERPANEL_TRACKER_VISIBLE);
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
      processedRows = processedRows + 1;
      if (processedRows > itemOffset and renderedRows < NUM_ITEMS_DISPLAYED) then
        local itemRow = _G["GatherBar" .. renderedRows+1];
        local itemBar = _G["GatherBar" .. renderedRows+1 .. "ItemBar"];
        renderItemGroup(itemRow, defaultGroup, level);
        renderedRows = renderedRows + 1;
        itemRow:Show();
        itemRow.item = nil;
        itemRow.itemKey = nil;
      end
      if defaultGroup.isCollapsed then
        collapsedLevel = 0;
      else
        collapsedLevel = 999;
      end
    else
      if element.type == "GROUP" then
        if collapsedLevel >= level then
          processedRows = processedRows + 1;
          if (processedRows > itemOffset and renderedRows < NUM_ITEMS_DISPLAYED) then
            local itemRow = _G["GatherBar" .. renderedRows+1];
            local itemBar = _G["GatherBar" .. renderedRows+1 .. "ItemBar"];
            itemRow.item = element;
            itemRow.itemKey = elementKey;
            renderItemGroup(itemRow, element, level);
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
          if (processedRows > itemOffset and renderedRows < NUM_ITEMS_DISPLAYED) then
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

  for i = renderedRows+1, NUM_ITEMS_DISPLAYED, 1 do
    local itemRow = _G["GatherBar" .. i];
    itemRow:Hide();
  end

  if (not FauxScrollFrame_Update(GatherFrameScrollFrame, processedRows, NUM_ITEMS_DISPLAYED, GATHERPANEL_ITEMBAR_HEIGHT)) then
    GatherFrameScrollFrameScrollBar:SetValue(0);
  end

end

function GatherPanel_Tracker_Update()
  if GATHERPANEL_TRACKER_VISIBLE then
    _G["GatherPanel_Tracker"]:Show();
  else
    _G["GatherPanel_Tracker"]:Hide();
  end
end

function GatherPanel_Tracker_UpdateItem(item)
  local tracker = _G["GatherPanel_Tracker" .. item.tracker];
  if (item.goalType == 'min') then
    tracker.Bar:SetStatusBarColor(0.9, 0.7, 0);
    tracker.Bar.BarBG:SetVertexColor(0.9, 0.7, 0);
  end
  if (item.goalType == 'max') then
    if (item.goal <= item.itemCount) then
      tracker.Bar:SetStatusBarColor(0, 0.6, 0.1);
      tracker.Bar.BarBG:SetVertexColor(0, 0.6, 0.1);
    else
      tracker.Bar:SetStatusBarColor(0.26, 0.42, 1);
      tracker.Bar.BarBG:SetVertexColor(0.26, 0.42, 1);
    end
  end
  if (item.goal <= item.itemCount) then
    tracker.Bar.CheckMarkTexture:Show();
  else
    tracker.Bar.CheckMarkTexture:Hide();
  end
  if (tracker.AnimValue) then
    local delta = item.progressPercentage * 100 - tracker.AnimValue;
    GatherPanel_Tracker_PlayFlareAnim(tracker, delta, sparkHorizontalOffset);
  end
  tracker.AnimValue = item.progressPercentage * 100;
  tracker.Bar:SetValue(item.progressPercentage * 100);
  tracker.Bar.Label:SetFormattedText(PERCENTAGE_STRING, item.progressPercentage * 100);
end

function GatherPanel_Tracker_PlayFlareAnim(progressBar, delta, sparkHorizontalOffset)
  if (progressBar.AnimValue >= 100 or delta == 0) then
    return;
  end

  animOffset = animOffset or 12;
  local offset = progressBar.Bar:GetWidth() * (progressBar.AnimValue / 100) - animOffset;

  local prefix = overridePrefix or "";
  if (delta < 10 and not overridePrefix) then
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
  GatherPanel_ItemDetailUpdateButton_Update();
  GatherPanel_UpdateItems();
  GatherPanel_Update();
end

local function SelectItemlist(self, itemListId)
  GATHERPANEL_ITEM_LIST_SELECTION = itemListId;

  -- Check if id exists. gets reset if not.
  setItemList();

  if GATHERPANEL_ITEM_LIST_SELECTION == GetItemlistId("X-Internal", "Combined") then
    -- disable all item list manipulations
    GatherPanel_NewItem_CreateButton:Disable();
    ItemDetailMin:Disable();
    ItemDetailMax:Disable();
    ItemDetailDeleteButton:Disable()
  else
    GatherPanel_NewItem_CreateButton:Enable();
    ItemDetailMin:Enable();
    ItemDetailMax:Enable();
    ItemDetailDeleteButton:Enable();
  end
  realm, characterName = decodeItemListId(GATHERPANEL_ITEM_LIST_SELECTION);
  UIDropDownMenu_SetText(GatherPanel_ItemlistSelection, characterName);
  CloseDropDownMenus();
  GatherPanel_InitializeSortedItemList();
  GatherPanel_ReloadTracker();
  GatherPanel_UpdateItems();
  GatherPanel_Update();
end


local function InitParentSelectionOptions(self)
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


local function InitListOptions(self)
  local info = UIDropDownMenu_CreateInfo();
  info.keepShownOnClick = 1;

  info.text = "Combined";
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

  if #GATHERPANEL_ITEMS_CHARACTER > 0 then
    for i, item in ipairs(GATHERPANEL_ITEMS_CHARACTER) do
      GATHERPANEL_ITEMLISTS[realm][characterName][item["id"]] = {};
      for k, v in pairs(item) do
        GATHERPANEL_ITEMLISTS[realm][characterName][item["id"]][k] = v;
      end
    end
  end

  if #GATHERPANEL_ITEMS > 0 then
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

    SelectItemlist(GATHERPANEL_ITEM_LIST_SELECTION);
    UIDropDownMenu_Initialize(GatherPanel_ItemlistSelection, InitListOptions);
    UIDropDownMenu_Initialize(GatherPanel_ItemDetails_ParentSelection, InitParentSelectionOptions);
    GatherPanel_InitItems();

    GATHERPANEL_LOADED = true;
    -- Run Tracker Update once addon loaded saved variable
    GatherPanel_Tracker_Update();
  end

  if GATHERPANEL_LOADED == true then
    -- Run Item and Bar Updates every event (as most commonly the character received a new item)
    GatherPanel_UpdateItems();
    GatherPanel_Update();
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
  GatherPanel_Update();
end

function GatherPanel_Bar_OnLeave(frame)
  frame.hovered = false;
  GameTooltip_Hide();
  GatherPanel_Update();
end

function GatherPanel_Bar_OnClick(frame)
  if frame.item and frame.item.type == "ITEM" then
    local item = frame.item;
    _G['ItemDetailFrame'].item = item;
    GatherPanel_UpdateItemDetails();
    _G['ItemDetailFrame']:Show();
  elseif frame.item and frame.item.type == "GROUP" then
    if frame.itemKey ~= 0 then
      StaticPopup_Show("GATHERPANEL_GROUP_EDIT_NAME", frame.item.name, nil, frame.item);
    end
  end
end

function GatherPanel_Bar_ExpandOrCollapse_OnClick(self)
  if self:GetParent().item == nil then
    -- Default category does not carry a real data set and thus get not assigned.
    GATHERPANEL_DEFAULT_GROUP_COLLAPSED = not GATHERPANEL_DEFAULT_GROUP_COLLAPSED;
  else
    self:GetParent().item.isCollapsed = not self:GetParent().item.isCollapsed
  end
  GatherPanel_Update();
end

function GatherPanel_UpdateItemDetails()
  local frame = _G['ItemDetailFrame'];
  _G['ItemDetailTrackerCheckBox']:SetChecked(frame.item.tracked);
  _G['ItemName']:SetText(frame.item.itemName);
  _G['ItemDetailMin']:SetText(frame.item.min);
  _G['ItemDetailMax']:SetText(frame.item.max);
  local items = getItemlist();
  local parent = items[frame.item.parent];
  if parent == nil then
    UIDropDownMenu_SetText(GatherPanel_ItemDetails_ParentSelection, defaultGroup.name);
  else
    UIDropDownMenu_SetText(GatherPanel_ItemDetails_ParentSelection, parent.name);
  end
end

function GatherPanel_ReloadTracker()
  -- Remove all trackers
  for i = 1, NUM_TRACKERS_CREATED, 1 do
    _G["GatherPanel_Tracker" .. i].item = nil;
    _G["GatherPanel_Tracker" .. i]:Hide();
  end
  NUM_TRACKERS_ENABLED = 0;

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
      GatherPanel_CreateTrackerForItem(item)
      GatherPanel_Tracker_UpdateItem(item)
    end
  end
end

function GatherPanel_TrackItem(item)
  if (item.tracked) then
    item.tracked = false;
    item.tracker = nil;
    -- Rearrange trackers
    local newTracker = 0;
    for i, item in pairs(getItemlist()) do
      if (item.tracker) then
        newTracker = newTracker + 1;
        item.tracker = newTracker;
        _G["GatherPanel_Tracker" .. newTracker].icon = item.itemTexture;
        _G["GatherPanel_Tracker" .. newTracker].item = item;
        _G["GatherPanel_Tracker" .. newTracker].Bar.Icon:SetTexture(item.itemTexture);
        if (item.goal <= item.itemCount) then
          _G["GatherPanel_Tracker" .. newTracker].Bar.CheckMarkTexture:Show();
        else
          _G["GatherPanel_Tracker" .. newTracker].Bar.CheckMarkTexture:Hide();
        end
      end
    end
    _G["GatherPanel_Tracker" .. NUM_TRACKERS_ENABLED]:Hide();
    NUM_TRACKERS_ENABLED = NUM_TRACKERS_ENABLED - 1;
  else
    GatherPanel_CreateTrackerForItem(item)
  end
  GatherPanel_UpdateItems();
  GatherPanel_Update();
end

function GatherPanel_CreateTrackerForItem(item)
  -- Enable Tracker
  if (NUM_TRACKERS_ENABLED == NUM_TRACKERS_CREATED) then
    local tracker = CreateFrame("Frame", "GatherPanel_Tracker" .. NUM_TRACKERS_CREATED + 1, _G["GatherPanel_Tracker"],
        "GatherPanel_Tracker_Template");
    tracker:SetPoint("TOPLEFT", "GatherPanel_Tracker" .. NUM_TRACKERS_CREATED, "BOTTOMLEFT", 0, 5);
    tracker.animValue = nil;
    NUM_TRACKERS_CREATED = NUM_TRACKERS_CREATED + 1;
  end
  NUM_TRACKERS_ENABLED = NUM_TRACKERS_ENABLED + 1;
  item.tracker = NUM_TRACKERS_ENABLED;
  _G["GatherPanel_Tracker" .. item.tracker].icon = item.itemTexture;
  _G["GatherPanel_Tracker" .. item.tracker].item = item;
  _G["GatherPanel_Tracker" .. item.tracker].Bar.Icon:SetTexture(item.itemTexture);
  if (item.goal <= item.itemCount) then
    _G["GatherPanel_Tracker" .. item.tracker].Bar.CheckMarkTexture:Show();
  else
    _G["GatherPanel_Tracker" .. item.tracker].Bar.CheckMarkTexture:Hide();
  end
  _G["GatherPanel_Tracker" .. item.tracker]:Show();
  item.tracked = true;
end

function GatherPanel_SetAllCharacters(checked)
  GATHERPANEL_ALL_CHARACTERS = checked;
  GatherPanel_UpdateItems();
  GatherPanel_Update();
end

function GatherPanel_SetIncludeCurrentCharacter(checked)
  GATHERPANEL_INCLUDE_CURRENT_CHARACTER = checked;
  GatherPanel_UpdateItems();
  GatherPanel_Update();
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

function GatherPanel_ItemDetailUpdateButton_OnClick(frame)
  local item = frame:GetParent().item;
  item.min = tonumber(_G['ItemDetailMin']:GetText());
  item.max = tonumber(_G['ItemDetailMax']:GetText());
  GatherPanel_ItemDetailUpdateButton_Update();
  GatherPanel_UpdateItems();
  GatherPanel_Update();
end

function GatherPanel_ItemDetailMin_OnEnter(frame)
  GatherPanel_ItemDetailMin_Update(frame);
  frame:ClearFocus();
end

function GatherPanel_ItemDetailMin_OnTab(frame)
  GatherPanel_ItemDetailMin_Update(frame);
  frame:ClearFocus();
  _G['ItemDetailMax']:SetFocus();
end

function GatherPanel_ItemDetailMax_OnEnter(frame)
  GatherPanel_ItemDetailMax_Update(frame);
  frame:ClearFocus();
end

function GatherPanel_ItemDetailMax_OnTab(frame)
  GatherPanel_ItemDetailMax_Update(frame);
  frame:ClearFocus();
end

function GatherPanel_ItemDetailMin_Update(frame)
  local amount = tonumber(frame:GetText());
  frame:SetText(amount);
  GatherPanel_ItemDetailUpdateButton_Update();
end

function GatherPanel_ItemDetailMax_Update(frame)
  local amount = tonumber(frame:GetText());
  frame:SetText(amount);
  GatherPanel_ItemDetailUpdateButton_Update();
end

function GatherPanel_ItemDetailUpdateButton_Update()
  local item = _G['ItemDetailFrame'].item;
  if (item.max == tonumber(_G['ItemDetailMax']:GetText()) and item.min == tonumber(_G['ItemDetailMin']:GetText())) then
    _G['ItemDetailUpdateButton']:Disable();
  else
    _G['ItemDetailUpdateButton']:Enable();
  end
end

function GatherPanel_NewItem_CreateButton_OnClick()
  local items = getItemlist();
  local itemID = tonumber(_G['GatherPanel_NewItem_Id']:GetText());
  local min = tonumber(_G['GatherPanel_NewItem_Min']:GetText());
  if (min == nil or min < 0) then
    min = 0;
  end
  local max = tonumber(_G['GatherPanel_NewItem_Max']:GetText());
  if (max == nil or max < min) then
    max = min;
  end

  items[itemID] = {
    id = itemID,
    min = min,
    max = max
  };
  GatherPanel_InitializeSortedItemList();
  GatherPanel_ReloadTracker();
  GatherPanel_UpdateItems();
  GatherPanel_Update();
  GatherPanel_TrackItem(items[itemID]);
  _G['GatherPanel_NewItem_CreateButton']:Disable();
  _G['GatherPanel_NewItem_Id']:SetText('');
  _G['GatherPanel_NewItem_Min']:SetText('');
  _G['GatherPanel_NewItem_Max']:SetText('');
  _G['GatherPanel_Label_ItemName']:SetText('Drag item into Item ID field.');
end

function GatherPanel_EditGroup(group, newName)
  group.name = newName;
  if group.name == "" then
    group = nil;
  end
  GatherPanel_InitializeSortedItemList();
  GatherPanel_Update();
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
  GatherPanel_Update();
end

function GatherPanel_Group_CreateButton_OnClick()
  StaticPopup_Show("GATHERPANEL_CREATE_GROUP")
end

function GatherPanel_NewItem_Id_OnReceive(frame)
  local infoType, itemID, itemLink = GetCursorInfo();
  if (infoType == 'item') then
    frame:SetText(tonumber(itemID));
    itemName = GetItemInfo(itemID);
    _G['GatherPanel_Label_ItemName']:SetText(itemName);
    ClearCursor();
    frame:ClearFocus();
    _G['GatherPanel_NewItem_Min']:SetFocus();
    GatherPanel_NewItem_Id_CheckItem(frame);
  end
end

function GatherPanel_NewItem_Id_CheckItem(frame)
  local itemID = tonumber(frame:GetText(itemID));
  if (itemID) then
    frame:SetText(itemID);
    itemName = GetItemInfo(itemID);
    if (itemName) then
      _G['GatherPanel_Label_ItemName']:SetText(itemName);

      for itemId, item in pairs(getItemlist()) do
        if (item.id == itemID) then
          _G['GatherPanel_Label_Status']:SetText('Item already added to the list!');
          _G['GatherPanel_NewItem_CreateButton']:Disable();
          return;
        end
      end
      _G['GatherPanel_Label_Status']:SetText('');
      ClearCursor();
      frame:ClearFocus();
      _G['GatherPanel_NewItem_Min']:SetFocus();
      frame:SetTextColor(1, 1, 1);
      _G['GatherPanel_NewItem_CreateButton']:Enable();

      return
    end
  end
  _G['GatherPanel_Label_ItemName']:SetText('Invalid Item ID');
  frame:SetTextColor(1, 0, 0);
end

function GatherPanel_ItemDetailDeleteButton_OnClick(frame)
  local itemID = frame:GetParent().item.id;

  for i, item in pairs(getItemlist()) do
    if (item.id == itemID) then
      getItemlist()[i] = nil;
      PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
      frame:GetParent().item = nil;
      GatherPanel_UpdateItems();
      GatherPanel_Update();
      HideParentPanel(frame);
      return;
    end
  end
end

function GatherPanel_TrackerX_OnMouseDown(self, button)
  if button == "RightButton" then
    GatherPanel_TrackItem(self.item);
  end
end

function GatherPanel_TrackerX_OnEnter(self)
  self.Bar.Label:SetText(self.item.itemCount .. '/' .. self.item.goal);
  GameTooltip:SetOwner(self, "ANCHOR_LEFTTOP");
  GameTooltip:SetItemByID(self.item.id);
  GameTooltip:Show();
end

function GatherPanel_TrackerX_OnLeave(self)
  self.Bar.Label:SetFormattedText(PERCENTAGE_STRING, self.item.progressPercentage * 100);
  GameTooltip_Hide();
end
