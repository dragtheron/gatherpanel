local _, addon = ...;
local module = addon:RegisterModule("ObjectiveTracker");

local objectiveTrackerHeaderFrame = CreateFrame("Frame", nil, ObjectiveTrackerBlocksFrame, "ObjectiveTrackerHeaderTemplate");
local updateReason = 0x100000;

local wantsUpdate = false;

local objectiveTrackerModule = ObjectiveTracker_GetModuleInfoTable("GATHERPANEL_TRACKER_MODULE");
objectiveTrackerModule.updateReasonModule = updateReason;
objectiveTrackerModule:SetHeader(objectiveTrackerHeaderFrame, "Gather Panel");

function objectiveTrackerModule:GetRelatedModules()
  local modules = {};
  local header = self.Header;
  local trackerModules = Shallowcopy(ObjectiveTrackerFrame.MODULES);
  table.insert(trackerModules, objectiveTrackerModule);
  for _, trackerModule in ipairs(trackerModules) do
    if trackerModule.Header == header then
      table.insert(modules, trackerModule);
    end
  end
  return modules;
end

function objectiveTrackerModule:SetCollapsed(collapsed)
	module:ObjectiveTracker_SetModulesCollapsed(collapsed, self:GetRelatedModules());

	if self.Header and self.Header.MinimizeButton then
		self.Header.MinimizeButton:SetCollapsed(collapsed);
	end
end

function objectiveTrackerModule:SetLineInfo(block, objectiveKey, text, lineType, dashStyle, colorStyle)
  local line = self:GetLine(block, objectiveKey, lineType);

	if ( line.Dash ) then
		if ( not dashStyle ) then
			dashStyle = OBJECTIVE_DASH_STYLE_SHOW;
		end
		if ( line.dashStyle ~= dashStyle ) then
			if ( dashStyle == OBJECTIVE_DASH_STYLE_SHOW ) then
				line.Dash:Show();
				line.Dash:SetText(QUEST_DASH);
			elseif ( dashStyle == OBJECTIVE_DASH_STYLE_HIDE ) then
				line.Dash:Hide();
				line.Dash:SetText(QUEST_DASH);
			elseif ( dashStyle == OBJECTIVE_DASH_STYLE_HIDE_AND_COLLAPSE ) then
				line.Dash:Hide();
				line.Dash:SetText(nil);
			else
				error("Invalid dash style: " .. tostring(dashStyle));
			end
			line.dashStyle = dashStyle;
		end
	end


	local textHeight = self:SetStringText(line.Text, text, nil, colorStyle, block.isHighlighted);
	line:SetHeight(textHeight);
	return line;
end

function objectiveTrackerModule:GetBlock(id, overrideType, overrideTemplate)
  local blockType = overrideType or self.blockType;
	local blockTemplate = overrideTemplate or self.blockTemplate;

	if not self.usedBlocks[blockTemplate] then
		self.usedBlocks[blockTemplate] = {};
	end

	-- first try to return existing block
	local block = self.usedBlocks[blockTemplate][id];

	if not block then
		local pool = self.poolCollection:GetOrCreatePool(blockType, self.BlocksFrame or ObjectiveTrackerFrame.BlocksFrame, blockTemplate);

		local isNewBlock = nil;
		block, isNewBlock = pool:Acquire(blockTemplate);

		if isNewBlock then
			block.blockTemplate = blockTemplate; -- stored so we can use it to free from the lookup later
			block.lines = {};
		end

		self.usedBlocks[blockTemplate][id] = block;
		block.id = id;
		block.module = self;
	end

	block.used = true;
	block.height = 0;
	block.currentLine = nil;

	-- prep lines
	if block.lines then
		for objectiveKey, line in pairs(block.lines) do
			line.used = nil;
		end
	end

	return block;
end

objectiveTrackerHeaderFrame.MinimizeButton:SetScript("OnClick", function(button)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	local trackerModule = button:GetParent().module;
	trackerModule:SetCollapsed(not trackerModule:IsCollapsed());
	module:ObjectiveTracker_Update(0, nil, trackerModule);
end)

local LINE_TYPE_ANIM = { template = "QuestObjectiveAnimLineTemplate", freeLines = { } };

local moduleLoaded = false;
local objectiveTrackerInitialized = false;

local function getProgressText(entry)
  return string.format("%s: %d/%d", entry.displayName, min(entry.goal, entry.itemCount), entry.goal);
end

