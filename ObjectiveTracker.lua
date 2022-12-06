local _, addon = ...;
local module = addon:RegisterModule("ObjectiveTracker");

local objectiveTrackerHeaderFrame = CreateFrame("Frame", nil, ObjectiveTrackerBlocksFrame, "ObjectiveTrackerHeaderTemplate");
local updateReason = 0x100000;

local objectiveTrackerModule = ObjectiveTracker_GetModuleInfoTable("GATHERPANEL_TRACKER_MODULE");
objectiveTrackerModule.updateReasonModule = updateReason;
objectiveTrackerModule:SetHeader(objectiveTrackerHeaderFrame, "Gather Panel");

local LINE_TYPE_ANIM = { template = "QuestObjectiveAnimLineTemplate", freeLines = { } };

local function getGroups()
  local entries = GatherPanel_GetItemList();
  local sortedEntryKeys = addon.sortedHierarchy;
  local groups = {};
  local currentGroup = nil;

  for i = 1, #sortedEntryKeys, 1 do
    local entryKey = sortedEntryKeys[i].id;
    local entry;

    if entryKey == 0 then
      entry = {
        type = "GROUP",
        name = "Default Group",
        id = 0,
      };
    else
      entry = entries[entryKey];
    end

    if entry.type == "GROUP" then
      if currentGroup ~= nil then
        table.insert(groups, currentGroup);
      end
      currentGroup = {
        groupData = entry,
        entries = {},
      };
    elseif entry.type == "ITEM" and entry.tracked then
      table.insert(currentGroup.entries, entry);
    end
  end

  if currentGroup ~= nil then
    table.insert(groups, currentGroup)
  end
  return groups;
end

function objectiveTrackerModule:Update()
  self:BeginLayout();

  -- TODO: Check what this does
  if self.continuableContainer then
    self.continuableContainer:Cancel();
  end

  self.continuableContainer = ContinuableContainer:Create();

  local entries = GatherPanel_GetItemList();

  for _, entry in pairs(entries) do
    if entry.type == "ITEM" then
      local item = Item:CreateFromItemID(entry.id);
      self.continuableContainer:AddContinuable(item);
    end
  end


  local function Layout()
    local groups = getGroups();
    for _, group in ipairs(groups) do

      if #group.entries > 0 then

        local block = self:GetBlock(group.groupData.name);
        self:SetBlockHeader(block, group.groupData.name);

        for _, entry in ipairs(group.entries) do
          local metQuantity = entry.itemCount >= entry.goal;
          local dashStyle = metQuantity and OBJECTIVE_DASH_STYLE_HIDE or OBJECTIVE_DASH_STYLE_SHOW;
          local colorStyle = OBJECTIVE_TRACKER_COLOR[metQuantity and "Complete" or "Normal"];
          local progressText = string.format("%d/%d %s", min(entry.goal, entry.itemCount), entry.goal, entry.displayName);
          local line = self:AddObjective(block, entry.id, progressText, LINE_TYPE_ANIM, nil, dashStyle, colorStyle);
          line.Check:SetShown(metQuantity);
        end

        block:SetHeight(block.height);

        if ObjectiveTracker_AddBlock(block) then
          block:Show();
          self:FreeUnusedLines(block);
        else
          block.used = false;
          break;
        end
      end
    end
  end

  local allLoaded = true;

  local function OnItemsLoaded()
    if allLoaded then
      Layout();
    else
      ObjectiveTracker_Update(updateReason);
    end
  end

  allLoaded = self.continuableContainer:ContinueOnLoad(OnItemsLoaded);
  self:EndLayout();
end


hooksecurefunc(_G, "ObjectiveTracker_Initialize", function(self)
  table.insert(ObjectiveTrackerFrame.MODULES, objectiveTrackerModule);
  table.insert(ObjectiveTrackerFrame.MODULES_UI_ORDER, objectiveTrackerModule);
  ObjectiveTracker_Update(updateReason);
end);

function module:UpdateItem(item)
  --fixme: implement
end

function module:FullUpdate()
  getGroups();
  ObjectiveTracker_Update(updateReason);
end
