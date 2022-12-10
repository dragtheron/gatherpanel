---@type _, Addon
local _, Addon = ...;

---@class SoundsModule: Module
local Module = Addon:RegisterModule("Sounds");

---@type SettingsModule
local Settings = Addon:LoadModule("Settings");

---@param soundFile string | number
local function playSound(soundFile)
  PlaySound(soundFile);
end

---@param soundFile string | number
local function playOptionalSound(soundFile)
  if Settings:GetSettingOrDefault("PlaySounds", true) then
    playSound(soundFile);
  end
end

function Module:PlayAbandonQuest()
  playOptionalSound(SOUNDKIT.IG_QUEST_LOG_ABANDON_QUEST);
end

function Module:PlayQuestAccepted()
  playOptionalSound(618);
end

function Module:PlayTabSelect()
  playSound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
end

function Module:PlayCheckBoxSelect()
  playSound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
end

function Module:PlayProfessionWindowOpen()
  playSound(SOUNDKIT.UI_PROFESSIONS_WINDOW_OPEN);
end

function Module:PlayProfessionWindowClose()
  playSound(SOUNDKIT.UI_PROFESSIONS_WINDOW_CLOSE);
end

function Module:PlayQuestComplete()
  playOptionalSound(SOUNDKIT.IG_QUEST_LIST_COMPLETE);
end
