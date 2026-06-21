-- [[ SCRIPT TỔNG HỢP DUY NHẤT DÀNH CHO ĐIỆN THOẠI - ĐẶT TRONG STARTERCHARACTERSCRIPTS ]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local character = script.Parent
local rootPart = character:WaitForChild("HumanoidRootPart")

-- CẤU HÌNH THÔNG SỐ (Bạn có thể tự chỉnh)
local FORCE_POWER = 60       -- Lực đá bay (Càng cao bay càng xa)
local FREEZE_TIME = 4        -- Thời gian tự rã đông (giây)
local COOLDOWN = 1.5         -- Thời gian chờ giữa các lần dùng

local onCooldown = false
local storedOriginalColors = {}

-- ----------------------------------------------------
-- TỰ ĐỘNG TẠO GIAO DIỆN (UI) TRÊN MÀN HÌNH ĐIỆN THOẠI
-- ----------------------------------------------------
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Xóa UI cũ nếu có để tránh trùng lặp khi hồi sinh
local oldGui = PlayerGui:FindFirstChild("MobileControlGui")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MobileControlGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

-- 1. Ô nhập tên người chơi
local nameBox = Instance.new("TextBox")
nameBox.Name = "NameBox"
nameBox.Size = UDim2.new(0, 200, 0, 40)
nameBox.Position = UDim2.new(0.5, -100, 0.1, 0) -- Nằm ở giữa phía trên màn hình
nameBox.PlaceholderText = "Nhập tên người chơi..."
nameBox.Text = ""
nameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
nameBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
nameBox.BorderColor3 = Color3.fromRGB(255, 255, 255)
nameBox.TextSize = 16
nameBox.Font = Enum.Font.SourceSansBold
nameBox.Parent = screenGui

-- 2. Nút bấm ĐÁ & ĐÓNG BĂNG
local kickButton = Instance.new("TextButton")
kickButton.Name = "KickButton"
kickButton.Size = UDim2.new(0, 140, 0, 50)
kickButton.Position = UDim2.new(0.5, -150, 0.1, 50)
kickButton.Text = "ĐÁ BĂNG GIÁ"
kickButton.TextColor3 = Color3.fromRGB(255, 255, 255)
kickButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255) -- Màu xanh dương
kickButton.TextSize = 16
kickButton.Font = Enum.Font.SourceSansBold
kickButton.Parent = screenGui

-- 3. Nút bấm RÃ ĐÔNG
local unfreezeButton = Instance.new("TextButton")
unfreezeButton.Name = "UnfreezeButton"
unfreezeButton.Size = UDim2.new(0, 140, 0, 50)
unfreezeButton.Position = UDim2.new(0.5, 10, 0.1, 50)
unfreezeButton.Text = "RÃ ĐÔNG"
unfreezeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
unfreezeButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- Màu đỏ
unfreezeButton.TextSize = 16
unfreezeButton.Font = Enum.Font.SourceSansBold
unfreezeButton.Parent = screenGui

-- Khi nhân vật chết, xóa UI để tránh lỗi
character:WaitForChild("Humanoid").Died:Connect(function()
	screenGui:Destroy()
end)

-- ----------------------------------------------------
-- HÀM XỬ LÝ LOGIC LOGIC GAME
-- ----------------------------------------------------

-- Hàm tìm người chơi theo tên viết tắt
local function findPlayerByName(name)
	for _, p in ipairs(Players:GetPlayers()) do
		if string.lower(p.Name):sub(1, #name) == string.lower(name) or string.lower(p.DisplayName):sub(1, #name) == string.lower(name) then
			return p
		end
	end
	return nil
end

-- Hàm rã đông
local function unfreeze(targetCharacter)
	local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
	if targetRoot then targetRoot.Anchored = false end
	local originalColors = storedOriginalColors[targetCharacter]
	if originalColors then
		for part, color in pairs(originalColors) do
			if part and part.Parent then part.Color = color end
		end
		storedOriginalColors[targetCharacter] = nil
	end
end

-- Xử lý khi chạm tay vào nút ĐÁ BĂNG GIÁ
kickButton.Activated:Connect(function()
	if onCooldown then return end
	local targetName = nameBox.Text
	if targetName == "" then return end
	
	local targetPlayer = findPlayerByName(targetName)
	if targetPlayer and targetPlayer ~= LocalPlayer then
		local targetCharacter = targetPlayer.Character
		local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
		local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
		
		if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
			onCooldown = true
			kickButton.Text = "Đang hồi..."
			
			-- 1. Đá văng (Xử lý vật lý trực tiếp từ máy của bạn)
			local pushDirection = (targetRoot.Position - rootPart.Position).Unit
			pushDirection = Vector3.new(pushDirection.X, 0.6, pushDirection.Z).Unit
			local attachment = Instance.new("Attachment", targetRoot)
			local linearVelocity = Instance.new("LinearVelocity")
			linearVelocity.Attachment0 = attachment
			linearVelocity.MaxForce = math.huge
			linearVelocity.VectorVelocity = pushDirection * FORCE_POWER
			linearVelocity.Parent = targetRoot
			game.Debris:AddItem(linearVelocity, 0.2)
			game.Debris:AddItem(attachment, 0.2)
			
			-- 2. Đóng băng & Đổi màu xanh băng giá
			targetRoot.Anchored = true
			if not storedOriginalColors[targetCharacter] then storedOriginalColors[targetCharacter] = {} end
			for _, part in ipairs(targetCharacter:GetChildren()) do
				if part:IsA("BasePart") then
					if not storedOriginalColors[targetCharacter][part] then storedOriginalColors[targetCharacter][part] = part.Color end
					part.Color = Color3.fromRGB(0, 255, 255)
				end
			end
			
			-- Tự động rã đông sau 4 giây
			local currentFreezeTime = tick()
			targetCharacter:SetAttribute("LastFreezeTime", currentFreezeTime)
			task.delay(FREEZE_TIME, function()
				if targetCharacter and targetCharacter.Parent and targetCharacter:GetAttribute("LastFreezeTime") == currentFreezeTime then
					unfreeze(targetCharacter)
				end
			end)
			
			task.wait(COOLDOWN)
			onCooldown = false
			kickButton.Text = "ĐÁ BĂNG GIÁ"
		end
	end
end)

-- Xử lý khi chạm tay vào nút RÃ ĐÔNG
unfreezeButton.Activated:Connect(function()
	local targetName = nameBox.Text
	if targetName == "" then return end
	
	local targetPlayer = findPlayerByName(targetName)
	if targetPlayer and targetPlayer.Character then
		unfreeze(targetPlayer.Character)
	end
end)
