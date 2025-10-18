local module = {}

local function create_UITextSize(max: number, min: number, parent)
	local create = Instance.new("UITextSizeConstraint", parent)
	create.MinTextSize = min
	create.MaxTextSize = max
end

local function create_UISize(max: number, parent)
	local create = Instance.new("UISizeConstraint", parent)
	create.MaxSize = Vector2.new(max, "inf")
end

local function create_UIRadio(max, parent)
	local create = Instance.new("UIAspectRatioConstraint", parent)
	create.AspectRatio = max
end

local function create_UIList(max: UDim, Horizont: Enum.HorizontalAlignment, parent)
	local create = Instance.new("UIListLayout", parent)
	create.Padding = max
	create.HorizontalAlignment = Horizont
	
	return create
end

local function create_UICorner(vec: UDim, parent)
	local create = Instance.new("UICorner", parent)
	create.CornerRadius = vec
end

local function create_UIStroke(num: num, parent)
	local create = Instance.new("UIStroke", parent)
	create.Thickness = num
end

function module.create_starter(parent)

	local frame_Frame = Instance.new("Frame")
	frame_Frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame_Frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame_Frame.BorderSizePixel = 0
	frame_Frame.ClipsDescendants = false
	frame_Frame.LayoutOrder = 0
	frame_Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame_Frame.Rotation = 0
	frame_Frame.Size = UDim2.new(0.683844, 0, 0.610638, 0)
	frame_Frame.Visible = true
	frame_Frame.Parent = parent

	local scrolling_ScrollingFrame = Instance.new("ScrollingFrame")
	scrolling_ScrollingFrame.AnchorPoint = Vector2.new(0, 0)
	scrolling_ScrollingFrame.BackgroundColor3 = Color3.new(1, 1, 1)
	scrolling_ScrollingFrame.BackgroundTransparency = 1
	scrolling_ScrollingFrame.BorderSizePixel = 0
	scrolling_ScrollingFrame.ClipsDescendants = true
	scrolling_ScrollingFrame.Position = UDim2.new(0.016293, 0, 0.045296, 0)
	scrolling_ScrollingFrame.Size = UDim2.new(0.967413, 0, 0.905923, 0)
	scrolling_ScrollingFrame.Name = "ScrollingFrame"
	scrolling_ScrollingFrame.ScrollBarImageColor3 = Color3.new(0.462745, 0.341176, 0.427451)
	scrolling_ScrollingFrame.ScrollBarThickness = 6
	scrolling_ScrollingFrame.CanvasSize = UDim2.new(0, 0, 2, 0)
	scrolling_ScrollingFrame.CanvasPosition = Vector2.new(0, 0)
	scrolling_ScrollingFrame.Parent = frame_Frame
	scrolling_ScrollingFrame.ZIndex = 2

	local FrameHome = Instance.new("Frame")
	FrameHome.BackgroundColor3 = Color3.new(1, 1, 1)
	FrameHome.BackgroundTransparency = 1
	FrameHome.BorderSizePixel = 0
	FrameHome.Position = UDim2.new(0.016293, 0, 0.045296, 0)
	FrameHome.Size = UDim2.new(0.967413, 0, 0.905923, 0)
	FrameHome.Name = "ScrollingFrame"
	FrameHome.Parent = frame_Frame
	FrameHome.Visible = false

	local frame_Frame2 = Instance.new("Frame")
	frame_Frame2.BackgroundTransparency = 1
	frame_Frame2.BorderSizePixel = 0.000000
	frame_Frame2.Position = UDim2.new(0.068, 0, 0.909, 0)
	frame_Frame2.Size = UDim2.new(0.862000, 0, 0.139798, 0)
	frame_Frame2.Transparency = 1
	frame_Frame2.Parent = frame_Frame
	frame_Frame2.ZIndex = 10

	local textbutton_Home = Instance.new("TextButton")
	textbutton_Home.BackgroundColor3 = Color3.new(0.937255, 0.937255, 0.937255)
	textbutton_Home.BorderColor3 = Color3.new(0, 0, 0)
	textbutton_Home.BorderSizePixel = 0
	textbutton_Home.Position = UDim2.new(0.030162, 0, 0.166667, 0)
	textbutton_Home.Rotation = 4.000000
	textbutton_Home.Size = UDim2.new(0.220418, 0, 0.666667, 0)
	textbutton_Home.Name = "Home"
	textbutton_Home.FontFace = Font.new("rbxasset://fonts/families/Fondamento.json", Enum.FontWeight.Regular)
	textbutton_Home.Text = "Home"
	textbutton_Home.TextColor3 = Color3.new(0, 0, 0)
	textbutton_Home.TextScaled = true
	textbutton_Home.TextStrokeColor3 = Color3.new(0.000000, 0.000000, 0.000000)
	textbutton_Home.Parent = frame_Frame2

	local textbutton_Main = Instance.new("TextButton")
	textbutton_Main.BackgroundColor3 = Color3.new(0.937255, 0.937255, 0.937255)
	textbutton_Main.BorderColor3 = Color3.new(0, 0, 0)
	textbutton_Main.BorderSizePixel = 0
	textbutton_Main.Position = UDim2.new(0.756, 0, 0.166667, 0)
	textbutton_Main.Rotation = 4.000000
	textbutton_Main.Size = UDim2.new(0.220418, 0, 0.666667, 0)
	textbutton_Main.Name = "Main"
	textbutton_Main.FontFace = Font.new("rbxasset://fonts/families/Fondamento.json", Enum.FontWeight.Regular)
	textbutton_Main.Text = "Main"
	textbutton_Main.TextColor3 = Color3.new(0, 0, 0)
	textbutton_Main.TextScaled = true
	textbutton_Main.TextStrokeColor3 = Color3.new(0.000000, 0.000000, 0.000000)
	textbutton_Main.Parent = frame_Frame2

	local uiLIst = create_UIList(UDim.new(0.001, 15), Enum.HorizontalAlignment.Center, scrolling_ScrollingFrame)
	create_UICorner(UDim.new(0, 8), frame_Frame)
	create_UISize(500, frame_Frame)
	
	uiLIst:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrolling_ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, uiLIst.AbsoluteContentSize.Y)
	end)
	
	textbutton_Home.MouseButton1Up:Connect(function()
		if not FrameHome.Visible then 
			FrameHome.Visible = true 
			scrolling_ScrollingFrame.Visible = false
		
		else
			FrameHome.Visible = false 
			scrolling_ScrollingFrame.Visible = true 
		end
		
	end)
		
	textbutton_Main.MouseButton1Up:Connect(function()
		if not scrolling_ScrollingFrame.Visible then 
			scrolling_ScrollingFrame.Visible = true 
			FrameHome.Visible = false 
		else
			scrolling_ScrollingFrame.Visible = false 
			FrameHome.Visible = true 
		end

	end)
	
	create_UIRadio(1.706, frame_Frame)

	return frame_Frame, FrameHome, scrolling_ScrollingFrame, {["Main"] = scrolling_ScrollingFrame, ["Home"] = FrameHome}, frame_Frame2
