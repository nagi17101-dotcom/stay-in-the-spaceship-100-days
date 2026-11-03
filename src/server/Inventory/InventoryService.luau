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

-- Returns applied, overflow (materials discarded because the cargo hold is at Config.MaterialCap)
function Inventory:Credit(items, txId: string): (boolean, {[string]: number}?)
	if self.applied[txId] then return false, nil end
	self.applied[txId] = true
	local overflow = nil
	for id, n in pairs(items) do
		if self.items[id] ~= nil and n > 0 then
			local cap = Config.MaterialCap and Config.MaterialCap[id] or math.huge
			local add = math.max(0, math.min(n, cap - self.items[id]))
			self.items[id] += add
			if add < n then
				overflow = overflow or {}
				overflow[id] = n - add
			end
		end
	end
	self.Changed:Fire(self:Snapshot())
	return true, overflow
end

function Inventory:Snapshot()
	return table.clone(self.items)
end

return Inventory
