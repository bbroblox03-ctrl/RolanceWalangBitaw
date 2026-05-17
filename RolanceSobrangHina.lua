--[[
    🎮 CaggyHub - Slime RNG Script
    🔧 Modern & Optimized
    ⚡ Supports: Sol's RNG, Slime RNG, RNG Games
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")

-- Variables
local Player = Players.LocalPlayer
local GUI = nil
local isAutoRoll = false
local isAutoClaim = false
local isAutoSell = false
local selectedBiome = "Default"
local rollSpeed = 1
local stats = {
    totalRolls = 0,
    rareAuras = 0,
    legendaryAuras = 0,
    mythicAuras = 0,
    luck = 0
}

-- Notification System
local function notify(title, message, duration)
    if syn and syn.notification then
        syn.notification(title, message, duration or 3)
    else
        game.StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = message,
            Duration = duration or 3
        })
    end
end

-- Create GUI
local function createGUI()
    local success, err = pcall(function()
        -- ScreenGui
        GUI = Instance.new("ScreenGui")
        GUI.Name = "CaggyHub_SlimeRNG"
        GUI.Parent = game.CoreGui
        GUI.ResetOnSpawn = false
        GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

        -- Main Frame
        local MainFrame = Instance.new("Frame")
        MainFrame.Name = "MainFrame"
        MainFrame.Size = UDim2.new(0, 350, 0, 480)
        MainFrame.Position = UDim2.new(0.5, -175, 0.5, -240)
        MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        MainFrame.BorderSizePixel = 0
        MainFrame.ClipsDescendants = true
        MainFrame.Parent = GUI

        -- Corner Radius
        local UICorner = Instance.new("UICorner")
        UICorner.CornerRadius = UDim.new(0, 12)
        UICorner.Parent = MainFrame

        -- Drop Shadow
        local Shadow = Instance.new("ImageLabel")
        Shadow.Name = "Shadow"
        Shadow.Size = UDim2.new(1, 40, 1, 40)
        Shadow.Position = UDim2.new(0, -20, 0, -20)
        Shadow.BackgroundTransparency = 1
        Shadow.Image = "rbxassetid://6014261993"
        Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
        Shadow.ImageTransparency = 0.5
        Shadow.ScaleType = Enum.ScaleType.Slice
        Shadow.SliceCenter = Rect.new(49, 49, 49, 49)
        Shadow.ZIndex = 0
        Shadow.Parent = MainFrame

        -- Title Bar
        local TitleBar = Instance.new("Frame")
        TitleBar.Name = "TitleBar"
        TitleBar.Size = UDim2.new(1, 0, 0, 40)
        TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
        TitleBar.BorderSizePixel = 0
        TitleBar.Parent = MainFrame

        local TitleCorner = Instance.new("UICorner")
        TitleCorner.CornerRadius = UDim.new(0, 12)
        TitleCorner.Parent = TitleBar

        local TitleLabel = Instance.new("TextLabel")
        TitleLabel.Size = UDim2.new(1, -80, 1, 0)
        TitleLabel.Position = UDim2.new(0, 15, 0, 0)
        TitleLabel.BackgroundTransparency = 1
        TitleLabel.Text = "🎲 CaggyHub | Slime RNG"
        TitleLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
        TitleLabel.TextSize = 16
        TitleLabel.Font = Enum.Font.GothamBold
        TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        TitleLabel.Parent = TitleBar

        -- Minimize Button
        local MinBtn = Instance.new("TextButton")
        MinBtn.Size = UDim2.new(0, 30, 0, 30)
        MinBtn.Position = UDim2.new(1, -35, 0, 5)
        MinBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
        MinBtn.Text = "—"
        MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        MinBtn.TextSize = 18
        MinBtn.Font = Enum.Font.GothamBold
        MinBtn.Parent = TitleBar

        local MinCorner = Instance.new("UICorner")
        MinCorner.CornerRadius = UDim.new(0, 6)
        MinCorner.Parent = MinBtn

        -- Content Frame
        local ContentFrame = Instance.new("Frame")
        ContentFrame.Name = "Content"
        ContentFrame.Size = UDim2.new(1, -20, 1, -90)
        ContentFrame.Position = UDim2.new(0, 10, 0, 50)
        ContentFrame.BackgroundTransparency = 1
        ContentFrame.Parent = MainFrame

        -- Tab Buttons Frame
        local TabFrame = Instance.new("Frame")
        TabFrame.Size = UDim2.new(1, 0, 0, 30)
        TabFrame.BackgroundTransparency = 1
        TabFrame.Parent = ContentFrame

        local tabs = {"Rolling", "Settings", "Stats", "Misc"}
        local tabButtons = {}
        
        for i, tabName in ipairs(tabs) do
            local Tab = Instance.new("TextButton")
            Tab.Size = UDim2.new(0.25, -5, 1, 0)
            Tab.Position = UDim2.new((i-1) * 0.25, 0, 0, 0)
            Tab.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
            Tab.Text = tabName
            Tab.TextColor3 = Color3.fromRGB(180, 180, 200)
            Tab.TextSize = 13
            Tab.Font = Enum.Font.GothamSemibold
            Tab.Parent = TabFrame
            
            local TabCorner = Instance.new("UICorner")
            TabCorner.CornerRadius = UDim.new(0, 6)
            TabCorner.Parent = Tab
            
            tabButtons[tabName] = Tab
        end

        -- Pages
        local Pages = {}
        
        -- Rolling Page
        local RollingPage = Instance.new("Frame")
        RollingPage.Size = UDim2.new(1, 0, 1, -35)
        RollingPage.Position = UDim2.new(0, 0, 0, 35)
        RollingPage.BackgroundTransparency = 1
        RollingPage.Visible = true
        RollingPage.Parent = ContentFrame
        Pages.Rolling = RollingPage

        -- Auto Roll Button
        local AutoRollBtn = Instance.new("TextButton")
        AutoRollBtn.Size = UDim2.new(1, 0, 0, 45)
        AutoRollBtn.Position = UDim2.new(0, 0, 0, 10)
        AutoRollBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 180)
        AutoRollBtn.Text = "⚡ START AUTO ROLL"
        AutoRollBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        AutoRollBtn.TextSize = 16
        AutoRollBtn.Font = Enum.Font.GothamBold
        AutoRollBtn.Parent = RollingPage
        
        local AutoRollCorner = Instance.new("UICorner")
        AutoRollCorner.CornerRadius = UDim.new(0, 8)
        AutoRollCorner.Parent = AutoRollBtn

        -- Roll Speed Slider
        local SpeedLabel = Instance.new("TextLabel")
        SpeedLabel.Size = UDim2.new(1, 0, 0, 20)
        SpeedLabel.Position = UDim2.new(0, 0, 0, 65)
        SpeedLabel.BackgroundTransparency = 1
        SpeedLabel.Text = "Roll Speed: 1.0x"
        SpeedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        SpeedLabel.TextSize = 14
        SpeedLabel.Font = Enum.Font.Gotham
        SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
        SpeedLabel.Parent = RollingPage

        local SpeedSlider = Instance.new("TextBox")
        SpeedSlider.Size = UDim2.new(1, 0, 0, 25)
        SpeedSlider.Position = UDim2.new(0, 0, 0, 85)
        SpeedSlider.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        SpeedSlider.Text = "1"
        SpeedSlider.TextColor3 = Color3.fromRGB(255, 255, 255)
        SpeedSlider.TextSize = 14
        SpeedSlider.Font = Enum.Font.Gotham
        SpeedSlider.Parent = RollingPage
        
        local SpeedCorner = Instance.new("UICorner")
        SpeedCorner.CornerRadius = UDim.new(0, 6)
        SpeedCorner.Parent = SpeedSlider

        -- Biome Selection
        local BiomeLabel = Instance.new("TextLabel")
        BiomeLabel.Size = UDim2.new(1, 0, 0, 20)
        BiomeLabel.Position = UDim2.new(0, 0, 0, 120)
        BiomeLabel.BackgroundTransparency = 1
        BiomeLabel.Text = "Select Biome:"
        BiomeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        BiomeLabel.TextSize = 14
        BiomeLabel.Font = Enum.Font.Gotham
        BiomeLabel.TextXAlignment = Enum.TextXAlignment.Left
        BiomeLabel.Parent = RollingPage

        local BiomeDropdown = Instance.new("TextButton")
        BiomeDropdown.Size = UDim2.new(1, 0, 0, 30)
        BiomeDropdown.Position = UDim2.new(0, 0, 0, 140)
        BiomeDropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        BiomeDropdown.Text = selectedBiome .. " ▼"
        BiomeDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
        BiomeDropdown.TextSize = 13
        BiomeDropdown.Font = Enum.Font.Gotham
        BiomeDropdown.Parent = RollingPage
        
        local BiomeCorner = Instance.new("UICorner")
        BiomeCorner.CornerRadius = UDim.new(0, 6)
        BiomeCorner.Parent = BiomeDropdown

        -- Quick Action Buttons
        local QuickActions = {"Auto Claim", "Auto Sell", "Auto Equip Best"}
        local yPos = 185
        
        for _, action in ipairs(QuickActions) do
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, 0, 0, 35)
            Btn.Position = UDim2.new(0, 0, 0, yPos)
            Btn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
            Btn.Text = action
            Btn.TextColor3 = Color3.fromRGB(200, 200, 220)
            Btn.TextSize = 13
            Btn.Font = Enum.Font.GothamSemibold
            Btn.Parent = RollingPage
            
            local BtnCorner = Instance.new("UICorner")
            BtnCorner.CornerRadius = UDim.new(0, 6)
            BtnCorner.Parent = Btn
            
            yPos = yPos + 42
        end

        -- Settings Page
        local SettingsPage = Instance.new("Frame")
        SettingsPage.Size = UDim2.new(1, 0, 1, -35)
        SettingsPage.Position = UDim2.new(0, 0, 0, 35)
        SettingsPage.BackgroundTransparency = 1
        SettingsPage.Visible = false
        SettingsPage.Parent = ContentFrame
        Pages.Settings = SettingsPage

        local settingsList = {"Hide Username", "Anti-AFK", "Auto Rejoin", "Low Graphics Mode"}
        local settingsY = 10
        
        for _, setting in ipairs(settingsList) do
            local SettingFrame = Instance.new("Frame")
            SettingFrame.Size = UDim2.new(1, 0, 0, 35)
            SettingFrame.Position = UDim2.new(0, 0, 0, settingsY)
            SettingFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
            SettingFrame.Parent = SettingsPage
            
            local SettingCorner = Instance.new("UICorner")
            SettingCorner.CornerRadius = UDim.new(0, 6)
            SettingCorner.Parent = SettingFrame

            local SettingLabel = Instance.new("TextLabel")
            SettingLabel.Size = UDim2.new(0.7, 0, 1, 0)
            SettingLabel.Position = UDim2.new(0, 10, 0, 0)
            SettingLabel.BackgroundTransparency = 1
            SettingLabel.Text = setting
            SettingLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
            SettingLabel.TextSize = 13
            SettingLabel.Font = Enum.Font.Gotham
            SettingLabel.TextXAlignment = Enum.TextXAlignment.Left
            SettingLabel.Parent = SettingFrame

            local ToggleBtn = Instance.new("TextButton")
            ToggleBtn.Size = UDim2.new(0, 50, 0, 25)
            ToggleBtn.Position = UDim2.new(1, -60, 0, 5)
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            ToggleBtn.Text = "OFF"
            ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            ToggleBtn.TextSize = 11
            ToggleBtn.Font = Enum.Font.GothamBold
            ToggleBtn.Parent = SettingFrame
            
            local ToggleCorner = Instance.new("UICorner")
            ToggleCorner.CornerRadius = UDim.new(0, 12)
            ToggleCorner.Parent = ToggleBtn
            
            settingsY = settingsY + 42
        end

        -- Stats Page
        local StatsPage = Instance.new("Frame")
        StatsPage.Size = UDim2.new(1, 0, 1, -35)
        StatsPage.Position = UDim2.new(0, 0, 0, 35)
        StatsPage.BackgroundTransparency = 1
        StatsPage.Visible = false
        StatsPage.Parent = ContentFrame
        Pages.Stats = StatsPage

        local statsData = {
            {"Total Rolls", "0"},
            {"Rare Auras", "0"},
            {"Legendary Auras", "0"},
            {"Mythic Auras", "0"},
            {"Current Luck", "0x"}
        }
        
        local statsY = 10
        for _, stat in ipairs(statsData) do
            local StatFrame = Instance.new("Frame")
            StatFrame.Size = UDim2.new(1, 0, 0, 40)
            StatFrame.Position = UDim2.new(0, 0, 0, statsY)
            StatFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
            StatFrame.Parent = StatsPage
            
            local StatCorner = Instance.new("UICorner")
            StatCorner.CornerRadius = UDim.new(0, 6)
            StatCorner.Parent = StatFrame

            local StatLabel = Instance.new("TextLabel")
            StatLabel.Size = UDim2.new(0.6, 0, 1, 0)
            StatLabel.Position = UDim2.new(0, 15, 0, 0)
            StatLabel.BackgroundTransparency = 1
            StatLabel.Text = stat[1]
            StatLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
            StatLabel.TextSize = 14
            StatLabel.Font = Enum.Font.Gotham
            StatLabel.TextXAlignment = Enum.TextXAlignment.Left
            StatLabel.Parent = StatFrame

            local StatValue = Instance.new("TextLabel")
            StatValue.Size = UDim2.new(0.4, -20, 1, 0)
            StatValue.Position = UDim2.new(0.6, 0, 0, 0)
            StatValue.BackgroundTransparency = 1
            StatValue.Text = stat[2]
            StatValue.TextColor3 = Color3.fromRGB(100, 200, 255)
            StatValue.TextSize = 16
            StatValue.Font = Enum.Font.GothamBold
            StatValue.TextXAlignment = Enum.TextXAlignment.Right
            StatValue.Parent = StatFrame
            
            statsY = statsY + 46
        end

        -- Misc Page
        local MiscPage = Instance.new("Frame")
        MiscPage.Size = UDim2.new(1, 0, 1, -35)
        MiscPage.Position = UDim2.new(0, 0, 0, 35)
        MiscPage.BackgroundTransparency = 1
        MiscPage.Visible = false
        MiscPage.Parent = ContentFrame
        Pages.Misc = MiscPage

        local miscButtons = {
            "🎮 Teleport to Best Biome",
            "💫 Use All Luck Boosts",
            "🎯 Auto Collect Rewards",
            "🔮 Spawn Best Aura"
        }
        
        local miscY = 10
        for _, miscBtn in ipairs(miscButtons) do
            local MscBtn = Instance.new("TextButton")
            MscBtn.Size = UDim2.new(1, 0, 0, 40)
            MscBtn.Position = UDim2.new(0, 0, 0, miscY)
            MscBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
            MscBtn.Text = miscBtn
            MscBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
            MscBtn.TextSize = 13
            MscBtn.Font = Enum.Font.GothamSemibold
            MscBtn.Parent = MiscPage
            
            local MscCorner = Instance.new("UICorner")
            MscCorner.CornerRadius = UDim.new(0, 6)
            MscCorner.Parent = MscBtn
            
            miscY = miscY + 46
        end

        -- Tab Switching
        for tabName, button in pairs(tabButtons) do
            button.MouseButton1Click:Connect(function()
                for _, page in pairs(Pages) do
                    page.Visible = false
                end
                Pages[tabName].Visible = true
                
                for _, btn in pairs(tabButtons) do
                    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
                end
                button.BackgroundColor3 = Color3.fromRGB(60, 60, 180)
            end)
        end

        -- Button Functionality
        AutoRollBtn.MouseButton1Click:Connect(function()
            isAutoRoll = not isAutoRoll
            if isAutoRoll then
                AutoRollBtn.Text = "⏸️ STOP AUTO ROLL"
                AutoRollBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
                notify("CaggyHub", "Auto Roll Started!", 2)
            else
                AutoRollBtn.Text = "⚡ START AUTO ROLL"
                AutoRollBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 180)
                notify("CaggyHub", "Auto Roll Stopped!", 2)
            end
        end)

        -- Draggable
        local dragging = false
        local dragStart = nil
        local startPos = nil
        
        TitleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = MainFrame.Position
            end
        end)
        
        TitleBar.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        TitleBar.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                MainFrame.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end)

        -- Minimize/Close
        local minimized = false
        MinBtn.MouseButton1Click:Connect(function()
            minimized = not minimized
            if minimized then
                ContentFrame.Visible = false
                MainFrame.Size = UDim2.new(0, 350, 0, 40)
            else
                ContentFrame.Visible = true
                MainFrame.Size = UDim2.new(0, 350, 0, 480)
            end
        end)
        
    end)
    
    if not success then
        warn("GUI Creation Error: " .. tostring(err))
    end
