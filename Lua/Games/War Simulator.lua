local function LoadFromRepo(Folder, FileName)
    return loadstring(game:HttpGet(("https://raw.githubusercontent.com/EpicThing/Epic-Thing/main/Lua/%s/%s.lua"):format(Folder, FileName)))()
end

LoadFromRepo("Utilities", "Init")

local Library = LoadFromRepo("Utilities", "Library")

local Window = Library:Window("War Simulator")

local MainCheats = Window:Tab("Cheats")

local Combat = MainCheats:Section("Combat")
local Autofarm = MainCheats:Section("Autofarm")
local Upgrade = MainCheats:Section("Auto Upgrade")
local GunMod = MainCheats:Section("Gun Mods")

local LocalPlayer = game:GetService("Players").LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local FireBullet = require(ReplicatedStorage.UsefulModules.NewBulletCaster)
local Basic = ReplicatedStorage.BulletFunctions.Basic
local Remotes = ReplicatedStorage.Remotes
local GunData = require(ReplicatedStorage.GunData)

local GunModsEnabled = false
local DoAutoStage = false
local AutoRebirth = false
local AutoKill = false
local OriginalGunInfo = {}
local AnticheatDisabled = false

local GunModMap = {
    ["Infinite Ammo"] = {Toggled = false, ModIndex = "mag", ModValue = math.huge},
    ["Rapid Fire"] = {Toggled = false, ModIndex = "fire_rate", ModValue = math.huge},
    ["No Spread"] = {Toggled = false, ModIndex = "spread", ModValue = 0},
    ["No Recoil"] = {Toggled = false, ModIndex = "recoil", ModValue = function() end}
}

local FireMode = "auto"
local ShootVolume = false
local ShootSound = 6029210056

local function GetModData()
    local ModData = {}

    for Index, Value in next, GunModMap do 
        if Value.Toggled then 
            ModData[Value.ModIndex] = Value.ModValue 
        end 
    end

    ModData["fire_sound"] = ShootSound
    ModData["fire_mode"] = FireMode 

    return ModData
end

local function ApplyGunMods(Gun, Disable, Mods)
    local Connection = getconnections(Gun.Equipped)[1]

    if not Connection then
        wait()
        return ApplyGunMods(Gun, Disable, Mods)
    end 

    local EquippedFunction = Connection.Function
    local GunData = debug.getupvalue(EquippedFunction, 2)

    if not OriginalGunInfo[Gun.Name] then
        OriginalGunInfo[Gun.Name] = {}

        for Index, Value in next, GunData do 
            OriginalGunInfo[Gun.Name][Index] = Value
        end
    end

    if AnticheatDisabled ~= Gun then
        AnticheatDisabled = Gun

        local ENV = getfenv(EquippedFunction)
        local OldPcall = ENV.pcall
        
        ENV.pcall = function(f)
            if table.find(debug.getconstants(f), 300) then
                return 
            end
            return OldPcall(f)
        end

        setfenv(EquippedFunction, ENV)
    end

    if not Disable then 
        for Index, Value in next, GunData do 
            local NewValue = Mods[Index]
    
            if NewValue then 
                GunData[Index] = NewValue

                if Index == "mag" then 
                    debug.setupvalue(debug.getupvalue(EquippedFunction, 7), 2, NewValue)
                end 
            end
        end

        debug.setupvalue(EquippedFunction, 2, GunData)
    else 
        if Mods then
            for Index, Value in next, Mods do 
                local NewValue = OriginalGunInfo[Gun.Name][Value]

                if NewValue then
                    GunData[Value] = NewValue
                end

                if Value == "mag" then 
                    debug.setupvalue(debug.getupvalue(EquippedFunction, 7), 2, OriginalGunInfo[Gun.Name]["mag"])
                end 
            end

            debug.setupvalue(EquippedFunction, 2, GunData)
        else
            for Index, Value in next, OriginalGunInfo[Gun.Name] do 
                GunData[Index] = Value
            end

            debug.setupvalue(EquippedFunction, 2, GunData)

            if GunModMap["Infinite Ammo"]["Toggled"] then 
                debug.setupvalue(debug.getupvalue(EquippedFunction, 7), 2, OriginalGunInfo[Gun.Name]["mag"])
            end
        end
    end
