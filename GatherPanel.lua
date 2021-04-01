GATHERPANEL_ITEMBAR_HEIGHT = 26;
NUM_ITEMS_DISPLAYED = 15;
NUM_TRACKERS_ENABLED = 0;
NUM_TRACKERS_CREATED = 1;
GATHERPANEL_ALL_CHARACTERS = false;
GATHERPANEL_ITEMS = {};



function GatherPanel_AddItem(itemId, min, max)
    GATHERPANEL_ITEMS[#GATHERPANEL_ITEMS] = {
        id = itemId,
        min = min,
        max = max
    };
end


function GatherPanel_OnShow()
    PlaySound(SOUNDKIT.UI_PROFESSIONS_WINDOW_OPEN);
    GatherPanel_UpdateItems();
    GatherPanel_Update();
end

function GatherPanel_OnHide()
    PlaySound(SOUNDKIT.UI_PROFESSIONS_WINDOW_CLOSE);
end

function GatherPanel_OnLoad()
    SlashCmdList["GATHERPANEL"] = function(msg)
        GatherPanel:SetShown(not GatherPanel:IsShown());
    end
    SLASH_GATHERPANEL1 = "/gp";

    local container = _G["GatherPanelInset"];
    for i=1, NUM_ITEMS_DISPLAYED, 1 do
        if (i ~= 1) then
            local bar = CreateFrame("Button", "GatherBar"..i, container, "GatherBarTemplate");
            bar:SetPoint("TOPRIGHT", "GatherBar"..(i-1), "BOTTOMRIGHT", 0, -3);
        end
        _G["GatherBar"..i].id = i;
        _G["GatherBar"..i]:SetPoint("LEFT", "GatherPanelInset", "LEFT", 10, 0);
        _G["GatherBar"..i.."ItemName"]:SetPoint("LEFT", "GatherBar"..i, "LEFT", 10, 0);
        _G["GatherBar"..i.."ItemName"]:SetPoint("RIGHT", "GatherBar"..i.."ItemBar", "LEFT", -3, 0);
        _G["GatherBar"..i.."ItemBarHighlight1"]:SetPoint("TOPLEFT", "GatherBar"..i, "TOPLEFT", -2, 4);
        _G["GatherBar"..i.."ItemBarHighlight1"]:SetPoint("BOTTOMRIGHT","GatherBar"..i, "BOTTOMRIGHT", -10, -4);
    end
    _G['ItemDetailDeleteButton']:SetText('Remove');
    _G['ItemDetailUpdateButton']:SetText('Update');
    _G['ItemDetailUpdateButton']:Disable();
    PanelTemplates_SetNumTabs(_G['GatherPanel'], 2);
    PanelTemplates_SetTab(_G['GatherPanel'], 1);
    GatherPanel_InitItems();
    GatherPanel_UpdateItems();
    GatherPanel_Update();
end

function GatherPanel_InitItems()
    for i, item in ipairs(GATHERPANEL_ITEMS) do
        item.itemName, _, _, _, _, _,
        _, _, _, item.itemTexture, _ = GetItemInfo(item.id);
        item.tracked = false;
        item.hovered = false;
    end
end

function GatherPanel_UpdateItems()
    for i, item in ipairs(GATHERPANEL_ITEMS) do
        local itemCount = 0;
        if (item.itemName == nil or item.itemTexture == nil) then
            -- retry, sometimes heavy load
            item.itemName, _, _, _, _, _,
            _, _, _, item.itemTexture, _ = GetItemInfo(item.id);
        end
        if (IsAddOnLoaded("DataStore_Containers") and GATHERPANEL_ALL_CHARACTERS) then
            for characterName, character in pairs(DataStore:GetCharacters()) do
                if (characterName ~= UnitName("player")) then
                    bagCount, bankCount, voidCount, reagentBankCount = DataStore:GetContainerItemCount(character, item.id);
                    itemCount = itemCount + bagCount + bankCount + voidCount + reagentBankCount;
                end
            end
        end
        local goal = 0;
        item.itemCount = itemCount + GetItemCount(item.id, true);
        if (item.min) then
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
            GatherPanel_Tracker_Update(_G["GatherPanel_Tracker"..item.tracker], item);
        end
    end
end

