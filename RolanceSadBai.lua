local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Kyypie Hub | +1 Punch Per Click",
   Icon = 109469954305452,
   LoadingTitle = "Kyypie Hub",
   LoadingSubtitle = "by Markyy",
   ShowText = "Mahenang Rolance",
   Theme = "Amethyst",
   ToggleUIKeybind = "K",
   ConfigurationSaving = {
      Enabled = false,
      FolderName = "KyypieHub",
      FileName = "Markyy"
   },
   Discord = { Enabled = false },
   KeySystem = true,
   KeySettings = {
      Title = "Kyypie Hub",
      Subtitle = "Key System",
      Note = "Rolance Walang Bitaw", 
      FileName = "Kyy-key", 
      SaveKey = false,
      GrabKeyFromSite = false, 
      Key = {
          "RolanceMahena",
          "key_01736"
      }
   }
})

-- ==================== SERVICES ====================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local plr = Players.LocalPlayer
local cam = Workspace.CurrentCamera

-- ==================== VARIABLES ====================
local AutoPunchEnabled = false
local AutoRebirthEnabled = false
local AutoTitleEnabled = false
local AutoPowerBoostEnabled = false
local AutoWinsBoostEnabled = false
local AutoLuckBoostEnabled = false
local AutoAurasEnabled = false
local AutoEggEnabled = false
local SelectedEgg = "Basic"
local SelectedAura = "Yellow"

-- Walk Speed & No Clip
local WalkSpeedValue = 16
local NoClipEnabled = false

-- ==================== TABS (3 ONLY) ====================

-- ========== TAB 1: MAIN ==========
local MainTab = Window:CreateTab("Main", 4483345998)

MainTab:CreateToggle({
   Name = "Auto Punch",
   CurrentValue = false,
   Flag = "AutoPunchToggle",
   Callback = function(Value)
      AutoPunchEnabled = Value
   end
})

MainTab:CreateToggle({
   Name = "Auto Rebirth",
   CurrentValue = false,
   Flag = "AutoRebirthToggle",
   Callback = function(Value)
      AutoRebirthEnabled = Value
   end
})

MainTab:CreateToggle({
   Name = "Auto Roll Title",
   CurrentValue = false,
   Flag = "AutoTitleToggle",
   Callback = function(Value)
      AutoTitleEnabled = Value
   end
})

MainTab:CreateInput({
   Name = "Walk Speed",
   PlaceholderText = "Enter speed (16-500)",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      local num = tonumber(Text)
      if num then
         WalkSpeedValue = math.clamp(num, 1, 500)
      end
   end
})

MainTab:CreateToggle({
   Name = "No Clip",
   CurrentValue = false,
   Flag = "NoClipToggle",
   Callback = function(Value)
      NoClipEnabled = Value
   end
})

-- ========== TAB 2: BOOSTS ==========
local BoostsTab = Window:CreateTab("Boosts", 4483345998)

BoostsTab:CreateToggle({
   Name = "Auto Power Boost",
   CurrentValue = false,
   Flag = "AutoPowerBoostToggle",
   Callback = function(Value)
      AutoPowerBoostEnabled = Value
   end
})

BoostsTab:CreateToggle({
   Name = "Auto Wins Boost",
   CurrentValue = false,
   Flag = "AutoWinsBoostToggle",
   Callback = function(Value)
      AutoWinsBoostEnabled = Value
   end
})

BoostsTab:CreateToggle({
   Name = "Auto Luck Boost",
   CurrentValue = false,
   Flag = "AutoLuckBoostToggle",
   Callback = function(Value)
      AutoLuckBoostEnabled = Value
   end
})

-- ========== TAB 3: SHOP ==========
local ShopTab = Window:CreateTab("Shop", 4483345998)

