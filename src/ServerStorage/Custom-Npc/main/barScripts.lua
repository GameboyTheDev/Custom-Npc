local Selection = game:GetService("Selection")

-- Bar button script

local barScripts = {}

local editModule = require(script.Parent.edit)
local popup = require(script.Parent.popup)

local assets = script.Parent.Parent.Assets

local dataKey = assets.getDataKey:Invoke()

local getData: BindableFunction = assets.getData
local loadDataEvent: BindableEvent = assets.loadData

local background: Frame = assets.Background

local main: Frame = background.Main
local menu: Frame = background.Menu

local bar = main.Bar

local editFrame: Frame = main.Edit
local npcView: ViewportFrame = editFrame.NpcView
local designFrame: Frame = editFrame.Design
local animationsFrame: Frame = editFrame.Animations
local npcsList: ScrollingFrame = menu.NpcsList.List

function barScripts:newNpcButton()
	bar.CreateButton.MouseButton1Click:Connect(function()
		if not editFrame.Visible and not background:FindFirstChild("chooseCharacterTypeClone") then
			local characterData = { Clothing = {} }

			-- local rigType = popup:rigTypePopup()

			-- table.insert(characterData, {RigType = rigType})

			-- print(characterData)

			characterData.RigType = popup:rigTypePopup()

			if characterData.RigType == "" then
				return
			end

			editModule.new("", characterData)
			--barScripts:designButton({Clothing = {}})
		else
			--barScripts:cleanUpDesignButton()
			editModule:cleanUp()
		end
	end)
end

--Args: self: plugin
function barScripts:saveButton()
	bar.SaveButton.MouseButton1Click:Connect(function()
		if editFrame.Visible and not background:FindFirstChild("popupFrameClone") then
			local data = getData:Invoke()

			-- Gets the newCharacterName and compiles the clothing pieces of the newCharacter in a table
			local newCharacterName, newCharacter = editModule.compileCharacter(self)

			-- If the newCharacterName returns the bool of false than that means the user didn't want to change the name.
			if newCharacterName == false then
				return
			end

			--print("Picked up from compile: ", newCharacter)

			if data then
				local npcsListChildrenAmount = #npcsList:GetChildren()

				if newCharacterName and newCharacterName ~= "" then
					-- Returns if name already is being used
					if data[newCharacterName] then
						warn("CUSTOM NPC ERROR: Can't have same character name, not saving")
						return
					end

					-- Sets the new data in
					data[newCharacterName] = newCharacter
					--print("Before saving: ",data)
				elseif newCharacterName == "" then
					-- So that the first npc character is not called "Npc 2"
					if npcsListChildrenAmount <= 0 then
						data[tostring("Npc " .. 1)] = newCharacter
					else
						data[tostring("Npc " .. npcsListChildrenAmount + 1)] = newCharacter
					end
				end

				-- Sets the new data in the plugin
				self:SetSetting(dataKey, data)

				--task.wait(1)

				--print("After saving: ", self:GetSetting(dataKey))
			end

			-- Cleans/Resets the edit frame
			editModule:cleanUp()

			-- Refresh's the npc list and loads the new data in
			loadDataEvent:Fire()

			print("CUSTOM NPC: Saved successfully")
		end
	end)
end

local editFrameConnections = {}

function barScripts:designButton(savedCharacterData)
	editFrameConnections["designButtonConnection"] = bar.DesignButton.MouseButton1Click:Connect(function()
		if designFrame.Visible then
			editModule:cleanUpDesign()
		else
			editModule:design(savedCharacterData)
		end
	end)
end

function barScripts:uploadCharacterButton()
	bar.UploadButton.MouseButton1Click:Connect(function()
		if editFrame.Visible then
			local npc: Model = npcView:FindFirstChildOfClass("Model")

			if not npc then
				warn("CUSTOM NPC ERROR: Npc not found in ViewportFrame")
				return
			end

			local clonedNpc = npc:Clone()
			clonedNpc.Name = "ClonedNpc"
			clonedNpc.Parent = workspace

			Selection:Set({ clonedNpc })

			print("Loaded npc in workspace")
		end
	end)
end

function barScripts:animationButton(savedCharacterData)
	editFrameConnections["animationButton"] = bar.AnimationButton.MouseButton1Click:Connect(function() 
		if not animationsFrame.Visible then
			print("Showing...")

			editModule:animationFrame(savedCharacterData)

			animationsFrame.Visible = true			
		else
			animationsFrame.Visible = false
		end
	end)
end

function barScripts:cleanUpEditFrame()
	for _, connection: RBXScriptConnection in pairs(editFrameConnections) do
		connection:Disconnect()
	end
end

function barScripts:initEditFrameButtons(savedCharacterData)
	barScripts:animationButton(savedCharacterData)
	barScripts:designButton(savedCharacterData)
end

--Args: self: plugin
function barScripts:Init()
	barScripts:newNpcButton()
	barScripts.saveButton(self)
	barScripts:uploadCharacterButton()
end

return barScripts
