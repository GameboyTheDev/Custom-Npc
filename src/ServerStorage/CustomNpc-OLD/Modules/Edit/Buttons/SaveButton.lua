local saveButtonModule = {}

local dataKey = "Testing_V1"

local assets = script.Parent.Parent.Parent.Parent.Assets
local savedCharacterButtonTemplate = assets.SavedCharTemplate

local background = assets.Background
local editFrame = background.Main.Edit
local saveButton = background.Main.Bar.SaveButton
local npcView = editFrame.NpcView
local menuFrame = background.Menu
local savedCharactersList = menuFrame.NpcsList.List

local clickedConnection = nil

function save()
	local dataToSave = plugin:GetSetting(dataKey) or {}
	
	local rig = npcView.Rig
	local characterInfo = {}

	if not rig then warn("Rig not found when trying to add to the character's list") return end
	
	-- Puts what clothing items the rig is currently wearing in the characterInfo table(data to save)
	for _, item in pairs(rig:GetChildren()) do
		if item:IsA("Pants") then
			table.insert(characterInfo,{Type = "pants",PantsId = item.PantsTemplate})
		elseif item:IsA("Shirt") then
			table.insert(characterInfo,{Type = "shirt",ShirtId = item.ShirtTemplate})
		elseif item:IsA("Accessory") then
			table.insert(characterInfo,{Type = "accessory"}) -- Need to find accessory id
		end
	end

	local savedCharacterButton = savedCharacterButtonTemplate:Clone()

	local rigName = rig:GetAttribute("Name")
	
	if rigName == "" then
		-- Sets a name automatically based on the amount of custom rigs the user has made already
		local function getAmountOfRigsSaved()
			local amount = 0

			for _, v in pairs(savedCharactersList:GetChildren()) do
				if not v:IsA("UIListLayout") then
					amount += 1
				end
			end

			return amount
		end

		savedCharacterButton.Text = "Rig "..getAmountOfRigsSaved()
	else
		-- If the player set a custom name then it sets the rigs name to that
		savedCharacterButton.Text = rigName
	end
	
	-- Adds the new rig to the characters saved list
	dataToSave[rigName] = characterInfo
	
	plugin:SetSetting(dataKey,dataToSave)
	
	-- Adds the new saved character to the characters list
	savedCharacterButton.Parent = savedCharactersList
	
	require(script.Parent.Parent.Parent.UIHandler).setUpButton(savedCharacterButton,characterInfo)
end

function saveButtonModule.activate()
	saveButtonModule:cleanUp()
	
	clickedConnection = saveButton.MouseButton1Click:Connect(function()
		save()
	end)
end

-- Cleans/resets the saveButtonModule
function saveButtonModule:cleanUp()
	if clickedConnection then
		clickedConnection:Disconnect()
	end
end

return saveButtonModule 
