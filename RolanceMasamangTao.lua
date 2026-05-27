local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
 
local Window = Rayfield:CreateWindow({
   Name = "Kyypie Hub - Slime RNG",
   Icon = 109469954305452,
   LoadingTitle = "Kyype Hub",
   LoadingSubtitle = "by Markyy",
   ShowText = "Mahenang Rolance",
   Theme = "Ocean",
   ToggleUIKeybind = "K",
   ConfigurationSaving = {
      Enabled = true,
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
      SaveKey = true,
      GrabKeyFromSite = false, 
Key = {
    "RolanceMahena",
    "key_01736",
    "key_90544",
    "key_66120",
    "key_23877",
    "key_69740"
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
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local plr = Players.LocalPlayer
local cam = Workspace.CurrentCamera

-- ==================== REMOTES ====================
local Remotes
local function GetRemotes()
    local success, result = pcall(function()
        return ReplicatedStorage:WaitForChild("Packages", 10)
            :WaitForChild("_Index", 10)
            :WaitForChild("leifstout_networker@0.3.1", 10)
            :WaitForChild("networker", 10)
            :WaitForChild("_remotes", 10)
    end)
    if success then
        return result
    end
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj.Name == "_remotes" and obj:IsA("Folder") then
            return obj
        end
    end
    return nil
end

Remotes = GetRemotes()

local SlimeGunRemote, ZonesRemote, RollRemote, LootRemote, BoostRemote
if Remotes then
    local slimeService = Remotes:FindFirstChild("SlimeGunService")
    if slimeService then
        SlimeGunRemote = slimeService:FindFirstChild("RemoteFunction")
    end
    local zoneService = Remotes:FindFirstChild("ZonesService")
    if zoneService then
        ZonesRemote = zoneService:FindFirstChild("RemoteFunction")
    end
    local rollService = Remotes:FindFirstChild("RollService")
    if rollService then
        RollRemote = rollService:FindFirstChild("RemoteFunction")
    end
    local lootService = Remotes:FindFirstChild("LootService")
    if lootService then
        LootRemote = lootService:FindFirstChild("RemoteFunction")
    end
    local boostService = Remotes:FindFirstChild("BoostService")
    if boostService then
        BoostRemote = boostService:FindFirstChild("RemoteFunction")
    end
end

print("[Kyypie] Remotes loaded:")
print("  SlimeGunRemote:", SlimeGunRemote and "OK" or "NOT FOUND")
print("  ZonesRemote:", ZonesRemote and "OK" or "NOT FOUND")
print("  RollRemote:", RollRemote and "OK" or "NOT FOUND")
print("  LootRemote:", LootRemote and "OK" or "NOT FOUND")
print("  BoostRemote:", BoostRemote and "OK" or "NOT FOUND")

-- ==================== SAFE FLAG ACCESS ====================
local function getFlag(name)
    if not Rayfield or not Rayfield.Flags then return false end
    local f = Rayfield.Flags[name]
    if not f or type(f) ~= "table" then return false end
    if f.CurrentValue ~= nil then
        return f.CurrentValue == true
    end
    return false
end

-- ==================== STATE ====================
local State = {
    humanizer = false,
    espEnabled = false,
    espColor = Color3.fromRGB(0, 150, 255),
    espMode = {},
    lastJump = 0,
    currentZoneNum = -1,
    zoneSpawnPos = nil,
    lastZoneScan = 0,
    isTravelingToZone = false,
    zoneCooldownEnd = 0,
    zoneArrivalTime = 0,
    hasArrivedAtZone = false,
    activeTask = "idle",
    lastEnemyMove = 0,
    lastLootETime = 0,
    lastM1Time = 0,
    m1Down = false,
    eDown = false,
    lastFruitETime = 0,
    fruitCollectionRadius = 50,
    lastFruitScan = 0,
    cachedFruits = {},
    fruitScanInterval = 0.5,
    lastRollTime = 0,
    selectedPotion = "Luck Boost",
    lastPotionTime = 0,
    potionCooldown = 2,
    walkSpeed = 16,
    configName = "",
    autoLoadConfigName = "Default",
    toggles = {
        auto1 = false,
        auto2 = false,
        autoFruit1 = false,
        autoZone1 = false,
        autoBlaster1 = false,
        humanizer1 = false,
        esp1 = false,
        autoRoll1 = false,
        fastRoll1 = false,
        autoPotion1 = false,
        antiKick = false,
        antiIdle = false,
        noclip = false,
        infiniteJump = false,
        autoSaveConfig = false,
        autoLoadConfig = false,
    }
}

-- ==================== INPUT HELPERS ====================
local function fireSlimeGun(model)
    if not model or not model.Parent then return end
    pcall(function()
        if SlimeGunRemote then
            SlimeGunRemote:InvokeServer("tryFireSlimeGun", model)
        end
    end)
end

local function purchaseNextZone()
    pcall(function()
        if ZonesRemote then
            ZonesRemote:InvokeServer("requestPurchaseZone")
        end
    end)
end

-- ==================== ROLL ====================
local function doRoll()
    pcall(function()
        if RollRemote then
            RollRemote:InvokeServer("requestRoll", true)
        end
    end)
end

-- ==================== BOOST / POTION ====================
local potionNameMap = {
    ["Luck Boost"] = "luck",
    ["Ultra Luck Boost"] = "ultraLuck",
    ["Currency Boost"] = "currency",
    ["Roll Speed Boost"] = "rollSpeed",
}

local function usePotion(potionName)
    local internalName = potionNameMap[potionName] or potionName
    pcall(function()
        if BoostRemote then
            BoostRemote:InvokeServer("requestUseBoost", internalName)
        end
    end)
end

local function setM1(down)
    if State.m1Down == down then return end
    State.m1Down = down
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, down, game, 0)
    end)
end

local function setE(down)
    if State.eDown == down then return end
    State.eDown = down
    pcall(function()
        VirtualInputManager:SendKeyEvent(down, Enum.KeyCode.E, false, game)
    end)
end

local function releaseAllInputs()
    setE(false)
end

-- ==================== CHARACTER HELPERS ====================
local function getChar() return plr.Character end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getPos(obj)
    if not obj then return nil end
    if obj:IsA("Model") then
        local p = obj:GetPivot()
        return p and p.Position
    elseif obj:IsA("BasePart") or obj:IsA("MeshPart") then
        return obj.Position
    elseif obj:IsA("Attachment") then
        return obj.WorldPosition
    end
    return nil
end
local function distToPos(pos)
    local hrp = getHRP()
    if not hrp or not pos then return math.huge end
    return (hrp.Position - pos).Magnitude
end
local function rng(a, b) return a + math.random() * (b - a) end

-- ==================== ZONE HELPERS ====================
local function getHighestOwnedZone()
    local zones = Workspace:FindFirstChild("Zones")
    if not zones then return nil, nil end
    local highestNum = -1
    local highestZone = nil
    for _, zone in ipairs(zones:GetChildren()) do
        local num = tonumber(zone.Name)
        if num and num > highestNum then
            local gate = zone:FindFirstChild("Gate")
            if gate then
                local back = gate:FindFirstChild("Back")
                if back and back:IsA("BasePart") and back.CanTouch == false then
                    highestNum = num
                    highestZone = zone
                end
            end
        end
    end
    if highestZone then
        local poi = highestZone:FindFirstChild("POI")
        if poi then
            local spawnPoint = poi:FindFirstChild("PlayerSpawn")
            if spawnPoint then
                return highestNum, getPos(spawnPoint)
            end
        end
    end
    return nil, nil
end

local function getZoneSpawn(zoneNum)
    local zones = Workspace:FindFirstChild("Zones")
    if not zones then return nil end
    local zone = zones:FindFirstChild(tostring(zoneNum))
    if not zone then return nil end
    local poi = zone:FindFirstChild("POI")
    if not poi then return nil end
    local spawnPoint = poi:FindFirstChild("PlayerSpawn")
    if not spawnPoint then return nil end
    return getPos(spawnPoint)
end

-- ==================== HEALTH PARSER ====================
local function parseHealthText(text)
    if type(text) ~= "string" then return nil, nil end
    text = text:gsub("%s+", "")
    local curStr, maxStr = text:match("^([%d%.]+[KMB]?)/([%d%.]+[KMB]?)$")
    if not curStr then return nil, nil end
    local function toNum(s)
        local suffix = s:sub(-1):upper()
        local mult = 1
        if suffix == "K" then mult = 1e3; s = s:sub(1, -2)
        elseif suffix == "M" then mult = 1e6; s = s:sub(1, -2)
        elseif suffix == "B" then mult = 1e9; s = s:sub(1, -2) end
        local n = tonumber(s)
        return n and n * mult or nil
    end
    return toNum(curStr), toNum(maxStr)
end

local function getEnemyHealth(enemy)
    local bb = enemy:FindFirstChild("HealthBarBillboardGui")
    if not bb then return nil, nil end
    local hpLabel = bb:FindFirstChild("Hp")
    if not hpLabel then return nil, nil end
    return parseHealthText(hpLabel.Text)
end

-- ==================== RAYCAST VISUALS ====================
local RayFolder = Instance.new("Folder")
RayFolder.Name = "MarkyyRays"
RayFolder.Parent = Workspace

local PathRay = Instance.new("Part")
PathRay.Name = "PathRay"
PathRay.Size = Vector3.new(0.12, 0.12, 1)
PathRay.Anchored = true
PathRay.CanCollide = false
PathRay.CanQuery = false
PathRay.CanTouch = false
PathRay.CastShadow = false
PathRay.Material = Enum.Material.Neon
PathRay.Color = Color3.fromRGB(0, 150, 255)
PathRay.Transparency = 0.15
PathRay.Parent = RayFolder

local ForwardRay = Instance.new("Part")
ForwardRay.Name = "ForwardRay"
ForwardRay.Size = Vector3.new(0.1, 0.1, 1)
ForwardRay.Anchored = true
ForwardRay.CanCollide = false
ForwardRay.CanQuery = false
ForwardRay.CanTouch = false
ForwardRay.CastShadow = false
ForwardRay.Material = Enum.Material.Neon
ForwardRay.Color = Color3.fromRGB(0, 200, 255)
ForwardRay.Transparency = 0.2
ForwardRay.Parent = RayFolder

local FruitRay = Instance.new("Part")
FruitRay.Name = "FruitRay"
FruitRay.Size = Vector3.new(0.15, 0.15, 1)
FruitRay.Anchored = true
FruitRay.CanCollide = false
FruitRay.CanQuery = false
FruitRay.CanTouch = false
FruitRay.CastShadow = false
FruitRay.Material = Enum.Material.Neon
FruitRay.Color = Color3.fromRGB(0, 255, 200)
FruitRay.Transparency = 0.1
FruitRay.Parent = RayFolder

local function updateRayPart(part, from, to, color)
    if not from or not to then
        part.Size = Vector3.new(0.01, 0.01, 0.01)
        return
    end
    local dist = (to - from).Magnitude
    if dist < 0.01 then
        part.Size = Vector3.new(0.01, 0.01, 0.01)
        return
    end
    part.Size = Vector3.new(part.Size.X, part.Size.Y, dist)
    part.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -dist / 2)
    if color then part.Color = color end
end

local function hidePathRay()
    PathRay.Size = Vector3.new(0.01, 0.01, 0.01)
end

local function hideFruitRay()
    FruitRay.Size = Vector3.new(0.01, 0.01, 0.01)
end

local function getIgnoreList(target)
    local list = {getChar(), RayFolder}
    if target and target:IsA("Model") then
        for _, d in ipairs(target:GetDescendants()) do
            if d:IsA("BasePart") then table.insert(list, d) end
        end
    elseif target and target:IsA("BasePart") then
        table.insert(list, target)
    end
    return list
end

local function checkObstacle(from, to, ignoreList)
    local dir = to - from
    local dist = dir.Magnitude
    if dist < 0.1 then return "clear" end
    local unit = dir.Unit
    local checkDist = math.min(dist, 24)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = ignoreList or {}
    local waistResult = Workspace:Raycast(from + Vector3.new(0, 2.5, 0), unit * checkDist, params)
    if waistResult then
        local jumpResult = Workspace:Raycast(from + Vector3.new(0, 5.5, 0), unit * checkDist, params)
        if not jumpResult then
            return "jumpable", waistResult.Position
        else
            return "blocked", waistResult.Position
        end
    end
    return "clear"
end

local function tryJump()
    if tick() - State.lastJump > 0.22 then
        local hum = getHum()
        if hum then hum.Jump = true end
        State.lastJump = tick()
    end
end

-- ==================== ESP SYSTEM ====================
local ESPObjects = {}

local function createESP(model)
    local box = Drawing.new("Square")
    box.Visible = false; box.Filled = false; box.Thickness = 1.5
    box.Color = State.espColor; box.Transparency = 1
    local tracer = Drawing.new("Line")
    tracer.Visible = false; tracer.Thickness = 1.2
    tracer.Color = State.espColor; tracer.Transparency = 1
    local healthBg = Drawing.new("Square")
    healthBg.Visible = false; healthBg.Filled = true; healthBg.Thickness = 0
    healthBg.Color = Color3.fromRGB(30, 30, 30); healthBg.Transparency = 0.85
    local healthBar = Drawing.new("Square")
    healthBar.Visible = false; healthBar.Filled = true; healthBar.Thickness = 0
    healthBar.Transparency = 1
    ESPObjects[model] = {box = box, tracer = tracer, healthBg = healthBg, healthBar = healthBar}
end

local function removeESP(model)
    local d = ESPObjects[model]
    if d then
        pcall(function() d.box:Remove() end)
        pcall(function() d.tracer:Remove() end)
        pcall(function() d.healthBg:Remove() end)
        pcall(function() d.healthBar:Remove() end)
        ESPObjects[model] = nil
    end
end

local function clearAllESP()
    for m, _ in pairs(ESPObjects) do removeESP(m) end
end

local function hasMode(modeName)
    for _, v in ipairs(State.espMode or {}) do
        if v == modeName then return true end
    end
    return false
end

local function updateESP()
    if not State.espEnabled then
        for _, d in pairs(ESPObjects) do
            pcall(function()
                d.box.Visible = false; d.tracer.Visible = false
                d.healthBg.Visible = false; d.healthBar.Visible = false
            end)
        end
        return
    end
    local eFolder
    for _, obj in ipairs(Workspace:GetChildren()) do
        if string.find(obj.Name, "Gameplay") then
            eFolder = obj:FindFirstChild("Enemies")
            break
        end
    end
    if not eFolder then clearAllESP(); return end
    local enemies = eFolder:GetChildren()
    local current = {}
    for _, e in ipairs(enemies) do
        if e:IsA("Model") then
            current[e] = true
            if not ESPObjects[e] then createESP(e) end
        end
    end
    for m, _ in pairs(ESPObjects) do
        if not current[m] then removeESP(m) end
    end
    local showBox = hasMode("Box")
    local showHealth = hasMode("Health")
    for _, enemy in ipairs(enemies) do
        if not enemy:IsA("Model") then continue end
        local d = ESPObjects[enemy]
        if not d then continue end
        local okBB, cf, size = pcall(enemy.GetBoundingBox, enemy)
        if not okBB or not cf then continue end
        local corners = {
            cf * CFrame.new( size.X/2, size.Y/2, size.Z/2),
            cf * CFrame.new(-size.X/2, size.Y/2, size.Z/2),
            cf * CFrame.new( size.X/2, -size.Y/2, size.Z/2),
            cf * CFrame.new(-size.X/2, -size.Y/2, size.Z/2),
            cf * CFrame.new( size.X/2, size.Y/2, -size.Z/2),
            cf * CFrame.new(-size.X/2, size.Y/2, -size.Z/2),
            cf * CFrame.new( size.X/2, -size.Y/2, -size.Z/2),
            cf * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2),
        }
        local minX, minY = math.huge, math.huge
        local maxX, maxY = -math.huge, -math.huge
        local onScreen = false
        for _, c in ipairs(corners) do
            local pos, vis = cam:WorldToViewportPoint(c.Position)
            if vis then onScreen = true end
            minX = math.min(minX, pos.X); minY = math.min(minY, pos.Y)
            maxX = math.max(maxX, pos.X); maxY = math.max(maxY, pos.Y)
        end
        if onScreen then
            local w = maxX - minX
            local h = maxY - minY
            pcall(function()
                if showBox then
                    d.box.Visible = true
                    d.box.Size = Vector2.new(w, h)
                    d.box.Position = Vector2.new(minX, minY)
                    d.box.Color = State.espColor
                    d.tracer.Visible = true
                    d.tracer.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                    d.tracer.To = Vector2.new(minX + w / 2, maxY)
                    d.tracer.Color = State.espColor
                else
                    d.box.Visible = false; d.tracer.Visible = false
                end
            end)
            pcall(function()
                if showHealth then
                    local cur, max = getEnemyHealth(enemy)
                    if cur and max and max > 0 then
                        local pct = math.clamp(cur / max, 0, 1)
                        local barH = h * pct
                        local barW = 5
                        local gap = 4
                        local barX = minX - gap - barW
                        d.healthBg.Visible = true
                        d.healthBg.Size = Vector2.new(barW, h)
                        d.healthBg.Position = Vector2.new(barX, minY)
                        d.healthBar.Visible = true
                        d.healthBar.Size = Vector2.new(barW, barH)
                        d.healthBar.Position = Vector2.new(barX, minY + (h - barH))
                        d.healthBar.Color = Color3.fromRGB(255 * (1 - pct), 255 * pct, 0)
                    else
                        d.healthBg.Visible = false; d.healthBar.Visible = false
                    end
                else
                    d.healthBg.Visible = false; d.healthBar.Visible = false
                end
            end)
        else
            pcall(function()
                d.box.Visible = false; d.tracer.Visible = false
                d.healthBg.Visible = false; d.healthBar.Visible = false
            end)
        end
    end