end

Autofarm:Toggle("Enabled", false, function(Value)
    AutoKill = Value
end)
Autofarm:Toggle("Auto Next Stage", false, function(Value)
    DoAutoStage = Value
end)
Autofarm:Toggle("Auto Rebirth", false, function(Value)
    AutoRebirth = Value
end)

GunMod:Toggle("Enabled", false, function(Value)
    GunModsEnabled = Value

    if Value then 
        local CurrentGun = LocalPlayer.Character:FindFirstChildOfClass("Tool")

        if CurrentGun then 
            ApplyGunMods(CurrentGun, false, GetModData())
        end 
    else 
        local CurrentGun = LocalPlayer.Character:FindFirstChildOfClass("Tool")

        if CurrentGun then 
            ApplyGunMods(CurrentGun, true)
        end 
    end
end)

for ModName, ModData in next, GunModMap do 
    GunMod:Toggle(ModName, false, function(Value)
        GunModMap[ModName]["Toggled"] = Value 
    
        if GunModsEnabled then
            if Value then 
                local CurrentGun = LocalPlayer.Character:FindFirstChildOfClass("Tool")
    
                if CurrentGun then 
                    ApplyGunMods(CurrentGun, false, {[ModData.ModIndex] = ModData.ModValue})
                end 
            else 
                local CurrentGun = LocalPlayer.Character:FindFirstChildOfClass("Tool")
    
                if CurrentGun then 
                    ApplyGunMods(CurrentGun, true, {ModData.ModIndex})
                end 
            end
        end
    end)
end

GunMod:Toggle("Loud Shoot Sound", false, function(Value)
    ShootVolume = Value
end)

GunMod:Box("Shoot Sound ID", "6029210056", function(Value)
    if not tonumber(Value) then
        return Window:Notification("Error", {Text = "Sound ID must be a number!", ConfirmText = "Okay"})
    end

    ShootSound = Value

    if GunModsEnabled then
        if Value then 
            local CurrentGun = LocalPlayer.Character:FindFirstChildOfClass("Tool")

            if CurrentGun then 
                ApplyGunMods(CurrentGun, false, {fire_sound = tonumber(Value)})
            end 
        else 
            local CurrentGun = LocalPlayer.Character:FindFirstChildOfClass("Tool")

            if CurrentGun then 
                ApplyGunMods(CurrentGun, true, {"fire_sound"})
            end 
        end
    end
end)

GunMod:Picker("Fire Mode", {"auto", "semi"}, "auto", function(Value)
    FireMode = Value 

    if GunModsEnabled then
        if Value then 
            local CurrentGun = LocalPlayer.Character:FindFirstChildOfClass("Tool")

            if CurrentGun then 
                ApplyGunMods(CurrentGun, false, {fire_mode = Value})
            end 
        else 
            local CurrentGun = LocalPlayer.Character:FindFirstChildOfClass("Tool")

            if CurrentGun then 
                ApplyGunMods(CurrentGun, true, {"fire_mode"})
            end 
        end
    end
end)

local DoAutoUpgrade = false
local Upgrades = {
    melee = false,
    ranged = false,
    armor = false,
    explosives = false
}

Upgrade:Toggle("Auto Upgrade", nil, function(Value)
    DoAutoUpgrade = Value
end)

for Index, Value in next, Upgrades do
    Upgrade:Toggle(Index, nil, function(Value)
        Upgrade[Index] = Value
    end)
end

local SilentAim = false

Combat:Toggle("Silent Aim", false, function(Value)
    SilentAim = Value
end)

Combat:Toggle("Wall Bang", false, function(Value)
    WallBang = Value
end)

local CurrentGun = LocalPlayer.Character:FindFirstChildOfClass("Tool")

if CurrentGun and GunModsEnabled then 
    ApplyGunMods(CurrentGun, false, GetModData())
end 

