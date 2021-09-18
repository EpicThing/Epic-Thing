local function LoadFromRepo(Folder, FileName)
    return loadstring(game:HttpGet(("https://raw.githubusercontent.com/EpicThing/Epic-Thing/main/Lua/%s/%s.lua"):format(Folder, FileName)))();
end;

LoadFromRepo("Utilities", "Init")

local library = LoadFromRepo("Utilities", "Library")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local Remotes = {}

local DataManager = require(ReplicatedStorage.Modules.DataManager)
local Hashes = getupvalue(getupvalue(DataManager.FireServer, 4), 3)
local RemoteAdded

for Index, Value in next, getreg() do
    if type(Value) == "function" and islclosure(Value) then
        if getconstants(Value)[1] == "tostring" and getinfo(Value).source:find("DataManager") then
            RemoteAdded = Value
            break
        end
    end
end

for Index, Value in next, getupvalue(getupvalue(RemoteAdded, 2), 1) do
    Remotes[Value:sub(1, 2) == "F_" and Value:sub(3) or Value] = Hashes[Index]
end

local function Call(Name, Arguments)
    local RemoteInstance = Remotes[tostring(Name)]
    
    if RemoteInstance then
        if RemoteInstance.ClassName == "RemoteEvent" then
            return RemoteInstance:FireServer(Arguments)
        elseif RemoteInstance.ClassName == "RemoteFunction" then
            return RemoteInstance:InvokeServer(Arguments)
        end
    end
    
    return false
end

local ModulesFolder, ScriptsFolder = ReplicatedStorage:FindFirstChild("Modules"), Player.PlayerGui.MainGUI:FindFirstChild("Scripts")
local DataFolder = ModulesFolder:FindFirstChild("Data")

local Connections = {}

function Connections:DisableConnection(Signal)
	for Index, Connection in next, getconnections(Signal) do
		Connection:Disable()
	end
end

function Connections:FireConnection(Signal)
	for Index, Connection in next, getconnections(Signal) do
		Connection:Fire()
	end
end

Connections:DisableConnection(Player.Idled)
Connections:DisableConnection(game:GetService("ScriptContext").Error)

local JobManagerInstance = ScriptsFolder.JobManager
local JobManagerModule = require(JobManagerInstance)

local Modules = {
	Hotbar = require(ScriptsFolder:FindFirstChild("Hotbar"));
	GUIHandler = require(ScriptsFolder:FindFirstChild("GUIHandler"));
	JobData = require(DataFolder:FindFirstChild("JobData"));
	TranslationHandler = require(ScriptsFolder:FindFirstChild("TranslationHandler"));
	FoodHandler = require(ModulesFolder:FindFirstChild("FoodHandler"));
}

local JobModules = {
	["Hairdresser"] = require(JobManagerInstance.StylezHairdresser);
	["Burger Cashier"] = require(JobManagerInstance.BloxyBurgersCashier);
	["Pizza Baker"] = require(JobManagerInstance.PizzaPlanetBaker);
}

local JobActions = {
	EndShift = function(Job)
		JobModules[Job]:EndShift()
	end, 

	IsWorking = function()
		return JobManagerModule:IsWorking()
	end,

	StartShift = function(Job)
		if not JobManagerModule:IsWorking() then
			JobModules[Job]:StartShift()
		end
	end
}

local function NoClipTween(TargetPosition)
	local Completed = false

	coroutine.wrap(function()
		while not Completed do
			Player.Character.Humanoid:ChangeState(11)
			RunService.RenderStepped:Wait()
		end
	end)()

	local Magnitude = (Player.Character.HumanoidRootPart.Position - TargetPosition).Magnitude
	local Tween = TweenService:Create(Player.Character.HumanoidRootPart, TweenInfo.new(Magnitude / 20, Enum.EasingStyle.Linear), {CFrame = CFrame.new(TargetPosition)})

	Tween:Play()
	Tween.Completed:Wait()

	Completed = true
end

local function GetRelativeComponents(vec)
	if Player.Character.PrimaryPart then
		local newCF = CFrame.new(Player.Character.PrimaryPart.Position, vec)
		local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = newCF:components()
		return {
			r00,
			r01,
			r02,
			r10,
			r11,
			r12,
			r20,
			r21,
			r22
		}
	end
end

local currentPlayerTween = nil
local function CoolTween(target, speed)
	if Player.Character:FindFirstChild("HumanoidRootPart") then
		local dist = (Player.Character.HumanoidRootPart.Position - target.p).magnitude
		currentPlayerTween = TweenService:Create(Player.Character.HumanoidRootPart, TweenInfo.new(dist / 20, Enum.EasingStyle.Linear), {
			CFrame = target
		})
		currentPlayerTween:Play()
		currentPlayerTween.Completed:wait()
		currentPlayerTween = nil
	end
