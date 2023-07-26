local _, addon = ...
local module = addon:RegisterModule("ObjectiveTracker")

local LINE_TYPE_ANIM = { template = "QuestObjectiveAnimLineTemplate", freeLines = { } };

local function blockFits(block, frame, offsetY)
  return frame.contentsHeight + block.height - offsetY < frame.maxHeight
end

local function scheduleFunction(func, ...)
  local args = ...

  C_Timer.After(0.5, function()
    func(args)
  end)
end

local function isComplete(entry)
  return entry.itemCount >= entry.goal
end

local function isGroupComplete(group)
  for _, entry in ipairs(group.entries) do
    if not isComplete(entry) then
      return false
    end
  end

  return true
end

local function getObjectiveStyles(entry)
  local metQuantity = isComplete(entry)
  local dashStyle = metQuantity and OBJECTIVE_DASH_STYLE_HIDE or OBJECTIVE_DASH_STYLE_SHOW

  if metQuantity then
    return dashStyle, OBJECTIVE_TRACKER_COLOR["Complete"]
  end

  if entry.max == entry.min or entry.max == entry.goal then
    return dashStyle, OBJECTIVE_TRACKER_COLOR["Normal"]
  end

  if entry.goal == entry.min then
    return dashStyle, OBJECTIVE_TRACKER_COLOR["Failed"]
  end

  return dashStyle, OBJECTIVE_TRACKER_COLOR["Normal"]
end

local function getObjectiveText(entry)
  if entry.goal == entry.max then
    return string.format(
      "%d/%d %s",
      min(entry.goal, entry.itemCount),
      entry.goal,
      entry.displayName)
  end

  return string.format(
    "%d/%d (max. %d) %s",
    min(entry.goal, entry.itemCount),
    entry.goal,
    entry.max,
    entry.displayName)
end

local objectiveTrackerFrame = CreateFrame("Frame", nil, ObjectiveTrackerBlocksFrame, "ObjectiveTrackerHeaderTemplate")

objectiveTrackerFrame.MinimizeButton:SetScript("OnClick", function(button)
  PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
  local trackerModule = button:GetParent().module
  trackerModule:SetCollapsed(not trackerModule:IsCollapsed())
  module:ObjectiveTracker_Update()
end)

local objectiveTrackerModule = ObjectiveTracker_GetModuleInfoTable("GATHERPANEL_TRACKER_MODULE")
objectiveTrackerModule:SetHeader(objectiveTrackerFrame, addon.T["GATHERING"])

function objectiveTrackerModule:GetRelatedModules()
  local modules = {}
  local trackerModules = Shallowcopy(ObjectiveTrackerFrame.MODULES)
  table.insert(trackerModules, objectiveTrackerModule)

  for _, trackerModule in ipairs(trackerModules) do
    if trackerModule.Header == self.Header then
      table.insert(modules, trackerModule)
    end
  end

  return modules
end

function objectiveTrackerModule:Update()
  if self.continuableContainer then
    self.continuableContainer:Cancel()
  end

  self.continuableContainer = ContinuableContainer:Create()
  local entries = GatherPanel_GetItemList()

  for _, entry in pairs(entries) do
    if entry.type == "ITEM" then
      local item = Item:CreateFromItemID(entry.id)
      self.continuableContainer:AddContinuable(item)
    end
  end

  self.allItemsLoaded = true
  self.allItemsLoaded = self.continuableContainer:ContinueOnLoad(function()
    if self.allItemsLoaded then
      self:BeginLayout()
      self:Layout()
      self:EndLayout()
    else
      module:InitObjectiveTracker(nil, true)
    end
  end)
end

function objectiveTrackerModule:Layout()
  if not addon.Variables.user.showObjectiveTracker then
    return
  end

  local groups = addon.getGroups()

  for _, group in ipairs(groups) do
    self:AddGroup(group)
  end
end