LocalPlayer.Character.ChildAdded:Connect(function(Child)
    if Child:IsA("Tool") and GunModsEnabled then
        ApplyGunMods(Child, false, GetModData())
    end
end)

LocalPlayer.CharacterAdded:Connect(function(Character)
    Character.ChildAdded:Connect(function(Child)
        if Child:IsA("Tool") and GunModsEnabled then
            ApplyGunMods(Child, false, GetModData())
        end
    end)
end)

local function GetBestMob()
    local Last = math.huge
    local Nearest

    for Index, Value in next, workspace.MapAreas.GetChildren(workspace.MapAreas) do
        if #Value.Mobs.GetChildren(Value.Mobs) > 0 then
            for Index, Mob in next, Value.Mobs.GetChildren(Value.Mobs) do
                if Mob.FindFirstChild(Mob, "HumanoidRootPart") and Mob.FindFirstChild(Mob, "Humanoid") and Mob.Humanoid.Health > 0 then
                    local Distance = (LocalPlayer.Character.HumanoidRootPart.Position - Mob.HumanoidRootPart.Position).Magnitude
                    if Distance < Last then
                        Nearest = Mob
                        Last = Distance
                    end
                end
            end
        end
    end

    return Nearest
end

local function GetMostExpensiveMob()
    local Team = LocalPlayer.Team.Name:gsub("%s+", "")
    local Last = 0
    local Best

    for Index, Value in next, workspace.MapAreas:GetChildren() do
        if Value:FindFirstChild("Stage") and tostring(Value.Stage.Value) == Team then
            for Index, Mob in next, Value.Mobs:GetChildren() do
                if Mob:FindFirstChild("HumanoidRootPart") and Mob:FindFirstChild("Humanoid") and Mob:FindFirstChild("MoneyValue") and Mob.Humanoid.Health > 0 then
                    if Mob.MoneyValue.Value > Last then
                        Last = Mob.MoneyValue.Value
                        Best = Mob
                    end
                end
            end
        end
    end

    return Best
end

local function Shoot(Position)
    local Gun = LocalPlayer.Character:FindFirstChildOfClass("Tool")

    if Gun and Gun:FindFirstChild("Nodes") then
        local BarrelPosition = Gun.Nodes.Barrel.CFrame.Position

        local Arguments = {
            false,
            BarrelPosition,
            (Position - BarrelPosition).Unit * 9e9,
            Basic,
            1090,
            1,
            2,
            9e9
        }
        
        syn.set_thread_identity(2)
        FireBullet(unpack(Arguments))
        syn.set_thread_identity(7)
    end
end

local function GetCheapestLockedGun(Type)
    local Purchases = Remotes.Get:InvokeServer("purchases")
    local Money = LocalPlayer.PlayerGui.WarMainUI.Money.Stat.val.Value
    local CheapestLockedGun
    local CheapestPrice = math.huge

    local Team = LocalPlayer.Team.Name:gsub("%s+", "")

    for Index, Gun in next, GunData()[Type][Team] do
        if not Purchases[Index] and Money >= Gun.price then
            if Gun.price < CheapestPrice then 
                CheapestPrice = Gun.price
                CheapestLockedGun = Index 
            end
        end 
    end

    return CheapestLockedGun
end

local function GetTableInfo(CountTbl, Tbl)
    local Count = 1

    for Index, Value in next, Tbl do
        if Count == CountTbl then
            return Value.StageName
        end

        Count = Count + 1
    end
end

local function GetInfo(Name, Tbl)
    local Count = 1

    for Index, Value in next, Tbl do
        if Value.StageName == Name then
            return GetTableInfo(Count + 1, Tbl)
        end 

        Count = Count + 1
    end
end