ShopTab:CreateDropdown({
   Name = "Select Aura",
   Options = {"Yellow", "Blue", "Red", "Green", "Purple", "Orange", "Acquatic", "Eternal"},
   CurrentOption = "Yellow",
   Flag = "AuraDropdown",
   Callback = function(Option)
      SelectedAura = Option
   end
})

ShopTab:CreateToggle({
   Name = "Auto Buy Aura",
   CurrentValue = false,
   Flag = "AutoAurasToggle",
   Callback = function(Value)
      AutoAurasEnabled = Value
   end
})

ShopTab:CreateButton({
   Name = "Buy All Auras",
   Callback = function()
      local trails = {"Yellow", "Blue", "Red", "Green", "Purple", "Orange", "Acquatic", "Eternal"}
      for _, aura in ipairs(trails) do
         ReplicatedStorage.Remotes.TrailsAction:FireServer({["action"] = "WinBuy", ["key"] = aura})
         task.wait(0.1)
      end
      Rayfield:Notify({
         Title = "Auras",
         Content = "All auras purchased!",
         Duration = 3,
         Image = 4483345998
      })
   end
})

ShopTab:CreateDropdown({
   Name = "Select Egg",
   Options = {"Basic", "Cracked", "Shroom", "Tree", "Coconut", "Retro"},
   CurrentOption = "Basic",
   Flag = "EggDropdown",
   Callback = function(Option)
      SelectedEgg = Option
   end
})

ShopTab:CreateToggle({
   Name = "Auto Hatch Selected Egg",
   CurrentValue = false,
   Flag = "AutoEggToggle",
   Callback = function(Value)
      AutoEggEnabled = Value
   end
})

-- ==================== MAIN LOOP ====================
RunService.Heartbeat:Connect(function()
   -- Auto Punch
   if AutoPunchEnabled then
      pcall(function()
         ReplicatedStorage.Remotes.PunchRequest:FireServer({["kind"] = "click"})
      end)
   end

   -- Auto Rebirth
   if AutoRebirthEnabled then
      pcall(function()
         ReplicatedStorage.Remotes.RebirthRequest:FireServer("Rebirth")
      end)
   end

   -- Auto Roll Title
   if AutoTitleEnabled then
      pcall(function()
         ReplicatedStorage.Remotes.TitleRollRequest:InvokeServer("Roll")
      end)
   end

   -- Walk Speed (Input value)
   pcall(function()
      local char = plr.Character
      if char and char:FindFirstChild("Humanoid") then
         char.Humanoid.WalkSpeed = WalkSpeedValue
      end
   end)

   -- No Clip
   if NoClipEnabled then
      pcall(function()
         local char = plr.Character
         if char then
            for _, part in pairs(char:GetDescendants()) do
               if part:IsA("BasePart") then
                  part.CanCollide = false
               end
            end
         end
      end)
   end

   -- Auto Power Boost
   if AutoPowerBoostEnabled then
      pcall(function()
         ReplicatedStorage.Remotes.BoostAction:InvokeServer("BuyWithWins", "Power")
      end)
   end

   -- Auto Wins Boost
   if AutoWinsBoostEnabled then
      pcall(function()
         ReplicatedStorage.Remotes.BoostAction:InvokeServer("BuyWithWins", "Wins")
      end)
   end

   -- Auto Luck Boost
   if AutoLuckBoostEnabled then
      pcall(function()
         ReplicatedStorage.Remotes.BoostAction:InvokeServer("BuyWithWins", "Luck")
      end)
   end

   -- Auto Buy Aura
   if AutoAurasEnabled then
      pcall(function()
         ReplicatedStorage.Remotes.TrailsAction:FireServer({["action"] = "WinBuy", ["key"] = SelectedAura})
      end)
   end

   -- Auto Hatch Egg
   if AutoEggEnabled then
      pcall(function()
         ReplicatedStorage.Remotes.Functions.Pets_HatchEgg:InvokeServer(SelectedEgg)
      end)
   end
end)

Rayfield:LoadConfiguration()
