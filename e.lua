-- ============================================================
--  Paradox Helper — Core Module
--  Modular version without GUI
--  All functions accept boolean/number/text parameters
--  Notifications are emitted via events
-- ============================================================

-- ─── Services ────────────────────────────────────────────────
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local UserInputService   = game:GetService("UserInputService")
local Lighting           = game:GetService("Lighting")
local RunService         = game:GetService("RunService")

-- ─── World refs ──────────────────────────────────────────────
local player            = Players.LocalPlayer
local playerName        = player.Name
local character         = player.Character or player.CharacterAdded:Wait()
local entitiesFolder    = workspace:WaitForChild("Entities", 10)
local currentRooms      = workspace:WaitForChild("CurrentRooms", 10)

-- ─── Module ─────────────────────────────────────────────────
local ParadoxHelper = {
    -- Events for notifications
    Events = {
        OnNotification = nil,  -- function(title, content, duration)
    },
    
    -- State
    State = {
        notificationsEnabled = true,
        dupeEnabled = false,
        
        -- Speed Boost
        speedBoostEnabled = false,
        speedBoostValue = 0,
        speedBoostConn = nil,
        
        -- Unlock Jump
        unlockJumpEnabled = false,
        unlockJumpConn = nil,
        
        -- Remove Shock Parts
        removeShockPartsEnabled = false,
        shockPartConn = nil,
        
        -- Fullbright
        fullbrightEnabled = false,
        fullbrightConn = nil,
        originalLighting = {},
        
        -- ESP
        masterEspEnabled = false,
        showItemNames = false,
        tracersEnabled = false,
        espEnabled = false,
        entityEspEnabled = false,
        entityTracerEnabled = false,
        categoryEnabled = {},
        tracerCategoryEnabled = {},
        categoryColors = {},
        activeESPInstances = {},
        activeEntityESPInstances = {},
        flatEntitySpheres = {},
        
        -- Anti Entity
        antiEntityEnabled = false,
        antiEntityConn = nil,
        isPlatform = false,
        antiEntityList = {},
        antiEntityTargets = {
            Cue = true, Route = true, UnknownEntity = true, A200 = true, A60New = true,
        },
        
        -- Auto Loot
        autoLootEnabled = false,
        autoLootThread = nil,
        autoLootCategories = {},
        
        -- Anti Snare
        antiSnareEnabled = false,
        snareConnection = nil,
        
        -- Anti A90/A90B
        antiGuiEnabled = false,
        guiConnection = nil,
        
        -- Anti Glare
        antiGlareEnabled = false,
        glareConnection = nil,
        
        -- Anti Shade
        antiShadeEnabled = false,
        shadeConnection = nil,
        
        -- Anti Lasers
        antiLasersEnabled = false,
        lasersConnection = nil,
        
        -- Anti Void
        antiVoidEnabled = false,
        
        -- Instant Interact
        instantInteractEnabled = false,
        instantInteractThread = nil,
        
        -- House Data (cached)
        houseData = nil,
        
        -- Keybinds
        keybindMap = {},
        keybindConn = nil,
    }
}

-- ─── Helper Functions ───────────────────────────────────────
local function getHumanoid()
    local wsChar = workspace:FindFirstChild(playerName)
    if not wsChar then return nil end
    return wsChar:FindFirstChild("Humanoid")
end

local function getWsCharacter()
    return workspace:FindFirstChild(playerName)
end

local function getLoadedRooms()
    if not currentRooms then return {} end
    local rooms = {}
    for _, room in ipairs(currentRooms:GetChildren()) do
        local num = tonumber(room.Name)
        if num then
            table.insert(rooms, num)
        end
    end
    table.sort(rooms)
    return rooms
end

local function teleportToRoom(roomNumber)
    if not currentRooms then return end
    local targetRoom = currentRooms:FindFirstChild(tostring(roomNumber))
    if not targetRoom then return end

    local targetPart = targetRoom.PrimaryPart
        or targetRoom:FindFirstChildWhichIsA("BasePart", true)
    if not targetPart then return end

    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
    end
end

local function getCurrentRoom()
    local clientData = workspace:FindFirstChild("ClientData")
    local val = clientData and clientData:FindFirstChild("CurrentRoom")
    if not val then return 0 end
    local v = val.Value
    if typeof(v) == "Instance" then
        return tonumber(v.Name) or 0
    end
    if v == nil or v == "" then return 0 end
    return tonumber(v) or 0
end

-- ─── Notification System ────────────────────────────────────
local function emitNotification(title, content, duration)
    if not ParadoxHelper.State.notificationsEnabled then return end
    if ParadoxHelper.Events.OnNotification then
        ParadoxHelper.Events.OnNotification(title, content, duration or 5)
    end
end

-- ─── Speed Boost ────────────────────────────────────────────
local function applySpeedBoost()
    local humanoid = getHumanoid()
    if not humanoid then return end
    humanoid:SetAttribute("SpeedBoost", ParadoxHelper.State.speedBoostValue)
end

local function startSpeedBoost()
    applySpeedBoost()
    
    if ParadoxHelper.State.speedBoostConn then
        ParadoxHelper.State.speedBoostConn:Disconnect()
    end
    
    local humanoid = getHumanoid()
    if not humanoid then return end
    
    ParadoxHelper.State.speedBoostConn = humanoid:GetAttributeChangedSignal("SpeedBoost"):Connect(function()
        if ParadoxHelper.State.speedBoostEnabled then
            local current = humanoid:GetAttribute("SpeedBoost")
            if current ~= ParadoxHelper.State.speedBoostValue then
                humanoid:SetAttribute("SpeedBoost", ParadoxHelper.State.speedBoostValue)
            end
        end
    end)
