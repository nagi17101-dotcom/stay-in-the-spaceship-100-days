-- RoomFX: local-only gentle brightness pulse for rooms in Critical (no network cost, no rainbow flicker).
local RoomFX = {}
local BASE = 2

function RoomFX.Start()
	local rooms = workspace:WaitForChild("Ship"):WaitForChild("Rooms")
	local pulsing = {}
	task.spawn(function()
		while true do
			local t = os.clock()
			for _, room in ipairs(rooms:GetChildren()) do
				local critical = room:GetAttribute("Mode") == "Critical"
				if critical or pulsing[room] then
					local b = critical and (BASE + 0.6 * math.sin(t * 3)) or BASE
					for _, d in ipairs(room:GetDescendants()) do
						if d:IsA("PointLight") then d.Brightness = b end
					end
					pulsing[room] = critical or nil
				end
			end
			task.wait(0.1)
		end
	end)
end

return RoomFX
