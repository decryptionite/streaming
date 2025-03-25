--!nonstrict
--[[

/*

	* unlocked_buildload.lua
	* Dekryptionite
	* 01/22/2025
	
*/

	The only valid reasons to clear a build from the database is either chain-crashing or a build that can lead to the game being terminated
	All useful functions are global and can be used in your require() script
	
	THIS VERSION IS OUTDATED! YOU ARE USING VERSION 1.
]]

if shared._DEK then
	print("Dekryptionite: Someone has already loaded the script! Use shared._DEK:Load()\n")
	return
end
if not game:GetService("RunService"):IsServer() then
	print("Dekryptionite: This script will not work on a client environment!\n")
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

local function CreateGui()
	-- Instances
	local Screen = Instance.new("ScreenGui")
	local Frame = Instance.new("Frame")
	local TopText = Instance.new("TextLabel")
	local Watermark = Instance.new("TextLabel")
	local Output = Instance.new("TextBox")
	
	Frame.Parent = Screen
	TopText.Parent = Frame
	Watermark.Parent = Frame
	Output.Parent = Frame
	
	-- Properties
		-- Frame
			Frame.AnchorPoint = Vector2.new(0.5,0.5)
			Frame.Position = UDim2.new(0.5,0,0.5,0)
			Frame.Size = UDim2.new(0,500,0,272) -- Scale is for FAGGOTS!!!!!
			Frame.Style = Enum.FrameStyle.RobloxRound
		-- TopText 
			TopText.AnchorPoint = Vector2.new(0.5,0.5)
			TopText.BackgroundTransparency = 1
			TopText.Position = UDim2.new(0.5,0,0.2,0)
			TopText.Size = UDim2.new(0,467,0,107)
			TopText.FontFace = Font.fromName("Armino")
			TopText.FontFace.Weight = Enum.FontWeight.Bold
			TopText.Text = "Copy and paste the bottom output into Notepad!"
			TopText.TextColor3 = Color3.new(255,255,255)
			TopText.TextScaled = true
		-- Watermark
			Watermark.BackgroundTransparency = 1
			Watermark.Position = UDim2.new(-0.08,0,0.93,0)
			Watermark.Size = UDim2.new(0,150,0,30)
			Watermark.FontFace = Font.fromName("Armino")
			Watermark.FontFace.Weight = Enum.FontWeight.Bold
			Watermark.Text = "Dekryptionite"
			Watermark.TextColor3 = Color3.new(255,255,255)
			Watermark.TextSize = 14
		-- Output
			Output.AnchorPoint = Vector2.new(0.5,0.5)
			Output.BackgroundColor3 = Color3.new(0,0,0)
			Output.BorderColor3 = Color3.new(255,0,0)
			Output.BorderSizePixel = 2
			Output.ClearTextOnFocus = false
			Output.Position = UDim2.new(0.5,0,0.7,0)
			Output.Size = UDim2.new(0,400,0,70)
			Output.FontFace = Font.fromName("Armino")
			Output.PlaceholderColor3 = Color3.new(255,255,255)
			Output.PlaceholderText = "Output"
			Output.TextColor3 = Color3.new(255,255,255)
			
	
	return Screen
	
end

shared._DEK.TEMP = {} -- do not rely on these functions

function shared._DEK.TEMP:GuiSave(Operator:Player,Inventor:number,Slot:number)

	if not (Operator or Inventor) then
		return
	end

	local RemoteParts = shared._DEK:GetStore(Inventor,Slot)
	if RemoteParts then
		local PartsString = game.HttpService:JSONEncode(RemoteParts)
		
		local GUI = CreateGui()
		if #PartsString > 200000 then
			GUI.Frame.TextBox.Text = "Large strings are yet to be implemented"
		else
			GUI.Frame.TextBox.Text = PartsString
		end
		GUI.Parent = Operator.PlayerGui
		
		task.wait(15)
		
		GUI:Destroy()
		
	end

end