end

local function BulldozePlot(Plot)
	if Plot.Name:split("Plot_")[2] == Player.Name then
		Call("BulldozePlot", {
			Exclude = {}
		})

		repeat wait() until Player.PlayerGui.MainGUI:FindFirstChild("MessageBox")

		local MessageBox = Player.PlayerGui.MainGUI.MessageBox

		if MessageBox.Title.Text == "Bulldoze Plot" then
			MessageBox.Event:Fire(true)
		end

		Player.PlayerGui.MainGUI.InputBox.ContentBox.Text = Player.Name

		Player.PlayerGui.MainGUI.InputBox.Event:Fire(true)
	else
		local Amount = 1

		for Index, Value in next, Plot.House:GetChildren() do
			for k, x in next, Value:GetChildren() do
				if x.Name ~= "Poles" then
					Amount = Amount + 1

					if Amount % 4 == 0 then
						wait(3)

						spawn(function()
							Call("SellObject", {
								Object = x
							})
						end)
					else
						spawn(function()
							Call("SellObject", {
								Object = x
							})
						end)
					end
				end
			end
		end
	end
end

local PlayerList, PlayerHouses = {}, {}

local function PlayerAdded(plr)
	table.insert(PlayerList, plr.Name)
	table.insert(PlayerHouses, plr.Name.."'s house")
end

local function PlayerRemoving(plr)
	table.remove(PlayerList, table.find(PlayerList, plr.Name))
	table.remove(PlayerHouses, table.find(PlayerHouses, plr.Name.."'s house"))
end

Players.PlayerAdded:Connect(PlayerAdded)
Players.PlayerRemoving:Connect(PlayerRemoving)

for Index, Value in next, Players:GetPlayers() do
	PlayerAdded(Value)
end

local Window = library:Window("Welcome to Bloxburg")

local Tabs = {
	Autofarm = Window:Tab("Autofarm");
    Utilities = Window:Tab("Utilities");
	Misc = Window:Tab("Misc");
}

local Sections = {
	Autofarm = {
		Main = Tabs.Autofarm:Section("Main");
		Settings = Tabs.Autofarm:Section("Settings");
		Stats = Tabs.Autofarm:Section("Stats");
	};

    Misc = {
        Random = Tabs.Misc:Section("Random");
        FakeMessage = Tabs.Misc:Section("Fake Message");
		FakePaycheck = Tabs.Misc:Section("Fake Paycheck");
    };

	Utilities = {
		AutoDrive = Tabs.Utilities:Section("Auto Drive");
		Sky = Tabs.Utilities:Section("Sky");
        AutoCook = Tabs.Utilities:Section("Auto Cook");
        StatViewer = Tabs.Utilities:Section("Stat Viewer");
	};
}

Sections.Misc.Random:Button("Bulldoze Current Plot", function()
	BulldozePlot(ReplicatedStorage.Stats[Player.Name].IsBuilding.Value)
end)

local StatLabels = {
	EarningsLabel = Sections.Autofarm.Stats:Label("");
	TimeLabel = Sections.Autofarm.Stats:Label("");
}

local ActiveJob = nil;
local WorkEnabled = false;

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
	local args = {...}

	if checkcaller() and getnamecallmethod() == "FireServer" and args[1].Order and args[1].Workstation then
		if args[1].Workstation.Parent.Name == "HairdresserWorkstations" and ActiveJob == "Hairdresser" then

			args[1].Order = {
				args[1].Workstation.Occupied.Value.Order.Style.Value,
				args[1].Workstation.Occupied.Value.Order.Color.Value
			}

			return oldNamecall(self, unpack(args))

		elseif args[1].Workstation.Parent.Name == "CashierWorkstations" and ActiveJob == "Cashier (Burger)" then

			args[1].Order = {
				args[1].Workstation.Occupied.Value.Order.Burger.Value,
				args[1].Workstation.Occupied.Value.Order.Fries.Value,
				args[1].Workstation.Occupied.Value.Order.Cola.Value
			}

			return oldNamecall(self, unpack(args))

		elseif args[1].Workstation.Parent.Name == "BakerWorkstations" and ActiveJob == "Pizza Baker" then

			args[1].Order = {
				true,
				true,
				true,
				args[1].Workstation.Order.Value
			}

			return oldNamecall(self, unpack(args))

		end
	end

	return oldNamecall(self, ...)
end)

local function FindClosest(Item)
	local closestBlock = nil
	local closestDistance = math.huge
	if Item == "PizzaCrate" then
		for Index, Value in next, workspace.Environment.Locations.PizzaPlanet.IngredientCrates:GetChildren() do
			local dis = (Player.Character.HumanoidRootPart.Position - Value.Position).magnitude
			if dis < closestDistance then
				closestDistance = dis
				closestBlock = Value
			end
		end
		if closestBlock == nil then
			wait(0.5)
			FindClosest("PizzaCrate")
		end
	end
	return closestBlock
