local assets = script.Parent.Parent.Parent.Parent.Assets
local background = assets.Background

local mainFrame = background.Main
local editFrame = mainFrame.Edit
local npcView = editFrame.NpcView

local nameBoxModule = {}

function nameBoxModule.activate(newName)
	editFrame.NameBox.FocusLost:Connect(function()
		local rig = npcView.Rig

		if not rig then warn("Rig not found when trying to change name") return end

		rig:SetAttribute("Name",newName)
	end)	
end

function nameBoxModule:cleanUp()
	editFrame.NameBox.Text = ""
end

return nameBoxModule