end

-- Auto Roll Function
local function autoRoll()
    while isAutoRoll and task.wait(rollSpeed > 0 and (1 / rollSpeed) or 0.1) do
        pcall(function()
            local rollBtn = findRollButton()
            if rollBtn then
                fireclick(rollBtn)
                stats.totalRolls = stats.totalRolls + 1
            end
        end)
    end
end

-- Find Roll Button
function findRollButton()
    -- Common roll button locations for RNG games
    local possiblePaths = {
        game.Players.LocalPlayer.PlayerGui:FindFirstChild("Roll", true),
        game.Players.LocalPlayer.PlayerGui:FindFirstChild("RollButton", true),
        workspace:FindFirstChild("Roll", true)
    }
    
    for _, path in ipairs(possiblePaths) do
        if path and path:IsA("GuiButton") or path and path:IsA("TextButton") then
            return path
        end
    end
    
    return nil
end

-- Safe fireclick
function fireclick(button)
    if button then
        local events = {
            button.MouseButton1Click,
            button.Activated,
            button.MouseButton1Down
        }
        
        for _, event in ipairs(events) do
            if event then
                pcall(function()
                    event:Fire()
                end)
            end
        end
    end
end

-- Detect Aura
local function detectAura()
    pcall(function()
        local auraGui = Player.PlayerGui:FindFirstChild("Aura", true)
        if auraGui then
            local rarity = string.lower(tostring(auraGui.Text or ""))
            if rarity:find("rare") then
                stats.rareAuras = stats.rareAuras + 1
            elseif rarity:find("legendary") then
                stats.legendaryAuras = stats.legendaryAuras + 1
            elseif rarity:find("mythic") then
                stats.mythicAuras = stats.mythicAuras + 1
            end
        end
    end)
end

-- Anti-AFK
local function antiAFK()
    local vu = game:GetService("VirtualUser")
    Player.Idled:Connect(function()
        vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end

-- Main Initialization
local function init()
    print("🎲 CaggyHub Slime RNG Script Loaded!")
    print("📊 Version: 3.0 | Developer: CaggyHub")
    
    -- Create GUI
    createGUI()
    
    -- Start Systems
    task.spawn(function()
        while task.wait() do
            if isAutoRoll then
                autoRoll()
            end
        end
    end)
    
    -- Detect Auras
    task.spawn(function()
        while task.wait(0.5) do
            detectAura()
        end
    end)
    
    -- Anti-AFK
    antiAFK()
    
    notify("🎮 CaggyHub", "Slime RNG Script Loaded Successfully!", 3)
end

-- Execute
init()