end

local toGo = nil
local Vehicle

local LocationCFrame = {
	["Pizza Planet"] = CFrame.new(1092.59473, 13.6776829, 249.286835);
	["Bloxy Burgers"] = CFrame.new(877.985901, 13.070406, 267.987854);
	["Stylez Hairdresser"] = CFrame.new(902.504822, 13.0960951, 166.004135);
	["Lake"] = CFrame.new(985.374207, 13.1055984, 1061.12622);
	["Mike's Motors"] = CFrame.new(1095.50464, 12.9041576, 384.505646);
	["Nightclub"] = CFrame.new(1068.34241, 12.9559097, 27.2332954);
	["City Hall"] = CFrame.new(994.741943, 13.1551933, -225.07254);
	["Gym"] = CFrame.new(841.105408, 12.9554825, -100.579193);
	["BFF Supermarket"] = CFrame.new(840.207581, 13.0544462, -14.4691305);
	["Fancy Furniture"] = CFrame.new(1095.1908, 13.1559048, 139.72467);
	["Lovely Lumber"] = CFrame.new(614.160645, 13.0296869, 772.316162);
	["Cave"] = CFrame.new(519.167419, 13.0106106, 728.404419);
	["Ben's Ice Cream"] = CFrame.new(943.374939, 13.0542393, 1017.85272);
	["Ferris Wheel"] = CFrame.new(986.463562, 13.0917492, 1089.16406);
}

local locationNames = {}

for Index in next, LocationCFrame do
	table.insert(locationNames, Index)
end

Sections.Utilities.AutoDrive:SearchBox("Location", locationNames, nil, function(die)
	toGo = die
end, true)

Sections.Utilities.AutoDrive:SearchBox("Player Location", PlayerList, nil, function(die)
	toGo = die
end, true)

Sections.Utilities.AutoDrive:SearchBox("Player Houses", PlayerHouses, nil, function(die)
	toGo = die
end, true)

local tween
local stop = false

local function VehicleTween(item, target, speed)
	local dist = (item.Position - target.p).magnitude
	tween = TweenService:Create(item, TweenInfo.new(dist / speed, Enum.EasingStyle.Linear), {
		CFrame = target
	})
	tween:Play()
	tween.Completed:wait()
end

local function PlayerLocations()
	local plrPos = {}
	for Index, Value in next, PlayerList do
		local PlayerCharacter = Players[Value].Character
		if PlayerCharacter and PlayerCharacter:FindFirstChild("HumanoidRootPart") then
			plrPos[Value] = PlayerCharacter.HumanoidRootPart.CFrame
		end
	end
	return plrPos
end

local function houseLocations()
	local housePos = {}
	for Index, Value in next, PlayerList do
		pcall(function()
			housePos[Value.."'s house"] = workspace.Plots["Plot_" .. Value].FrontObjects.ItemHolder["Basic Mailbox"].CFrame
		end)
	end
	return housePos
end

Sections.Utilities.AutoDrive:Button("Drive", function()
	for Index, Value in next, Player.Character:GetChildren() do
		if Value.Name:sub(0, 8) == "Vehicle_" then
			Vehicle = Value
		end
	end
	if not Vehicle then
		Window:Notification("Error", {
			Text = "You must be on a vehicle!";
			ConfirmText = "Okay";
		})
	else
		local oldg = workspace.Gravity
		workspace.Gravity = 0
		local _, VehicleSize = Vehicle:GetBoundingBox()
		local LocationPath = PathfindingService:CreatePath()

		local placeToGo = LocationCFrame[toGo] or PlayerLocations()[toGo] or houseLocations()[toGo]
		LocationPath:ComputeAsync(Player.Character.HumanoidRootPart.Position, placeToGo.p)
		local LocationPoints = LocationPath:GetWaypoints({
			AgentRadius = VehicleSize.X;
			AgentHeight = VehicleSize.Y
		})

		driving = true

		for Index, Value in next, LocationPoints do
			if stop then
				stop = false
				workspace.Gravity = oldg
				break
			end
			if Index % 10 == 0 then
				VehicleTween(Vehicle.PrimaryPart, CFrame.new(Value.Position.X, Value.Position.Y + 5, Value.Position.Z, unpack(GetRelativeComponents(Value.Position + Vector3.new(0, 5, 0)))), 60)
			end
		end
		workspace.Gravity = oldg
		if tween then
			tween:Cancel()
			tween = nil
		end
		driving = false
	end
end)

Sections.Utilities.AutoDrive:Button("Stop Driving", function()
	stop = true
end)

local driving = false
local GoToStation = false

