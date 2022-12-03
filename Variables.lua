local _, addon = ...;
local module = addon:RegisterModule("Variables");

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
  Entries = {},
};

module.user = {
  minimapPosition = 90,
}
