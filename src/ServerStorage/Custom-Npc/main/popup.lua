local TweenService = game:GetService("TweenService")

local edit = require(script.Parent.edit)

local popup = {}

local assets: Folder = script.Parent.Parent.Assets
local background: Frame = assets.Background

local popupFrameClone = background.PopupFrame
local chooseCharacterTypeLocation: Frame = background.ChooseCharacterType

local getData: BindableFunction = assets.getData
local loadData: BindableEvent = assets.loadData

local dataKey = assets.getDataKey:Invoke()

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

	local r6Button: GuiButton = chooseCharacterType["R6Button"]
	local r15Button: GuiButton = chooseCharacterType["R15Button"]

	local chosenRigType = ""
	local stop = false

	local viewFrames = { chooseCharacterType["R6"], chooseCharacterType["R15"] }

	for _, viewFrame in pairs(viewFrames) do
		local viewPortFrame: ViewportFrame = viewFrame.ViewportFrame
		edit:npcView({ Clothing = {}, RigType = viewFrame:GetAttribute("RigType") }, viewPortFrame)
	end

	local function mouseEnter(button, color)
		connections[button.Name .. "HoverStart"] = button.MouseEnter:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.25), { TextColor3 = color }):Play()
		end)
	end

	local function mouseLeave(button)
		connections[button.Name .. "HoverEnd"] = button.MouseLeave:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.25), { TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
		end)
	end

	mouseEnter(r6Button, Color3.fromRGB(252, 168, 0))
	mouseLeave(r6Button)

	connections["R6ButtonClick"] = r6Button.MouseButton1Click:Connect(function()
		chosenRigType = "R6"
		stop = true
	end)

	mouseEnter(r15Button, Color3.fromRGB(252, 168, 0))
	mouseLeave(r15Button)

	connections["R15ButtonClick"] = r15Button.MouseButton1Click:Connect(function()
		chosenRigType = "R15"
		stop = true
	end)

	mouseEnter(cancel, Color3.fromRGB(255, 0, 0))
	mouseLeave(cancel)

	connections["cancelButtonClick"] = cancel.MouseButton1Click:Connect(function()
		chosenRigType = ""
		stop = true
	end)

	chooseCharacterType.Name = "chooseCharacterTypeClone"
	chooseCharacterType.Visible = true
	chooseCharacterType.Parent = background

	repeat
		task.wait()
	until stop

	cleanUpPopupFrame(chooseCharacterType, connections)

	return chosenRigType
end

-- Gives the user a popup to change a character's name
-- Args: self: plugin, oldSavedCharacterName, savedCharacterData
function popup:editNamePopup(isNewName, oldSavedCharacterName, savedCharacterData)
	local data = getData:Invoke() --loadData:getData()

	local connections = {}

	local popupFrame = popupFrameClone:Clone()

	local editNameFrame: Frame = popupFrame.EditNameFrame

	local editNameTextBox: TextBox = editNameFrame:FindFirstChildOfClass("TextBox")
	local cancel: GuiButton = editNameFrame.Cancel
	local confirm: GuiButton = editNameFrame.Confirm

	editNameFrame.Visible = true
	popupFrame.Visible = true

	popupFrame.Name = "popupFrameClone"

	popupFrame.Parent = background

	connections["confirmButtonHoverStart"] = confirm.MouseEnter:Connect(function()
		TweenService:Create(confirm, TweenInfo.new(0.25), { TextColor3 = Color3.fromRGB(85, 255, 0) }):Play()
	end)

	connections["confirmButtonHoverEnd"] = confirm.MouseLeave:Connect(function()
		TweenService:Create(confirm, TweenInfo.new(0.25), { TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
	end)

	connections["cancelButtonHoverStart"] = cancel.MouseEnter:Connect(function()
		TweenService:Create(cancel, TweenInfo.new(0.25), { TextColor3 = Color3.fromRGB(255, 0, 0) }):Play()
	end)

	connections["cancelButtonHoverEnd"] = cancel.MouseLeave:Connect(function()
		TweenService:Create(cancel, TweenInfo.new(0.25), { TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
	end)

	if not isNewName then
		connections["confirmButton"] = confirm.MouseButton1Click:Connect(function()
			if data[editNameTextBox.Text] then
				warn("CUSTOM NPC ERROR: Unable to change name due to a character already having the same name.")
				return
			end

			data[oldSavedCharacterName] = nil
			data[editNameTextBox.Text] = savedCharacterData

			-- Sets the new data in the plugin
			self:SetSetting(dataKey, data)

			cleanUpPopupFrame(popupFrame, connections)

			-- Refresh's the npc list and loads the new data in
			loadData:Fire(self) -- Puts the plugin in args
			--loadData.LoadData(self)

			--print("Successfully changed character name")
		end)

		connections["cancelButton"] = cancel.MouseButton1Click:Connect(function()
			cleanUpPopupFrame(popupFrame, connections)
		end)
	else
		local newName = ""
		local stop = false
		--local cancelName = false

		connections["confirmButton"] = confirm.MouseButton1Click:Connect(function()
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

	local deleteFrame: Frame = popupFrame.DeleteFrame
	local warningLabel: TextLabel = deleteFrame.WarningLabel
	local deleteButton: GuiButton = deleteFrame.Delete
	local cancelButton: GuiButton = deleteFrame.Cancel

	warningLabel.Text = "Are you sure you want to delete " .. savedCharacterName .. "? This action can't be undone."

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
		self:SetSetting(dataKey, data)

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