end

-- ==================== TARGETING ====================
local function getEnemyFolder()
    for _, obj in ipairs(Workspace:GetChildren()) do
        if string.find(obj.Name, "Gameplay") then
            return obj:FindFirstChild("Enemies")
        end
    end
    return nil
end

local function getNearestEnemy()
    local f = getEnemyFolder()
    if not f then return nil end
    local list = f:GetChildren()
    if #list == 0 then return nil end
    local hrp = getHRP()
    if not hrp then return nil end
    local best, bestD = nil, math.huge
    for _, e in ipairs(list) do
        if e:IsA("Model") and e.Parent then
            local p = getPos(e)
            if p then
                local d = (hrp.Position - p).Magnitude
                if d < bestD then bestD = d; best = e end
            end
        end
    end
    return best
end

local function getNearestLoot()
    local f = Workspace:FindFirstChild("Loot")
    if not f then return nil end
    local list = f:GetChildren()
    if #list == 0 then return nil end
    local hrp = getHRP()
    if not hrp then return nil end
    local best, bestD = nil, math.huge
    for _, l in ipairs(list) do
        if l.Parent then
            local p = getPos(l)
            if p then
                local d = (hrp.Position - p).Magnitude
                if d < bestD then bestD = d; best = l end
            end
        end
    end
    return best