end

function module.create_home(game_name, parent)

	local textlabel_Gg = Instance.new("TextLabel")
	textlabel_Gg.BackgroundTransparency = 1
	textlabel_Gg.Position = UDim2.new(0.268873, 0, -0.055108, 0)
	textlabel_Gg.Size = UDim2.new(0.463289, 0, 0.117564, 0)
	textlabel_Gg.Transparency = 1.000000
	textlabel_Gg.Name = "Gg"
	textlabel_Gg.FontFace = Font.new("rbxasset://fonts/families/Fondamento.json", Enum.FontWeight.Regular)
	textlabel_Gg.Text = game_name
	textlabel_Gg.TextColor3 = Color3.new(0, 0, 0)
	textlabel_Gg.TextScaled = true
	textlabel_Gg.TextStrokeColor3 = Color3.new(0, 0, 0)
	textlabel_Gg.TextTransparency = 0
	textlabel_Gg.Parent = parent

	local textlabel_TextLabel = Instance.new("TextLabel")
	textlabel_TextLabel.BackgroundTransparency = 1.000000
	textlabel_TextLabel.Position = UDim2.new(0.148914, 0, 0.062456, 0)
	textlabel_TextLabel.Size = UDim2.new(0.701138, 0, 0.224105, 0)
	textlabel_TextLabel.Transparency = 1.000000
	textlabel_TextLabel.Name = "TextLabel"
	textlabel_TextLabel.FontFace = Font.new("rbxasset://fonts/families/Fondamento.json", Enum.FontWeight.Regular)
	textlabel_TextLabel.Text = "TV Scripts"
	textlabel_TextLabel.TextColor3 = Color3.new(0, 0, 0)
	textlabel_TextLabel.TextScaled = true
	textlabel_TextLabel.TextTransparency = 0
	textlabel_TextLabel.Parent = parent

	local frame_Frame = Instance.new("Frame")
	frame_Frame.BackgroundTransparency = 1
	frame_Frame.Position = UDim2.new(0.153051, 0, 0.396777, 0)
	frame_Frame.Size = UDim2.new(0.692865, 0, 0.367386, 0)
	frame_Frame.Transparency = 1
	frame_Frame.Name = "Frame"
	frame_Frame.Parent = parent


	local imagelabel_ImageLabel = Instance.new("ImageLabel")
	imagelabel_ImageLabel.BackgroundTransparency = 1
	imagelabel_ImageLabel.BorderSizePixel = 0.000000
	imagelabel_ImageLabel.Position = UDim2.new(0, 0, 0, 0)
	imagelabel_ImageLabel.Size = UDim2.new(0.298507, 0, 1.000000, 0)
	imagelabel_ImageLabel.Transparency = 1
	imagelabel_ImageLabel.ZIndex = 1.000000
	imagelabel_ImageLabel.Name = "ImageLabel"
	imagelabel_ImageLabel.Parent = frame_Frame

	local textlabel_NN = Instance.new("TextLabel")
	textlabel_NN.BackgroundTransparency = 1
	textlabel_NN.BorderSizePixel = 0.000000
	textlabel_NN.Position = UDim2.new(0.337313, 0, 0, 0)
	textlabel_NN.Size = UDim2.new(0.650746, 0, 0.51, 0)
	textlabel_NN.Transparency = 1
	textlabel_NN.Visible = true
	textlabel_NN.FontFace = Font.new("rbxasset://fonts/families/Fondamento.json", Enum.FontWeight.Regular)
	textlabel_NN.Text = "Roblox"
	textlabel_NN.TextScaled = true
	textlabel_NN.TextXAlignment = Enum.TextXAlignment.Left
	textlabel_NN.TextTransparency = 0
	textlabel_NN.Parent = frame_Frame

	local textlabel_County = Instance.new("TextLabel")
	textlabel_County.BackgroundTransparency = 1
	textlabel_County.BorderSizePixel = 0
	textlabel_County.Position = UDim2.new(0.337313, 0, 0.680000, 0)
	textlabel_County.Size = UDim2.new(0.408955, 0, 0.320000, 0)
	textlabel_County.Transparency = 1.000000
	textlabel_County.FontFace = Font.new("rbxasset://fonts/families/Fondamento.json", Enum.FontWeight.Regular)
	textlabel_County.Text = "USA"
	textlabel_County.TextScaled = true
	textlabel_County.TextTransparency = 0
	textlabel_County.TextXAlignment = Enum.TextXAlignment.Left
	textlabel_County.Parent = frame_Frame

	create_UIRadio(3.35, frame_Frame)
	create_UIRadio(4.275, textlabel_NN)
	create_UIRadio(1, imagelabel_ImageLabel)
	create_UIRadio(4.281, textlabel_County)

	return imagelabel_ImageLabel, textlabel_NN, textlabel_County
