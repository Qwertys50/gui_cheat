local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")

local DefaultConfig = {
	color = Color3.fromRGB(255, 255, 255),
	lineThickness = 1.5,
	textSize = 13,
	showDistance = true,
	showName = true,
	showTracer = true,
	maxDistance = 3000000,
	tracerOrigin = "bottom",
	autoScaleUI = true,
	customName = nil
}

local ESPInstances = {}

local function GetPrimaryPart(model)
	if model:IsA("Model") then
		return model.PrimaryPart or model:FindFirstChildOfClass("Part") or model:FindFirstChildOfClass("MeshPart")
	else
		return model
	end
end

local function GetModelName(model, customName)
	return customName or model.Name or "Unknown"
end

local function GetUIScale(baseSize)
	local viewport = Camera.ViewportSize
	local baseResolution = 1920
	local scale = viewport.X / baseResolution
	return baseSize * scale
end

local function GetScaledScreenPos(worldPos)
	local screenPos, onScreen = Camera:WorldToScreenPoint(worldPos)
	if not onScreen then
		return nil, false
	end
	return Vector2.new(screenPos.X, screenPos.Y), true
end

local function CreateESP(model, options)
	options = options or {}
	
	if not model then
		warn("CreateESP: Model is nil")
		return nil
	end
	
	print("CreateESP: Creating ESP for", model:GetFullName())
	
	local config = {}
	
	for key, value in pairs(DefaultConfig) do
		config[key] = value
	end
	
	for key, value in pairs(options) do
		config[key] = value
	end
	
	local esp = {
		Model = model,
		Config = config,
		TracerLine = nil,
		NameText = nil,
		DistanceText = nil,
		Active = true,
	}
	
	function esp:destroy()
		self:_cleanup()
	end
	
	function esp:_cleanup()
		print("cleanup called for", self.Model and self.Model.Name or "nil")
		if self.TracerLine then
			pcall(function() self.TracerLine:Remove() end)
			self.TracerLine = nil
		end
		if self.NameText then
			pcall(function() self.NameText:Remove() end)
			self.NameText = nil
		end
		if self.DistanceText then
			pcall(function() self.DistanceText:Remove() end)
			self.DistanceText = nil
		end
		self.Active = false
		ESPInstances[self.Model] = nil
	end
	
	function esp:_hideAll()
		if self.TracerLine then self.TracerLine.Visible = false end
		if self.NameText then self.NameText.Visible = false end
		if self.DistanceText then self.DistanceText.Visible = false end
	end
	
	function esp:update()
			if not self.Active then return end
			if not self.Model or not self.Model.Parent then
				self:_cleanup()
				return
			end
			
			local primaryPart = GetPrimaryPart(self.Model)
			if not primaryPart then return end
			
			local screenPos, onScreen = GetScaledScreenPos(primaryPart.Position)
			
			if not onScreen or not screenPos then
				self:_hideAll()
				return
			end
			
			local distance = (primaryPart.Position - Camera.CFrame.Position).Magnitude
			
			if distance > self.Config.maxDistance then
				self:_hideAll()
				return
			end
			
			if self.Config.showTracer then
				if not self.TracerLine then
					self.TracerLine = Drawing.new("Line")
				end
				
				local viewportSize = Camera.ViewportSize
				
				local origin = Vector2.new(viewportSize.X / 2, viewportSize.Y)
				if self.Config.tracerOrigin == "center" then
					origin = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
				elseif self.Config.tracerOrigin == "cursor" then
					origin = UserInputService:GetMouseLocation()
				end
				
				self.TracerLine.Visible = true
				self.TracerLine.From = origin
				self.TracerLine.To = screenPos
				self.TracerLine.Color = self.Config.color
				
				local thickness = self.Config.lineThickness
				if self.Config.autoScaleUI then
					thickness = GetUIScale(self.Config.lineThickness)
				end
				
				self.TracerLine.Thickness = thickness
				self.TracerLine.Transparency = 0.7
			end
			
            if self.Config.showName then
                if not self.NameText then
                    self.NameText = Drawing.new("Text")
                else
                    self.NameText.Text = ""
                end
                
                local displayName = GetModelName(self.Model, self.Config.customName)

                self.NameText.Visible = true
                self.NameText.Text = displayName
                self.NameText.Position = Vector2.new(screenPos.X, screenPos.Y - 25)
                
                local textSize = self.Config.textSize
                if self.Config.autoScaleUI then
                    textSize = GetUIScale(self.Config.textSize)
                end
                
                self.NameText.Size = textSize
                self.NameText.Color = self.Config.color
                self.NameText.Center = true
                self.NameText.Outline = true
                self.NameText.OutlineColor = Color3.fromRGB(0, 0, 0)
                self.NameText.Transparency = 1
            end
			
			if self.Config.showDistance then
				if not self.DistanceText then
					self.DistanceText = Drawing.new("Text")
				end
				
				self.DistanceText.Visible = true
				self.DistanceText.Text = string.format("%.0f", distance) .. "s"
				self.DistanceText.Position = Vector2.new(screenPos.X, screenPos.Y + 15)
				
				local textSize = self.Config.textSize - 2
				if self.Config.autoScaleUI then
					textSize = GetUIScale(self.Config.textSize - 2)
				end
				
				self.DistanceText.Size = textSize
				self.DistanceText.Color = Color3.fromRGB(150, 150, 150)
				self.DistanceText.Center = true
				self.DistanceText.Outline = true
				self.DistanceText.OutlineColor = Color3.fromRGB(0, 0, 0)
				self.DistanceText.Transparency = 1
			end
		end
	
	function esp:setColor(color)
		self.Config.color = color
	end
	
	function esp:Change(newOptions)
		print("Change called with:", newOptions)
		for key, value in pairs(newOptions) do
			if self.Config[key] ~= nil then
				self.Config[key] = value
			end
		end
		
		if newOptions.customName and self.NameText then
			local displayName = GetModelName(self.Model, self.Config.customName)
			self.NameText.Text = displayName
		end
	end
	
	ESPInstances[model] = esp
	print("ESP created successfully:", esp) -- отладка
	return esp
end

RunService.RenderStepped:Connect(function()
	for _, esp in pairs(ESPInstances) do
		if esp.Active then
			esp:update()
		end
	end
end)

local function ClearAllESP()
	for _, esp in pairs(ESPInstances) do
		esp:_cleanup()
	end
	ESPInstances = {}
end

_G.ClearAllESP = ClearAllESP
_G.CreateESP = CreateESP
