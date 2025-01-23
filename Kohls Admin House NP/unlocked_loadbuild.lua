--!nonstrict
--Dekryptionite 01/22/2025

-- Not finished with this, didn't even test it in game. When I am finished it is just used to locally load people's builds on your client; useful for moderation etc.

if shared._DEK then
	return
end
if not game:GetService("RunService"):IsServer() then
	return
end
if not game.Players["Dekryptionite"] then
	return
end

shared._DEK = {}

-- Datastores
local DStore = game:GetService("DataStoreService")
local DStoreKohls = DStore:GetDataStore("BuildSaveSystem")
local DStoreP299 = "Person299BuildSaveSystem"

-- Grab commands from Solinium (used for clientscript)
--local Solinium = require(game.ServerScriptService.goog.Utilities.Commands)
local Solinium = game.ServerScriptService.goog

function shared._DEK:GetStore(Inventor:Player,Slot:number)
	if not Slot then -- You are attempting to get from the Kohls store.
		return DStoreKohls:GetAsync(Inventor.UserId)
	end
	if Slot then -- You are attempting to get from a Person299 store slot.
		local Store = DStore:GetDataStore(DStoreP299..Slot)
		return Store:GetAsync(Inventor.UserId)
	end
end

function shared._DEK:LoadParts()
	
end

function shared._DEK:ClientCode(Player:Player,Code:string)
	local scr = Solinium.Utilities.Client:Clone()
	scr:WaitForChild("Exec").Value =  Code
	scr.Parent = Player.PlayerGui
	scr.Enabled = true
end
