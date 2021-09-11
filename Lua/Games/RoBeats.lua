local function LoadFromRepo(Folder, FileName)
    return loadstring(game:HttpGet(("https://raw.githubusercontent.com/EpicThing/Epic-Thing/main/Lua/%s/%s.lua"):format(Folder, FileName)))()
end

LoadFromRepo("Utilities", "Init")

local library = LoadFromRepo("Utilities", "Library")

local Window = library:Window("RoBeats")

local Autoplayer = Window:Tab("Autoplayer")
local Misc = Window:Tab("Misc")

local HitPercentages = {
    Perfect = 100;
    Great = 0;
    Okay = 0;
    Miss = 0;
    Combined = 0;
}

local HeldNotes = {}

local Bounds = {
    Perfect = -20;
    Great = -50;
    Okay = -100;
    Miss = -500;
}

local RELEASE_TRACK = 'release_track_index';
local PRESS_TRACK = 'press_track_index';
local TEST_HIT = 'get_delta_time_from_hit_time';
local TEST_RELEASE = 'get_delta_time_from_release_time';
local visit_webnpc = nil
local WebNPCManager = nil

local function GetHitPercentage(a) 
    return HitPercentages[a] 
end

local function Calculate(a, b, c, d)
    local Total = a + b + c + d
    return a / Total * 100, b / Total * 100, c / Total * 100, d / Total * 100
end

local Utilities
Utilities = {

    get_target_delay_from_noteresult = function(noteresult)
        return Bounds[noteresult]
    end;
    
    get_noteresult = function()

        local P, G, O, M = Calculate(GetHitPercentage("Perfect"), GetHitPercentage("Great"), GetHitPercentage("Okay"), GetHitPercentage("Miss"))
        local Target = P + G + O + M
        local Total = 0
        
        local ChanceTBL = {}
        local chs = {"Miss", "Okay", "Great", "Perfect"}

        for i,v in next, {M, O, G, P} do 
            if v > 0 then 
                ChanceTBL[chs[i]] = v
            end
        end

        local Entries = {}
        for i,v in next, ChanceTBL do
            Entries[i] = {Min = Total, Max = Total + v}
            Total = Total + v
        end
        
        local Number = math.random(0, math.floor(Target));

        for i,v in next, Entries do
            if v.Min <= Number and v.Max >= Number then
                return i
            end
        end
    end;

    updatehitpct = function()
        local P, G, O, M = GetHitPercentage('Perfect'), GetHitPercentage('Great'), GetHitPercentage('Okay'), GetHitPercentage('Miss')
        HitPercentages.Combined = P + G + O + M
    end;

    determine = function(key, constants)
        local finding
    
        if (key == RELEASE_TRACK) then
            finding = 'release'
        elseif (key == PRESS_TRACK) then
            finding = 'press'
        elseif (key == TEST_HIT) then
            finding = 'get_delta_time_from_hit_time'
        elseif (key == TEST_RELEASE) then
            finding = 'get_delta_time_from_release_time'
        elseif (key == 'ya_mum') then
            finding = 'set_game_noteskin_colors'
        end
    
        if finding == nil then return false end
    
        if table.find(constants, finding) then
            return true
        end
        
        return false 
    end;
    
    get_notes = function(tracksystem)
        for i,v in next, tracksystem do 
            if type(v) == "function" then 
                local c = getconstants(v)
                if table.find(c, "do_remove") and table.find(c, "clear") then
                    return getupvalue(v, 1)
                end 
            end 
        end
    end;
    
    get_tracksystems = function(_game)
        for i,v in next, _game do
            if (type(v) == 'function') then
                local obj = getupvalue(v, 1)
                if (type(obj) == 'table' and rawget(obj, '_table') and rawget(obj, 'count')) then
                    if (obj:count() <= 4) then
                        return obj
                    end
                end
            end
        end
    end;
    
    get_func = function(parent, func)
        for i,v in next, parent do
            local consts = type(v) == 'function' and getconstants(v) or {}
            if (type(v) == 'function' and Utilities.determine(func, consts)) then
                return v
            end
        end
    end;
};

local Database
local AllSongs;
local Applying = {}
local StoredSongs = {}