function GatherPanel_Update()
    _G['GatherPanel_Panel1'].ShowOfflineButton:SetChecked(GATHERPANEL_ALL_CHARACTERS);
    local numItems = #GATHERPANEL_ITEMS;
    if (not FauxScrollFrame_Update(GatherFrameScrollFrame, numItems, NUM_ITEMS_DISPLAYED, GATHERPANEL_ITEMBAR_HEIGHT)) then
        GatherFrameScrollFrameScrollBar:SetValue(0);
    end
    local itemOffset = FauxScrollFrame_GetOffset(GatherFrameScrollFrame);
    for i=1, NUM_ITEMS_DISPLAYED, 1 do
        local itemRow = _G["GatherBar"..i];
        local itemBar = _G["GatherBar"..i.."ItemBar"];
        local itemIndex = itemOffset + i;
        local item = GATHERPANEL_ITEMS[itemIndex];
        itemRow.itemIndex = itemIndex;
        if (itemIndex <= numItems) then
            if (item.goalType == 'min') then
                _G["GatherBar"..i.."ItemBar"]:SetStatusBarColor(0.9, 0.7, 0);
            end
            if (item.goalType == 'max') then
                _G["GatherBar"..i.."ItemBar"]:SetStatusBarColor(0, 0.6, 0.1);
            end
            _G["GatherBar"..i.."ItemName"]:SetText(item.itemName);

            if (itemRow.hovered or item == _G['ItemDetailFrame'].item) then
                _G["GatherBar"..i.."ItemBarHighlight1"]:Show();
                _G["GatherBar"..i.."ItemBarHighlight2"]:Show();
            else
                _G["GatherBar"..i.."ItemBarHighlight1"]:Hide();
                _G["GatherBar"..i.."ItemBarHighlight2"]:Hide();
            end

            if (item.hovered) then
                _G["GatherBar"..i.."ItemBarPercentage"]:SetText(item.itemCount.."/"..item.goal);
                -- Update tooltip when scrolled
                GameTooltip:SetItemByID(item.id);
            else
                if (item.progressPercentage >= 1) then
                    _G["GatherBar"..i.."ItemBarPercentage"]:SetText("Fully Stocked");
                else
                    _G["GatherBar"..i.."ItemBarPercentage"]:SetText(item.progressPercentageInteger.." %");
                end
            end
            _G["GatherBar"..i.."ItemBar"]:SetValue(item.progressPercentage);
            itemRow:Show();
        else
            itemRow:Hide()
        end
    end
end


function GatherPanel_Tracker_Update(tracker, item)
    if (item.goalType == 'min') then
        tracker.Bar:SetStatusBarColor(0.9, 0.7, 0);
    end
    if (item.goalType == 'max') then
        tracker.Bar:SetStatusBarColor(0, 0.6, 0.1);
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
	if( progressBar.AnimValue >= 100 or delta == 0 ) then
		return;
	end

	animOffset = animOffset or 12;
	local offset = progressBar.Bar:GetWidth() * (progressBar.AnimValue / 100) - animOffset;

	local prefix = overridePrefix or "";
	if( delta < 10 and not overridePrefix ) then
		prefix = "Small";
	end

	local flare = progressBar[prefix.."Flare1"];
	if( flare.FlareAnim:IsPlaying() ) then
		flare = progressBar[prefix.."Flare2"];
		if( flare.FlareAnim:IsPlaying() ) then
			flare = nil;
		end
	end

	if ( flare ) then
		flare:SetPoint("LEFT", progressBar.Bar, "LEFT", offset, 0);
		flare.FlareAnim:Play();
	end

	local barFlare = progressBar["FullBarFlare1"];
	if( barFlare.FlareAnim:IsPlaying() ) then
		barFlare = progressBar["FullBarFlare2"];
		if( barFlare.FlareAnim:IsPlaying() ) then
			barFlare = nil;
		end
	end

	if ( barFlare ) then
		barFlare.FlareAnim:Play();
	end
end


function GatherPanel_OnEvent(event)
    GatherPanel_UpdateItems();
    GatherPanel_Update();
end

function GatherPanel_Bar_OnEnter(frame)
    -- Rollover Text
    frame.hovered = true;
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT");
    GameTooltip:SetItemByID(GATHERPANEL_ITEMS[frame.itemIndex].id);
    GameTooltip:Show();
    GatherPanel_Update();
end

function GatherPanel_Bar_OnLeave(frame)
    frame.hovered = false;
    GameTooltip_Hide();
    GatherPanel_Update();
end

function GatherPanel_Bar_OnClick(frame)
    local item = GATHERPANEL_ITEMS[frame.itemIndex];
    _G['ItemDetailFrame'].item = item;
    GatherPanel_UpdateItemDetails();
    _G['ItemDetailFrame']:Show();
end


function GatherPanel_UpdateItemDetails()
    local frame = _G['ItemDetailFrame'];
    _G['ItemDetailTrackerCheckBox']:SetChecked(frame.item.tracked);
    _G['ItemName']:SetText(frame.item.itemName);
    _G['ItemDetailMin']:SetText(frame.item.min);
    _G['ItemDetailMax']:SetText(frame.item.max);