end

local function stopSpeedBoost()
    if ParadoxHelper.State.speedBoostConn then
        ParadoxHelper.State.speedBoostConn:Disconnect()
        ParadoxHelper.State.speedBoostConn = nil
    end
    local humanoid = getHumanoid()
    if humanoid then
        humanoid:SetAttribute("SpeedBoost", 0)
    end
end

function ParadoxHelper:SetSpeedBoost(enabled, value)
    if type(enabled) ~= "boolean" then error("SetSpeedBoost: enabled must be boolean") end
    if enabled and value ~= nil and type(value) ~= "number" then error("SetSpeedBoost: value must be number") end
    
    self.State.speedBoostEnabled = enabled
    if value then
        self.State.speedBoostValue = math.clamp(value, 1, 100)
    end
    
    if enabled then
        startSpeedBoost()
        emitNotification("Speed Boost", "Enabled - Value: " .. self.State.speedBoostValue, 2)
    else
        stopSpeedBoost()
        emitNotification("Speed Boost", "Disabled", 2)
    end
end

-- ─── Unlock Jump ────────────────────────────────────────────
local function startUnlockJump()
    local wsChar = getWsCharacter()
    if not wsChar then return end
    
    wsChar:SetAttribute("CanJump", true)
    
    if ParadoxHelper.State.unlockJumpConn then
        ParadoxHelper.State.unlockJumpConn:Disconnect()
    end
    
    ParadoxHelper.State.unlockJumpConn = wsChar:GetAttributeChangedSignal("CanJump"):Connect(function()
        if ParadoxHelper.State.unlockJumpEnabled then
            local current = wsChar:GetAttribute("CanJump")
            if current ~= true then
                wsChar:SetAttribute("CanJump", true)
            end
        end
    end)
end

local function stopUnlockJump()
    if ParadoxHelper.State.unlockJumpConn then
        ParadoxHelper.State.unlockJumpConn:Disconnect()
        ParadoxHelper.State.unlockJumpConn = nil
    end
end

function ParadoxHelper:SetUnlockJump(enabled)
    if type(enabled) ~= "boolean" then error("SetUnlockJump: enabled must be boolean") end
    
    self.State.unlockJumpEnabled = enabled
    if enabled then
        startUnlockJump()
        emitNotification("Unlock Jump", "Enabled", 2)
    else
        stopUnlockJump()
        emitNotification("Unlock Jump", "Disabled", 2)
    end
end

-- ─── Kill Character (KYS) ────────────────────────────────────
function ParadoxHelper:Kill()
    pcall(function()
        local wsChar = getWsCharacter()
        if not wsChar then return end
        local humanoid = wsChar:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.Health = 0
            emitNotification("Kill", "Character killed", 2)
        end
    end)
end

