local edit = require(script.Parent.edit)

local editFrameFunctions = {}

function editFrameFunctions:initEditFrameButtons(savedCharacterName, savedCharacterData)
    edit:initEditFrameButtons(savedCharacterName, savedCharacterData)
end

return editFrameFunctions