function objectiveTrackerModule:Update()
  self:BeginLayout();

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
    if not addon.Variables.user.showObjectiveTracker then
      return;
    end

    local groups = addon.getGroups();
    for _, group in ipairs(groups) do

      if #group.entries > 0 then
        local block = self:GetBlock(group.groupData.name);
        self:SetBlockHeader(block, group.groupData.name);

        local allMet = true;
        local hasRelevantItems = true;

        for _, entry in ipairs(group.entries) do
          if entry.goal and entry.goal > 0 then
            hasRelevantItems = true;
            if entry.itemCount < entry.goal then
              allMet = false;
              break;
            end
          end
        end

        if not hasRelevantItems then
          return;
        end

        if allMet then
          local progressText = addon.T["ALL_TRACKED_IN_GROUP_COMPLETE"];
          local dashStyle = OBJECTIVE_DASH_STYLE_HIDE;
          local colorStyle = OBJECTIVE_TRACKER_COLOR["Complete"];
          local line = self:AddObjective(block, 0, progressText, LINE_TYPE_ANIM, nil, dashStyle, colorStyle);
          line.Glow.Anim:SetScript("OnFinished", function(_line)
            if _line.state == "COMPLETING_ALL" then
              _line.FadeOutAnim:Play();
              _line.state = "FADING";
            else
              _line.state = "COMPLETED";
            end
          end)
          line:Show();
          line.Check:SetShown(false);
        else
          for _, entry in ipairs(group.entries) do
            if entry.goal and entry.goal > 0 then
              local metQuantity = entry.itemCount >= entry.goal;
              local dashStyle = metQuantity and OBJECTIVE_DASH_STYLE_HIDE or OBJECTIVE_DASH_STYLE_SHOW;
              local colorStyle;
              if metQuantity then
                colorStyle = OBJECTIVE_TRACKER_COLOR["Complete"];
              elseif entry.max == entry.min or entry.goal == entry.max then
                colorStyle = OBJECTIVE_TRACKER_COLOR["Normal"];
              elseif entry.goal == entry.min then
                colorStyle = OBJECTIVE_TRACKER_COLOR["Failed"];
              else
                colorStyle = OBJECTIVE_TRACKER_COLOR["Normal"];
              end
              local progressText = getProgressText(entry);
              local line = self:AddObjective(block, entry.id, progressText, LINE_TYPE_ANIM, nil, dashStyle, colorStyle);
              line.Check:SetShown(metQuantity);
              line.Glow.Anim:SetScript("OnFinished", function(_line)
                if _line.state == "COMPLETING_ALL" then
                  _line.FadeOutAnim:Play();
                  _line.state = "FADING";
                else
                  _line.state = "COMPLETED";
                end
              end)
            end
          end
        end

        block:SetHeight(block.height);

        if module:AddBlock(block) then
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
      objectiveTrackerModule:Update();
    end
  end

  allLoaded = self.continuableContainer:ContinueOnLoad(OnItemsLoaded);
  self:EndLayout();
end

function objectiveTrackerModule:IsHeaderVisible()
  local header = self.Header;
  if header.added and header:IsVisible() then
    return true;
  end
  return false;
end

function module:AddBlock(block)
  local header = block.module.Header;
  local blockAdded = false;

  -- if there's no header or it's been added, just add the block...
  if not header or header.added then
    blockAdded = self:InternalAddBlock(block);
  elseif ObjectiveTracker_CanFitBlock(block, header) then
    -- try to add header and maybe block
    if ObjectiveTracker_AddHeader(header) then
      blockAdded = self:InternalAddBlock(block);
    end
  end

  if not blockAdded then
    block.module.hasSkippedBlocks = true;
  end

  return blockAdded;
end

function module:InternalAddBlock(block)
  local module = block.module or DEFAULT_OBJECTIVE_TRACKER_MODULE;
	local blocksFrame = self.BlocksFrame;
	local blocksFrame = module.BlocksFrame;
	block.nextBlock = nil;

	-- This doesn't take fit into account, it just assumes that there's content to be added, so the potential count
	-- should increase (this is related to showing the collapse buttons on the headers, see Reorder)
	-- NOTE: Never count headers as added blocks
	if not block.isHeader then
		module.potentialBlocksAddedThisLayout = (module.potentialBlocksAddedThisLayout or 0) + 1;
	end

	-- Only allow headers to be added if the module is collapsed.
	if not block.isHeader and module:IsCollapsed() then
		return false;
	end

	local offsetY = self:AnchorBlock(block, blocksFrame.currentBlock, not module.ignoreFit);
	if ( not offsetY ) then
		return false;
	end

	if ( not module.topBlock ) then
		module.topBlock = block;
	end
	if ( not module.firstBlock and not block.isHeader ) then
		module.firstBlock = block;
	end
	if ( blocksFrame.currentBlock ) then
		blocksFrame.currentBlock.nextBlock = block;
	end
	blocksFrame.currentBlock = block;
	blocksFrame.contentsHeight = blocksFrame.contentsHeight + block.height - offsetY;
	module.contentsAnimHeight = module.contentsAnimHeight + block.height;
	module.contentsHeight = module.contentsHeight + block.height - offsetY;
	return true;
