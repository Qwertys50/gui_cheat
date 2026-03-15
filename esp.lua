local ESPModule = {}

local player = game:GetService("Players").LocalPlayer
local camera = game:GetService("Workspace").CurrentCamera
local mouse = player:GetMouse()

local Settings = {
    Tracer_Color = Color3.fromRGB(255, 0, 0),
    Tracer_Thickness = 1,
    Tracer_Origin = "Bottom",
    Tracer_FollowMouse = false,
    Tracers = true,
    ShowDistance = true
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

local function NewText()
    local text = Drawing.new("Text")
    text.Visible = false
    text.Text = ""
    text.Size = 24
    text.Color = Color3.new(1, 1, 1)
    text.Outline = true
    text.OutlineColor = Color3.new(1, 1, 1)
    text.Center = true
    text.Position = Vector2.new(0, 0)
    text.Transparency = 1
    return text
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
        distanceText = NewText()
    }
    
    local connection
    connection = game:GetService("RunService").RenderStepped:Connect(function()
        if not target or not target.Parent then
            Visibility(false, library)
            if connection then connection:Disconnect() end
            return
        end
        
        local rootPart = GetRootPart(target)
        local playerRoot = GetRootPart(player.Character)
        
        if rootPart and rootPart.Parent and playerRoot and playerRoot.Parent then
            local humPos, onScreen = camera:WorldToViewportPoint(rootPart.Position)
            
            if onScreen then
                local distance = (rootPart.Position - playerRoot.Position).Magnitude
                local distanceText = string.format("%.1f studs", distance)
                
                if Settings.Tracers then
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
                    
                    library.tracer.To = Vector2.new(humPos.X, humPos.Y)
                    library.blacktracer.To = Vector2.new(humPos.X, humPos.Y)
                    
                    library.tracer.Color = color or Settings.Tracer_Color
                    
                    if Settings.ShowDistance then
                        library.distanceText.Text = distanceText
                        library.distanceText.Position = Vector2.new(humPos.X, humPos.Y - 30)
                        library.distanceText.Color = color or Settings.Tracer_Color
                        library.distanceText.Size = 16
                    end
                    
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
        end,
        
        setShowDistance = function(show)
            Settings.ShowDistance = show
            if not show then
                library.distanceText.Visible = false
            end
        end,
        
        setDistanceTextSize = function(size)
            library.distanceText.Size = size
        end
    }
end
return ESPModule