--//Noclip
RunService.Stepped:Connect(function()
	if driving or GoToStation or (WorkEnabled == true and ActiveJob == "Pizza Baker") then
		if Player.Character then 
            for Index, Value in next, Player.Character:GetChildren() do 
                if Value:IsA("BasePart") then 
                    Value.CanCollide = false 
                end 
            end 
        end
	end
end)

local WorkstationFunctions
WorkstationFunctions = {
	GetFreeBakerStation = function()
		if workspace.Environment.Locations:FindFirstChild("PizzaPlanet") then
			for Index, Value in next, workspace.Environment.Locations.PizzaPlanet.BakerWorkstations:GetChildren() do
				if Value:FindFirstChild("InUse") and Value.InUse.Value == Player then
					return Value
				end
			end
			for Index, Value in next, workspace.Environment.Locations.PizzaPlanet.BakerWorkstations:GetChildren() do
				if Value:FindFirstChild("InUse") and Value.InUse.Value == nil then
					return Value
				end
			end
		end
	end;
	GetHairWorkstations = function()
		if workspace.Environment.Locations:FindFirstChild("StylezHairStudio") then
			local stations = {}
			for Index, Value in next, workspace.Environment.Locations.StylezHairStudio.HairdresserWorkstations:GetChildren() do
				if ((Value.Mirror:FindFirstChild("HairdresserGUI") and not Value.Mirror.HairdresserGUI.Used.Visible) or Value.InUse.Value == Player) and Value.Occupied.Value ~= nil then
					table.insert(stations, Value)
				end
			end
			return stations
		end
	end;
	GetBurgerWorkstations = function()
		if workspace.Environment.Locations:FindFirstChild("BloxyBurgers") then
			local stations = {}
			for Index, Value in next, workspace.Environment.Locations.BloxyBurgers.CashierWorkstations:GetChildren() do
				if Value.InUse.Value == Player and Value.Occupied.Value ~= nil then
					table.insert(stations, Value)
				end
				if Value.InUse.Value == nil and Value.Occupied.Value ~= nil then
					table.insert(stations, Value)
				end
			end
			return stations
		end
	end;
	GetFreeHairStation = function()
		local station
		if workspace.Environment.Locations:FindFirstChild("StylezHairStudio") then
			for Index, Value in next, workspace.Environment.Locations.StylezHairStudio.HairdresserWorkstations:GetChildren() do
				if Value.InUse.Value == nil then
					station = Value
				end
			end
		end
		if station == nil then
			GetFreeHairStation()
		end
		return station
	end;
	GetFreeBurgerStation = function()
		if workspace.Environment.Locations:FindFirstChild("BloxyBurgers") then
			local station
			for Index, Value in next, workspace.Environment.Locations.BloxyBurgers.CashierWorkstations:GetChildren() do
				if Value.InUse.Value == nil then
					station = Value
				end
			end
			if station == nil then
				GetFreeBurgerStation()
			end
			return station
		end
	end;
}

local JobHandler = {
	["Hairdresser"] = function()
		if #WorkstationFunctions.GetHairWorkstations() > 0 then
			for Index, workstation in next, WorkstationFunctions.GetHairWorkstations() do
				if workstation.Mirror:FindFirstChild("HairdresserGUI") then
					workstation.Mirror.HairdresserGUI.Overlay:FindFirstChild("false").ImageRectOffset = Vector2.new(0, 0)
					workstation.Mirror.HairdresserGUI.Overlay:FindFirstChild("false").ImageColor3 = Color3.new(0, 255, 0)

					Connections:FireConnection(workstation.Mirror.HairdresserGUI.Frame.Done.Activated)
				end
			end
		end
	end;

	["Cashier (Burger)"] = function()
		if #WorkstationFunctions.GetBurgerWorkstations() > 0 then
			for Index, Value in next, WorkstationFunctions.GetBurgerWorkstations() do
				if Value.OrderDisplay.DisplayMain:FindFirstChild("CashierGUI") then
					Value.OrderDisplay.DisplayMain.CashierGUI.Overlay:FindFirstChild("false").ImageRectOffset = Vector2.new(0, 0)
					Value.OrderDisplay.DisplayMain.CashierGUI.Overlay:FindFirstChild("false").ImageColor3 = Color3.new(0, 255, 0)
					
					Connections:FireConnection(Value.OrderDisplay.DisplayMain.CashierGUI.Frame.Done.Activated)
				end
			end
		end
	end;
    
	["Pizza Baker"] = function()
		local Station = WorkstationFunctions.GetFreeBakerStation()
		if Station ~= nil then
			if Station.Order.IngredientsLeft.Value == 0 then
				repeat
					wait()
				until not currentPlayerTween
				local Crate = FindClosest("PizzaCrate")
				Player.Character.Humanoid:MoveTo((Crate.CFrame + Vector3.new(6, 0, 0)).Position)
				repeat
					Remotes["TakeIngredientCrate"]:FireServer({
						Object = Crate
					})

					wait()
				until Player.Character:FindFirstChild("Ingredient Crate")
				Player.Character.Humanoid:MoveTo((Station.CounterTop.CFrame - Vector3.new(7, 0, 0)).p)
				repeat
					Remotes["RestockIngredients"]:FireServer({
						Workstation = Station;
					})

					wait()
				until Station.Order.IngredientsLeft.Value > 0
			end
			if Station.OrderDisplay.DisplayMain:FindFirstChild("BakerGUI") then
				Station.OrderDisplay.DisplayMain.BakerGUI.Overlay:FindFirstChild("false").ImageRectOffset = Vector2.new(0, 0)
				Station.OrderDisplay.DisplayMain.BakerGUI.Overlay:FindFirstChild("false").ImageColor3 = Color3.new(0, 255, 0)

				Connections:FireConnection(Station.OrderDisplay.DisplayMain.BakerGUI.Frame.Done.Activated)
			end
		end
	end;
}

