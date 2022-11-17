local _, addon = ...;
addon.Variables = {};
local module = addon.Variables;

module.const = {
  ---@enum
  COUNT_FORMAT = {
    PERCENT = 0,
    ABSOLUTE = 1,
    NONE = 2,
  },
  ---@enum
  PROGRESS_FORMAT = {
    FILL_TO_GOAL = 0,
    FILL_TO_MAXIMUM = 1,
  }
}

module.global = {
  panelCountFormat = module.const.COUNT_FORMAT.PERCENT,
  panelProgressFormat = module.const.PROGRESS_FORMAT.FILL_TO_GOAL,
  trackerCountFormat = module.const.COUNT_FORMAT.PERCENT,
  trackerProgressFormat = module.const.PROGRESS_FORMAT.FILL_TO_MAXIMUM,
};

module.user = {
  trackerVisible = true,
  includeAllFromRealm = false,
  includeCurrentCharacter = true,
  minimapPosition = 90,
}

GATHERPANEL_SETTINGS_GLOBAL2 = module.global;
GATHERPANEL_SETTINGS_USER2 = module.user;