end


function GatherPanel_TrackItem(item)
    if (item.tracked) then
        item.tracked = false;
        item.tracker = nil;
        -- Rearrange trackers
        local newTracker = 0;
        for i, item in ipairs(GATHERPANEL_ITEMS) do
            if (item.tracker) then
                newTracker = newTracker + 1;
                item.tracker = newTracker;
                _G["GatherPanel_Tracker"..newTracker].icon = item.itemTexture;
                _G["GatherPanel_Tracker"..newTracker].Bar.Icon:SetTexture(item.itemTexture);
            end
        end
        _G["GatherPanel_Tracker"..NUM_TRACKERS_ENABLED]:Hide();
        NUM_TRACKERS_ENABLED = NUM_TRACKERS_ENABLED - 1;
    else
        -- Enable Tracker
        if (NUM_TRACKERS_ENABLED == NUM_TRACKERS_CREATED) then
            local tracker = CreateFrame("Frame", "GatherPanel_Tracker"..NUM_TRACKERS_CREATED+1, _G["GatherPanel_Tracker"], "GatherPanel_Tracker_Template");
            tracker:SetPoint("TOPLEFT", "GatherPanel_Tracker"..NUM_TRACKERS_CREATED, "BOTTOMLEFT", 0, 5);
            tracker.animValue = nil;
            NUM_TRACKERS_CREATED = NUM_TRACKERS_CREATED + 1;
        end
        NUM_TRACKERS_ENABLED = NUM_TRACKERS_ENABLED + 1;
        item.tracker = NUM_TRACKERS_ENABLED;
        _G["GatherPanel_Tracker"..item.tracker].icon = item.itemTexture;
        _G["GatherPanel_Tracker"..item.tracker].Bar.Icon:SetTexture(item.itemTexture);
        _G["GatherPanel_Tracker"..item.tracker]:Show();
        item.tracked = true;
    end
    GatherPanel_UpdateItems();
    GatherPanel_Update();
end


function GatherPanel_SetAllCharacters(checked)
    GATHERPANEL_ALL_CHARACTERS = checked;
    GatherPanel_UpdateItems();
    GatherPanel_Update();
end


function GatherPanel_SetPanel(id)
    _G['GatherPanel_Panel'.._G['GatherPanel'].selectedTab]:Hide();
    _G['GatherPanel_Panel'..id]:Show();
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
    local itemID = tonumber(_G['GatherPanel_NewItem_Id']:GetText());
    local min = tonumber(_G['GatherPanel_NewItem_Min']:GetText());
    if (min == nil or min < 0) then
        min = 0;
    end
    local max = tonumber(_G['GatherPanel_NewItem_Max']:GetText());
    if (max == nil or max < min) then
        max = min;
    end
    table.insert(GATHERPANEL_ITEMS, {
        id = itemID,
        min = min,
        max = max
    });
    GatherPanel_UpdateItems();
    GatherPanel_Update();
    _G['GatherPanel_NewItem_CreateButton']:Disable();
    _G['GatherPanel_NewItem_Id']:SetText('');
    _G['GatherPanel_NewItem_Min']:SetText('');
    _G['GatherPanel_NewItem_Max']:SetText('');
    _G['GatherPanel_Label_ItemName']:SetText('Drag item into Item ID field.');
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
    end
end

function GatherPanel_NewItem_Id_CheckItem(frame)
    local itemID = tonumber(frame:GetText(itemID));
    if (itemID) then
        frame:SetText(itemID);
        itemName = GetItemInfo(itemID);
        if (itemName) then
            _G['GatherPanel_Label_ItemName']:SetText(itemName);

            for i, item in ipairs(GATHERPANEL_ITEMS) do
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
            frame:SetTextColor(1,1,1);
            _G['GatherPanel_NewItem_CreateButton']:Enable();

            return
        end
    end
    _G['GatherPanel_Label_ItemName']:SetText('Invalid Item ID');
    frame:SetTextColor(1,0,0);
end


function GatherPanel_ItemDetailDeleteButton_OnClick(frame)
    local itemID = frame:GetParent().item.id;

    for i, item in ipairs(GATHERPANEL_ITEMS) do
        if (item.id == itemID) then
            table.remove(GATHERPANEL_ITEMS, i);
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
            frame:GetParent().item = nil;
            GatherPanel_UpdateItems();
            GatherPanel_Update();
            HideParentPanel(frame);
            return;
        end
    end
end