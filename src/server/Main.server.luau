local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local Lighting = game:GetService("Lighting")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local remotes = Instance.new("Folder")
remotes.Name = "OrbitRemotes"
remotes.Parent = ReplicatedStorage
local action = Instance.new("RemoteEvent")
action.Name = "Action"
action.Parent = remotes
local toast = Instance.new("RemoteEvent")
toast.Name = "Toast"
toast.Parent = remotes

local world = Instance.new("Folder")
world.Name = "ROT ORBIT"
world.Parent = workspace
local bases, states, rots = {}, {}, {}
local rng = Random.new()
local releaseCarry, returnStolen, lockBase

local function notify(player, text)
	if player.Parent then toast:FireClient(player, text) end
end
local function part(name, size, cf, color, material, parent)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame = name, size, cf
	p.Anchored, p.TopSurface, p.BottomSurface = true, Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Color, p.Material = color, material or Enum.Material.SmoothPlastic
	p.Parent = parent or world
	return p
end
local function label(parent, text, color, offset, width)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(width or 240, 76)
	gui.StudsOffset = offset or Vector3.new(0, 4, 0)
	gui.AlwaysOnTop, gui.MaxDistance = true, 130
	gui.Parent = parent
	local t = Instance.new("TextLabel")
	t.Size, t.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	t.Font, t.TextSize, t.Text = Enum.Font.GothamBold, 15, text
	t.TextColor3, t.TextStrokeTransparency = color or Color3.new(1, 1, 1), 0.3
	t.Parent = gui
	return t
end
local function prompt(parent, text, object, callback, hold)
	local p = Instance.new("ProximityPrompt")
	p.ActionText, p.ObjectText = text, object
	p.HoldDuration, p.MaxActivationDistance = hold or 0.25, 11
	p.RequiresLineOfSight = false
	p.Parent = parent
	p.Triggered:Connect(callback)
	return p
