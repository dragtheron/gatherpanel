---@type _, Addon
local _, Addon = ...;

local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0");

---@type LocalizationModule
local LocalizationModule = Addon:LoadModule("Localization");

---@type StoreModule
local StoreModule = Addon:LoadModule("Store");

---@type ConstantsModule
local ConstantsModule = Addon:LoadModule("Constants");

---@class SettingsModule: Module
local Module = Addon:RegisterModule("Settings");

StoreModule:RegisterModule("Settings", StoreModule.Scopes.Acocunt, function() end);

local Constants = ConstantsModule.Constants;

---@generic T: Primitive
---@param settingsKey string
---@param defaultValue T
---@return T
function Module:GetSettingOrDefault(settingsKey, defaultValue)
  return StoreModule:Get(Module.ModuleName, StoreModule.Scopes.Account, settingsKey, defaultValue);
end

---@type table<string, Setting>
local settings = {};

---@param enum table
---@param localizationKeyPrefix string
---@return DropDownOption[]
local function compileOptionsFromEnum(enum, localizationKeyPrefix)
  ---@type DropDownOption[]
  local options = {};

  for key, value in pairs(enum) do
    ---@type DropDownOption
    local option = {
      value = value,
      text = LocalizationModule:Get(localizationKeyPrefix .. key),
    }

    table.insert(options, option);
  end

  return options;
end

local quantityFormatOptions = compileOptionsFromEnum(Constants.QuantityFormat, "QuantityFormat");
local progressTypeOptions = compileOptionsFromEnum(Constants.ProgressType, "ProgressType");

---@param options DropDownOption[]
---@param value Primitive
---@return DropDownOption
local function getDropDownOption(options, value)
  for _, option in ipairs(options) do
    if option.value == value then
      return option
    end
  end
  error("Option Not Found");
end

---@param dropDown DropDownFrame
---@param newValue Primitive
local function setDropDown(dropDown, newValue)
  dropDown.value = newValue;
  local option = getDropDownOption(dropDown.options, newValue);
  LibDD:UIDropDownMenu_SetText(dropDown, option.text);
end

---@param dropDown DropDownFrame
---@param options DropDownOption[]
local function initializeDropDownOptions(dropDown, options)
  for _, option in ipairs(options) do
    local function onSelect(_, value)
      setDropDown(dropDown, value);
    end

    local info = LibDD:UIDropDownMenu_CreateInfo();
    info.text = option.text;
    info.func = onSelect;
    info.notCheckable = true;
    info.arg1 = option.value;
    LibDD:UIDropDownMenu_AddButton(info);
  end
end

---@param parentFrame Frame
---@param labelText string
---@param options DropDownOption[]
---@return DropDownFrame
local function createDropDownWithLabel(parentFrame, labelText, options)
  local dropDownFrame = LibDD:Create_UIDropDownMenu(nil, parentFrame);
  dropDownFrame.Label = dropDownFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
  dropDownFrame.Label:SetText(labelText);
  dropDownFrame.Label:SetPoint("BOTTOMLEFT", dropDownFrame, "TOPLEFT", 20, 0);
  initializeDropDownOptions(dropDownFrame, options);
  return dropDownFrame;
end

---@return Frame
local function createDefaultsButtonFrame()
  local frame = CreateFrame("Button", nil, nil, "UIPanelButtonTemplate");
  frame:SetSize(96, 22);
  frame:SetPoint("TOPRIGHT", -36, -16);
  frame:SetText(SETTINGS_DEFAULTS);

  frame:SetScript("OnClick", function()
    ShowAppropriateDialog("GAME_SETTINGS_APPLY_DEFAULTS");
  end);

  return frame;
end

---@return Frame
local function createInputBlockerFrame()
  local frame = CreateFrame("Button");
  frame:SetAllPoints();
  frame:SetHidden(true);
  frame:SetClipsChildren(true);
  return frame;
end

---@param frame Frame
---@return FontString
local function createPanelOptionsLabel(frame)
  local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  label:SetPoint("TOPLEFT", 16, -16);
  label:SetText(LocalizationModule:Get("PanelOptions"));
  return label;
