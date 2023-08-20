local editModule = {}

local Assets = script.Parent.Parent.Assets --script.Parent.Parent.Assets
local background = Assets.Background

local mainFrame = background.Main
local editFrame = mainFrame.Edit
local barFrame = mainFrame.Bar

local buttonModules = script.Buttons
local editModules = script.EditModules

function editModule.activate(savedCharacter)
	-- Activates all the modules for the user to edit the custom rig
	for _, folder in pairs(script:GetChildren()) do
		for _, moduleScript: ModuleScript in pairs(folder:GetChildren()) do
			moduleScript.activate(savedCharacter)
		end
	end
	
	editFrame.Visible = true
end

-- Closes the edit frame and cleans everything up
function editModule:close()
	editFrame.Visible = false
	
	for _, folder in pairs(script:GetChildren()) do
		for _, moduleScript: ModuleScript in pairs(folder:GetChildren()) do
			moduleScript:cleanUp()
		end
	end
end

return editModule
