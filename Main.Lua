Tool = script.Parent
Handle = Tool:WaitForChild("Handle")

Players = game:GetService("Players")
Debris = game:GetService("Debris")
RunService = game:GetService("RunService")
BuffFolder = game:GetService("ServerScriptService"):FindFirstChild("PlayerBuff")
remoteReload = Tool:WaitForChild("ReloadRequest")

local Character
local Humanoid
local Player
local sound = game:GetService("ReplicatedStorage"):WaitForChild("PlaySound")
local debounce = false
local COOLDOWN = Tool:GetAttribute("Cooldown")
local MAXAMMO = Tool:GetAttribute("MaxAmmo")
Tool:SetAttribute("CurrentAmmo", MAXAMMO)
local DAMAGE = Tool:GetAttribute("Damage")
local RELOADRATE = Tool:GetAttribute("ReloadRate")
local SPREAD = Tool:GetAttribute("Spread") -- In Degrees
local CANHEADSHOT = Tool:GetAttribute("CanHeadshot")
local HEADSHOT = Tool:GetAttribute("HeadshotMultiplier")
local remote = Tool:WaitForChild("GunfireRemote")
local IdleAnim = script:WaitForChild("Holding")
local ReloadAnim = script:WaitForChild("Reload")
local SweepAnim = script:WaitForChild("Sweep")
local ImpactSFX = game:GetService("ReplicatedStorage"):FindFirstChild("ImpactSFX")
local Buffs = {}
local StancePas
local StanceAct
local StanceSweep
local loadedAnims = false
local details = game:GetService("ReplicatedStorage").Details

for i, x in pairs(Tool.AppliedBuffs:GetChildren()) do
	Buffs[i] = x.Name
end

ToolEquipped = false
Tool.Enabled = true

if script.Parent:GetAttribute("CanScope") == false then
	Tool.Scope:Destroy()
end

function detailsMeter(incDMG)
	local dpsfolder = details:FindFirstChild("DetailsTracker"..Player.Name)
	local tracker
	if not dpsfolder:FindFirstChild(Tool.Name) then
		tracker = Instance.new("NumberValue")
		tracker.Name = Tool.Name
		tracker.Parent = dpsfolder
	else
		tracker = dpsfolder:FindFirstChild(Tool.Name)
	end
	tracker.Value += incDMG
end

--Main
function Attack(lv)
	if Humanoid and Humanoid.Health > 0 and debounce == false and Tool:GetAttribute("Reloading") == false then
		debounce = true
		local distance = (lv - Handle.Position).Magnitude
		if ToolEquipped == true and Tool:GetAttribute("Reloading") == false then
			if Tool:GetAttribute("CurrentAmmo") <= 0 and Tool:GetAttribute("Reloading") == false and Tool:GetAttribute("GunEquipped") == true then
				--Reloading	
				Reload()
			else
				--Firing
				Tool:SetAttribute("CurrentAmmo", Tool:GetAttribute("CurrentAmmo") - 1)
				--Sound
				task.spawn(SFX)
				--Animation
				StanceSweep:Play()
				--Raycast shot position
				local Start = Tool.Handle.BarrelPoint.WorldCFrame.Position
				local Direction = (CFrame.new(Start,lv) * CFrame.Angles(math.rad(-SPREAD+(math.random()*(SPREAD*2))),math.rad(-SPREAD+(math.random()*(SPREAD*2))),0)).LookVector
				local Hit,EndPos = RayCast(Start,Direction,5000,Player.Character)
				--Flash
				task.spawn(VFX)
				--Shot landed
				if Hit then
					--Living Target
					local Victim = Hit.Parent:FindFirstChild("Humanoid")
					if Victim and Victim.Parent.Name ~= "_DESTRUCTABLE" then
						sound:FireClient(Player, 0, 5)
						--If Headshots are Enabled
						if Hit.Name == "Head" and CANHEADSHOT == true then
							if game.Players:FindFirstChild(Victim.Parent.Name) and game.Players:FindFirstChild(Victim.Parent.Name).Team.Name == "Zombies" then
								local dmgCalc = (DAMAGE+math.random(-1,1)) * HEADSHOT * (game:GetService("ServerScriptService"):FindFirstChild("PlayerBuff"):FindFirstChild("BuffTracker"..Victim.Parent.Name):FindFirstChild("Incoming Dmg Multiplier").Value) 
								Victim:TakeDamage(dmgCalc)
								task.spawn(detailsMeter, dmgCalc)
							elseif Victim.Parent.Name ~= "_DESTRUCTABLE" and not game.Players:FindFirstChild(Victim.Parent.Name) then
								Victim:TakeDamage((DAMAGE+math.random(-1,1)) * HEADSHOT)
							end
						--If Headshots are disabled or just a Body Shot
						else
							if game.Players:FindFirstChild(Victim.Parent.Name) and game.Players:FindFirstChild(Victim.Parent.Name).Team.Name == "Zombies" then
								local dmgCalc = (DAMAGE+math.random(-1,1)) * (game:GetService("ServerScriptService"):FindFirstChild("PlayerBuff"):FindFirstChild("BuffTracker"..Victim.Parent.Name):FindFirstChild("Incoming Dmg Multiplier").Value)
								Victim:TakeDamage(dmgCalc)
								task.spawn(detailsMeter, dmgCalc)
							elseif Victim.Parent.Name ~= "_DESTRUCTABLE" and not game.Players:FindFirstChild(Victim.Parent.Name) then
								Victim:TakeDamage(DAMAGE+math.random(-1,1))
							end
						end
						--Tag Credit
						task.spawn(TagHumanoid, Victim, Player)
						--Apply Buffs/Debuffs
						task.spawn(ApplyEffect, Buffs, Victim.Parent.Name)
					--Breakable Glass
					elseif string.lower(Hit.Name) == "glass" then
						task.spawn(ShatterGlass, Hit)
					end
				end
				--Mark where shot landed
				task.spawn(DrawHit, EndPos, Hit)
			end
		end
	end
	if Tool:GetAttribute("CurrentAmmo") <= 0 and Tool:GetAttribute("Reloading") == false and Tool:GetAttribute("GunEquipped") == true then
		wait(COOLDOWN)
		Reload()
	else
		wait(COOLDOWN)
	end
	debounce = false
