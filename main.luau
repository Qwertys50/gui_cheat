local module = {}

local function create_UITextSize(max: number, min: number, parent)
	local constraint = Instance.new("UITextSizeConstraint", parent)
	constraint.MinTextSize = min
	constraint.MaxTextSize = max
end

local function create_UISize(max: number, parent)
	local constraint = Instance.new("UISizeConstraint", parent)
	constraint.MaxSize = Vector2.new(max, "inf")
end

local function create_UIRadio(aspect, parent)
	local constraint = Instance.new("UIAspectRatioConstraint", parent)
	constraint.AspectRatio = aspect
end

local function create_UIList(padding: UDim, align: Enum.HorizontalAlignment, parent)
	local list = Instance.new("UIListLayout", parent)
	list.Padding = padding
	list.HorizontalAlignment = align
	return list
end

local function create_UICorner(radius: UDim, parent)
	local corner = Instance.new("UICorner", parent)
	corner.CornerRadius = radius
end

local function create_UIStroke(thickness, parent)
	local stroke = Instance.new("UIStroke", parent)
	stroke.Thickness = thickness
end

local function CreateFrame(parent)
	local frame = Instance.new("Frame", parent)
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	return frame
end

local function CreateButton(frame)
	local btn = Instance.new("TextButton", frame)
	btn.BorderSizePixel = 0
	btn.BackgroundColor3 = Color3.new(1, 1, 1)
	pcall(function()
		btn.FontFace = Font.fromId(12187375716, Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	end)
	
	btn.TextSize = 14
	return btn
end

local function CreateTextLabel(parent)
	local lbl = Instance.new("TextLabel", parent)
	lbl.BorderSizePixel = 0
	lbl.BackgroundTransparency = 1
	lbl.BackgroundColor3 = Color3.new(1, 1, 1)
	lbl.TextColor3 = Color3.new(0, 0, 0)
	lbl.TextSize = 14
	lbl.FontFace = Font.fromId(12187375716, Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	return lbl
end

local function CreateTextBox(parent)
	local lbl = Instance.new("TextBox", parent)
	lbl.BorderSizePixel = 0
	lbl.BackgroundTransparency = 1
	lbl.BackgroundColor3 = Color3.new(1, 1, 1)
	lbl.TextColor3 = Color3.new(0, 0, 0)
	lbl.TextSize = 14
	lbl.FontFace = Font.fromId(12187375716, Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	return lbl
end

local function CreateScrollFrame(name: string, parent, hasList: boolean?)
	local frame = Instance.new("ScrollingFrame")
	frame.Name = name
	frame.Parent = parent
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.ClipsDescendants = true
	frame.ScrollBarThickness = 6
	frame.ScrollBarImageColor3 = Color3.new(0.462745, 0.341176, 0.427451)
	frame.CanvasSize = UDim2.new(0, 0, 2, 0)

	if hasList then
		local list = create_UIList(UDim.new(0.001, 15), Enum.HorizontalAlignment.Center, frame)
		list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			frame.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y)
		end)
	end

	return frame
end

local function CreateMainContainer(parent, size, position)
	local frame = CreateFrame(parent)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = position or UDim2.new(0.5, 0, 0.5, 0)
	frame.Size = size or UDim2.new(0.683844, 0, 0.610638, 0)
	return frame
end

local function createAssetButton(frame, is_enable)
	local btn = CreateButton(frame)
	btn.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
	btn.TextTransparency = 1
	btn.AutoButtonColor = false
	btn.Size = UDim2.new(0, 56, 0, 28)

	local isOn = is_enable
	local indicator = CreateFrame(btn)
	indicator.Size = UDim2.new(0.5, 0, 1, 0)
	indicator.Position = UDim2.new(0, 0, 0, 0)
	indicator.BackgroundColor3 = Color3.fromRGB(227, 21, 21)
	
	if is_enable then
		
		indicator.Position = UDim2.new(0.5, 0, 0, 0)
		indicator.BackgroundColor3 = Color3.fromRGB(56, 182, 18)
	end

	create_UICorner(UDim.new(0, 3), btn)
	create_UICorner(UDim.new(0, 3), indicator)

	btn.MouseButton1Up:Connect(function()
		isOn = not isOn
		local pos = isOn and UDim2.new(0.5, 0, 0, 0) or UDim2.new(0, 0, 0, 0)
		indicator:TweenPosition(pos, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
		indicator.BackgroundColor3 = isOn and Color3.fromRGB(56, 182, 18) or Color3.fromRGB(227, 21, 21)
	end)

	return btn
end

local function createAsseVibButton(frame)
	local btn = CreateButton(frame)
	btn.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
	btn.TextTransparency = 1
	btn.AutoButtonColor = false
	btn.Size = UDim2.new(0, 21, 0, 21)

	local indicator = CreateFrame(btn)
	indicator.Size = UDim2.new(1, 0, 1, 0)
	indicator.Position = UDim2.new(0, 0, 0, 0)
	indicator.BackgroundColor3 = Color3.fromRGB(227, 21, 21)

	create_UICorner(UDim.new(0, 3), btn)
	create_UICorner(UDim.new(0, 3), indicator)

	return btn
end

function module.create_starter(parent)
	local mainFrame = CreateMainContainer(parent)
	create_UICorner(UDim.new(0, 8), mainFrame)
	create_UISize(500, mainFrame)
	create_UIRadio(1.706, mainFrame)

	local scrollFrame = CreateScrollFrame("ScrollingFrame", mainFrame, true)
	scrollFrame.Position = UDim2.new(0.016293, 0, 0.045296, 0)
	scrollFrame.Size = UDim2.new(0.967413, 0, 0.905923, 0)

	local homeFrame = CreateFrame(mainFrame)
	homeFrame.BackgroundTransparency = 1
	homeFrame.Position = UDim2.new(0.016293, 0, 0.045296, 0)
	homeFrame.Size = UDim2.new(0.967413, 0, 0.905923, 0)
	homeFrame.Name = "HomeFrame"
	homeFrame.Visible = false

	local navBar = CreateFrame(mainFrame)
	navBar.BackgroundTransparency = 1
	navBar.Position = UDim2.new(0.068, 0, 0.909, 0)
	navBar.Size = UDim2.new(0.862000, 0, 0.139798, 0)
	navBar.ZIndex = 10

	local homeBtn = CreateButton(navBar)
	local mainBtn = CreateButton(navBar)

	homeBtn.BackgroundColor3 = Color3.new(0.937255, 0.937255, 0.937255)
	homeBtn.Position = UDim2.new(0.030162, 0, 0.166667, 0)
	homeBtn.Rotation = 4
	homeBtn.Size = UDim2.new(0.220418, 0, 0.666667, 0)
	homeBtn.Text = "Home"
	homeBtn.TextScaled = true

	mainBtn.BackgroundColor3 = Color3.new(0.937255, 0.937255, 0.937255)
	mainBtn.Position = UDim2.new(0.756, 0, 0.166667, 0)
	mainBtn.Rotation = 4
	mainBtn.Size = UDim2.new(0.220418, 0, 0.666667, 0)
	mainBtn.Text = "Main"
	mainBtn.TextScaled = true

	homeBtn.MouseButton1Up:Connect(function()
		if not homeFrame.Visible then 
			homeFrame.Visible = true 
			scrollFrame.Visible = false
		else
			homeFrame.Visible = false 
			scrollFrame.Visible = true 
		end
	end)

	mainBtn.MouseButton1Up:Connect(function()
		if not scrollFrame.Visible then 
			scrollFrame.Visible = true 
			homeFrame.Visible = false 
		else
			scrollFrame.Visible = false 
			homeFrame.Visible = true 
		end
	end)

	return mainFrame, homeFrame, scrollFrame, {Main = scrollFrame, Home = homeFrame}, navBar
end

function module.create_home(game_name, parent)
	local title = CreateTextLabel(parent)
	title.Position = UDim2.new(0.268873, 0, -0.055108, 0)
	title.Size = UDim2.new(0.463289, 0, 0.117564, 0)
	title.Text = game_name
	title.TextScaled = true

	local subtitle = CreateTextLabel(parent)
	subtitle.Position = UDim2.new(0.148914, 0, 0.062456, 0)
	subtitle.Size = UDim2.new(0.701138, 0, 0.224105, 0)
	subtitle.Text = "TV Scripts"
	subtitle.TextScaled = true

	local container = CreateFrame(parent)
	container.Position = UDim2.new(0.153051, 0, 0.396777, 0)
	container.Size = UDim2.new(0.692865, 0, 0.367386, 0)
	container.BackgroundTransparency = 1

	local img = Instance.new("ImageLabel", container)
	img.BackgroundTransparency = 1
	img.Size = UDim2.new(0.298507, 0, 1, 0)

	local robloxTxt = CreateTextLabel(container)
	robloxTxt.Position = UDim2.new(0.337313, 0, 0, 0)
	robloxTxt.Size = UDim2.new(0.650746, 0, 0.51, 0)
	robloxTxt.Text = "Roblox"
	robloxTxt.TextScaled = true
	robloxTxt.TextXAlignment = Enum.TextXAlignment.Left

	local countryTxt = CreateTextLabel(container)
	countryTxt.Position = UDim2.new(0.337313, 0, 0.680000, 0)
	countryTxt.Size = UDim2.new(0.408955, 0, 0.320000, 0)
	countryTxt.Text = "USA"
	countryTxt.TextScaled = true
	countryTxt.TextXAlignment = Enum.TextXAlignment.Left

	create_UIRadio(3.35, container)
	create_UIRadio(4.275, robloxTxt)
	create_UIRadio(1, img)
	create_UIRadio(4.281, countryTxt)

	return img, robloxTxt, countryTxt
end

function module.create_num(name, parent, info_input)
	local frame = CreateFrame(parent)
	frame.AnchorPoint = Vector2.new(0, 0.5)
	frame.Position = UDim2.new(0, 0, 0.037308, 0)
	frame.Size = UDim2.new(0.885140, 0, 0.074615, 0)

	local inputContainer = CreateFrame(frame)
	inputContainer.Position = UDim2.new(0.470370, 0, 0.174127, 0)
	inputContainer.Size = UDim2.new(0.280088, 0, 0.619048, 0)

	create_UICorner(UDim.new(0, 8), inputContainer)
	create_UIStroke(2, inputContainer)

	local textbox = Instance.new("TextBox", inputContainer)
	textbox.Size = UDim2.new(1, 0, 1, 0)
	textbox.BackgroundColor3 = Color3.new(1, 1, 1)
	textbox.BorderSizePixel = 0
	textbox.FontFace = Font.new("rbxasset://fonts/families/Fondamento.json")
	textbox.TextColor3 = Color3.new(0, 0, 0)
	textbox.TextWrapped = true

	create_UITextSize(40, 20, textbox)
	create_UICorner(UDim.new(0, 8), textbox)

	local maxLen = (info_input or {max = 10}).max
	textbox:GetPropertyChangedSignal("Text"):Connect(function()
		textbox.Text = textbox.Text:gsub('%D+', '')
		if #textbox.Text > maxLen then
			textbox.Text = string.sub(textbox.Text, 1, maxLen)
		end
	end)

	local clearBtn = Instance.new("TextButton", frame)
	clearBtn.Position = UDim2.new(0.897, 0, 0.137, 0)
	clearBtn.Size = UDim2.new(0.066, 0, 0.64, 0)
	clearBtn.BackgroundColor3 = Color3.new(1, 0, 0)
	clearBtn.Text = ""

	create_UIRadio(1.003, clearBtn)

	local label = CreateTextLabel(frame)
	label.Position = UDim2.new(0.02, 0, 0.27, 0)
	label.Size = UDim2.new(0.706, 0, 0.444444, 0)
	label.Text = name
	label.TextScaled = true
	label.RichText = true
	label.TextXAlignment = Enum.TextXAlignment.Left

	create_UITextSize(30, 20, label)

	return clearBtn, textbox
end

function module.create_button(name, frame, is_enable)
	local container = CreateFrame(frame)
	container.AnchorPoint = Vector2.new(0, 0.5)
	container.Transparency = 1
	container.Size = UDim2.new(0.885140, 0, 0, 45)

	local btn = createAssetButton(container, is_enable)
	btn.Position = UDim2.new(0.85, 0, 0.5, 0)
	btn.AnchorPoint = Vector2.new(0, 0.5)

	local label = CreateTextLabel(container)
	label.Position = UDim2.new(0.02, 0, 0.27, 0)
	label.Size = UDim2.new(0.706, 0, 0.444444, 0)
	label.Text = name
	label.TextScaled = true
	label.RichText = true
	label.TextXAlignment = Enum.TextXAlignment.Left

	return btn
end

function module.create_button2(name, frame, is_enable)
	local container = CreateFrame(frame)
	container.AnchorPoint = Vector2.new(0, 0.5)
	container.Transparency = 1
	container.Size = UDim2.new(0.885140, 0, 0, 45)

	local btn = createAsseVibButton(container)
	btn.Position = UDim2.new(0.85, 0, 0.5, 0)
	btn.AnchorPoint = Vector2.new(0, 0.5)

	local label = CreateTextLabel(container)
	label.Position = UDim2.new(0.02, 0, 0.27, 0)
	label.Size = UDim2.new(0.706, 0, 0.444444, 0)
	label.Text = name
	label.TextScaled = true
	label.RichText = true
	label.TextXAlignment = Enum.TextXAlignment.Left

	return btn
end

function module.create_text_button(name, frame, is_enable, is_num)
	local container = CreateFrame(frame)
	container.AnchorPoint = Vector2.new(0, 0.5)
	container.Transparency = 1
	container.Size = UDim2.new(0.885140, 0, 0, 45)

	local input = CreateTextBox(container)
	input.Position = UDim2.new(0.350000024, 0, 0.5, 0)
	input.AnchorPoint = Vector2.new(0, 0.5)
	input.Size = UDim2.new(0.5, 0, 0.6, 0)
	input.Text = ""
	input.PlaceholderText = is_num and "Введите число..." or "Введите текст..."
	input.ClearTextOnFocus = false
	
	local input_event = Instance.new("BindableEvent")
	
	-- Функция проверки и отправки значения
	local function validateAndFire(text)
		if is_num then
			local num = tonumber(text)
			if num then
				input_event:Fire(num)
				input.BackgroundColor = Color3.new(1, 1, 1)
			else
				input.BackgroundColor = Color3.new(1, 0.239215, 0.239215)
			end
		else
			input_event:Fire(text)
		end
	end
	
	input.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			validateAndFire(input.Text)
		end
	end)
	
	input.Changed:Connect(function(property)
		if property == "Text" and is_num then
			input.BackgroundColor = Color3.new(1, 1, 1)
		end
	end)

	local btn = createAssetButton(container, is_enable)
	btn.Position = UDim2.new(0.85, 0, 0.5, 0)
	btn.AnchorPoint = Vector2.new(0, 0.5)

	local label = CreateTextLabel(container)
	label.Position = UDim2.new(0.02, 0, 0.5, 0)
	label.Size = UDim2.new(0.706, 0, 0.3, 0)
	label.AnchorPoint = Vector2.new(0, 0.5)
	label.Text = name
	label.TextScaled = true
	label.RichText = true
	label.TextXAlignment = Enum.TextXAlignment.Left

	return btn, input_event
end

function module.create_texts_button_click(name_par, name_sel, all_vib, parent, size_ps, is_num)

	local events = {}

	local vibs = {}
	local container = CreateFrame(parent)
	container.AnchorPoint = Vector2.new(0, 0.5)
	container.Position = UDim2.new(0.057430, 0, 0.113133, 0)
	container.Size = UDim2.new(0.885, 0, 0, 96)

	create_UICorner(UDim.new(0, 8), container)

	local scrollFrame = CreateScrollFrame("VibScroller", container)
	scrollFrame.Position = UDim2.new(0.02, 0, 0.485, 0)
	scrollFrame.Size = UDim2.new(0.96, 0, 0.417 + size_ps, 0)
	scrollFrame.Visible = false
	scrollFrame.ZIndex = 10
	scrollFrame.ScrollBarThickness = 12

	create_UIList(UDim.new(0.001, 0), Enum.HorizontalAlignment.Center, scrollFrame)

	for name, _ in pairs(all_vib) do
		local item = CreateFrame(scrollFrame)
		item.Size = UDim2.new(0.839, 0, 0, 29)
		item.BackgroundColor3 = Color3.new(0.945098, 0.945098, 0.945098)
		item:SetAttribute("id", name)

		local box = CreateTextBox(item)
		box.Position = UDim2.new(0.919118, 0, 0.147059, 0)

		local input_event = Instance.new("BindableEvent")
		events[name] = input_event
			
		local function validateAndFire(text)
			if is_num then
				local num = tonumber(text)
				if num then
					input_event:Fire(num)
					box.BackgroundColor = Color3.new(1, 1, 1)
				else
					box.BackgroundColor = Color3.new(1, 0.239215, 0.239215)
				end
			else
				input_event:Fire(text)
			end
		end
		
		box.FocusLost:Connect(function(enterPressed)
			if enterPressed then
				validateAndFire(box.Text)
			end
		end)
		

		local label = CreateTextLabel(item)
		label.Position = UDim2.new(0.026961, 0, 0.176471, 0)
		label.Size = UDim2.new(0.360294, 0, 0.617647, 0)
		label.Text = name
		label.TextScaled = true

		table.insert(vibs, item)
	end

	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollFrame.UIListLayout.AbsoluteContentSize.Y)

	local toggleBtn = Instance.new("TextButton", container)
	toggleBtn.AnchorPoint = Vector2.new(0, 0.5)
	toggleBtn.Position = UDim2.new(0.02, 0, 0, 55)
	toggleBtn.Size = UDim2.new(0.959, 0, 0, 16)
	toggleBtn.BackgroundColor3 = Color3.new(0, 0, 0)
	toggleBtn.Text = name_sel
	toggleBtn.TextColor3 = Color3.new(1, 1, 1)
	toggleBtn.TextScaled = true

	toggleBtn.MouseButton1Up:Connect(function()
		local isOpen = toggleBtn.Text ~= name_sel
		scrollFrame.Visible = not isOpen
		container.Size = UDim2.new(0.885, 0, 0, isOpen and 70 or 140 + size_ps)
		toggleBtn.Text = isOpen and name_sel or "Close"
	end)
	
	local title = CreateTextLabel(container)
	title.Position = UDim2.new(0.019985, 0, 0, 10)
	title.Size = UDim2.new(0.492640, 0, 0, 18)
	title.Text = name_par
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left

	local mainBtn = createAsseVibButton(container)
	mainBtn.Position = UDim2.new(0.85, 0, 0, 20)
	mainBtn.AnchorPoint = Vector2.new(0, 0.5)

	return vibs, mainBtn, events
