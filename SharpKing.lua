--[[
    SHARP V8 MODIFIED - ULTRA-SPEED AUTO-SNAP
    - Added: Hide Button (Toggle to Point)
    - Improved: Global Xray (Comprehensive)
    - Logic: Pure V8 Engine (No changes to Aim Logic)
]]--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Configuration
local circleSize = 65
local snapStrength = 1.0 
local swipeBreakThreshold = 35 

-- State
local circleDragging = false
local circleLocked = false 
local isHidden = false
local currentTarget = nil
local lastBreak = 0
local dragOffset = Vector2.new(0, 0)
local lastPos = nil

-- ==================== XRAY (ALL PLAYERS) ====================
local function applyXray(char)
    if not char then return end
    task.wait(0.5)
    local highlight = char:FindFirstChild("SharpX8_Highlight") or Instance.new("Highlight")
    highlight.Name = "SharpX8_Highlight"
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.4 
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = char
end

local function updateXray()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            applyXray(plr.Character)
        end
    end
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(applyXray)
end)

task.spawn(function()
    while task.wait(3) do updateXray() end 
end)

-- ==================== UI ELEMENTS ====================
local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
gui.Name = "SharpV8_Updated"
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

-- زر القفل
local lockButton = Instance.new("TextButton", mainFrame)
lockButton.Size = UDim2.new(0, 45, 0, 18)
lockButton.Position = UDim2.new(0.5, -22, 1, 5) 
lockButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
lockButton.Text = "FREE"
lockButton.TextColor3 = Color3.fromRGB(0, 255, 0)
lockButton.TextSize = 10
lockButton.Font = Enum.Font.GothamBold
Instance.new("UICorner", lockButton).CornerRadius = UDim.new(0, 4)
Instance.new("UIStroke", lockButton).Color = Color3.fromRGB(255, 255, 255)

-- زر الإخفاء (HIDE)
local hideButton = Instance.new("TextButton", mainFrame)
hideButton.Size = UDim2.new(0, 45, 0, 18)
hideButton.Position = UDim2.new(0.5, -22, 1, 26) -- تحت زر القفل
hideButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
hideButton.Text = "HIDE"
hideButton.TextColor3 = Color3.fromRGB(200, 200, 200)
hideButton.TextSize = 10
hideButton.Font = Enum.Font.GothamBold
Instance.new("UICorner", hideButton).CornerRadius = UDim.new(0, 4)
Instance.new("UIStroke", hideButton).Color = Color3.fromRGB(255, 255, 255)

-- نقطة الاستعادة (تظهر فقط عند الإخفاء)
local revealPoint = Instance.new("TextButton", mainFrame)
revealPoint.Size = UDim2.new(0, 6, 0, 6)
revealPoint.Position = UDim2.new(0.5, -3, 0.5, -3)
revealPoint.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
revealPoint.BackgroundTransparency = 0.3
revealPoint.Text = ""
revealPoint.Visible = false
Instance.new("UICorner", revealPoint).CornerRadius = UDim.new(1, 0)

-- ==================== UI LOGIC ====================

hideButton.MouseButton1Click:Connect(function()
    isHidden = true
    ring.Visible = false
    centerDot.Visible = false
    lockButton.Visible = false
    hideButton.Visible = false
    revealPoint.Visible = true
end)

revealPoint.MouseButton1Click:Connect(function()
    isHidden = false
    ring.Visible = true
    centerDot.Visible = true
    lockButton.Visible = true
    hideButton.Visible = true
    revealPoint.Visible = false
end)

lockButton.MouseButton1Click:Connect(function()
    circleLocked = not circleLocked
    if circleLocked then
        lockButton.Text = "LOCKED"
        lockButton.TextColor3 = Color3.fromRGB(255, 0, 0)
    else
        lockButton.Text = "FREE"
        lockButton.TextColor3 = Color3.fromRGB(0, 255, 0)
    end
end)

mainFrame.InputBegan:Connect(function(input)
    if not isHidden and not circleLocked and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
        circleDragging = true
        local framePos = mainFrame.AbsolutePosition
        dragOffset = framePos - Vector2.new(input.Position.X, input.Position.Y)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
        local currentPos = Vector2.new(input.Position.X, input.Position.Y)
        if circleDragging and not isHidden then
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

-- ==================== LOCK ENGINE (V8 ORIGINAL LOGIC) ====================
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
    
    local targetCandidate = findBestTarget()
    if targetCandidate then
        currentTarget = targetCandidate
    end

    if currentTarget and currentTarget.Parent and currentTarget.Parent:FindFirstChild("Humanoid") and currentTarget.Parent.Humanoid.Health > 0 then
        local headPos, onScreen = Camera:WorldToViewportPoint(currentTarget.Position)
        local frameCenter = mainFrame.AbsolutePosition + Vector2.new(circleSize/2, circleSize/2)
        
        -- التزام كامل بنفس شرط المسافة في النسخة التي وضعتها أنت
        if onScreen and (Vector2.new(headPos.X, headPos.Y) - frameCenter).Magnitude < (circleSize * 3) then
            local lockCF = CFrame.new(Camera.CFrame.Position, currentTarget.Position)
            Camera.CFrame = Camera.CFrame:Lerp(lockCF, snapStrength)
            centerDot.BackgroundColor3 = Color3.fromRGB(0, 255, 0) 
            return
        else
            currentTarget = nil
        end
    end
    
    if not currentTarget then
        centerDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    end
end)

print("SHARP V8 - MODS ADDED SUCCESSFULLY")