end

function module.create_num(name, parent, info_input)
	local frame_Frame = Instance.new("Frame")
	frame_Frame.AnchorPoint = Vector2.new(0, 0.5)
	frame_Frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame_Frame.BorderSizePixel = 0.000000
	frame_Frame.Position = UDim2.new(0.000000, 0, 0.037308, 0)
	frame_Frame.Size = UDim2.new(0.885140, 0, 0.074615, 0)
	frame_Frame.Name = "Frame"
	frame_Frame.Parent = parent

	local frame_Input = Instance.new("Frame")
	frame_Input.BackgroundColor3 = Color3.new(1, 1, 1)
	frame_Input.BorderSizePixel = 0.000000
	frame_Input.ClipsDescendants = false
	frame_Input.Position = UDim2.new(0.470370, 0, 0.174127, 0)
	frame_Input.Size = UDim2.new(0.280088, 0, 0.619048, 0)
	frame_Input.Transparency = 0.000000
	frame_Input.Name = "Input"
	frame_Input.Parent = frame_Frame

	local textbox_TextBox = Instance.new("TextBox")
	textbox_TextBox.AnchorPoint = Vector2.new(0, 0)
	textbox_TextBox.BackgroundColor3 = Color3.new(1, 1, 1)
	textbox_TextBox.BorderSizePixel = 0.000000
	textbox_TextBox.ClipsDescendants = false
	textbox_TextBox.Position = UDim2.new(0, 0, 0, 0)
	textbox_TextBox.Rotation = 0.000000
	textbox_TextBox.Size = UDim2.new(1, 0, 1, 0)
	textbox_TextBox.FontFace = Font.new("rbxasset://fonts/families/Fondamento.json", Enum.FontWeight.Regular)
	textbox_TextBox.Text = ""
	textbox_TextBox.TextColor3 = Color3.new(0.000000, 0.000000, 0.000000)
	textbox_TextBox.TextTransparency = 0.000000
	textbox_TextBox.TextWrapped = true
	textbox_TextBox.TextStrokeColor3 = Color3.new(0, 0, 0)
	textbox_TextBox.PlaceholderText = ""
	textbox_TextBox.PlaceholderColor3 = Color3.new(0.7, 0.7, 0.7)
	textbox_TextBox.Parent = frame_Input

	create_UITextSize(40, 20, textbox_TextBox)
	create_UICorner(UDim.new(0, 8), textbox_TextBox)

	create_UICorner(UDim.new(0, 8), frame_Input)
	create_UIStroke(2, frame_Input)

	textbox_TextBox:GetPropertyChangedSignal("Text"):Connect(function()
		textbox_TextBox.Text = textbox_TextBox.Text:gsub('%D+', '');

		local max = info_input or {max = 10}

		if string.len(textbox_TextBox.Text) > max.max then
			textbox_TextBox.Text = string.sub(textbox_TextBox.Text, 1, max.max)
		end
	end)

	local textbutton_TextButton = Instance.new("TextButton")
	textbutton_TextButton.BackgroundColor3 = Color3.new(1, 0, 0)
	textbutton_TextButton.BorderSizePixel = 2.000000
	textbutton_TextButton.Position = UDim2.new(0.897, 0,0.137, 0)
	textbutton_TextButton.Size = UDim2.new(0.066, 0, 0.64, 0)
	textbutton_TextButton.ZIndex = 1.000000
	textbutton_TextButton.Name = "TextButton"
	textbutton_TextButton.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular)
	textbutton_TextButton.Text = ""
	textbutton_TextButton.TextWrapped = true
	textbutton_TextButton.Parent = frame_Frame
	
	create_UIRadio(1.003, textbutton_TextButton)

	local textlabel_TextLabel = Instance.new("TextLabel")
	textlabel_TextLabel.BackgroundTransparency = 1
	textlabel_TextLabel.BorderSizePixel = 0.000000
	textlabel_TextLabel.Position = UDim2.new(0.02, 0, 0.27, 0)
	textlabel_TextLabel.Size = UDim2.new(0.205689, 0, 0.444444, 0)
	textlabel_TextLabel.FontFace = Font.new("rbxasset://fonts/families/Fondamento.json", Enum.FontWeight.Regular)
	textlabel_TextLabel.Text = name
	textlabel_TextLabel.TextColor3 = Color3.new(0, 0, 0)
	textlabel_TextLabel.TextWrapped = true
	textlabel_TextLabel.TextScaled = true
	textlabel_TextLabel.Parent = frame_Frame
	textlabel_TextLabel.TextXAlignment = Enum.TextXAlignment.Left

	create_UITextSize(30, 20, textlabel_TextLabel)

	return textbutton_TextButton, textbox_TextBox
