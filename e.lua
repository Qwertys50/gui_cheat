-- ============================================================
--  Paradox Helper — Modular Core v2 (FIXED)
--  • No GUI, pure functions
--  • Event-based notifications
--  • Accepts boolean/number/string parameters
-- ============================================================

-- ─── Services ──────────────────────────────────────────────
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local UserInputService   = game:GetService("UserInputService")
local Lighting           = game:GetService("Lighting")
local rs                 = game:GetService("RunService")

-- ─── World refs ────────────────────────────────────────────
local player         = Players.LocalPlayer
local playerName     = player.Name
local character      = player.Character or player.CharacterAdded:Wait()
local entitiesFolder = workspace:FindFirstChild("Entities")
local currentRooms   = workspace:FindFirstChild("CurrentRooms")

-- Wait for important folders if needed
if not entitiesFolder then
    entitiesFolder = workspace:WaitForChild("Entities", 5)
end
if not currentRooms then
    currentRooms = workspace:WaitForChild("CurrentRooms", 5)
end

-- ============================================================
--  EVENT SYSTEM (instead of GUI notifications)
-- ============================================================

local Events = {
    Notification = Instance.new("BindableEvent"),  -- (title, content, duration)
    EntitySpawned = Instance.new("BindableEvent"), -- (entityName)
    EntityDespawned = Instance.new("BindableEvent"), -- (entityName)
    PlayerTeleported = Instance.new("BindableEvent"), -- (roomNumber)
    SpeedChanged = Instance.new("BindableEvent"), -- (newSpeed, enabled)
    ESPToggled = Instance.new("BindableEvent"), -- (type, enabled)
    AntiEntityTriggered = Instance.new("BindableEvent"), -- (entityName)
}

-- Helper to fire notification events
local function Notify(title, content, duration)
    duration = duration or 3
    Events.Notification:Fire(title, content, duration)
end

-- ============================================================
--  ESP SYSTEM (Pattern-based matching, no GUI)
-- ============================================================

local hidingLockerNames = {
    "Warehouse_HidingLocker", "HidingLocker", "Toolshed", "CaveLocker", "TrueLabHidingLocker",
}

local espCategories = {
    { Name = "Amethysts",     Pattern = "Amethyst",
        FormatName = function(n)
            if string.find(n, "Single") or string.find(n, "Shard") then return "Amethyst Shard" end
            if string.find(n, "Small") then return "Small Amethyst" end
            if string.find(n, "Mid") then return "Medium Amethyst" end
            if string.find(n, "Big") then return "Big Amethyst" end
            return "Amethyst"
        end
    },
    { Name = "BreakableCrate", Pattern = "BreakableCrate", FormatName = function() return "Breakable Crate" end },
    { Name = "Batteries",     Pattern = "Battery" },
    { Name = "Bandages",      Pattern = "Bandage" },
    { Name = "Vitamins",      Pattern = "Vitamin" },
    { Name = "Keycards",      
        IsMatch = function(n)
            if string.find(n, "Collision") then return false end
            if string.find(n, "LootLocker") then return false end
            return string.find(n, "Keycard") ~= nil
        end,
        FormatName = function(n)
            if n == "KeycardLevel2" then return "Keycard (Level 2)" end
            if n == "StellaKeycard" then return "Stella's Keycard" end
            return "Keycard"
        end
    },
    { Name = "Flashlights",   Pattern = "Flashlight" },
    { Name = "Lighters",      Pattern = "Lighter" },
    { Name = "BulkLight",     Pattern = "BulkLight", FormatName = function() return "Bulk Light" end },
    { Name = "DeceivingDust", Pattern = "DeceivingDust", FormatName = function() return "Deceiving Dust" end },
    { Name = "Silver",        Pattern = "Silver",
        FormatName = function(n)
            if string.find(n, "ReallySmall") then return "Small Coin" end
            if string.find(n, "Small") then return "Coin" end
            if string.find(n, "Big") then return "Big Coin" end
            return "Silver"
        end
    },
    { Name = "Lever",         Pattern = "MainLever", FormatName = function() return "Main Lever" end },
    { Name = "Sword",         Pattern = "Sword" },
    { Name = "Doors",         IsMatch = function(n) return n == "Door" end },
    { Name = "Gates",         IsMatch = function(n) return n == "Gate" or n == "BasementGate" end },
    { Name = "Vents",         
        IsMatch = function(n, item) return n == "Inside" or (n == "Grate" and item and item.Parent and item.Parent.Name == "OpenableVent") end,
        FormatName = function() return "Vent" end 
    },
    { Name = "HidingLockers", 
        IsMatch = function(n, item)
            local found = false
            for _, name in ipairs(hidingLockerNames) do
                if n == name then found = true break end
            end
            if not found then return false end
            if item and not item:FindFirstChildWhichIsA("ProximityPrompt", true) then return false end
            return true
        end,
        FormatName = function(n)
            if n == "Warehouse_HidingLocker" then return "Warehouse Locker" end
            if n == "TrueLabHidingLocker" then return "Lab Locker" end
            if n == "CaveLocker" then return "Cave Locker" end
            if n == "Toolshed" then return "Tool Shed" end
            return "Locker"
        end
    },
}

-- ESP State
local masterEspEnabled = false
local itemEspEnabled = false
local entityEspEnabled = false
local showItemNames = false
local tracersEnabled = false
local categoryEnabled = {}
local tracerCategoryEnabled = {}
local categoryColors = {}
local activeESPInstances = {}
local activeEntityESPInstances = {}
local flatEntitySpheres = {}

-- Entity targets for ESP
local flatEntityNames = {"A200", "A60New", "Route", "Cue", "UnknownEntity"}

