--!nonstrict
--Dekryptionite 01/22/2025

-- Do not overwrite people's builds unless they are making the game unplayable or violating ROBLOX rules in a way that will lead to BoasGameTest being terminated.

if shared._DEK then
	print("Dekryptionite: Someone has already loaded the script! Use shared._DEK:Load()\n")
	return
end
if not game:GetService("RunService"):IsServer() then
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

function shared._DEK:ClientCode(Player:Player,Code:string)
	local scr = Solinium.Utilities.Client:Clone()
	scr:WaitForChild("Exec").Value = Code
	scr.Parent = Player.PlayerGui
	scr.Enabled = true
end

function shared._DEK:GetStore(Inventor:number,Slot:number)

	if not Slot then -- You are attempting to get from the Kohls store.
		return DStoreKohls:GetAsync(Inventor)
	end
	
	if Slot then -- You are attempting to get from a Person299 store slot.
		local Store = DStore:GetDataStore(DStoreP299..Slot)
		return Store:GetAsync(Inventor)
	end
	
end

function shared._DEK:LoadParts(Parts)
	
	if not Parts then
		return
	end
	
	local PartsParent = Instance.new("Folder")
	PartsParent.Name = "TempBuilds"
	
	for i,v in Parts do
	
		local Placed
		
		if v.Name == "Part" then
			Placed = Instance.new("Part")
		elseif v.Name == "Truss" then
			Placed = Instance.new("TrussPart")
		elseif v.Name == "Wedge" then
			Placed = Instance.new("WedgePart")
		elseif v.Name == "CornerWedge" then
			Placed = Instance.new("CornerWedgePart")
		end
		
		Placed.Name = "Part"
		Placed.CFrame = CFrame.new(table.unpack(game:GetService('HttpService'):JSONDecode('['..v.CFrame..']')))
		Placed.Size = Vector3.new(v.Size.x,v.Size.y,v.Size.z)
		Placed.Color = Color3.new(v.Color.r,v.Color.g,v.Color.b)
		Placed.Material = Enum.Material[v.Material] or Enum.Material.SmoothPlastic
		Placed.Anchored = v.Anchored
		Placed.CanCollide = v.CanCollide
		--
		Placed.Transparency = 0.6
		Placed.CastShadow = false
		--
		Placed.Parent = PartsParent
		
	end
	return PartsParent
end

function shared._DEK:Load(Operator:Player,Inventor:number,Slot:number) -- Operator of command, Inventor/Owner of the build, Inventor's build save slot

	if not (Operator or Inventor) then -- to lazy to make this shit actually useful info on the user end
		return
	end

	local Parts = shared._DEK:GetStore(Inventor,Slot)
	
	if Parts then
	
		local PartsFolder = shared._DEK:LoadParts(Parts)
		
		PartsFolder.Parent = Operator.PlayerGui
		task.wait(1)
		
		shared._DEK:ClientCode(Operator,[["
			game.Players.LocalPlayer.PlayerGui.TempBuilds.Parent = workspace
		"]])
		
	end
	
end