end

---@param text string
---@return Frame
local function createCheckButton(text)
  local frame = CreateFrame("CheckButton", nil, nil, "UICheckButtonTemplate");
  frame.Text:SetText(text);

  frame:SetScript("OnClick", function()
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
  end);

  return frame;
end

---@param anchorFrame Frame
---@return Frame
local function createIncludeCurrentCharacterButton(anchorFrame)
  local frame = createCheckButton(LocalizationModule:Get("IncludeCurrentCharacter"));
  frame:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -10);

  frame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:AddLine(LocalizationModule:Get("IncludeCurrentCharacterDescription1"), nil, nil, nil, true);
    GameTooltip:AddLine(LocalizationModule:Get("IncludeCurrentCharacterDescription2"), 1, 1, 1, true);
    GameTooltip:Show();
  end);

  frame:SetScript("OnLeave", GameTooltip_Hide);
  return frame;
end

---@param anchorFrame Frame
---@return Frame
local function createIncludeAllCharactersButton(anchorFrame)
  local frame = createCheckButton(LocalizationModule:Get("IncludeAllCharactersFromThisRealm"));
  frame:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, 0);

  frame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:AddLine(LocalizationModule:Get("IncludeAllCharactersDescription1"), nil, nil, nil, true);
    GameTooltip:AddLine(LocalizationModule:Get("IncludeAllCharactersDescription2"), 1, 1, 1, true);
    GameTooltip:Show();
  end);

  frame:SetScript("OnLeave", GameTooltip_Hide);
  return frame;
end

---@param anchorFrame Frame
---@return Frame
local function createCumulateLowerQualitiesButton(anchorFrame)
  local frame = createCheckButton(LocalizationModule:Get("CumulateLowerQualities"));
  frame:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -10);
  return frame;
end

---@param anchorFrame Frame
---@return Frame
local function createShowObjectiveNotificationsButton(anchorFrame)
  local frame = createCheckButton(LocalizationModule:Get("ShowProgressNotifications"));
  frame:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -10);

  frame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:AddLine(LocalizationModule:Get("ShowProgressNotificationsDescription"), nil, nil, nil, true);
    GameTooltip:Show();
  end);

  frame:SetScript("OnLeave", GameTooltip_Hide);
  return frame;
end

---@param anchorFrame Frame
---@return Frame
local function createPlaySoundsButton(anchorFrame)
  local frame = createCheckButton(LocalizationModule:Get("PlaySounds"));
  frame:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -10);

  frame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:AddLine(LocalizationModule:Get("PlaySoundsDescription"), nil, nil, nil, true);
    GameTooltip:Show();
  end);

  frame:SetScript("OnLeave", GameTooltip_Hide);
  return frame;
end

---@return PanelOptionsFrame
local function createPanelOptionsFrame()
  ---@class PanelOptionsFrame: Frame
  local frame = CreateFrame("Frame");
  frame:SetSize(0, 240);
  frame:SetPoint("TOPLEFT", 0, 0);
  frame:SetPoint("TOPRIGHT", 0, 0);
  frame.Label = createPanelOptionsLabel(frame);
  frame.IncludeCurrentCharacterButton = createIncludeCurrentCharacterButton(frame.Label);
  frame.IncludeAllCharactersButton = createIncludeAllCharactersButton(frame.IncludeCurrentCharacterButton);
  frame.CumulateLowerQualitiesButton = createCumulateLowerQualitiesButton(frame.IncludeAllCharactersButton);
  frame.ShowObjectiveNotificationsButton = createShowObjectiveNotificationsButton(frame.CumulateLowerQualitiesButton);
  frame.PlaySoundsButton = createPlaySoundsButton(frame.ShowObjectiveNotificationsButton);
  frame.QuantityFormatDropDown = createDropDownWithLabel(frame, LocalizationModule:Get("QuantityFormat"), quantityFormatOptions);
  frame.QuantityFormatDropDown:SetPoint("TOPLEFT", frame.PlaySoundsButton, "BOTTOMLEFT", -12, -17);
  frame.ProgressTypeDropDown = createDropDownWithLabel(frame, LocalizationModule:Get("ProgressType"), progressTypeOptions);
  frame.ProgressTypeDropDown:SetPoint("TOPLEFT", frame.QuantityFormatDropDown, "TOPRIGHT", 60, 0);
  return frame;