end

function module.create_button(name, parent)
	
	local frame_Frame = Instance.new("Frame")
	frame_Frame.AnchorPoint = Vector2.new(0, 0.5)
	frame_Frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame_Frame.BorderSizePixel = 0.000000
	frame_Frame.Position = UDim2.new(0, 0, 0, 0)
	frame_Frame.Size = UDim2.new(0.885140, 0, 0, 45)
	frame_Frame.Name = "Frame"
	frame_Frame.Parent = parent

	local textbutton_TextButton = Instance.new("TextButton")
	textbutton_TextButton.BackgroundColor3 = Color3.new(1, 0, 0)
	textbutton_TextButton.BorderSizePixel = 2.000000
	textbutton_TextButton.Position = UDim2.new(0.897, 0,0.5, 0)
	textbutton_TextButton.Size = UDim2.new(0.066, 0,0.64, 0)
	textbutton_TextButton.ZIndex = 1.000000
	textbutton_TextButton.Name = "TextButton"
	textbutton_TextButton.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular)
	textbutton_TextButton.Text = ""
	textbutton_TextButton.TextWrapped = true
	textbutton_TextButton.Parent = frame_Frame
	textbutton_TextButton.AnchorPoint = Vector2.new(0, 0.5)
	
	create_UIRadio(1.003, textbutton_TextButton)

	local textlabel_TextLabel = Instance.new("TextLabel")
	textlabel_TextLabel.BackgroundTransparency = 1
	textlabel_TextLabel.BorderSizePixel = 0.000000
	textlabel_TextLabel.Position = UDim2.new(0.02, 0, 0.27, 0)
	textlabel_TextLabel.Size = UDim2.new(0.706, 0, 0.444444, 0)
	textlabel_TextLabel.FontFace = Font.new("rbxasset://fonts/families/Fondamento.json", Enum.FontWeight.Regular)
	textlabel_TextLabel.Text = name
	textlabel_TextLabel.TextColor3 = Color3.new(0, 0, 0)
	textlabel_TextLabel.TextWrapped = true
	textlabel_TextLabel.TextScaled = true
	textlabel_TextLabel.RichText = true
	textlabel_TextLabel.Parent = frame_Frame
	textlabel_TextLabel.TextXAlignment = Enum.TextXAlignment.Left

	create_UITextSize(30, 20, textlabel_TextLabel)

	return textbutton_TextButton