local JobFunctions = {
	["Cashier (Burger)"] = {
		Start = function()
			JobActions.StartShift("Cashier (Burger)")
			GoToStation = true
			CoolTween(CFrame.new(WorkstationFunctions.GetFreeBurgerStation().OrderDisplay.DisplayMain.Position) - Vector3.new(3, 0, 0), 12)
			GoToStation = false
		end;
		End = function()
			JobActions.EndShift("Cashier (Burger)")
		end;
		GoTo = function()
			JobManagerModule:GoToWork("BloxyBurgersCashier")
		end;
	};

	["Hairdresser"] = {
		Start = function()
			JobActions.StartShift("Hairdresser")
			GoToStation = true
			CoolTween(WorkstationFunctions.GetFreeHairStation().Stool.PrimaryPart.CFrame, 12)
			GoToStation = false
		end;
		End = function()
			JobActions.EndShift("Hairdresser")
		end;
		GoTo = function()
			JobManagerModule:GoToWork("StylezHairdresser")
		end;
	};

	["Pizza Baker"] = {
		Start = function()
			JobActions.StartShift("Pizza Baker")
			local Station = WorkstationFunctions.GetFreeBakerStation()
			if Station ~= nil then
				CoolTween(Station.CounterTop.CFrame - Vector3.new(7, 0, 0), 12)
			end
		end;
		End = function()
			JobActions.EndShift("Pizza Baker")
		end;
		GoTo = function()
			JobManagerModule:GoToWork("PizzaPlanetBaker")
		end;
	};
}

local JobList = {
	"Burger Cashier";
	"Hairdresser";
	"Pizza Baker";
}

local StopSettings = {
	StopAfterAmount = false,
	StopAmount = nil
}

Sections.Autofarm.Main:SearchBox("Job", JobList, nil, function(value)

	if value == "Burger Cashier" then 
		value = "Cashier (Burger)"
	elseif value == "Market Cashier" then 
		value = "Cashier (Market)"
	end 

	local lastActive = ActiveJob
	ActiveJob = value
	if WorkEnabled and lastActive then
		JobFunctions[lastActive]["End"]()
	end
end)

Sections.Autofarm.Main:Button("Go To Job", function()
	if ActiveJob ~= nil then
		JobFunctions[ActiveJob]["GoTo"]()
	else
		Window:Notification("Error", {
			Text = "Job Not Selected";
			ConfirmText = "Okay";
		})
	end
end)

Sections.Autofarm.Main:Toggle("Enabled", false, function(bool)
	WorkEnabled = bool
	if ActiveJob ~= nil then
		if JobFunctions[ActiveJob] ~= nil then
			if bool then
				JobFunctions[ActiveJob]["Start"]()
			elseif bool then
				JobFunctions[ActiveJob]["End"]()
			end
		end
	else
		Window:Notification("Error", {
			Text = "Job Not Selected";
			ConfirmText = "Okay";
		})
	end
end, true)

Sections.Autofarm.Settings:Toggle("Stop After Amount", false, function(bool)
	StopSettings.StopAfterAmount = bool
end)

Sections.Autofarm.Settings:Box("Amount", "100000", function(val)
	StopSettings.StopAmount = tonumber(val)
end)

Sections.Misc.Random:Button("Private Server", function()
	Window:Notification("Message", {
		Text = "Teleporting...";
		ConfirmText = "Okay";
	})

	game:GetService("TeleportService"):Teleport(4491408735)
end)