end

Tool.Enabled = true

function Activated(Player, lookvector)
	if not Tool.Enabled or not ToolEquipped or not CheckIfAlive() then
		return
	end
	Tool.Enabled = false
	Attack(lookvector)
	Tool.Enabled = true
end

function RayCast(Start,Direction,Range,Ignore)
	local Hit,EndPos = game.Workspace:FindPartOnRay(Ray.new(Start,Direction*Range),Ignore)
	if Hit then
		--print(Hit.Name)
		if (Hit.Transparency > 0.75
			or Hit.Name == "Handle"
			or Hit:IsA("Accessory")
			or string.lower(Hit.Name) == "water"
			or Hit.Name == "Bush1"
			or Hit.Name == "Bush2"
			or Hit.Name == "Hitscan"
			or Hit.Name == "BloodDrop"
			or Hit.Name == "PlagueCloud"
			or Hit.Name == "bazookaimpact"
			or Hit.Name == "ScarpPilePart"
			or (Hit.Parent:FindFirstChild("Humanoid") and Hit.Parent.Humanoid.Health == 0)) then
			Hit,EndPos = RayCast(EndPos+(Direction*.01),Direction,Range-((Start-EndPos).magnitude),Ignore)
		end
	end
	return Hit,EndPos
end

function TagHumanoid(humanoid, player)
	if humanoid:FindFirstChild("creator") then
		humanoid:FindFirstChild("creator"):Destroy()
	end
	local Creator_Tag = Instance.new("ObjectValue", humanoid)
	Creator_Tag.Name = "creator"
	Creator_Tag.Value = player
	Debris:AddItem(Creator_Tag, 5)
end

function ShatterGlass(Hit)
	--Temp part to host sound
	local tempSfx = Instance.new("Part")
	tempSfx.Parent = game.Workspace.CurrentMap.Junk
	tempSfx.Transparency = 1
	tempSfx.Anchored = true
	tempSfx.CanCollide = false
	tempSfx.Size = Vector3.new(.1, .1, .1)
	tempSfx.Position = Hit.Position
	game.Debris:AddItem(tempSfx,3)
	--Sound
	local sfx = ImpactSFX:FindFirstChild("Shatter"..math.random(1,3)):Clone()
	sfx.Parent = tempSfx
	sfx.PlaybackSpeed = Random.new():NextNumber(0.9,1)
	sfx:Play()
	--Particles
	local shards = script.Particle:Clone()
	shards.Parent = Hit
	shards:Emit(15)
	Hit.Transparency = 1
	if Hit:GetChildren(1) then
		for i, x in pairs (Hit:GetChildren()) do
			if x:IsA("Decal") then
				x.Transparency = 1
			end
			if x:IsA("SpotLight") then
				x.Enabled = false
			end
		end
	end
	Hit.CanCollide = false
	game.Debris:AddItem(Hit, 1)
end

