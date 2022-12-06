local _, addon = ...;
local module = addon:RegisterModule("Settings");
local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0");

---@enum SettingScope
local SettingScope = {
  user = "user",
  global = "global",
}


---@enum SettingsFrameType
local SettingsFrameType = {
  CheckButton = "CheckButton",
  DropDown = "DropDown",
}


---@class SettingConfig
---@field frame Frame
---@field type type
---@field defaultVal any
---@field scope SettingScope
---@field identifier string
---@field frameType SettingsFrameType


---@class DropDownOption<T>: { value: T, text: string }

---@type table<string, SettingConfig>
local settings = {}


local function compileOptions(enum, translationPrefix)
  ---@type table<DropDownOption>
  local options = {};
  for key, val in pairs(enum) do
    table.insert(
      options,
      {
        value = val,
        text = addon.T[translationPrefix .. '_' .. key];
      }
    )
  end
  return options;
end


local countFormatOptions = compileOptions(addon.Variables.const.COUNT_FORMAT, "COUNT_FORMAT");
local progressFormatOptions = compileOptions(addon.Variables.const.PROGRESS_FORMAT, "PROGRESS_FORMAT");


local function getSettingsTable(scope)
  if scope == SettingScope.global then
    return addon.Variables.global;
  elseif scope == SettingScope.user then
    return addon.Variables.user;
  end
end


local function saveConfig(identifier, scope, value)
  local settingsTable = getSettingsTable(scope);
  settingsTable[identifier] = value;
  return settingsTable[identifier];
end


local function saveDefaultIfNotSet(identifier, scope, value)
  local settingsTable = getSettingsTable(scope);
  if settingsTable[identifier] == nil then
    settingsTable[identifier] = value;
  end
  return settingsTable[identifier];
end


local function setCheckBox(frame, value)
  frame:SetChecked(value);
end



---@param options table<DropDownOption>
---@param value any
local function getOption(options, value)
  for _, option in ipairs(options) do
    if option.value == value then
      return option
    end
  end
end


---@param frame Frame
local function setDropDown(frame, value)
  frame.value = value;
  local option = getOption(frame.options, frame.value);
  LibDD:UIDropDownMenu_SetText(frame, option.text);
  LibDD:UIDropDownMenu_SetWidth(frame, 160);
end


---@param identifier string
---@param scope SettingScope
---@param frame Frame
---@param defaultVal boolean
local function registerCheckBoxSetting(identifier, scope, frame, defaultVal)
  settings[scope .. '.' .. identifier] = {
    frame = frame,
    type = type(defaultVal),
    defaultVal = defaultVal,
    scope = scope,
    identifier = identifier,
    frameType = "CheckButton"
  }

  local value = saveDefaultIfNotSet(identifier, scope, defaultVal);
  setCheckBox(frame, value);
end


---@param options table<DropDownOption>
local function registerDropDownSetting(identifier, scope, frame, defaultVal, options)
  local function initializeOptions()
    for _, option in ipairs(options) do

      local function onSelect(_, value)
        setDropDown(frame, value)
      end

      local info = LibDD:UIDropDownMenu_CreateInfo();
      info.text = option.text;
      info.func = onSelect;
      info.notCheckable = true;
      info.arg1 = option.value;
      LibDD:UIDropDownMenu_AddButton(info);
    end
  end

  settings[scope .. '..' .. identifier] = {
    frame = frame,
    type = type(defaultVal),
    defaultVal = defaultVal,
    scope = scope,
    identifier = identifier,
    frameType = "DropDown"
  }

  LibDD:UIDropDownMenu_Initialize(frame, initializeOptions);

  local value = saveDefaultIfNotSet(identifier, scope, defaultVal);
  frame.options = options;
  setDropDown(frame, value);
end


local function registerSettings(frame)
  local panelOptionsFrame = frame.ScrollBox.PanelOptions;
  local trackerOptionsFrame = frame.ScrollBox.TrackerOptions;

  registerCheckBoxSetting("includeCurrentCharacter", SettingScope.user, panelOptionsFrame.IncludeCurrentCharacterButton, true);
  registerCheckBoxSetting("includeAllFromRealm", SettingScope.user, panelOptionsFrame.ShowOfflineButton, false);
  registerCheckBoxSetting("showObjectiveText", SettingScope.global, panelOptionsFrame.ShowObjectiveText, true);
  registerCheckBoxSetting("playSounds", SettingScope.global, panelOptionsFrame.PlaySounds, true);
  registerCheckBoxSetting("trackerVisible", SettingScope.user, trackerOptionsFrame.ShowTrackerButton, true);
  registerCheckBoxSetting("showObjectiveTracker", SettingScope.user, trackerOptionsFrame.ShowObjectiveTrackerButton, true);

  registerDropDownSetting("panelCountFormat", SettingScope.global, panelOptionsFrame.CountFormat, addon.Variables.const.COUNT_FORMAT.PERCENT, countFormatOptions);
  registerDropDownSetting("trackerCountFormat", SettingScope.global, trackerOptionsFrame.CountFormat, addon.Variables.const.COUNT_FORMAT.PERCENT, countFormatOptions);
  registerDropDownSetting("panelProgressFormat", SettingScope.global, panelOptionsFrame.ProgressFormat, addon.Variables.const.PROGRESS_FORMAT.FILL_TO_GOAL, progressFormatOptions);
  registerDropDownSetting("trackerProgressFormat", SettingScope.global, trackerOptionsFrame.ProgressFormat, addon.Variables.const.PROGRESS_FORMAT.FILL_TO_MAXIMUM, progressFormatOptions);

