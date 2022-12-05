game.Players.LocalPlayer:Kick("patched")
wait(9e9)
---@diagnostic disable: redundant-parameter
local settings = {
    autoplayer = false,
    playing = false,
    hitdelay = 0, 
    mindelay = 0,
    maxdelay = 0
}

local orion = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()
repeat task.wait() until orion
local window = orion:MakeWindow({
    Name = "rosu! Perfect Autoplayer",
    HidePremium = false,
    SaveConfig = false,
    ConfigFolder = ""
})

local autoplayer_tab = window:MakeTab({
    Name = "Autoplayer",
    Icon = "",
    PremiumOnly = false
})

autoplayer_tab:AddToggle({
    Name = "Autoplayer",
    Default = false,
    Callback = function(bool)
        settings.autoplayer = bool
    end
})

autoplayer_tab:AddParagraph("Hit Delay", "Hit Delay is a random number between your min & max")
autoplayer_tab:AddToggle({
    Name = "Hit Delay",
    Default = false,
    Callback = function(bool)
        settings.hitdelay = bool
    end
})

autoplayer_tab:AddSlider({
    Name = "Hit Delay Min (ms)",
    Min = 0,
    Max = 1000,
    Default = 0,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 1,
    ValueName = "ms",
    Callback = function(v)
        settings.mindelay = v / 1000
    end
})

autoplayer_tab:AddSlider({
    Name = "Hit Delay Max (ms)", 
    Min = 0,
    Default = 0,
    Max = 1000,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 1,
    ValueName = "ms",
    Callback = function(v)
        settings.maxdelay = v / 1000
    end
})

local function copy_table(t)
    local c = {}
    
    for i, v in next, t do
        c[i] = v
    end
    
    return c
end

local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local function err()
    plr:Kick("Possible script patch\nError Line: " .. getinfo(2).currentline)
end

