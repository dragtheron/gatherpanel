local addonName, addon = ...;
local module = addon:RegisterModule("Sounds");


local function playSound(soundFile)
  PlaySound(soundFile);
end


local function playOptionalSound(soundFile)
  if addon.Variables.global.playSounds then
    playSound(soundFile);
  end
end


function module:PlayAbandonQuest()
  playOptionalSound(SOUNDKIT.IG_QUEST_LOG_ABANDON_QUEST);
end

function module:PlayQuestAccepted()
  playOptionalSound(618);
end

function module:PlayTabSelect()
  playSound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
end

function module:PlayCheckBoxSelect()
  playSound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
end

function module:PlayProfessionWindowOpen()
  playSound(SOUNDKIT.UI_PROFESSIONS_WINDOW_OPEN);
end

function module:PlayProfessionWindowClose()
  playSound(SOUNDKIT.UI_PROFESSIONS_WINDOW_CLOSE);
end

function module:PlayQuestComplete()
  playOptionalSound(SOUNDKIT.IG_QUEST_LIST_COMPLETE);
end