end

-- ==================== OPTIMIZED FRUIT DETECTION ====================
local fruitKeywords = {
    "fruit", "berry", "apple", "orange", "banana", "mango",
    "coconut", "melon", "grape", "cherry", "pearl", "gem",
    "collectible", "drop", "item"
}

local knownFruitFolders = {"Fruits", "FruitSpawns", "Collectibles", "Drops", "Items", "Spawns"}

local function isFruitObject(obj)
    if not obj or not obj.Parent then return false end
    local name = obj.Name:lower()
    for _, kw in ipairs(fruitKeywords) do
        if name:find(kw) then return true end
    end
    if obj:IsA("BasePart") or obj:IsA("Model") or obj:IsA("MeshPart") then
        if obj:FindFirstChildOfClass("ProximityPrompt") then return true end
        if obj:FindFirstChildOfClass("ClickDetector") then return true end
    end
    local parent = obj.Parent
    if parent then
        local pName = parent.Name:lower()
        for _, kw in ipairs(fruitKeywords) do
            if pName:find(kw) then return true end
        end
    end
    return false
end

local function scanFruits()
    local fruits = {}
    local hrp = getHRP()
    if not hrp then return fruits end
    local myPos = hrp.Position
    local checked = {}

    for _, obj in ipairs(Workspace:GetChildren()) do
        if isFruitObject(obj) then
            local pos = getPos(obj)
            if pos then
                local dist = (myPos - pos).Magnitude
                if dist <= State.fruitCollectionRadius then
                    table.insert(fruits, {object = obj, distance = dist, position = pos})
                    checked[obj] = true
                end
            end
        end
        if obj:IsA("Folder") or obj:IsA("Model") then
            for _, child in ipairs(obj:GetChildren()) do
                if not checked[child] and isFruitObject(child) then
                    local pos = getPos(child)
                    if pos then
                        local dist = (myPos - pos).Magnitude
                        if dist <= State.fruitCollectionRadius then
                            table.insert(fruits, {object = child, distance = dist, position = pos})
                            checked[child] = true
                        end
                    end
                end
            end
        end
    end

    for _, folderName in ipairs(knownFruitFolders) do
        local folder = Workspace:FindFirstChild(folderName)
        if folder then
            for _, obj in ipairs(folder:GetChildren()) do
                if not checked[obj] and obj.Parent then
                    local pos = getPos(obj)
                    if pos then
                        local dist = (myPos - pos).Magnitude
                        if dist <= State.fruitCollectionRadius then
                            table.insert(fruits, {object = obj, distance = dist, position = pos})
                            checked[obj] = true
                        end
                    end
                end
            end
        end
    end

    table.sort(fruits, function(a, b) return a.distance < b.distance end)
    return fruits
