local addonName, addon = ...;


function GatherPanel_Migrate_2_4_0()
  print("Updating Gather Panel to 2.5.0...");

  addon.Variables.global.showIds = false;

  local entries = {};
  for realm, realmList in pairs(GATHERPANEL_ITEMLISTS) do
    entries[realm] = {};
    for character, characterList in pairs(realmList) do
      entries[realm][character] = {};
      for _, entry in pairs(characterList) do
        table.insert(entries, entry);
      end
    end
  end
  addon.Variables.global.Entries = entries;
end