function objectiveTrackerModule:AddGroup(group)
  local block = self:GetBlock(group.id)
  block.group = group
  self:SetBlockHeader(block, group.groupData.name)
  local allObjectivesComplete = true
  local hasObjectives = false

  for _, entry in ipairs(group.entries) do
    if entry.tracked and  entry.goal and entry.goal > 0
    and (addon.Variables.user.showCompleted or entry.goal > entry.itemCount) then
      hasObjectives = true

      if entry.itemCount < entry.goal then
        allObjectivesComplete = false
        break
      end
    end
  end

  if not hasObjectives then
    block.used = false
    self:FreeUnusedLines(block)
    return
  end

  if allObjectivesComplete and addon.Variables.user.showCompleted then
    self:AddCompleteGroup(block)
  else
    self:AddObjectives(block, group.entries)
  end

  block:SetHeight(block.height)

  if self:AddBlock(block) then
    self:FreeUnusedLines(block)
    block:Show()
  else
    block.used = false
    self:FreeUnusedLines(block)
  end
end

function objectiveTrackerModule:AddCompleteGroup(block)
  local text = addon.T["ALL_TRACKED_IN_GROUP_COMPLETE"]
  local dashStyle = OBJECTIVE_DASH_STYLE_HIDE
  local colorStyle = OBJECTIVE_TRACKER_COLOR["Complete"]
  local line = self:AddObjective(block, 0, text, LINE_TYPE_ANIM, nil, dashStyle, colorStyle)
  line:Show()
  line.Check:SetShown(false)
end

function objectiveTrackerModule:AddObjectives(block, entries)
  for _, entry in ipairs(entries) do
    self:AddObjectiveLine(block, entry)
  end
end

function objectiveTrackerModule:AddObjectiveLine(block, entry)
  if not entry.goal or entry.goal == 0 then
    return
  end

  local completed = isComplete(entry)

  if completed and not addon.Variables.user.showCompleted then
    return
  end

  return self:AddOrUpdateObjectiveLine(block, entry)
end

function objectiveTrackerModule:AddOrUpdateObjectiveLine(block, entry)
  local completed = isComplete(entry)
  local dashStyle, colorStyle = getObjectiveStyles(entry)
  local text = getObjectiveText(entry)
  local line = self:AddObjective(block, entry.id, text, LINE_TYPE_ANIM, nil, dashStyle, colorStyle)
  line.Check:SetShown(completed)
  line.block = block

  line.FadeOutAnim:SetScript("OnFinished", function()
    module:ObjectiveTracker_Update()
  end)

  return line
end

function objectiveTrackerModule:AddBlock(block)
  local header = block.module.Header
  local blockAdded = false

  if not header or header.added then
    blockAdded = self:InternalAddBlock(block)
  elseif ObjectiveTracker_CanFitBlock(block, header) then
    if ObjectiveTracker_AddHeader(header) then
      blockAdded = self:InternalAddBlock(block)
    end
  end

  if not blockAdded then
    block.module.hasSkippedBlocks = true
  end

  return blockAdded
end

function objectiveTrackerModule:InternalAddBlock(block)
  local trackerModule = block.module or DEFAULT_OBJECTIVE_TRACKER_MODULE
  local blocksFrame = trackerModule.BlocksFrame
  block.nextBlock = nil

  if not block.isHeader then
    trackerModule.potentialBlocksAddedThisLayout = (trackerModule.potentialBlocksAddedThisLayout or 0) + 1
  end

  if not block.isHeader and trackerModule:IsCollapsed() then
    return false
  end

  block.offsetY = nil
  module:AnchorBlock(block, blocksFrame.currentBlock, not trackerModule.ignoreFit)

  if not block.offsetY then
    return false
  end

  if not trackerModule.topBlock then
    trackerModule.topBlock = block
  end

  if not trackerModule.firstBlock and not block.isHeader then
    trackerModule.firstBlock = block
  end

  if blocksFrame.currentBlock then
    blocksFrame.currentBlock.nextBlock = block
  end

  blocksFrame.currentBlock = block
  blocksFrame.contentsHeight = blocksFrame.contentsHeight + block.height - block.offsetY
  trackerModule.contentsAnimHeight = trackerModule.contentsAnimHeight + block.height
  trackerModule.contentsHeight = trackerModule.contentsHeight + block.height - block.offsetY
  return true
end

function objectiveTrackerModule:OnBlockHeaderClick(block, mouseButton)
  if mouseButton == "LeftButton" then
    if IsModifiedClick("QUESTWATCHTOGGLE") then
      local shouldTrack = false
      local groupId = block.id
      addon.trackGroup(nil, groupId, shouldTrack)
    else
      addon:ShowGroupInFrame(block.id)
    end
  end