end

local function getNearestFruit()
    if tick() - State.lastFruitScan > 0.3 then
        State.lastFruitScan = tick()
        State.cachedFruits = scanFruits()
    end
    if #State.cachedFruits > 0 then
        return State.cachedFruits[1].object, State.cachedFruits[1].position, State.cachedFruits[1].distance
    end
    return nil, nil, math.huge
end

-- ==================== MOVEMENT ====================
local function tweenToZone(targetPos)
    local hrp = getHRP()
    local hum = getHum()
    if not hrp or not hum then return false end
    local dist = (hrp.Position - targetPos).Magnitude
    if dist <= 6 then return true end
    local wasAnchored = hrp.Anchored
    local wasCanCollide = hrp.CanCollide
    pcall(function()
        hrp.Anchored = true
        hrp.CanCollide = false
    end)
    local speed = 60
    local duration = math.clamp(dist / speed, 0.6, 14)
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(hrp, tweenInfo, {
        CFrame = CFrame.new(targetPos + Vector3.new(0, 4, 0))
    })
    tween:Play()
    local completed = false
    local conn
    conn = tween.Completed:Connect(function()
        completed = true
        if conn then conn:Disconnect() end
    end)
    local start = tick()
    while not completed do
        if tick() - start > duration + 4 then
            pcall(function() tween:Cancel() end)
            break
        end
        hrp = getHRP()
        if not hrp then
            pcall(function() tween:Cancel() end)
            break
        end
        tryJump()
        task.wait(0.06)
    end
    pcall(function()
        tween:Cancel()
        if conn then conn:Disconnect() end
        hrp = getHRP()
        if hrp and hrp.Parent then
            hrp.Anchored = wasAnchored
            hrp.CanCollide = wasCanCollide
        end
    end)
    return distToPos(targetPos) <= 8
end

local function smoothMoveToEnemy(enemy, humanizer)
    local hrp = getHRP()
    local hum = getHum()
    if not hrp or not hum then return end
    local ePos = getPos(enemy)
    if not ePos then return end
    if humanizer then
        if tick() - State.lastEnemyMove > 2.2 then
            State.lastEnemyMove = tick()
            local myPos = hrp.Position
            local dir = (myPos - ePos)
            if dir.Magnitude < 0.01 then dir = Vector3.new(1, 0, 0) end
            local target = ePos + dir.Unit * 3.5
            hum:MoveTo(target + Vector3.new(rng(-0.4, 0.4), 0, rng(-0.4, 0.4)))
        end
    else
        if tick() - State.lastEnemyMove > 0.14 then
            State.lastEnemyMove = tick()
            hum:MoveTo(ePos)
        end
    end
end

local function moveToLoot(loot)
    local hrp = getHRP()
    local hum = getHum()
    if not hrp or not hum then return false end
    local lootPos = getPos(loot)
    if not lootPos then return false end
    local dist = (hrp.Position - lootPos).Magnitude
    if dist <= 3.5 then return true end
    hum:MoveTo(lootPos)
    local ignore = getIgnoreList(nil)
    local status, hitPos = checkObstacle(hrp.Position, lootPos, ignore)
    if status == "jumpable" then
        tryJump()
        updateRayPart(PathRay, hrp.Position, hitPos or lootPos, Color3.fromRGB(255, 255, 0))
    elseif status == "blocked" then
        updateRayPart(PathRay, hrp.Position, hitPos or lootPos, Color3.fromRGB(255, 50, 50))
    else
        updateRayPart(PathRay, hrp.Position, lootPos, Color3.fromRGB(0, 150, 255))
    end
    return dist <= 4
end

local function moveToFruit(fruit)
    local hrp = getHRP()
    local hum = getHum()
    if not hrp or not hum then return false end
    local fruitPos = getPos(fruit)
    if not fruitPos then return false end
    local dist = (hrp.Position - fruitPos).Magnitude
    if dist <= 3 then return true end
    hum:MoveTo(fruitPos)
    local ignore = getIgnoreList(fruit)
    local status, hitPos = checkObstacle(hrp.Position, fruitPos, ignore)
    if status == "jumpable" then
        tryJump()
        updateRayPart(FruitRay, hrp.Position, hitPos or fruitPos, Color3.fromRGB(255, 255, 0))
    elseif status == "blocked" then
        updateRayPart(FruitRay, hrp.Position, hitPos or fruitPos, Color3.fromRGB(255, 50, 50))
    else
        updateRayPart(FruitRay, hrp.Position, fruitPos, Color3.fromRGB(0, 255, 200))
    end
    return dist <= 3.5
end

-- ==================== FRUIT INTERACTION ====================
local function interactWithFruit(fruit)
    if not fruit or not fruit.Parent then return false end
    local prompt = fruit:FindFirstChildOfClass("ProximityPrompt")
    if prompt then
        pcall(function() fireproximityprompt(prompt) end)
        return true
    end
    local clickDetector = fruit:FindFirstChildOfClass("ClickDetector")
    if clickDetector then
        pcall(function() fireclickdetector(clickDetector) end)
        return true
    end
    if tick() - State.lastFruitETime > 0.15 then
        State.lastFruitETime = tick()
        setE(true)
        task.wait(0.05)
        setE(false)
        return true
    end
    return false
