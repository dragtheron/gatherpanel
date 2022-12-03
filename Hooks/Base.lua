local _, addon = ...;
local module = addon:RegisterModule("Hooks_Base");

function module.Hook(table, func, callback)
  print("Hook enabled");
  if table and table[func] then
    hooksecurefunc(table, func, callback);
  else
    print("Hook could not found");
  end
end


function module.HookScript(table, func, callback)
  if table and table:HasScript(func) then
    table:HookScript(func, callback);
  end
end
