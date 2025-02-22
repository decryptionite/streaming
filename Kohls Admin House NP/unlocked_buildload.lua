--!nonstrict
--Dekryptionite 01/22/2025
--Dekryptionite 02/20/2025 You can now save builds
--Dekryptionite 02/21/2025 cleaned some shit up; didnt test in game prob doesnt even work lol

-- To-do: Incase of larger builds add a dynamic wait() and have it be cancellable
-- will clean up shit l8r, works pretty good 4 now

-- Do not overwrite people's builds unless they are making the game unplayable or violating ROBLOX rules in a way that will lead to BoasGameTest being terminated

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
local Solinium = game.ServerScriptService.goog

function shared._DEK:ClientCode(Player:Player,Code:string)

	local Loadstring = Solinium.Utilities.loadstring:Clone()
	local scr = Solinium.Utilities.Client:Clone()
	
	Loadstring.Parent = scr
	
	scr:WaitForChild("Exec").Value = Code
	scr.Parent = Player.PlayerGui
	scr.Enabled = true
	
end

function shared._DEK:GetStore(Inventor:number,Slot:number)

	if not Slot then -- You are attempting to get from the Kohls store
		return DStoreKohls:GetAsync(Inventor)
	end
	
	if Slot then -- You are attempting to get from a Person299 store slot
		local Store = DStore:GetDataStore(DStoreP299..Slot)
		return Store:GetAsync(Inventor)
	end
	
end

function shared._DEK:LoadParts(Parts:{},Client:boolean) 
	
	if not Parts then
		return
	end
	
	local PartsParent = {}
	
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
		if Client then
			Placed.Transparency = 0.6
			Placed.CastShadow = false
		end
		--
		table.insert(PartsParent, Placed)
		
	end
	return PartsParent
end

function shared._DEK:SaveParts(Parts:{},User:number,Slot:number) 
	-- If any developer for NP is reading this, please save the PartType instead of it's Name
	-- https://create.roblox.com/docs/reference/engine/enums/PartType
	
	if not Parts then
		return
	end
	
	local toSave = {}
	
	for i,v in Parts do
		
		if v:IsA("BasePart") and (v.Name == "Part" or v.Name == "CornerWedge" or v.Name == "Wedge" or v.Name == "Truss") then 
			
			table.insert(toSave,{
				Name = tostring(v.Name);
				CFrame = tostring(v.CFrame);
				Size = {
					x = v.Size.X;
					y = v.Size.Y;
					z = v.Size.Z;
				};
				Color = {
					r = v.Color.R;
					g = v.Color.G;
					b = v.Color.B;
				};
				Material = v.Material.Name;
				Anchored = v.Anchored;
				CanCollide = v.CanCollide;
			})
			
		end
		
	end
		
	local Success,Error = pcall(function()
		if Slot then
			local Store = DStore:GetDataStore(DStoreP299..Slot)
			Store:SetAsync(tostring(User),toSave)
		else -- Slot 0 (Kohls)
			DStoreKohls:SetAsync(tostring(User),toSave)
		end
	end)
	--
	if Success then
		print("Build data saved successfully for "..tostring(User))
	else
		warn("Failed to save build data for " ..tostring(User).. ": "..Error)
	end
	
end

local function BundleIt(Parts:{},Class:string,Name:string)

	local PartsParent = Instance.new(Class)
	PartsParent.Name = Name
	
	for i,v in Parts do
		v.Parent = PartsParent
	end
	
	return PartsParent
	
end

function shared._DEK:Load(Operator:Player,Inventor:number,Slot:number) -- Operator of command, Inventor/Owner of the build, Inventor's build save slot

	if not (Operator or Inventor) then -- to lazy to make this shit actually useful info on the user end
		return
	end
	
	local RemoteParts = shared._DEK:GetStore(Inventor,Slot)
	
	if RemoteParts then
		-- Place the parts on the server
		if Operator == game.Workspace then
			local Parts = shared._DEK:LoadParts(RemoteParts,false)
			
			for i,v in Parts do
				table.insert(_G.btoolsparts, v)
				v.Parent = game.Workspace
			end
			
			return
		end
		
		-- Place the parts on Operator's client
		if Operator:IsA("Player") then
			local Parts = shared._DEK:LoadParts(RemoteParts,true)
			local PartsFolder = BundleIt(Parts,"Folder","TempBuilds")
		
			PartsFolder.Parent = Operator.PlayerGui
		
			shared._DEK:ClientCode(Operator,"game.Players.LocalPlayer.PlayerGui:WaitForChild(\"TempBuilds\").Parent = game.Workspace")
			
		end
		
	end
	
end

function shared._DEK:Steal(Operator:Player,OperatorSlot:number,Victim:number,VictimSlot:number) -- fix 4 kohles (allow 0)
	
	if not (Operator or Victim) then
		return
	end
	
	local RemoteParts = shared._DEK:GetStore(Victim,VictimSlot)
	if RemoteParts then
		local StolenParts = shared._DEK:LoadParts(RemoteParts,false)
		
		shared._DEK:SaveParts(StolenParts,Operator.UserId,OperatorSlot)
		
	end
	
end

function shared._DEK:Delete(Inventor:number,Slot:number)
	-- DO NOT USE THIS FUNCTION
	local Success,Error = pcall(function()
		
		if Slot then -- Person299
			
			local Store = DStore:GetDataStore(DStoreP299..Slot)
			Store:RemoveAsync(Inventor)
		
		else -- Kohls
		
			DStoreKohls:RemoveAsync(Inventor)
			
		end
		
	end)
	
	if Success then
		print("Successfully removed build from "..Inventor)
	else
		warn("Failed to remove build from "..Inventor)
	end
end