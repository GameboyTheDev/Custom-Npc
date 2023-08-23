local Selection = game:GetService("Selection")

-- Bar button script

local barScripts = {}

local editModule = require(script.Parent.edit)
local popup = require(script.Parent.popup)

local assets = script.Parent.Parent.Assets
local ui = assets.UI
local animateScripts = assets.AnimateScripts
local events = assets.Events

local getData: BindableFunction = events.getData
local setData: BindableEvent = events.setData
local loadDataEvent: BindableEvent = events.loadData

local background: Frame = ui.Background

local main: Frame = background.Main
local menu: Frame = background.Menu

local bar = main.Bar

local editFrame: Frame = main.Edit
local npcView: ViewportFrame = editFrame.NpcView
--local npcViewFrame : WorldModel = npcView:FindFirstChildOfClass("WorldModel")
local designFrame: Frame = editFrame.Design
local animationsFrame: Frame = editFrame.Animations
local npcsList: ScrollingFrame = menu.NpcsList.List

function barScripts:newNpcButton()
	bar.CreateButton.MouseButton1Click:Connect(function()
		if not editFrame.Visible and not background:FindFirstChild("chooseCharacterTypeClone") then
			local characterData = { Clothing = {}, currentAnimPack = "" }

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

			if data["TEMPDATA"] then
				data["TEMPDATA"] = nil
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
				--self:SetSetting(dataKey, data)
				print("Saving data", data)

				setData:Fire(data)

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
			if animationsFrame.Visible then
				editModule:cleanUpAnimationFrame()
			end

			editModule:design(savedCharacterData)
		end
	end)
end

function barScripts:uploadCharacterButton(savedCharacterName, savedCharacterData)
	editFrameConnections["uploadCharacterButtonConnection"] = bar.UploadButton.MouseButton1Click:Connect(function()
		if editFrame.Visible then
			local npc: Model = npcView:FindFirstChildOfClass("Model")

			if not npc then
				warn("CUSTOM NPC ERROR: Npc not found in ViewportFrame")
				return
			end

			local clonedNpc = npc:Clone()
			local humanoid: Humanoid = npc.Humanoid

			if savedCharacterName ~= "" and savedCharacterName then
				clonedNpc.Name = savedCharacterName
			end

			clonedNpc.Parent = workspace

			local animateScript: Script
			local animations

			if savedCharacterData.currentAnimPack ~= "" and savedCharacterData.RigType == "R15" then
				for _, animationHolder: Instance in pairs(animateScripts:GetChildren()) do
					if animationHolder.Name == savedCharacterData.currentAnimPack then
						animations = animationHolder:Clone()
						break
					end
				end
			elseif savedCharacterData.RigType == "R6" and savedCharacterData.currentAnimPack == "R6Default" then
				animations = animateScripts["R6Default"]:Clone()
			end

			for _, v: Script in pairs(animateScripts:GetChildren()) do
				if v:IsA("Script") then
					if v:GetAttribute("Type") == savedCharacterData.RigType then
						animateScript = v:Clone()
						break
					end
				end
			end

			if not animateScript then
				warn("CUSTOM NPC ERROR: Animate Script not found for " .. savedCharacterData.RigType)
				return
			end

			if not animations and humanoid.RigType == Enum.HumanoidRigType.R15 then
				warn("CUSTOM NPC ERROR: Animations not found for " .. savedCharacterData.currentAnimPack)
				return
			end

			animateScript.Parent = clonedNpc

			if animations then
				for _, v in pairs(animations:GetChildren()) do
					v.Parent = animateScript
				end
			end

			animateScript.Enabled = true

			-- Makes the player select the npc in studio
			Selection:Set({ clonedNpc })

			print("Loaded npc in workspace")
		end
	end)
end

function barScripts:animationButton(savedCharacterName, savedCharacterData)
	editFrameConnections["animationButton"] = bar.AnimationButton.MouseButton1Click:Connect(function()
		if not animationsFrame.Visible then
			if designFrame.Visible then
				editModule:cleanUpDesign()
			end

			animationsFrame.Visible = true

			editModule:animationFrame(savedCharacterName, savedCharacterData)
		else
			editModule:cleanUpAnimationFrame()
		end
	end)
end

function barScripts:cleanUpEditFrame()
	for _, connection: RBXScriptConnection in pairs(editFrameConnections) do
		connection:Disconnect()
	end
end

function barScripts:initEditFrameButtons(savedCharacterName, savedCharacterData)
	barScripts:animationButton(savedCharacterName, savedCharacterData)
	barScripts:designButton(savedCharacterData)
	barScripts:uploadCharacterButton(savedCharacterName, savedCharacterData)
end

--Args: self: plugin
function barScripts:Init()
	barScripts:newNpcButton()
	barScripts.saveButton(self)
	--barScripts:uploadCharacterButton()
end

return barScripts