end

-- ==================== ANTI KICK (FIXED) ====================
local antiKickEnabled = false

local function setupAntiKick()
    local ok, err = pcall(function()
        local mt = getrawmetatable(game)
        if not mt then
            warn("[KyypieHub] getrawmetatable returned nil. AntiKick unavailable.")
            return
        end
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "Kick" and self == plr and antiKickEnabled then
                warn("[KyypieHub] AntiKick: Blocked server kick attempt.")
                return nil
            end
            return oldNamecall(self, ...)
        end)
        
        setreadonly(mt, true)
    end)
    if not ok then
        warn("[KyypieHub] AntiKick setup error: " .. tostring(err))
    else
        print("[KyypieHub] AntiKick system initialized.")
    end
end

-- ==================== ANTI IDLE ====================
local antiIdleEnabled = false

-- ==================== NO CLIP ====================
local noclipConnection
local function setNoclip(enabled)
    if enabled then
        if noclipConnection then noclipConnection:Disconnect() end
        noclipConnection = RunService.Stepped:Connect(function()
            local char = getChar()
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        local char = getChar()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- ==================== INFINITE JUMP ====================
local infiniteJumpConnection
local function setInfiniteJump(enabled)
    if enabled then
        if infiniteJumpConnection then infiniteJumpConnection:Disconnect() end
        infiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
            local hum = getHum()
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    else
        if infiniteJumpConnection then
            infiniteJumpConnection:Disconnect()
            infiniteJumpConnection = nil
        end
    end
end

-- ==================== CONFIG SYSTEM ====================
local configFolder = "KyypieHub/Configs"

local function ensureConfigFolder()
    pcall(function()
        if not isfolder("KyypieHub") then
            makefolder("KyypieHub")
        end
        if not isfolder(configFolder) then
            makefolder(configFolder)
        end
    end)
end

local function getConfigNames()
    local names = {}
    pcall(function()
        for _, file in ipairs(listfiles(configFolder)) do
            local name = file:match("([^/\\]+)%.json$")
            if name then
                table.insert(names, name)
            end
        end
    end)
    return names
end

local function saveConfig(name)
    ensureConfigFolder()
    if not name or name == "" then name = "Default" end
    local data = {
        toggles = State.toggles,
        fruitRadius = State.fruitCollectionRadius,
        selectedPotion = State.selectedPotion,
        espColor = {R = State.espColor.R, G = State.espColor.G, B = State.espColor.B},
        espMode = State.espMode,
        walkSpeed = State.walkSpeed,
        autoLoadConfigName = State.autoLoadConfigName,
    }
    local success, err = pcall(function()
        writefile(configFolder .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    end)
    if success then
        Rayfield:Notify({Title = "Config Saved", Content = "Saved as: " .. name, Duration = 3, Image = 4483362458})
    else
        Rayfield:Notify({Title = "Config Error", Content = tostring(err), Duration = 3, Image = 4483362458})
    end
    return success
end

local function loadConfig(name)
    local success, data = pcall(function()
        local content = readfile(configFolder .. "/" .. name .. ".json")
        return HttpService:JSONDecode(content)
    end)
    if not success or not data then
        Rayfield:Notify({Title = "Config Error", Content = "Failed to load " .. name, Duration = 3, Image = 4483362458})
        return false
    end
    
    for key, value in pairs(data.toggles or {}) do
        if State.toggles[key] ~= nil then
            State.toggles[key] = value
        end
    end
    
    if data.fruitRadius then State.fruitCollectionRadius = data.fruitRadius end
    if data.selectedPotion then State.selectedPotion = data.selectedPotion end
    if data.espColor then State.espColor = Color3.new(data.espColor.R, data.espColor.G, data.espColor.B) end
    if data.espMode then State.espMode = data.espMode end
    if data.walkSpeed then
        State.walkSpeed = data.walkSpeed
        local hum = getHum()
        if hum then hum.WalkSpeed = State.walkSpeed end
    end
    if data.autoLoadConfigName then State.autoLoadConfigName = data.autoLoadConfigName end
    
    if State.toggles.noclip then setNoclip(true) else setNoclip(false) end
    if State.toggles.infiniteJump then setInfiniteJump(true) else setInfiniteJump(false) end
    
    antiKickEnabled = State.toggles.antiKick or false
    antiIdleEnabled = State.toggles.antiIdle or false
    
    pcall(function()
        if HumanizerToggle then HumanizerToggle:Set(State.toggles.humanizer1) end
        if FarmToggle then FarmToggle:Set(State.toggles.auto1) end
        if CollectToggle then CollectToggle:Set(State.toggles.auto2) end
        if FruitToggle then FruitToggle:Set(State.toggles.autoFruit1) end
        if AutoZoneToggle then AutoZoneToggle:Set(State.toggles.autoZone1) end
        if AutoRollToggle then AutoRollToggle:Set(State.toggles.autoRoll1) end
        if FastRollToggle then FastRollToggle:Set(State.toggles.fastRoll1) end
        if AutoPotionToggle then AutoPotionToggle:Set(State.toggles.autoPotion1) end
        if AutoBlasterToggle then AutoBlasterToggle:Set(State.toggles.autoBlaster1) end
        if ESPToggle then ESPToggle:Set(State.toggles.esp1) end
        if FruitRadiusSlider then FruitRadiusSlider:Set(State.fruitCollectionRadius) end
        if Slider then Slider:Set(State.walkSpeed or 16) end
        if PotionDropdown then PotionDropdown:Set({State.selectedPotion}) end
        if ESPColorPicker then ESPColorPicker:Set(State.espColor) end
        if ESPModeDropdown then ESPModeDropdown:Set(State.espMode) end
        if AntiKickToggle then AntiKickToggle:Set(State.toggles.antiKick or false) end
        if AntiIdleToggle then AntiIdleToggle:Set(State.toggles.antiIdle or false) end
        if NoclipToggle then NoclipToggle:Set(State.toggles.noclip or false) end
        if InfJumpToggle then InfJumpToggle:Set(State.toggles.infiniteJump or false) end
        if AutoSaveToggle then AutoSaveToggle:Set(State.toggles.autoSaveConfig or false) end
        if AutoLoadToggle then AutoLoadToggle:Set(State.toggles.autoLoadConfig or false) end
        if AutoLoadNameInput then AutoLoadNameInput:Set(State.autoLoadConfigName or "Default") end
    end)
    
    Rayfield:Notify({Title = "Config Loaded", Content = "Loaded: " .. name, Duration = 3, Image = 4483362458})
    return true
end

-- ==================== MAIN DAEMON ====================
task.spawn(function()
    while true do
        local ok = pcall(function()
            task.wait(0.06)
            State.humanizer = State.toggles.humanizer1
            local hum = getHum()
            if not hum then
                hidePathRay()
                hideFruitRay()
                setE(false)
                State.activeTask = "idle"
                return
            end
            if tick() - State.lastZoneScan > 3 then
                State.lastZoneScan = tick()
                local highestOwned, _ = getHighestOwnedZone()
                if highestOwned and highestOwned + 1 > State.currentZoneNum then
                    local nextZoneNum = highestOwned + 1
                    local nextSpawn = getZoneSpawn(nextZoneNum)
                    if nextSpawn then
                        State.currentZoneNum = nextZoneNum
                        State.zoneSpawnPos = nextSpawn
                        State.isTravelingToZone = true
                        State.hasArrivedAtZone = false
                        State.zoneArrivalTime = 0
                        State.zoneCooldownEnd = 0
                    end
                end
            end
            if State.isTravelingToZone and State.zoneSpawnPos then
                local dist = distToPos(State.zoneSpawnPos)
                if dist <= 6 and not State.hasArrivedAtZone then
                    State.hasArrivedAtZone = true
                    State.zoneArrivalTime = tick()
                    State.zoneCooldownEnd = tick() + 5
                    State.isTravelingToZone = false
                    hidePathRay()
                end
            end
            local onCooldown = tick() < State.zoneCooldownEnd
            local nearestLoot = nil
            local nearestEnemy = nil
            local nearestFruit = nil
            local fruitPos = nil
            local fruitDist = math.huge
            if State.toggles.autoFruit1 then
                nearestFruit, fruitPos, fruitDist = getNearestFruit()
            end
            if State.toggles.auto2 and not onCooldown then
                nearestLoot = getNearestLoot()
            end
            if State.toggles.auto1 and not onCooldown then
                nearestEnemy = getNearestEnemy()
            end
            local desiredTask = "idle"
            if State.isTravelingToZone and State.zoneSpawnPos then
                desiredTask = "zone"
            elseif State.toggles.autoFruit1 and nearestFruit and fruitDist <= State.fruitCollectionRadius then
                desiredTask = "fruit"
            elseif State.toggles.auto2 and nearestLoot and not onCooldown then
                desiredTask = "loot"
            elseif State.toggles.auto1 and nearestEnemy and not onCooldown then
                desiredTask = "combat"
            end
            if desiredTask ~= State.activeTask then
                releaseAllInputs()
                hidePathRay()
                hideFruitRay()
                State.activeTask = desiredTask
                State.lastEnemyMove = 0
                State.lastLootETime = 0
                State.lastM1Time = 0
                State.lastFruitETime = 0
            end
            if State.activeTask == "zone" then
                local dist = distToPos(State.zoneSpawnPos)
                if dist > 6 then
                    tweenToZone(State.zoneSpawnPos)
                end
            elseif State.activeTask == "fruit" then
                if not nearestFruit or not nearestFruit.Parent then
                    State.activeTask = "idle"
                    setE(false)
                    hideFruitRay()
                    return
                end
                local arrived = moveToFruit(nearestFruit)
                if arrived then
                    if tick() - State.lastFruitETime > 0.12 then
                        State.lastFruitETime = tick()
                        interactWithFruit(nearestFruit)
                    end
                end
            elseif State.activeTask == "loot" then
                if not nearestLoot or not nearestLoot.Parent then
                    State.activeTask = "idle"
                    setE(false)
                    hidePathRay()
                    return
                end
                local arrived = moveToLoot(nearestLoot)
                if arrived then
                    if tick() - State.lastLootETime > 0.14 then
                        State.lastLootETime = tick()
                        setE(true)
                        task.wait(0.07)
                        setE(false)
                    end
                end
            elseif State.activeTask == "combat" then
                if not nearestEnemy or not nearestEnemy.Parent then
                    State.activeTask = "idle"
                    hidePathRay()
                    return
                end
                local ePos = getPos(nearestEnemy)
                local hrp = getHRP()
                if ePos and hrp then
                    local dist = (hrp.Position - ePos).Magnitude
                    if dist > (State.humanizer and 4 or 2.5) then
                        smoothMoveToEnemy(nearestEnemy, State.humanizer)
                        local ignore = getIgnoreList(nearestEnemy)
                        local st, hit = checkObstacle(hrp.Position, ePos, ignore)
                        if st == "jumpable" then
                            tryJump()
                            updateRayPart(PathRay, hrp.Position, hit or ePos, Color3.fromRGB(255, 255, 0))
                        elseif st == "blocked" then
                            updateRayPart(PathRay, hrp.Position, hit or ePos, Color3.fromRGB(255, 50, 50))
                        else
                            updateRayPart(PathRay, hrp.Position, ePos, Color3.fromRGB(0, 255, 100))
                        end
                    else
                        hidePathRay()
                        smoothMoveToEnemy(nearestEnemy, State.humanizer)
                        fireSlimeGun(nearestEnemy)
                    end
                else
                    State.activeTask = "idle"
                    hidePathRay()
                end
            else
                setE(false)
                hidePathRay()
                hideFruitRay()
            end
        end)
        if not ok then
            setE(false)
            hidePathRay()
            hideFruitRay()
            State.activeTask = "idle"
        end
    end
end)

-- ==================== AUTO ROLL DAEMON ====================
task.spawn(function()
    while true do
        pcall(function()
            if State.toggles.autoRoll1 or State.toggles.fastRoll1 then
                doRoll()
            end
        end)
        local delayTime = State.toggles.fastRoll1 and 0 or 0.5
        task.wait(delayTime)
    end
end)

-- ==================== AUTO POTION DAEMON ====================
task.spawn(function()
    while true do
        pcall(function()
            if State.toggles.autoPotion1 then
                if tick() - State.lastPotionTime >= State.potionCooldown then
                    State.lastPotionTime = tick()
                    usePotion(State.selectedPotion)
                end
            end
        end)
        task.wait(1)
    end
end)

-- ==================== AUTO BLASTER DAEMON ====================
task.spawn(function()
    local UserInputService = game:GetService("UserInputService")
    local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    local isTablet = UserInputService.TouchEnabled and UserInputService.KeyboardEnabled

    while true do
        pcall(function()
            local isOn = State.toggles.autoBlaster1

            if isOn then
                if isMobile or isTablet then
                    local screenSize = Workspace.CurrentCamera.ViewportSize
                    local centerX = screenSize.X / 2
                    local centerY = screenSize.Y / 2

                    pcall(function()
                        VirtualInputManager:SendTouchEvent(
                            {Vector2.new(centerX, centerY)},
                            {true},
                            {1},
                            game
                        )
                    end)

                    pcall(function()
                        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
                    end)
                else
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                end
            else
                pcall(function()
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                end)
                pcall(function()
                    local screenSize = Workspace.CurrentCamera.ViewportSize
                    VirtualInputManager:SendTouchEvent(
                        {Vector2.new(screenSize.X/2, screenSize.Y/2)},
                        {false},
                        {1},
                        game
                    )
                end)
            end
        end)
        task.wait(0.005)
    end
end)

-- ==================== FORWARD RAY DAEMON ====================
task.spawn(function()
    while true do
        local ok = pcall(function()
            task.wait(0.1)
            local hrp = getHRP()
            if hrp then
                local myPos = hrp.Position
                local look = hrp.CFrame.LookVector
                local ignore = getIgnoreList(nil)
                local st, hit = checkObstacle(myPos, myPos + look * 14, ignore)
                if st == "jumpable" then
                    tryJump()
                    updateRayPart(ForwardRay, myPos, hit or (myPos + look * 14), Color3.fromRGB(255, 220, 0))
                elseif st == "blocked" then
                    updateRayPart(ForwardRay, myPos, hit or (myPos + look * 14), Color3.fromRGB(255, 80, 80))
                else
                    updateRayPart(ForwardRay, myPos, myPos + look * 14, Color3.fromRGB(0, 200, 255))
                end
            else
                ForwardRay.Size = Vector3.new(0.01, 0.01, 0.01)
            end
        end)
        if not ok then task.wait(0.2) end
    end
end)

-- ==================== AUTO NEXT AREA DAEMON ====================
task.spawn(function()
    while true do
        local ok = pcall(function()
            if State.toggles.autoZone1 then
                purchaseNextZone()
            end
        end)
        if not ok then task.wait(0.2) end
        task.wait(1.5)
    end
end)

-- ==================== UI: MAIN ====================
local MainTab = Window:CreateTab("Main", 84342305212226)
MainTab:CreateSection("Auto Farm")

local HumanizerToggle = MainTab:CreateToggle({
    Name = "Humanizer",
    CurrentValue = false,
    Flag = "humanizer1",
    Callback = function(Value)
        State.toggles.humanizer1 = Value
        State.humanizer = Value
    end,
})

local FarmToggle = MainTab:CreateToggle({
    Name = "Autofarm",
    CurrentValue = false,
    Flag = "auto1",
    Callback = function(Value)
        State.toggles.auto1 = Value
    end,
})

local CollectToggle = MainTab:CreateToggle({
    Name = "Auto Collect",
    CurrentValue = false,
    Flag = "auto2",
    Callback = function(Value)
        State.toggles.auto2 = Value
    end,
})

local FruitToggle = MainTab:CreateToggle({
    Name = "Auto Fruit Collector",
    CurrentValue = false,
    Flag = "autoFruit1",
    Callback = function(Value)
        State.toggles.autoFruit1 = Value
    end,
})

local FruitRadiusSlider = MainTab:CreateSlider({
    Name = "Fruit Detection Radius",
    Range = {10, 200},
    Increment = 5,
    Suffix = " studs",
    CurrentValue = 30,
    Flag = "fruitRadius1",
    Callback = function(Value)
        State.fruitCollectionRadius = Value
    end,
})

local Slider = MainTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 150},
    Increment = 2,
    Suffix = "",
    CurrentValue = 16,
    Flag = "ws1",
    Callback = function(Value)
        State.walkSpeed = Value
        local hum = getHum()
        if hum then hum.WalkSpeed = Value end
    end,
})

