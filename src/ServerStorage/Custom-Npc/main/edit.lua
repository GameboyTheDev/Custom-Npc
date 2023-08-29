local AssetService = game:GetService("AssetService")
local InsertService = game:GetService("InsertService")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local edit = {}

local assets: Folder = script.Parent.Parent.Assets
local ui = assets.UI
local events = assets.Events

local setData: BindableEvent = events.setData
--local playAnim: RemoteFunction = assets.playAnim
local getData: BindableFunction = events.getData

local animationPackTemplate: Frame = ui.AnimationPackTemplate
local clothingPieceTemplate: GuiButton = ui.ClothingPieceTemplate
local background: Frame = ui.Background

local main = background.Main

local editFrame = main.Edit

local npcViewFrame: ViewportFrame = editFrame.NpcView
--local npcViewFrameModel: WorldModel = npcViewFrame:FindFirstChildOfClass("WorldModel")
local npcViewTitle: TextLabel = editFrame.NpcViewTitle
local selectedAnimPackLabel: TextLabel = editFrame.SelectedAnimPack
local faceIdBox: TextBox = editFrame.FaceIdBox
local design: Frame = editFrame.Design
local animations: Frame = editFrame.Animations

local currentNpcMovement = nil

local function equipFace(npc, inputtedId)
	local id = inputtedId

	--print(inputtedId)

	if string.find(id, "id=") then
		id = string.split(id, "id=")[2]
	end

	if id == "" or id == "rbxasset://textures/face.png" then
		return
	end

	local _, message = pcall(function()
		local info = MarketplaceService:GetProductInfo(tonumber(id))

		if info.AssetTypeId ~= 13 and info.AssetTypeId ~= 1 and info.AssetTypeId ~= 18 then
			error("Id invalid, make sure you are using an image, face or decal." .. info.AssetTypeId)
			return
		end
	end)

	if message then
		warn("CUSTOM NPC ERROR: " .. message)
		return
	end

	local start = "rbxthumb://type=Asset&w=768&h=432&id="
	local decalFound: Decal = npc.Head:FindFirstChildOfClass("Decal")

	if decalFound then
		decalFound:Destroy()
	end

	--print("Creating new...")

	local decal = Instance.new("Decal")
	decal.Texture = start .. id
	decal.Face = Enum.NormalId.Front
	decal.Name = "face"
	decal.Parent = npc.Head
end

function edit:updateNpcClothing(savedCharacterData, npc)
	--local npc = npcViewFrame:FindFirstChildOfClass("Model")
	local bodyColors: BodyColors = npc:FindFirstChildOfClass("BodyColors")

	if not bodyColors then
		bodyColors = Instance.new("BodyColors")
		bodyColors.Parent = npc
	end

	local function getColor(color: string)
		local split = string.split(color, ",")
		return Color3.fromRGB(tonumber(split[1]),tonumber(split[2]),tonumber(split[3]))
	end

	for name, colorData in pairs(savedCharacterData.BodyColors) do
		if name == "Head" then
			bodyColors.HeadColor3 = getColor(colorData)
		elseif name == "LeftArm" then
			bodyColors.LeftArmColor3 = getColor(colorData)
		elseif name == "RightArm" then
			bodyColors.RightArmColor3 = getColor(colorData)
		elseif name == "LeftLeg" then
			bodyColors.LeftLegColor3 = getColor(colorData)
		elseif name == "RightLeg" then
			bodyColors.RightLegColor3 = getColor(colorData)
		elseif name == "Torso" then
			bodyColors.TorsoColor3 = getColor(colorData)
		end
	end

	for _, data in pairs(savedCharacterData.Clothing) do
		if data.Type then
			if data.Type == "Shirt" then
				local shirt = Instance.new("Shirt")
				shirt.ShirtTemplate = data.ShirtId
				shirt.Parent = npc
			elseif data.Type == "Pants" then
				local pants = Instance.new("Pants")
				pants.PantsTemplate = data.PantsId
				pants.Parent = npc
			elseif data.Type == "Face" then
				--print(data)
				equipFace(npc, data.Texture)
			elseif data.Type == "Accessory" then
				-- Loads the accessory in via InsertService
				local success, clothing = pcall(function()
					return InsertService:LoadAsset(tonumber(data.AssetId)):GetChildren()[1]
				end)

				if not success then
					warn(clothing)
					return
				end

				local tempFolder = Instance.new("Folder")
				tempFolder.Name = "RigLoadingFolderCustomNpc"
				tempFolder.Parent = workspace

				local otherNpcParent = npc.Parent

				local newNpc = npc:Clone()
				newNpc.Parent = tempFolder

				local newClothing = clothing:Clone()

				newNpc.Humanoid:AddAccessory(newClothing)

				task.wait(1)

				if npc == npcViewFrame:FindFirstChildOfClass("Model") then
					newNpc.Parent = npcViewFrame

					npc:Destroy()

					npc = newNpc
				else
					newNpc.Parent = otherNpcParent
				end

				clothing = newClothing

				tempFolder:Destroy()

				clothing:SetAttribute("AssetId", data.AssetId)
			end
		end
	end

	--print("Updated npcview")
