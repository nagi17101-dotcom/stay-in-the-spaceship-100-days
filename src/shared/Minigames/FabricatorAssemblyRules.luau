-- M11 Fabricator Assembly rules (shared: client preview + server validation).
-- pub = { blueprint = {id,name,system,amount,cost,label}, upgrade = {cost,amount,label}?, maxLoad,
--         sockets = { {id, connector, lo, hi, needs = {ids}, optional?} }, parts = { {connector, size, mass} } }
-- action.steps = { {socket = "A", part = 3}, ... } in mounting order.
local Rules = {}

function Rules.SocketById(pub, id)
	for _, s in ipairs(pub.sockets) do if s.id == id then return s end end
	return nil
end

function Rules.Fits(socket, part): (boolean, string?)
	if part.connector ~= socket.connector then
		return false, ("Socket %s needs a %s connector."):format(socket.id, socket.connector)
	end
	if part.size < socket.lo or part.size > socket.hi then
		return false, ("Ø%d is outside socket %s tolerance Ø%d–%d."):format(part.size, socket.id, socket.lo, socket.hi)
	end
	return true
end

-- Returns ok, reason, message, state{ load, filled = {socketId = partIndex}, used = {partIndex = socketId}, upgrade }
function Rules.Evaluate(pub, steps)
	local st = { load = 0, filled = {}, used = {}, upgrade = false }
	for _, step in ipairs(steps) do
		local s = Rules.SocketById(pub, step.socket)
		local p = pub.parts[step.part]
		if not s or not p then return false, "Invalid", "Unknown socket or part.", st end
		if st.filled[s.id] then return false, "Occupied", ("Socket %s is already filled."):format(s.id), st end
		if st.used[step.part] then return false, "Reused", ("Part #%d is already mounted."):format(step.part), st end
		local fits, why = Rules.Fits(s, p)
		if not fits then return false, "Incompatible", why, st end
		for _, need in ipairs(s.needs) do
			if not st.filled[need] then
				return false, "Order", ("Socket %s must be mounted after %s."):format(s.id, need), st
			end
		end
		st.filled[s.id] = step.part
		st.used[step.part] = s.id
		st.load += p.mass
		if s.optional then st.upgrade = true end
	end
	for _, s in ipairs(pub.sockets) do
		if not s.optional and not st.filled[s.id] then
			return false, "Incomplete", ("Socket %s is still empty."):format(s.id), st
		end
	end
	if st.load > pub.maxLoad then
		return false, "Stress", ("Stress test failed: load %d/%d kg."):format(st.load, pub.maxLoad), st
	end
	return true, "Assembled", st.upgrade and "Stress test passed — reinforced part." or "Stress test passed.", st
end

-- Materials actually consumed for this assembly (blueprint + optional upgrade)
function Rules.TotalCost(pub, upgrade: boolean)
	local cost = table.clone(pub.blueprint.cost)
	if upgrade and pub.upgrade then
		for id, n in pairs(pub.upgrade.cost) do cost[id] = (cost[id] or 0) + n end
	end
	return cost
end

return Rules
