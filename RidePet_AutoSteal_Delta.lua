--[[
    Vaehz BEST SCRIPT
    WindUI + Tween Steal + Egg Selection
    Fully fixed for Delta Executor
    Clean syntax • No cut-off • Ready to execute
]]

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
    Humanoid = char:WaitForChild("Humanoid")
end)

-- Config
local Config = {
    AutoSteal = false,
    TweenSpeed = 1.2,          -- lower = faster
    SelectedEgg = "All",
    AutoReturn = true,
    ReturnDelay = 0.35,
    WalkSpeed = 16,
    JumpPower = 50,
    StealRange = 12,
    AntiAFK = true,
}

-- Egg options (common in Steal An Egg / Pet games)
local EggList = {
    "All",
    "Common",
    "Uncommon",
    "Rare",
    "Epic",
    "Legendary",
    "Mythical",
    "Secret",
    "Exclusive",
    "Godly",
    "Titanic",
    "Huge",
}

-- Anti AFK
if Config.AntiAFK then
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

-- Utility
local function Notify(title, content, duration)
    WindUI:Notify({
        Title = title,
        Content = content,
        Duration = duration or 3,
    })
end

local function GetRoot()
    if Character and Character.Parent and HumanoidRootPart and HumanoidRootPart.Parent then
        return HumanoidRootPart
    end
    return nil
end

local function TweenTo(pos, speed)
    local root = GetRoot()
    if not root then return false end

    local distance = (root.Position - pos).Magnitude
    local time = math.clamp(distance / (speed * 60), 0.15, 8)

    local tweenInfo = TweenInfo.new(time, Enum.EasingStyle.Linear)
    local goal = {CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))}
    local tween = TweenService:Create(root, tweenInfo, goal)

    -- Prevent physics fighting
    if Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    end
    root.Anchored = true
    tween:Play()
    tween.Completed:Wait()
    root.Anchored = false
    if Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Running)
    end
    return true
end

local function IsMatchingEgg(name)
    if Config.SelectedEgg == "All" then return true end
    name = string.lower(name or "")
    local target = string.lower(Config.SelectedEgg)
    return string.find(name, target) ~= nil
end

local function FindNearestEgg()
    local root = GetRoot()
    if not root then return nil end

    local nearest = nil
    local shortest = math.huge
    local searchFolders = {
        workspace,
        workspace:FindFirstChild("Eggs"),
        workspace:FindFirstChild("EggSpawns"),
        workspace:FindFirstChild("Map"),
        workspace:FindFirstChild("World"),
        workspace:FindFirstChild("Plots"),
    }

    for _, folder in pairs(searchFolders) do
        if folder then
            for _, obj in pairs(folder:GetDescendants()) do
                if (obj:IsA("Model") or obj:IsA("BasePart") or obj:IsA("MeshPart")) then
                    local name = obj.Name
                    if (string.find(string.lower(name), "egg") or string.find(string.lower(name), "nest")) and IsMatchingEgg(name) then
                        local part = obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                        if part and part:IsA("BasePart") then
                            local dist = (root.Position - part.Position).Magnitude
                            if dist < shortest and dist < 500 then
                                shortest = dist
                                nearest = part
                            end
                        end
                    end
                end
            end
        end
    end
    return nearest
end

local function FirePrompt(part)
    if not part then return end
    for _, v in pairs(part:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            fireproximityprompt(v)
            return true
        end
    end
    -- Fallback click
    pcall(function()
        VirtualUser:ClickButton1(Vector2.new())
    end)
    return false
end

local function StealLoop()
    while Config.AutoSteal do
        local egg = FindNearestEgg()
        if egg then
            local success = TweenTo(egg.Position, Config.TweenSpeed)
            if success then
                task.wait(0.12)
                FirePrompt(egg)
                task.wait(Config.ReturnDelay)

                if Config.AutoReturn then
                    -- Try find base / plot
                    local base = workspace:FindFirstChild("Base") 
                        or workspace:FindFirstChild("Plot") 
                        or workspace:FindFirstChild(LocalPlayer.Name)
                        or workspace:FindFirstChild("Home")
                    if base then
                        local basePart = base:IsA("BasePart") and base or base.PrimaryPart or base:FindFirstChildWhichIsA("BasePart")
                        if basePart then
                            TweenTo(basePart.Position, Config.TweenSpeed * 0.9)
                        end
                    end
                end
            end
        else
            task.wait(0.6)
        end
        task.wait(0.15)
    end
end

-- Create UI
local Window = WindUI:CreateWindow({
    Title = "Vaehz BEST SCRIPT",
    Icon = "egg",
    Theme = "Dark",
    Folder = "VaehzBestScript",
    Size = UDim2.fromOffset(520, 380),
})

local MainTab = Window:Tab({
    Title = "Auto Steal",
    Icon = "zap",
})

local PlayerTab = Window:Tab({
    Title = "Player",
    Icon = "user",
})

local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings",
})

