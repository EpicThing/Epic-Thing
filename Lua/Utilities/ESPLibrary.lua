local function LoadFromRepo(Folder, FileName)
    return loadstring(game:HttpGet(("https://raw.githubusercontent.com/EpicThing/Epic-Thing/main/Lua/%s/%s.lua"):format(Folder, FileName)))()
end

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera

local CIELUV = LoadFromRepo("Utilities", "CIELUV")
local HealthbarLerp = CIELUV:Lerp(Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 0))

local Fonts = {}

for Font, Number in next, Drawing.Fonts do
    table.insert(Fonts, Font)
end

local Visuals = {Players = {}, Flags = {
    ["Ally Color"] = Color3.new(0, 255, 0),
    ["Enemy Color"] = Color3.new(255, 0, 0),
    ["Use Team Color"] = false, 
    ["Team Check"] = false,
    ["Info Font"] = Fonts[1],
    ["Tracers"] = true,
    ["Boxes"] = true,
    ["Healthbar"] = true,
    ["Info"] = true,
    ["Extra Info"] = true
}}

local DrawingProperties = {
    Line = {
        Thickness = 1.5,
        Color = Color3.fromRGB(255, 255, 255),
        Visible = false
    },
    Text = {
        Size = 16,
        Center = true,
        Outline = true,
        Color = Color3.fromRGB(255, 255, 255),
        Visible = false
    },
    Square = {
        Thickness = 1.5,
        Filled = false,
        Color = Color3.fromRGB(255, 255, 255),
        Visible = false
    }
}

function Visuals:Round(Number)
    local VectorX, VectorY = Number.X, Number.Y

    return Vector2.new(VectorX - VectorX % 1, VectorY - VectorY % 1)
end

function Visuals:CreateDrawing(Type, Custom)
    local Drawing = Drawing.new(Type)

    for Property, Value in next, DrawingProperties[Type] do
        Drawing[Property] = Value
    end

    if Custom then
        for Property, Value in next, Custom do
            Drawing[Property] = Value
        end
    end

    return Drawing
end

function Visuals.AddPlayer(Player)
    if not Visuals.Players[Player] then
        Visuals.Players[Player] = {
            Color = Color3.fromRGB(0, 255, 0),
            Box = {
                Outline = Visuals:CreateDrawing("Square", {Color = Color3.fromRGB(0, 255, 0)}),
                Main = Visuals:CreateDrawing("Square")
            },
            Tracer = {
                Outline = Visuals:CreateDrawing("Line", {Color = Color3.fromRGB(0, 255, 0)}),
                Main = Visuals:CreateDrawing("Line")
            },
            Healthbar = {
                Outline = Visuals:CreateDrawing("Square", {Filled = true, Color = Color3.fromRGB(0, 0, 0)}),
                Main = Visuals:CreateDrawing("Square", {Filled = true, Color = Color3.fromRGB(0, 255, 0)})
            },
            Info = {
                Main = Visuals:CreateDrawing("Text"),
                Extra = Visuals:CreateDrawing("Text")
            }
        }
    end
end

function Visuals.RemovePlayer(Player)
    if Visuals.Players[Player] then
        for Index, Table in next, Visuals.Players[Player] do
            if type(Table) == "Table" then
                for Index2, Drawing in next, Table do
                    if Drawing.Remove then
                        Drawing:Remove()
                    end
                end
            end
        end

        Visuals.Players[Player] = nil
    end
end

local PlayerUtilities = {}

function PlayerUtilities:IsPlayerAlive(Player)
    local Character = Player.Character
    local Humanoid = (Character and Character:FindFirstChildWhichIsA("Humanoid"))

    if Character and Humanoid then
        return Humanoid.Health > 0
    end

    return false
end

function PlayerUtilities:GetHealth(Player)
    local Character = Player.Character
    local Humanoid = (Character and Character:FindFirstChildWhichIsA("Humanoid"))

    if Character and Humanoid then
        return {
            CurrentHealth = Humanoid.Health,
            MaxHealth = Humanoid.MaxHealth
        }
    end
end

function PlayerUtilities:GetBodyParts(Player)
    local Character = Player.Character

    if Character then
        local Head = Character:FindFirstChild("Head")
        local Root = Character:FindFirstChild("HumanoidRootPart")
        local Torso = Character:FindFirstChild("LowerTorso") or Character:FindFirstChild("Torso")
        local LeftArm = Character:FindFirstChild("LeftLowerArm") or Character:FindFirstChild("Left Arm")
        local RightArm = Character:FindFirstChild("RightLowerArm") or Character:FindFirstChild("Right Arm")
        local LeftLeg = Character:FindFirstChild("LeftLowerLeg") or Character:FindFirstChild("Left Leg")
        local RightLeg = Character:FindFirstChild("RightLowerLeg") or Character:FindFirstChild("Right Leg")

        if Head and Root and Torso and LeftArm and RightArm and LeftLeg and RightLeg then
            return {
                Character = Character,
                Head = Head,
                Root = Root,
                Torso = Torso,
                LeftArm = LeftArm,
                RightArm = RightArm,
                LeftLeg = LeftLeg,
                RightLeg = RightLeg
            }
        end
    end
end

