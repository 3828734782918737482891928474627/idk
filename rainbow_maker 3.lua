-- Rainbow Maker Avatar Equip
-- Client-sided

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local ASSET_ID    = 10648446748  -- Rainbow Maker

-- ══════════════════════════════════════════════
--  CORE FUNCTION
-- ══════════════════════════════════════════════
local function EquipRainbowMaker()
    local character = LocalPlayer.Character
    if not character then return false, "No character" end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local rootPart = humanoidRootPart or character:FindFirstChildOfClass("Part")
    if not rootPart then return false, "No root part" end

    -- Remove any existing Rainbow Maker first
    for _, child in pairs(character:GetChildren()) do
        if child.Name == "RainbowMaker" or child.Name == "rainbow_maker" then
            child:Destroy()
        end
    end

    local ok, err = pcall(function()
        local objects = game:GetObjects("rbxassetid://" .. ASSET_ID)
        if not objects or #objects == 0 then error("GetObjects returned nothing") end

        for _, obj in pairs(objects) do
            -- Print what we got so we know what type it is
            print("[RainbowMaker] Got object: " .. obj.ClassName .. " | " .. obj.Name)

            -- Clone everything directly into the character
            local clone = obj:Clone()
            clone.Name = "RainbowMaker"

            -- If it's a Model/Tool, weld its parts to HumanoidRootPart
            if clone:IsA("Tool") then
                -- Activate as a held tool
                clone.Parent = character
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:EquipTool(clone)
                end

            elseif clone:IsA("Model") then
                -- Weld each BasePart to HumanoidRootPart
                for _, part in pairs(clone:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Anchored = false
                        local weld = Instance.new("WeldConstraint")
                        weld.Part0 = rootPart
                        weld.Part1 = part
                        weld.Parent = part
                    end
                end
                clone.Parent = character

            elseif clone:IsA("Accessory") then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    clone.Parent = workspace
                    humanoid:AddAccessory(clone)
                else
                    clone.Parent = character
                end

            elseif clone:IsA("BasePart") then
                clone.Anchored = false
                local weld = Instance.new("WeldConstraint")
                weld.Part0 = rootPart
                weld.Part1 = clone
                weld.Parent = clone
                clone.Parent = character

            else
                -- Fallback: just parent to character
                clone.Parent = character
            end
        end
    end)

    if ok then
        print("[RainbowMaker] Equipped!")
        return true
    end

    warn("[RainbowMaker] Failed: " .. tostring(err))
    return false
end

-- ══════════════════════════════════════════════
--  GUI
-- ══════════════════════════════════════════════
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local old = playerGui:FindFirstChild("RainbowMakerGui")
if old then old:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "RainbowMakerGui"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = playerGui

local frame = Instance.new("Frame")
frame.Size             = UDim2.new(0, 220, 0, 60)
frame.Position         = UDim2.new(0.5, -110, 0.08, 0)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
frame.BorderSizePixel  = 0
frame.Parent           = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local stroke = Instance.new("UIStroke")
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Color           = Color3.fromRGB(255, 80, 180)
stroke.Thickness       = 2.5
stroke.Parent          = frame

local rgbColors = {
    Color3.fromRGB(255, 80,  180),
    Color3.fromRGB(255, 140, 60),
    Color3.fromRGB(255, 240, 60),
    Color3.fromRGB(80,  255, 120),
    Color3.fromRGB(60,  200, 255),
    Color3.fromRGB(140, 80,  255),
}
local rIdx = 1
task.spawn(function()
    while frame.Parent do
        local nxt = rIdx % #rgbColors + 1
        TweenService:Create(stroke, TweenInfo.new(1.2, Enum.EasingStyle.Linear), {
            Color = rgbColors[nxt]
        }):Play()
        rIdx = nxt
        task.wait(1.2)
    end
end)

local closeBtn = Instance.new("TextButton")
closeBtn.Size             = UDim2.new(0, 20, 0, 20)
closeBtn.Position         = UDim2.new(1, -24, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 80)
closeBtn.Text             = "x"
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.TextSize         = 11
closeBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
closeBtn.Parent           = frame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 5)
closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

local btn = Instance.new("TextButton")
btn.Size             = UDim2.new(0, 170, 0, 34)
btn.Position         = UDim2.new(0.5, -85, 0.5, -17)
btn.BackgroundColor3 = Color3.fromRGB(38, 28, 68)
btn.Text             = "Rainbow Maker on Avatar"
btn.Font             = Enum.Font.GothamBold
btn.TextSize         = 11
btn.TextColor3       = Color3.fromRGB(245, 220, 255)
btn.Parent           = frame
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 9)
local btnStroke = Instance.new("UIStroke")
btnStroke.Color        = Color3.fromRGB(200, 140, 255)
btnStroke.Thickness    = 1.5
btnStroke.Transparency = 0.2
btnStroke.Parent       = btn

btn.MouseButton1Click:Connect(function()
    btn.Text             = "Loading..."
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    local success = EquipRainbowMaker()
    if success then
        btn.Text             = "Equipped!"
        btn.BackgroundColor3 = Color3.fromRGB(30, 90, 50)
        btnStroke.Color      = Color3.fromRGB(100, 255, 150)
    else
        btn.Text             = "Failed - retry?"
        btn.BackgroundColor3 = Color3.fromRGB(90, 25, 35)
        btnStroke.Color      = Color3.fromRGB(255, 100, 100)
        task.delay(2.5, function()
            btn.Text             = "Rainbow Maker on Avatar"
            btn.BackgroundColor3 = Color3.fromRGB(38, 28, 68)
            btnStroke.Color      = Color3.fromRGB(200, 140, 255)
        end)
    end
end)

-- Drag
local dragging, dragStart, startPos = false, nil, nil
frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging  = true
        dragStart = input.Position
        startPos  = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
frame.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement or
        input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

print("[RainbowMaker] Ready!")
