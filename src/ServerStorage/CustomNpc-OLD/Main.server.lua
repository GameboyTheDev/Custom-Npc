-- Gameboy 4/16/23

-- Modules
local UIHandler = require(script.Parent.Modules.UIHandler)

-- Plugin
local toolbar: PluginToolbar = plugin:CreateToolbar("CustomNpc-Lite")
local button: PluginToolbarButton = toolbar:CreateButton("Customize", "Customize your npcs", "rbxassetid://13089516202")

-- The plugin widget (The UI the user interacts with)
local widget = plugin:CreateDockWidgetPluginGui(
	"PluginDock",
	DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 300, 300, 200, 200)
)

widget.Title = "CustomNpc-Lite"
script.Parent.Assets.Background.Parent = widget

UIHandler:Init(plugin)

local isOpen = false

button.Click:Connect(function()
	isOpen = not isOpen

	if isOpen then
        widget.Enabled = false
	else
        widget.Enabled = true
	end
end)