local AutoZoneToggle = MainTab:CreateToggle({
    Name = "Auto Next Area",
    CurrentValue = false,
    Flag = "autoZone1",
    Callback = function(Value)
        State.toggles.autoZone1 = Value
    end,
})

-- ==================== AUTO ROLL SECTION ====================
MainTab:CreateSection("Auto Roll")

local AutoRollToggle = MainTab:CreateToggle({
    Name = "Auto Roll",
    CurrentValue = false,
    Flag = "autoRoll1",
    Callback = function(Value)
        State.toggles.autoRoll1 = Value
        if Value and State.toggles.fastRoll1 then
            State.toggles.fastRoll1 = false
            pcall(function()
                if FastRollToggle and type(FastRollToggle.Set) == "function" then
                    FastRollToggle:Set(false)
                end
            end)
        end
    end,
})

local FastRollToggle = MainTab:CreateToggle({
    Name = "Fast Roll (Spam)",
    CurrentValue = false,
    Flag = "fastRoll1",
    Callback = function(Value)
        State.toggles.fastRoll1 = Value
        if Value and State.toggles.autoRoll1 then
            State.toggles.autoRoll1 = false
            pcall(function()
                if AutoRollToggle and type(AutoRollToggle.Set) == "function" then
                    AutoRollToggle:Set(false)
                end
            end)
        end
    end,
})