for _, cat in ipairs(espCategories) do
    categoryEnabled[cat.Name] = false
    tracerCategoryEnabled[cat.Name] = false
    categoryColors[cat.Name] = Color3.fromRGB(255, 0, 255)
end

-- FIXED: Load ESP library with proper error handling
local ESPLibrary = nil
local loadSuccess, loadError = pcall(function()
    ESPLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/mstudio45/MSESP/refs/heads/main/source.luau"))()
end)

if not loadSuccess or not ESPLibrary then
    warn("Failed to load ESP library: " .. tostring(loadError))
    -- Create a dummy ESPLibrary to prevent nil errors
    ESPLibrary = {
        Add = function() return { Show = function() end, Hide = function() end, Destroy = function() end, CurrentSettings = {} } end
    }
end

-- Helper functions
local function getCategoryForItem(item)
    if not item then return nil end
    local itemName = item.Name
    for _, cat in ipairs(espCategories) do
        if cat.IsMatch then
            if cat.IsMatch(itemName, item) then return cat.Name end
        elseif cat.Pattern then
            if string.find(itemName, cat.Pattern) then return cat.Name end
        end
    end
    return nil
end

local function refreshHighlights()
    if not ESPLibrary then return end
    for item, espInst in pairs(activeESPInstances) do
        if item and item.Parent and espInst and not espInst.Deleted then
            local catName = getCategoryForItem(item)
            local globalEnable = masterEspEnabled and itemEspEnabled
            if catName and categoryEnabled[catName] and globalEnable then
                local color = categoryColors[catName]
                local catData = nil
                for _, cat in ipairs(espCategories) do
                    if cat.Name == catName then catData = cat break end
                end
                local displayName = item.Name
                if catData and catData.FormatName then displayName = catData.FormatName(item.Name) end
                if espInst.CurrentSettings then
                    espInst.CurrentSettings.FillColor = color
                    if espInst.CurrentSettings.Tracer then
                        espInst.CurrentSettings.Tracer.Enabled = tracersEnabled and (tracerCategoryEnabled[catName] == true)
                    end
                    espInst.CurrentSettings.Name = showItemNames and string.format("[%s] %s", catName, displayName) or ""
                end
                pcall(function() espInst:Show() end)
            else
                pcall(function() espInst:Hide() end)
            end
        end
    end
end

local function refreshEntityHighlights()
    if not ESPLibrary then return end
    local globalEnable = masterEspEnabled and entityEspEnabled
    for ent, espInst in pairs(activeEntityESPInstances) do
        if ent and ent.Parent and espInst and not espInst.Deleted then
            if espInst.CurrentSettings and espInst.CurrentSettings.Tracer then
                espInst.CurrentSettings.Tracer.Enabled = tracersEnabled and globalEnable
            end
            if globalEnable then 
                pcall(function() espInst:Show() end)
            else 
                pcall(function() espInst:Hide() end)
            end
        end
    end
end

local function processEspItem(item)
    if not item or not item.Parent then return end
    local catName = getCategoryForItem(item)
    if not catName then return end
    if catName == "Doors" and (not item.Parent or tonumber(item.Parent.Name) == nil) then return end
    
    if not activeESPInstances[item] and ESPLibrary then
        local catData = nil
        for _, cat in ipairs(espCategories) do
            if cat.Name == catName then catData = cat break end
        end
        local displayName = item.Name
        if catData and catData.FormatName then displayName = catData.FormatName(item.Name) end
        local color = categoryColors[catName]
        
        local espInst = ESPLibrary:Add({
            Name = showItemNames and string.format("[%s] %s", catName, displayName) or "",
            Model = item,
            ESPType = "Highlight",
            FillColor = color,
            OutlineColor = Color3.fromRGB(255, 255, 255),
            MaxDistance = 400,
            FillTransparency = 0.5,
            OutlineTransparency = 0,
            Visible = masterEspEnabled and itemEspEnabled and categoryEnabled[catName],
            Tracer = {
                Enabled = tracersEnabled and tracerCategoryEnabled[catName],
                Color = color,
                Thickness = 2,
                Transparency = 0,
                From = "Bottom",
            },
        })
        if espInst then
            activeESPInstances[item] = espInst
        end
    end
    refreshHighlights()
end

local function processEntityEsp(ent)
    if not ent or not ent.Parent then return end
    if not activeEntityESPInstances[ent] and ESPLibrary then
        if table.find(flatEntityNames, ent.Name) then
            task.spawn(function()
                task.wait(0.15)
                if not ent or not ent.Parent then return end
                local rootPart = ent:FindFirstChildWhichIsA("BasePart", true)
                if not rootPart then return end
                local sphere = Instance.new("Part")
                sphere.Shape = Enum.PartType.Ball
                sphere.Size = Vector3.new(20, 20, 20)
                sphere.Anchored = false
                sphere.CanCollide = false
                sphere.CanQuery = false
                sphere.CanTouch = false
                sphere.Transparency = 1
                sphere.CastShadow = false
                sphere.Material = Enum.Material.Glass
                sphere.Name = "_ESPSphere"
                sphere.CFrame = rootPart.CFrame
                sphere.Parent = ent
                flatEntitySpheres[ent] = sphere
                rs.Heartbeat:Connect(function()
                    if not ent or not ent.Parent or not sphere then return end
                    pcall(function() sphere.CFrame = rootPart.CFrame end)
                end)
            end)
        end
        local espInst = ESPLibrary:Add({
            Name = ent.Name,
            Model = ent,
            ESPType = "Highlight",
            FillColor = Color3.fromRGB(255, 0, 0),
            OutlineColor = Color3.fromRGB(255, 255, 255),
            MaxDistance = 1000,
            FillTransparency = 0.5,
            OutlineTransparency = 0,
            Visible = masterEspEnabled and entityEspEnabled,
            Tracer = { Enabled = tracersEnabled, Color = Color3.fromRGB(255, 0, 0), Thickness = 2, Transparency = 0, From = "Bottom" },
        })
        if espInst then
            activeEntityESPInstances[ent] = espInst
        end
    end
    refreshEntityHighlights()