end


function module.create_vib(name_par, name_sel, all_vib, parent, size_ps, is_enable, vib_, color_)
	local vibs = {}
	local container = CreateFrame(parent)
	container.AnchorPoint = Vector2.new(0, 0.5)
	container.Position = UDim2.new(0.057430, 0, 0.113133, 0)
	container.Size = UDim2.new(0.885, 0, 0, 96)

	create_UICorner(UDim.new(0, 8), container)

	local scrollFrame = CreateScrollFrame("VibScroller", container)
	scrollFrame.Position = UDim2.new(0.02, 0, 0.485, 0)
	scrollFrame.Size = UDim2.new(0.96, 0, 0.417 + size_ps, 0)
	scrollFrame.Visible = false
	scrollFrame.ZIndex = 10
	scrollFrame.ScrollBarThickness = 12

	create_UIList(UDim.new(0.001, 0), Enum.HorizontalAlignment.Center, scrollFrame)

	for name, _ in pairs(all_vib) do
		local item = CreateFrame(scrollFrame)
		item.Size = UDim2.new(0.839, 0, 0, 29)
		item.BackgroundColor3 = Color3.new(0.945098, 0.945098, 0.945098)
		item:SetAttribute("id", name)

		local btn = createAsseVibButton(item)
		btn.Position = UDim2.new(0.919118, 0, 0.147059, 0)
		
		if vib_[name] then
			
			btn.Frame.BackgroundColor3 = color_
		else
			btn.Frame.BackgroundColor3 = Color3.new(0.764706, 0.764706, 0.764706)
		end

		local label = CreateTextLabel(item)
		label.Position = UDim2.new(0.026961, 0, 0.176471, 0)
		label.Size = UDim2.new(0.360294, 0, 0.617647, 0)
		label.Text = name
		label.TextScaled = true

		table.insert(vibs, item)
	end

	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollFrame.UIListLayout.AbsoluteContentSize.Y)

	local toggleBtn = Instance.new("TextButton", container)
	toggleBtn.AnchorPoint = Vector2.new(0, 0.5)
	toggleBtn.Position = UDim2.new(0.02, 0, 0, 55)
	toggleBtn.Size = UDim2.new(0.959, 0, 0, 16)
	toggleBtn.BackgroundColor3 = Color3.new(0, 0, 0)
	toggleBtn.Text = name_sel
	toggleBtn.TextColor3 = Color3.new(1, 1, 1)
	toggleBtn.TextScaled = true

	toggleBtn.MouseButton1Up:Connect(function()
		local isOpen = toggleBtn.Text ~= name_sel
		scrollFrame.Visible = not isOpen
		container.Size = UDim2.new(0.885, 0, 0, isOpen and 70 or 140 + size_ps)
		toggleBtn.Text = isOpen and name_sel or "Close"
	end)

	local title = CreateTextLabel(container)
	title.Position = UDim2.new(0.019985, 0, 0, 10)
	title.Size = UDim2.new(0.492640, 0, 0, 18)
	title.Text = name_par
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left

	local mainBtn = createAssetButton(container, is_enable)
	mainBtn.Position = UDim2.new(0.85, 0, 0, 20)
	mainBtn.AnchorPoint = Vector2.new(0, 0.5)

	return vibs, mainBtn
end

return module
