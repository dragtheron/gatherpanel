local addonName, Addon = ...;


print("Before", Dump(Addon))

Addon.T = {
  ["Test"] = "Hey";
};

print("After", Dump(Addon));

-- setup localization
local function L_Default(L, key)
  return key;
end

setmetatable(Addon.T, { __index=L_Default });

-- global var for use in xml's
GATHERPANEL_T = Addon.T
