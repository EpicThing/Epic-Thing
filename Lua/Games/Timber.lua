local function LoadFromRepo(Folder, FileName)
    return loadstring(game:HttpGet(("https://raw.githubusercontent.com/EpicThing/Epic-Thing/main/Lua/%s/%s.lua"):format(Folder, FileName)))()
end

LoadFromRepo("Utilities", "Init")

local library = LoadFromRepo("Utilities", "Library")

local Window = library:Window("Timber")

local MainCheats = Window:Tab("Cheats")

local Autofarm = MainCheats:Section("Autofarm")
local Upgrades = MainCheats:Section("Upgrades")
local UpgradeTypes = MainCheats:Section("Upgrade Types")
local Selling = MainCheats:Section("Selling")
local Misc = MainCheats:Section("Misc")

local LocalPlayer = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")

local DataModule = require(ReplicatedStorage.Modules.Data)
local Remotes = ReplicatedStorage.Communication.Remotes
local Bindables = ReplicatedStorage.Communication.Bindables
local Owner = workspace.Plots:WaitForChild(LocalPlayer:WaitForChild("Plot").Value)
Owner:WaitForChild("0_0")

local ChopTrees = false
local SellTrees = false
local ScaledSelling = false
local ManualSelling = false

Autofarm:Toggle("Auto Chop Trees", false, function(Value)
    ChopTrees = Value
end)

Selling:Toggle("Auto Sell Trees", false, function(Value)
    SellTrees = Value
end)
Selling:Toggle("Scaled Selling", false, function(Value)
    ScaledSelling = Value
end)
Selling:Slider("Manual Selling", {min = 0, default = 100, max = 10000}, function(Value)
    ManualSelling = Value
end)

Selling:Button("What is scaled selling?", function()
    Window:Notification("Message", {Text = "The code will calculate when you should sell, reducing the chance of you getting kicked", ConfirmText = "Okay"})
end)

local AutoUpgrade = false
local AutoExpand = false
local StopRebirth = false

Upgrades:Toggle("Auto Upgrade", false, function(Value)
    AutoUpgrade = Value
end)
Upgrades:Toggle("Auto Expand", false, function(Value)
    AutoExpand = Value
end)
Upgrades:Toggle("Stop Upgrading When Rebirth", false, function(Value)
    StopRebirth = Value
end)

local UpgradeType = {
    AxeStrength = false, Speed = false, 
    TreeGrowth = false, GoldenChance = false, 
    WCount = false, WStrength = false, 
    WSpeed = false, WLogs = false
}

for Index, Value in next, UpgradeType do
    UpgradeTypes:Toggle(Index, false, function(Value)
        UpgradeType[Index] = Value
    end)
end

local AutoRebirth = false
local AutoHoney = false
local AutoMission = false
local FastMode = false

Misc:Toggle("Auto Rebirth", false, function(Value)
    AutoRebirth = Value
end)
Misc:Toggle("Auto Collect Honey", false, function(Value)
    AutoHoney = Value
end)
Misc:Toggle("Auto Collect Missions", false, function(Value)
    AutoMission = Value
end)
Misc:Toggle("Fast Mode", false, function(Value)
    FastMode = Value
end)
Misc:Button("What is fast mode?", function()
    Window:Notification("Message", {Text = "The code will ignore all safety protocols, meaning you'll get trees really fast. The code will rejoin and re execute the script if you get kicked (the code will do this regardeless if you have this enabled or not)", ConfirmText = "Okay"})
end)