function Reload(Player)
	Tool:SetAttribute("Reloading", true)
	Tool:SetAttribute("CurrentAmmo", 0)
	local tempMag = Tool.Handle.MagDump.EmptyMag:Clone()
	tempMag.Parent = game.Workspace.CurrentMap.Junk
	tempMag.Transparency = 0
	tempMag.Position = Tool.Handle.MagDump.WorldCFrame.Position
	tempMag.CanCollide = true
	game.Debris:AddItem(tempMag, 5)
	StanceAct:Play()
	Tool.Handle.Reload.PlaybackSpeed = Random.new():NextNumber(0.95,1.05)
	Tool.Handle.Reload:Play()
	wait(RELOADRATE)
	if Tool:GetAttribute("GunEquipped") == true and Tool:GetAttribute("Reloading") == true then
		Tool:SetAttribute("CurrentAmmo", MAXAMMO)
	end
	Tool:SetAttribute("Reloading", false)
end

function SFX()
	local s = Tool.Handle.Fire:Clone()
	s.Parent = Tool.Handle
	s.PlaybackSpeed = Random.new():NextNumber(0.85,1.1)
	s:Play()
	game.Debris:AddItem(s, 5)
end

function VFX()
	Tool.Handle.BarrelPoint.Flash:Emit(1)
	Tool.Handle.BarrelPoint.Light.Enabled = true
end

function DrawHit(Pos, Hit)
	local p = Instance.new("Part")
	p.Name = "Hitscan"
	p.CollisionGroup = "Fishing"
	p.Anchored = true
	p.Parent = game.Workspace.CurrentMap.Junk
	p.Size = Vector3.new(.2,.2,.2)
	p.Shape = Enum.PartType.Ball
	p.BrickColor = BrickColor.new("Really black")
	p.Position = Pos
	p.Transparency = 0.85
	game.Debris:AddItem(p, 2)
	if Hit then
		local d = script.Debris:Clone()
		d.Parent = p
		d.Color = ColorSequence.new(Hit.Color)
		if Hit.Parent:FindFirstChild("Humanoid") and Hit.Parent.Name ~= "_DESTRUCTABLE" then
			p.Transparency = 1
			local sb = ImpactSFX:FindFirstChild("flesh"..tostring(math.random(1,5))):Clone()
			sb.PlaybackSpeed = Random.new():NextNumber(0.8,0.95)
			sb.Parent = p
			sb:Play()
			local bld = game.ReplicatedStorage:FindFirstChild("Blood"):Clone()
			bld.Parent = p
			bld:Emit(math.random(3,7))
			game:GetService("Debris"):AddItem(bld, 4)
		elseif Hit.Material == Enum.Material.Grass or Hit.Material == Enum.Material.Ground or 
				Hit.Material == Enum.Material.Sand or Hit.Material == Enum.Material.Snow then
			local sb = ImpactSFX:FindFirstChild("dirt"..tostring(math.random(1,3))):Clone()
			sb.PlaybackSpeed = Random.new():NextNumber(0.5,0.8)
			sb.Parent = p
			sb:Play()
			d:Emit(math.random(3,7))
		elseif Hit.Material == Enum.Material.Wood or Hit.Material == Enum.Material.WoodPlanks then
			local sb = ImpactSFX:FindFirstChild("wood"..tostring(math.random(1,5))):Clone()
			sb.PlaybackSpeed = Random.new():NextNumber(0.85,1)
			sb.Parent = p
			sb:Play()
			d:Emit(math.random(3,7))
		elseif Hit.Material == Enum.Material.Brick or Hit.Material == Enum.Material.Concrete or 
				Hit.Material == Enum.Material.Asphalt or Hit.Material == Enum.Material.Basalt or 
				Hit.Material == Enum.Material.Cobblestone or Hit.Material == Enum.Material.Marble or 
				Hit.Material == Enum.Material.Limestone or Hit.Material == Enum.Material.Pavement or 
				Hit.Material == Enum.Material.Slate or Hit.Material == Enum.Material.Rock or 
				Hit.Material == Enum.Material.Sandstone or Hit.Material == Enum.Material.Granite then
			local sb = ImpactSFX:FindFirstChild("concrete"..tostring(math.random(1,5))):Clone()
			sb.PlaybackSpeed = Random.new():NextNumber(0.8,1)
			sb.Parent = p
			sb:Play()
			d:Emit(math.random(3,7))
		elseif Hit.Material == Enum.Material.CorrodedMetal or Hit.Material == Enum.Material.DiamondPlate or Hit.Material == Enum.Material.Metal then
			local sb = ImpactSFX:FindFirstChild("metal"..tostring(math.random(1,4))):Clone()
			sb.PlaybackSpeed = Random.new():NextNumber(0.9,1.1)
			sb.Parent = p
			sb:Play()
			d:Emit(math.random(3,7))
		else
			local sb = ImpactSFX:FindFirstChild("else"):Clone()
			sb.PlaybackSpeed = Random.new():NextNumber(0.8,1.1)
			sb.Parent = p
			sb:Play()
			d:Emit(math.random(3,7))
		end	
	end