end

local function scanExistingRooms()
    if not currentRooms then return end
    for _, descendant in ipairs(currentRooms:GetDescendants()) do
        local parent = descendant.Parent
        if parent then
            local parentName = parent.Name:lower()
            if parentName == "main" or parentName == "spawning" then
                local grandParent = parent.Parent
                if grandParent and (grandParent.Name:match("Spawns") or grandParent.Name:match("Drawer")) then
                    processEspItem(descendant)
                end
            elseif descendant:FindFirstAncestor("Scriptables") then
                processEspItem(descendant)
            elseif descendant:FindFirstAncestor("Furniture") then
                processEspItem(descendant)
            elseif (parentName == "vent" and descendant.Name == "Inside") or (parentName == "openablevent" and descendant.Name == "Grate") then
                processEspItem(descendant)
            elseif tonumber(parentName) ~= nil then
                processEspItem(descendant)
            elseif table.find(hidingLockerNames, descendant.Name) then
                processEspItem(descendant)
            elseif descendant.Name == "BreakableCrate" or (descendant:FindFirstAncestor("Puzzle") and descendant:FindFirstAncestor("Boxes")) then
                processEspItem(descendant)
            elseif parentName == "guaranteedcard" then
                processEspItem(descendant)
            end
        end
    end
    if entitiesFolder then
        for _, ent in ipairs(entitiesFolder:GetChildren()) do
            processEntityEsp(ent)
        end
    end
end

local function clearAllHighlights()
    for _, espInst in pairs(activeESPInstances) do
        pcall(function() if espInst and espInst.Destroy then espInst:Destroy() end end)
    end
    table.clear(activeESPInstances)
    for _, espInst in pairs(activeEntityESPInstances) do
        pcall(function() if espInst and espInst.Destroy then espInst:Destroy() end end)
    end
    table.clear(activeEntityESPInstances)
end

-- ============================================================
--  SPEED BOOST
-- ============================================================

local speedBoostEnabled = false
local SpeedBoost = 0
local speedBoostConn = nil

local function getHumanoid()
    local wsChar = workspace:FindFirstChild(playerName)
    if not wsChar then return nil end
    return wsChar:FindFirstChild("Humanoid")
end

local function applySpeedBoost()
    local humanoid = getHumanoid()
    if not humanoid then return end
    humanoid:SetAttribute("SpeedBoost", SpeedBoost)
end

--- Set speed boost value
--- @param value number Speed value (1-100)
--- @return boolean Success
local function SetSpeedValue(value)
    SpeedBoost = math.clamp(value, 1, 100)
    if speedBoostEnabled then applySpeedBoost() end
    Events.SpeedChanged:Fire(SpeedBoost, speedBoostEnabled)
    return true
end

--- Enable/disable speed boost
--- @param enabled boolean
--- @return boolean Success
local function SetSpeedBoost(enabled)
    if enabled == speedBoostEnabled then return true end
    speedBoostEnabled = enabled
    
    if enabled then
        applySpeedBoost()
        if speedBoostConn then speedBoostConn:Disconnect() end
        local humanoid = getHumanoid()
        if humanoid then
            speedBoostConn = humanoid:GetAttributeChangedSignal("SpeedBoost"):Connect(function()
                if speedBoostEnabled then
                    local current = humanoid:GetAttribute("SpeedBoost")
                    if current ~= SpeedBoost then
                        humanoid:SetAttribute("SpeedBoost", SpeedBoost)
                    end
                end
            end)
        end
        Notify("Speed Boost", "Enabled at " .. SpeedBoost, 2)
    else
        if speedBoostConn then
            speedBoostConn:Disconnect()
            speedBoostConn = nil
        end
        local humanoid = getHumanoid()
        if humanoid then humanoid:SetAttribute("SpeedBoost", 0) end
        Notify("Speed Boost", "Disabled", 2)
    end
    Events.SpeedChanged:Fire(SpeedBoost, speedBoostEnabled)
    return true
end

-- ============================================================
--  UNLOCK JUMP
-- ============================================================

local unlockJumpEnabled = false
local unlockJumpConn = nil

local function getWsCharacter()
    return workspace:FindFirstChild(playerName)
end

--- Enable/disable jump unlock
--- @param enabled boolean
--- @return boolean Success
local function SetUnlockJump(enabled)
    if enabled == unlockJumpEnabled then return true end
    unlockJumpEnabled = enabled
    
    if enabled then
        local wsChar = getWsCharacter()
        if wsChar then wsChar:SetAttribute("CanJump", true) end
        if unlockJumpConn then unlockJumpConn:Disconnect() end
        unlockJumpConn = wsChar:GetAttributeChangedSignal("CanJump"):Connect(function()
            if unlockJumpEnabled then
                local wsChar2 = getWsCharacter()
                if wsChar2 and wsChar2:GetAttribute("CanJump") ~= true then
                    wsChar2:SetAttribute("CanJump", true)
                end
            end
        end)
        Notify("Jump Unlock", "Enabled", 2)
    else
        if unlockJumpConn then
            unlockJumpConn:Disconnect()
            unlockJumpConn = nil
        end
        Notify("Jump Unlock", "Disabled", 2)
    end
    return true
end

-- ============================================================
--  TELEPORT FUNCTIONS
-- ============================================================

