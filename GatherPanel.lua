GATHERPANEL_ITEMBAR_HEIGHT = 26;
NUM_ITEMS_DISPLAYED = 15;
NUM_TRACKERS_ENABLED = 0;
NUM_TRACKERS_CREATED = 1;
GATHERPANEL_ALL_CHARACTERS = false;
GATHERPANEL_ITEMS = {
    -- Herbalism
    { id=169701, max=2400, min=800 }, -- Death Blossom
    { id=168586, max=1200, min=400 }, -- Rising Glory
    { id=168589, max=1200, min=400 }, -- Marrowrot
    { id=170554, max=1200, min=400 }, -- Vigil's Torch
    { id=168583, max=1200, min=400 }, -- Widowbloom
    { id=171315, max=400, min=100 }, -- Nightshade

    -- Mining
    { id=171829, max=1600, min=800 }, -- Solenium Ore
    { id=171830, max=1600, min=800 }, -- Oxxein Ore
    { id=171831, max=1600, min=800 }, -- Phaedrum Ore
    { id=171832, max=1600, min=800 }, -- Sinvyr Ore
    { id=171833, max=1600, min=800 }, -- Elethium Ore
    { id=171828, max=2400, min=800 }, -- Lasestrite Ore

    -- Cooking
    { id=173032, max=400, min=200 }, -- Lost Sole
    { id=173033, max=400, min=200 }, -- Iridescent Amberjack
    { id=172053, max=400, min=200 }, -- Tenebrous Ribs
    { id=179314, max=400, min=200 }, -- Creeping Crawler Meat

    -- Raiding
    { id=172347, max=40, min=20 }, -- Heavy Desolate Armor Kit
    { id=171285, max=100, min=50 }, -- Shadowcore Oil
    { id=172049, max=80, min=40 }, -- Iridescent Ravioli with Apple Sauce
    { id=172045, max=80, min=40 }, -- Tenebrous Crown Roast Aspic
    { id=171267, max=160, min=80 }, -- Spiritual Healing Potion
    { id=171349, max=160, min=80 }, -- Potion of Phantom Fire
    { id=171275, max=160, min=80 }, -- Potion of Spectral Strength
    { id=181468, max=20 }, -- Veiled Augment Rune
    { id=171266, max=40, min=20 }, -- Potion of the Hidden Spirit
    { id=171370, max=40, min=20 }, -- Potion of the Specter Swiftness
    { id=171264, max=40, min=20 }, -- Potion of Shaded Sight
    { id=171276, max=40, min=20 }, -- Spectral Flask of Power
};

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
    GatherPanel_InitItems();
    GatherPanel_UpdateItems();
    GatherPanel_Update();
end

function GatherPanel_InitItems()
    for i, item in ipairs(GATHERPANEL_ITEMS) do
        item.itemName, _, _, _, _, _,
        _, _, _, item.itemTexture, _ = GetItemInfo(item.id);
        print(item.itemName);
    end
end

function GatherPanel_UpdateItems()
    for i, item in ipairs(GATHERPANEL_ITEMS) do
        local itemCount = 0;
        if (item.itemName == nil or item.itemTexture == nil) then
            -- retry, sometimes heavy load
            item.itemName, _, _, _, _, _,
            _, _, _, item.itemTexture, _ = GetItemInfo(item.id);
            print(item.itemName);
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

            if (itemRow.hovered or item.selected) then
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
    if (item.selected) then
        item.selected = false;
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
        item.selected = true;
    end
    GatherPanel_UpdateItems();
    GatherPanel_Update();
end


function GatherPanel_SetAllCharacters(checked)
    GATHERPANEL_ALL_CHARACTERS = checked;
    GatherPanel_UpdateItems();
    GatherPanel_Update();
end