local OldNamecall
OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local Args = {...}

    if ShootVolume and tostring(self) == "Event" and getnamecallmethod() == "Fire" and #Args >= 3 then
        Args[3].functiondata[2].MaxDistance = math.huge
        Args[3].functiondata[2].Volume = math.huge
    end

    if (SilentAim or WallBang or AutoKill) and getnamecallmethod() == "FindPartOnRayWithIgnoreList" then
        local CallingScript = tostring(getcallingscript())

        if CallingScript == "NewBulletCaster" or CallingScript == "CastBullet" then
            local Mob = GetBestMob()

            if SilentAim or AutoKill then
                Args[1] = Ray.new(workspace.CurrentCamera.CFrame.Position, (Mob.Head.Position - workspace.CurrentCamera.CFrame.Position))
            end

            if WallBang or AutoKill then
                table.insert(Args[2], workspace.Terrain)
                table.insert(Args[2], workspace.Stages)
                table.insert(Args[2], workspace.SmallMapDetails)
            end
        end
    end
    
    return OldNamecall(self, unpack(Args))
end)

local BodyPartIndex = 1

RunService.Heartbeat:Connect(function()
    if AutoKill then 
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            local Tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            local IsGun = Tool and Tool:FindFirstChild("Mod") ~= nil 

            if not IsGun then 
                for Index, Value in next, LocalPlayer.Backpack:GetChildren() do 
                    if Value:FindFirstChild("Mod") then 
                        LocalPlayer.Character.Humanoid:EquipTool(Value)
                    end
                end
            end
        end

        local Mob = GetMostExpensiveMob()

        if LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and Mob and Mob:FindFirstChild("HumanoidRootPart") and Mob:FindFirstChild("Humanoid") and Mob.Humanoid.Health > 0 then
            local BodyPart = BodyPartIndex == 1 and Mob.Head or Mob.HumanoidRootPart
            
            Shoot(BodyPart.Position)

            BodyPartIndex = BodyPartIndex + 1

            if BodyPartIndex == 3 then 
                BodyPartIndex = 1
            end
        end
    end
end)

while wait() do
    local Team = LocalPlayer.Team.Name:gsub("%s+", "")
    local Money = LocalPlayer.PlayerGui.WarMainUI.Money.Stat.val.Value

    if DoAutoUpgrade then
        for Index, Value in next, Upgrades do
            local Name = GetCheapestLockedGun(Index)
            if Team and Name then
                local OldCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                LocalPlayer.Character.HumanoidRootPart.CFrame = workspace.Stages[Team].Spawns.Part.CFrame
                wait(0.3)

                local DidBuy = Remotes.Buy:InvokeServer(tostring(Index), {
                    stage = Team,
                    name = Name
                })

                if DidBuy then
                    Remotes.Equip:InvokeServer(Name, Index)
                end

                LocalPlayer.Character.HumanoidRootPart.CFrame = OldCFrame
            end
        end
    end

    if DoAutoStage then
        local ClonedTable = {}
        local TableIndex = 1

        for Index, Value in next, GunData().stages do 
            Value.StageName = Index
            ClonedTable[TableIndex] = Value 

            TableIndex = TableIndex + 1
        end 

        table.sort(ClonedTable, function(a, b)
            return a.price < b.price
        end)

        local BuyTeam = GetInfo(Team, ClonedTable)

        if BuyTeam and Money >= GunData()["stages"][BuyTeam].price then
            local OldCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
            LocalPlayer.Character.HumanoidRootPart.CFrame = workspace.Stages[Team].Spawns.Part.CFrame
            wait(0.3)

            Remotes.Buy:InvokeServer("stages", {
                stage = BuyTeam
            })
            
            LocalPlayer.Character.HumanoidRootPart.CFrame = workspace.Stages[BuyTeam].Spawns.Part.CFrame + Vector3.new(0, 10, 40)
        end
    end

    if AutoRebirth then
        local ClonedTable = {}
        local TableIndex = 1

        for Index, Value in next, GunData().rebirth do 
            Value.StageName = Index
            ClonedTable[TableIndex] = Value 

            TableIndex = TableIndex + 1
        end 

        table.sort(ClonedTable, function(a, b)
            return a.price < b.price
        end)

        local BuyRebirth = GetInfo(Team, ClonedTable)

        if BuyRebirth and Money > GunData()["rebirth"][BuyRebirth].price then
            Remotes.RebirthSend:InvokeServer(BuyRebirth)
        end
    end
end
