local AssetService = game:GetService("AssetService")
local InsertService = game:GetService("InsertService")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local edit = {}

local assets: Folder & any = script.Parent.Parent.Assets
local ui = assets.UI
local events = assets.Events

local setData: BindableEvent = events.setData
--local playAnim: RemoteFunction = assets.playAnim
local getData: BindableFunction = events.getData

local animationPackTemplate: Frame = ui.AnimationPackTemplate
local clothingPieceTemplate: TextButton = ui.ClothingPieceTemplate
local background: Frame & any = ui.Background

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

-- local function splitFunction(split)
-- 	if #split ~= 3 then
-- 		warn("split is not 3")
-- 		return
-- 	end
-- 	if
-- 		tonumber(split[1]) >= 0
-- 		and tonumber(split[1]) <= 1
-- 		and tonumber(split[2]) >= 0
-- 		and tonumber(split[2]) <= 1
-- 		and tonumber(split[3]) >= 0
-- 		and tonumber(split[3]) <= 1
-- 	then
-- 		local transfer = Color3.new(tonumber(split[1]), tonumber(split[2]), tonumber(split[3])):ToHex()

-- 		if transfer then
-- 			return transfer, "Color3ToHex"
-- 		end
-- 	end

-- 	if
-- 		tonumber(split[1]) >= 0
-- 		and tonumber(split[1]) <= 255
-- 		and tonumber(split[2]) >= 0
-- 		and tonumber(split[2]) <= 255
-- 		and tonumber(split[3]) >= 0
-- 		and tonumber(split[3]) <= 255
-- 	then
-- 		local transfer = Color3.fromRGB(tonumber(split[1]), tonumber(split[2]), tonumber(split[3])):ToHex()

-- 		if transfer then
-- 			return transfer, "RGBToHex"
-- 		end
-- 	end
-- end

--local clothingIdStart = "rbxassetid://" --"http://www.roblox.com/asset/?id="

local function color3torgb(color3)
	--if color3.R > 0 and color3.R < 1 then
	return color3.R * 255, color3.G * 255, color3.B * 255
	-- else
	-- 	warn(color3, "Is not a color3 value")
	-- 	return color3
	-- end
end

local default = Color3.fromRGB(127, 127, 127)

