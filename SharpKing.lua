--[[
    SHARP V8 - ULTRA-SPEED AUTO-SNAP
    - Speed: Instantaneous (1:1 Hard Lock)
    - Scan Rate: Doubled (Every Frame Priority)
    - Snap: Direct Head Teleport
    - Logic: Closest-to-Center Priority
]]--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Configuration
local circleSize = 65
local snapStrength = 1.0 -- سرعة خارقة (انتقال فوري)
local swipeBreakThreshold = 35 -- قوة السحب المطلوبة لفك التثبيت

-- State
local circleDragging = false
local currentTarget = nil
local lastBreak = 0
local dragOffset = Vector2.new(0, 0)
local lastPos = nil

-- ==================== XRAY ====================
local function applyXray(char)
    if not char then return end
    local highlight = char:FindFirstChild("SharpX8") or Instance.new("Highlight")
    highlight.Name = "SharpX8"
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.1 -- لون أحمر غامق وواضح جداً
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = char
end

for _, plr in pairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then
        if plr.Character then applyXray(plr.Character) end
        plr.CharacterAdded:Connect(applyXray)
    end
end
Players.PlayerAdded:Connect(function(plr) plr.CharacterAdded:Connect(applyXray) end)

-- ==================== UI ====================
local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
gui.Name = "SharpV8"
gui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", gui)
mainFrame.Size = UDim2.new(0, circleSize, 0, circleSize)
mainFrame.Position = UDim2.new(0.5, -circleSize/2, 0.5, -circleSize/2)
mainFrame.BackgroundTransparency = 1

local ring = Instance.new("Frame", mainFrame)
ring.Size = UDim2.new(1, 0, 1, 0)
ring.BackgroundTransparency = 1
local stroke = Instance.new("UIStroke", ring)
stroke.Color = Color3.fromRGB(255, 0, 0)
stroke.Thickness = 2.5
Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)

local centerDot = Instance.new("Frame", mainFrame)
centerDot.Size = UDim2.new(0, 8, 0, 8)
centerDot.Position = UDim2.new(0.5, -4, 0.5, -4)
centerDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", centerDot).CornerRadius = UDim.new(1, 0)

-- ==================== INPUT ====================
mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        circleDragging = true
        local framePos = mainFrame.AbsolutePosition
        dragOffset = framePos - Vector2.new(input.Position.X, input.Position.Y)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
        local currentPos = Vector2.new(input.Position.X, input.Position.Y)
        if circleDragging then
            local newPos = currentPos + dragOffset
            mainFrame.Position = UDim2.new(0, newPos.X, 0, newPos.Y)
        else
            if lastPos then
                if (currentPos - lastPos).Magnitude > swipeBreakThreshold then
                    currentTarget = nil
                    lastBreak = tick()
                end
            end
            lastPos = currentPos
        end
    end
end)

mainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        circleDragging = false
    end
end)

-- ==================== LOCK ENGINE (V8) ====================
local function findBestTarget()
    local center = mainFrame.AbsolutePosition + Vector2.new(circleSize/2, circleSize/2)
    local best = nil
    local shortestDist = circleSize * 1.1 
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            local head = plr.Character:FindFirstChild("Head")
            if head then
                local pos, visible = Camera:WorldToViewportPoint(head.Position)
                if visible then
                    local mag = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if mag < shortestDist then
                        shortestDist = mag
                        best = head
                    end
                end
            end
        end
    end
    return best
end

RunService.RenderStepped:Connect(function()
    if circleDragging or (tick() - lastBreak < 0.05) then 
        centerDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        return 
    end
    
    -- نظام التعرف المزدوج: يبحث دائماً عن أفضل هدف حتى لو كان مثبت
    local targetCandidate = findBestTarget()
    if targetCandidate then
        currentTarget = targetCandidate
    end

    if currentTarget and currentTarget.Parent and currentTarget.Parent:FindFirstChild("Humanoid") and currentTarget.Parent.Humanoid.Health > 0 then
        local headPos, onScreen = Camera:WorldToViewportPoint(currentTarget.Position)
        local frameCenter = mainFrame.AbsolutePosition + Vector2.new(circleSize/2, circleSize/2)
        
        if onScreen and (Vector2.new(headPos.X, headPos.Y) - frameCenter).Magnitude < (circleSize * 3) then
            -- تثبيت خارق مباشر على الرأس
            local lockCF = CFrame.new(Camera.CFrame.Position, currentTarget.Position)
            Camera.CFrame = Camera.CFrame:Lerp(lockCF, snapStrength)
            centerDot.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- أخضر عند التثبيت
            return
        else
            currentTarget = nil
        end
    end
    
    if not currentTarget then
        centerDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    end
end)

print("✅ SHARP V8 LOADED - ULTRA RECOGNITION ACTIVE")