end

--Would not suggest more than 1 or 2 effects
function ApplyEffect(Buffs, Victim)
	for i, x in ipairs (Buffs) do
		if game.Players:FindFirstChild(Victim) and game.Players:FindFirstChild(Victim).Team.Name == "Zombies" then
			if not BuffFolder:FindFirstChild("BuffTracker"..Victim):FindFirstChild("List"):FindFirstChild(Buffs[i]) and BuffFolder:FindFirstChild("BuffTracker"..Victim) then
				game:GetService("ReplicatedStorage"):FindFirstChild("Buffs"):FindFirstChild(Buffs[i]):Clone().Parent = BuffFolder:FindFirstChild("BuffTracker"..Victim):FindFirstChild("List")	
			end
		end
	end
end

function WeldToBack(bool)
	if bool == false then
		if Player.Character ~= nil then
			if not Player.Character:FindFirstChild("BACKWELDRANGED") then
				local torso = Player.Character:FindFirstChild("Torso")
				if torso ~= nil then
					local model = Instance.new("Model")
					model.Name = "BACKWELDRANGED"
					model.Parent = Player.Character

					local weapClone = Instance.new("Part")
					local mesh = Instance.new("SpecialMesh")
					mesh.Parent = weapClone
					mesh.MeshId = Tool.Handle.Mesh.MeshId
					mesh.TextureId = Tool.Handle.Mesh.TextureId
					mesh.VertexColor = Tool.Handle.Mesh.VertexColor
					mesh.Scale = Tool.Handle.Mesh.Scale
					weapClone.Color = Tool.Handle.Color
					weapClone.Size = Tool.Handle.Size
					weapClone.CanCollide = false
					weapClone.Name = "Item"
					weapClone.Parent = model
					weapClone.Massless = true

					local weld = Instance.new("Weld")
					weld.Name = "BackWeld"
					weld.Part0 = torso
					weld.Part1 = weapClone
					weld.C0 = CFrame.new(0,0,0.6)
					weld.C0 = weld.C0 * CFrame.fromEulerAnglesXYZ(math.rad(-90),math.rad(30),math.rad(90))
					weld.Parent = weapClone
				end
			else
				Player.Character:FindFirstChild("BACKWELDRANGED").Item.Transparency = 0
			end
		end
	elseif bool == true then
		if Player.Character:FindFirstChild("BACKWELDRANGED") then
			Player.Character:FindFirstChild("BACKWELDRANGED").Item.Transparency = 1
		end
	end
end

function CheckIfAlive()
	return (((Player and Player.Parent and Character and Character.Parent and Humanoid and Humanoid.Parent and Humanoid.Health > 0 and Torso and Torso.Parent) and true) or false)
end

function Equipped()
	Character = Tool.Parent
	Player = Players:GetPlayerFromCharacter(Character)
	script.Parent.AmmoUI.Enabled = true
	WeldToBack(true)
	Humanoid = Character:FindFirstChildOfClass("Humanoid")
	Torso = Character:FindFirstChild("Torso") or Character:FindFirstChild("HumanoidRootPart")
	if not CheckIfAlive() then
		return
	end
	ToolEquipped = true
	Tool:SetAttribute("GunEquipped", true)
	if loadedAnims == false then
		loadedAnims = true
		StancePas = Humanoid.Animator:LoadAnimation(IdleAnim)
		StanceAct = Humanoid.Animator:LoadAnimation(ReloadAnim)
		StanceSweep = Humanoid.Animator:LoadAnimation(SweepAnim)
	end
	StancePas:Play()
	Tool.Handle.Unsheath:Play()
	
end

function Unequipped()
	StancePas:Stop()
	if StanceAct then 
		StanceAct:Stop()
	end
	ToolEquipped = false
	Tool:SetAttribute("GunEquipped", false)
	Tool:SetAttribute("Reloading", false)
	WeldToBack(false)
end

remote.OnServerEvent:Connect(Activated)
Tool.Equipped:Connect(Equipped)
Tool.Unequipped:Connect(Unequipped)
remoteReload.OnServerEvent:Connect(Reload)
