---@type _, Addon
local _, Addon = ...;

---@class StoreModule: Module
local Module = Addon:RegisterModule("Store");

---@enum StoreScope
Module.Scopes = {
  "Account",
  "Character",
}

---@type Store
local store = {
  Account = {},
  Character = {},
}

---@type StoreValidationFunctions
local storeValidationFunctions = {
  Account = {},
  Character = {},
};

-- make store available for SavedVariables
GatherPanel_Account = store.Account;
GatherPanel_Character = store.Character;

function Module:Validate()
  for scope, scopedStore in pairs(store) do
    for moduleName, moduleStore in pairs(scopedStore) do
      local validationFunctions = storeValidationFunctions[scope][moduleName];
      for _, validationFunction in pairs(validationFunctions) do
        validationFunction(moduleStore);
      end
    end
  end
end

---@param scope StoreScope
---@return ScopedStore, ScopedValidationFunction
local function checkScope(scope)
  if store[scope] == nil then
    error("Invalid Scope");
  end

  if storeValidationFunctions[scope] == nil then
    error("Invalid Scope");
  end

  return store[scope], storeValidationFunctions[scope];
end

---@param moduleName string
---@param scope StoreScope
---@param validationFunc StoreValidationFunction
function Module:RegisterModule(moduleName, scope, validationFunc)
  local scopedStore, scopedValidationFunctions = checkScope(scope);

  if scopedStore[moduleName] == nil then
    scopedStore[moduleName] = {};
  end

  if scopedValidationFunctions[moduleName] == nil then
    scopedValidationFunctions[moduleName] = {};
  end

  -- allow multiple validation functions
  table.insert(scopedValidationFunctions[moduleName], validationFunc);
end

---@param moduleName string
---@param scope StoreScope
---@return ModuleStore
local function getRegisteredStore(moduleName, scope)
  local scoped = checkScope(scope);

  if scoped[moduleName] == nil then
    error("Module not Registered");
  end

  return scoped[moduleName];
end

---@param moduleName string
---@param scope StoreScope
---@param key string
---@param value Primitive
function Module:Commit(moduleName, scope, key, value)
  local moduleStore = getRegisteredStore(moduleName, scope);
  moduleStore[key] = value;
end

---@generic T: Primitive
---@param moduleName string
---@param scope StoreScope
---@param key string
---@param default T
---@return T
function Module:Get(moduleName, scope, key, default)
  local moduleStore = getRegisteredStore(moduleName, scope);
  local value = moduleStore[key];

  if value == nil then
    return default
  end

  return value;
end