end

function module.create_vib(name_par, name_sel, all_vib, parent, size_ps)
	
	local all_vib_button = {}

	local frame_Vib = Instance.new("Frame")
	frame_Vib.AnchorPoint = Vector2.new(0, 0.5)
	frame_Vib.BackgroundColor3 = Color3.new(1, 1, 1)
	frame_Vib.BorderSizePixel = 0
	frame_Vib.ClipsDescendants = false
	frame_Vib.Position = UDim2.new(0.057430, 0, 0.113133, 0)
	frame_Vib.Size = UDim2.new(0.885, 0,0, 96)
	frame_Vib.Name = "Vib"
	frame_Vib.Parent = parent

	create_UICorner(UDim.new(0, 8), frame_Vib)

	local scrollingframe_ScrollingFrame = Instance.new("ScrollingFrame")
	scrollingframe_ScrollingFrame.BackgroundColor3 = Color3.new(1, 1, 1)
	scrollingframe_ScrollingFrame.BackgroundTransparency = 1
	scrollingframe_ScrollingFrame.BorderSizePixel = 0
	scrollingframe_ScrollingFrame.Position = UDim2.new(0.02, 0, 0.485, 0)
	scrollingframe_ScrollingFrame.Size = UDim2.new(0.96, 0, 0.417 + size_ps, 0)
	scrollingframe_ScrollingFrame.ScrollBarImageColor3 = Color3.new(0, 0, 0)
	scrollingframe_ScrollingFrame.ScrollBarThickness = 12
	scrollingframe_ScrollingFrame.CanvasSize = UDim2.new(0, 0, 2, 0)
	scrollingframe_ScrollingFrame.Parent = frame_Vib
	scrollingframe_ScrollingFrame.Visible = false
	scrollingframe_ScrollingFrame.ZIndex = 10

	create_UIList(UDim.new(0.001, 0), Enum.HorizontalAlignment.Center, scrollingframe_ScrollingFrame)

	for name1, _ in pairs(all_vib) do

		local clones = Instance.new("Frame")
		clones.BackgroundColor3 = Color3.new(0.945098, 0.945098, 0.945098)
		clones.BackgroundTransparency = 0
		clones.BorderSizePixel = 0
		clones.LayoutOrder = 0
		clones.Position = UDim2.new(0, 0, 0, 0)
		clones.Rotation = 0.000000
		clones.Size = UDim2.new(0.839, 0, 0, 29)
		clones.Name = "Frame"
		clones.Parent = scrollingframe_ScrollingFrame
		clones:SetAttribute("id", name1)

		local TextButtonClones = Instance.new("TextButton")
		TextButtonClones.BackgroundColor3 = Color3.new(0.764706, 0.764706, 0.764706)
		TextButtonClones.BorderColor3 = Color3.new(0, 0, 0)
		TextButtonClones.BorderSizePixel = 3.000000
		TextButtonClones.Position = UDim2.new(0.919118, 0, 0.147059, 0)
		TextButtonClones.Size = UDim2.new(0.058824, 0, 0.705882, 0)
		TextButtonClones.Name = "TextButton"
		TextButtonClones.Text = ""
		TextButtonClones.Parent = clones

		local TextLabelClones = Instance.new("TextLabel")
		TextLabelClones.BackgroundTransparency = 1
		TextLabelClones.BorderSizePixel = 0
		TextLabelClones.Position = UDim2.new(0.026961, 0, 0.176471, 0)
		TextLabelClones.Size = UDim2.new(0.360294, 0, 0.617647, 0)
		TextLabelClones.FontFace = Font.new("rbxasset://fonts/families/Fondamento.json", Enum.FontWeight.Regular)
		TextLabelClones.Text = name1
		TextLabelClones.TextScaled = true
		TextLabelClones.Parent = clones
		
		table.insert(all_vib_button, clones)
	end

	scrollingframe_ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, scrollingframe_ScrollingFrame.UIListLayout.AbsoluteContentSize.Y)

	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(0, 0.5)
	button.BackgroundColor3 = Color3.new(0, 0, 0)
	button.BorderSizePixel = 0
	button.Position = UDim2.new(0.02, 0, 0, 55)
	button.Size = UDim2.new(0.959, 0,0, 16)
	button.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular)
	button.Text = name_sel
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextScaled = true
	button.Parent = frame_Vib

	button.MouseButton1Up:Connect(function()
		if button.Text == "Close" then
			scrollingframe_ScrollingFrame.Visible = false
			frame_Vib.Size = UDim2.new(0.885, 0,0, 70)

			button.Size = UDim2.new(0.959, 0, 0, 16)
			button.Text = name_sel
		else

			scrollingframe_ScrollingFrame.Visible = true
			frame_Vib.Size = UDim2.new(0.885, 0,0, 140 + size_ps)

			button.Text = "Close"
			button.Size = UDim2.new(0.959, 0, 0, 16)
		end
	end)

	local textlabel_TextLabel = Instance.new("TextLabel")
	textlabel_TextLabel.BackgroundTransparency = 1
	textlabel_TextLabel.BorderSizePixel = 0.000000
	textlabel_TextLabel.Position = UDim2.new(0.019985, 0, 0, 10)
	textlabel_TextLabel.Size = UDim2.new(0.492640, 0, 0, 18)
	textlabel_TextLabel.FontFace = Font.new("rbxasset://fonts/families/Fondamento.json", Enum.FontWeight.Regular)
	textlabel_TextLabel.Text = name_par
	textlabel_TextLabel.TextScaled = true
	textlabel_TextLabel.TextXAlignment = Enum.TextXAlignment.Left
	textlabel_TextLabel.Parent = frame_Vib

	local textbutton_TextButton = Instance.new("TextButton")
	textbutton_TextButton.BackgroundColor3 = Color3.new(1, 0, 0)
	textbutton_TextButton.BorderSizePixel = 2.000000
	textbutton_TextButton.Position = UDim2.new(0.897, 0,0.1, 10)
	textbutton_TextButton.Size = UDim2.new(0.066, 0,0.32, 0)
	textbutton_TextButton.ZIndex = 1.000000
	textbutton_TextButton.Name = "TextButton"
	textbutton_TextButton.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular)
	textbutton_TextButton.Text = ""
	textbutton_TextButton.TextWrapped = true
	textbutton_TextButton.Parent = frame_Vib	
	textbutton_TextButton.AnchorPoint = Vector2.new(0, 0.5)


	create_UIRadio(1.003, textbutton_TextButton)
	return all_vib_button, textbutton_TextButton
end

return module