Sections.Misc.Random:Button("Remote Stink Effect", function()
	local Found = false

	if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
		if Player.Character.HumanoidRootPart:FindFirstChild("SmellParticles") then
			Found = true
			Player.Character.HumanoidRootPart.SmellParticles:Destroy()
		end

		if Player.Character.HumanoidRootPart:FindFirstChild("FlyParticles") then
			Found = true
			Player.Character.HumanoidRootPart.FlyParticles:Destroy()
		end
	end

	if not Found then
		Window:Notification("Error", {
			Text = "Stink not found";
			ConfirmText = "Okay";
		})
	end
end)

Sections.Misc.Random:SearchBox("To Player Plot", PlayerList, nil, function(value)
	if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
		local Target = Call("ToPlot", {
			Player = Players:FindFirstChild(value)
		})

		Player.Character:SetPrimaryPartCFrame(Target)
	end
end, true)

local ClickDoor = false

Sections.Misc.Random:Toggle("Click to Open Doors", false, function(value)
	ClickDoor = value
end)

Sections.Misc.Random:Button("Open all Doors", function()
	for Index, Value in next, workspace.Plots:GetChildren() do
		if Value:FindFirstChild("House") then
			for k,x in next, Value.House:GetChildren() do
				for a,b in next, x:GetDescendants() do
					if b.Name == "IsOpen" and b:IsA("BoolValue") then
						b.Value = true
					end
				end
			end
		end
	end
end)

Mouse.Button1Down:Connect(function()
	if ClickDoor then
		local Target = Mouse.Target

		if Target then
			local IsOpen = Target:FindFirstChild("IsOpen", true) or (Target.Parent and Target.Parent:FindFirstChild("IsOpen", true)) or (Target.Parent and Target.Parent.Parent and Target.Parent.Parent:FindFirstChild("IsOpen", true))

			if IsOpen and IsOpen:FindFirstAncestor("House") and IsOpen:IsA("BoolValue") then
				IsOpen.Value = not IsOpen.Value
			end
		end
	end
end)

local FakePaycheck = {
	pamount = nil;
	pjob = nil;
}

Sections.Misc.FakePaycheck:Box("Amount", "999", function(am)
	if tonumber(am) ~= nil then
		FakePaycheck.pamount = am
	else
		Window:Notification("Error", {
			Text = "Amount must be a number!";
			ConfirmText = "Okay";
		})
	end
end)

Sections.Misc.FakePaycheck:Box("Job", "", function(Input)
	FakePaycheck.pjob = Input
end)

Sections.Misc.FakePaycheck:Button("Fake Paycheck", function()
	if not FakePaycheck.pamount or not FakePaycheck.pjob then
		Window:Notification("Error", {
			Text = "Amount/Job were not provided";
			ConfirmText = "Okay";
		})
	else
		local JobData = Modules.JobData
		local old = JobData.GetJob
		JobData.GetJob = function(...)
			local args = {
				...
			}
			if args[2] == FakePaycheck.pjob then
				return {
					Title = FakePaycheck.pjob,
					ID = 69,
					Name = FakePaycheck.pjob,
					Location = Instance.new("Model"),
					AwardName = "bruh moment"
				}
			end
			return old(...)
		end
		local TranslationHandler = Modules.TranslationHandler
		local old2 = TranslationHandler.Format
		TranslationHandler.Format = function(...)
			local args = {
				...
			}
			if args[2] == "T_Job"..FakePaycheck.pjob then
				return FakePaycheck.pjob
			end
			return old2(...)
		end

		JobManagerModule:ShowPaycheck(FakePaycheck.pamount, FakePaycheck.pjob)
	end
end)

local FakeMessage = {
	messageText = nil;
	Type = nil;
}

Sections.Misc.FakeMessage:Picker("Type", {
	"Message",
	"Error",
	"Confirmation"
}, function(a)
	FakeMessage.Type = a
end)

Sections.Misc.FakeMessage:Box("Text", "", function(a)
	FakeMessage.messageText = a
end)

Sections.Misc.FakeMessage:Button("Fake Message", function()
	if FakeMessage.messageText then
		local GUIHandler = Modules.GUIHandler
		
		if FakeMessage.Type == "Message" or FakeMessage.Type == nil then
			spawn(function()
				GUIHandler:MessageBox(FakeMessage.messageText)
			end)
		elseif FakeMessage.Type == "Error" then
			spawn(function()
				GUIHandler:AlertBox(FakeMessage.messageText)
			end)
		elseif FakeMessage.Type == "Confirmation" then
			spawn(function()
				GUIHandler:ConfirmBox(FakeMessage.messageText)
			end)
		end
	end
end)

local SkySettings = {
	SkyEnabled = false;
	Time = "Day";
	Weather = "Clear";
}

Sections.Utilities.Sky:Toggle("Enabled", false, function(bool)
	SkySettings.SkyEnabled = bool
end)

