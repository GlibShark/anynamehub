-- hello, i made this nice script for you! 
-- this script is very anonymous and does not send any data about you or your game.
----------------------------------------------------------------------------------

-- data fetch
local game = game
local Players = game:GetService("Players")

local placeId = game.PlaceId
local playerName = Players.LocalPlayer.Name

-- supported place
local supportedModes = {
    6961824067,  -- ftap
    537413528, -- babft
}

-- support check
local function checkSupportedMode()
    for _, id in ipairs(supportedModes) do
        if id == placeId then
            -- fast execute loadstring for supported place
            coroutine.wrap(function()
                pcall(function()
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/GlibShark/bibaexec/refs/heads/main/game/" .. placeId .. "/loader.lua"))()
                end)
            end)()
            return "Type: supported"
        end
    end

    -- fast loadstring for unsupported place
    coroutine.wrap(function()
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/GlibShark/anynamehub/refs/heads/main/lua/notsupp.lua"))()
        end)
    end)()

    -- return
    return "Type: not supported"
end

-- show debug info
print("                                              _           _     ")
print("                                             | |         | |    ")
print("  __ _ _ __  _   _ _ __   __ _ _ __ ___   ___| |__  _   _| |__ ") 
print(" / _` | '_ \\| | | | '_ \\ / _` | '_ ` _ \\ / _ \\ '_ \\| | | | '_ \\ ")
print("| (_| | | | | |_| | | | | (_| | | | | | |  __/ | | | |_| | |_) |")
print(" \\__,_|_| |_|\\__, |_| |_|\\__,_|_| |_| |_|\\___|_| |_|\\__,_|_.__/ ")
print("              __/ |     ")                                        
print("             |___/     ")
print("Current Place ID: " .. placeId)
print("Current Player: " .. playerName)
print(checkSupportedMode())