Players.PlayerAdded:Connect(Visuals.AddPlayer)
Players.PlayerRemoving:Connect(Visuals.RemovePlayer)

RunService.RenderStepped:Connect(function()
    for Player, Objects in next, Visuals.Players do
        if Objects then
            local OnScreen, PassedTeamCheck = false, true
            local Health = PlayerUtilities:GetHealth(Player)
            local BodyParts = PlayerUtilities:GetBodyParts(Player)
            local IsOnClientTeam = LocalPlayer.Team == Player.Team
            local PlayerColor = Objects.Color--IsOnClientTeam and Visuals.Flags["Ally Color"] or Visuals.Flags["Enemy Color"]    

            local Tracer = Objects.Tracer 
            local Box = Objects.Box 
            local Healthbar = Objects.Healthbar
            local Info = Objects.Info

            if Tracer and Box and Healthbar and Info then
                if Visuals.Flags["Use Team Color"] then
                    PlayerColor = Player.TeamColor.Color
                end

                if Visuals.Flags["Team Check"] and IsOnClientTeam then
                    PassedTeamCheck = false
                end

                if PlayerUtilities:IsPlayerAlive(Player) and Health and BodyParts and PlayerColor and PassedTeamCheck then
                    local HealthPercent = (Health.CurrentHealth / Health.MaxHealth)
                    local Distance = LocalPlayer:DistanceFromCharacter(BodyParts.Root.Position)
                    ScreenPosition, OnScreen = CurrentCamera:WorldToViewportPoint(BodyParts.Root.Position)

                    local Orientation, BoxSize = BodyParts.Character:GetBoundingBox()
                    local Height = (CurrentCamera.CFrame - CurrentCamera.CFrame.Position) * Vector3.new(0, (math.clamp(BoxSize.Y, 1, 10) + 0.5) / 2, 0)  
                    local ScreenHeight = math.abs(CurrentCamera:WorldToScreenPoint(Orientation.Position + Height).Y - CurrentCamera:WorldToScreenPoint(Orientation.Position - Height).Y)
                    local Size = Visuals:Round(Vector2.new((ScreenHeight / 2), ScreenHeight))

                    local NameString = Player.DisplayName ~= Player.Name and string.format("%s | %s", Player.Name, Player.DisplayName) or Player.Name
                    
                    Tracer.Main.Color = PlayerColor
                    Tracer.Main.From = Vector2.new(CurrentCamera.ViewportSize.X / 2,  CurrentCamera.ViewportSize.Y)
                    Tracer.Main.To = Vector2.new(ScreenPosition.X, ScreenPosition.Y)
                    
                    Tracer.Outline.Thickness = (Tracer.Main.Thickness * 2)
                    Tracer.Outline.From = Tracer.Main.From
                    Tracer.Outline.To = Tracer.Main.To

                    Box.Main.Color = PlayerColor
                    Box.Main.Size = Size
                    Box.Main.Position = Visuals:Round(Vector2.new(ScreenPosition.X, ScreenPosition.Y) - (Size / 2))

                    Box.Outline.Thickness = Box.Main.Thickness * 2
                    Box.Outline.Size = Box.Main.Size
                    Box.Outline.Position = Box.Main.Position

                    Healthbar.Main.Color = HealthbarLerp(HealthPercent)
                    Healthbar.Main.Size = Vector2.new(2, (-Box.Main.Size.Y * HealthPercent))
                    Healthbar.Main.Position = Vector2.new((Box.Main.Position.X - (Box.Outline.Thickness + 1)), (Box.Main.Position.Y + Box.Main.Size.Y))

                    Healthbar.Outline.Size = Vector2.new(4, (Box.Main.Size.Y + 2))
                    Healthbar.Outline.Position = Vector2.new((Box.Main.Position.X - (Box.Outline.Thickness + 2)), (Box.Main.Position.Y - 1))
                    
                    Info.Main.Font = Drawing.Fonts[Visuals.Flags["Info Font"]]
                    Info.Main.Text = NameString
                    Info.Main.Position = Vector2.new(((Box.Main.Size.X / 2) + Box.Main.Position.X), ((ScreenPosition.Y - Box.Main.Size.Y / 2) - 18))

                    Info.Extra.Font = Drawing.Fonts[Visuals.Flags["Info Font"]]
                    Info.Extra.Text = string.format("(%dft) (%d/%d)", Distance, Health.CurrentHealth, Health.MaxHealth)
                    Info.Extra.Position = Vector2.new(((Box.Main.Size.X / 2) + Box.Main.Position.X), (Box.Main.Size.Y + Box.Main.Position.Y))
                end
                
                Tracer.Main.Visible = (OnScreen and Visuals.Flags["Tracers"]) or false
                Tracer.Outline.Visible = Tracer.Main.Visible

                Box.Main.Visible = (OnScreen and Visuals.Flags["Boxes"]) or false
                Box.Outline.Visible = Box.Main.Visible

                Healthbar.Main.Visible = (OnScreen and Visuals.Flags["Healthbar"]) or false
                Healthbar.Outline.Visible = Healthbar.Main.Visible

                Info.Main.Visible = (OnScreen and Visuals.Flags["Info"]) or false
                Info.Extra.Visible = (OnScreen and Visuals.Flags["Extra Info"]) or false
            end
        end
    end
end)

return Visuals
