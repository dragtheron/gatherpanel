---@alias StoreValidationFunctions ScopedValidationFunction[]
---@alias ScopedValidationFunction ModuleValidationFunctions[]
---@alias ModuleValidationFunctions StoreValidationFunction[]
---@alias StoreValidationFunction fun(store: ModuleStore)

---@alias Store ScopedStore[]
---@alias ScopedStore ModuleStore[]
---@alias ModuleStore table<string, StoreVariable>
---@alias StoreVariable Primitive
