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
local colorPicker: Frame = editFrame.ColorPicker
local animationsFrame: Frame = editFrame.Animations
local npcsList: ScrollingFrame = menu.NpcsList.List

function barScripts:newNpcButton()
	bar.CreateButton.MouseButton1Click:Connect(function()
		if not editFrame.Visible and not background:FindFirstChild("chooseCharacterTypeClone") then
			local characterData = { Clothing = {}, BodyColors = {}, currentAnimPack = "" }

			characterData.RigType = popup:rigTypePopup()

			if characterData.RigType == "" then
				return
			end

			editModule.new("", characterData)
		-- else
		-- 	if background:FindFirstChild("popupFrameClone") then
		-- 		return
		-- 	end

		-- 	editModule:cleanUp()
		end
	end)
end

-- Args: self: plugin
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
				--self:SetSetting(dataKey, data)
				-- print("Saving data", data)

				setData:Fire(data)

				--task.wait(1)

				--print("After saving: ", self:GetSetting(dataKey))
			end

			-- Cleans/Resets the edit frame
			editModule:cleanUp()

			-- Refresh's the npc list and loads the new data in
			loadDataEvent:Fire()

			-- print("CUSTOM NPC: Saved successfully")
		end
	end)
end

local editFrameConnections = {}

function barScripts:designButton(savedCharacterData)
	editFrameConnections["designButtonConnection"] = bar.DesignButton.MouseButton1Click:Connect(function()
		if designFrame.Visible then
			editModule:cleanUpDesign()
		else
			if colorPicker.Visible then
				barScripts:cleanUpColorPicker()
			end

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

			if not animations and savedCharacterData.currentAnimPack ~= "" and humanoid.RigType == Enum.HumanoidRigType.R15 then
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

			print("Loaded npc in workspace successfully")
		end
	end)
end

function barScripts:animationButton(savedCharacterName, savedCharacterData)
	editFrameConnections["animationButton"] = bar.AnimationButton.MouseButton1Click:Connect(function()
		if not animationsFrame.Visible then
			if designFrame.Visible then
				editModule:cleanUpDesign()
			end

			if colorPicker.Visible then
				barScripts:cleanUpColorPicker()
			end

			animationsFrame.Visible = true

			editModule:animationFrame(savedCharacterName, savedCharacterData)
		else
			editModule:cleanUpAnimationFrame()
		end
	end)
end

-- Changing the body colors of the rigs
function barScripts:colorPicker(savedCharacterName, savedCharacterData)
	editFrameConnections["colorPickerButton"] = bar.ColorPicker.MouseButton1Click:Connect(function()
		if colorPicker.Visible then
			barScripts:cleanUpColorPicker()
		else
			if animationsFrame.Visible then
				editModule:cleanUpAnimationFrame()
			end

			if designFrame.Visible then
				editModule:cleanUpDesign()
			end

			colorPicker.Visible = true

			local defaultColor = "127, 127, 127"

			for _, frame: Frame in pairs(colorPicker:GetChildren()) do
				if frame:IsA("Frame") then
					local box: TextBox = frame.Box

					local loadData = getData:Invoke()

					local tempDataBefore = loadData["TEMPDATA"]

					if tempDataBefore then
						if tempDataBefore.BodyColors then
							if tempDataBefore.BodyColors[frame.Name] then
								box.Text = tempDataBefore.BodyColors[frame.Name]
							end
						end
					elseif savedCharacterName ~= "" then
						if savedCharacterData.BodyColors[frame.Name] then
							box.Text = savedCharacterData.BodyColors[frame.Name]
						end
					end

					editFrameConnections[frame.Name .. "ColorPickerBoxConnection"] = box.FocusLost:Connect(
						function(enterPressed)
							if not enterPressed then
								return
							end

							if box.Text == "" then
								-- Sets the color to the default npc grey color
								box.Text = defaultColor
							end

							local split = string.split(box.Text, ",")

							if #split < 3 then
								box.Text = defaultColor
								warn("CUSTOM NPC ERROR: Make sure you format the color as: 0,0,0 in RGB")
							end

							local data = getData:Invoke()

							local tempData = data["TEMPDATA"]

							if savedCharacterName == "" and tempData then
								if not tempData.BodyColors then
									tempData.BodyColors = {}
								end

								tempData.BodyColors[frame.Name] = box.Text

								editModule:updateNpcClothing(tempData, npcView:FindFirstChildOfClass("Model"))
							elseif savedCharacterName == "" and not tempData then
								local _, compiledData = editModule:compileCharacter(true)

								tempData = compiledData
								tempData.BodyColors = {}
								tempData.BodyColors[frame.Name] = box.Text

								editModule:updateNpcClothing(tempData, npcView:FindFirstChildOfClass("Model"))
							else
								data[savedCharacterName].BodyColors[frame.Name] = box.Text

								editModule:updateNpcClothing(
									data[savedCharacterName],
									npcView:FindFirstChildOfClass("Model")
								)
							end

							setData:Fire(data)
						end
					)
				end
			end
		end
	end)
end

function barScripts:cleanUpColorPicker()
	colorPicker.Visible = false

	for connectionName, connection: RBXScriptConnection in pairs(editFrameConnections) do
		if string.find(connectionName, "ColorPicker") then
			connection:Disconnect()
		end
	end
end

function barScripts:cleanUpEditFrame()
	barScripts:cleanUpColorPicker()

	for _, connection: RBXScriptConnection in pairs(editFrameConnections) do
		connection:Disconnect()
	end
end

function barScripts:initEditFrameButtons(savedCharacterName, savedCharacterData)
	barScripts:colorPicker(savedCharacterName, savedCharacterData)
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