end

function edit:npcView(savedCharacterData, viewFrame: ViewportFrame)
	if not savedCharacterData then
		return
	end

	-- Bandaid fix to use this function on other viewportframes
	if viewFrame == npcViewFrame then
		if currentNpcMovement then
			currentNpcMovement:Disconnect()
			currentNpcMovement = nil
		end
	end

	local loading = true
	local textDelay = 0.3 -- The amount of time (in seconds) between each text change

	if viewFrame.Name == npcViewFrame.Name then
		-- While the character is loading it will change the npcViewTitle's text to Loading... etc.
		task.spawn(function()
			while loading do
				npcViewTitle.Text = "Loading."
				task.wait(textDelay)
				npcViewTitle.Text = "Loading.."
				task.wait(textDelay)
				npcViewTitle.Text = "Loading..."
				task.wait(textDelay)
			end

			npcViewTitle.Text = "Npc View"
		end)
	end

	viewFrame.Visible = false

	local rigType = savedCharacterData.RigType

	local rig = assets.Characters:FindFirstChild(rigType):Clone() -- Clones a new rig
	rig.Parent = viewFrame

	local angle = 10 -- current rotation angle
	local speed = 1 -- How long it takes to do a full cycle
	local distance = 6 -- Studs
	local center = rig.PrimaryPart.Position -- the center location the camera should go around

	if #savedCharacterData.Clothing > 0 then
		edit:updateNpcClothing(savedCharacterData, rig)
	end

	local camera = Instance.new("Camera") -- Camera to view the rig
	camera.Parent = viewFrame

	viewFrame.CurrentCamera = camera -- Connects the camera to the viewportframe

	local function UpdateCamera(timeSinceLastFrame)
		angle += timeSinceLastFrame * speed -- Sets the angle
		camera.CFrame = CFrame.Angles(0, angle, 0) * CFrame.new(0, -0.2, distance) + center -- Sets the cframe
	end

	currentNpcMovement = RunService:BindToRenderStep("UpdateCamera", Enum.RenderPriority.Camera.Value + 1, UpdateCamera)

	viewFrame.Visible = true
	loading = false

	return rig
end

function cleanUpNpcView()
	for _, v in pairs(npcViewFrame:GetChildren()) do
		if not v:IsA("UICorner") then
			v:Destroy()
		end
	end

	--print("NpcViewFrame cleaned")
end

-- This gets all of the instances the npc is wearing and compiles it into a table
--Args: self: plugin (Only needed if editName is false)
function edit:compileCharacter(editName)
	local npc: Model = npcViewFrame:FindFirstChildOfClass("Model")
	local characterData = { Clothing = {}, BodyColors = {}, currentAnimPack = "" }

	local data = getData:Invoke()

	if data["TEMPDATA"] then
		characterData = data["TEMPDATA"]
		data["TEMPDATA"] = nil
	end

	local characterName

	for _, v in pairs(npc:GetDescendants()) do
		if v:IsA("Shirt") then
			table.insert(characterData.Clothing, { Type = "Shirt", ShirtId = v.ShirtTemplate })
		elseif v:IsA("Pants") then
			table.insert(characterData.Clothing, { Type = "Pants", PantsId = v.PantsTemplate })
		elseif v:IsA("Accessory") then
			table.insert(characterData.Clothing, { Type = "Accessory", AssetId = v:GetAttribute("AssetId") })
		elseif v:IsA("Decal") and v.Parent == npc.Head then
			local texture = v.Texture

			if string.find(texture, "id=") then
				-- Because we are grabbing the decal's texture which doesn't return just the id
				texture = string.split(v.Texture, "id=")[2]
			end

			table.insert(characterData.Clothing, { Type = "Face", Texture = texture })
		end
	end

	if not editName then
		characterName = require(script.Parent.popup).editNamePopup(self, true, nil, characterData)
	end

	characterData.RigType = npc.Name

	--print("Compiled: ", characterData)

	--table.insert(characterData, { RigType = npc.Name })

	return characterName, characterData