Sections.Utilities.Sky:Picker("Time of Day", {
	"Day",
	"Night"
}, "Day", function(selected)
	SkySettings.Time = selected
	if SkySettings.SkyEnabled then
		if SkySettings.Time == "Day" then
			Lighting:FindFirstChild("TimeOfDay").Value = 500
		elseif SkySettings.Time == "Night" then
			Lighting:FindFirstChild("TimeOfDay").Value = 0
		end
	end
end)

Sections.Utilities.Sky:Picker("Weather", {
	"Clear",
	"Rain",
	"Fog",
	"Snow"
}, "Clear", function(selected)
	SkySettings.Weather = selected
	if SkySettings.SkyEnabled then
		if SkySettings.Weather == "Clear" then
			Lighting:FindFirstChild("Weather").Value = ""
		else
			Lighting:FindFirstChild("Weather").Value = SkySettings.Weather
		end
	end
end)

local TimeOfDay = Lighting:FindFirstChild("TimeOfDay")
TimeOfDay:GetPropertyChangedSignal("Value"):Connect(function()
	if SkySettings.SkyEnabled and SkySettings.Time ~= nil then
		if SkySettings.Time == "Day" and math.floor(TimeOfDay.Value) ~= 500 then
			TimeOfDay.Value = 500
		elseif SkySettings.Time == "Night" and math.floor(TimeOfDay.Value) ~= 0 then
			TimeOfDay.Value = 0
		end
	end
end)

local Weather = Lighting:FindFirstChild("Weather")
Weather:GetPropertyChangedSignal("Value"):Connect(function()
	if SkySettings.SkyEnabled and SkySettings.Weather ~= nil then
		if SkySettings.Weather == "Clear" and Weather.Value ~= "" then
			Weather.Value = ""
		else
            if Weather.Value ~= SkySettings.Weather then
			    Weather.Value = SkySettings.Weather
            end
		end
	end
end)

local function GetClosestAppliance(Types)
	local Results = {}
	for Index, Value in next, workspace.Plots["Plot_"..Player.Name].House:GetChildren() do
		for k, x in next, Value:GetDescendants() do
			for a, b in next, Types do
				if x.Name:find(b) and x:IsA("Part") then
					table.insert(Results, x)
				end
			end
		end
	end
	if #Results == 1 then
		return Results[1]
	else
		local closest
		local last = math.huge
		for Index, Value in next, Results do
			local mag = (Player.Character.HumanoidRootPart.Position - Value.Position).magnitude
			if mag < last then
				last = mag
				closest = Value
			end
		end
		return closest
	end
end

local FoodHandler = Modules.FoodHandler
local FoodData = FoodHandler.FoodData
local CookActions = FoodHandler.CookActions

local function GetApplianceFromRecipe(recipe)
	local Types = {
		"Stove",
		"Counter"
	}
	local Action = CookActions[recipe]
	local Type = Action.Type or Action.Types
	local Result
	if typeof(Type) == "table" then
		for Index, Value in next, Type do
			if table.find(Types, Value) then
				if Value == "Counters" then
					Value = "Counter"
				end
				Type = Value
			end
		end
	else
		if Type == "Counters" then
			Type = "Counter"
		end
	end
	if table.find(Types, Type) then
		return Type
	end
end

local function GetRecipe(name)
	local Recipe = FoodData[name].Recipe
	local Result = {}
	for Index, Value in next, Recipe do
		if type(Value) == "table" then
			for k, x in next, Value do
				if GetApplianceFromRecipe(x) then
					table.insert(Result, x)
				end
			end
		else
			table.insert(Result, Value)
		end
	end
	return Result
end

local AutoMoodVariables = {
	Food = "Garden Salad";
	AutoCompleteCookingChallenges = false;
	SelectedFood = "Garden Salad";
	Cooking = false;
	DoingAutoMood = false;
}

Player.PlayerGui.MainGUI.Scripts.Hotbar.ChildAdded:Connect(function(child)
	if (AutoMoodVariables.AutoCompleteCookingChallenges or AutoMoodVariables.Cooking) and child:IsA("BindableEvent") then
		wait()
		child:Fire(true)
	end
end)

local CharConnection
local CurrentConnection