end

function objectiveTrackerModule:FadeOutAllLines(block)
  for _, line in pairs(block.lines) do
    line.state = "FADING"
    line.FadeOutAnim:Play()
  end
end


function objectiveTrackerModule:GlowLine(line, onFinishedFunc)
  if onFinishedFunc then
    line.Glow.Anim:SetScript("OnFinished", onFinishedFunc)
  end

  line.Glow.Anim:Play()
  line.Sheen.Anim:Play()
  line.Check:Show()
  line.CheckFlash.Anim:Play()
end

function module:AnchorBlock(block, anchorBlock, checkFit)
  block:ClearAllPoints()

  if anchorBlock then
    self:AnchorBlockToReferenceBlock(block, anchorBlock, checkFit)
  else
    self:AnchorBlockToBlocksFrame(block, checkFit)
  end
end

function module:AnchorBlockToReferenceBlock(block, anchorBlock, checkFit)
  local trackerModule = block.module
	local blocksFrame = trackerModule.BlocksFrame
	block.offsetX, block.offsetY = ObjectiveTracker_GetBlockOffset(block)

  if anchorBlock.isHeader then
    block.offsetY = trackerModule.fromHeaderOffsetY
  end

  if checkFit and not blockFits(block, blocksFrame, block.offsetY) then
    block.offsetY = nil
    return
  end

  if block.isHeader then
    block.offsetY = block.offsetY + anchorBlock.module.fromModuleOffsetY
    block:SetPoint("LEFT", OBJECTIVE_TRACKER_HEADER_OFFSET_X, 0)
  else
    block:SetPoint("LEFT", block.offsetX, 0)
  end

  block:SetPoint("TOP", anchorBlock, "BOTTOM", 0, block.offsetY)
end

function module:AnchorBlockToBlocksFrame(block, checkFit)
  local trackerModule = block.module
	local blocksFrame = trackerModule.BlocksFrame
	local offsetX = ObjectiveTracker_GetBlockOffset(block)
  block.offsetY = 0

  if checkFit and not blockFits(block, blocksFrame, block.offsetY) then
    block.offsetY = nil
    return
  end

  local anchorFrame = blocksFrame.ScrollContents or blocksFrame

  if block.isHeader then
    block:SetPoint("TOPLEFT", anchorFrame, "TOPLEFT", OBJECTIVE_TRACKER_HEADER_OFFSET_X,block.offsetY)
  else
    block:SetPoint("TOPLEFT", anchorFrame, "TOPLEFT", offsetX, block.offsetY)
  end
end

function module:Init()
  module:InitObjectiveTracker(nil, true)
end

function module:FullUpdate()
  module:UpdateObjectiveTracker(nil, true)
end

function module:UpdateItem(entry, oldCount)
  if oldCount == entry.itemCount then
    return
  end

  if oldCount >= entry.goal and oldCount > entry.itemCount then
    return
  end

  for _, group in ipairs(addon.getGroups()) do
    self:UpdateEntryInGroup(entry, group)
  end
end

function module:UpdateEntryInGroup(entry, group)
  if #group.entries == 0 then
    return
  end

  if group.id ~= entry.parent then
    return
  end

  local block = objectiveTrackerModule:GetExistingBlock(group.id)

  if not block then
    return
  end

  local line = objectiveTrackerModule:GetLine(block, entry.id, LINE_TYPE_ANIM)

  if line then
    local _, previousLine = line:GetPointByName("TOPLEFT")
    local originalLastLine = block.currentLine
    block.currentLine = previousLine or block.HeaderText
    objectiveTrackerModule:AddOrUpdateObjectiveLine(block, entry)
    block.currentLine = originalLastLine

    if isGroupComplete(group) then
      if addon.Variables.user.showCompleted then
        return objectiveTrackerModule:GlowLine(line, function()
          objectiveTrackerModule:FadeOutAllLines(block)
        end)
      else
        return objectiveTrackerModule:GlowLine(line, function()
          objectiveTrackerModule:FreeBlock(block)
        end)
      end
    end

    if isComplete(entry) then
      if addon.Variables.user.showCompleted then
        return objectiveTrackerModule:GlowLine(line)
      else
        return objectiveTrackerModule:GlowLine(line, function()
          line.FadeOutAnim:Play()
        end)
      end
    end
  end