local function getLoadedRooms()
    if not currentRooms then return {} end
    local rooms = {}
    for _, room in ipairs(currentRooms:GetChildren()) do
        local num = tonumber(room.Name)
        if num then table.insert(rooms, num) end
    end
    table.sort(rooms)
    return rooms
end

local function getCurrentRoom()
    local clientData = workspace:FindFirstChild("ClientData")
    local val = clientData and clientData:FindFirstChild("CurrentRoom")
    if not val then return 0 end
    local v = val.Value
    if typeof(v) == "Instance" then return tonumber(v.Name) or 0 end
    return tonumber(v) or 0
end

local function teleportToRoom(roomNumber)
    if not currentRooms then return false end
    local targetRoom = currentRooms:FindFirstChild(tostring(roomNumber))
    if not targetRoom then return false end
    local targetPart = targetRoom.PrimaryPart or targetRoom:FindFirstChildWhichIsA("BasePart", true)
    if not targetPart then return false end
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
        Events.PlayerTeleported:Fire(roomNumber)
        return true
    end
    return false
end

--- Teleport to next room (furthest loaded)
--- @return boolean Success
local function TeleportNext()
    local rooms = getLoadedRooms()
    if #rooms == 0 then return false end
    return teleportToRoom(rooms[#rooms])
end

--- Teleport to previous room (3 rooms back or first)
--- @return boolean Success
local function TeleportPrev()
    local rooms = getLoadedRooms()
    if #rooms == 0 then return false end
    if #rooms >= 3 then
        return teleportToRoom(rooms[#rooms - 2])
    else
        return teleportToRoom(rooms[1])
    end
end

--- Teleport to specific room number
--- @param roomNumber number|string
--- @return boolean Success
local function TeleportToRoom(roomNumber)
    return teleportToRoom(tonumber(roomNumber) or 0)
end

-- ============================================================
--  AUTO LOOT
-- ============================================================

local autoLootEnabled = false
local autoLootThread = nil
local autoLootCategories = {}

local lootCategoryNames = {"Amethysts", "Batteries", "Bandages", "Vitamins", "Keycards", "Flashlights", "Lighters", "BulkLight", "DeceivingDust", "Silver", "Sword"}
for _, name in ipairs(lootCategoryNames) do
    autoLootCategories[name] = false
end

local function isShopItem(item)
    if not currentRooms then return false end
    local ancestor = item.Parent
    while ancestor and ancestor ~= currentRooms and ancestor ~= workspace do
        if ancestor.Name == "TopPart" then
            local shop = ancestor.Parent
            if shop and shop.Name == "Shop" then return true end
        end
        ancestor = ancestor.Parent
    end
    return false
end

local function doAutoLootAura()
    if not currentRooms then return end
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local pos = hrp.Position
    
    for _, prompt in ipairs(currentRooms:GetDescendants()) do
        if not autoLootEnabled then return end
        if not prompt:IsA("ProximityPrompt") then goto continue end
        if prompt:GetAttribute("PH_Looted") then goto continue end
        
        local part = prompt.Parent
        if not (part and part:IsA("BasePart")) then goto continue end
        if (part.Position - pos).Magnitude > 13 then goto continue end
        
        local item = part
        local catName = nil
        while item and item ~= workspace and item ~= currentRooms do
            catName = getCategoryForItem(item)
            if catName then break end
            item = item.Parent
        end
        
        if not catName or not autoLootCategories[catName] then goto continue end
        if isShopItem(item) then goto continue end
        
        prompt:SetAttribute("PH_Looted", true)
        prompt.Enabled = true
        prompt.HoldDuration = 0
        prompt.MaxActivationDistance = 13
        pcall(function() fireproximityprompt(prompt) end)
        
        ::continue::
    end
end

local function startAutoLootLoop()
    if autoLootThread then task.cancel(autoLootThread) end
    autoLootThread = task.spawn(function()
        while autoLootEnabled do
            pcall(doAutoLootAura)
            task.wait(0.5)
        end
    end)
end

--- Enable/disable auto loot
--- @param enabled boolean
--- @return boolean Success
local function SetAutoLoot(enabled)
    if enabled == autoLootEnabled then return true end
    autoLootEnabled = enabled
    if enabled then
        startAutoLootLoop()
        Notify("Auto Loot", "Enabled", 2)
    else
        if autoLootThread then task.cancel(autoLootThread); autoLootThread = nil end
        Notify("Auto Loot", "Disabled", 2)
    end
    return true
end

--- Set which loot categories to auto-loot
--- @param categories table {["CategoryName"] = boolean}
--- @return boolean Success
local function SetLootCategories(categories)
    for name, enabled in pairs(categories) do
        if autoLootCategories[name] ~= nil then
            autoLootCategories[name] = enabled
        end
    end
    return true
end

-- ============================================================
--  ANTI ENTITY (2D entities like A60, etc.)
-- ============================================================

local antiEntityEnabled = false
local antiEntityConn = nil
local is_platform = false
local antiEntityList = {}
local antiEntityTargets = { Cue = true, Route = true, UnknownEntity = true, A200 = true, A60New = true }

local houseData = {
    Part = { Color = Color3.new(163/255, 162/255, 165/255), CFrame = CFrame.new(-45.5, 0.5, 10.16), Size = Vector3.new(30.36, 1, 25.72), Material = Enum.Material.Glass, Anchored = true, CanCollide = true }
}

local function buildHouse(targetCFrame)
    local model = Instance.new("Model")
    model.Name = "_AntiEntityHouse"
    model.Parent = workspace
    for name, v in pairs(houseData) do
        local part = Instance.new("Part")
        part.Name = name
        part.Size = v.Size or Vector3.new(1, 1, 1)
        part.CFrame = v.CFrame
        part.Color = v.Color
        part.Material = v.Material or Enum.Material.SmoothPlastic
        part.Anchored = true
        part.CanCollide = v.CanCollide ~= false
        part.Parent = model
    end
    model:PivotTo(targetCFrame)
    return model
end

local function saveFromEntity(entity)
    if not entity then return end
    table.insert(antiEntityList, entity)
    if is_platform then return end
    is_platform = true
    Events.AntiEntityTriggered:Fire(entity.Name)
    Notify("⚠ Anti Entity", "Saved from " .. entity.Name, 3)
    
    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then is_platform = false; return end
    
    local lastPos = hrp.CFrame
    local newPos = hrp.CFrame + Vector3.new(0, 1500, 0)
    hrp.CFrame = newPos
    
    local house = buildHouse(newPos)
    while #antiEntityList > 0 do task.wait(1) end
    pcall(function() house:Destroy() end)
    is_platform = false
    hrp.CFrame = lastPos
end

-- Clean dead entities
task.spawn(function()
    while true do
        task.wait(0.1)
        for i = #antiEntityList, 1, -1 do
            if not antiEntityList[i] or not antiEntityList[i].Parent then
                table.remove(antiEntityList, i)
            end
        end
    end
end)

local function startAntiEntity()
    if antiEntityConn then antiEntityConn:Disconnect() end
    if not entitiesFolder then return end
    antiEntityConn = entitiesFolder.ChildAdded:Connect(function(child)
        if antiEntityEnabled and antiEntityTargets[child.Name] then
            task.spawn(saveFromEntity, child)
        end
    end)
end

--- Enable/disable anti-entity (teleports above on dangerous entity spawn)
--- @param enabled boolean
--- @return boolean Success
local function SetAntiEntity(enabled)
    if enabled == antiEntityEnabled then return true end
    antiEntityEnabled = enabled
    if enabled then
        startAntiEntity()
        Notify("Anti Entity", "Enabled", 2)
    else
        if antiEntityConn then antiEntityConn:Disconnect(); antiEntityConn = nil end
        if is_platform then table.clear(antiEntityList) end
        Notify("Anti Entity", "Disabled", 2)
    end
    return true
end

--- Set which entities trigger anti-entity
--- @param targets table {["EntityName"] = boolean}
--- @return boolean Success
local function SetAntiEntityTargets(targets)
    for name, enabled in pairs(targets) do
        if antiEntityTargets[name] ~= nil then
            antiEntityTargets[name] = enabled
        end
    end
    return true
end

-- ============================================================
--  ESP CONTROLS
-- ============================================================

--- Enable/disable ESP master switch
--- @param enabled boolean
--- @return boolean Success
local function SetMasterESP(enabled)
    masterEspEnabled = enabled
    refreshHighlights()
    refreshEntityHighlights()
    Events.ESPToggled:Fire("master", enabled)
    return true
end

--- Enable/disable item ESP
--- @param enabled boolean
--- @return boolean Success
local function SetItemESP(enabled)
    itemEspEnabled = enabled
    refreshHighlights()
    Events.ESPToggled:Fire("items", enabled)
    return true
end

--- Enable/disable entity ESP
--- @param enabled boolean
--- @return boolean Success
local function SetEntityESP(enabled)
    entityEspEnabled = enabled
    refreshEntityHighlights()
    Events.ESPToggled:Fire("entities", enabled)
    return true
end

--- Enable/disable tracers for ESP
--- @param enabled boolean
--- @return boolean Success
local function SetTracers(enabled)
    tracersEnabled = enabled
    clearAllHighlights()
    scanExistingRooms()
    return true
end

--- Show/hide item names on ESP
--- @param enabled boolean
--- @return boolean Success
local function SetShowItemNames(enabled)
    showItemNames = enabled
    refreshHighlights()
    return true
end

--- Set which ESP categories are visible
--- @param categories table {["CategoryName"] = boolean}
--- @return boolean Success
local function SetESPCategories(categories)
    for name, enabled in pairs(categories) do
        if categoryEnabled[name] ~= nil then
            categoryEnabled[name] = enabled
        end
    end
    refreshHighlights()
    return true
end

--- Set tracer categories
--- @param categories table {["CategoryName"] = boolean}
--- @return boolean Success
local function SetTracerCategories(categories)
    for name, enabled in pairs(categories) do
        if tracerCategoryEnabled[name] ~= nil then
            tracerCategoryEnabled[name] = enabled
        end
    end
    clearAllHighlights()
    scanExistingRooms()
    return true
end

--- Set color for ESP category
--- @param category string Category name
--- @param color Color3
--- @return boolean Success
local function SetESPCategoryColor(category, color)
    if categoryColors[category] then
        categoryColors[category] = color
        refreshHighlights()
        return true
    end
    return false
end

--- Enable/disable fullbright
--- @param enabled boolean
--- @return boolean Success
local function SetFullbright(enabled)
    if enabled then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        Notify("Fullbright", "Enabled", 2)
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = 0
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
        Notify("Fullbright", "Disabled", 2)
    end
    return true
end

-- ============================================================
--  UTILITY FUNCTIONS
-- ============================================================

local function killPlayer()
    local wsChar = getWsCharacter()
    if wsChar then
        local humanoid = wsChar:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.Health = 0
            Notify("KYS", "You died", 2)
            return true
        end
    end
    return false
end

local function skipCutscene()
    local success, err = pcall(function()
        local fireVote = ReplicatedStorage:FindFirstChild("Assets") and 
                         ReplicatedStorage.Assets:FindFirstChild("Events") and 
                         ReplicatedStorage.Assets.Events:FindFirstChild("FireVote")
        if fireVote then fireVote:FireServer() end
    end)
    if success then Notify("Skip Cutscene", "Vote fired", 2) end
    return success
end

local function finishComputers()
    if not currentRooms then return false end
    local clientData = workspace:FindFirstChild("ClientData")
    local currentRoom = clientData and clientData:FindFirstChild("CurrentRoom")
    if not currentRoom or not currentRoom.Value or (currentRoom.Value.Name ~= "100" and currentRoom.Value.Name ~= "110") then
        Notify("Wrong Room", "Not in room 100/110!", 3)
        return false
    end
    local roomNum = currentRoom.Value.Name
    local targetRoom = currentRooms:FindFirstChild(roomNum)
    if not targetRoom then return false end
    local scriptables = targetRoom:FindFirstChild("Scriptables")
    if not scriptables then return false end
    
    pcall(function()
        local finishEvent = ReplicatedStorage:FindFirstChild("Assets") and
                            ReplicatedStorage.Assets:FindFirstChild("Events") and
                            ReplicatedStorage.Assets.Events:FindFirstChild("FinishDoor100Puzzle1")
        if finishEvent then
            for _, computer in ipairs(scriptables:GetChildren()) do
                finishEvent:FireServer(computer)
            end
        end
    end)
    Notify("Computers", "Finished room " .. roomNum .. " computers", 3)
    return true
end

local function finishLibrary()
    local nullZone = workspace:FindFirstChild("NullZone")
    if not nullZone then return false end
    local library = nullZone:FindFirstChild("Library")
    if library then
        local args = {"padlock"}
        local puzzleEvent = ReplicatedStorage:FindFirstChild("Assets") and 
                            ReplicatedStorage.Assets:FindFirstChild("Events") and 
                            ReplicatedStorage.Assets.Events:FindFirstChild("PuzzleCompletedNull")
        if puzzleEvent then
            puzzleEvent:FireServer(unpack(args))
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local portal = library:FindFirstChild("MisleadingPortal")
            if hrp and portal then
                hrp.CFrame = portal:GetPivot()
            end
            Notify("Library", "Finished", 3)
            return true
        end
    end
    return false
end

local HOUSE_ANCHORS = {"A", "B", "C"}

local function finishNest()
    local nullZone = workspace:FindFirstChild("NullZone")
    if not nullZone then return false end
    local nest = nullZone:FindFirstChild("Nest")
    if not nest then return false end
    
    local rep = ReplicatedStorage
    local finishEvent = rep:FindFirstChild("Assets") and 
                        rep.Assets:FindFirstChild("Events") and 
                        rep.Assets.Events:FindFirstChild("NestAnchorFinish")
    if not finishEvent then return false end
    
    local scriptables = nest:FindFirstChild("Scriptables")
    local anchorsFolder = scriptables and scriptables:FindFirstChild("Anchors")
    if anchorsFolder then
        for _, name in ipairs(HOUSE_ANCHORS) do
            for _, obj in ipairs(anchorsFolder:GetChildren()) do
                if obj:GetAttribute("friendlyName") == name and obj:GetAttribute("Code") then
                    pcall(function() finishEvent:FireServer(obj, obj:GetAttribute("Code")) end)
                    task.wait(0.4)
                    break
                end
            end
        end
    end
    Notify("Nest", "Anchors finished, press button within 20s", 4)
    
    local startTime = tick()
    while (tick() - startTime) < 20 do
        if player:GetAttribute("InCutscene") == true then
            while player:GetAttribute("InCutscene") == true do task.wait(0.3) end
            break
        end
        task.wait(0.5)
    end
    
    local portal = nest:FindFirstChild("MisleadingPortal")
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and portal then
        hrp.CFrame = portal:GetPivot()
        Notify("Nest", "Teleported to portal", 3)
    end
    return true 
end

local function seekChaseEnd()
    local nullZone = workspace:FindFirstChild("NullZone")
    if not nullZone then return false end
    local chase = nullZone:FindFirstChild("Chase")
    if not chase then return false end
    local lab = chase:FindFirstChild("Lab")
    if not lab then return false end
    local endingChase = lab:FindFirstChild("EndingChase")
    if not endingChase then return false end
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = endingChase:GetPivot()
        Notify("Seek Chase", "Teleported to end", 3)
        return true
    end
    return false
end

local function tpNullZoneStart()
    local nullZone = workspace:FindFirstChild("NullZone")
    if not nullZone then return false end
    local cutscene = nullZone:FindFirstChild("Cutscene")
    if not cutscene then return false end
    local cameraRig = cutscene:FindFirstChild("CameraRig")
    if not cameraRig then return false end
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = cameraRig:GetPivot()
        Notify("NullZone", "Teleported to start", 3)
        return true
    end
    return false
end

-- ============================================================
--  ANTI EXPLOITS (remove hazards)
-- ============================================================

local removeShockPartsEnabled = false
local shockPartConn = nil
local antiSnareEnabled = false
local snareConnection = nil
local antiGuiEnabled = false
local guiConnection = nil
local antiGlareEnabled = false
local glareConnection = nil
local antiShadeEnabled = false
local shadeConnection = nil
local antiLasersEnabled = false
local lasersConnection = nil
local antiVoid = false
local instantInteractEnabled = false
local instantInteractThread = nil

local function clearShockPartsInRoom(room)
    pcall(function()
        local lights = room:FindFirstChild("Lights")
        if not lights then return end
        for _, light in ipairs(lights:GetChildren()) do
            local bulb = light:FindFirstChild("Bulb")
            if bulb then
                local shockPart = bulb:FindFirstChild("ShockPart")
                if shockPart then pcall(function() shockPart:Destroy() end) end
            end
        end
    end)
end

local function startShockPartRemoval()
    if not currentRooms then return end
    for _, room in ipairs(currentRooms:GetChildren()) do
        clearShockPartsInRoom(room)
    end
    if shockPartConn then shockPartConn:Disconnect() end
    shockPartConn = currentRooms.DescendantAdded:Connect(function(desc)
        if removeShockPartsEnabled and desc.Name == "ShockPart" and desc.Parent and desc.Parent.Name == "Bulb" then
            pcall(function() desc:Destroy() end)
        end
    end)
end

local function stopShockPartRemoval()
    if shockPartConn then shockPartConn:Disconnect(); shockPartConn = nil end
end

local function removeAllSnares()
    for _, descendant in ipairs(workspace:GetDescendants()) do
        if descendant.Name == "Snare" then pcall(function() descendant:Destroy() end) end
    end
end

local function startAntiSnare()
    removeAllSnares()
    snareConnection = workspace.DescendantAdded:Connect(function(descendant)
        if descendant.Name == "Snare" then
            task.spawn(function()
                task.wait(0.15)
                if descendant and descendant.Parent then pcall(function() descendant:Destroy() end) end
            end)
        end
    end)
end

local function stopAntiSnare()
    if snareConnection then snareConnection:Disconnect(); snareConnection = nil end
end

local function startAntiA90_A90B()
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        for _, gui in ipairs(playerGui:GetChildren()) do
            if gui.Name == "a90b" or gui.Name == "a90" then pcall(function() gui:Destroy() end) end
        end
    end
    local lightingEffect = Lighting:FindFirstChild("a90bCc")
    if lightingEffect then pcall(function() lightingEffect:Destroy() end) end
    
    if playerGui then
        guiConnection = playerGui.ChildAdded:Connect(function(child)
            if child.Name == "a90b" or child.Name == "a90" then pcall(function() child:Destroy() end) end
        end)
    end
    Lighting.ChildAdded:Connect(function(child)
        if child.Name == "a90bCc" then pcall(function() child:Destroy() end) end
    end)
end

local function stopAntiA90_A90B()
    if guiConnection then guiConnection:Disconnect(); guiConnection = nil end
end

local function startAntiGlare()
    if not entitiesFolder then return end
    for _, ent in ipairs(entitiesFolder:GetChildren()) do
        if ent.Name == "Glare" then pcall(function() ent:Destroy() end) end
    end
    glareConnection = entitiesFolder.ChildAdded:Connect(function(child)
        if child.Name == "Glare" then pcall(function() child:Destroy() end) end
    end)
end

local function stopAntiGlare()
    if glareConnection then glareConnection:Disconnect(); glareConnection = nil end
end

local function startAntiShade()
    if not currentRooms then return end
    for _, room in ipairs(currentRooms:GetChildren()) do
        for _, desc in ipairs(room:GetDescendants()) do
            if desc.Name == "Shade" then pcall(function() desc:Destroy() end) end
        end
    end
    shadeConnection = currentRooms.DescendantAdded:Connect(function(child)
        if child.Name == "Shade" then pcall(function() child:Destroy() end) end
    end)
end

local function stopAntiShade()
    if shadeConnection then shadeConnection:Disconnect(); shadeConnection = nil end
end

local function startAntiLasers()
    if not currentRooms then return end
    for _, room in ipairs(currentRooms:GetChildren()) do
        local lasers = room:FindFirstChild("Lasers")
        if lasers then
            for _, laser in ipairs(lasers:GetChildren()) do
                if laser.Name == "LaserPair" then pcall(function() laser:Destroy() end) end
            end
        end
    end
    lasersConnection = currentRooms.DescendantAdded:Connect(function(child)
        if child.Name == "LaserPair" and child.Parent and child.Parent.Name == "Lasers" then
            pcall(function() child:Destroy() end)
        end
    end)
end

local function stopAntiLasers()
    if lasersConnection then lasersConnection:Disconnect(); lasersConnection = nil end
end

local function startInstantInteractLoop()
    if instantInteractThread then task.cancel(instantInteractThread) end
    instantInteractThread = task.spawn(function()
        while instantInteractEnabled do
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and currentRooms then
                local pos = hrp.Position
                for _, prompt in ipairs(currentRooms:GetDescendants()) do
                    if not instantInteractEnabled then break end
                    if prompt:IsA("ProximityPrompt") then
                        if prompt.Parent and prompt.Parent.Name == "LeftGascap" then goto continue end
                        local part = prompt.Parent
                        if part and part:IsA("BasePart") and (part.Position - pos).Magnitude <= 13 then
                            if prompt.HoldDuration ~= 0 then prompt.HoldDuration = 0 end
                        end
                    end
                    ::continue::
                end
            end
            task.wait(0.5)
        end
    end)
end

--- Enable/disable NoShock (removes electricity from bulbs)
--- @param enabled boolean
--- @return boolean Success
local function SetNoShock(enabled)
    if enabled == removeShockPartsEnabled then return true end
    removeShockPartsEnabled = enabled
    if enabled then
        startShockPartRemoval()
        Notify("NoShock", "Enabled", 2)
    else
        stopShockPartRemoval()
        Notify("NoShock", "Disabled", 2)
    end
    return true
end

--- Enable/disable Anti Snare (removes spike traps)
--- @param enabled boolean
--- @return boolean Success
local function SetAntiSnare(enabled)
    if enabled == antiSnareEnabled then return true end
    antiSnareEnabled = enabled
    if enabled then
        startAntiSnare()
        Notify("Anti Snare", "Enabled", 2)
    else
        stopAntiSnare()
        Notify("Anti Snare", "Disabled", 2)
    end
    return true
end

--- Enable/disable Anti A90/A90B (removes screen effects)
--- @param enabled boolean
--- @return boolean Success
local function SetAntiA90(enabled)
    if enabled == antiGuiEnabled then return true end
    antiGuiEnabled = enabled
    if enabled then
        startAntiA90_A90B()
        Notify("Anti A90", "Enabled", 2)
    else
        stopAntiA90_A90B()
        Notify("Anti A90", "Disabled", 2)
    end
    return true
end

--- Enable/disable Anti Glare (removes glare entity)
--- @param enabled boolean
--- @return boolean Success
local function SetAntiGlare(enabled)
    if enabled == antiGlareEnabled then return true end
    antiGlareEnabled = enabled
    if enabled then
        startAntiGlare()
        Notify("Anti Glare", "Enabled", 2)
    else
        stopAntiGlare()
        Notify("Anti Glare", "Disabled", 2)
    end
    return true
end

--- Enable/disable Anti Shade (removes shade entity from doors)
--- @param enabled boolean
--- @return boolean Success
local function SetAntiShade(enabled)
    if enabled == antiShadeEnabled then return true end
    antiShadeEnabled = enabled
    if enabled then
        startAntiShade()
        Notify("Anti Shade", "Enabled", 2)
    else
        stopAntiShade()
        Notify("Anti Shade", "Disabled", 2)
    end
    return true
end

--- Enable/disable Anti Lasers (removes laser traps)
--- @param enabled boolean
--- @return boolean Success
local function SetAntiLasers(enabled)
    if enabled == antiLasersEnabled then return true end
    antiLasersEnabled = enabled
    if enabled then
        startAntiLasers()
        Notify("Anti Lasers", "Enabled", 2)
    else
        stopAntiLasers()
        Notify("Anti Lasers", "Disabled", 2)
    end
    return true
end

--- Enable/disable Anti Void (prevents void teleport)
--- @param enabled boolean
--- @return boolean Success
local function SetAntiVoid(enabled)
    antiVoid = enabled
    player:SetAttribute("VoidDisabled", enabled)
    Notify("Anti Void", enabled and "Enabled" or "Disabled", 2)
    return true
end

--- Enable/disable Instant Interact (sets hold duration to 0)
--- @param enabled boolean
--- @return boolean Success
local function SetInstantInteract(enabled)
    if enabled == instantInteractEnabled then return true end
    instantInteractEnabled = enabled
    if enabled then
        startInstantInteractLoop()
        Notify("Instant Interact", "Enabled", 2)
    else
        if instantInteractThread then task.cancel(instantInteractThread); instantInteractThread = nil end
        Notify("Instant Interact", "Disabled", 2)
    end
    return true
end

-- ============================================================
--  ENTITY NOTIFICATIONS (Event-based)
-- ============================================================

if entitiesFolder then
    for _, obj in ipairs(entitiesFolder:GetChildren()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            Events.EntitySpawned:Fire(obj.Name)
        end
    end
    entitiesFolder.ChildAdded:Connect(function(child)
        if (child:IsA("Model") or child:IsA("BasePart")) then
            Events.EntitySpawned:Fire(child.Name)
        end
    end)
    entitiesFolder.ChildRemoved:Connect(function(child)
        if (child:IsA("Model") or child:IsA("BasePart")) then
            Events.EntityDespawned:Fire(child.Name)
        end
    end)
end

-- ============================================================
--  INITIALIZATION
-- ============================================================

local function init()
    task.spawn(scanExistingRooms)
    player:SetAttribute("VoidDisabled", antiVoid)
end

-- Re-apply on respawn
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    task.wait(1)
    if speedBoostEnabled then SetSpeedBoost(true) end
    if unlockJumpEnabled then SetUnlockJump(true) end
end)

init()

-- ============================================================
--  PUBLIC API
-- ============================================================

local ParadoxHelper = {
    -- Events
    Events = Events,
    
    -- Teleport
    TeleportNext = TeleportNext,
    TeleportPrev = TeleportPrev,
    TeleportToRoom = TeleportToRoom,
    GetCurrentRoom = getCurrentRoom,
    GetLoadedRooms = getLoadedRooms,
    
    -- Movement
    SetSpeedBoost = SetSpeedBoost,
    SetSpeedValue = SetSpeedValue,
    SetUnlockJump = SetUnlockJump,
    Kill = killPlayer,
    
    -- ESP
    SetMasterESP = SetMasterESP,
    SetItemESP = SetItemESP,
    SetEntityESP = SetEntityESP,
    SetTracers = SetTracers,
    SetShowItemNames = SetShowItemNames,
    SetESPCategories = SetESPCategories,
    SetTracerCategories = SetTracerCategories,
    SetESPCategoryColor = SetESPCategoryColor,
    SetFullbright = SetFullbright,
    
    -- Tools
    SkipCutscene = skipCutscene,
    FinishComputers = finishComputers,
    FinishLibrary = finishLibrary,
    FinishNest = finishNest,
    SeekChaseEnd = seekChaseEnd,
    TpNullZoneStart = tpNullZoneStart,
    SetAutoLoot = SetAutoLoot,
    SetLootCategories = SetLootCategories,
    
    -- Exploits
    SetNoShock = SetNoShock,
    SetAntiSnare = SetAntiSnare,
    SetAntiA90 = SetAntiA90,
    SetAntiGlare = SetAntiGlare,
    SetAntiShade = SetAntiShade,
    SetAntiLasers = SetAntiLasers,
    SetAntiVoid = SetAntiVoid,
    SetInstantInteract = SetInstantInteract,
    SetAntiEntity = SetAntiEntity,
    SetAntiEntityTargets = SetAntiEntityTargets,
}

return ParadoxHelper