end

---@param frame Frame
---@return FontString
local function createTrackerOptionsLabel(frame)
  local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  label:SetPoint("TOPLEFT", 16, -16);
  label:SetText(LocalizationModule:Get("TrackerOptions"));
  return label;
end

---@param anchorFrame Frame
---@return Frame
local function createShowTrackerButton(anchorFrame)
  local frame = createCheckButton(LocalizationModule:Get("ShowTracker"));
  frame:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -10);
  return frame;
end

---@param anchorFrame Frame
---@return Frame
local function createShowObjectiveTrackerButton(anchorFrame)
  local frame = createCheckButton(LocalizationModule:Get("ShowObjectiveTracker"));
  frame:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, 0);
  return frame;
end

---@param anchorFrame Frame
---@return TrackerOptionsFrame
local function createTrackerOptionsFrame(anchorFrame)
  ---@class TrackerOptionsFrame: Frame
  local frame = CreateFrame("Frame");
  frame:SetSize(330, 400);
  frame:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -20);
  frame.Label = createTrackerOptionsLabel(frame);
  frame.ShowTrackerButton = createShowTrackerButton(frame.Label);
  frame.ShowObjectiveTrackerButton = createShowObjectiveTrackerButton(frame.ShowTrackerButton);
  frame.QuantityFormatDropDown = createDropDownWithLabel(frame, LocalizationModule:Get("QuantityFormat"), quantityFormatOptions);
  frame.QuantityFormatDropDown:SetPoint("TOPLEFT", frame.ShowObjectiveTrackerButton, "BOTTOMLEFT", -12, -17);
  frame.ProgressTypeDropDown = createDropDownWithLabel(frame, LocalizationModule:Get("ProgressType"), progressTypeOptions);
  frame.ProgressTypeDropDown:SetPoint("TOPLEFT", frame.QuantityFormatDropDown, "TOPRIGHT", 60, 0);
  return frame;
end

---@return ScrollBoxFrame
local function createScrollBoxFrame()
  ---@class ScrollBoxFrame: Frame
  local frame = CreateFrame("Frame", nil, nil, "WowScrollBox");
  frame:SetAllPoints();
  frame.InputBlocker = createInputBlockerFrame();
  frame.PanelOptions = createPanelOptionsFrame();
  frame.TrackerOptions = createTrackerOptionsFrame(frame.TrackerOptions);
  return frame;
end

---@param scrollBox Frame
---@return Frame
local function createScrollBarFrame(scrollBox)
  local frame = CreateFrame("EventFrame", nil, nil, "MinimalScrollBar");
  frame:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 0, -4);
  frame:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", -1, -3);
  return frame;
end

---@return SettingsFrame
local function createFrame()
  ---@class SettingsFrame: Frame
  local frame = CreateFrame("Frame");
  frame.DefaultsButton = createDefaultsButtonFrame();
  frame.ScrollBox = createScrollBoxFrame();
  frame.ScrollBar = createScrollBarFrame(frame.ScrollBox);
  return frame;
end

local settingsFrame = createFrame();

---@param settingsKey string
---@param setting Setting
local function setSetting(settingsKey, setting)
  local value = setting.GetValue();
  StoreModule:Commit(Module.ModuleName, StoreModule.Scopes.Account, settingsKey, value);
  setting.UpdateFrame(value);
end

function settingsFrame:OnCommit()
  for settingsKey, setting in pairs(settings) do
    setSetting(settingsKey, setting);
  end

  Addon:Reset();
end

function settingsFrame:OnCancel() end;

---@param settingsKey string
---@param setting Setting
local function setDefault(settingsKey, setting)
  StoreModule:Commit(Module.ModuleName, StoreModule.Scopes.Account, settingsKey, setting.DefaultValue);
  setting.UpdateFrame(setting.DefaultValue);
