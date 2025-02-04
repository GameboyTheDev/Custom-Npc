local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local popup = {}

local assets: Folder & any = script.Parent.Parent.Assets
local events = assets.Events
local ui = assets.UI

local setData: BindableEvent = events.setData
local getData: BindableFunction = events.getData
local loadData: BindableEvent = events.loadData

local background: Frame & any = ui.Background

local popupFrameClone = background.PopupFrame
local chooseCharacterTypeLocation: Frame = background.ChooseCharacterType
local customAvatarFrameLocation: Frame = background.CustomAvatar

-- Cleans up the popup frame
local function cleanUpPopupFrame(popupFrame, connections)
	popupFrame:Destroy()

	for _, connection: RBXScriptConnection in pairs(connections) do
		connection:Disconnect()
	end
end

-- Gives the user a pop up to which rigtype they want to edit
function popup:rigTypePopup()
	local connections = {}

	local chooseCharacterType = chooseCharacterTypeLocation:Clone()
	local cancel: GuiButton = chooseCharacterType.Cancel
	local r15: GuiButton = chooseCharacterType.R15Button
	local r6: GuiButton = chooseCharacterType.R6Button
	local robloxian2: GuiButton = chooseCharacterType.Robloxian2Button
	local customAvatar: GuiButton = chooseCharacterType.CustomAvatarButton

	-- local r6Button: GuiButton = chooseCharacterType.ActivateButton
	-- local r15Button: GuiButton = chooseCharacterType.ActivateButton

	local chosenRigType = ""
	local stop = false

	--* Old character selection UI
	--local viewFrames = { chooseCharacterType["R6"], chooseCharacterType["R15"] }

	local function getGoal(instance, color)
		if instance:IsA("TextButton") then
			return { TextColor3 = color }
		else
			return { BackgroundColor3 = color }
		end
	end

	local function mouseEnter(button, color)
		connections[button.Name .. "HoverStart"] = button.MouseEnter:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.25), getGoal(button, color)):Play()
		end)
	end

	local function mouseLeave(button, color)
		connections[button.Name .. "HoverEnd"] = button.MouseLeave:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.25), getGoal(button, color)):Play()
		end)
	end

	local customAvatarFrame: Frame & any = customAvatarFrameLocation:Clone()

	customAvatarFrame.Visible = false
	customAvatarFrame.Parent = background

	-- This was with the old character selection UI
	--[[
	for _, viewFrame in pairs(viewFrames) do
		local viewPortFrame: ViewportFrame = viewFrame.ViewportFrame
		local activateButton: GuiButton = viewFrame.ActivateButton

		edit:npcView({ Clothing = {}, RigType = viewFrame:GetAttribute("RigType") }, viewPortFrame)

		mouseEnter(viewFrame, Color3.fromRGB(252, 168, 0))
		mouseLeave(viewFrame, Color3.fromRGB(62, 62, 62))

		connections["R6ButtonClick"] = activateButton.MouseButton1Click:Connect(function()
			chosenRigType = viewFrame.Name
			stop = true
		end)
	end
	--]]

	connections["CustomAvatarClick"] = customAvatar.MouseButton1Up:Connect(function()
		local searchBar: TextBox = customAvatarFrame.SearchBar.Bar
		local customAvatarCancel: TextButton = customAvatarFrame.Cancel
		local customAvatarEdit: TextButton = customAvatarFrame.Edit
		local avatarView: ImageLabel = customAvatarFrame.AvatarView

		--local _connections

		mouseEnter(customAvatarCancel, Color3.fromRGB(255, 0, 0))
		mouseLeave(customAvatarCancel, Color3.fromRGB(255, 255, 255))

		connections["CustomAvatarCancel"] = customAvatarCancel.MouseButton1Up:Connect(function()
			customAvatarFrame.Visible = false
			chosenRigType = "cancel"
			stop = true
		end)

		local getUserId

		connections["CustomAvatarSearchBar"] = searchBar.FocusLost:Connect(function()
			local _, userIdFound = pcall(function()
				return Players:GetUserIdFromNameAsync(searchBar.Text)
			end)

			if not userIdFound then
				warn("CUSTOM NPC ERROR: Could not get userid")
				return
			end

			if not avatarView then
				return
			end

			if userIdFound then
				pcall(function()
					avatarView.Image = Players:GetUserThumbnailAsync(
						userIdFound,
						Enum.ThumbnailType.AvatarBust,
						Enum.ThumbnailSize.Size420x420
					)
				end)
			end

			getUserId = userIdFound
		end)

		connections["EditButtonClick"] = customAvatarEdit.MouseButton1Up:Connect(function()
			customAvatarFrame.Visible = false
			chosenRigType = getUserId
			stop = true
		end)

		chooseCharacterType.Visible = false
		customAvatarFrame.Visible = true
	end)

	connections["Robloxian2ButtonClick"] = robloxian2.MouseButton1Up:Connect(function()
		chosenRigType = "Robloxian2.0"
		stop = true
	end)

	connections["R15ButtonClick"] = r15.MouseButton1Up:Connect(function()
		chosenRigType = "R15"
		stop = true
	end)

	connections["R6ButtonClick"] = r6.MouseButton1Up:Connect(function()
		chosenRigType = "R6"
		stop = true
	end)

	mouseEnter(cancel, Color3.fromRGB(255, 0, 0))
	mouseLeave(cancel, Color3.fromRGB(255, 255, 255))

	connections["cancelButtonClick"] = cancel.MouseButton1Click:Connect(function()
		chosenRigType = "cancel"
		stop = true
	end)

	chooseCharacterType.Name = "chooseCharacterTypeClone"
	chooseCharacterType.Visible = true
	chooseCharacterType.Parent = background

	repeat
		task.wait()
	until stop

	customAvatarFrame:Destroy()
	cleanUpPopupFrame(chooseCharacterType, connections)

	--print(chosenRigType)

	return chosenRigType
