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
    Name = "rosu! Perfect Autoplayer | Made By avg#1496",
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

local notes = {}
local core  
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
                    
                if typeof(heldnote) ~= "table" then return heldnote end
                if typeof(rawget(heldnote, "update")) ~= "function" then return heldnote end
                
                local t = copy_table(heldnote)
                t.held = true
                t.track = track
                notes[#notes + 1] = t

                local old5 = heldnote.update
                heldnote.update = function(...)
                    local o = old5(...)
                    local u11 = getupvalue(old5, 2)

                    t.press = u11 - p7
                    t.release = u11 - (p6 + p7)
                    
                    return o
                end

                return heldnote
            end)
        end
        
        local noteproto = getprotos(v)[5]
        if noteproto and getconstants(noteproto)[3] == "NoteProto" then
            local old3; old3 = hookfunc(v, function(self, _, track, ...)
                local note = old3(self, _, track, ...)
                if typeof(note) ~= "table" then return note end
                
                local t = copy_table(note)
                t.track = track
                t.held = false
                notes[#notes + 1] = t
                
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
                    
                    if getconstant(2, 1) ~= "print" or getconstant(2, 3) ~= ">> Song Rate: " then return temp end
                    if typeof(temp) ~= "table" then return temp end
                    if typeof(rawget(temp, "teardown_game")) ~= "function" then return temp end
                    
                    core = temp
                    settings.playing = true
                    
                    local old2 = temp.teardown_game
                    temp.teardown_game = function(...)
                        settings.playing = false
                        table.clear(fakekeys)
                        table.clear(notes)
                        
                        return old2(...)
                    end
                    
                    return temp
                end
            end)
            --[[
            spawn(function()
                local noteproto = getprotos(new)[5]
                if noteproto and getconstants(noteproto)[3] == "NoteProto" then
                    local old3; old3 = hookfunc(new, function(self, _, track, ...)
                        print('lol')
                        local note = old3(self, _, track, ...)
                        if typeof(note) ~= "table" then return note end
                        
                        notes[#notes + 1] = copy_table(note)
                        notes[#notes].track = track
                        
                        return note
                    end)
                end
            end)

            local heldnoteproto = getprotos(new)[10]
            if heldnoteproto and getconstants(heldnoteproto)[3] == "HeldNoteProto" then
                local old4; old4 = hookfunc(new, function(self, _1, track, _2, _3, p6, p7, ...)
                    local heldnote = old4(self, _1, track, _2, _3, p6, p7, ...)
                    
                    if typeof(heldnote) ~= "table" then return heldnote end
                    if typeof(rawget(heldnote, "update")) ~= "function" then return heldnote end

                    notes[#notes + 1] = copy_table(heldnote)
                    
                    local t = notes[#notes]
                    t.track = track
                    
                    local old5 = heldnote.update
                    heldnote.update = function(...)
                        local o = old5(...)
                        local u11 = getupvalue(old5, 2)

                        t.press = u11 - p6
                        t.release = u11 - (p6 + p7)
                        
                        return o
                    end
                    
                    return heldnote
                end)
            end
            ]]
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

local function delay()
    local mindelay = settings.mindelay
    local maxdelay = settings.maxdelay

    local rand = Random.new()
    local t = rand:NextNumber(mindelay, maxdelay) / 10

    task.wait(t)
end

local rates = { 
    --[[
	Miss = 0, 
	Bad = 1, 
	Good = 2, 
	Great = 3, 
	Perfect = 4, 
	PerfectX = 5, 
	]]
	timedelta_to_result = function(self, p2, p3)
		p2 = p2 / p3._audio_manager.get_song_rate();

        return p3._audio_manager.NOTE_PERFECTX_MIN < p2 and p2 <= p3._audio_manager.NOTE_PERFECTX_MAX

        --[[
		if not (p3._audio_manager.NOTE_BAD_MIN <= p2) or not (p2 <= p3._audio_manager.NOTE_MISS_MAX) then
			return false, self.Miss
		end;
		
        
		local v1
		if p3._audio_manager.NOTE_BAD_MIN < p2 and p2 <= p3._audio_manager.NOTE_GOOD_MIN then
			v1 = self.Bad

		elseif p3._audio_manager.NOTE_GOOD_MIN < p2 and p2 <= p3._audio_manager.NOTE_GREAT_MIN then
			v1 = self.Good

		elseif p3._audio_manager.NOTE_GREAT_MIN < p2 and p2 <= p3._audio_manager.NOTE_PERFECT_MIN then
			v1 = self.Great

		elseif p3._audio_manager.NOTE_PERFECT_MIN < p2 and p2 <= p3._audio_manager.NOTE_PERFECTX_MIN then
			v1 = self.Perfect

		elseif p3._audio_manager.NOTE_PERFECTX_MIN < p2 and p2 <= p3._audio_manager.NOTE_PERFECTX_MAX then
			v1 = self.PerfectX

		elseif p3._audio_manager.NOTE_PERFECTX_MAX < p2 and p2 <= p3._audio_manager.NOTE_PERFECT_MAX then
			v1 = self.Perfect

		elseif p3._audio_manager.NOTE_PERFECT_MAX < p2 and p2 <= p3._audio_manager.NOTE_GREAT_MAX then
			v1 = self.Great

		elseif p3._audio_manager.NOTE_GREAT_MAX < p2 and p2 <= p3._audio_manager.NOTE_GOOD_MAX then
			v1 = self.Good

		elseif p3._audio_manager.NOTE_GOOD_MAX < p2 and p2 <= p3._audio_manager.NOTE_BAD_MAX then
			v1 = self.Bad
		else
			v1 = self.Miss
		end

		return true, v1]]
	end, 

	release_timedelta_to_result = function(self, p5, p6)
		p5 = p5 / p6._audio_manager.get_song_rate()

        return p6._audio_manager.NOTE_PERFECTX_MIN * 2 < p5 and p5 <= p6._audio_manager.NOTE_PERFECTX_MAX * 2

		--[[
        local v2    
        if not (p6._audio_manager.NOTE_BAD_MIN * 2 <= p5) or not (p5 <= p6._audio_manager.NOTE_BAD_MAX * 2) then
			return false, self.Miss
		end;
		if p6._audio_manager.NOTE_BAD_MIN * 2 < p5 and p5 <= p6._audio_manager.NOTE_GOOD_MIN * 2 then
			v2 = self.Bad

		elseif p6._audio_manager.NOTE_GOOD_MIN * 2 < p5 and p5 <= p6._audio_manager.NOTE_GREAT_MIN * 2 then
			v2 = self.Good

		elseif p6._audio_manager.NOTE_GREAT_MIN * 2 < p5 and p5 <= p6._audio_manager.NOTE_PERFECT_MIN * 2 then
			v2 = self.Great

		elseif p6._audio_manager.NOTE_PERFECT_MIN * 2 < p5 and p5 <= p6._audio_manager.NOTE_PERFECTX_MIN * 2 then
			v2 = self.Perfect

		elseif p6._audio_manager.NOTE_PERFECTX_MIN * 2 < p5 and p5 <= p6._audio_manager.NOTE_PERFECTX_MAX * 2 then
			v2 = self.PerfectX

		--elseif p6._audio_manager.NOTE_PERFECTX_MAX * 2 < p5 and p5 <= p6._audio_manager.NOTE_PERFECT_MAX * 2 then
			v2 = self.Perfect

		elseif p6._audio_manager.NOTE_PERFECT_MAX * 2 < p5 and p5 <= p6._audio_manager.NOTE_GREAT_MAX * 2 then
			v2 = self.Great

		elseif p6._audio_manager.NOTE_GREAT_MAX * 2 < p5 and p5 <= p6._audio_manager.NOTE_GOOD_MAX * 2 then
			v2 = self.Good

		else
			v2 = self.Bad
		end

		return true, v2]]
	end
}

local Players = game:GetService("Players")
local uis = game:GetService("UserInputService")
local realkeys = {}
local ban2 = game.ReplicatedStorage:FindFirstChild("GameEvent")
local ban = game.ReplicatedStorage:FindFirstChild("Ban")
local nc; nc = hookmetamethod(game, "__namecall", function(self, ...)
    local ncm = getnamecallmethod()
    
    if self == uis then
        if ncm == "GetKeysPressed" then
            return {unpack(fakekeys)} -- returns a different table each time
        end
        --[[
        local args = {...}
        local keycode = args[1]
        if ncm == "IsKeyDown" and typeof(keycode) == "EnumItem" then
            for _, v in next, fakekeys do
                if v.KeyCode == keycode then
                    return true 
                end
            end
            
            for _, v in next, realkeys do
                if v.KeyCode == keycode then
                    return true 
                end
            end
        end

        ]]
    elseif self == ban or self == ban2 and self.IsA(self, "RemoteEvent") and ncm == "FireServer" then
        --print(debug.traceback())
        
        return
    end
    
    return nc(self, ...)
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


local plr = Players.LocalPlayer
local mouse = plr:GetMouse()
while true do
    if not settings.autoplayer or not settings.playing then task.wait(1) continue end
    
    for i = 1, #notes do
        local note = notes[i] or {hit = true}
        
        if note.hit then continue end
        
        if not note.held then
            note.press = note:_get_time_to_end()
            note.release = note:_get_time_to_end()
        end
        
        local press = rates:timedelta_to_result(note.press, core)
        if press and not note.hit then
            note.hit = true

            spawn(function()
                if settings.hitdelay then
                    delay()
                end
                
                local t = {KeyCode = tracks[note.track], UserInputType = Enum.UserInputType.Keyboard}
                local key = keys:GetChildren()[note.track].Value:lower()
                table.insert(fakekeys, 1, t)
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
                
                fakekeys[table.find(fakekeys, t) or 9999] = nil
                spawn(firesignal, mouse.KeyUp, key)
            end)
        end
    end
    
    task.wait() 
end