end

function module:InitObjectiveTracker(reason, internalReason)
  local tracker = ObjectiveTrackerFrame

  if not tracker.initialized then
    scheduleFunction(self.UpdateObjectiveTracker, self)
    return
  end

  if module.isUpdating or tracker.isUpdating then
    scheduleFunction(self.UpdateObjectiveTracker, self)
    return
  end

  module.isUpdating = true

  self:UpdateObjectiveTracker(reason, internalReason)
end

function module:UpdateObjectiveTracker(reason, internalReason)
  local tracker = ObjectiveTrackerFrame
  local trackerModules, trackerModulesInOrder

  if tracker.MODULES then
    trackerModules = Shallowcopy(tracker.MODULES)
    trackerModulesInOrder = Shallowcopy(tracker.MODULES_UI_ORDER)
  else
    trackerModules= {}
    trackerModulesInOrder = {}
  end

  table.insert(trackerModules, objectiveTrackerModule)
  table.insert(trackerModulesInOrder, objectiveTrackerModule)

  tracker.BlocksFrame.maxHeight = tracker.BlocksFrame:GetHeight()

  if tracker.BlocksFrame.maxHeight == 0 then
    self.isUpdating = false
    return
  end

  tracker.BlocksFrame.currentBlock = nil
  tracker.BlocksFrame.contentsHeight = 0

	local currentHeaders = module:ObjectiveTracker_GetVisibleHeaders();

  for _, trackerModule in ipairs(trackerModules) do
    if trackerModule.Header then
      trackerModule.Header.added = nil
    end
  end

  local gotMoreRoomThisPass = false
  local updateReason = reason or OBJECTIVE_TRACKER_UPDATE_ALL

  for _, trackerModule in ipairs(trackerModules) do
    local internalOverride = trackerModule == objectiveTrackerModule and (
      internalReason or updateReason == OBJECTIVE_TRACKER_UPDATE_ALL)

    if internalOverride then
      trackerModule:Update()
    elseif trackerModule == objectiveTrackerModule then
      local wantsMoreRoom = trackerModule.hasSkippedBlocks and gotMoreRoomThisPass
      local justShowsUp = trackerModule.Header and trackerModule.Header.animating

      if wantsMoreRoom or justShowsUp then
        trackerModule:Update()
      else
        trackerModule:StaticReanchor()
      end
    else
      if trackerModule.oldContentsHeight - trackerModule.contentsHeight >= 1 then
				gotMoreRoomThisPass = true
			end

      trackerModule:StaticReanchor()
    end
  end

  self:ObjectiveTracker_ReorderModules()
  self:ObjectiveTracker_AnimateHeaders(currentHeaders)

  for _, trackerModule in ipairs(trackerModules) do
    ObjectiveTracker_CheckAndHideHeader(trackerModule.Header)
  end

  if tracker.BlocksFrame.currentBlock then
    tracker.HeaderMenu:Show()
  else
    tracker.HeaderMenu:Hide()
  end

  tracker.BlocksFrame.currentBlock = nil
  self.isUpdating = false

  if tracker:IsInDefaultPosition() then
    UIParent_ManageFramePositions()
  end
end

function module:GetRelatedModulesForUpdate(trackerModule)
  if trackerModule then
    return tInvert(trackerModule:GetRelatedModules())
  end

  return nil
end

function module:IsRelatedModuleForUpdate(trackerModule, moduleLookup)
  if moduleLookup then
    return moduleLookup[trackerModule] ~= nil
  end

  return false
end

function module:ObjectiveTracker_Initialize()
  self:InitObjectiveTracker()
end

function module:ObjectiveTracker_Update(reason)
  self:InitObjectiveTracker(reason)
end