end

local designConnections = {}

-- This initiates the design frame
function edit:design(savedCharacterData)
	-- Here we are setting the design frames buttons up
	for _, clothingFrame: Frame in pairs(design:GetChildren()) do
		if clothingFrame:IsA("Frame") then
			local list: ScrollingFrame = clothingFrame.List

			for _, data in pairs(savedCharacterData.Clothing) do
				if data.Type == clothingFrame:GetAttribute("CustomizationType") then
					local id

					if data.Type == "Shirt" then
						id = data.ShirtId
					elseif data.Type == "Pants" then
						id = data.PantsId
					elseif data.Type == "Accessory" then
						id = data.AssetId
					end

					local success, name = pcall(function()
						if string.find(id, "=") then
							local idNum = tonumber(string.split(id, "=")[2])
							return MarketplaceService:GetProductInfo(idNum, Enum.InfoType.Asset).Name
						else
							return MarketplaceService:GetProductInfo(tonumber(id), Enum.InfoType.Asset).Name
						end
					end)

					if not success then
						warn(
							"CUSTOM NPC ERROR: Name of "
								.. id
								.. " could not be retrieved, setting name of button to the asset id instead."
						)
						name = id
					end

					local clothingPieceButton: GuiButton = clothingPieceTemplate:Clone()
					clothingPieceButton.Text = tostring(name)
					clothingPieceButton.Parent = list

					designConnections[clothingFrame.Name .. clothingPieceButton.Text .. "ButtonClick"] = clothingPieceButton.MouseButton1Click:Connect(
						function()
							clothingPieceButton:Destroy()
						end
					)

					designConnections[clothingFrame.Name .. clothingPieceButton.Text .. "ButtonClick"] = clothingPieceButton.MouseButton1Click:Connect(
						function()
							for _, v in pairs(npcViewFrame:FindFirstChildOfClass("Model"):GetChildren()) do
								if v.ClassName == clothingFrame:GetAttribute("CustomizationType") then
									if v:IsA("Shirt") then
										if v.ShirtTemplate == id then
											v:Destroy()
											break
										end
									elseif v:IsA("Pants") then
										if v.PantsTemplate == id then
											v:Destroy()
											break
										end
									elseif v:IsA("Accessory") then
										if v:GetAttribute("AssetId") == id then
											v:Destroy()
											break
										end
									end
								end
							end

							clothingPieceButton:Destroy()
						end
					)
				elseif data.Type == "Face" then
					--local id = string.split(data.Texture,"=")[2]

					if data.Texture and data.Texture ~= "rbxasset://textures/face.png" then
						faceIdBox.Text = data.Texture
					end
				end
			end
		end
	end

	local npc: Model = npcViewFrame:FindFirstChildOfClass("Model")

	--print("Loaded")

	-- Connecting the faceIdBox to a FocusLost event so that when the user presses enter it changes the npc's face
	designConnections["faceIdBox"] = faceIdBox.FocusLost:Connect(function(enterPressed)
		if not enterPressed then
			return
		end

		equipFace(npc, faceIdBox.Text)
	end)

	--print("Connecting...")

	-- Here we are detecing the user's input if they add in a new piece of clothing etc.
	for _, clothingFrame: Frame in pairs(design:GetChildren()) do
		if clothingFrame:IsA("Frame") then
			local list: ScrollingFrame = clothingFrame:FindFirstChild("List")
			local add: TextButton = clothingFrame:FindFirstChild("Add")
			local input: TextBox = clothingFrame:FindFirstChild("Input")

			designConnections[clothingFrame.Name .. "addClick"] = add.MouseButton1Click:Connect(function()
				local text = input.Text

				--[[
				if clothingFrame:GetAttribute("CustomizationType") == "shirt" then

				elseif clothingFrame:GetAttribute("CustomizationType") == "pants" then
					local pants = Instance.new("Pants")
					pants.PantsTemplate = text
					pants.Parent = npc
				elseif clothingFrame:GetAttribute("CustomizationType") == "accessory" then
					-- Loads the accessory in via InsertService
					local accessory: Accessory = InsertService:LoadAsset(text):FindFirstChildOfClass("Accessory")

					npc:FindFirstChildOfClass("Humanoid"):AddAccessory(accessory)

					accessory:SetAttribute("AssetId", text)
				end
				--]]

				local successfullyLoadedAsset, clothing = pcall(function()
					return InsertService:LoadAsset(tonumber(text)):GetChildren()[1]
				end)

				if not successfullyLoadedAsset then
					warn(clothing)
					return
				end

				if clothing.ClassName ~= clothingFrame:GetAttribute("CustomizationType") then
					warn("CUSTOM NPC ERROR: Pairing clothing asset in wrong section.")
					input.Text = ""
					return
				end

				if clothingFrame:GetAttribute("CustomizationType") == "Accessory" then
					local tempFolder = Instance.new("Folder")
					tempFolder.Name = "RigLoadingFolderCustomNpc"
					tempFolder.Parent = workspace

					-- We have to parent the npc to workspace and than equip the accessory because it we can't just equip the accessory when the npc is in the viewportframe
					local newNpc = npc:Clone()
					newNpc.Parent = tempFolder

					local newClothing = clothing:Clone()

					newNpc.Humanoid:AddAccessory(newClothing)

					task.wait(1) -- Small delay so that the accessory can be fully put on the npc

					newNpc.Parent = npcViewFrame -- Putting it back in the viewportframe

					-- Destroying the npc and setting the new npc to one we cloned above
					npc:Destroy()

					clothing = newClothing
					npc = newNpc

					tempFolder:Destroy()

					clothing:SetAttribute("AssetId", text) -- Setting the asset id because you can't get the asset id of an accessory from the accessory instance itself
				else
					clothing.Parent = npc -- If the clothing is not an accessory then just parent the clothing to the npc
				end

				-- Wrapped in a pcall so that the script doesn't crash if an error occurs
				local successfullyGottenName, name = pcall(function()
					-- Returns the name of the clothing so that the clothingPieceButton's text is the name of the clothing
					return MarketplaceService:GetProductInfo(tonumber(text), Enum.InfoType.Asset).Name
				end)

				-- If something bad happend it warns the user and sets the text to the clothing's asset id instead
				if not successfullyGottenName then
					warn(
						"CUSTOM NPC ERROR: Name of "
							.. text
							.. " could not be retrieved, setting name of button to the asset id instead."
					)
					name = text
				end

				local clothingPieceButton: GuiButton = clothingPieceTemplate:Clone()
				clothingPieceButton.Text = tostring(name)
				clothingPieceButton.Parent = list

				-- Deletes the clothing and the button itself when you click on it
				designConnections[clothingFrame.Name .. clothingPieceButton.Text .. "ButtonClick"] = clothingPieceButton.MouseButton1Click:Connect(
					function()
						clothing:Destroy()
						clothingPieceButton:Destroy()
					end
				)

				input.Text = "" -- Sets the input's (TextBox) text to blank
			end)
		end
	end

	faceIdBox.Visible = true
	design.Visible = true

	--print("Visible", design.Visible)