-- ==================== AUTO POTION SECTION ====================
MainTab:CreateSection("Auto Potion")

local PotionDropdown = MainTab:CreateDropdown({
    Name = "Select Potion",
    Options = {"Luck Boost", "Ultra Luck Boost", "Currency Boost", "Roll Speed Boost"},
    CurrentOption = "Luck Boost",
    MultipleOptions = false,
    Flag = "potionSelect1",
    Callback = function(Option)
        State.selectedPotion = Option[1] or Option
    end,
})

-- Note: Amount input kept for UI consistency but BoostService does not use amounts
local PotionAmountInput = MainTab:CreateInput({
    Name = "Amount to Use",
    PlaceholderText = "1",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num and num > 0 then
            State.potionAmount = math.floor(num)
        else
            State.potionAmount = 1
        end
    end,
})

local AutoPotionToggle = MainTab:CreateToggle({
    Name = "Auto Use Potion",
    CurrentValue = false,
    Flag = "autoPotion1",
    Callback = function(Value)
        State.toggles.autoPotion1 = Value
    end,
})

-- ==================== AUTO BLASTER SECTION ====================
MainTab:CreateSection("Blaster")

local AutoBlasterToggle = MainTab:CreateToggle({
    Name = "Auto Blaster",
    CurrentValue = false,
    Flag = "autoBlaster1",
    Callback = function(Value)
        State.toggles.autoBlaster1 = Value
    end,
})

local BlasterKeybind = MainTab:CreateKeybind({
    Name = "Blaster Toggle Key",
    CurrentKeybind = "B",
    HoldToInteract = false,
    Flag = "blasterKey1",
    Callback = function(Keybind)
        local newValue = not State.toggles.autoBlaster1
        State.toggles.autoBlaster1 = newValue
        pcall(function()
            if AutoBlasterToggle and type(AutoBlasterToggle.Set) == "function" then
                AutoBlasterToggle:Set(newValue)
            end
        end)
        Rayfield:Notify({
            Title = "Auto Blaster",
            Content = newValue and "ON" or "OFF",
            Duration = 1,
            Image = 4483362458,
        })
    end,
})

-- ==================== UI: VISUALS ====================
local VisualsTab = Window:CreateTab("Visuals", 125020872044147)
VisualsTab:CreateSection("Enemy ESP")

