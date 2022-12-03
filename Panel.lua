local _, addon = ...;
local module = addon:RegisterModule("Panel");

local itemButtonHeight = 26;
local numItemsDisplayed = 15;
local numTrackersEnabled = 0;
local numTrackersCreated = 1;


local loaded = false;


local function sortByQualityAndName(a, b)
  if a.quality ~= nil and b.quality ~= nil
    and a.quality ~= b.quality then
      return a.quality > b.quality;
  end

  if a.professionQuality ~= nil and b.professionQuality ~= nil
    and a.professionQuality ~= b.professionQuality then
      return a.professionQuality > b.professionQuality
  end

  return a.name < b.name;
end


local function generateSortedEntriesList()
  local entriesSorted = {};

  for _, entry in pairs(addon.Variables.global.Items) do
    table.insert(entriesSorted, entry);
    table.sort(entriesSorted, sortByQualityAndName)
  end

  return entriesSorted;
end


local function extractGroupHierarchy()
  local groups = {};
  for _, entry in module.entriesSorted do
    if entry.type == addon.Core_Entries.ItemTypes.group then
      local group = entry;
      groups[group.id] = {};
    end
  end
  for _, entry in module.entriesSorted do
    if entry.type ~= addon.Core_Entries.ItemTypes.group then
      table.insert(groups[entry.groupId], entry);
    end
  end
  return groups;
end


local function createFrame()
  local frame = CreateFrame("Frame", nil, nil, "GatherPanel_PanelTemplate");
  module.frame = frame;
end


local function updateGroupDropDowns(entry)
  module.frame.AddEntry.ParentDropDown.id = entry.id;
  UIDropDownMenu_SetText(module.frame.AddEntry.ParentDropDown, entry.name);
  UIDropDownMenu_SetWidth(module.frame.AddEntry.ParentDropDown, 120);
end


---@param entry Entries.Entry
local function setGroupForEntry(entry)
  local parentEntry = addon.Entries.GetParent(entry);
  if parentEntry then
    updateGroupDropDowns(parentEntry);
  else
    updateGroupDropDowns(addon.Groups.defaultGroup);
  end
end


local function addGroupDropDownInfo(dropDown, entry)
  local info = UIDropDownMenu_CreateInfo();
  info.text = entry.name;
  info.isNotRadio = false;
  info.func = setGroupForEntry;
  info.arg1 = entry.id;
  if dropDown.selected == 0 then
    info.checked = 1;
  else
    info.checked = nil;
  end
  UIDropDownMenu_AddButton(info);
end


local function initGroupDropDownOptions(dropDown)
  addGroupDropDownInfo(dropDown, addon.Groups.defaultGroup);
  for _, index in addon.Entries:GetIndex(addon.Entries.EntryTypes.group) do
    local entry = module.Entries.Entries[index];
    addGroupDropDownInfo(dropDown, entry);
  end
end


local function selectList(listKey)
  return addon.Entries:SelectList(listKey);
end


local function addListDropDownInfo(dropdown, displayName, listKey)
  local info = UIDropDownMenu_CreateInfo();
  info.keepShownOnClick = 1;
  info.text = displayName;
  info.isNotRadio = false;
  info.tooltipTitle = displayName;
  info.func = selectList;
  info.arg1 = listKey;

  if addon.Entries.selectedListKey == listKey then
    info.checked = 1;
  else
    info.checked = nil;
  end
  UIDropDownMenu_AddButton(info);
end


local function initListSelectionDropDownOptions(dropdown)
  local combinedListKey = addon.Entries:GenerateListKey("X-Internal", "Combined");
  addListDropDownInfo(dropdown, addon.T["COMBINED"], combinedListKey);
  for realm, realmList in pairs(addon.Variables.Entries) do
    for character in pairs(realmList) do
      local displayName = string.format("%s-%s", character, realm);
      local listKey = addon.Entries:GenerateListKey(realm, character);
      addListDropDownInfo(dropdown, displayName, listKey);
    end
  end
end


function module:Init()
  self.entriesSorted = generateSortedEntriesList();
  self.groups = extractGroupHierarchy();
  self.frame = createFrame();
  self.tabFrames = {
    self.frame.List,
    self.frame.AddEntry,
  };
  self.selectedTabFrame = self.tabFrames[1];
  initGroupDropDownOptions(module.frame.AddEntry.ParentDropDown);
  initListSelectionDropDownOptions(module.frame.ListDropDown);
end


function module:Update()
end


local function selectTab(index)
  module.selectedTab:Hide();
  module.selectedTab = module.tabFrames[index];
  module.selectedTab:Show();
end
