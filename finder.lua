local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- === CONFIGURATION ===
local WEBHOOK_URL = "https://discord.com/api/webhooks/1401675657896923276/OAJ7yuun484AbREmJftg4AtY4S-O6oFMcPQL8ZVlyDcrNm1cqnvV8i11eX0G4jja1KQN"
local VALUE_THRESHOLD = 1000000 -- 1 million

-- === GUI SETUP ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ItemListGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 500, 0, 400)
mainFrame.Position = UDim2.new(0, 50, 0, 100)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
titleLabel.Text = "🧾 Server Item List"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 24
titleLabel.Parent = mainFrame

local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Size = UDim2.new(1, -20, 1, -60)
scrollingFrame.Position = UDim2.new(0, 10, 0, 50)
scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollingFrame.BackgroundTransparency = 1
scrollingFrame.ScrollBarThickness = 8
scrollingFrame.BorderSizePixel = 0
scrollingFrame.Parent = mainFrame

local uiListLayout = Instance.new("UIListLayout", scrollingFrame)
uiListLayout.Padding = UDim.new(0, 4)
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- === FUNCTION TO GET ITEMS ===
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
	return items
end

-- === FUNCTION TO UPDATE GUI ===
local function updateGUI(items)
	for _, child in pairs(scrollingFrame:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	for _, item in ipairs(items) do
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -10, 0, 30)
		label.BackgroundTransparency = 1
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Font = Enum.Font.SourceSans
		label.TextSize = 22
		label.TextColor3 = item.value >= VALUE_THRESHOLD and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(220, 220, 220)
		label.Text = item.name .. " - $" .. tostring(item.value)
		label.Parent = scrollingFrame
	end

	wait()
	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, uiListLayout.AbsoluteContentSize.Y + 10)
end

-- === FUNCTION TO SEND WEBHOOK ===
local sentItems = {}

local function sendWebhook(items)
	for _, item in ipairs(items) do
		if item.value >= VALUE_THRESHOLD and not sentItems[item.name] then
			local data = {
				["embeds"] = {{
					["title"] = "💰 High-Value Item Detected!",
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
				warn("Webhook Error:", err)
			end
		end
	end
end

-- === MAIN LOOP ===
while true do
	local items = getAllItems()
	updateGUI(items)
	sendWebhook(items)
	wait(1)
end