end

function module:UpdateItem(entry, oldCount)
  if oldCount == entry.itemCount then
    return;
  end

  if oldCount >= entry.goal and oldCount > entry.itemCount then
    return;
  end

  local groups = addon.getGroups();

  for _, group in ipairs(groups) do
    local groupCompleted = true;
    if #group.entries > 0 then
      if group.id == entry.parent then
        local block = objectiveTrackerModule:GetExistingBlock(group.groupData.name);

        if not block then
          -- not ready yet. come back later.
          return
        end

        for _, groupEntry in ipairs(group.entries) do
          if groupEntry.itemCount < entry.goal then
            groupCompleted = false;
            break;
          end
        end

        local metQuantity = entry.itemCount >= entry.goal;
        local dashStyle = metQuantity and OBJECTIVE_DASH_STYLE_HIDE or OBJECTIVE_DASH_STYLE_SHOW;
        local colorStyle;
        if entry.goal == entry.min then
          colorStyle = OBJECTIVE_TRACKER_COLOR["Failed"];
        elseif metQuantity then
          colorStyle = OBJECTIVE_TRACKER_COLOR["Complete"];
        else
          colorStyle = OBJECTIVE_TRACKER_COLOR["Normal"];
        end
        local progressText = getProgressText(entry);
        local line = objectiveTrackerModule:GetLine(block, entry.id, LINE_TYPE_ANIM);

        if line then
          objectiveTrackerModule:SetLineInfo(block, entry.id, progressText, LINE_TYPE_ANIM, dashStyle, colorStyle);
          if (entry.itemCount >= entry.goal) then
            line.Glow.Anim:SetScript("OnFinished", function(glowFrame)
              local _line = glowFrame:GetParent():GetParent();
              if _line.state == "COMPLETING_ALL" then
                _line.FadeOutAnim:Play();
                _line.state = "FADING";
              else
                _line.state = "COMPLETED";
              end
            end);
            line.FadeOutAnim:SetScript("OnFinished", function(fadeOutFrame)
              local _line = fadeOutFrame:GetParent();
              local block = _line.block;
              block.module:FreeLine(block, line);
              for _, otherLine in pairs(block.lines) do
                if ( otherLine.state == "FADING" ) then
                  -- some other line is still fading
                  return;
                end
              end
              module:ObjectiveTracker_Update();
            end);
            line.block = block;

            if groupCompleted then
              line.state = "COMPLETING_ALL";
            else
              line.state = "COMPLETING";
            end

            line.Check:Show();
            line.Sheen.Anim:Play();
            line.Glow.Anim:Play();
            line.CheckFlash.Anim:Play();
          end
        end
      end
    end
  end
end

function module:FullUpdate()
  module:ObjectiveTracker_Update();
end


function module:Init()
  self:FullUpdate();
end

local function scheduleUpdate(func, ...)
  local args = ...;

  C_Timer.After(0.5, function()
    func(args);
  end)
end

