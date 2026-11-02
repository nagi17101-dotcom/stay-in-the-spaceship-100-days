-- ProfileStore: UpdateAsync-only persistence with retries, budget awareness and session locking.
-- Backends: DataStore (live) or Memory (Studio without API access / tests). Memory is NEVER reported as saved.
local DataStoreService = game:GetService("DataStoreService")
local Schema = require(script.Parent.ProfileSchema)

local Store = {}
Store.__index = Store

local DATASTORE_NAME = "PlayerProfiles_v1"
Store.LOCK_STALE_SECONDS = 300 -- autosave refreshes the lock every 120s; older locks belong to dead servers
Store.LOAD_LOCK_TRIES = 5
Store.RETRIES = 5

-- Backend contract: update(key, transform) -> newValue (transform may return nil to cancel the write)
local function dataStoreBackend(ds)
	return {
		persistent = true,
		update = function(key, transform) return ds:UpdateAsync(key, transform) end,
		waitBudget = function()
			local t0 = os.clock()
			while DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.UpdateAsync) < 1 and os.clock() - t0 < 10 do
				task.wait(1)
			end
		end,
	}
end

function Store.MemoryBackend(failFirst: number?)
	local data, fails = {}, failFirst or 0
	local b = { persistent = false, data = data, calls = 0 }
	b.update = function(key, transform)
		b.calls += 1
		if fails > 0 then fails -= 1 error("simulated DataStore outage") end
		local result = transform(Schema.DeepCopy(data[key]))
		if result ~= nil then data[key] = Schema.DeepCopy(result) end
		return result
	end
	b.waitBudget = function() end
	return b
end

-- Returns backend, reason
function Store.Detect()
	local ok, ds = pcall(function() return DataStoreService:GetDataStore(DATASTORE_NAME) end)
	if ok then
		local probeOk, err = pcall(function() return ds:GetAsync("__probe") end)
		if probeOk then return dataStoreBackend(ds), "DataStore" end
		return Store.MemoryBackend(), "DataStore unavailable: " .. tostring(err)
	end
	return Store.MemoryBackend(), "DataStore unavailable: " .. tostring(ds)
end

function Store.new(backend, jobId: string)
	return setmetatable({ backend = backend, jobId = jobId, backoff = { 1, 2, 4, 8 } }, Store)
end

function Store:_retry(fn)
	local lastErr
	for attempt = 1, Store.RETRIES do
		self.backend.waitBudget()
		local ok, result = pcall(fn)
		if ok then return true, result end
		lastErr = result
		if attempt < Store.RETRIES then task.wait(self.backoff[math.min(attempt, #self.backoff)]) end
	end
	return false, lastErr
end

local function key(userId: number) return "u_" .. userId end

-- Returns data (migrated, locked to this server) or nil, reason ("Locked" | error text)
function Store:Load(userId: number)
	for _ = 1, Store.LOAD_LOCK_TRIES do
		local loaded, lockedBy = nil, nil
		local ok, err = self:_retry(function()
			return self.backend.update(key(userId), function(old)
				local data = Schema.Migrate(old)
				local lock = data.sessionLock
				if lock and lock.jobId ~= self.jobId and os.time() - lock.at < Store.LOCK_STALE_SECONDS then
					lockedBy = lock.jobId
					return nil -- cancel: another live server owns this profile
				end
				data.sessionLock = { jobId = self.jobId, at = os.time() }
				loaded = data
				return data
			end)
		end)
		if not ok then return nil, tostring(err) end
		if loaded then return loaded end
		task.wait(3) -- other server should release on leave; wait and retry
	end
	return nil, "Locked"
end

-- Writes data if this server still owns the lock. release=true clears the lock (player leaving).
-- Returns ok, reason ("LockLost" | error text)
function Store:Save(userId: number, data, release: boolean)
	local lost = false
	local ok, err = self:_retry(function()
		return self.backend.update(key(userId), function(old)
			local current = Schema.Migrate(old)
			if current.sessionLock and current.sessionLock.jobId ~= self.jobId then
				lost = true
				return nil -- never clobber another server's session
			end
			local out = Schema.DeepCopy(data)
			out.sessionLock = (not release) and { jobId = self.jobId, at = os.time() } or nil
			out.updatedAt = os.time()
			return out
		end)
	end)
	if not ok then return false, tostring(err) end
	if lost then return false, "LockLost" end
	return true
end

return Store
