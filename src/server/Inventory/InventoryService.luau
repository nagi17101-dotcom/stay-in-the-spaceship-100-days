-- InventoryService: shared crew materials. Atomic, idempotent debits/credits keyed by server txId.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config.GameConfig)

local Inventory = {}
Inventory.__index = Inventory

function Inventory.new(startingFactor: number)
	local self = setmetatable({}, Inventory)
	self.factor = startingFactor
	self.items = {}
	self.applied = {}
	self.Changed = Instance.new("BindableEvent")
	self:Reset()
	return self
end

function Inventory:Reset()
	for _, m in ipairs(Config.Materials) do
		self.items[m.id] = math.floor((Config.StartingMaterials[m.id] or 0) * self.factor + 0.5)
	end
	self.applied = {}
	self.Changed:Fire(self:Snapshot())
end

function Inventory:Has(cost): boolean
	for id, n in pairs(cost) do
		if (self.items[id] or 0) < n then return false end
	end
	return true
end

function Inventory:TryDebit(cost, txId: string): boolean
	if self.applied[txId] or not self:Has(cost) then return false end
	self.applied[txId] = true
	for id, n in pairs(cost) do self.items[id] -= n end
	self.Changed:Fire(self:Snapshot())
	return true
end

function Inventory:Credit(items, txId: string): boolean
	if self.applied[txId] then return false end
	self.applied[txId] = true
	for id, n in pairs(items) do
		if self.items[id] ~= nil and n > 0 then self.items[id] += n end
	end
	self.Changed:Fire(self:Snapshot())
	return true
end

function Inventory:Snapshot()
	return table.clone(self.items)
end

return Inventory