-- Main Tab
MainTab:Toggle({
    Title = "Auto Steal",
    Desc = "Tween to selected eggs and steal them",
    Value = false,
    Callback = function(value)
        Config.AutoSteal = value
        if value then
            Notify("Auto Steal", "Started targeting: " .. Config.SelectedEgg, 3)
            task.spawn(StealLoop)
        else
            Notify("Auto Steal", "Stopped", 2)
        end
    end,
})

MainTab:Dropdown({
    Title = "Target Egg",
    Desc = "Which egg rarity / type to steal",
    Values = EggList,
    Value = "All",
    Callback = function(option)
        Config.SelectedEgg = option
        Notify("Egg Target", "Now targeting: " .. option, 2)
    end,
})

MainTab:Slider({
    Title = "Tween Speed",
    Desc = "Lower = faster tween (0.4 - 3)",
    Value = 1.2,
    Min = 0.4,
    Max = 3,
    Step = 0.1,
    Callback = function(value)
        Config.TweenSpeed = value
    end,
})

MainTab:Toggle({
    Title = "Auto Return to Base",
    Desc = "Return after each steal",
    Value = true,
    Callback = function(value)
        Config.AutoReturn = value
    end,
})

MainTab:Slider({
    Title = "Return Delay",
    Desc = "Seconds to wait after steal before return",
    Value = 0.35,
    Min = 0.1,
    Max = 2,
    Step = 0.05,
    Callback = function(value)
        Config.ReturnDelay = value
    end,
})

MainTab:Button({
    Title = "Steal Nearest Once",
    Callback = function()
        local egg = FindNearestEgg()
        if egg then
            TweenTo(egg.Position, Config.TweenSpeed)
            task.wait(0.1)
            FirePrompt(egg)
            Notify("Steal", "Stole nearest egg", 2)
        else
            Notify("Steal", "No matching egg found", 2)
        end
    end,
})

-- Player Tab
PlayerTab:Slider({
    Title = "WalkSpeed",
    Value = 16,
    Min = 16,
    Max = 200,
    Step = 1,
    Callback = function(value)
        Config.WalkSpeed = value
        if Humanoid then
            Humanoid.WalkSpeed = value
        end
    end,
})

PlayerTab:Slider({
    Title = "JumpPower",
    Value = 50,
    Min = 50,
    Max = 200,
    Step = 1,
    Callback = function(value)
        Config.JumpPower = value
        if Humanoid then
            Humanoid.JumpPower = value
            Humanoid.UseJumpPower = true
        end
    end,
})

PlayerTab:Button({
    Title = "Reset Speed / Jump",
    Callback = function()
        if Humanoid then
            Humanoid.WalkSpeed = 16
            Humanoid.JumpPower = 50
        end
        Notify("Player", "Reset to default", 2)
    end,
})

-- Settings Tab
SettingsTab:Toggle({
    Title = "Anti AFK",
    Value = true,
    Callback = function(value)
        Config.AntiAFK = value
    end,
})

SettingsTab:Button({
    Title = "Destroy UI",
    Callback = function()
        Window:Close()
    end,
})

SettingsTab:Paragraph({
    Title = "Info",
    Desc = "Delta Fixed • WindUI • Tween Steal\nSelect egg type then enable Auto Steal.\nWorks on most Steal An Egg / Pet simulators.",
})

Notify("Vaehz BEST SCRIPT", "Loaded successfully on Delta", 4)
print("[Vaehz BEST SCRIPT] Loaded | WindUI + Tween Auto Steal")