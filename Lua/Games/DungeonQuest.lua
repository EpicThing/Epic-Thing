  local function LoadFromRepo(Folder, FileName)
    return loadstring(game:HttpGet(("https://raw.githubusercontent.com/EpicThing/Epic-Thing/main/Lua/%s/%s.lua"):format(Folder, FileName)))()
end

LoadFromRepo("Utilities", "Init")

local library = LoadFromRepo("Utilities", "Library")
local Window = library:Window("Dungeon Quest")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("remotes")

local Local = Window:Tab("Local")
local Dungeon = Window:Tab("Dungeon")

local Character = Local:Section("Character")
local AntiReport = Local:Section("Anti Report")
local Trolling = Local:Section("Trolling")
local Autosell = Local:Section("Auto Sell")
local AutoSkill = Local:Section("Auto Skill")

local ManualFarm = Dungeon:Section("Manual Farm")

local WalkSpeed = 16
local JumpPower = 25

Character:Slider("Walk Speed", {min = 0, max = 35, default = 16}, function(value)
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.WalkSpeed = value 
    end

    WalkSpeed = value
end)

Character:Slider("Jump Height", {min = 0, max = 65, default = 25}, function(value)
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.JumpPower = value 
    end

    JumpPower = value
end)

AntiReport:Button("Hide Nametag", function()
    if player.Character and player.Character:FindFirstChild("playerNameplate") then 
        player.Character.playerNameplate:Destroy()
    end
end)

AntiReport:Toggle("Stream Mode", false, function(value)
    if player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("playerStatus") then
        player.PlayerGui.playerStatus.Enabled = not value
    end
end)

local AllPlayers = {}

for Index, Plr in next, Players:GetPlayers() do 
    if Plr ~= player then
        table.insert(AllPlayers, Plr.Name)
    end
end

Trolling:SearchBox("Force Boss Raids Lobby Whitelist", AllPlayers, nil, function(value)
    local Lobby = workspace.bossLobbies:FindFirstChild(value)

    if Lobby and Lobby:FindFirstChild("whitelist") and not Lobby.whitelist:FindFirstChild(player.Name) then 
        local Whitelist = Instance.new("StringValue")
        Whitelist.Name = player.Name 
        Whitelist.Parent = Lobby.whitelist
    end
end, true)

local SellRarities = {
    legendary = false, 
    epic = false, 
    rare = false, 
    uncommon = false, 
    common = false
}

for i,v in next, {"legendary", "epic", "rare", "uncommon", "common"} do 
    Autosell:Toggle(v, false, function(value)
        SellRarities[v] = value
    end)
end

Autosell:Button("Sell", function()
    local Inventory = remotes.reloadInvy:InvokeServer()

    local SellItems = {
        ["ability"] = {},
        ["helmet"] = {},
        ["chest"] = {},
        ["weapon"] = {}
    }

    for i,v in next, Inventory do
        for k,x in next, v do
            if type(x) == "table" then
                local Class, Id = k:split("_")[1], k:split("_")[2]

                if SellRarities[x.rarity] == true and not x.equipped then 
                    table.insert(SellItems[Class], tonumber(Id))
                end
            end
        end
    end

    remotes.sellItemEvent:FireServer(SellItems)
end)

local Skills = {
    ["physicalPower"] = 0,
    ["spellPower"] = 0,
    ["stamina"] = 0
}

local Level = player.leaderstats.Level.Value

for i,v in next, Skills do 
    AutoSkill:Slider(i, {min = 0, max = Level - 1, default = 0}, function(value)
        Skills[i] = value
    end)
end

AutoSkill:Button("Spend Skill Points", function()
    for Skill, Amount in next, Skills do 
        if Amount > 0 then
            for Index = 1, Amount do 
                remotes.spendSkillPoint:FireServer(Skill)
            end
        end
    end
end)

ManualFarm:Toggle("Disable Borders", false, function(value)
    if workspace:FindFirstChild("borders") then 
        for Index, Border in next, workspace.borders:GetChildren() do 
            Border.CanCollide = not value 
        end
    end
end)

ManualFarm:Toggle("Auto Use Abilities", false)

ManualFarm:Toggle("Auto Swing", false)

Players.PlayerAdded:connect(function(plr)
    table.insert(AllPlayers, plr.Name)
end)

Players.PlayerRemoving:connect(function(plr)
    table.remove(AllPlayers, table.find(AllPlayers, plr.Name))
end)

player.CharacterAdded:Connect(function(Character)
    local Humanoid = Character:WaitForChild("Humanoid")
    Humanoid.WalkSpeed = WalkSpeed 
    Humanoid.JumpPower = JumpPower
end)

local SwordCooldown = false

game:GetService("RunService").Heartbeat:Connect(function()
    if library.flags["Auto Use Abilities"] then 
        for Index, Ability in next, player.Backpack:GetChildren() do 
            if Ability.cooldown.Value <= 0 then
                local Event = Ability:FindFirstChildOfClass("RemoteEvent")

                if Event then 
                    Event:FireServer()
                end
            end
        end
    end 

    if library.flags["Auto Swing"] and player.Character then 
        for Index, Child in next, player.Character:GetChildren() do
            if Child.ClassName == "Accessory" and Child:FindFirstChild("swing") and Child:FindFirstChild("attackSpeed") then
                if not SwordCooldown then 
                    SwordCooldown = true 
                    Child.swing:FireServer()
                    wait(Child.attackSpeed.Value / 10)
                    SwordCooldown = false
                end
            end
        end
    end
end)