local ESPToggle = VisualsTab:CreateToggle({
    Name = "ESP",
    CurrentValue = false,
    Flag = "esp1",
    Callback = function(Value)
        State.toggles.esp1 = Value
        State.espEnabled = Value
        if not Value then clearAllESP() end
    end,
})

local ESPModeDropdown = VisualsTab:CreateDropdown({
    Name = "ESP Mode",
    Options = {"Box", "Health"},
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "espMode1",
    Callback = function(Options)
        State.espMode = Options
    end,
})

local ESPColorPicker = VisualsTab:CreateColorPicker({
    Name = "ESP Color",
    Color = State.espColor,
    Flag = "espColor1",
    Callback = function(Value)
        State.espColor = Value
    end,
})

-- ==================== UI: SETTINGS ====================
local SettingsTab = Window:CreateTab("Settings", 80758916183665)

local Themes = SettingsTab:CreateDropdown({
    Name = "Themes",
    Options = {"Default", "AmberGlow", "Amethyst", "Bloom", "DarkBlue", "Green", "Light", "Ocean", "Serenity"},
    CurrentOption = "Ocean",
    MultipleOptions = false,
    Flag = "Dropdown1",
    Callback = function(Options)
        Window.ModifyTheme(Options[1])
    end,
})

local Paragraph = SettingsTab:CreateParagraph({
    Title = "How to use",
    Content = "Auto Roll uses requestRoll remote. Fast Roll spams with no delay. Auto Potion uses requestUseBoost remote every 2 seconds."
})

-- ==================== CONFIGURATION SECTION ====================
SettingsTab:CreateSection("Configuration")

local ConfigNameInput = SettingsTab:CreateInput({
    Name = "Config Name",
    PlaceholderText = "MyConfig",
    RemoveTextAfterFocusLost = false,
    Flag = "configName1",
    Callback = function(Text)
        State.configName = Text
    end,
})

local SaveConfigBtn = SettingsTab:CreateButton({
    Name = "Save Config",
    Callback = function()
        local name = State.configName or "Default"
        if name == "" then name = "Default" end
        saveConfig(name)
    end,
})

local ConfigDropdown = SettingsTab:CreateDropdown({
    Name = "Load Config",
    Options = getConfigNames(),
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "configLoad1",
    Callback = function(Option)
        local name = Option[1] or Option
        if name and name ~= "" then
            loadConfig(name)
        end
    end,
})

local RefreshConfigsBtn = SettingsTab:CreateButton({
    Name = "Refresh Config List",
    Callback = function()
        pcall(function()
            ConfigDropdown:Refresh(getConfigNames())
        end)
    end,
})

local AutoSaveToggle = SettingsTab:CreateToggle({
    Name = "Auto Save Config",
    CurrentValue = false,
    Flag = "autoSaveConfig1",
    Callback = function(Value)
        State.toggles.autoSaveConfig = Value
    end,
})

-- ==================== AUTO LOAD CONFIG ====================
SettingsTab:CreateSection("Auto Load")

local AutoLoadNameInput = SettingsTab:CreateInput({
    Name = "Auto Load Config Name",
    PlaceholderText = "Default",
    RemoveTextAfterFocusLost = false,
    Flag = "autoLoadName1",
    Callback = function(Text)
        State.autoLoadConfigName = Text
    end,
})

local AutoLoadToggle = SettingsTab:CreateToggle({
    Name = "Auto Load Config on Start",
    CurrentValue = false,
    Flag = "autoLoadConfig1",
    Callback = function(Value)
        State.toggles.autoLoadConfig = Value
        State.autoLoadConfig = Value
    end,
})

-- ==================== PLAYER SAFETY SECTION ====================
SettingsTab:CreateSection("Player Safety")

local AntiKickToggle = SettingsTab:CreateToggle({
    Name = "Anti Kick",
    CurrentValue = false,
    Flag = "antiKick1",
    Callback = function(Value)
        antiKickEnabled = Value
        State.toggles.antiKick = Value
        if Value then
            Rayfield:Notify({Title = "Anti Kick", Content = "Enabled - kick attempts will be blocked", Duration = 3, Image = 4483362458})
        end
    end,
})

local AntiIdleToggle = SettingsTab:CreateToggle({
    Name = "Anti Idle",
    CurrentValue = false,
    Flag = "antiIdle1",
    Callback = function(Value)
        antiIdleEnabled = Value
        State.toggles.antiIdle = Value
        if Value then
            Rayfield:Notify({Title = "Anti Idle", Content = "Enabled - idle kicks prevented", Duration = 3, Image = 4483362458})
        end
    end,
})

-- ==================== MOVEMENT SECTION ====================
SettingsTab:CreateSection("Movement")

local NoclipToggle = SettingsTab:CreateToggle({
    Name = "No Clip",
    CurrentValue = false,
    Flag = "noclip1",
    Callback = function(Value)
        State.toggles.noclip = Value
        setNoclip(Value)
    end,
})

local InfJumpToggle = SettingsTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "infJump1",
    Callback = function(Value)
        State.toggles.infiniteJump = Value
        setInfiniteJump(Value)
    end,
})

-- ==================== BACKGROUND ====================
RunService.RenderStepped:Connect(function()
    local ok = pcall(updateESP)
    if not ok then end
end)

plr.CharacterAdded:Connect(function()
    State.lastJump = 0
    State.isTravelingToZone = false
    State.hasArrivedAtZone = false
    State.zoneArrivalTime = 0
    State.zoneCooldownEnd = 0
    State.activeTask = "idle"
    State.lastEnemyMove = 0
    State.lastLootETime = 0
    State.lastM1Time = 0
    State.lastFruitETime = 0
    State.lastFruitScan = 0
    State.cachedFruits = {}
    State.lastRollTime = 0
    State.lastPotionTime = 0
    setE(false)
    hidePathRay()
    hideFruitRay()
    task.wait(0.1)
    local hum = getHum()
    if hum and State.walkSpeed then hum.WalkSpeed = State.walkSpeed end
end)

-- ==================== ANTI IDLE CONNECTION ====================
plr.Idled:Connect(function()
    if antiIdleEnabled then
        local VirtualUser = game:GetService("VirtualUser")
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(math.random(10, 100), math.random(10, 100)), workspace.CurrentCamera.CFrame)
    end
end)

-- ==================== ANTI KICK SETUP ====================
setupAntiKick()

-- ==================== AUTO SAVE DAEMON ====================
task.spawn(function()
    while true do
        pcall(function()
            if State.toggles.autoSaveConfig then
                saveConfig("AutoSave")
            end
        end)
        task.wait(30)
    end
end)

-- ==================== AUTO LOAD CONFIG ON START ====================
task.delay(3, function()
    pcall(function()
        if State.toggles.autoLoadConfig then
            local name = State.autoLoadConfigName
            if not name or name == "" then name = "Default" end
            loadConfig(name)
        end
    end)
end)