end
local function aliveRoot(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	return hum and hum.Health > 0 and char:FindFirstChild("HumanoidRootPart") or nil
end
local function near(player, target, distance)
	local root = aliveRoot(player)
	return root and (root.Position - target.Position).Magnitude <= (distance or 15)
end
local function money(player)
	return player.leaderstats.Money
end
local function refresh(player)
	local s = states[player]
	if not s then return end
	local total = 0
	for _, slot in ipairs(s.base.slots) do
		if slot.rot then total += Config.Rarities[slot.rot.info.Rarity].Income end
	end
	player:SetAttribute("Income", total * Config.Multiplier(s.level, player.leaderstats.Rebirths.Value))
	player:SetAttribute("UpgradeCost", Config.UpgradeCost(s.level))
	player:SetAttribute("RebirthCost", Config.RebirthCost(player.leaderstats.Rebirths.Value))
	player:SetAttribute("Multiplier", Config.Multiplier(s.level, player.leaderstats.Rebirths.Value))
end
local function slotLabel(slot)
	if slot.rot then
		slot.text.Text = string.format("COLLECT $%d\n%s", math.floor(slot.bank), slot.rot.info.Name)
	elseif slot.reserved then
		slot.text.Text = string.format("STOLEN! TAG THE THIEF\n$%d still safe here", math.floor(slot.bank))
	else
		slot.text.Text = string.format("EMPTY • BANK $%d\nCarry a rot here!", math.floor(slot.bank))
	end
	if slot.prompt then slot.prompt.Enabled = not slot.rot and not slot.reserved end
end
local function hasSpace(base)
	for _, slot in ipairs(base.slots) do
		if not slot.rot and not slot.reserved then return true end
	end
	return false
end
local function destroyRot(rot)
	if rot.weld then rot.weld:Destroy() end
	rots[rot] = nil
	rot.model:Destroy()
end
local function collect(player, base)
	if base.owner ~= player or not near(player, base.collector, 18) then return end
	local sum = 0
	for _, slot in ipairs(base.slots) do
		sum += math.floor(slot.bank)
		slot.bank -= math.floor(slot.bank)
		slotLabel(slot)
	end
	if sum > 0 then money(player).Value += sum; notify(player, "+$" .. sum .. " collected!") end
end
local function mount(rot, cf, anchored)
	if rot.weld then rot.weld:Destroy(); rot.weld = nil end
	rot.body.Anchored = anchored
	rot.model:PivotTo(cf)
end
local function carry(player, rot, origin)
	local s, root = states[player], aliveRoot(player)
	if not s or s.carry or not root then return false end
	rot.mode, rot.carrier, rot.origin = "carry", player, origin
	rot.prompt.Enabled = false
	mount(rot, root.CFrame * CFrame.new(0, 4.5, 0), false)
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1, weld.Parent = root, rot.body, rot.body
	rot.weld, s.carry = weld, rot
	if origin then
		local glow = Instance.new("Highlight")
		glow.Name, glow.Adornee = "StolenCargo", rot.model
		glow.FillColor, glow.OutlineColor = Color3.fromRGB(255, 80, 110), Color3.fromRGB(255, 240, 100)
		glow.FillTransparency, glow.Parent = 0.45, rot.model
		rot.glow = glow
	end
	local hum = player.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed = origin and 13 or 16 end
	return true
end
local function clearCarrier(rot)
	if rot.glow then rot.glow:Destroy(); rot.glow = nil end
	local player = rot.carrier
	local s = player and states[player]
	if s then s.carry = nil end
	local hum = player and player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed = 16 end
	rot.carrier = nil
end
local function place(rot, player, slot)
	clearCarrier(rot)
	if rot.origin then
		rot.origin.reserved = nil
		slotLabel(rot.origin)
	end
	rot.origin, rot.mode, rot.owner, rot.slot = nil, "placed", player, slot
	slot.rot = rot
	mount(rot, slot.pad.CFrame * CFrame.new(0, 2.8, 0), true)
	rot.prompt.ActionText, rot.prompt.ObjectText = "Steal", rot.info.Name
	rot.prompt.Enabled = true
	slotLabel(slot)
	refresh(player)
end
returnStolen = function(rot)
	local origin, owner = rot.origin, rot.owner
	clearCarrier(rot)
	if origin and states[owner] and origin.reserved == rot then
		place(rot, owner, origin)
		notify(owner, "Your rot returned safely!")
	else destroyRot(rot) end
end
releaseCarry = function(player)
	local s = states[player]
	if not s or not s.carry then return end
	local rot = s.carry
	if rot.origin then returnStolen(rot) else clearCarrier(rot); destroyRot(rot) end
end

Lighting.ClockTime, Lighting.Brightness = 19, 2
Lighting.Ambient = Color3.fromRGB(105, 100, 145)
part("Cosmic Plaza", Vector3.new(180, 2, 150), CFrame.new(0, -1, 0), Color3.fromRGB(20, 23, 41))
part("Orbit Rail", Vector3.new(12, 0.6, 138), CFrame.new(0, 0.2, 0), Color3.fromRGB(50, 235, 233), Enum.Material.Neon)
for z = -64, 64, 8 do
	part("Rail arrow", Vector3.new(2, 0.12, 3), CFrame.new(0, 0.58, z) * CFrame.Angles(0, math.rad(45), 0), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
end
label(part("Welcome", Vector3.new(1, 1, 1), CFrame.new(0, 15, -68), Color3.fromRGB(90, 60, 180), Enum.Material.Neon), "ROT ORBIT\nBUY • PLACE • COLLECT • STEAL", Color3.fromRGB(120, 255, 245), Vector3.zero, 420)
for _, z in ipairs({ -57, 0, 57 }) do
	for i = 1, 24 do
		local angle = i * math.pi * 2 / 24
		local cf = CFrame.new(math.cos(angle) * 13, 12 + math.sin(angle) * 13, z) * CFrame.Angles(0, 0, angle + math.pi / 2)
		local p = part("Orbit Halo", Vector3.new(3.5, 0.35, 0.35), cf, Color3.fromRGB(162, 90, 255), Enum.Material.Neon)
		p.CanCollide = false
	end
end

for index = 1, 6 do
	local side = index <= 3 and -1 or 1
	local z = ((index - 1) % 3 - 1) * 43
	local center = Vector3.new(side * 48, 0, z)
	local color = Color3.fromHSV((index - 1) / 6, 0.6, 1)
	local base = { slots = {}, index = index, center = center, side = side, lockedUntil = 0, nextLock = 0 }
	bases[index] = base
	part("Base " .. index, Vector3.new(52, 0.5, 37), CFrame.new(center), Color3.fromRGB(35, 39, 63))
	for _, dz in ipairs({ -18.5, 18.5 }) do
		part("Base Wall", Vector3.new(52, 10, 1), CFrame.new(center + Vector3.new(0, 5, dz)), color, Enum.Material.Glass).Transparency = 0.45
	end
	part("Back Wall", Vector3.new(1, 10, 37), CFrame.new(center + Vector3.new(side * 26, 5, 0)), color, Enum.Material.Glass).Transparency = 0.45
	base.gate = part("Lock Shield", Vector3.new(1, 12, 36), CFrame.new(center + Vector3.new(-side * 26, 6, 0)), color, Enum.Material.ForceField)
	base.gate.Transparency, base.gate.CanCollide = 1, false
	base.sign = label(base.gate, "UNCLAIMED ORBIT", color, Vector3.new(0, 9, 0), 310)
	base.collector = part("Collect", Vector3.new(8, 0.5, 13), CFrame.new(center + Vector3.new(-side * 16, 0.5, 0)), Color3.fromRGB(95, 255, 153), Enum.Material.Neon)
	label(base.collector, "COLLECT ALL", Color3.fromRGB(140, 255, 175), Vector3.new(0, 2, 0))
	prompt(base.collector, "Collect", "Base earnings", function(player) collect(player, base) end)
	base.collector.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit:FindFirstAncestorOfClass("Model"))
		if player then collect(player, base) end
	end)
	local button = part("Lock Button", Vector3.new(4, 1, 4), CFrame.new(center + Vector3.new(-side * 16, 1, 12)), color, Enum.Material.Neon)
	label(button, "LOCK 30s", color, Vector3.new(0, 2, 0))
	prompt(button, "Lock Base", "30s shield / 60s cooldown", function(player) if base.owner == player then lockBase(player) end end)
	for slotIndex = 1, 6 do
		local dx = slotIndex <= 3 and 0 or side * 15
		local dz = ((slotIndex - 1) % 3 - 1) * 11
		local pad = part("Pedestal " .. slotIndex, Vector3.new(7, 1.2, 7), CFrame.new(center + Vector3.new(dx, 1, dz)), color)
		local slot = { pad = pad, bank = 0 }
		slot.text = label(pad, "EMPTY PEDESTAL\nCarry a rot here!", Color3.new(1, 1, 1), Vector3.new(0, 5.5, 0))
		table.insert(base.slots, slot)
		slot.prompt = prompt(pad, "Place", "Your empty pedestal", function(player)
			local s = states[player]
			if base.owner ~= player or not s or not s.carry or slot.rot or slot.reserved or not near(player, pad) then return end
			local rot, previousOwner = s.carry, s.carry.owner
			place(rot, player, slot)
			if previousOwner and previousOwner ~= player then notify(previousOwner, "A rot was stolen! Defend your orbit.") end
			notify(player, "Placed! Earnings collect at the green pad.")
		end)
	end
