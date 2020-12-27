GATHERPANEL_ITEMBAR_HEIGHT = 26;
NUM_ITEMS_DISPLAYED = 15;
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
    { id=171829, max=1200, min=400 }, -- Solenium Ore
    { id=171830, max=1200, min=400 }, -- Oxxein Ore
    { id=171831, max=1200, min=400 }, -- Phaedrum Ore
    { id=171832, max=1200, min=400 }, -- Sinvyr Ore
    { id=171833, max=1200, min=400 }, -- Elethium Ore
    { id=171828, max=2400, min=800 }, -- Lasestrite Ore

    -- Cooking
    { id=173032, max=200, min=100 }, -- Lost Sole
    { id=173033, max=200, min=100 }, -- Iridescent Amberjack
    { id=172053, max=200, min=100 }, -- Tenebrous Ribs
    { id=179314, max=200, min=100 }, -- Creeping Crawler Meat

    -- Raiding
    { id=172347, max=40, min=20 }, -- Heavy Desolate Armor Kit
    { id=171285, max=40, min=20 }, -- Shadowcore Oil
    { id=172049, max=80, min=40 }, -- Iridescent Ravioli with Apple Sauce
    { id=172045, max=80, min=40 }, -- Tenebrous Crown Roast Aspic
    { id=171267, max=80, min=40 }, -- Spiritual Healing Potion
    { id=171349, max=80, min=40 }, -- Potion of Phantom Fire
    { id=171275, max=80, min=40 }, -- Potion of Spectral Strength
    { id=181468, max=20 }, -- Veiled Augment Rune
    { id=171266, max=20 }, -- Potion of the Hidden Spirit
    { id=171370, max=20 }, -- Potion of the Specter Swiftness
    { id=171264, max=20 }, -- Potion of Shaded Sight
    { id=171276, max=20, min=4 }, -- Spectral Flask of Power
};

function GatherPanel_OnShow()
    PlaySound(SOUNDKIT.UI_PROFESSIONS_WINDOW_OPEN);
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
        _G["GatherBar"..i]:SetPoint("LEFT", "GatherPanelInset", "LEFT", 10, 0);
        _G["GatherBar"..i.."ItemName"]:SetPoint("LEFT", "GatherBar"..i, "LEFT", 10, 0);
        _G["GatherBar"..i.."ItemName"]:SetPoint("RIGHT", "GatherBar"..i.."ItemBar", "LEFT", -3, 0);
        _G["GatherBar"..i.."ItemBarHighlight1"]:SetPoint("TOPLEFT", "GatherBar"..i, "TOPLEFT", -2, 4);
        _G["GatherBar"..i.."ItemBarHighlight1"]:SetPoint("BOTTOMRIGHT","GatherBar"..i, "BOTTOMRIGHT", -10, -4);
    end
    GatherPanel_Update();
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
        itemRow.itemIndex = itemIndex;
        if (itemIndex <= numItems) then
            local itemName = GetItemInfo(GATHERPANEL_ITEMS[itemIndex].id);
            local itemCount = 0;
            if (IsAddOnLoaded("DataStore_Containers") and GATHERPANEL_ALL_CHARACTERS) then
                for characterName, character in pairs(DataStore:GetCharacters()) do
                    if (characterName ~= UnitName("player")) then
                        bagCount, bankCount, voidCount, reagentBankCount = DataStore:GetContainerItemCount(character, GATHERPANEL_ITEMS[itemIndex].id);
                        itemCount = itemCount + bagCount + bankCount + voidCount + reagentBankCount;
                    end
                end
            end
            itemCount = itemCount + GetItemCount(GATHERPANEL_ITEMS[itemIndex].id, true)
            local goal = 0;
            if (GATHERPANEL_ITEMS[itemIndex].min) then
                if (itemCount < GATHERPANEL_ITEMS[itemIndex].min) then
                    goal = GATHERPANEL_ITEMS[itemIndex].min;
                    _G["GatherBar"..i.."ItemBar"]:SetStatusBarColor(0.9, 0.7, 0);
                else
                    goal = GATHERPANEL_ITEMS[itemIndex].max;
                    _G["GatherBar"..i.."ItemBar"]:SetStatusBarColor(0, 0.6, 0.1);
                end
            else
                goal = GATHERPANEL_ITEMS[itemIndex].max
                _G["GatherBar"..i.."ItemBar"]:SetStatusBarColor(0, 0.6, 0.1);
            end
            local progressPercentage = itemCount / goal;
            local progressPercentageInteger = math.floor(progressPercentage * 100);
            _G["GatherBar"..i.."ItemName"]:SetText(itemName);
            if (itemRow.selected) then
                _G["GatherBar"..i.."ItemBarPercentage"]:SetText(itemCount.."/"..goal);
                _G["GatherBar"..i.."ItemBarHighlight1"]:Show();
                _G["GatherBar"..i.."ItemBarHighlight2"]:Show();
                -- Update tooltip when scrolled
                GameTooltip:SetItemByID(GATHERPANEL_ITEMS[itemIndex].id);
            else
                if (progressPercentage >= 1) then
                    _G["GatherBar"..i.."ItemBarPercentage"]:SetText("Fully Stocked");
                else
                    _G["GatherBar"..i.."ItemBarPercentage"]:SetText(progressPercentageInteger.." %");
                end
                _G["GatherBar"..i.."ItemBarHighlight1"]:Hide();
                _G["GatherBar"..i.."ItemBarHighlight2"]:Hide();
            end
            _G["GatherBar"..i.."ItemBar"]:SetValue(progressPercentage);
            itemRow:Show();
        else
            itemRow:Hide()
        end
    end
end

function GatherPanel_OnEvent(event)
    GatherPanel_Update();
end

function GatherPanel_Bar_OnEnter(frame)
    -- Rollover Text
    frame.selected = true;
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT");
    GameTooltip:SetItemByID(GATHERPANEL_ITEMS[frame.itemIndex].id);
    GameTooltip:Show();
    GatherPanel_Update();
end

function GatherPanel_Bar_OnLeave(frame)
    frame.selected = false;
    GameTooltip_Hide();
    GatherPanel_Update();
end


function GatherPanel_SetAllCharacters(checked)
    GATHERPANEL_ALL_CHARACTERS = checked;
    GatherPanel_Update();
end