local TweenService = game:GetService("TweenService")

local toolbar: PluginToolbar = plugin:CreateToolbar("Custom-Npc")
local mainButton: PluginToolbarButton =
	toolbar:CreateButton("MainButton", "Customize your npcs", "rbxassetid://13089516202", "Customize")

-- The plugin widget (The UI the user interacts with)
local widget = plugin:CreateDockWidgetPluginGui(
	"PluginDock",
	DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 400, 400, 250, 250)
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

local getDataKey: BindableFunction = assets.getDataKey
local getData: BindableFunction = assets.getData
local loadDataEvent: BindableEvent = assets.loadData

local savedCharacterTemplate: Frame = assets.SavedCharacterTemplate

local background: Frame = assets.Background

local main: Frame = background.Main
local menu: Frame = background.Menu

local editFrame: Frame = main.Edit
local npcsList: ScrollingFrame = menu.NpcsList.List

getDataKey.OnInvoke = function()
	return dataKey
end

getData.OnInvoke = function()
	return data
end

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
		print(savedCharacterName, savedCharacterData)

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
			if editFrame.Visible then
				editModule:cleanUp()
				--editModule:cleanUpDesign()
			else
				print("Refiring: ", savedCharacterData)
				editModule.new(savedCharacterName, savedCharacterData)
			end
		end)
		--print("Done setting up", savedCharacterName)
	end
	--print("Data loaded")
end

loadDataEvent.Event:Connect(loadData)

loadData()

local isOpen = false

mainButton.Click:Connect(function()
	isOpen = not isOpen

	if isOpen then
		widget.Enabled = false
	else
		widget.Enabled = true
	end
end)
