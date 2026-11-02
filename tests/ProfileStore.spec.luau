--[[
	ProfileStore / ProfileSchema unit tests (memory backend, no DataStore needed).
	Run in Studio Command Bar (Edit mode). Prints PASS/FAIL per case.
]]
local SSS = game:GetService("ServerScriptService")
local prog = SSS.Server.Progression
local tmp = Instance.new("Folder") tmp.Parent = SSS
local S = prog.ProfileSchema:Clone() S.Parent = tmp
local P = prog.ProfileStore:Clone() P.Parent = tmp
local Store, Schema = require(P), require(S)
local function check(name, cond) print((cond and "PASS " or "FAIL ") .. name) end

local mem = Store.MemoryBackend()
local a = Store.new(mem, "jobA")
local d = a:Load(1)
check("default profile created + locked", d and d.xp == 0 and d.sessionLock.jobId == "jobA")
d.xp = 120
check("save while owning lock", (a:Save(1, d, false)))
check("release clears lock", (a:Save(1, d, true)) and mem.data["u_1"].sessionLock == nil)
local d2 = a:Load(1)
check("reload keeps xp", d2 and d2.xp == 120)

local b = Store.new(mem, "jobB")
Store.LOAD_LOCK_TRIES = 1
local d3, why = b:Load(1)
check("second server blocked by fresh lock", d3 == nil and why == "Locked")
local okB, whyB = b:Save(1, { xp = 999 }, false)
check("second server cannot overwrite", okB == false and whyB == "LockLost" and mem.data["u_1"].xp == 120)
mem.data["u_1"].sessionLock.at = os.time() - 1000
local d4 = b:Load(1)
check("stale lock taken over", d4 ~= nil and d4.xp == 120 and mem.data["u_1"].sessionLock.jobId == "jobB")
local okA, whyA = a:Save(1, d2, false)
check("old owner now rejected (LockLost)", okA == false and whyA == "LockLost")

local flaky = Store.MemoryBackend(2)
local f = Store.new(flaky, "jobF") f.backoff = { 0.01 }
check("2 transient failures retried then loaded", f:Load(7) ~= nil and flaky.calls == 3)
local dead = Store.MemoryBackend(99)
local g = Store.new(dead, "jobG") g.backoff = { 0.01 }
local okG, errG = g:Save(8, Schema.Default(), true)
check("permanent outage reported as failure", okG == false and string.find(errG, "outage") ~= nil)

local m = Schema.Migrate({ xp = 300, level = 9 })
check("v0 migrated", m.schema == 1 and m.level == nil and m.stats.runs == 0 and m.xp == 300)
check("level curve", Schema.Level(0) == 1 and Schema.Level(49) == 1 and Schema.Level(50) == 2 and Schema.Level(200) == 3)
check("rank", Schema.Rank(1).id == "CrewCadet" and Schema.Rank(12).id == "Navigator")
Store.LOAD_LOCK_TRIES = 5
tmp:Destroy()