end

-- Each base has its own collision group: its owner can pass its shield.
for _, base in ipairs(bases) do
	local group = "OrbitBase" .. base.index
	PhysicsService:RegisterCollisionGroup(group)
	base.gate.CollisionGroup = group
	PhysicsService:CollisionGroupSetCollidable(group, group, false)
end
lockBase = function(player)
	local s = states[player]
	if not s then return end
	local base, now = s.base, workspace:GetServerTimeNow()
	if now < base.nextLock then notify(player, "Shield ready in " .. math.ceil(base.nextLock - now) .. "s"); return end
	base.lockedUntil, base.nextLock = now + Config.LockDuration, now + Config.LockCooldown
	base.gate.CanCollide, base.gate.Transparency = true, 0.25
	player:SetAttribute("LockReadyAt", base.nextLock)
	notify(player, "Orbit shield active for 30 seconds!")
end

local function createRot(info)
	local tier = Config.Rarities[info.Rarity]
	local model = Instance.new("Model")
	model.Name, model.Parent = info.Name, world
	local body = part("Body", Vector3.new(2.7, 2.6, 1.8), CFrame.new(), tier.Color, Enum.Material.SmoothPlastic, model)
	model.PrimaryPart = body
	local function detail(name, size, offset, color, shape)
		local p = part(name, size, CFrame.new(offset), color, Enum.Material.SmoothPlastic, model)
		if shape then p.Shape = shape end
		p.Anchored, p.CanCollide, p.Massless = false, false, true
		local w = Instance.new("WeldConstraint")
		w.Part0, w.Part1, w.Parent = body, p, body
		return p
	end
	body.CanCollide, body.Massless = false, true
	detail("Head", Vector3.new(2.5, 2.1, 2.1), Vector3.new(0, 2, 0), tier.Color, Enum.PartType.Ball)
	for _, x in ipairs({ -0.55, 0.55 }) do
		detail("Eye", Vector3.new(0.65, 0.8, 0.3), Vector3.new(x, 2.2, -0.95), Color3.new(1, 1, 1))
		detail("Pupil", Vector3.new(0.26, 0.4, 0.16), Vector3.new(x, 2.2, -1.15), Color3.fromRGB(20, 20, 35))
		detail("Moon Shoe", Vector3.new(1.2, 0.65, 2.3), Vector3.new(x * 1.5, -1.5, -0.2), Color3.fromRGB(245, 235, 255))
	end
	detail("Antenna", Vector3.new(0.3, 1.5, 0.3), Vector3.new(0, 3.6, 0), tier.Color)
	detail("Star", Vector3.new(0.8, 0.8, 0.8), Vector3.new(0, 4.4, 0), tier.Color, Enum.PartType.Ball).Material = Enum.Material.Neon
	label(body, string.format("%s\n%s • $%d • +$%d/s", info.Name, info.Rarity, tier.Price, tier.Income), tier.Color, Vector3.new(0, 6, 0), 300)
	local rot = { model = model, body = body, info = info, mode = "rail" }
	rots[rot] = true
	model:PivotTo(CFrame.new(0, 3, -66))
	rot.prompt = prompt(body, "Buy $" .. tier.Price, info.Name, function(player)
		local s = states[player]
		if not s or s.carry or not near(player, body) then return end
		if rot.mode == "rail" then
			if not hasSpace(s.base) then notify(player, "Your six pedestals are full!"); return end
			if money(player).Value < tier.Price then notify(player, "Need $" .. tier.Price .. " to buy this rot."); return end
			if carry(player, rot, nil) then money(player).Value -= tier.Price; notify(player, "Carry it to an empty pedestal in your base!") end
		elseif rot.mode == "placed" and rot.owner ~= player then
			if not hasSpace(s.base) then notify(player, "You need an empty pedestal before stealing!"); return end
			local ownerState = states[rot.owner]
			if not ownerState then return end
			if ownerState.base.lockedUntil > workspace:GetServerTimeNow() then notify(player, "This orbit is shielded!"); return end
			local slot = rot.slot
			if carry(player, rot, slot) then
				slot.rot, slot.reserved = nil, rot
				slotLabel(slot)
				refresh(rot.owner)
				notify(rot.owner, player.DisplayName .. " is stealing " .. info.Name .. "! Touch them!")
				notify(player, "ESCAPE! Place it at your base. Owner tags return it!")
			end
		end
	end, 0.5)
	return rot