local function Apply(as,db)
    local MNM = db:name_to_key('MondayNightMonsters1')

    local old_new = as.new
    
    as.new = function(...)
        local as_self = old_new(...)
        local old_skp = as_self.on_songkey_pressed;
        as_self.on_songkey_pressed = function(self, song)
            
            local actual = tonumber(song);
            
            if library.flags["Unlock All Songs (locks score)"] then
                song = MNM
            end
            
            local song_name = db:key_to_name(song)
            local actual_name = db:key_to_name(actual)
            local title = db:get_title_for_key(actual)
            local data = StoredSongs[title]
            
            if not data then
                for i,v in next, getloadedmodules() do
                    local req = require(v)
                    if (type(req) == 'table' and rawget(req, 'HitObjects')) then
                        StoredSongs[rawget(req, 'AudioFilename')] = req
                        if (rawget(req, 'AudioFilename') == title) then
                            data = req;
                        end
                    end
                end
            end
            
            local all = getupvalue(db.add_key_to_data, 1);

            all:add(song, data);
            data.__key = song;
            
            setupvalue(db.add_key_to_data, 1, all)
             
            return old_skp(self, song)
        end
        
        return as_self
    end
end

local colors = {
    [1] = Color3.fromRGB(255, 0, 0);
    [2] = Color3.fromRGB(255, 0, 0);
    [3] = Color3.fromRGB(255, 0, 0);
    [4] = Color3.fromRGB(255, 0, 0);
}

local TrackSystem
local get_local_elements_folder
local vip
local WebNPCManager
local SPRemoteEvent 
local GameUtilities
local MenuManager
local Client
local SongSpeedValue = 1000

local SongVolume = 1

local Main = Autoplayer:Section("Main")

Main:Toggle("Block Input")

local Utils = Misc:Section("Utilities")

Utils:Slider("Song Speed", {min = 0, max = 5000, default = 1000}, function(value)
    SongSpeedValue = value
end)

Utils:Slider("Song Volume", {min = 1, max = 100, default = 10}, function(Value)
    SongVolume = Value / 10
end)

local SongId = Utils:Label("Song ID : ")

