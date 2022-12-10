---@type _, Addon
local _, Addon = ...;

---@class ConstantsModule: Module
local Module = Addon:RegisterModule("Constants");

Module.Constants = {
  QuantityFormat = {
    Percent = 0,
    Absolute = 1,
    None = 2,
  },
  ProgressType = {
    FillToNextGoal = 0,
    FillToMaximum = 1,
  }
};
