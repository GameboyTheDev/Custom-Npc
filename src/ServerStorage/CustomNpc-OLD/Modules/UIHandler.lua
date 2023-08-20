-- 4/17/23

local UIHandler = {}

local dataKey = "Testing_V2"

local editModule = require(script.Parent.Edit)

--local barModule = require(script.Parent.Bar)

local Assets = script.Parent.Parent.Assets
local savedCharacterTemplate = Assets.SavedCharTemplate

local background = Assets.Background

local mainFrame = background.Main
local editFrame = mainFrame.Edit
local npcView = editFrame.NpcView
local barFrame = mainFrame.Bar

local menuFrame = background.Menu
local charactersList = menuFrame.NpcsList.List

local isEditFrameOpen = false

--[[ Data Model
	["Rig"] = {
		{Type = "pants",PantsId = 0}
	}
--]]

local savedCharacters

function loadData(plugin)
	local data = plugin:GetSetting(dataKey) or {}

	if data then
		savedCharacters = data.savedCharacters
	else
		data.savedCharacters = {}
	end

	-- Gets all the saved characters and loads them in to the savedCharactersList frame
	for savedCharacterName, savedCharacter in pairs(savedCharacters) do
		local characterButton: TextButton = savedCharacterTemplate:Clone()
		characterButton.Text = savedCharacterName
		
		-- Sets up the buttons functionality with the editframe
		UIHandler.setUpButton(characterButton,savedCharacter)

		characterButton.Parent = charactersList
	end
end

-- Sets up the button that is in the saved characters list
function UIHandler.setUpButton(button,savedCharacter)
	button.MouseButton1Click:Connect(function()
		isEditFrameOpen = not isEditFrameOpen
		
		if isEditFrameOpen then
			editModule:close()
		else
			editModule.activate(savedCharacter)
		end
	end)
end

-- Initializes the plugin UI
function UIHandler:Init(plugin)
	loadData(plugin)
	
	--barModule()
end

return UIHandler