end
local function randomCharacter()
	local roll, sum, chosen = rng:NextNumber(0, 100), 0, "Common"
	for _, name in ipairs(Config.TierOrder) do
		sum += Config.Rarities[name].Weight
		if roll <= sum then chosen = name; break end
	end
	local pool = {}
	for _, info in ipairs(Config.Characters) do if info.Rarity == chosen then table.insert(pool, info) end end
	return pool[rng:NextInteger(1, #pool)]
end

local function characterAdded(player, char)
	local s = states[player]
	if not s then return end
	local root = char:WaitForChild("HumanoidRootPart", 10)
	local hum = char:WaitForChild("Humanoid", 10)
	if not root or not hum or not states[player] then return end
	char:PivotTo(CFrame.new(s.base.center + Vector3.new(-s.base.side * 12, 5, 0)))
	local function setupPart(p)
		if p:IsA("BasePart") then
			p.CollisionGroup = "OrbitBase" .. s.base.index
			p.Touched:Connect(function(hit)
				local thief = Players:GetPlayerFromCharacter(hit:FindFirstAncestorOfClass("Model"))
				local ts = thief and states[thief]
				if ts and ts.carry and ts.carry.origin and ts.carry.owner == player then
					notify(thief, "Tagged! The rot returned to its owner.")
					returnStolen(ts.carry)
				end
			end)
		end
	end
	for _, p in ipairs(char:GetDescendants()) do setupPart(p) end
	char.DescendantAdded:Connect(setupPart)
	hum.Died:Connect(function() releaseCarry(player) end)
end
local function playerAdded(player)
	local base
	for _, candidate in ipairs(bases) do if not candidate.owner then base = candidate; break end end
	if not base then player:Kick("All six orbits are occupied. Please join another server!"); return end
	base.owner = player
	base.sign.Text = player.DisplayName .. "'S ORBIT\nBASE " .. base.index
	local stats = Instance.new("Folder")
	stats.Name, stats.Parent = "leaderstats", player
	local cash = Instance.new("IntValue")
	cash.Name, cash.Value, cash.Parent = "Money", Config.StartingMoney, stats
	local rebirths = Instance.new("IntValue")
	rebirths.Name, rebirths.Parent = "Rebirths", stats
	states[player] = { base = base, level = 0, lastAction = 0 }
	player:SetAttribute("BaseNumber", base.index)
	player:SetAttribute("LockReadyAt", 0)
	refresh(player)
	player.CharacterAdded:Connect(function(char) characterAdded(player, char) end)
	player.CharacterRemoving:Connect(function() releaseCarry(player) end)
	if player.Character then task.spawn(characterAdded, player, player.Character) end
end
Players.PlayerAdded:Connect(playerAdded)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(playerAdded, player) end
Players.PlayerRemoving:Connect(function(player)
	local s = states[player]
	if not s then return end
	releaseCarry(player)
	for rot in pairs(rots) do
		if rot.owner == player then
			if rot.carrier then clearCarrier(rot) end
			if rot.origin then rot.origin.reserved = nil end
			destroyRot(rot)
		end
	end
	for _, slot in ipairs(s.base.slots) do slot.rot, slot.reserved, slot.bank = nil, nil, 0; slotLabel(slot) end
	s.base.owner, s.base.lockedUntil, s.base.nextLock = nil, 0, 0
	s.base.gate.CanCollide, s.base.gate.Transparency = false, 1
	s.base.sign.Text = "UNCLAIMED ORBIT"
	states[player] = nil
end)
action.OnServerEvent:Connect(function(player, kind)
	local s = states[player]
	if not s or type(kind) ~= "string" or os.clock() - s.lastAction < 0.3 then return end
	s.lastAction = os.clock()
	if kind == "Lock" then lockBase(player)
	elseif kind == "Upgrade" then
		local cost = Config.UpgradeCost(s.level)
		if money(player).Value < cost then notify(player, "Upgrade needs $" .. cost); return end
		money(player).Value -= cost
		s.level += 1
		refresh(player)
		notify(player, "Income upgraded! +25% base income.")
	elseif kind == "Rebirth" then
		local rebirths = player.leaderstats.Rebirths
		if money(player).Value < Config.RebirthCost(rebirths.Value) then notify(player, "Collect more cash to rebirth!"); return end
		money(player).Value = Config.StartingMoney
		rebirths.Value += 1
		refresh(player)
		notify(player, "REBIRTH! Permanent +50% income. Your rots stay!")
	end
end)

RunService.Heartbeat:Connect(function(dt)
	for rot in pairs(rots) do
		if rot.mode == "rail" then
			local z = rot.body.Position.Z + Config.RailSpeed * dt
			if z > 69 then destroyRot(rot) else rot.model:PivotTo(CFrame.new(0, 3 + math.sin(os.clock() * 3 + z) * 0.15, z)) end
		end
	end
end)
task.spawn(function()
	-- A cheap first rot makes the opening playable regardless of random luck.
	createRot(Config.Characters[1])
	while true do task.wait(Config.SpawnInterval); createRot(randomCharacter()) end
end)
task.spawn(function()
	while true do
		local elapsed = task.wait(1)
		local now = workspace:GetServerTimeNow()
		for player, s in pairs(states) do
			local mult = Config.Multiplier(s.level, player.leaderstats.Rebirths.Value)
			for _, slot in ipairs(s.base.slots) do
				if slot.rot then slot.bank += Config.Rarities[slot.rot.info.Rarity].Income * mult * elapsed end
				slotLabel(slot)
			end
			if s.base.lockedUntil > 0 then
				local seconds = math.ceil(s.base.lockedUntil - now)
				if seconds <= 0 then
					s.base.lockedUntil = 0
					s.base.gate.CanCollide, s.base.gate.Transparency = false, 1
					s.base.sign.Text = player.DisplayName .. "'S ORBIT\nBASE " .. s.base.index
				else s.base.sign.Text = player.DisplayName .. "'S ORBIT\nSHIELDED " .. seconds .. "s" end
			end
		end
	end
end)
