local ESPModule = {}

local defaultSettings = {
    Tracer_Color = Color3.fromRGB(255, 0, 0),
    Tracer_Thickness = 1,
    Tracer_Origin = "Bottom",
    Tracer_FollowMouse = false,
    Tracers = true
}

local player = game:GetService("Players").LocalPlayer
local camera = game:GetService("Workspace").CurrentCamera
local mouse = player:GetMouse()

local function NewLine(thickness, color)
    local line = Drawing.new("Line")
    line.Visible = false
    line.From = Vector2.new(0, 0)
    line.To = Vector2.new(0, 0)
    line.Color = color 
    line.Thickness = thickness
    line.Transparency = 1
    return line
end

local function Visibility(state, lib)
    for _, element in pairs(lib) do
        element.Visible = state
    end
end

local function GetRootPart(obj)
    if not obj then return nil end
    
    if obj:IsA("Model") then
        if obj.PrimaryPart then
            return obj.PrimaryPart
        end
        local humanoid = obj:FindFirstChild("Humanoid")
        if humanoid then
            local rootPart = obj:FindFirstChild("HumanoidRootPart")
            if rootPart and rootPart:IsA("BasePart") then
                return rootPart
            end
        end
        for _, part in ipairs(obj:GetDescendants()) do
            if part:IsA("BasePart") then
                return part
            end
        end
    elseif obj:IsA("BasePart") then
        return obj
    end
    return nil
end

function ESPModule.new(target, customSettings)
    local settings = {}
    for k, v in pairs(defaultSettings) do
        settings[k] = customSettings and customSettings[k] or v
    end
    
    local library = {
        blacktracer = NewLine(settings.Tracer_Thickness * 2, Color3.new(0, 0, 0)),
        tracer = NewLine(settings.Tracer_Thickness, settings.Tracer_Color),
    }
    
    local connection
    local function start()
        if connection then
            connection:Disconnect()
        end
        
        connection = game:GetService("RunService").RenderStepped:Connect(function()
            if not target or not target.Parent then
                Visibility(false, library)
                return
            end
            
            local rootPart = GetRootPart(target)
            
            if rootPart and rootPart.Parent then
                local humPos, onScreen = camera:WorldToViewportPoint(rootPart.Position)
                
                if onScreen then
                    if settings.Tracers then

                        if settings.Tracer_FollowMouse then
                            library.tracer.From = Vector2.new(mouse.X, mouse.Y + 36)
                            library.blacktracer.From = Vector2.new(mouse.X, mouse.Y + 36)
                        elseif settings.Tracer_Origin == "Middle" then
                            library.tracer.From = camera.ViewportSize * 0.5
                            library.blacktracer.From = camera.ViewportSize * 0.5
                        else
                            library.tracer.From = Vector2.new(camera.ViewportSize.X * 0.5, camera.ViewportSize.Y)
                            library.blacktracer.From = Vector2.new(camera.ViewportSize.X * 0.5, camera.ViewportSize.Y)
                        end
                        
                        library.tracer.To = Vector2.new(humPos.X, humPos.Y)
                        library.blacktracer.To = Vector2.new(humPos.X, humPos.Y)
                        
                        library.tracer.Color = settings.Tracer_Color
                        
                        Visibility(true, library)
                    else
                        Visibility(false, library)
                    end
                else
                    Visibility(false, library)
                end
            else
                Visibility(false, library)
            end
        end)
    end
    
    local function updateSettings(newSettings)
        for k, v in pairs(newSettings) do
            if settings[k] ~= nil then
                settings[k] = v
            end
        end
        library.tracer.Thickness = settings.Tracer_Thickness
        library.blacktracer.Thickness = settings.Tracer_Thickness * 2
        library.tracer.Color = settings.Tracer_Color
    end
    
    local function destroy()
        if connection then
            connection:Disconnect()
        end
        for _, element in pairs(library) do
            element:Remove()
        end
    end
    
    start()
    
    return {
        updateSettings = updateSettings,
        destroy = destroy
    }
end

return ESPModule