function module:ObjectiveTracker_ReorderModules()
  local trackerModulesInOrder = Shallowcopy(ObjectiveTrackerFrame.MODULES_UI_ORDER)
  table.insert(trackerModulesInOrder, objectiveTrackerModule)
  local visibleCount = self:ObjectiveTracker_CountVisibleModules()
  local showMinimizeButtons = visibleCount > 1
  local headerMenu = ObjectiveTrackerFrame.HeaderMenu
  headerMenu:ClearAllPoints()
  self.lastAnchorBlock = nil
  self.headerMenuPositioned = false

  for _, trackerModule in ipairs(trackerModulesInOrder) do
    local block = trackerModule.topBlock

    if block then
      self:PositionBlock(trackerModule, block, showMinimizeButtons)
    end
  end
end

function module:ObjectiveTracker_CountVisibleModules()
  local trackerModules = Shallowcopy(ObjectiveTrackerFrame.MODULES)
  table.insert(trackerModules, objectiveTrackerModule)
  local count = 0
  local seen = {}

  for _, trackerModule in ipairs(trackerModules) do
    local header = trackerModule.Header

    if header and not seen[header] then
      seen[header] = true

      if header:IsVisible() and trackerModule:GetBlockCount() > 0 then
        count = count + 1
      end
    end
  end

  return count
end

function module:PositionBlock(trackerModule, block, showMinimizeButtons)
  if trackerModule:UsesSharedHeader() then
    self:AnchorBlock(block, trackerModule.Header)
    local containingModule = trackerModule.Header.module

    if containingModule and containingModule.firstBlock then
      containingModule.firstBlock:ClearAllPoints()
      self:AnchorBlock(containingModule.firstBlock, trackerModule.lastBlock)
    end
  else
    self:AnchorBlock(block, self.lastAnchorBlock)
    self.lastAnchorBlock = trackerModule.lastBlock
  end

  local headerPoint = ObjectiveTrackerFrame.isOnLeftSideOfScreen and "LEFT" or "RIGHT"
  local offsetXHeader = ObjectiveTrackerFrame.isOnLeftSideOfScreen and -10 or 0
  local offsetXHeaderText = ObjectiveTrackerFrame.isOnLeftSideOfScreen and 30 or 4
  local offsetXButton = ObjectiveTrackerFrame.isOnLeftSideOfScreen and 9 or -20

  local headerMenu = ObjectiveTrackerFrame.HeaderMenu

  if not self.headerMenuPositioned and headerMenu then
    headerMenu:ClearAllPoints()
    headerMenu:SetPoint(headerPoint, trackerModule.Header, headerPoint, offsetXHeader, 0)
    self.headerMenuPositioned = true
  end

  trackerModule.Header.Text:ClearAllPoints()
  trackerModule.Header.Text:SetPoint("LEFT", trackerModule.Header, "LEFT", offsetXHeaderText, -1)
  local shouldShowMinimizeButton = showMinimizeButtons or trackerModule:IsCollapsed()
  trackerModule.Header.MinimizeButton:SetShown(shouldShowMinimizeButton)

  if shouldShowMinimizeButton then
    trackerModule.Header.MinimizeButton:ClearAllPoints()
    trackerModule.Header.MinimizeButton:SetPoint(headerPoint, trackerModule.Header, headerPoint, offsetXButton, 0)
  end
end

function module:ObjectiveTracker_GetVisibleHeaders()
  local headers = {}
  local trackerModules = Shallowcopy(ObjectiveTrackerFrame.MODULES)
  table.insert(trackerModules, objectiveTrackerModule)

  for _, trackerModule in ipairs(trackerModules) do
    local header = trackerModule.Header

    if header.added and header:IsVisible() then
      headers[header] = true
    end
  end

  return headers
end

function module:ObjectiveTracker_AnimateHeaders(previouslyVisibleHeaders)
  local currentHeaders = module:ObjectiveTracker_GetVisibleHeaders()

  for header, isVisible in pairs(currentHeaders) do
    if isVisible and not previouslyVisibleHeaders[header] then
      header:PlayAddAnimation()
    end
  end
end

function module:ObjectiveTracker_SetModulesCollapsed(collapsed, modules)
  for _, trackerModule in ipairs(modules) do
    trackerModule.collapsed = collapsed
  end
end

hooksecurefunc(_G, "ObjectiveTracker_Initialize", function()
  module:ObjectiveTracker_Initialize()
end)

hooksecurefunc(_G, "ObjectiveTracker_Update", function(reason)
  module:ObjectiveTracker_Update(reason)
end)
