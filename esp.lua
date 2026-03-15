local ESPModule = {}

local player = game:GetService("Players").LocalPlayer
local camera = game:GetService("Workspace").CurrentCamera
local mouse = player:GetMouse()

local Settings = {
    Tracer_Color = Color3.fromRGB(255, 0, 0),
    Tracer_Thickness = 1,
    Tracer_Origin = "Bottom",
    Tracer_FollowMouse = false,
    Tracers = true
}

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

function ESPModule.new(target, color)
    local library = {
        blacktracer = NewLine(Settings.Tracer_Thickness * 2, Color3.new(0, 0, 0)),
        tracer = NewLine(Settings.Tracer_Thickness, color or Settings.Tracer_Color),
    }
    
    local connection
    connection = game:GetService("RunService").RenderStepped:Connect(function()
        if not target or not target.Parent then
            Visibility(false, library)
            if connection then connection:Disconnect() end
            return
        end
        
        local rootPart = GetRootPart(target)
        
        if rootPart and rootPart.Parent then
            local humPos, onScreen = camera:WorldToViewportPoint(rootPart.Position)
            
            if onScreen then
                if Settings.Tracers then
                    -- Set origin
                    if Settings.Tracer_FollowMouse then
                        library.tracer.From = Vector2.new(mouse.X, mouse.Y + 36)
                        library.blacktracer.From = Vector2.new(mouse.X, mouse.Y + 36)
                    elseif Settings.Tracer_Origin == "Middle" then
                        library.tracer.From = camera.ViewportSize * 0.5
                        library.blacktracer.From = camera.ViewportSize * 0.5
                    else
                        library.tracer.From = Vector2.new(camera.ViewportSize.X * 0.5, camera.ViewportSize.Y)
                        library.blacktracer.From = Vector2.new(camera.ViewportSize.X * 0.5, camera.ViewportSize.Y)
                    end
                    
                    -- Set target
                    library.tracer.To = Vector2.new(humPos.X, humPos.Y)
                    library.blacktracer.To = Vector2.new(humPos.X, humPos.Y)
                    
                    library.tracer.Color = color or Settings.Tracer_Color
                    
                    Visibility(true, library)
                end
            else
                Visibility(false, library)
            end
        else
            Visibility(false, library)
        end
    end)
    
    return {
        destroy = function()
            if connection then
                connection:Disconnect()
            end
            for _, element in pairs(library) do
                element:Remove()
            end
        end
    }
end

return ESPModule
