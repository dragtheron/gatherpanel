local addonName, addon = ...;


function GatherPanel_Migrate_2_7_0()
  GATHERPANEL_VARIABLES_USER.showCompleted = true;
  print("Gather Panel database ready for version 2.7.0!");
end
