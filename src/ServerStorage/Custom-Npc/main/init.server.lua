local TweenService = game:GetService("TweenService")

local toolbar: PluginToolbar = plugin:CreateToolbar("Custom-Npc")
local mainButton: PluginToolbarButton =
	toolbar:CreateButton("MainButton", "Customize your npcs", "rbxassetid://14534329195", "Customize")

-- The plugin widget (The UI the user interacts with)
local widget = plugin:CreateDockWidgetPluginGui(
	"PluginDock",
	DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, true, false, 500, 400, 200, 200) -- Testing dockui
)

widget.Title = "Custom-Npc"

local data

-- Data example
--[[
    ["Name"] = {}
]]
--

local dataKey = "PluginDataTest9"

local assets = script.Parent.Assets
local events = assets.Events
local ui = assets.UI

local setData: BindableEvent = events.setData
local getData: BindableFunction = events.getData
local loadDataEvent: BindableEvent = events.loadData

local savedCharacterTemplate: Frame = ui.SavedCharacterTemplate

local background: Frame = ui.Background

local main: Frame = background.Main
local menu: Frame = background.Menu

local editFrame: Frame = main.Edit
local npcsList: ScrollingFrame = menu.NpcsList.List

getData.OnInvoke = function()
	return data
end

setData.Event:Connect(function(newData)
	-- if newData["TEMPDATA"] then
	-- 	newData["TEMPDATA"] = nil
	-- end

	plugin:SetSetting(dataKey, newData)

	data = newData

	-- print("setData event: ", data)
end)

local barScripts = require(script.barScripts)
local popup = require(script.popup)
local editModule = require(script.edit)

barScripts.Init(plugin)

-- Parents the UI to the widget
background.Parent = widget

-- Loads the data in
function loadData()
	--print("Getting data")

	data = nil
	data = plugin:GetSetting(dataKey)

	if not data then
		data = {}
	end

	for _, savedCharacterFrame: Frame in pairs(npcsList:GetChildren()) do
		if savedCharacterFrame:IsA("Frame") then
			savedCharacterFrame:Destroy()
		end
	end

	--print("Cleared")

	local connections = {}

	for savedCharacterName, savedCharacterData in pairs(data) do
		-- print(savedCharacterName, savedCharacterData)

		--if savedCharacterName ~= "TEMPDATA" then
		local savedCharacterFrame = savedCharacterTemplate:Clone()

		local loadCharacter: GuiButton = savedCharacterFrame.LoadCharacter

		local editName: GuiButton = savedCharacterFrame.EditName
		local editImageLabel: ImageLabel = editName:FindFirstChildOfClass("ImageLabel")

		local trash: GuiButton = savedCharacterFrame.Trash
		local trashImageLabel: ImageLabel = trash:FindFirstChildOfClass("ImageLabel")

		loadCharacter.Text = savedCharacterName

		savedCharacterFrame.Name = savedCharacterName
		savedCharacterFrame.Parent = npcsList

		--barScripts:designButton(savedCharacterData)

		local function mouseEnter(button, color)
			connections[savedCharacterName .. "HoverStart"] = button.MouseEnter:Connect(function()
				TweenService:Create(button, TweenInfo.new(0.25), { ImageColor3 = color }):Play()
			end)
		end

		local function mouseLeave(button)
			connections[savedCharacterName .. "HoverEnd"] = button.MouseLeave:Connect(function()
				TweenService:Create(button, TweenInfo.new(0.25), { ImageColor3 = Color3.fromRGB(255, 255, 255) }):Play()
			end)
		end

		mouseEnter(editImageLabel, Color3.fromRGB(252, 168, 0))
		mouseLeave(editImageLabel)

		connections[savedCharacterName .. "_editNameClick"] = editName.MouseButton1Click:Connect(function()
			if background:FindFirstChild("popupFrameClone") then
				return
			end

			popup.editNamePopup(plugin, false, savedCharacterName, savedCharacterData)
		end)

		mouseEnter(trashImageLabel, Color3.fromRGB(255, 0, 0))
		mouseLeave(trashImageLabel)

		connections[savedCharacterName .. "_trashClick"] = trash.MouseButton1Click:Connect(function()
			if background:FindFirstChild("popupFrameClone") then
				return
			end

			local delete = popup.deleteSavedCharacter(plugin, savedCharacterName)

			if delete then
				for connectionName, connection: RBXScriptConnection in pairs(connections) do
					if string.find(connectionName, savedCharacterName) then
						connection:Disconnect()
					end
				end

				editModule:cleanUp()

				--barScripts:cleanUpDesignButton()
			end
		end)

		connections[savedCharacterName .. "_loadCharacterClick"] = loadCharacter.MouseButton1Click:Connect(function()
			if background:FindFirstChild("popupFrameClone") then
				return
			end

			-- if editFrame.Visible then
			-- 	editModule:cleanUp()

			-- 	editModule.new(savedCharacterName, savedCharacterData)

			-- 	--editModule:cleanUpDesign()
			-- else
				--print("Refiring: ", savedCharacterData)

				if not editFrame.Visible then
					editModule.new(savedCharacterName, savedCharacterData)
				end
			--end
		end)
		--print("Done setting up", savedCharacterName)
		--end
	end

	-- if data["TEMPDATA"] then
	-- 	data["TEMPDATA"] = nil
	-- end

	--print("Data loaded")
end

loadDataEvent.Event:Connect(loadData)

loadData()

local isOpen = false

mainButton.Click:Connect(function()
	isOpen = not isOpen

	if isOpen then
		local newData = data

		if newData["TEMPDATA"] then
			newData["TEMPDATA"] = nil
		end

		plugin:SetSetting(dataKey, newData)

		data = newData

		widget.Enabled = false
	else
		widget.Enabled = true
	end
end)