local function GetClosestTree(Furthest)
    local Closest
    local Distance = Furthest and 0 or math.huge

    for _, Value in next, Owner:GetChildren() do
        if Value.ClassName == "Model" and not Value:FindFirstChild("Sell") then
            for _, Tree in next, Value:GetChildren() do
                if Tree.ClassName == "Model" and Tree:FindFirstChild("Base") and Tree:FindFirstChild("MeshPart") then
                    local Magnitude = (Tree.Base.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude

                    if Furthest then
                        if Magnitude > Distance then 
                            Distance = Magnitude 
                            Closest = Tree 
                        end
                    else
                        if Magnitude < Distance then 
                            Distance = Magnitude 
                            Closest = Tree 
                        end
                    end
                end
            end
        end
    end
    
    return Closest
end

local function GetTreeCount()
    local TreeCount = 0

    for _, Value in next, Owner:GetChildren() do
        if Value.ClassName == "Model" and not Value:FindFirstChild("Sell") then
            TreeCount = TreeCount + 1
        end
    end

    return TreeCount * 3
end

local function GetHoneyPlot()
    for _, Value in next, Owner:GetChildren() do
        if Value.ClassName == "Model" and Value:FindFirstChild("Honey stuff") then
            return Value
        end
    end
end

local function RandomTeleport(Times, WaitTime)
    for Index = 1, Times do
        LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(math.random(-10, 10), 0, math.random(-10, 10)) --math.random(-10, 10)
        wait(WaitTime)
    end
end

for Index, Value in next, getconnections(LocalPlayer.Idled) do
    Value:Disable()
end

CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(Child)
    if Child:FindFirstChild("MessageArea") and Child.MessageArea:FindFirstChild("ErrorFrame") then
        TeleportService:Teleport(game.PlaceId)
    end
end)

RunService.Stepped:Connect(function()
    if ChopTrees and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(11)
    end
end)

local Count = 0

while wait(1) do
    coroutine.wrap(function()
        if not (StopRebirth and Owner["0_0"].Rebirth.Beam.Enabled) then
            local Coins = LocalPlayer.leaderstats.Coins.Value

            if AutoUpgrade then
                for Index, Value in next, LocalPlayer.PlayerGui.Main.UpgradeMenu.Main.Hold:GetChildren() do
                    if Value.ClassName  == "Frame" and UpgradeType[Value.Name] and Coins >= DataModule.GetCost(Value.Name, LocalPlayer.datastats:FindFirstChild(Value.Name).Value) then
                        Remotes.Upgrade:FireServer(tostring(Value.Name)) 
                    end
                end
            end
            
            if AutoExpand then
                for Index = -4, 4 do
                    for Index_ = -4, 4 do
                        local Name = tostring(Index) .. "_" .. tostring(Index_)

                        if not Owner:FindFirstChild(Name) then
                            Remotes.ExpandIsland:FireServer(Name)
                        end
                    end
                end
            end
        end
    end)()

    if ChopTrees then
        local ClosestTree = GetClosestTree()
        local CurrentTrees = GetTreeCount()
        local HoneyPlot = GetHoneyPlot()
        local SellCount = CurrentTrees * 15
        local WaitTree = CurrentTrees < 3 and 2 or CurrentTrees / 4

        if not ScaledSelling then
            SellCount = ManualSelling
        end
        
        if ClosestTree then
            repeat
                LocalPlayer.Character.HumanoidRootPart.CFrame = ClosestTree.Base.CFrame
                Remotes.HitTree:FireServer(LocalPlayer.Plot.Value, ClosestTree.Parent.Name, tonumber(ClosestTree.Name:split("_")[2]))
                wait()
            until not ChopTrees or not ClosestTree:IsDescendantOf(workspace) or not ClosestTree.Parent

            if ChopTrees then
                if not FastMode and Count > WaitTree / 4 then
                    local FurthestAwayTree = GetClosestTree(true)
                    if FurthestAwayTree then
                        RandomTeleport(WaitTree / 2, 0.35)
                        Count = 0
                    end
                end

                if SellTrees and LocalPlayer.leaderstats.Logs.Value >= SellCount then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = Owner["0_0"].Sell.CFrame
                    wait(0.3)
                end

                if HoneyPlot then
                    local Honey = tonumber(HoneyPlot.Jar.Lid.BillboardGui.Counter.Text:split("/")[1])
                    if AutoHoney and Honey == 30 then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = HoneyPlot.Jar.Lid.CFrame
                        wait(0.3)
                    end
                end 
    
                if AutoMission then
                    for Index = 1, 3 do
                        Bindables.CompleteMission:InvokeServer(Index)
                    end
                end
                
                if AutoRebirth and Owner["0_0"].Rebirth.Beam.Enabled and LocalPlayer.leaderstats.Coins.Value >= ((LocalPlayer.leaderstats.Rebirth.Value + 1) * 10000) then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = Owner["0_0"].Rebirth.CFrame 
                end

                Count = Count + 1
            end
        end
    end
end
