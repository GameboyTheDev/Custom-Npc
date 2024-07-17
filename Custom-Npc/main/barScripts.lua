local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local StudioService = game:GetService("StudioService")

-- Bar button script

local barScripts = {}

local assets = script.Parent.Parent.Assets
local ui = assets.UI
local animateScripts = assets.AnimateScripts
local events = assets.Events

local editModule = require(script.Parent.edit)
local popup = require(script.Parent.popup)

local getData: BindableFunction = events.getData
local setData: BindableEvent = events.setData
local loadDataEvent: BindableEvent = events.loadData

local background: Frame & any = ui.Background

local main: Frame & any = background.Main
local menu: Frame & any = background.Menu

local bar = main.Bar

local editFrame: Frame & any = main.Edit
local npcView: ViewportFrame = editFrame.NpcView
--local npcViewFrame : WorldModel = npcView:FindFirstChildOfClass("WorldModel")
local designFrame: Frame = editFrame.Design
local colorPicker: Frame = editFrame.ColorPicker
local animationsFrame: Frame = editFrame.Animations
local npcsList: ScrollingFrame = menu.NpcsList.List
local reviewFrame: Frame & any = main.Review
local inputFrame: Frame & any = reviewFrame.InputFrame

--Plan
--When character imported add colors to the editor rig
--Make sure to add bodyparts color data saved in RGB
--Change of the textboxes text in the color picker to the color of each body part in RGB
--When new color inputed by the texboxes change the rigs bodypart color to that color in RGB
--Also update the data

local function dark()
	for _, v in pairs(background:GetDescendants()) do
		if v:GetAttribute("DarkBackground") then
			v.BackgroundColor3 = v:GetAttribute("DarkBackground")
		end
		if v:GetAttribute("DarkPlaceholder") then
			v.PlaceholderColor3 = v:GetAttribute("DarkPlaceholder")
		end
	end
end

local function light()
	for _, v in pairs(background:GetDescendants()) do
		if v:GetAttribute("LightBackground") then
			v.BackgroundColor3 = v:GetAttribute("LightBackground")
		end
		if v:GetAttribute("LightPlaceholder") then
			v.PlaceholderColor3 = v:GetAttribute("LightPlaceholder")
		end
	end
end

function barScripts:themeButton()
	local darkLabel: ImageLabel = bar.ThemeButton.DarkMode
	local lightLabel: ImageLabel = bar.ThemeButton.LightMode

	local currentTheme = settings().Studio.Theme

	if currentTheme == "Dark" then
		lightLabel.Visible = false
		darkLabel.Visible = true
		dark()
	elseif currentTheme == "Light" then
		darkLabel.Visible = false
		lightLabel.Visible = true
		light()
	end

	local function change()
		if lightLabel.Visible == true then
			light()
		else
			dark()
		end
	end

	background.DescendantAdded:Connect(change)
	background.DescendantRemoving:Connect(change)

	bar.ThemeButton.MouseButton1Up:Connect(function()
		if darkLabel.Visible == true then
			lightLabel.Visible = true
			darkLabel.Visible = false
			light()
		else
			lightLabel.Visible = false
			darkLabel.Visible = true
			dark()
		end
	end)
end

function barScripts:reviewButton()
	local cooldown = false

	inputFrame.Submit.MouseButton1Up:Connect(function()
		local sent = false

		local success, message = pcall(function()
			if cooldown then
				warn("CUSTOM NPC: Cooldown, please wait.")
				return
			end
			cooldown = true

			local userId = StudioService:GetUserId()

			if not userId or userId == 0 then
				warn("UserId error")
				cooldown = false
				return
			end

			local name = Players:GetNameFromUserIdAsync(userId)

			if not name then
				warn("Name not found")
				cooldown = false
				return
			end

			if inputFrame.Input.Text == "" then
				cooldown = false
				return
			end

			local webhookUrl =
				"https://discord.com/api/webhooks/1262116319629934652/WWZ1mN99u5dR59kmB8hEc9poqDX5V587ld7jZNt2R-u9A81UeacKHjuUsfAysP6xgBYC"
			local data = {
				["content"] = "", -- Set to empty string if not used
				["embeds"] = {
					{
						["title"] = "Custom-Npc Review!",
						["description"] = "",
						["type"] = "rich",
						["color"] = tonumber(0xfca800),
						["fields"] = {
							{
								["name"] = name .. " wrote a review!",
								["value"] = inputFrame.Input.Text,
								["inline"] = true,
							},
						},
					},
				},
			}

			task.delay(10, function()
				inputFrame.Submit.Text = "Submit"
				cooldown = false
			end)

			local jsonData = HttpService:JSONEncode(data)

			HttpService:PostAsync(webhookUrl, jsonData, Enum.HttpContentType.ApplicationJson)
			sent = true

			inputFrame.Submit.Text = "Sent!"
		end)

		if success then
			if sent then
				print("Successfully sent review!")
			end
		else
			warn(message)
		end
	end)

	inputFrame.Cancel.MouseButton1Up:Connect(function()
		reviewFrame.Visible = false
	end)

	bar.ReviewButton.MouseButton1Up:Connect(function()
		reviewFrame.Visible = not reviewFrame.Visible
	end)