end

function settingsFrame:OnDefault()
  for settingsKey, setting in pairs(settings) do
    setDefault(settingsKey, setting);
  end

  Addon:Reset();
end

local category, layout = Settings.RegisterCanvasLayoutCategory(settingsFrame, "Gather Panel");
layout:AddAnchorPoint("TOPLEFT", 10, -10);
layout:AddAnchorPoint("BOTTOMRIGHT", -10, 10);
Settings.RegisterAddOnCategory(category);

function Module:OpenGameSettings()
  Settings.OpenToCategory(category:GetID());
end

---@generic T: Primitive
---@param settingsKey string
---@param frame Frame
---@param frameType "CheckButton" | "DropDown"
---@param defaultValue T
---@param updateFunc fun(frame: Frame, newValue: T)
---@param getValueFunc fun(frame: Frame): T
---@return T
local function registerSetting(settingsKey, frame, frameType, defaultValue, updateFunc, getValueFunc)
  settings[settingsKey] = {
    Frame = frame,
    Type = type(defaultValue),
    FrameType = frameType,
    DefaultValue = defaultValue,
    UpdateFrame = function(newValue)
      updateFunc(frame, newValue);
    end,
    GetValue = function()
      return getValueFunc(frame);
    end,
  }

  local storedValue = Module:GetSettingOrDefault(settingsKey, defaultValue);
  updateFunc(frame, storedValue);
  return storedValue;
end

---@param settingsKey string
---@param checkButton Frame
---@param defaultValue Primitive
local function registerCheckBoxSetting(settingsKey, checkButton, defaultValue)
  local function updateFunc(_checkButton, newValue)
    _checkButton:SetChecked(newValue);
  end

  local function getValueFunc(_checkButton)
    return _checkButton:GetChecked();
  end

  registerSetting(settingsKey, checkButton, "CheckButton", defaultValue, updateFunc, getValueFunc);
end

---@param settingsKey string
---@param dropDown Frame
---@param defaultValue Primitive
local function registerDropDownSetting(settingsKey, dropDown, defaultValue)
  local function getValueFunc(_dropDown)
    return _dropDown.value;
  end

  registerSetting(settingsKey, dropDown, "DropDown", defaultValue, setDropDown, getValueFunc);
end

local function registerPanelOptionsSettings()
  local optionsFrame = settingsFrame.ScrollBox.PanelOptions;
  registerCheckBoxSetting("IncludeCurrentCharacter", optionsFrame.IncludeCurrentCharacterButton, true);
  registerCheckBoxSetting("IncludeAllCharactersFromThisRealm", optionsFrame.IncludeAllCharactersButton, false);
  registerCheckBoxSetting("ShowObjectiveNotifications", optionsFrame.ShowObjectiveNotificationsButton, true);
  registerCheckBoxSetting("PlaySounds", optionsFrame.PlaySoundsButton, true);
  registerCheckBoxSetting("CumulateLowerQualities", optionsFrame.CumulateLowerQualitiesButton, true);
  registerDropDownSetting("OverviewQuantityFormat", optionsFrame.QuantityFormatDropDown, Constants.QuantityFormat.Percent);
  registerDropDownSetting("OverviewProgressType", optionsFrame.ProgressTypeDropDown, Constants.ProgressType.FillToNextGoal);
end

local function registerTrackerOptionsSettings()
  local optionsFrame = settingsFrame.ScrollBox.TrackerOptions;
  registerCheckBoxSetting("ShowTracker", optionsFrame.ShowTrackerButton, false);
  registerCheckBoxSetting("ShowObjectiveTracker", optionsFrame.ShowObjectiveTrackerButton, true);
  registerDropDownSetting("TrackerQuantityFormat", optionsFrame.QuantityFormatDropDown, Constants.QuantityFormat.Percent);
  registerDropDownSetting("TrackerProgressType", optionsFrame.ProgressTypeDropDown, Constants.ProgressType.FillToMaximum);
end

local function registerSettings()
  registerPanelOptionsSettings();
  registerTrackerOptionsSettings();
end

function Module:Init()
  registerSettings();
end