local function AutoCook(Food)
    local Fridge = GetClosestAppliance({
        "Fridge"
    })

    if Fridge == nil then
        Window:Notification("Error", {
            Text = "You must have a fridge on your plot";
            ConfirmText = "Okay";
        })
        return
    end

    NoClipTween(Fridge.AttachPos.Position)

    Remotes["Interact"]:FireServer({
        Target = Fridge,
        Path = "1"
    })

    Remotes["TakeIngredient"]:FireServer({
        Name = Food
    })

    local CurrentChild
    local Recipe = GetRecipe(Food)
    AutoMoodVariables.Cooking = true

    local function DoAction(CookProgress, child)
        local AppFromRec = GetApplianceFromRecipe(Recipe[CookProgress + 1])
        local Appliance = GetClosestAppliance({
            AppFromRec
        })

        if Appliance == nil then
            Window:Notification("Error", {
                Text = "You must have a "..AppFromRec.." on your plot";
                ConfirmText = "Okay";
            })
            return
        end

        NoClipTween(Appliance.AttachPos.Position)

        if AppFromRec == "Stove" then
            Remotes["Interact"]:FireServer({
                Target = Appliance,
                Path = "1"
            })
            if Recipe[CookProgress + 1] == "Bake" then
                repeat
                    wait()
                until not Player.Character:FindFirstChild(child.Name)

                repeat
                    Remotes["Interact"]:FireServer({
                        Target = Appliance,
                        Path = "1"
                    })
                    wait(1)
                until Player.Character:FindFirstChild(child.Name)

                CurrentConnection:Disconnect()

                local NewCookProgress = Player.Character:FindFirstChild(child.Name):WaitForChild("CookProgress")

                CurrentConnection = NewCookProgress:GetPropertyChangedSignal("Value"):connect(function()
                    DoAction(NewCookProgress.Value, CurrentChild)
                end)
            end
        elseif AppFromRec == "Counter" then
            Remotes["Interact"]:FireServer({
                Target = Appliance,
                Path = "2"
            })
        end
    end

    CharConnection = Player.Character.ChildAdded:connect(function(child)
        if child:IsA("Model") and child.Name:find("Ingredients") then
            local CookProgress = child:WaitForChild("CookProgress")

            if #Recipe == 1 or CookProgress.Value + 1 ~= #Recipe then
                DoAction(CookProgress.Value, child)

                if #Recipe > 1 then
                    CurrentConnection = CookProgress:GetPropertyChangedSignal("Value"):connect(function()
                        DoAction(CookProgress.Value, child)

                        if CookProgress.Value + 1 == #Recipe then
                            CurrentConnection:Disconnect()
                        end
                    end)
                end

                CurrentChild = child
            end
        end
    end)
end

local AllFoods = {}

for Index, Value in next, FoodData do
	if not Value.IsQuick and not Value.Hidden then
		table.insert(AllFoods, Index)
	end
end

local AutoCompleteCookingChallengesToggle = Sections.Utilities.AutoCook:Toggle("Auto Complete Cooking Challenges", false, function(value)
	AutoMoodVariables.AutoCompleteCookingChallenges = value
end)

local FoodSearchBox = Sections.Utilities.AutoCook:SearchBox("Food", AllFoods, nil, function(value)
	AutoMoodVariables.SelectedFood = value
end)

local CookFoodButton = Sections.Utilities.AutoCook:Button("Cook Food", function()
	AutoCook(AutoMoodVariables.SelectedFood, false)
end)

coroutine.wrap(function()
	while wait() do
		if WorkEnabled == true and ActiveJob ~= nil and JobHandler[ActiveJob] ~= nil then
			JobHandler[ActiveJob]()
		end
	end
end)()

coroutine.wrap(function()
	while wait() do
		if JobActions.IsWorking() then
			if StopSettings.StopAfterAmount == true and StopSettings.StopAmount ~= nil and math.floor(ReplicatedStorage.Stats[Player.Name].Job.ShiftEarnings.Value) >= StopSettings.StopAmount then
				WorkEnabled = false
				JobFunctions[ActiveJob]["End"]()
				wait(1)
				Modules.Hotbar:ToPlot()
			end
			StatLabels.EarningsLabel:Update("Shift Earnings: "..tostring(math.floor(ReplicatedStorage.Stats[Player.Name].Job.ShiftEarnings.Value)))
			StatLabels.TimeLabel:Update("Shift Duration: "..Player.PlayerGui.MainGUI.Bar.CharMenu.WorkFrame.WorkFrame.TimeLabel.TextLabel.Text)
		else
			StatLabels.EarningsLabel:Update("Shift Earnings: 0")
			StatLabels.TimeLabel:Update("Shift Duration: 0s")
			repeat wait() until JobActions.IsWorking()
		end
	end
end)()

do
	local function getUserStat(user, stat)
		return ReplicatedStorage.Stats[user]:FindFirstChild(stat, true).Value
	end

	local otherStatLabels = {}

	local selectStatPlayer = Sections.Utilities.StatViewer:SearchBox("Select Player", PlayerList, nil, function(target)
		for Index, Value in next, otherStatLabels do
			Value:Update(string.format("%s: %s", Index, getUserStat(target, Index)))
		end
	end, true)

	otherStatLabels.Money = Sections.Utilities.StatViewer:Label("Money: 0")
	otherStatLabels.Blockbux = Sections.Utilities.StatViewer:Label("Blockbux: 0")
	otherStatLabels.Houses = Sections.Utilities.StatViewer:Label("Houses: 0")
end
