local addonName, addon = ...;


function GatherPanel_Migrate_2_4_0()
  print("Updating Gather Panel to 2.4.0...");
  GATHERPANEL_VARIABLES_GLOBAL = GATHERPANEL_SETTINGS_GLOBAL;
  GATHERPANEL_VARIABLES_USER = GATHERPANEL_SETTINGS;
  addon.Variables.global.minimapPosition = 90;
end