function edit:updateNpcClothing(savedCharacterData, npc, onlyUpdateColors)
	--local npc = npcViewFrame:FindFirstChildOfClass("Model")
	local bodyColors = npc:FindFirstChildOfClass("BodyColors")

	if not bodyColors then
		bodyColors = Instance.new("BodyColors")
		bodyColors.Parent = npc

		bodyColors.HeadColor3 = default
		bodyColors.TorsoColor3 = default
		bodyColors.LeftArmColor3 = default
		bodyColors.RightArmColor3 = default
		bodyColors.LeftLegColor3 = default
		bodyColors.RightLegColor3 = default

		--print("New BodyColors created")
	end

	--[[
	local function to_hex(color: Color3): string
		return string.format("#%02X%02X%02X", color.R * 0xFF, color.G * 0xFF, color.B * 0xFF)
	end

	local function from_hex(hex: string): Color3
		local r, g, b = string.match(hex, "^#?(%w%w)(%w%w)(%w%w)$")
		return Color3.fromRGB(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16))
	end

	local function getColor(color: string)
		local split = string.split(color, ",")
		return Color3.fromRGB(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
	end

	local function test(colorData)
		local stringed = tostring(colorData)
		local split = string.split(stringed, ",")

		if #split == 3 then
			--return getColor(colorData)

			local to = to_hex(Color3.fromRGB(colorData))
			return from_hex(to)
		else
			return from_hex(stringed)
		end

		-- if type(colorData) == "string" then
		-- 	return from_hex(colorData)
		-- elseif typeof(colorData) == "Color3" then
		-- 	return getColor(colorData)
		-- end
	end
	--]]

	for name, colorData in pairs(savedCharacterData.BodyColors) do
		--print(name, colorData, savedCharacterData, onlyUpdateColors)
		if name == "Head" then
			if onlyUpdateColors and typeof(colorData) == "string" then
				local split = string.split(colorData, ",")
				bodyColors.HeadColor3 = Color3.fromRGB(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
			elseif typeof(colorData) == "string" then
				local split = string.split(colorData, ",")

				if tonumber(split[1]) >= 0 and tonumber(split[1]) < 1 then
					local r, g, b = color3torgb(Color3.new(tonumber(split[1]), tonumber(split[2]), tonumber(split[3])))
					bodyColors.HeadColor3 = Color3.fromRGB(r, g, b)
				elseif tonumber(split[1]) >= 0 and tonumber(split[1]) <= 255 then
					bodyColors.HeadColor3 = Color3.fromRGB(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
				end

				--local r, g, b = Color3.fromRGB(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))

				--if #split == 3 then
				--Color3.fromRGB(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
				--else
				--	bodyColors.HeadColor3 = Color3.fromHex(colorData) --Color3.new(tonumber(split[1]), tonumber(split[2]), tonumber(split[3])):ToHex() --test(colorData)
				--end
			else
				--if typeof(colorData) == "Color3" then
				bodyColors.HeadColor3 = colorData
			end
		elseif name == "LeftArm" then
			if onlyUpdateColors and typeof(colorData) == "string" then
				local split = string.split(colorData, ",")
				bodyColors.LeftArmColor3 = Color3.fromRGB(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
			elseif typeof(colorData) == "string" then
				local split = string.split(colorData, ",")

				if tonumber(split[1]) >= 0 and tonumber(split[1]) < 1 then
					local r, g, b = color3torgb(Color3.new(tonumber(split[1]), tonumber(split[2]), tonumber(split[3])))
					bodyColors.LeftArmColor3 = Color3.fromRGB(r, g, b)
				elseif tonumber(split[1]) >= 0 and tonumber(split[1]) <= 255 then
					bodyColors.LeftArmColor3 =
						Color3.fromRGB(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
				end
				--local r, g, b = Color3.fromRGB(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
				--local r, g, b = color3torgb(Color3.new(tonumber(split[1]), tonumber(split[2]), tonumber(split[3])))

				--if #split == 3 then
				--bodyColors.LeftArmColor3 = Color3.fromRGB(r, g, b) --Color3.fromRGB(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
				--else
				--	bodyColors.HeadColor3 = Color3.fromHex(colorData) --Color3.new(tonumber(split[1]), tonumber(split[2]), tonumber(split[3])):ToHex() --test(colorData)
				--end
			else
				--if typeof(colorData) == "Color3" then
				bodyColors.LeftArmColor3 = colorData
			end
		elseif name == "RightArm" then
			if onlyUpdateColors and typeof(colorData) == "string" then
				local split = string.split(colorData, ",")
				bodyColors.RightArmColor3 = Color3.fromRGB(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
			elseif typeof(colorData) == "string" then
				local split = string.split(colorData, ",")

				if tonumber(split[1]) >= 0 and tonumber(split[1]) < 1 then
					local r, g, b = color3torgb(Color3.new(tonumber(split[1]), tonumber(split[2]), tonumber(split[3])))
					bodyColors.RightArmColor3 = Color3.fromRGB(r, g, b)
				elseif tonumber(split[1]) >= 0 and tonumber(split[1]) <= 255 then
					bodyColors.RightArmColor3 =
						Color3.fromRGB(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
				end

				--local r, g, b = Color3.fromRGB(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
				--local r, g, b = color3torgb(Color3.new(tonumber(split[1]), tonumber(split[2]), tonumber(split[3])))

				--if #split == 3 then
				--bodyColors.RightArmColor3 = Color3.fromRGB(r, g, b) --Color3.fromRGB(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
				--else
				--	bodyColors.HeadColor3 = Color3.fromHex(colorData) --Color3.new(tonumber(split[1]), tonumber(split[2]), tonumber(split[3])):ToHex() --test(colorData)
				--end
			else
				--if typeof(colorData) == "Color3" then
				bodyColors.RightArmColor3 = colorData
			end
		elseif name == "LeftLeg" then
			if onlyUpdateColors and typeof(colorData) == "string" then
				local split = string.split(colorData, ",")
				bodyColors.LeftLegColor3 = Color3.fromRGB(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
			elseif typeof(colorData) == "string" then
				local split = string.split(colorData, ",")

				if tonumber(split[1]) >= 0 and tonumber(split[1]) < 1 then
					local r, g, b = color3torgb(Color3.new(tonumber(split[1]), tonumber(split[2]), tonumber(split[3])))
					bodyColors.LeftLegColor3 = Color3.fromRGB(r, g, b)
				elseif tonumber(split[1]) >= 0 and tonumber(split[1]) <= 255 then
					bodyColors.LeftLegColor3 =
						Color3.fromRGB(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
				end
				--local r, g, b = Color3.fromRGB(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
				--local r, g, b = color3torgb(Color3.new(tonumber(split[1]), tonumber(split[2]), tonumber(split[3])))

				--if #split == 3 then
				--bodyColors.LeftLegColor3 = Color3.fromRGB(r, g, b) --Color3.fromRGB(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
				--else
				--	bodyColors.HeadColor3 = Color3.fromHex(colorData) --Color3.new(tonumber(split[1]), tonumber(split[2]), tonumber(split[3])):ToHex() --test(colorData)
				--end
			else
				--if typeof(colorData) == "Color3" then
				bodyColors.LeftLegColor3 = colorData
			end
		elseif name == "RightLeg" then
			if onlyUpdateColors and typeof(colorData) == "string" then
				local split = string.split(colorData, ",")
				bodyColors.RightLegColor3 = Color3.fromRGB(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
			elseif typeof(colorData) == "string" then
				local split = string.split(colorData, ",")

				if tonumber(split[1]) >= 0 and tonumber(split[1]) < 1 then
					local r, g, b = color3torgb(Color3.new(tonumber(split[1]), tonumber(split[2]), tonumber(split[3])))
					bodyColors.RightLegColor3 = Color3.fromRGB(r, g, b)
				elseif tonumber(split[1]) >= 0 and tonumber(split[1]) <= 255 then
					bodyColors.RightLegColor3 =
						Color3.fromRGB(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
				end

				--local r, g, b = Color3.fromRGB(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
				--local r, g, b = color3torgb(Color3.new(tonumber(split[1]), tonumber(split[2]), tonumber(split[3])))

				--if #split == 3 then
				--bodyColors.RightLegColor3 = Color3.fromRGB(r, g, b) --Color3.fromRGB(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
				--else
				--	bodyColors.HeadColor3 = Color3.fromHex(colorData) --Color3.new(tonumber(split[1]), tonumber(split[2]), tonumber(split[3])):ToHex() --test(colorData)
				--end
			else
				--if typeof(colorData) == "Color3" then
				bodyColors.RightLegColor3 = colorData
			end
		elseif name == "Torso" then
			if onlyUpdateColors and typeof(colorData) == "string" then
				local split = string.split(colorData, ",")
				bodyColors.TorsoColor3 = Color3.fromRGB(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
			elseif typeof(colorData) == "string" then
				local split = string.split(colorData, ",")

				if tonumber(split[1]) >= 0 and tonumber(split[1]) < 1 then
					local r, g, b = color3torgb(Color3.new(tonumber(split[1]), tonumber(split[2]), tonumber(split[3])))
					bodyColors.TorsoColor3 = Color3.fromRGB(r, g, b)
				elseif tonumber(split[1]) >= 0 and tonumber(split[1]) <= 255 then
					bodyColors.TorsoColor3 = Color3.fromRGB(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
				end

				--local r, g, b = Color3.fromRGB(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
				--local r, g, b = color3torgb(Color3.new(tonumber(split[1]), tonumber(split[2]), tonumber(split[3])))

				--if #split == 3 then
				--bodyColors.TorsoColor3 = Color3.fromRGB(r, g, b) --Color3.fromRGB(tonumber(split[1]), tonumber(spt[2]), tonumber(split[3]))
				--else
				--	bodyColors.HeadColor3 = Color3.fromHex(colorData) --Color3.new(tonumber(split[1]), tonumber(split[2]), tonumber(split[3])):ToHex() --test(colorData)
				--end
			else
				--if typeof(colorData) == "Color3" then
				bodyColors.TorsoColor3 = colorData
			end
		end
	end

	if onlyUpdateColors then
		return
	end

	for _, data in ipairs(savedCharacterData.Clothing) do
		if data.Type then
			--print(data, data.Type)
			if data.Type == "Shirt" then
				-- local id = tostring(data.ShirtId - 1)
				-- local finalId: string = clothingIdStart..id

				-- if not string.find(id, clothingIdStart) then
				-- 	finalId = clothingIdStart .. id
				-- end

				if type(data.ShirtId) == "string" then
					if string.find(data.ShirtId, "roblox") then
						local shirt = Instance.new("Shirt")
						shirt.Parent = npc
						shirt.ShirtTemplate = data.ShirtId

						-- local split = string.split(data.ShirtId, "=")

						-- local num = tonumber(split[2])
						-- --num += 1

						-- local shirt = InsertService:LoadAsset(num):FindFirstChildOfClass("Shirt")
						-- shirt.Parent = npc
					end
				else
					local shirt = InsertService:LoadAsset(tonumber(data.ShirtId)):FindFirstChildOfClass("Shirt")
					shirt.Parent = npc
				end

				-- local _, message = pcall(function()
				-- 	local shirt = InsertService:LoadAsset(data.ShirtId):FindFirstChildOfClass("Shirt")
				-- 	shirt.Parent = npc

				-- 	shirt:SetAttribute("Id", data.ShirtId)
				-- end)

				-- if message then
				-- 	warn("Shirt "..message)
				-- end
				--print("shirt created")
			elseif data.Type == "Pants" then
				-- local id = tostring(data.PantsId - 1)
				-- local finalId: string = clothingIdStart..id

				-- if not string.find(id, clothingIdStart) then
				-- 	finalId = clothingIdStart .. id
				-- end

				if type(data.PantsId) == "string" then
					if string.find(data.PantsId, "roblox") then
						--print("pants", data.PantsId)

						local pants = Instance.new("Pants")
						pants.Parent = npc
						pants.PantsTemplate = data.PantsId

						-- local split = string.split(data.PantsId, "=")

						-- local num = tonumber(split[2])
						-- num += 1

						-- local pants = InsertService:LoadAsset(num):FindFirstChildOfClass("Pants")
						-- pants.Parent = npc
					end
				else
					local pants = InsertService:LoadAsset(tonumber(data.PantsId)):FindFirstChildOfClass("Pants")
					pants.Parent = npc
				end

				-- local _, message = pcall(function()
				-- 	local pants = InsertService:LoadAsset(data.PantsId):FindFirstChildOfClass("Pants")
				-- 	pants.Parent = npc

				-- 	pants:SetAttribute("Id", data.PantsId)
				-- end)

				-- if message then
				-- 	warn("Pants " .. message)
				-- end

				--print("pants created")
			elseif data.Type == "Face" then
				equipFace(npc, data.Texture)
			elseif data.Type == "Accessory" then
				if not data["AssetId"] then
					warn(
						"CUSTOM NPC ERROR: Please set the AssetId attribute in the accessory to insert in the editor. Learn more here: https://gameboythedev.github.io/Custom-Npc-Docs/"
					)
					continue
				end
				-- Loads the accessory in via InsertService
				local success, clothing = pcall(function()
					return InsertService:LoadAsset(tonumber(data.AssetId)):GetChildren()[1]
				end)

				if not success then
					warn(clothing)
					print(data)
					continue
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

				--print("accessory created")
			end
		end
	end

	--print("Updated npcview")
end

--Roblox's asset type id's for accessories
local assetTypeIds = {
	8,
	41,
	42,
	43,
	44,
	45,
	46,
	47,
}

--Compiles clothing, bodycolors and accessories into savedCharacterData for custom avatars
local function compileCustomCharacter(savedCharacterData, characterInfo)
	--print("before", savedCharacterData)

	local notSerializedBodyColors = characterInfo.bodyColors

	--Sets the BodyColors found in characterInfo to the character's data
	savedCharacterData.BodyColors = {
		["LeftArm"] = tostring(BrickColor.new(notSerializedBodyColors.leftArmColorId).Color), -- .Color returns the Color3 value of a BrickColor
		["RightArm"] = tostring(BrickColor.new(notSerializedBodyColors.rightArmColorId).Color),
		["LeftLeg"] = tostring(BrickColor.new(notSerializedBodyColors.leftLegColorId).Color),
		["RightLeg"] = tostring(BrickColor.new(notSerializedBodyColors.rightLegColorId).Color),
		["Head"] = tostring(BrickColor.new(notSerializedBodyColors.headColorId).Color),
		["Torso"] = tostring(BrickColor.new(notSerializedBodyColors.torsoColorId).Color),
	}

	table.clear(savedCharacterData.Clothing)

	for _, assetInfo in pairs(characterInfo.assets) do
		local assetType = assetInfo.assetType

		if assetType.name == "Face" then
			table.insert(savedCharacterData.Clothing, {
				Type = "Face",
				Texture = assetInfo.id,
			})
		elseif assetType.name == "Pants" then
			table.insert(savedCharacterData.Clothing, {
				Type = "Pants",
				PantsId = assetInfo.id,
			})
		elseif assetType.name == "Shirt" then
			table.insert(savedCharacterData.Clothing, {
				Type = "Shirt",
				ShirtId = assetInfo.id,
			})
		elseif table.find(assetTypeIds, tonumber(assetType.id)) then
			table.insert(savedCharacterData.Clothing, {
				Type = "Accessory",
				AssetId = tonumber(assetInfo.id),
			})
		end
	end

	--print("after", savedCharacterData)

	return savedCharacterData
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

	local rig: Model

	if not rigType then
		warn("CUSTOM NPC ERROR: Rig type not found")
		return
	end

	if type(rigType) == "number" then
		local characterInfo = game:GetService("Players"):GetCharacterAppearanceInfoAsync(savedCharacterData.RigType)

		if not characterInfo then
			warn("CUSTOM NPC ERROR: info not found")
			return
		end

		local actualRigType = nil

		for _, v: { id: number, assetType: { name: string, id: number }, name: string } in ipairs(characterInfo.assets) do
			if v.assetType.name == "Torso" and v.id == 27112025 then
				actualRigType = "Robloxian2.0"
				break
			end
		end

		if not actualRigType then
			actualRigType = characterInfo["playerAvatarType"]
		end

		if actualRigType ~= "R15" and actualRigType ~= "R6" and actualRigType ~= "Robloxian2.0" then
			warn("CUSTOM NPC ERROR: RigType not compatible")
			return
		end

		rig = assets.Characters:FindFirstChild(actualRigType):Clone() -- Clones a new rig
		rig:SetAttribute("ActualRigType", actualRigType)

		savedCharacterData = compileCustomCharacter(savedCharacterData, characterInfo)

		--edit:updateNpcClothing(savedCharacterData, rig)
	else
		rig = assets.Characters:FindFirstChild(rigType):Clone() -- Clones a new rig
	end

	rig.Parent = viewFrame

	if not rig.PrimaryPart then
		return
	end

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
-- nameNotNeeded is if the name is not needed set it to true
function edit:compileCharacter(editName, nameNotNeeded, npcOverride)
	local npc = npcViewFrame:FindFirstChildOfClass("Model")

	if npcOverride then
		npc = npcOverride
	end

	local rigTypeFound = npc:FindFirstChildOfClass("Humanoid").RigType

	if npc:GetAttribute("ActualRigType") then
		rigTypeFound = npc:GetAttribute("ActualRigType")
	end

	if rigTypeFound == Enum.HumanoidRigType.R6 then
		rigTypeFound = "R6"
	elseif rigTypeFound == Enum.HumanoidRigType.R15 then
		rigTypeFound = "R15"
	elseif npc:FindFirstChild("UpperTorso") then
		if string.find(npc:FindFirstChild("UpperTorso").MeshId, "1660648364") then
			rigTypeFound = "Robloxian2.0"
		end
	end

	local characterData = { Clothing = {}, BodyColors = {}, currentAnimPack = "", RigType = rigTypeFound }

	local data = getData:Invoke()

	if data["TEMPDATA"] then
		characterData = data["TEMPDATA"]
		data["TEMPDATA"] = nil
	end

	--? Idea: Make tempfolder full of accessories that don't have an assetid to store them in

	local characterName = "" -- = "TempName"

	--local accessoryFolder = Instance.new("Folder")

	if type(rigTypeFound) == "string" then
		table.clear(characterData.Clothing)

		for _, v in pairs(npc:GetDescendants()) do
			if v:IsA("Shirt") then
				if not v:GetAttribute("Id") then
					v:SetAttribute("Id", v.ShirtTemplate)
				end
				table.insert(characterData.Clothing, { Type = "Shirt", ShirtId = v:GetAttribute("Id") })
			elseif v:IsA("Pants") then
				if not v:GetAttribute("Id") then
					v:SetAttribute("Id", v.PantsTemplate)
				end
				table.insert(characterData.Clothing, { Type = "Pants", PantsId = v:GetAttribute("Id") })
			elseif v:IsA("Accessory") then
				--! MAJOR ISSUE CAN'T GET ACCESSORY ASSETID THROUGH ACCESSORY INSTANCE ITSELF
				if v:GetAttribute("AssetId") then
					table.insert(characterData.Clothing, { Type = "Accessory", AssetId = v:GetAttribute("AssetId") })
				else
					warn(
						"CUSTOM NPC ERROR: Please set the AssetId attribute in the accessory to insert in the editor. Learn more here: https://gameboythedev.github.io/Custom-Npc-Docs/"
					)
				end
			--[[
			if v:GetAttribute("AssetId") then
				table.insert(characterData.Clothing, { Type = "Accessory", AssetId = v:GetAttribute("AssetId") })
			else
				local newAccessory: Accessory = v:Clone()

				if accessoryFolder:FindFirstChild(v.Name) then
					for i = 1, 10000 do
						for _, accessory in pairs(accessoryFolder:GetChildren()) do
							if string.find(accessory.Name, tostring(i)) then
								continue
							end
						end
						newAccessory.Name = v.Name .. "_" .. i
					end
				end

				-- newAccessory.Parent = accessoryFolder
			end
			--]]
			elseif v:IsA("BodyColors") then
				--[[
				local function colorType(color3)
					local split = string.split(tostring(color3), ",")

					if tonumber(split[1]) >= 0 and tonumber(split[1]) <= 1 then
						return "Color3.new"
					elseif tonumber(split[1]) >= 0 and tonumber(split[1]) <= 255 then
						return "RGB"
					end
				end

				local function getColor(color3)
					local get = colorType(color3)

					if get == "RGB" then
						--local v1, v2, v3 = rgbtocolor3(color3)
						local split = string.split(tostring(color3), ",")
						return tostring(split[1] .. "," .. split[2] .. "," .. split[3])
					else
						local v1, v2, v3 = color3torgb(color3)
						return tostring(v1 .. "," .. v2 .. "," .. v3)
					end
				end
				--]]

				local function getColorData(colorValue: Color3Value)
					local r, g, b = color3torgb(colorValue)

					return tostring(
						tostring(math.floor(r)) .. "," .. tostring(math.floor(g)) .. "," .. tostring(math.floor(b))
					)
				end

				characterData.BodyColors["Head"] = getColorData(v.HeadColor3)
				characterData.BodyColors["LeftArm"] = getColorData(v.LeftArmColor3)
				characterData.BodyColors["RightArm"] = getColorData(v.RightArmColor3)
				characterData.BodyColors["LeftLeg"] = getColorData(v.LeftLegColor3)
				characterData.BodyColors["RightLeg"] = getColorData(v.RightLegColor3)
				characterData.BodyColors["Torso"] = getColorData(v.TorsoColor3)
			elseif v:IsA("Decal") and v.Parent == npc.Head then
				local texture = v.Texture

				if string.find(texture, "id=") then
					-- Because we are grabbing the decal's texture which doesn't return just the id
					texture = string.split(v.Texture, "id=")[2]
				end

				table.insert(characterData.Clothing, { Type = "Face", Texture = texture })
			end
		end
	else
		local characterInfo = game:GetService("Players"):GetCharacterAppearanceInfoAsync(rigTypeFound)

		if not characterInfo then
			warn("characterInfo not found")
			return
		end

		characterData = compileCustomCharacter(characterData, characterInfo)
	end

	if not editName then
		if not nameNotNeeded then
			characterName = require(script.Parent.popup).editNamePopup(self, true, nil, characterData)
		end
	end

	-- if assets:FindFirstChild(characterName) then
	-- 	for i = 1,10000 do
	-- 		for _, accessory in pairs(accessoryFolder:GetChildren()) do
	-- 			if string.find(accessory.Name, tostring(i)) then
	-- 				continue
	-- 			end
	-- 		end
	-- 		characterName = characterName.."_"..tostring(i)
	-- 	end
	-- 	warn("CUSTOM NPC ERROR: characterName already exists in PluginStorage")
	-- end

	--accessoryFolder.Name = characterName

	--? Not sure what is going on here
	--characterData.RigType = npc.Name

	--print("Compiled: ", characterData)

	--table.insert(characterData, { RigType = npc.Name })

	return characterName, characterData
end

local designConnections = {}

-- This initiates the design frame
function edit:design(savedCharacterData)
	-- Here we are setting the design frames buttons up
	for _, clothingFrame in pairs(design:GetChildren()) do
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
						if data.AssetId then
							id = data.AssetId
						else
							continue
						end
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
						-- warn(
						-- 	"CUSTOM NPC ERROR: Name of "
						-- 		.. id
						-- 		.. " could not be retrieved, setting name of button to the asset id instead."
						-- )
						name = id
					end

					local clothingPieceButton: TextButton = clothingPieceTemplate:Clone()
					clothingPieceButton.Text = tostring(name)
					clothingPieceButton.Parent = list

					designConnections[clothingFrame.Name .. clothingPieceButton.Text .. "ButtonClick"] = clothingPieceButton.MouseButton1Click:Connect(
						function()
							local model = npcViewFrame:FindFirstChildOfClass("Model")

							for _, v in pairs(model:GetChildren()) do
								if v.ClassName == clothingFrame:GetAttribute("CustomizationType") then
									if type(savedCharacterData.RigType) == "string" then
										if v:IsA("Shirt") then
											if v:GetAttribute("Id") == id or v.ShirtTemplate == id then
												v:Destroy()
												break
											end
										elseif v:IsA("Pants") then
											if v:GetAttribute("Id") == id or v.PantsTemplate == id then
												v:Destroy()
												break
											end
										elseif v:IsA("Accessory") then
											if v:GetAttribute("AssetId") == id then
												v:Destroy()
												break
											end
										end
									elseif type(savedCharacterData.RigType) == "number" then
										if v:IsA("Shirt") then
											local loadedAsset = InsertService:LoadAsset(id)
												:FindFirstChildOfClass("Shirt")

											if v.ShirtTemplate == loadedAsset.ShirtTemplate then
												v:Destroy()
												loadedAsset:Destroy()
												break
											else
												loadedAsset:Destroy()
											end
										elseif v:IsA("Pants") then
											local loadedAsset = InsertService:LoadAsset(id)
												:FindFirstChildOfClass("Pants")

											if v.PantsTemplate == loadedAsset.PantsTemplate then
												v:Destroy()
												loadedAsset:Destroy()
												break
											else
												loadedAsset:Destroy()
											end
										elseif v:IsA("Accessory") then
											if v:GetAttribute("AssetId") == id then
												v:Destroy()
												break
											end
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

	local npc = npcViewFrame:FindFirstChildOfClass("Model")

	--print("Loaded")

	-- Connecting the faceIdBox to a FocusLost event so that when the user presses enter it changes the npc's face
	designConnections["faceIdBox"] = faceIdBox.FocusLost:Connect(function(enterPressed)
		if not enterPressed then
			return
		end

		equipFace(npc, faceIdBox.Text)
	end)

	-- Here we are detecting the user's input if they add in a new piece of clothing etc.
	for _, clothingFrame in pairs(design:GetChildren()) do
		if clothingFrame:IsA("Frame") then
			local list: ScrollingFrame = clothingFrame:FindFirstChild("List")
			local add: TextButton = clothingFrame:FindFirstChild("Add")
			local input: TextBox = clothingFrame:FindFirstChild("InputFrame"):FindFirstChild("Input")

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

				local clothing
				local parented

				local function createInstanceMethod(customId)
					local id

					if not customId then
						id = tonumber(string.split(text, "=")[2])
					else
						id = customId
					end

					local success, dict = pcall(function()
						return MarketplaceService:GetProductInfo(id)
					end)

					if success then
						if dict.AssetTypeId == 11 or dict.AssetTypeId == 2 then --shirt
							local shirt = Instance.new("Shirt")
							shirt.Parent = npc
							shirt.ShirtTemplate = "rbxassetid://" .. id
						elseif dict.AssetTypeId == 12 then
							local pants = Instance.new("Pants")
							pants.Parent = npc
							pants.PantsTemplate = "rbxassetid://" .. id
						end

						parented = true
					else
						warn(dict)
					end
				end

				if string.find(text, "roblox") then
					createInstanceMethod()
				else
					local successfullyLoadedAsset, clothingReturned = pcall(function()
						return InsertService:LoadAsset(tonumber(text)):GetChildren()[1]
					end)

					if not successfullyLoadedAsset or not clothingReturned then
						--createInstanceMethod(tonumber(text))
						warn("CUSTOM NPC ERROR: Try using the AssetId instead.")
						return
					else
						clothing = clothingReturned
					end
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
				elseif not parented then
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

				local clothingPieceButton: TextButton = clothingPieceTemplate:Clone()
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

	for _, clothingFrame in pairs(design:GetChildren()) do
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

	local animationPackFrame: Frame & any = animationPackTemplate:Clone()
	local animationPackImage: ImageLabel = animationPackFrame.AssetImage
	local activateButton: TextButton = animationPackFrame.ActivateButton

	if type(savedCharacterData.RigType) == "number" then
		local characterInfo = game:GetService("Players"):GetCharacterAppearanceInfoAsync(savedCharacterData.RigType)

		if not characterInfo then
			warn("CUSTOM NPC ERROR: info not found")
			return
		end

		for _, v: { id: number, assetType: { name: string, id: number }, name: string } in ipairs(characterInfo.assets) do
			if v.assetType.name == "Torso" and v.id == 27112025 then
				rigType = "Robloxian2.0"
				break
			end
		end
	end

	if rigType == "R15" or rigType == "Robloxian2.0" then
		local success, assetInfo = pcall(function()
			-- Gets info on the bundle (name, assetid's etc.)
			return AssetService:GetBundleDetailsAsync(id)
		end)

		if not success then
			warn("CUSTOM NPC ERROR: " .. assetInfo)
			return
		end

		animationPackImage.Image = "rbxthumb://type=BundleThumbnail&id=" .. id .. "&w=150&h=150"

		animationPackFrame.Title.Text = assetInfo.Name

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

	local function mouseLeave(Frame)
		animationConnections[Frame.Name .. "HoverEnd"] = Frame.MouseLeave:Connect(function()
			if animations.BackgroundColor3 == Color3.fromRGB(159, 159, 159) then
				TweenService:Create(Frame, TweenInfo.new(0.25), { BackgroundColor3 = Color3.fromRGB(213, 213, 213) })
					:Play()
			else
				TweenService:Create(Frame, TweenInfo.new(0.25), { BackgroundColor3 = Color3.fromRGB(49, 49, 49) })
					:Play()
			end
		end)
	end

	mouseEnter(animationPackFrame, Color3.fromRGB(252, 168, 0))
	mouseLeave(animationPackFrame)

	-- if animations.BackgroundColor3 == Color3.fromRGB(159, 159, 159) then
	-- 	mouseLeave(animationPackFrame, animationPackFrame:GetAttribute("LightBackground"))
	-- else
	-- 	mouseLeave(animationPackFrame, Color3.fromRGB(49, 49, 49))
	-- end

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

	if savedCharacterData.RigType == "R15" or type(savedCharacterData.RigType) == "number" then
		for _, id in ipairs(animationPackIds) do
			task.spawn(function()
				animationFrame(savedCharacterName, savedCharacterData, id)
			end)
		end
	else
		task.spawn(function()
			animationFrame(savedCharacterName, savedCharacterData)
		end)
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

	for _, frame in pairs(animations:GetChildren()) do
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
		close.TextColor3 = Color3.fromRGB(255, 0, 0)
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

	if type(savedCharacterData.RigType) == "number" then
		local characterInfo = game:GetService("Players"):GetCharacterAppearanceInfoAsync(savedCharacterData.RigType)

		if not characterInfo then
			warn("CUSTOM NPC ERROR: info not found")
			return
		end

		local actualRigType = nil

		for _, v: { id: number, assetType: { name: string, id: number }, name: string } in ipairs(characterInfo.assets) do
			if v.assetType.name == "Torso" and v.id == 27112025 then
				actualRigType = "Robloxian2.0"
				break
			end
		end

		if not actualRigType then
			actualRigType = characterInfo["playerAvatarType"]
		end

		if actualRigType ~= "R15" and actualRigType ~= "R6" and actualRigType ~= "Robloxian2.0" then
			warn("CUSTOM NPC ERROR: RigType not compatible")
			return
		end

		--savedCharacterData.RigType = actualRigType

		savedCharacterData = compileCustomCharacter(savedCharacterData, characterInfo)
	end

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

	-- Clears all text from the textboxes
	for _, v: TextBox in pairs(editFrame.ColorPicker:GetDescendants()) do
		if v:IsA("TextBox") then
			v.Text = ""
		end
	end

	-- if pluginStorage:FindFirstChild("TempData") then
	-- 	pluginStorage:FindFirstChild("TempData"):Destroy()
	-- end

	editFrame.Close.TextColor3 = Color3.fromRGB(255, 255, 255)

	editFrame.Visible = false
end

return edit