local notes = {}
local core  
local songrate
local fakekeys = {}
local gc = getgc(true)
local spawn = task.spawn
for i = 1, #gc do
    local v = gc[i]
    if typeof(v) == "function" and islclosure(v) then
        local heldnoteproto = getprotos(v)[10]
        if heldnoteproto and getconstants(heldnoteproto)[3] == "HeldNoteProto" then
            local old1; old1 = hookfunc(v, function(self, _1, track, _2, _3, p6, p7, ...)
                local heldnote = old1(self, _1, track, _2, _3, p6, p7, ...)
                    
                if typeof(heldnote) ~= "table" then err() return heldnote end
                if typeof(rawget(heldnote, "update")) ~= "function" then err() return heldnote end
                
                local t = copy_table(heldnote)
                t.held = true
                t.track = track
                notes[#notes + 1] = t

                local old5 = heldnote.update
                heldnote.update = function(...)
                    local o = old5(...)
                    local u11 = getupvalue(old5, 2)

                    if typeof(u11) ~= "number" then err() return o end

                    t.press = u11 - p7
                    t.release = u11 - (p6 + p7)
                    
                    return o
                end

                return heldnote
            end)
        end
        
        local noteproto = getprotos(v)[5]
        if noteproto and getconstants(noteproto)[3] == "NoteProto" then
            local old3; old3 = hookfunc(v, function(self, _1, track, p4, _2, p6, ...)
                local note = old3(self, _1, track, p4, _2, p6, ...)
                if typeof(note) ~= "table" then err() return note end
                if typeof(p4) ~= "number" or typeof(p6) ~= "number" then err() return note end
                if typeof(rawget(note, "update")) ~= "function" then err() return note end
                if typeof(rawget(note, "get_time_to_end")) ~= "function" then err() return note end
                
                local t = copy_table(note)
                t.track = track
                t.held = false
                notes[#notes + 1] = t
                
                local old6 = note.get_time_to_end
                note.get_time_to_end = function(...)
                    local o = old6(...)
                    local u8 = getupvalue(old6, 3)
                    if typeof(u8) ~= "number" then err() return o end

                    t.press = (p4 - p6) * (1 - u8)
                    t.release = (p4 - p6) * (1 - u8)

                    return o
                end

                return note
            end)
        end
        
    elseif typeof(v) == "table" then
        local new = rawget(v, "new")
        if typeof(new) == "function" and islclosure(new) then
            spawn(function()
                local gamelocal = getprotos(new)[3]
                if not gamelocal then return end
                
                local constants = getconstants(gamelocal)
                if constants[1] ~= 1000 or constants[2] ~= "_audio_manager" or constants[3] ~= "get_song_length_ms" then return end

                local old = v.new
                v.new = function(...)
                    local temp = old(...)
                    
                    if getconstant(2, 1) ~= "print" or getconstant(2, 3) ~= ">> Song Rate: " then err() return temp end
                    if typeof(temp) ~= "table" then err() return temp end
                    if typeof(rawget(temp, "_audio_manager")) ~= "table" then err() return temp end
                    if typeof(rawget(temp._audio_manager, "load_song")) ~= "function" then err() return temp end
                    if typeof(rawget(temp, "teardown_game")) ~= "function" then err() return temp end
                    if typeof(rawget(temp, "start_game")) ~= "function" then err() return temp end
                    
                    core = temp
                    settings.playing = true
                    
                    local old2 = temp.teardown_game
                    temp.teardown_game = function(...)
                        settings.playing = false
                        table.clear(fakekeys)
                        table.clear(notes)
                        
                        return old2(...)
                    end

                    local old7 = temp._audio_manager.load_song
                    temp._audio_manager.load_song = function(...)
                        local o = old7(...)
			local temp = getupvalue(old7, 2)
			if typeof(temp) ~= "number" then err() return o end	
                        songrate = temp

                        return o
                    end
                    
                    return temp
                end
            end)
        end
    end
end

repeat task.wait(.1) until core and notes[1]
local spawn = task.spawn
local firesignal = firesignal
local setThreadIdentity = syn and syn.set_thread_identity or setthreadcontext

local keys = game.ReplicatedStorage.Configuration.Keybinds
local tracks = {}

local children = keys:GetChildren()
for i = 1, 4 do
    local v = children[i]
    tracks[#tracks + 1] = Enum.KeyCode[v.Value]
    
    v:GetPropertyChangedSignal("Value"):Connect(function()
        table.clear(tracks)
        
        local children = keys:GetChildren()
        for i2 = 1, 4 do
            local v = children[i2]
            tracks[#tracks + 1] = Enum.KeyCode[v.Value]
        end
    end)
end

local rand = Random.new()
local function delay()
    local mindelay = settings.mindelay
    local maxdelay = settings.maxdelay

    task.wait(rand:NextNumber(mindelay, maxdelay) / 10)
end

local rates = { 
	timedelta_to_result = function(self, p2, p3)
		p2 = p2 / songrate
        	return -20 < p2 and p2 <= 20
	end, 
	release_timedelta_to_result = function(self, p5, p6)
		p5 = p5 / songrate

        return -40 < p5 and p5 <= 40
	end
}

local uis = game:GetService("UserInputService")
local realkeys = {}
--local ban = game.ReplicatedStorage:FindFirstChild("GameEvent")
local nc; nc = hookmetamethod(game, "__namecall", function(self, ...)
    local ncm = getnamecallmethod()
    
    if self == uis then
        if ncm == "GetKeysPressed" then
            local o = {}
            local count = 1
            for _, v in next, fakekeys do
                o[count] = v
                count = count + 1
            end
            
            return o
        end

        local args = {...}
        local keycode = args[1]
        if ncm == "IsKeyDown" and typeof(keycode) == "EnumItem" then
            local keydown
            for i = 1, #fakekeys do
                local v = fakekeys[i]
                if v.KeyCode == keycode then
                    return true
                end
            end
            
            for i = 1, #realkeys do
                local v = realkeys[i]
                if v.KeyCode == keycode then
                    return true 
                end
            end
        end

        ]]
   --elseif self == ban and self.IsA(self, "RemoteEvent") and ncm == "FireServer" then
        --print(debug.traceback())
        --
        --return
    end
    
    return nc(self, ...)
end)

local old8; old8 = hookfunc(uis.GetKeysPressed, function(self, ...)
    if self == uis then
        local o = {}
        local count = 1
        for _, v in next, fakekeys do
            o[count] = v
            count = count + 1
        end
        
        return o
    end
    
    return old8(self, ...)
end)

game.UserInputService.InputBegan:Connect(function(key)
    if key.UserInputType == Enum.UserInputType.Keyboard then
        local children = keys:GetChildren()
        for i = 1, #children do
            local v = children[i]

            if key.KeyCode == Enum.KeyCode[v.Value] then return end
        end

        realkeys[#realkeys + 1] = key
    end
end)

game.UserInputService.InputEnded:Connect(function(key)
    if key.UserInputType == Enum.UserInputType.Keyboard then
        local i = table.find(realkeys, key)
        if i then
            realkeys[i] = nil 
        end
    end
end)

local mouse = plr:GetMouse()
while true do
    if not settings.autoplayer or not settings.playing then task.wait(1) continue end
    
    for i = 1, #notes do
        local note = notes[i] or {hit = true}
        if note.hit then continue end
        
        local press = rates:timedelta_to_result(note.press, core)
        if press and not note.hit then
            note.hit = true
            
            spawn(function()
                if settings.hitdelay then
                    delay()
                end
                
                local t = {KeyCode = tracks[note.track], UserInputType = Enum.UserInputType.Keyboard}
                local key = keys:GetChildren()[note.track].Value:lower()
                fakekeys[t] = t
                spawn(firesignal, mouse.KeyDown, key)
                
                setThreadIdentity(2)
                spawn(firesignal, uis.InputBegan, t, false)
                
                local release
                repeat
                    release = rates:release_timedelta_to_result(note.release, core)
                    task.wait() 
                until release
                
                if settings.hitdelay then
                    delay()
                end
                
                spawn(firesignal, uis.InputEnded, t, false)
                setThreadIdentity(7)
                
                fakekeys[t] = nil
                spawn(firesignal, mouse.KeyUp, key)
            end)
        end
    end
    
    task.wait()
end
