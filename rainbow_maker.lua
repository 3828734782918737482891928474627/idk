-- Rainbow Maker Avatar Equip
-- Equips the Rainbow Maker (ID: 10648446748) onto your local Adopt Me avatar
-- Client-sided using InsertService

local Players       = game:GetService("Players")
local InsertService = game:GetService("InsertService")
local TweenService  = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local ASSET_ID    = 10648446748  -- Rainbow Maker

-- ══════════════════════════════════════════════
--  CORE FUNCTION
-- ══════════════════════════════════════════════
local function EquipRainbowMaker()
    local character = LocalPlayer.Character
    if not character then
        warn("[RainbowMaker] No character found.")
        return false
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        warn("[RainbowMaker] No Humanoid found.")
        return false
    end

    local ok, result = pcall(function()
        local assetModel = InsertService:LoadAsset(ASSET_ID)
        local accessory  = assetModel:FindFirstChildOfClass("Accessory")
            or assetModel:FindFirstChildWhichIsA("Accessory", true)

        if not accessory then
            for _, child in pairs(assetModel:GetDescendants()) do
                if child:IsA("Accessory") then
                    accessory = child
                    break
                end
            end
        end

        if not accessory then
            error("Accessory not found inside asset " .. ASSET_ID)
        end

        accessory.Parent = workspace
        humanoid:AddAccessory(accessory)
        assetModel:Destroy()
    end)

    if ok then
        print("[RainbowMaker] Equipped on your avatar!")
        return true
    else
        warn("[RainbowMaker] Failed: " .. tostring(result))
        return false
    end
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
        local next = rIdx % #rgbColors + 1
        TweenService:Create(stroke, TweenInfo.new(1.2, Enum.EasingStyle.Linear), {
            Color = rgbColors[next]
        }):Play()
        rIdx = next
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
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

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
        task.delay(2, function()
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
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
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