for i,v in next, getgc(true) do
    if type(v) == 'table' then
        if rawget(v, 'key_has_combineinfo') then
            Database = v;
        end

        if rawget(v, "input_began") then 
            local input_began = v.input_began
            v.input_began = function(_, input) 
                if type(input) ~= "number" and input ~= Enum.KeyCode.Backspace and library.flags["Block Input"] then 
                    return
                end 
                return input_began(_, input)
            end
        end

        if rawget(v, "visit_webnpc") then
            visit_webnpc = v.visit_webnpc
        end 

        if rawget(v, "webnpcid_should_trigger_reward") then
            WebNPCManager = v
        end

        if rawget(v, "EVT_WebNPC_ServerAcknowledgeClientVisitNPC") then
            SPRemoteEvent = v
        end
        
        if rawget(v, "fire_event_to_server") then
            GameUtilities = v
        end
        
        if rawget(v, "visit_webnpc") then
            MenuManager = v
        end

        if rawget(v, "_player_blob_manager") and typeof(v._player_blob_manager) == "table" then
            Client = v
        end

        if rawget(v, 'playerblob_has_vip_for_current_day') then
            vip = v
        end

        if type(rawget(v, 'new')) == 'function' and islclosure(v.new) then
            local new = v.new
            local finding = {"get_default_base_color_list", "get_default_fever_color_list"};
            local found = 0;
            for _, bruh in next, getconstants(new) do
                if (bruh == 'on_songkey_pressed') then
                    table.insert(Applying, #Applying+1, v)
                end
                if (table.find(finding, bruh)) then
                    found = found + 1
                end
            end
            if (found >= #finding) and not TrackSystem then
                TrackSystem = v;
            end
        end	

        if rawget(v, "TimescaleToDeltaTime") then 
            local OldTTDT = v.TimescaleToDeltaTime
            v.TimescaleToDeltaTime = function(...)
                local args = {...}
                args[2] = args[2] * (SongSpeedValue / 1000)
                return OldTTDT(unpack(args))
            end
        end

        if rawget(v, 'color3_for_slot') then 
            local old = v.color3_for_slot
            v.color3_for_slot = function(self, ...)
                local orig = old(self, ...)
                if not library.flags["Note Colors"] then 
                    return orig 
                end
                return colors[self:get_track_index()] or orig
            end
        end

        if rawget(v, 'get_local_elements_folder') then 
            get_local_elements_folder = v.get_local_elements_folder 
        end
    end
end

for _,AllSongs in next, Applying do
    Apply(AllSongs, Database)
end

local playerblob_has_vip_for_current_day = vip.playerblob_has_vip_for_current_day

Main:Toggle("Autoplayer")

local Percentages = Autoplayer:Section("Percentages")

Percentages:Slider("Perfect Percentage", {min = 0, max = 100, default = 100}, function(value)
    HitPercentages.Perfect = value
    Utilities.updatehitpct();
end)

Percentages:Slider("Great Percentage", {min = 0, max = 100, default = 0}, function(value)
    HitPercentages.Great = value
    Utilities.updatehitpct();
end)

Percentages:Slider("Okay Percentage", {min = 0, max = 100, default = 0}, function(value)
    HitPercentages.Okay = value
    Utilities.updatehitpct();
end)

Percentages:Slider("Miss Percentage", {min = 0, max = 100, default = 0}, function(value)
    HitPercentages.Okay = value
    Utilities.updatehitpct();
end)

Utils:Toggle("Unlock All Songs (locks score)", false, function(value)
    if value then 
        vip.playerblob_has_vip_for_current_day = function()
            return true 
        end 
    else 
        vip.playerblob_has_vip_for_current_day = playerblob_has_vip_for_current_day
    end
end)

Utils:Button("Collect NPC Rewards", function()
    for Index, Value in next, getupvalue(WebNPCManager.webnpcid_should_trigger_reward, 1)._table do
        MenuManager:visit_webnpc(Index, function() end)
        wait(1)
        
        Client._player_blob_manager:do_sync(function()
            GameUtilities:fire_event_to_server(SPRemoteEvent.EVT_PlayerBlob_ClientRequestSync)
        end)
    end
end)

local NoteColors = Misc:Section("Note Colors")

NoteColors:Toggle("Note Colors")

for i = 1, 4 do 
    NoteColors:ColorPicker("Note Track "..tostring(i), Color3.fromRGB(255, 0, 0), function(value)
        colors[i] = value
    end)
end

game:GetService('RunService').Heartbeat:Connect(function()
    local elements = get_local_elements_folder()
    local sound = elements and elements:FindFirstChildWhichIsA("Sound")
    if (sound) then
        SongId:Update("Song ID : " .. tostring(sound.SoundId):sub(14));
    end
end)

local function update_autoplayer(_game, target_delay)
    local localSlot = getupvalue(_game.set_local_game_slot, 1)
    local trackSystem = Utilities.get_tracksystems(_game)._table[localSlot]
    local Notes = Utilities.get_notes(trackSystem)
    local Target = -math.abs(target_delay)
    local current_song = get_local_elements_folder():FindFirstChildWhichIsA("Sound")

    if current_song then 
        current_song.PlaybackSpeed = SongSpeedValue / 1000
        if current_song.Volume > 0 then
            current_song.Volume = SongVolume
        end
    end

    for Index = 1, Notes:count() do
        local Note = Notes:get(Index)
        if Note then
            local NoteTrack = Note:get_track_index(Index)
            if ( HeldNotes[NoteTrack] and Utilities.get_func(Note, TEST_RELEASE) ) then
                local released, result, delay = Utilities.get_func(Note, TEST_RELEASE)(Note, _game, 0)
                if (released and delay >= Target) then
                    HeldNotes[NoteTrack] = nil
                    Utilities.get_func(trackSystem, RELEASE_TRACK)(trackSystem, _game, NoteTrack)
                    return true
                end
            elseif (library.flags["Autoplayer"] and Utilities.get_func(Note, TEST_HIT)) then
                local hit, result, delay = Utilities.get_func(Note, TEST_HIT)(Note, _game, 0)
                if hit and delay >= Target then
                    Utilities.get_func(trackSystem, PRESS_TRACK)(trackSystem, _game, NoteTrack)
                    _game:debug_any_press()
    
                    if (type(Note.get_time_to_end) == 'nil') then
                        HeldNotes[NoteTrack] = true
                    else
                        wait(0.05)
                        Utilities.get_func(trackSystem, RELEASE_TRACK)(trackSystem, _game, NoteTrack)
                    end
                end
            end
        end
    end
end

local old_new = TrackSystem.new;
TrackSystem.new = function(...)
    local self = old_new(...)
    local old_update
    for i,v in next, self do 
        if type(v) == "function" then 
            local c = getconstants(v)
            if table.find(c, "do_remove") and table.find(c, "remove_at") then 
                old_update = v
                rawset(self, getinfo(v).name, function(shit, slot, _game)
                    if library.flags["Autoplayer"] then
                        local delay = Utilities.get_target_delay_from_noteresult(Utilities.get_noteresult()) or 25
                        coroutine.wrap(update_autoplayer)(_game, delay)
                    end
                    return old_update(self, slot, _game)
                end)
                break
            end
        end 
    end
    return self;
end
