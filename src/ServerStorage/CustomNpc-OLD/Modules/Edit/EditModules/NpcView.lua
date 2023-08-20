local npcViewModule = {}

local RunService = game:GetService("RunService")
local InsertService = game:GetService("InsertService")

local assets = script.Parent.Parent.Parent.Parent.Assets
local background = assets.Background

local mainFrame = background.Main
local editFrame = mainFrame.Edit
local npcView = editFrame.NpcView

local currentNpcMovement = nil

-- Updates the current npc's clothing in the npcview (Viewportframe)
function npcViewModule.updateClothing(characterInfo)
	local rig = npcView.Rig

	if not rig then warn("Could not find rig to update the clothing for") return end

	for _, data in pairs(characterInfo) do
		if data.Type == "shirt" then
			local shirt = Instance.new("Shirt")
			shirt.ShirtTemplate = data.ShirtId
			shirt.Parent = rig
		elseif data.Type == "pants" then
			local pants = Instance.new("Pants")
			pants.PantsTemplate = data.PantsId
			pants.Parent = rig
		elseif data.Type == "accessory" then
			local loadedModel = InsertService:LoadAsset(data.AccessoryId)
			loadedModel.Parent = workspace

			local accessory = loadedModel:FindFirstChildOfClass("Accessory")
			
			accessory:SetAttribute(data.AccessoryId)

			rig.Humanoid:AddAccessory(accessory)

			loadedModel:Destroy()
		end
	end
end

-- Args: characterInfo (the data saved about the character)
function npcViewModule.activate(characterInfo)
	npcViewModule:cleanUpNpcView() -- Cleans up everything in npcview before update
	
	local rig = assets.Rig:Clone() -- Clones a new rig
	rig.Parent = npcView
	
	if characterInfo ~= nil then
		npcViewModule.updateClothing(characterInfo)
	end
	
	local camera = Instance.new("Camera") -- Camera to view the rig
	camera.Parent = npcView
	
	npcView.CurrentCamera = camera -- Connects the camera to the viewportframe
	
	local angle = 0 -- current rotation angle
	local speed = 1 -- How long it takes to do a full cycle
	local distance = 6 -- Studs
	local center = rig.PrimaryPart.Position -- the center location the camera should go around
	
	local function UpdateCamera(timeSinceLastFrame)
		angle += timeSinceLastFrame * speed -- Sets the angle
		camera.CFrame = CFrame.Angles(0, angle, 0) * CFrame.new(0, -.5, distance) + center -- Sets the cframe
	end
	
	currentNpcMovement = RunService:BindToRenderStep("UpdateCamera", Enum.RenderPriority.Camera.Value + 1, UpdateCamera)
end

-- Cleans up the npcview and resets it
function npcViewModule:cleanUp()
	if currentNpcMovement then
		currentNpcMovement:Disconnect()
		currentNpcMovement = nil
	end

	for _, v in pairs(npcView:GetChildren()) do
		if not v:IsA("UICorner") then
			v:Destroy()
		end
	end

	npcView.CurrentCamera = nil
end

return npcViewModule