function module:ObjectiveTracker_Update(reason, id, moduleWhoseCollapseChanged)
  local tracker = ObjectiveTrackerFrame;

  local trackerModules, trackerModulesInOrder;

  if tracker.MODULES then
    trackerModules = Shallowcopy(tracker.MODULES);
    trackerModulesInOrder = Shallowcopy(tracker.MODULES_UI_ORDER);
  else
    trackerModules = {};
    trackerModulesInOrder = {};
  end

  table.insert(trackerModules, objectiveTrackerModule);
  table.insert(trackerModulesInOrder, objectiveTrackerModule);

  -- tracker position handled by blizzard

	if tracker.isUpdating then
    scheduleUpdate(module.ObjectiveTracker_Update, self, reason, id, moduleWhoseCollapseChanged);
		return;
	end

	if ( not tracker.initialized ) then
    scheduleUpdate(module.ObjectiveTracker_Update, self, reason, id, moduleWhoseCollapseChanged);
		return;
	end

	tracker.BlocksFrame.maxHeight = tracker.BlocksFrame:GetHeight();
	if ( tracker.BlocksFrame.maxHeight == 0 ) then
		return;
	end

	tracker.BlocksFrame.currentBlock = nil;
	tracker.BlocksFrame.contentsHeight = 0;

	-- Gather existing headers, only newly added ones will animate
	local currentHeaders = module:ObjectiveTracker_GetVisibleHeaders();

	-- mark headers unused
	for _, trackerModule in ipairs(trackerModules) do
    if trackerModule == objectiveTrackerModule then
      if trackerModule.Header then
        trackerModule.Header.added = nil;
      end
    end
	end

	-- run module updates
	local gotMoreRoomThisPass = false;
	for i = 1, #trackerModules do
		local trackerModule = trackerModules[i];
		if true then
        -- run a full update on this module
        if trackerModule == objectiveTrackerModule then
          trackerModule:Update();
        end
        -- check if it's now taking up less space, using subtraction because of floats
        if ( trackerModule.oldContentsHeight - trackerModule.contentsHeight >= 1 ) then
          -- it is taking up less space, might have freed room for other modules
          gotMoreRoomThisPass = true;
        end
      else
        -- this module's contents have not have changed
        -- but if we got more room and this module has unshown content, do a full update
        -- also do a full update if the header is animating since the module does not technically have any blocks at that point
        if trackerModule == objectiveTrackerModule then
          if ( (trackerModule.hasSkippedBlocks and gotMoreRoomThisPass) or (trackerModule.Header and trackerModule.Header.animating) ) then
            trackerModule:Update();
          else
            trackerModule:StaticReanchor();
          end
        end
      end
	end

	module:ObjectiveTracker_ReorderModules();
	module:ObjectiveTracker_AnimateHeaders(currentHeaders);

	-- hide unused headers
	for i = 1, #trackerModules do
		ObjectiveTracker_CheckAndHideHeader(trackerModules[i].Header);
	end

	if ( tracker.BlocksFrame.currentBlock ) then
		tracker.HeaderMenu:Show();
	else
		tracker.HeaderMenu:Hide();
	end

	tracker.BlocksFrame.currentBlock = nil;

	if tracker:IsInDefaultPosition() then
		UIParent_ManageFramePositions();
	end
end


-- yes, we have to implement each objective tracker frame method.
-- this calls for a library!

hooksecurefunc(_G, "ObjectiveTracker_Initialize", function()
  objectiveTrackerInitialized = true;
end);

hooksecurefunc(_G, "ObjectiveTracker_Update", function(reason, id, moduleWhoseCollapseChanged)
  module:ObjectiveTracker_Update(reason, id, moduleWhoseCollapseChanged)
end);

-- hooksecurefunc(_G, "ObjectiveTracker_ReorderModules", function()
--   module:ObjectiveTracker_ReorderModules()
-- end);

hooksecurefunc(_G, "ObjectiveTracker_UpdatePOIs", function() end);

function module:GetRelatedModulesForUpdate(trackerModule)
  if trackerModule then
    return tInvert(trackerModule:GetRelatedModules());
  end

  return nil;
end

function module:IsRelatedModuleForUpdate(module, moduleLookup)
	if moduleLookup then
		return moduleLookup[module] ~= nil;
	end

	return false;
end