end



local function apply()
  GatherPanel_UpdateItems(false);
  GatherPanel_Tracker_Update();
  GatherPanel_UpdatePanel();
  addon.ObjectiveTracker:FullUpdate();
end



---@param setting SettingConfig
local function setCheckBoxSetting(setting)
  local value = setting.frame:GetChecked();
  saveConfig(setting.identifier, setting.scope, value);
end



---@param setting SettingConfig
local function setDropDownSetting(setting)
  local value = setting.frame.value;
  local res = saveConfig(setting.identifier, setting.scope, value);
  setDropDown(setting.frame, res);
end



---@param setting SettingConfig
local function setSetting(setting)
  if setting.frameType == SettingsFrameType.CheckButton then
    setCheckBoxSetting(setting);
  elseif setting.frameType == SettingsFrameType.DropDown then
    setDropDownSetting(setting);
  end
end


---@param setting SettingConfig
local function setDefault(setting)
  local settingsTable = getSettingsTable(setting.scope);
  settingsTable[setting.identifier] = setting.defaultVal;
  if setting.frameType == SettingsFrameType.CheckButton then
    setCheckBox(setting.frame, setting.defaultVal);
  elseif setting.frameType == SettingsFrameType.DropDown then
    setDropDown(setting.frame, setting.defaultVal);
  end
end


local frame = CreateFrame("Frame", nil, nil, "GatherPanel_Settings_FrameTemplate");
frame.DefaultsButton:SetText(SETTINGS_DEFAULTS);
frame.DefaultsButton:SetScript("OnClick", function(button, buttonName, down)
  ShowAppropriateDialog("GAME_SETTINGS_APPLY_DEFAULTS");
end);

local function createDropDownWithLabel(parentFrame, labelText)
  local dropDownFrame = LibDD:Create_UIDropDownMenu(nil, parentFrame);
  dropDownFrame.Label = dropDownFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
  dropDownFrame.Label:SetText(labelText);
  dropDownFrame.Label:SetPoint("BOTTOMLEFT", dropDownFrame, "TOPLEFT", 20, 0);
  return dropDownFrame;
end

function frame:CreatePanelOptionsDropDowns()
  local sectionFrame = self.ScrollBox.PanelOptions;

  sectionFrame.CountFormat = createDropDownWithLabel(sectionFrame, addon.T["STOCK_COUNT_FORMAT"]);
  sectionFrame.CountFormat:SetPoint("TOPLEFT", sectionFrame.PlaySounds, "BOTTOMLEFT", -12, -17);

  sectionFrame.ProgressFormat = createDropDownWithLabel(sectionFrame, addon.T["PROGRESS_TYPE"]);
  sectionFrame.ProgressFormat:SetPoint("TOPLEFT", sectionFrame.CountFormat, "TOPRIGHT", 60, 0);
end

function frame:CreateTrackerOptionsDropDowns()
  local sectionFrame = self.ScrollBox.TrackerOptions;

  sectionFrame.CountFormat = createDropDownWithLabel(sectionFrame, addon.T["STOCK_COUNT_FORMAT"]);
  sectionFrame.CountFormat:SetPoint("TOPLEFT", sectionFrame.ShowObjectiveTrackerButton, "BOTTOMLEFT", -12, -17);

  sectionFrame.ProgressFormat = createDropDownWithLabel(sectionFrame, addon.T["PROGRESS_TYPE"]);
  sectionFrame.ProgressFormat:SetPoint("TOPLEFT", sectionFrame.CountFormat, "TOPRIGHT", 60, 0);
end

frame:CreatePanelOptionsDropDowns();
frame:CreateTrackerOptionsDropDowns();



function frame:OnCommit()
  for _, setting in pairs(settings) do
    setSetting(setting);
  end
  apply();
end

function frame:OnCancel()
end

function frame:OnDefault()
  for _, setting in pairs(settings) do
    setDefault(setting);
  end
  apply();
end

local category, layout = Settings.RegisterCanvasLayoutCategory(frame, "Gather Panel");
layout:AddAnchorPoint("TOPLEFT", 10, -10);
layout:AddAnchorPoint("BOTTOMRIGHT", -10, 10);

Settings.RegisterAddOnCategory(category);

function module:Open()
  Settings.OpenToCategory(category:GetID());
end

function module:Init()
  registerSettings(frame);
end