end

-- Cleans up the design frame (Removes connections etc.)
function edit:cleanUpDesign()
	for _, connection: RBXScriptConnection in pairs(designConnections) do
		connection:Disconnect()
	end

	for _, clothingFrame: Frame in pairs(design:GetChildren()) do
		if clothingFrame:IsA("Frame") then
			for _, button: TextButton in pairs(clothingFrame:FindFirstChild("List"):GetChildren()) do
				if button:IsA("TextButton") then
					button:Destroy()
				end
			end
		end
	end

	faceIdBox.Visible = false
	faceIdBox.Text = ""
	design.Visible = false

	--print("Design cleaned")
end

local animationPackIds = {
	356,
	56,
	82,
	667,
	43,
	75,
	80,
	81,
	83,
	63,
	32,
	48,
	34,
	79,
	68,
	33,
	55,
	39,
}

--local stop = false

local animationConnections = {}

local function animationFrame(savedCharacterName, savedCharacterData, id)
	local rigType = savedCharacterData.RigType

	local animationPackFrame: Frame = animationPackTemplate:Clone()
	local animationPackImage: ImageLabel = animationPackFrame.AssetImage
	local activateButton: TextButton = animationPackFrame.ActivateButton

	if rigType == "R15" then
		local success, assetInfo = pcall(function()
			-- Gets info on the bundle (name, assetid's etc.)
			return AssetService:GetBundleDetailsAsync(id)
		end)

		if not success then
			warn("CUSTOM NPC ERROR: " .. assetInfo)
			return
		end

		if rigType == "R15" then
			animationPackImage.Image = "rbxthumb://type=BundleThumbnail&id=" .. id .. "&w=150&h=150"

			animationPackFrame.Title.Text = assetInfo.Name
		end

		designConnections["ActivateButton" .. id] = activateButton.MouseButton1Click:Connect(function()
			--[[
			local selectedBefore = savedCharacterData.currentAnimPack
	
			if selectedBefore ~= "" then
				local frame: Frame = animations[selectedBefore]
	
				if not frame then
					warn("CUSTOM NPC ERROR: When trying to get frame returned nil")
					return
				end
	
				mouseEnter(frame, Color3.fromRGB(252, 168, 0))
				mouseLeave(frame, Color3.fromRGB(49, 49, 49))
	
				frame.BackgroundColor3 = Color3.fromRGB(173, 170, 170)
			end
	
			if animationConnections[animationPackFrame.Name .. "HoverEnd"] then
				animationConnections[animationPackFrame.Name .. "HoverEnd"]:Disconnect()
				animationConnections[animationPackFrame.Name .. "HoverStart"] = nil
			end
	
			if animationConnections[animationPackFrame.Name .. "HoverStart"] then
				animationConnections[animationPackFrame.Name .. "HoverStart"]:Disconnect()
				animationConnections[animationPackFrame.Name .. "HoverStart"] = nil
			end
	
			animationPackFrame.BackgroundColor3 = Color3.fromRGB(152, 152, 152)
			--]]

			local data = getData:Invoke()

			if data["TEMPDATA"] then
				selectedAnimPackLabel.Text = "Selected Animation Pack: None"
				data["TEMPDATA"].currentAnimPack = nil

				if #data["TEMPDATA"] <= 0 then
					data["TEMPDATA"] = nil
				end
			else
				selectedAnimPackLabel.Text = "Selected Animation Pack: " .. assetInfo.Name

				if savedCharacterName ~= "" then
					data[savedCharacterName] = savedCharacterData
					data[savedCharacterName].currentAnimPack = assetInfo.Name
				else
					-- TEMPDATA is for data that is temporarily going to be in the data but is going to be set as the savedCharacterData when its being compiled
					data["TEMPDATA"] = savedCharacterData
					data["TEMPDATA"].currentAnimPack = assetInfo.Name
				end
			end

			-- What if its a new character? How would I update savedCharacterName when it doesn't even exist

			--print("Saving data animation package")
			setData:Fire(data)
		end)

		animationPackFrame.Name = assetInfo.Name
	else
		animationPackFrame.Title.Text = "R6 Default Animation"
		animationPackImage.Image = "rbxthumb://type=BundleThumbnail&id=8246626421&w=150&h=150"

		designConnections["ActivateButtonR6Default"] = activateButton.MouseButton1Click:Connect(function()
			local data = getData:Invoke()

			if data["TEMPDATA"] then
				selectedAnimPackLabel.Text = "Selected Animation Pack: None"
				data["TEMPDATA"].currentAnimPack = nil

				if #data["TEMPDATA"] <= 0 then
					data["TEMPDATA"] = nil
				end
			else
				selectedAnimPackLabel.Text = "Selected Animation Pack: R6 Default"

				if savedCharacterName ~= "" then
					data[savedCharacterName] = savedCharacterData
					data[savedCharacterName].currentAnimPack = "R6Default"
				else
					-- TEMPDATA is for data that is temporarily going to be in the data but is going to be set as the savedCharacterData when its being compiled
					data["TEMPDATA"] = savedCharacterData
					data["TEMPDATA"].currentAnimPack = "R6Default"
				end
			end

			-- What if its a new character? How would I update savedCharacterName when it doesn't even exist

			--print("Saving data animation package")
			setData:Fire(data)
		end)

		animationPackFrame.Name = "R6Default"
	end

	local function mouseEnter(Frame, color)
		animationConnections[Frame.Name .. "HoverStart"] = Frame.MouseEnter:Connect(function()
			TweenService:Create(Frame, TweenInfo.new(0.25), { BackgroundColor3 = color }):Play()
		end)
	end

	local function mouseLeave(Frame, color)
		animationConnections[Frame.Name .. "HoverEnd"] = Frame.MouseLeave:Connect(function()
			TweenService:Create(Frame, TweenInfo.new(0.25), { BackgroundColor3 = color }):Play()
		end)
	end

	mouseEnter(animationPackFrame, Color3.fromRGB(252, 168, 0))
	mouseLeave(animationPackFrame, Color3.fromRGB(49, 49, 49))

	animationPackFrame.Parent = animations
end

function edit:animationFrame(savedCharacterName, savedCharacterData)
	--print(game:GetService("AssetService"):GetBundleDetailsAsync(356))

	-- print("Picked up")

	-- local _, savedCharacterData = edit.compileCharacter(nil, true)

	--print(savedCharacterData)

	-- stop = false

	if savedCharacterData.currentAnimPack == "" then
		selectedAnimPackLabel.Text = "Selected Animation Pack: None"
	else
		selectedAnimPackLabel.Text = "Selected Animation Pack: " .. savedCharacterData.currentAnimPack
	end

	selectedAnimPackLabel.Visible = true

	if savedCharacterData.RigType == "R15" then
		for _, id in ipairs(animationPackIds) do
			task.spawn(animationFrame, savedCharacterName, savedCharacterData, id)
		end
	else
		task.spawn(animationFrame, savedCharacterName, savedCharacterData)
	end
end

function edit:cleanUpAnimationFrame()
	--stop = true

	selectedAnimPackLabel.Text = "Selected Animation Pack: None"

	selectedAnimPackLabel.Visible = false
	animations.Visible = false

	for _, connection: RBXScriptConnection in pairs(animationConnections) do
		connection:Disconnect()
	end

	for _, frame: Frame in pairs(animations:GetChildren()) do
		if frame:IsA("Frame") then
			frame:Destroy()
		end
	end
end

local closeButtonConnections = {}

-- Opens the edit frame to edit a character
function edit.new(savedCharacterName, savedCharacterData)
	--if savedCharacterName ~= "" then
		local close: TextButton = editFrame.Close

		closeButtonConnections["closeHoverStart"] = close.MouseEnter:Connect(function()
			close.TextColor3 = Color3.fromRGB(255,0,0)
		end)

		closeButtonConnections["closeHoverEnd"] = close.MouseLeave:Connect(function()
			close.TextColor3 = Color3.fromRGB(255, 255, 255)
		end)

		closeButtonConnections["closeClick"] = close.MouseButton1Click:Connect(function()
			if background:FindFirstChild("popupFrameClone") then
				return
			end
			
			edit:cleanUp()
		end)
	--end

	require(script.Parent.barScripts):initEditFrameButtons(savedCharacterName, savedCharacterData)

	editFrame.Visible = true

	edit:npcView(savedCharacterData, npcViewFrame)
end

-- Cleans up the edit frame (Cleans up connections etc.)
function edit:cleanUp()
	for _, connection: RBXScriptConnection in pairs(closeButtonConnections) do
		connection:Disconnect()
	end

	require(script.Parent.barScripts):cleanUpEditFrame()

	edit:cleanUpDesign()

	cleanUpNpcView()

	edit:cleanUpAnimationFrame()

	local data = getData:Invoke()

	if data["TEMPDATA"] then
		data["TEMPDATA"] = nil
	end

	setData:Fire(data)

	editFrame.Close.TextColor3 = Color3.fromRGB(255, 255, 255)

	editFrame.Visible = false
end

return edit
