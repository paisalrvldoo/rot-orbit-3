local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("OrbitRemotes")
local action, toast = remotes:WaitForChild("Action"), remotes:WaitForChild("Toast")
local stats = player:WaitForChild("leaderstats")
local money, rebirths = stats:WaitForChild("Money"), stats:WaitForChild("Rebirths")
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset = "OrbitHUD", false, false
gui.Parent = player:WaitForChild("PlayerGui")
local function round(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius, c.Parent = UDim.new(0, radius or 12), parent
end
local function text(parent, size, pos, value, color)
	local t = Instance.new("TextLabel")
	t.Size, t.Position = size, pos
	t.BackgroundTransparency, t.TextScaled, t.TextWrapped = 1, true, true
	t.Font, t.Text, t.TextColor3 = Enum.Font.GothamBold, value, color or Color3.new(1, 1, 1)
	t.Parent = parent
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize, limit.MaxTextSize, limit.Parent = 10, 25, t
	return t
end
local panel = Instance.new("Frame")
panel.Size, panel.Position = UDim2.fromScale(0.36, 0.2), UDim2.fromScale(0.025, 0.035)
panel.BackgroundColor3, panel.BackgroundTransparency = Color3.fromRGB(16, 19, 38), 0.08
panel.Parent = gui
round(panel)
text(panel, UDim2.fromScale(0.9, 0.22), UDim2.fromScale(0.05, 0.07), "ROT ORBIT", Color3.fromRGB(103, 255, 238))
local cashText = text(panel, UDim2.fromScale(0.9, 0.28), UDim2.fromScale(0.05, 0.32), "$100", Color3.fromRGB(139, 255, 159))
local incomeText = text(panel, UDim2.fromScale(0.9, 0.18), UDim2.fromScale(0.05, 0.65), "+$0 / sec")
local baseText = text(panel, UDim2.fromScale(0.9, 0.14), UDim2.fromScale(0.05, 0.84), "Find your orbit")
local buttons = {}
for index, entry in ipairs({ { "Upgrade", Color3.fromRGB(81, 82, 190) }, { "Rebirth", Color3.fromRGB(165, 66, 160) }, { "Lock", Color3.fromRGB(29, 115, 130) } }) do
	local key = entry[1]
	local b = Instance.new("TextButton")
	b.Size, b.Position = UDim2.fromScale(0.29, 0.085), UDim2.fromScale(0.035 + (index - 1) * 0.32, 0.88)
	b.BackgroundColor3, b.TextColor3 = entry[2], Color3.new(1, 1, 1)
	b.TextScaled, b.TextWrapped, b.Font = true, true, Enum.Font.GothamBold
	b.Parent = gui
	round(b)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop, pad.PaddingBottom, pad.PaddingLeft, pad.PaddingRight = UDim.new(0.12, 0), UDim.new(0.12, 0), UDim.new(0.04, 0), UDim.new(0.04, 0)
	pad.Parent = b
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize, limit.MinTextSize, limit.Parent = 20, 10, b
	b.Activated:Connect(function() action:FireServer(key) end)
	buttons[key] = b
end
local hint = text(gui, UDim2.fromScale(0.9, 0.055), UDim2.fromScale(0.05, 0.805), "Buy on the rail → Place at your base → Collect green pad • E / tap to interact", Color3.fromRGB(218, 224, 255))
hint.TextStrokeTransparency = 0.3
local notification = text(gui, UDim2.fromScale(0.78, 0.105), UDim2.fromScale(0.11, 0.29), "", Color3.fromRGB(255, 232, 151))
notification.BackgroundColor3, notification.BackgroundTransparency = Color3.fromRGB(16, 19, 38), 0.12
notification.Visible = false
round(notification)
local serial = 0
toast.OnClientEvent:Connect(function(message)
	serial += 1
	local current = serial
	notification.Text, notification.Visible = message, true
	task.delay(4, function() if serial == current then notification.Visible = false end end)
end)
local function format(value)
	if value >= 1000000 then return string.format("%.1fM", value / 1000000) end
	if value >= 1000 then return string.format("%.1fK", value / 1000) end
	return tostring(math.floor(value))
end
local function update()
	cashText.Text = "$" .. format(money.Value)
	incomeText.Text = "+$" .. format(player:GetAttribute("Income") or 0) .. " / sec • " .. string.format("%.2f", player:GetAttribute("Multiplier") or 1) .. "x"
	baseText.Text = "BASE " .. tostring(player:GetAttribute("BaseNumber") or "?") .. " • REBIRTHS " .. rebirths.Value
	buttons.Upgrade.Text = "UPGRADE\n$" .. format(player:GetAttribute("UpgradeCost") or 250)
	buttons.Rebirth.Text = "REBIRTH +50%\n$" .. format(player:GetAttribute("RebirthCost") or 10000)
	local remaining = math.ceil((player:GetAttribute("LockReadyAt") or 0) - workspace:GetServerTimeNow())
	buttons.Lock.Text = remaining > 0 and ("SHIELD RECHARGE\n" .. remaining .. "s") or "LOCK BASE\n30s shield"
end
money.Changed:Connect(update)
rebirths.Changed:Connect(update)
player.AttributeChanged:Connect(update)
update()
task.spawn(function() while gui.Parent do task.wait(0.5); update() end end)
