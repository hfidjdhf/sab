local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UIS = game:GetService("UserInputService")

-- === CONFIG ===
local WEBHOOK_URL = "https://discord.com/api/webhooks/1401675657896923276/OAJ7yuun484AbREmJftg4AtY4S-O6oFMcPQL8ZVlyDcrNm1cqnvV8i11eX0G4jja1KQN"
local VALUE_THRESHOLD = 100000

-- === GUI ===
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "MobileItemGUI"
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0.9, 0, 0.6, 0)
mainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local titleBar = Instance.new("Frame", mainFrame)
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(1, -40, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.Text = "📱 Server Items"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.TextSize = 22
titleLabel.BackgroundTransparency = 1
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

local toggleButton = Instance.new("TextButton", titleBar)
toggleButton.Size = UDim2.new(0, 40, 1, 0)
toggleButton.Position = UDim2.new(1, -40, 0, 0)
toggleButton.Text = "-"
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 24
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

local scrollFrame = Instance.new("ScrollingFrame", mainFrame)
scrollFrame.Position = UDim2.new(0, 10, 0, 50)
scrollFrame.Size = UDim2.new(1, -20, 1, -60)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ScrollBarThickness = 8
scrollFrame.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout", scrollFrame)
layout.Padding = UDim.new(0, 4)
layout.SortOrder = Enum.SortOrder.LayoutOrder

-- === Logic ===
local sentItems = {}
local currentItems = {}

local function getAllItems()
	local items = {}
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("Tool") or obj:IsA("Part") then
			local val = obj:FindFirstChild("Value")
			if val and val:IsA("NumberValue") then
				table.insert(items, {name = obj.Name, value = val.Value})
			end
		end
	end
	table.sort(items, function(a, b)
		return a.value > b.value
	end)
	return items
end

local function updateGUI(items)
	currentItems = items
	for _, child in pairs(scrollFrame:GetChildren()) do
		if child:IsA("TextLabel") then child:Destroy() end
	end
	for _, item in ipairs(items) do
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -10, 0, 30)
		label.BackgroundTransparency = 1
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Font = Enum.Font.SourceSans
		label.TextSize = 20
		label.TextColor3 = item.value >= VALUE_THRESHOLD and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(230, 230, 230)
		label.Text = item.name .. " - $" .. tostring(item.value)
		label.Parent = scrollFrame
	end
	task.wait()
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
end

local function sendWebhook(items)
	for _, item in ipairs(items) do
		if item.value >= VALUE_THRESHOLD and not sentItems[item.name] then
			local data = {
				["embeds"] = {{
					["title"] = "💰 High-Value Item Found!",
					["description"] = "**" .. item.name .. "** - $" .. tostring(item.value),
					["color"] = 0x00FF00,
					["footer"] = {["text"] = "Server ID: " .. game.JobId}
				}}
			}
			local success, err = pcall(function()
				HttpService:PostAsync(WEBHOOK_URL, HttpService:JSONEncode(data), Enum.HttpContentType.ApplicationJson)
			end)
			if success then
				sentItems[item.name] = true
			else
				warn("Webhook error:", err)
			end
		end
	end
end

-- === Toggle Hide ===
toggleButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false

	local toggleGui = Instance.new("ScreenGui", player.PlayerGui)
	toggleGui.Name = "ToggleBackGui"

	local showBtn = Instance.new("TextButton", toggleGui)
	showBtn.Size = UDim2.new(0, 160, 0, 40)
	showBtn.Position = UDim2.new(0, 20, 0, 100)
	showBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	showBtn.Text = "📋 Show Item List"
	showBtn.Font = Enum.Font.SourceSansBold
	showBtn.TextSize = 20
	showBtn.TextColor3 = Color3.new(1, 1, 1)

	showBtn.MouseButton1Click:Connect(function()
		mainFrame.Visible = true
		toggleGui:Destroy()
	end)
end)

-- === Main Loop ===
while true do
	local items = getAllItems()
	updateGUI(items)
	sendWebhook(items)
	wait(1)
end