end

function barScripts:newNpcButton()
	bar.CreateButton.MouseButton1Click:Connect(function()
		if not editFrame.Visible and not background:FindFirstChild("chooseCharacterTypeClone") then
			local characterData = { Clothing = {}, BodyColors = {}, currentAnimPack = "" }

			characterData.RigType = popup:rigTypePopup()

			if not characterData.RigType then
				return
			end

			if characterData.RigType == "cancel" then
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

				-- There is 1 instance in there (a UIListLayout)
				npcsListChildrenAmount -= 1

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

				--print(data)

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

-- Args: self (plugin)
function barScripts:insertCharacterButton()
	bar.InsertButton.MouseButton1Up:Connect(function()
		local selected: Model = game.Selection:Get()[1]

		if not selected then
			return
		end

		if not selected:IsA("Model") then
			warn("CUSTOM NPC ERROR: Selection invalid")
			return
		end

		if not selected:FindFirstChildOfClass("Humanoid") or not selected:FindFirstChild("HumanoidRootPart") then
			warn("CUSTOM NPC ERROR: Npc not valid, Humanoid & HumanoidRootPart required")
			return
		end

		local _, compiledCharacterData = editModule.compileCharacter(self, false, true, selected)

		-- not compiledCharacterName or
		if not compiledCharacterData then
			warn("compiledCharacterName or compiledCharacterData is nil")
			return
		end

		if not editFrame.Visible then
			editModule.new("", compiledCharacterData)
		else
			warn("CUSTOM NPC ERROR: The EditFrame is currently in use")
		end
	end)
end

function barScripts:uploadCharacterButton(savedCharacterName, savedCharacterData)
	editFrameConnections["uploadCharacterButtonConnection"] = bar.UploadButton.MouseButton1Click:Connect(function()
		if editFrame.Visible then
			local npc = npcView:FindFirstChildOfClass("Model")

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
			elseif savedCharacterData.currentAnimPack ~= "" and savedCharacterData.RigType == "Robloxian2.0" then
				for _, animation: Instance in pairs(animateScripts:GetChildren()) do
					if animation.Name == savedCharacterData.currentAnimPack then
						animations = animation:Clone()
						break
					end
				end
			elseif savedCharacterData.RigType == "R6" and savedCharacterData.currentAnimPack == "R6Default" then
				animations = animateScripts["R6Default"]:Clone()
			end

			local rigType = savedCharacterData.RigType

			if type(rigType) == "number" then
				if humanoid.RigType == Enum.HumanoidRigType.R6 then
					rigType = "R6"
				elseif humanoid.RigType == Enum.HumanoidRigType.R15 then
					rigType = "R15"
				elseif string.find(npc:FindFirstChild("UpperTorso").MeshId, "1660648364") then
					rigType = "Robloxian2.0"
				end
			end

			for _, v: Script in pairs(animateScripts:GetChildren()) do
				if v:IsA("Script") then
					if
						v:GetAttribute("Type") == rigType
						or rigType == "Robloxian2.0" and v:GetAttribute("Type") == "R15"
					then
						animateScript = v:Clone()
						break
					end
				end
			end

			if not animateScript then
				warn("CUSTOM NPC ERROR: Animate Script not found for " .. savedCharacterData.RigType)
				return
			end

			if
				not animations
				and savedCharacterData.currentAnimPack ~= ""
				and humanoid.RigType == Enum.HumanoidRigType.R15
			then
				warn("CUSTOM NPC ERROR: Animations not found for " .. savedCharacterData.currentAnimPack)
				return
			end

			animateScript.Parent = clonedNpc
			print("Loaded npc in workspace successfully!")
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

local function splitFunction(split)
	if not split[1] or not split[2] or not split[3] then
		return
	end
	
	if
		tonumber(split[1]) >= 0
		and tonumber(split[1]) <= 1
		and tonumber(split[2]) >= 0
		and tonumber(split[2]) <= 1
		and tonumber(split[3]) >= 0
		and tonumber(split[3]) <= 1
	then
		return "Color3.new"
		-- local transfer = Color3.new(tonumber(split[1]), tonumber(split[2]), tonumber(split[3])):ToHex()

		-- if transfer then
		-- 	return transfer, "Color3ToHex"
		-- end
	elseif
		tonumber(split[1]) >= 0
		and tonumber(split[1]) <= 255
		and tonumber(split[2]) >= 0
		and tonumber(split[2]) <= 255
		and tonumber(split[3]) >= 0
		and tonumber(split[3]) <= 255
	then
		return "RGB"
		-- local transfer = Color3.fromRGB(tonumber(split[1]), tonumber(split[2]), tonumber(split[3])):ToHex()

		-- if transfer then
		-- 	return transfer, "RGBToHex"
		-- end
	end

	return
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

			for _, frame in pairs(colorPicker:GetChildren()) do
				if frame:IsA("Frame") then
					local box: TextBox = frame.Box

					local loadData = getData:Invoke()

					local tempDataBefore = loadData["TEMPDATA"]

					--print(savedCharacterName, savedCharacterData, "B")

					local function Length(Table)
						local counter = 0
						for _, _ in pairs(Table) do
							counter = counter + 1
						end
						return counter
					end

					local function color3torgb(color3)
						return color3.R * 255, color3.G * 255, color3.B * 255
					end

					if tempDataBefore then
						if tempDataBefore.BodyColors then
							if tempDataBefore.BodyColors[frame.Name] then
								--local _, msg = pcall(function()
								-- local split = string.split(tempDataBefore.BodyColors[frame.Name], ",")

								--print(tempDataBefore.BodyColors[frame.Name], "!")

								local stringed = tostring(tempDataBefore.BodyColors[frame.Name])

								tempDataBefore.BodyColors[frame.Name] = stringed

								local split = string.split(stringed)

								if #split == 3 then
									if
										tonumber(split[1]) >= 0
										and tonumber(split[1]) <= 1
										and tonumber(split[2]) >= 0
										and tonumber(split[2]) <= 1
										and tonumber(split[3]) >= 0
										and tonumber(split[3]) <= 1
									then
										local r, g, b = color3torgb(
											Color3.new(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
										)

										if r then
											box.Text = tostring(
												math.floor(r) .. ", " .. math.floor(g) .. ", " .. math.floor(b)
											)
										else
											warn("no transfer", r, g, b)
										end
									else
										box.Text = stringed
									end
								else
									box.Text = stringed
								end

								--[[
									if
										tonumber(split[1]) >= 0
										and tonumber(split[1]) <= 255
										and tonumber(split[2]) >= 0
										and tonumber(split[2]) <= 255
										and tonumber(split[3]) >= 0
										and tonumber(split[3]) <= 255
									then
										local transfer = Color3.fromRGB(
											tonumber(split[1]),
											tonumber(split[2]),
											tonumber(split[3])
										):ToHex()

										if transfer then
											box.Text = transfer
											print("Transfered to HEX from RGB", transfer)
										end
									end
								else
									box.Text = tempDataBefore.BodyColors[frame.Name]
								end

								box.Text = split[1] .. "," .. split[2] .. "," .. split[3]
								color3torgb(Color3.new(tonumber(split[1]), tonumber(split[2]), tonumber(split[3])))

								local transferedColor = splitFunction(split)

								if transferedColor then
									box.Text = transferedColor
								else

								savedCharacterData.BodyColors[frame.Name]
								end
								end)

								if msg then
									warn(msg)
								end
								--]]

								--print("TempData changed", tempDataBefore)
							end
						end
					elseif Length(savedCharacterData.BodyColors) > 0 then
						if savedCharacterData.BodyColors[frame.Name] then
							--[[
							local _, msg = pcall(function()
							local split = string.split(savedCharacterData.BodyColors[frame.Name], ",")

							if #split == 3 then
								if
									tonumber(split[1]) >= 0
									and tonumber(split[1]) <= 1
									and tonumber(split[2]) >= 0
									and tonumber(split[2]) <= 1
									and tonumber(split[3]) >= 0
									and tonumber(split[3]) <= 1
								then
									local transfer =
										Color3.new(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
											:ToHex()

									if transfer then
										box.Text = transfer
										print("Transfered to HEX from .new", transfer)
									else
										warn("no transfer", transfer)
									end
								end

								if
									tonumber(split[1]) >= 0
									and tonumber(split[1]) <= 255
									and tonumber(split[2]) >= 0
									and tonumber(split[2]) <= 255
									and tonumber(split[3]) >= 0
									and tonumber(split[3]) <= 255
								then
									local transfer =
										Color3.fromRGB(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
											:ToHex()

									if transfer then
										box.Text = transfer
										print("Transfered to HEX from RGB", transfer)
									end
								end
							else
								box.Text = savedCharacterData.BodyColors[frame.Name]
							end

							local transferedColor = splitFunction(split)

							if transferedColor then
								box.Text = transferedColor
							else
							--]]

							--print(savedCharacterData.BodyColors[frame.Name], "?")

							local stringed = tostring(savedCharacterData.BodyColors[frame.Name])

							savedCharacterData.BodyColors[frame.Name] = stringed

							local split = string.split(stringed)

							if #split == 3 then
								if
									tonumber(split[1]) >= 0
									and tonumber(split[1]) <= 1
									and tonumber(split[2]) >= 0
									and tonumber(split[2]) <= 1
									and tonumber(split[3]) >= 0
									and tonumber(split[3]) <= 1
								then
									local r, g, b = color3torgb(
										Color3.new(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
									)

									if r then
										box.Text =
											tostring(math.floor(r) .. ", " .. math.floor(g) .. ", " .. math.floor(b))
									else
										warn("No transfer", r, g, b)
									end
								else
									box.Text = stringed
								end
							else
								box.Text = stringed
							end

							--box.Text = stringed --savedCharacterData.BodyColors[frame.Name]
							--box.Text = savedCharacterData.BodyColors[frame.Name]
							-- end
							-- end)

							-- if msg then
							-- 	warn(msg)
							-- end

							-- box.Text = split[1] .. "," .. split[2] .. "," .. split[3] -- color3torgb(
							-- 	Color3.new(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
							-- )
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

							-- local split = string.split(box.Text, ",")

							-- if #split < 3 then
							-- 	box.Text = defaultColor
							-- 	warn("CUSTOM NPC ERROR: Make sure you format the color as: 0,0,0 in RGB")
							-- end

							local data = getData:Invoke()

							local tempData = data["TEMPDATA"]

							local _, m = pcall(function()
								if savedCharacterName == "" and tempData then
									if not tempData.BodyColors then
										tempData.BodyColors = {}
									end

									local split = string.split(box.Text, ",")

									local f = splitFunction(split)

									if f == "Color3.new" then
										local r, g, b = color3torgb(
											Color3.new(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
										)
										tempData.BodyColors[frame.Name] = tostring(r .. ", " .. g .. ", " .. b)
									elseif f == "RGB" then
										tempData.BodyColors[frame.Name] = box.Text
									else
										--print("return")
										return
									end

									editModule:updateNpcClothing(tempData, npcView:FindFirstChildOfClass("Model"), true)
								elseif savedCharacterName == "" and not tempData then
									local _, compiledData = editModule:compileCharacter(true)

									tempData = compiledData
									tempData.BodyColors = {}

									local split = string.split(box.Text, ",")

									local f = splitFunction(split)

									if f == "Color3.new" then
										local r, g, b = color3torgb(
											Color3.new(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
										)
										tempData.BodyColors[frame.Name] = tostring(r .. ", " .. g .. ", " .. b)
									elseif f == "RGB" then
										tempData.BodyColors[frame.Name] = box.Text
									else
										--print("return")
										return
									end

									editModule:updateNpcClothing(tempData, npcView:FindFirstChildOfClass("Model"), true)
								else
									--data[savedCharacterName].BodyColors[frame.Name] = box.Text

									local split = string.split(box.Text, ",")

									local f = splitFunction(split)

									if f == "Color3.new" then
										local r, g, b = color3torgb(
											Color3.new(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
										)
										data[savedCharacterName].BodyColors[frame.Name] =
											tostring(r .. ", " .. g .. ", " .. b)
									elseif f == "RGB" then
										data[savedCharacterName].BodyColors[frame.Name] = box.Text
									else
										return
									end

									editModule:updateNpcClothing(
										data[savedCharacterName],
										npcView:FindFirstChildOfClass("Model"),
										true
									)
								end
							end)

							if m then
								warn(m)
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
	barScripts:themeButton()
	barScripts:newNpcButton()
	barScripts:reviewButton()
	barScripts.saveButton(self)
	barScripts.insertCharacterButton(self)
	--barScripts:uploadCharacterButton()
end

return barScripts
