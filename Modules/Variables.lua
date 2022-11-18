local _, addon = ...;

local module, modules = addon:RegisterModule("Variables");

module.Constants = {
  CountFormat = {
    Percent = 0,
    Absolute = 1,
    None = 2,
  },
  ProgressTrackingMethod = {
    NextGoal = 0,
    Maximum = 1,
  },
};

module.SettingScopes = addon:Enum {
  "Account",
  "Character",
}

module.Settings = {
  Account = {},
  Character = {},
};