-- ─── Teleport Functions ─────────────────────────────────────
function ParadoxHelper:TeleportNextDoor()
    if self.State.isPlatform then
        emitNotification("Anti Entity", "TP blocked — entity active!", 2)
        return
    end
    local rooms = getLoadedRooms()
    if #rooms == 0 then return end
    teleportToRoom(rooms[#rooms])
    emitNotification("Teleport", "Teleported to door " .. rooms[#rooms], 2)
end

function ParadoxHelper:TeleportPrevDoor()
    if self.State.isPlatform then
        emitNotification("Anti Entity", "TP blocked — entity active!", 2)
        return
    end
    local rooms = getLoadedRooms()
    if #rooms == 0 then return end
    if #rooms >= 3 then
        teleportToRoom(rooms[#rooms - 2])
        emitNotification("Teleport", "Teleported to door " .. rooms[#rooms - 2], 2)
    else
        teleportToRoom(rooms[1])
        emitNotification("Teleport", "Teleported to door " .. rooms[1], 2)
    end
end

function ParadoxHelper:TeleportToRoom(roomNumber)
    if type(roomNumber) ~= "number" then error("TeleportToRoom: roomNumber must be number") end
    teleportToRoom(roomNumber)
    emitNotification("Teleport", "Teleported to room " .. roomNumber, 2)
end

-- ─── Skip Cutscene ──────────────────────────────────────────
function ParadoxHelper:SkipCutscene()
    pcall(function()
        ReplicatedStorage
            :WaitForChild("Assets", 5)
            :WaitForChild("Events", 5)
            :WaitForChild("FireVote", 5)
            :FireServer()
    end)
    emitNotification("Skip Cutscene", "Vote to skip fired", 2)
end

-- ─── Finish Computers (Room 110) ────────────────────────────
function ParadoxHelper:FinishComputers()
    if not currentRooms then return end

    local clientData = workspace:FindFirstChild("ClientData")
    local currentRoom = clientData and clientData:FindFirstChild("CurrentRoom")
    if not currentRoom or not currentRoom.Value or currentRoom.Value.Name ~= "110" then
        emitNotification("Finish Computers", "You are not in room 110!", 5)
        return
    end

    local room110 = currentRooms:FindFirstChild("110")
    if not room110 then return end

    local scriptables = room110:FindFirstChild("Scriptables")
    if not scriptables then return end

    pcall(function()
        local finishEvent = ReplicatedStorage
            :WaitForChild("Assets", 5)
            :WaitForChild("Events", 5)
            :WaitForChild("FinishDoor100Puzzle1", 5)

        if not finishEvent then return end
        if not finishEvent:IsA("RemoteEvent") then return end

        for _, computer in ipairs(scriptables:GetChildren()) do
            finishEvent:FireServer(computer)
        end
    end)

    task.delay(7, function()
        local r110 = currentRooms:FindFirstChild("110")
        if not r110 then return end

        local sc = r110:FindFirstChild("Scriptables")
        if not sc then return end

        local gameData = workspace:FindFirstChild("GameData")
        if not gameData then return end

        local endingPath = gameData:FindFirstChild("CurrentEndingPath")
        if not endingPath then return end

        local endingType = endingPath.Value

        local teleportTarget
        if endingType == "Good" then
            teleportTarget = sc:WaitForChild("ExitDoor", 5)
        elseif endingType == "Bad" then
            teleportTarget = sc:WaitForChild("BadEndingPuzzle", 5)
        end

        if not teleportTarget then return end

        local targetCFrame = teleportTarget.PrimaryPart and teleportTarget.PrimaryPart.CFrame
        if not targetCFrame then
            local part = teleportTarget:FindFirstChildWhichIsA("BasePart", true)
            if part then targetCFrame = part.CFrame end
        end

        if not targetCFrame then return end

        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = targetCFrame + Vector3.new(0, 3, 0)
        end

        if endingType == "Bad" then
            emitNotification("Bad Ending", "Spin the puzzle to get your ending!", 10)
        end
    end)
    
    emitNotification("Finish Computers", "Processing room 110 computers", 3)
end

-- ─── Teleport to NullZone Start ─────────────────────────────
function ParadoxHelper:TeleportNullZoneStart()
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local target = workspace.NullZone and workspace.NullZone.Cutscene and workspace.NullZone.Cutscene.CameraRig

    if hrp and target then
        hrp.CFrame = target:GetPivot() + Vector3.new(0, 0, 0)
        emitNotification("NullZone", "Teleported to start", 2)
    else
        emitNotification("NullZone", "Failed to teleport", 2)
    end
end

-- ─── Finish Library ─────────────────────────────────────────
function ParadoxHelper:FinishLibrary()
    local nullZone = workspace:FindFirstChild("NullZone")
    if not nullZone then return end
    
    local function completeLibrary(child)
        if child.Name == "Library" then
            local args = {"padlock"}
            ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Events"):WaitForChild("PuzzleCompletedNull"):FireServer(unpack(args))
            game.Players.LocalPlayer.Character.PrimaryPart.CFrame = child.MisleadingPortal:GetPivot()
            emitNotification("Library", "Library completed", 3)
        end
    end

    if not ParadoxHelper.State._libraryConn then
        ParadoxHelper.State._libraryConn = workspace.NullZone.ChildAdded:Connect(completeLibrary)
    end

    if workspace.NullZone:FindFirstChild("Library") then
        completeLibrary(workspace.NullZone.Library)
    end
end

-- ─── Finish Nest (Mines) ────────────────────────────────────
local ANCHOR_NAMES = {"A", "B", "C"}

function ParadoxHelper:FinishNest()
    local nullZone = workspace:FindFirstChild("NullZone")
    if not nullZone then return end

    local nest = nullZone:FindFirstChild("Nest")
    if not nest then return end

    local rep = game:GetService("ReplicatedStorage")
    local assets = rep:FindFirstChild("Assets")
    if not assets then return end
    local events = assets:FindFirstChild("Events")
    if not events then return end
    local finishEvent = events:FindFirstChild("NestAnchorFinish")
    if not finishEvent then return end

    -- 1. Anchors
    local scriptables = nest:FindFirstChild("Scriptables")
    local anchorsFolder = scriptables and scriptables:FindFirstChild("Anchors")
    if anchorsFolder then
        for _, name in ipairs(ANCHOR_NAMES) do
            local anchor = nil
            for _, obj in ipairs(anchorsFolder:GetChildren()) do
                if obj:GetAttribute("friendlyName") == name then
                    anchor = obj
                    break
                end
            end
            if anchor and anchor:GetAttribute("Code") then
                pcall(function()
                    finishEvent:FireServer(anchor, anchor:GetAttribute("Code"))
                end)
                task.wait(0.4)
            end
        end
    end

    -- 2. Teleport to button
    local console = nest:FindFirstChild("Console")
    local cylinder = console and console:FindFirstChild("Cylinder")
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp and cylinder then
        hrp.CFrame = cylinder:GetPivot() + Vector3.new(4, 0, 0)
    end

    emitNotification("Nest Auto", "You have 20 seconds to manually press the button!", 6)

    local startTime = tick()
    while (tick() - startTime) < 20 do
        if player:GetAttribute("InCutscene") == true then
            emitNotification("Nest Auto", "Button pressed! Waiting for cutscene...", 5)
            while player:GetAttribute("InCutscene") == true do
                task.wait(0.3)
            end
            break
        end
        task.wait(0.5)
    end

    -- 4. Teleport to portal
    local portal = nest:FindFirstChild("MisleadingPortal")
    if hrp and portal then
        hrp.CFrame = portal:GetPivot() + Vector3.new(0, 0, 0)
    end

    emitNotification("Nest Auto", "Teleported to portal!", 4)
end

-- ─── Seek Chase End ─────────────────────────────────────────
function ParadoxHelper:SeekChaseEnd()
    local nullZone = workspace:FindFirstChild("NullZone")
    if not nullZone then return end

    local chase = nullZone:FindFirstChild("Chase")
    if not chase then return end

    local lab = chase:FindFirstChild("Lab")
    if not lab then return end

    local endingChase = lab:FindFirstChild("EndingChase")
    if not endingChase then return end

    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = endingChase:GetPivot() + Vector3.new(0, 0, 0)
        emitNotification("Seek Chase", "Teleported to chase end", 2)
    end
end

-- ─── Fullbright ─────────────────────────────────────────────
local function applyFullbright()
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    Lighting.FogEnd = 100000
    Lighting.GlobalShadows = false
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
end

local function restoreLighting()
    local orig = ParadoxHelper.State.originalLighting
    Lighting.Brightness = orig.Brightness
    Lighting.ClockTime = orig.ClockTime
    Lighting.FogEnd = orig.FogEnd
    Lighting.GlobalShadows = orig.GlobalShadows
    Lighting.OutdoorAmbient = orig.OutdoorAmbient
end

function ParadoxHelper:SetFullbright(enabled)
    if type(enabled) ~= "boolean" then error("SetFullbright: enabled must be boolean") end
    
    if enabled and not self.State.fullbrightEnabled then
        self.State.originalLighting = {
            Brightness = Lighting.Brightness,
            ClockTime = Lighting.ClockTime,
            FogEnd = Lighting.FogEnd,
            GlobalShadows = Lighting.GlobalShadows,
            OutdoorAmbient = Lighting.OutdoorAmbient
        }
        applyFullbright()
        
        if not self.State.fullbrightConn then
            self.State.fullbrightConn = Lighting.Changed:Connect(function()
                if self.State.fullbrightEnabled then applyFullbright() end
            end)
        end
        emitNotification("Fullbright", "Enabled", 2)
    elseif not enabled and self.State.fullbrightEnabled then
        if self.State.fullbrightConn then
            self.State.fullbrightConn:Disconnect()
            self.State.fullbrightConn = nil
        end
        restoreLighting()
        emitNotification("Fullbright", "Disabled", 2)
    end
    
    self.State.fullbrightEnabled = enabled
end

-- ─── Shock Part Removal ─────────────────────────────────────
local function clearShockPartsInRoom(room)
    pcall(function()
        local lights = room:FindFirstChild("Lights")
        if not lights then return end
        
        for _, light in ipairs(lights:GetChildren()) do
            local bulb = light:FindFirstChild("Bulb")
            if bulb then
                local shockPart = bulb:FindFirstChild("ShockPart")
                if shockPart then
                    pcall(function() shockPart:Destroy() end)
                end
            end
        end
    end)
end

local function startShockPartRemoval()
    if not currentRooms then return end
    
    for _, room in ipairs(currentRooms:GetChildren()) do
        clearShockPartsInRoom(room)
    end
    
    if ParadoxHelper.State.shockPartConn then
        ParadoxHelper.State.shockPartConn:Disconnect()
    end
    
    ParadoxHelper.State.shockPartConn = currentRooms.DescendantAdded:Connect(function(desc)
        if ParadoxHelper.State.removeShockPartsEnabled and desc.Name == "ShockPart" and desc.Parent and desc.Parent.Name == "Bulb" then
            pcall(function() desc:Destroy() end)
        end
    end)
end

local function stopShockPartRemoval()
    if ParadoxHelper.State.shockPartConn then
        ParadoxHelper.State.shockPartConn:Disconnect()
        ParadoxHelper.State.shockPartConn = nil
    end
end

function ParadoxHelper:SetRemoveShockParts(enabled)
    if type(enabled) ~= "boolean" then error("SetRemoveShockParts: enabled must be boolean") end
    
    self.State.removeShockPartsEnabled = enabled
    if enabled then
        startShockPartRemoval()
        emitNotification("NoShock", "Enabled", 2)
    else
        stopShockPartRemoval()
        emitNotification("NoShock", "Disabled", 2)
    end
end

-- ─── Anti Snare ─────────────────────────────────────────────
local function removeAllSnares()
    for _, descendant in ipairs(workspace:GetDescendants()) do
        if descendant.Name == "Snare" then
            pcall(function() descendant:Destroy() end)
        end
    end
end

local function startAntiSnare()
    removeAllSnares()
    ParadoxHelper.State.snareConnection = workspace.DescendantAdded:Connect(function(descendant)
        if descendant.Name == "Snare" then
            task.spawn(function()
                task.wait(0.15)
                if descendant and descendant.Parent then
                    pcall(function() descendant:Destroy() end)
                end
            })
        end
    end)
end

local function stopAntiSnare()
    if ParadoxHelper.State.snareConnection then
        ParadoxHelper.State.snareConnection:Disconnect()
        ParadoxHelper.State.snareConnection = nil
    end
end

function ParadoxHelper:SetAntiSnare(enabled)
    if type(enabled) ~= "boolean" then error("SetAntiSnare: enabled must be boolean") end
    
    self.State.antiSnareEnabled = enabled
    if enabled then
        startAntiSnare()
        emitNotification("Anti Snare", "Enabled", 2)
    else
        stopAntiSnare()
        emitNotification("Anti Snare", "Disabled", 2)
    end
end

-- ─── Anti A90/A90B ──────────────────────────────────────────
local function removeA90BStatic()
    pcall(function()
        local gui = player:WaitForChild("PlayerGui", 3)
        if not gui then return end
        local nodes = {"Initiate", "Library", "Entities", "Lab", "A90B", "a90bModule", "assets", "Static"}
        local cur = gui
        for _, n in ipairs(nodes) do
            if not cur then return end
            cur = cur:FindFirstChild(n)
        end
        if cur then cur:Destroy() end
    end)
end

local function startAntiA90()
    local playerGui = player:WaitForChild("PlayerGui")
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui.Name == "a90b" or gui.Name == "a90" then
            pcall(function() gui:Destroy() end)
        end
    end
    
    local lightingEffect = Lighting:FindFirstChild("a90bCc")
    if lightingEffect then
        pcall(function() lightingEffect:Destroy() end)
    end
    
    ParadoxHelper.State.guiConnection = playerGui.ChildAdded:Connect(function(child)
        if child.Name == "a90b" or child.Name == "a90" then
            pcall(function() child:Destroy() end)
        end
    end)
    
    Lighting.ChildAdded:Connect(function(child)
        if child.Name == "a90bCc" then
            pcall(function() child:Destroy() end)
        end
    end)
    
    removeA90BStatic()
    
    player:WaitForChild("PlayerGui").ChildAdded:Connect(function(child)
        if child.Name == "Initiate" then
            task.wait(1)
            removeA90BStatic()
        end
    end)
end

local function stopAntiA90()
    if ParadoxHelper.State.guiConnection then
        ParadoxHelper.State.guiConnection:Disconnect()
        ParadoxHelper.State.guiConnection = nil
    end
end

function ParadoxHelper:SetAntiA90(enabled)
    if type(enabled) ~= "boolean" then error("SetAntiA90: enabled must be boolean") end
    
    self.State.antiGuiEnabled = enabled
    if enabled then
        startAntiA90()
        emitNotification("Anti A90/A90B", "Enabled", 2)
    else
        stopAntiA90()
        emitNotification("Anti A90/A90B", "Disabled", 2)
    end
end

-- ─── Anti Glare ─────────────────────────────────────────────
local function startAntiGlare()
    if not entitiesFolder then return end
    
    for _, ent in ipairs(entitiesFolder:GetChildren()) do
        if ent.Name == "Glare" then
            pcall(function() ent:Destroy() end)
        end
    end
    
    ParadoxHelper.State.glareConnection = entitiesFolder.ChildAdded:Connect(function(child)
        if child.Name == "Glare" then
            pcall(function() child:Destroy() end)
        end
    end)
end

local function stopAntiGlare()
    if ParadoxHelper.State.glareConnection then
        ParadoxHelper.State.glareConnection:Disconnect()
        ParadoxHelper.State.glareConnection = nil
    end
end

function ParadoxHelper:SetAntiGlare(enabled)
    if type(enabled) ~= "boolean" then error("SetAntiGlare: enabled must be boolean") end
    
    self.State.antiGlareEnabled = enabled
    if enabled then
        startAntiGlare()
        emitNotification("Anti Glare", "Enabled", 2)
    else
        stopAntiGlare()
        emitNotification("Anti Glare", "Disabled", 2)
    end
end

-- ─── Anti Shade ─────────────────────────────────────────────
local function startAntiShade()
    if not currentRooms then return end
    
    for _, room in ipairs(currentRooms:GetChildren()) do
        for _, desc in ipairs(room:GetDescendants()) do
            if desc.Name == "Shade" then
                pcall(function() desc:Destroy() end)
            end
        end
    end
    
    ParadoxHelper.State.shadeConnection = currentRooms.DescendantAdded:Connect(function(child)
        if child.Name == "Shade" then
            pcall(function() child:Destroy() end)
        end
    end)
end

local function stopAntiShade()
    if ParadoxHelper.State.shadeConnection then
        ParadoxHelper.State.shadeConnection:Disconnect()
        ParadoxHelper.State.shadeConnection = nil
    end
end

function ParadoxHelper:SetAntiShade(enabled)
    if type(enabled) ~= "boolean" then error("SetAntiShade: enabled must be boolean") end
    
    self.State.antiShadeEnabled = enabled
    if enabled then
        startAntiShade()
        emitNotification("Anti Shade", "Enabled", 2)
    else
        stopAntiShade()
        emitNotification("Anti Shade", "Disabled", 2)
    end
end

-- ─── Anti Lasers ────────────────────────────────────────────
local function startAntiLasers()
    if not currentRooms then return end
    
    for _, room in ipairs(currentRooms:GetChildren()) do
        local lasers = room:FindFirstChild("Lasers")
        if lasers then
            for _, laser in ipairs(lasers:GetChildren()) do
                if laser.Name == "LaserPair" then
                    pcall(function() laser:Destroy() end)
                end
            end
        end
    end
    
    ParadoxHelper.State.lasersConnection = currentRooms.DescendantAdded:Connect(function(child)
        if child.Name == "LaserPair" and child.Parent and child.Parent.Name == "Lasers" then
            pcall(function() child:Destroy() end)
        end
    end)
end

local function stopAntiLasers()
    if ParadoxHelper.State.lasersConnection then
        ParadoxHelper.State.lasersConnection:Disconnect()
        ParadoxHelper.State.lasersConnection = nil
    end
end

function ParadoxHelper:SetAntiLasers(enabled)
    if type(enabled) ~= "boolean" then error("SetAntiLasers: enabled must be boolean") end
    
    self.State.antiLasersEnabled = enabled
    if enabled then
        startAntiLasers()
        emitNotification("Anti Lasers", "Enabled", 2)
    else
        stopAntiLasers()
        emitNotification("Anti Lasers", "Disabled", 2)
    end
end

-- ─── Anti Void ──────────────────────────────────────────────
function ParadoxHelper:SetAntiVoid(enabled)
    if type(enabled) ~= "boolean" then error("SetAntiVoid: enabled must be boolean") end
    
    self.State.antiVoidEnabled = enabled
    player:SetAttribute("VoidDisabled", enabled)
    emitNotification("Anti Void", enabled and "Enabled" or "Disabled", 2)
end

-- ─── Instant Interact ───────────────────────────────────────
local function startInstantInteract()
    if ParadoxHelper.State.instantInteractThread then
        task.cancel(ParadoxHelper.State.instantInteractThread)
    end
    
    ParadoxHelper.State.instantInteractThread = task.spawn(function()
        while ParadoxHelper.State.instantInteractEnabled do
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and currentRooms then
                local pos = hrp.Position
                for _, prompt in ipairs(currentRooms:GetDescendants()) do
                    if not ParadoxHelper.State.instantInteractEnabled then break end
                    if prompt:IsA("ProximityPrompt") then
                        if prompt.Parent and prompt.Parent.Name == "LeftGascap" then continue end
                        local part = prompt.Parent
                        if part and part:IsA("BasePart") then
                            if (part.Position - pos).Magnitude <= 13 then
                                if prompt.HoldDuration ~= 0 then
                                    prompt.HoldDuration = 0
                                end
                            end
                        end
                    end
                end
            end
            task.wait(0.5)
        end
    end)
end

local function stopInstantInteract()
    if ParadoxHelper.State.instantInteractThread then
        task.cancel(ParadoxHelper.State.instantInteractThread)
        ParadoxHelper.State.instantInteractThread = nil
    end
end

function ParadoxHelper:SetInstantInteract(enabled)
    if type(enabled) ~= "boolean" then error("SetInstantInteract: enabled must be boolean") end
    
    self.State.instantInteractEnabled = enabled
    if enabled then
        startInstantInteract()
        emitNotification("Instant Interact", "Enabled", 2)
    else
        stopInstantInteract()
        emitNotification("Instant Interact", "Disabled", 2)
    end
end

-- ─── Entity Notifications ───────────────────────────────────
local function onEntitySpawned(child)
    if not (child:IsA("Model") or child:IsA("BasePart")) then return end
    
    local message = child.Name .. " appeared — Hide!"
    if child.Name == "Terminus" or child.Name == "IlVerdeMisleadingChasing" then
        message = child.Name .. " appeared — Run!"
    elseif child.Name == "Glare" then
        message = child.Name .. " appeared — Don't look at it!"
    elseif child.Name == "Ghoul" then
        message = child.Name .. " appeared — Crouch & stay silent!"
    elseif child.Name == "Scope" then
        message = child.Name .. " appeared — Red light, Green light!"
    end
    
    emitNotification("Entity Spawned", message, 6)
end

local function onEntityDespawned(child)
    if not (child:IsA("Model") or child:IsA("BasePart")) then return end
    emitNotification("Entity Gone", child.Name .. " has despawned.", 3)
end

function ParadoxHelper:SetEntityNotifications(enabled)
    if type(enabled) ~= "boolean" then error("SetEntityNotifications: enabled must be boolean") end
    
    self.State.notificationsEnabled = enabled
    emitNotification("Entity Notifications", enabled and "Enabled" or "Disabled", 2)
end

-- ─── Anti Entity (2D entities teleport) ─────────────────────
local function buildAntiEntityHouse(targetCFrame)
    -- Simplified house building (you can expand this)
    local model = Instance.new("Model")
    model.Name = "_AntiEntityHouse"
    model.Parent = workspace
    
    local platform = Instance.new("Part")
    platform.Name = "Platform"
    platform.Size = Vector3.new(10, 1, 10)
    platform.Anchored = true
    platform.CanCollide = true
    platform.Transparency = 0.5
    platform.Color = Color3.fromRGB(100, 100, 100)
    platform.Parent = model
    platform.CFrame = targetCFrame
    
    model:PivotTo(targetCFrame)
    return model
end

local function saveFromEntity(entity)
    table.insert(ParadoxHelper.State.antiEntityList, entity)
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    if ParadoxHelper.State.isPlatform then return end
    ParadoxHelper.State.isPlatform = true
    
    local lastPos = humanoidRootPart.CFrame
    local newPosition = humanoidRootPart.CFrame + Vector3.new(0, 1500, 0)
    humanoidRootPart.CFrame = newPosition
    
    local houseModel = buildAntiEntityHouse(newPosition)
    
    while #ParadoxHelper.State.antiEntityList > 0 do
        task.wait(1)
    end
    
    pcall(function() houseModel:Destroy() end)
    ParadoxHelper.State.isPlatform = false
    humanoidRootPart.CFrame = lastPos
end

local function startAntiEntity()
    if ParadoxHelper.State.antiEntityConn then
        ParadoxHelper.State.antiEntityConn:Disconnect()
    end
    
    ParadoxHelper.State.antiEntityConn = workspace.Entities.ChildAdded:Connect(function(child)
        if not ParadoxHelper.State.antiEntityEnabled then return end
        if ParadoxHelper.State.antiEntityTargets[child.Name] then
            task.spawn(saveFromEntity, child)
        end
    end)
end

local function stopAntiEntity()
    if ParadoxHelper.State.antiEntityConn then
        ParadoxHelper.State.antiEntityConn:Disconnect()
        ParadoxHelper.State.antiEntityConn = nil
    end
    if ParadoxHelper.State.isPlatform then
        table.clear(ParadoxHelper.State.antiEntityList)
    end
end

function ParadoxHelper:SetAntiEntity(enabled)
    if type(enabled) ~= "boolean" then error("SetAntiEntity: enabled must be boolean") end
    
    self.State.antiEntityEnabled = enabled
    if enabled then
        startAntiEntity()
        emitNotification("Anti Entity", "Enabled", 2)
    else
        stopAntiEntity()
        emitNotification("Anti Entity", "Disabled", 2)
    end
end

function ParadoxHelper:SetAntiEntityTargets(targets)
    if type(targets) ~= "table" then error("SetAntiEntityTargets: targets must be table") end
    
    for name, enabled in pairs(targets) do
        if self.State.antiEntityTargets[name] ~= nil then
            self.State.antiEntityTargets[name] = enabled
        end
    end
end

-- ─── Auto Loot ──────────────────────────────────────────────
local lootCategoryNames = {
    "Ignore shop items", "Amethysts", "Batteries", "Bandages", "Vitamins",
    "Keycards", "Flashlights", "Lighters", "BulkLight",
    "DeceivingDust", "Silver", "Sword",
}

local hidingLockerNames = {
    "Warehouse_HidingLocker", "HidingLocker", "Toolshed", "CaveLocker", "TrueLabHidingLocker",
}

local espCategories = {
    { Name = "Amethysts", Pattern = "Amethyst" },
    { Name = "BreakableCrate", Pattern = "BreakableCrate" },
    { Name = "Batteries", Pattern = "Battery" },
    { Name = "Bandages", Pattern = "Bandage" },
    { Name = "Vitamins", Pattern = "Vitamin" },
    { Name = "Keycards", IsMatch = function(n) return string.find(n, "Keycard") and not string.find(n, "Collision") and not string.find(n, "LootLocker") end },
    { Name = "Flashlights", Pattern = "Flashlight" },
    { Name = "Lighters", Pattern = "Lighter" },
    { Name = "BulkLight", Pattern = "BulkLight" },
    { Name = "DeceivingDust", Pattern = "DeceivingDust" },
    { Name = "Silver", Pattern = "Silver" },
    { Name = "Sword", Pattern = "Sword" },
}

local function getCategoryForItem(item)
    local itemName = item.Name
    for _, cat in ipairs(espCategories) do
        if cat.IsMatch then
            if cat.IsMatch(itemName, item) then return cat.Name end
        elseif cat.Pattern then
            if string.find(itemName, cat.Pattern) then return cat.Name end
        end
    end
    if table.find(hidingLockerNames, itemName) then return "HidingLockers" end
    if itemName == "Door" then return "Doors" end
    if itemName == "Gate" or itemName == "BasementGate" then return "Gates" end
    return nil
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

local function doAutoLoot()
    if not currentRooms then return end
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local pos = hrp.Position

    for _, prompt in ipairs(currentRooms:GetDescendants()) do
        if not ParadoxHelper.State.autoLootEnabled then return end
        if not prompt:IsA("ProximityPrompt") then continue end
        if prompt:GetAttribute("PH_Looted") then continue end

        local part = prompt.Parent
        if not (part and part:IsA("BasePart")) then continue end
        if (part.Position - pos).Magnitude > 13 then continue end

        local item = part
        local catName = nil
        while item and item ~= workspace and item ~= currentRooms do
            catName = getCategoryForItem(item)
            if catName then break end
            item = item.Parent
        end

        if not catName or not ParadoxHelper.State.autoLootCategories[catName] then continue end
        if ParadoxHelper.State.autoLootCategories["Ignore shop items"] and isShopItem(item) then continue end

        prompt:SetAttribute("PH_Looted", true)
        prompt.Enabled = true
        prompt.HoldDuration = 0
        prompt.MaxActivationDistance = 13
        pcall(function() fireproximityprompt(prompt) end)
    end
end

local function startAutoLootThread()
    if ParadoxHelper.State.autoLootThread then
        task.cancel(ParadoxHelper.State.autoLootThread)
    end
    
    ParadoxHelper.State.autoLootThread = task.spawn(function()
        while ParadoxHelper.State.autoLootEnabled do
            pcall(doAutoLoot)
            task.wait(0.5)
        end
    end)
end

local function stopAutoLootThread()
    if ParadoxHelper.State.autoLootThread then
        task.cancel(ParadoxHelper.State.autoLootThread)
        ParadoxHelper.State.autoLootThread = nil
    end
end

function ParadoxHelper:SetAutoLoot(enabled)
    if type(enabled) ~= "boolean" then error("SetAutoLoot: enabled must be boolean") end
    
    self.State.autoLootEnabled = enabled
    if enabled then
        startAutoLootThread()
        emitNotification("Auto Loot", "Enabled", 2)
    else
        stopAutoLootThread()
        emitNotification("Auto Loot", "Disabled", 2)
    end
end

function ParadoxHelper:SetAutoLootCategories(categories)
    if type(categories) ~= "table" then error("SetAutoLootCategories: categories must be table") end
    
    for name, enabled in pairs(categories) do
        self.State.autoLootCategories[name] = enabled
    end
end

-- ─── Keybind System ─────────────────────────────────────────
function ParadoxHelper:SetKeybind(key, callback)
    if type(key) ~= "string" then error("SetKeybind: key must be string") end
    if type(callback) ~= "function" then error("SetKeybind: callback must be function") end
    
    self.State.keybindMap[key] = callback
end

function ParadoxHelper:RemoveKeybind(key)
    if type(key) ~= "string" then error("RemoveKeybind: key must be string") end
    self.State.keybindMap[key] = nil
end

function ParadoxHelper:ClearKeybinds()
    self.State.keybindMap = {}
end

-- Initialize keybind system
local function initKeybindSystem()
    if self.State.keybindConn then
        self.State.keybindConn:Disconnect()
    end
    
    self.State.keybindConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        
        local keyName = input.KeyCode.Name
        if self.State.keybindMap[keyName] then
            task.spawn(self.State.keybindMap[keyName])
        end
    end)
end

-- ─── ESP System (simplified) ────────────────────────────────
function ParadoxHelper:SetMasterESP(enabled)
    if type(enabled) ~= "boolean" then error("SetMasterESP: enabled must be boolean") end
    self.State.masterEspEnabled = enabled
end

function ParadoxHelper:SetItemESP(enabled)
    if type(enabled) ~= "boolean" then error("SetItemESP: enabled must be boolean") end
    self.State.espEnabled = enabled
end

function ParadoxHelper:SetEntityESP(enabled)
    if type(enabled) ~= "boolean" then error("SetEntityESP: enabled must be boolean") end
    self.State.entityEspEnabled = enabled
end

function ParadoxHelper:SetShowItemNames(enabled)
    if type(enabled) ~= "boolean" then error("SetShowItemNames: enabled must be boolean") end
    self.State.showItemNames = enabled
end

function ParadoxHelper:SetTracers(enabled)
    if type(enabled) ~= "boolean" then error("SetTracers: enabled must be boolean") end
    self.State.tracersEnabled = enabled
end

function ParadoxHelper:SetCategoryEnabled(category, enabled)
    if type(category) ~= "string" then error("SetCategoryEnabled: category must be string") end
    if type(enabled) ~= "boolean" then error("SetCategoryEnabled: enabled must be boolean") end
    self.State.categoryEnabled[category] = enabled
end

function ParadoxHelper:SetCategoryColor(category, color)
    if type(category) ~= "string" then error("SetCategoryColor: category must be string") end
    if type(color) ~= "Color3" then error("SetCategoryColor: color must be Color3") end
    self.State.categoryColors[category] = color
end

-- ─── Initialize ─────────────────────────────────────────────
function ParadoxHelper:Init()
    -- Store original lighting
    self.State.originalLighting = {
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        FogEnd = Lighting.FogEnd,
        GlobalShadows = Lighting.GlobalShadows,
        OutdoorAmbient = Lighting.OutdoorAmbient
    }
    
    -- Initialize auto loot categories
    for _, name in ipairs(lootCategoryNames) do
        self.State.autoLootCategories[name] = false
    end
    self.State.autoLootCategories["Ignore shop items"] = true
    
    -- Initialize ESP categories
    for _, cat in ipairs(espCategories) do
        self.State.categoryEnabled[cat.Name] = false
        self.State.categoryColors[cat.Name] = Color3.fromRGB(255, 0, 255)
        self.State.tracerCategoryEnabled[cat.Name] = false
    end
    
    -- Initialize entity notifications
    if entitiesFolder then
        for _, obj in ipairs(entitiesFolder:GetChildren()) do
            onEntitySpawned(obj)
        end
        entitiesFolder.ChildAdded:Connect(onEntitySpawned)
        entitiesFolder.ChildRemoved:Connect(onEntityDespawned)
    end
    
    -- Initialize keybind system
    initKeybindSystem()
    
    -- Clean up anti entity list
    task.spawn(function()
        while task.wait(0.1) do
            for i = #self.State.antiEntityList, 1, -1 do
                if not self.State.antiEntityList[i] or not self.State.antiEntityList[i].Parent then
                    table.remove(self.State.antiEntityList, i)
                end
            end
        end
    end)
    
    emitNotification("Paradox Helper", "Module loaded successfully!", 3)
end

-- ─── Cleanup ────────────────────────────────────────────────
function ParadoxHelper:Destroy()
    if self.State.speedBoostConn then self.State.speedBoostConn:Disconnect() end
    if self.State.unlockJumpConn then self.State.unlockJumpConn:Disconnect() end
    if self.State.shockPartConn then self.State.shockPartConn:Disconnect() end
    if self.State.fullbrightConn then self.State.fullbrightConn:Disconnect() end
    if self.State.snareConnection then self.State.snareConnection:Disconnect() end
    if self.State.guiConnection then self.State.guiConnection:Disconnect() end
    if self.State.glareConnection then self.State.glareConnection:Disconnect() end
    if self.State.shadeConnection then self.State.shadeConnection:Disconnect() end
    if self.State.lasersConnection then self.State.lasersConnection:Disconnect() end
    if self.State.antiEntityConn then self.State.antiEntityConn:Disconnect() end
    if self.State.keybindConn then self.State.keybindConn:Disconnect() end
    
    stopAutoLootThread()
    stopInstantInteract()
    
    -- Restore lighting
    if self.State.fullbrightEnabled then
        restoreLighting()
    end
    
    self.State = nil
end

return ParadoxHelper
