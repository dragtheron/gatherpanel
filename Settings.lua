local _, addon = ...;
addon.Settings = {};
local module = addon.Settings;


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
  return value;
end


local function saveDefaultIfNotSet(identifier, scope, value)
  local settingsTable = getSettingsTable(scope);
  settingsTable[identifier] = settingsTable[identifier] or value;
  return value;
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
  UIDropDownMenu_SetText(frame, option.text);
  UIDropDownMenu_SetWidth(frame, 160);
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

      local info = UIDropDownMenu_CreateInfo();
      info.text = option.text;
      info.func = onSelect;
      info.notCheckable = true;
      info.arg1 = option.value;
      UIDropDownMenu_AddButton(info);
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

  UIDropDownMenu_Initialize(frame, initializeOptions);

  local value = saveDefaultIfNotSet(identifier, scope, defaultVal);
  frame.options = options;
  setDropDown(frame, value);
end


local function registerSettings(frame)
  registerCheckBoxSetting("includeCurrentCharacter", SettingScope.user, frame.PanelOptions.IncludeCurrentCharacterButton, true);
  registerCheckBoxSetting("includeAllFromRealm", SettingScope.user, frame.PanelOptions.ShowOfflineButton, false);
  registerCheckBoxSetting("showObjectiveText", SettingScope.global, frame.PanelOptions.ShowObjectiveText, true);
  registerCheckBoxSetting("playSounds", SettingScope.global, frame.PanelOptions.PlaySounds, true);
  registerCheckBoxSetting("trackerVisible", SettingScope.user, frame.TrackerOptions.ShowTrackerButton, true);
  registerDropDownSetting("panelCountFormat", SettingScope.global, frame.PanelOptions.CountFormat, addon.Variables.const.COUNT_FORMAT.PERCENT, countFormatOptions);
  registerDropDownSetting("trackerCountFormat", SettingScope.global, frame.TrackerOptions.CountFormat, addon.Variables.const.COUNT_FORMAT.PERCENT, countFormatOptions);
  registerDropDownSetting("panelProgressFormat", SettingScope.global, frame.PanelOptions.ProgressFormat, addon.Variables.const.PROGRESS_FORMAT.FILL_TO_GOAL, progressFormatOptions);
  registerDropDownSetting("trackerProgressFormat", SettingScope.global, frame.TrackerOptions.ProgressFormat, addon.Variables.const.PROGRESS_FORMAT.FILL_TO_MAXIMUM, progressFormatOptions);
end



local function apply()
  GatherPanel_UpdateItems(false);
  GatherPanel_Tracker_Update();
  GatherPanel_UpdatePanel();
end



---@param setting SettingConfig
local function setCheckBoxSetting(setting)
  local value = setting.frame:GetChecked();
  saveConfig(setting.identifier, setting.scope, value);
end



---@param setting SettingConfig
local function setDropDownSetting(setting)
  local value = setting.frame.value;
  saveConfig(setting.identifier, setting.scope, value);
  setDropDown(setting.frame, value);
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

registerSettings(frame);

local category, layout = Settings.RegisterCanvasLayoutCategory(frame, "Gather Panel");
layout:AddAnchorPoint("TOPLEFT", 10, -10);
layout:AddAnchorPoint("BOTTOMRIGHT", -10, 10);

Settings.RegisterAddOnCategory(category);



function module:Open()
  Settings.OpenToCategory(category:GetID());
end