end

-- Gives the user a popup to change a character's name and saves the savedCharacterData to that name
-- Args: self: plugin, oldSavedCharacterName, savedCharacterData
function popup:editNamePopup(isNewName, oldSavedCharacterName, savedCharacterData)
	local data = getData:Invoke() --loadData:getData()

	local connections = {}

	local popupFrame = popupFrameClone:Clone()

	local editNameFrame: Frame & any = popupFrame.EditNameFrame

	local editNameTextBox = editNameFrame:FindFirstChildOfClass("TextBox")
	local cancel: GuiButton = editNameFrame.Cancel
	local confirm: GuiButton = editNameFrame.Confirm

	editNameFrame.Visible = true
	popupFrame.Visible = true

	popupFrame.Name = "popupFrameClone"

	popupFrame.Parent = background

	local function mouseEnter(button: GuiButton, color)
		connections[button.Name .. "HoverStart"] = button.MouseEnter:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.25), { TextColor3 = color }):Play()
		end)
	end

	local function mouseLeave(button: GuiButton)
		connections[button.Name .. "HoverEnd"] = button.MouseLeave:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.25), { TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
		end)
	end

	mouseEnter(confirm, Color3.fromRGB(85, 255, 0))
	mouseLeave(confirm)

	mouseEnter(cancel, Color3.fromRGB(255, 0, 0))
	mouseLeave(cancel)

	if not isNewName then
		connections["confirmButton"] = confirm.MouseButton1Click:Connect(function()
			if data[editNameTextBox.Text] then
				warn("CUSTOM NPC ERROR: Unable to change name due to a character already having the same name.")
				return
			end

			data[oldSavedCharacterName] = nil
			data[editNameTextBox.Text] = savedCharacterData

			-- Sets the new data in the plugin
			--self:SetSetting(dataKey, data)
			setData:Fire(data)

			cleanUpPopupFrame(popupFrame, connections)

			-- Refresh's the npc list and loads the new data in
			loadData:Fire(self) -- Puts the plugin in args
			--loadData.LoadData(self)

			--print("Successfully changed character name")
		end)

		connections["cancelButton"] = cancel.MouseButton1Click:Connect(function()
			cleanUpPopupFrame(popupFrame, connections)
		end)

		return
	else
		local newName = ""
		local stop = false
		--local cancelName = false

		connections["confirmButton"] = confirm.MouseButton1Click:Connect(function()
			if string.match(editNameTextBox.Text, "%W") then
				warn("CUSTOM NPC ERROR: Special characters are not allowed in the name of your NPC.")
				return
			end

			newName = editNameTextBox.Text
			stop = true
			cleanUpPopupFrame(popupFrame, connections)
		end)

		connections["cancelButton"] = cancel.MouseButton1Click:Connect(function()
			newName = false
			stop = true
			cleanUpPopupFrame(popupFrame, connections)
			--cancelName = true
		end)

		repeat
			task.wait()
		until stop

		return newName

		-- if not cancelName then
		-- 	return newName
		-- else
		-- 	return nil
		-- end
	end
end

-- Gives the user a popup if they want to delete an character or not
-- Args: self: plugin, savedCharacterName
function popup:deleteSavedCharacter(savedCharacterName)
	local delete = false
	local stop = false

	local data = getData:Invoke()

	local popupFrame = popupFrameClone:Clone()

	local deleteFrame: Frame & any = popupFrame.DeleteFrame
	local warningLabel: TextLabel = deleteFrame.WarningLabel
	local deleteButton: GuiButton = deleteFrame.Delete
	local cancelButton: GuiButton = deleteFrame.Cancel

	warningLabel.Text = "Are you sure you want to delete " .. savedCharacterName .. "? This action cannot be undone."

	local connections = {}

	local enterTweenInfo = TweenInfo.new(0.15)
	local leaveTweenInfo = TweenInfo.new(0.15)

	connections["deleteButtonHoverStart"] = deleteButton.MouseEnter:Connect(function()
		TweenService:Create(deleteButton, enterTweenInfo, { TextColor3 = Color3.fromRGB(255, 0, 0) }):Play()
	end)

	connections["deleteButtonHoverEnd"] = deleteButton.MouseLeave:Connect(function()
		TweenService:Create(deleteButton, leaveTweenInfo, { TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
	end)

	connections["cancelButtonHoverStart"] = cancelButton.MouseEnter:Connect(function()
		TweenService:Create(cancelButton, enterTweenInfo, { TextColor3 = Color3.fromRGB(252, 168, 0) }):Play()
	end)

	connections["cancelButtonHoverEnd"] = cancelButton.MouseLeave:Connect(function()
		TweenService:Create(cancelButton, leaveTweenInfo, { TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
	end)

	connections["deleteButtonClick"] = deleteButton.MouseButton1Click:Connect(function()
		delete = true
		stop = true

		data[savedCharacterName] = nil -- Removes the savedCharacter from the data table

		-- Sets the new data in the plugin
		--self:SetSetting(dataKey, data)
		setData:Fire(data)

		-- Cleans up the popup frame
		cleanUpPopupFrame(popupFrame, connections)

		-- Reloads the list of savedCharacters
		loadData:Fire()
	end)

	connections["cancelButtonClick"] = cancelButton.MouseButton1Click:Connect(function()
		stop = true

		cleanUpPopupFrame(popupFrame, connections)
	end)

	deleteFrame.Visible = true
	popupFrame.Visible = true

	popupFrame.Name = "popupFrameClone"

	popupFrame.Parent = background

	repeat
		task.wait()
	until stop

	return delete
end

return popup