function module:ObjectiveTracker_ReorderModules()
  local trackerModulesInOrder = Shallowcopy(ObjectiveTrackerFrame.MODULES_UI_ORDER);
  table.insert(trackerModulesInOrder, objectiveTrackerModule);
	local visibleCount = module:ObjectiveTracker_CountVisibleModules();
  local showAllModuleMinimizeButtons = visibleCount > 1;

  local anchorBlock = nil;

  local header = ObjectiveTrackerFrame.HeaderMenu;
  header:ClearAllPoints();

  for i, trackerModule in ipairs(trackerModulesInOrder) do
    local topBlock = trackerModule.topBlock;
    if topBlock then
      if trackerModule:UsesSharedHeader() then
        module:AnchorBlock(topBlock, trackerModule.Header);

        local containingModule = trackerModule.Header.module;
        if containingModule and containingModule.firstBlock then
          containingModule.firstBlock:ClearAllPoints();
          module:AnchorBlock(containingModule.firstBlock, trackerModule.lastBlock);
        end
      else
        module:AnchorBlock(topBlock, anchorBlock);
        anchorBlock = trackerModule.lastBlock;
      end

      local headerPoint = ObjectiveTrackerFrame.isOnLeftSideOfScreen and "LEFT" or "RIGHT";
      local offsetXHeader = ObjectiveTrackerFrame.isOnLeftSideOfScreen and -10 or 0;
      local offsetXHeaderText = ObjectiveTrackerFrame.isOnLeftSideOfScreen and 30 or 4;
      local offsetXButton = ObjectiveTrackerFrame.isOnLeftSideOfScreen and 9 or -20;

      if header then
        header:ClearAllPoints();
        header:SetPoint(headerPoint, trackerModule.Header, headerPoint, offsetXHeader, 0);
        header = nil;
      end

      trackerModule.Header.Text:ClearAllPoints();
      trackerModule.Header.Text:SetPoint("LEFT", trackerModule.Header, "LEFT", offsetXHeaderText, -1);
      local shouldShowThisModuleMinimizeButton = showAllModuleMinimizeButtons or trackerModule:IsCollapsed();
      trackerModule.Header.MinimizeButton:SetShown(shouldShowThisModuleMinimizeButton);

      if shouldShowThisModuleMinimizeButton then
        trackerModule.Header.MinimizeButton:ClearAllPoints();
        trackerModule.Header.MinimizeButton:SetPoint(headerPoint, trackerModule.Header, headerPoint, offsetXButton, 0);
      end
    end
  end
end

function module:ObjectiveTracker_GetVisibleHeaders()
	local headers = {};
  local trackerModules = Shallowcopy(ObjectiveTrackerFrame.MODULES);
  table.insert(trackerModules, objectiveTrackerModule);
	for _, trackerModule in ipairs(trackerModules) do
		local header = trackerModule.Header;
		if header.added and header:IsVisible() then
			headers[header] = true;
		end
	end

	return headers;
end

function module:ObjectiveTracker_AnimateHeaders(previouslyVisibleHeaders)
	local currentHeaders = module:ObjectiveTracker_GetVisibleHeaders();
	for header, isVisible in pairs(currentHeaders) do
		if isVisible and not previouslyVisibleHeaders[header] then
			header:PlayAddAnimation();
		end
	end
end

function module:ObjectiveTracker_CountVisibleModules()
  local trackerModules = Shallowcopy(ObjectiveTrackerFrame.MODULES);
  table.insert(trackerModules, objectiveTrackerModule);
  local count = 0;
  local seen = {};

  for i, trackerModule in ipairs(trackerModules) do
    local header = trackerModule.Header;

    if header and not seen[header] then
      seen[header] = true;
      if header:IsVisible() and trackerModule:GetBlockCount() > 0 then
        count = count + 1;
      end
    end
  end

  return count;
end

function module:AnchorBlock(block, anchorBlock, checkFit)
	local trackerModule = block.module;
	local blocksFrame = trackerModule.BlocksFrame;
	local offsetX, offsetY = ObjectiveTracker_GetBlockOffset(block);
	block:ClearAllPoints();
	if ( anchorBlock ) then
		if ( anchorBlock.isHeader ) then
			offsetY = trackerModule.fromHeaderOffsetY;
		end
		-- check if the block can fit
		if ( checkFit and (blocksFrame.contentsHeight + block.height - offsetY > blocksFrame.maxHeight) ) then
			return;
		end
		if ( block.isHeader ) then
			offsetY = offsetY + anchorBlock.module.fromModuleOffsetY;
			block:SetPoint("LEFT", OBJECTIVE_TRACKER_HEADER_OFFSET_X, 0);
		else
			block:SetPoint("LEFT", offsetX, 0);
		end
		block:SetPoint("TOP", anchorBlock, "BOTTOM", 0, offsetY);
	else
		offsetY = 0;
		-- check if the block can fit
		if ( checkFit and (blocksFrame.contentsHeight + block.height > blocksFrame.maxHeight) ) then
			return;
		end
		-- if the blocks frame is a scrollframe, attach to its scrollchild
		if ( block.isHeader ) then
			block:SetPoint("TOPLEFT", blocksFrame.ScrollContents or blocksFrame, "TOPLEFT", OBJECTIVE_TRACKER_HEADER_OFFSET_X, offsetY);
		else
			block:SetPoint("TOPLEFT", blocksFrame.ScrollContents or blocksFrame, "TOPLEFT", offsetX, offsetY);
		end
	end
	return offsetY;
end


function module:ObjectiveTracker_SetModulesCollapsed(collapsed, modules)
	for index, trackerModule in ipairs(modules) do
		trackerModule.collapsed = collapsed;
	end
end
