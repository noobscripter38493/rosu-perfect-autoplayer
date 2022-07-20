local settings = {
    autoplayer = false,
    playing = false,
    hitdelay = 0, 
    mindelay = 0,
    maxdelay = 0
}

local orion = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
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
    Max = 5,
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
    Max = 5,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 1,
    ValueName = "ms",
    Callback = function(v)
        settings.maxdelay = v / 1000
    end
})

local core
local NoteResult
local notes = {}
local gc = getgc(true)
for i = 1, #gc do
    local v = gc[i]
    if typeof(v) == "table" then
        local gamestart = rawget(v, "new")
        if typeof(gamestart) == "function" then
            local source = getinfo(gamestart).source
            
            if source:match("Local.GameLocal") then
                local old; old = hookfunc(v.new, function(...)
                    core = old(...)
                    settings.playing = true
                    
                    local old2 = core.teardown_game
                    core.teardown_game = function(...)
                        settings.playing = false
                        table.clear(notes)
                        return old2(...) 
                    end
                    
                    return core
                end)
                
            elseif source == "=ReplicatedStorage.Local.Note" then
                local old3; old3 = hookfunc(v.new, function(self, _, track, ...)
                    local note = old3(self, _, track, ...)

                    notes[#notes + 1] = note    
                    note.track = track
                    
                    return note
                end)
            
            elseif source == "=ReplicatedStorage.Local.HeldNote" then
                local old4; old4 = hookfunc(v.new, function(self, _1, track, _2, _3, p6, p7, ...)
                    local heldnote = old4(self, _1, track, _2, _3, p6, p7, ...)
                    notes[#notes + 1] = heldnote
                    heldnote.track = track

                    local old5 = heldnote.update
                    heldnote.update = function(...)
                        local o = old5(...) -- update the value before grabbing it (just calls function)
                        local u11 = getupvalue(old5, 2)

                        heldnote.press = u11 - p6
                        heldnote.release = u11 - (p6 + p7)
                        
                        return o
                    end
                
                    return heldnote
                end)
            end
            
        elseif rawget(v, "timedelta_to_result") then
            NoteResult = v
        end
    end
end

repeat task.wait(.1) until core and notes[1] and NoteResult
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

local uis = game:GetService("UserInputService")
while true do
    if not settings.autoplayer or not settings.playing then task.wait(1) continue end
    for i = 1, #notes do
        local note = notes[i] or {hit = true}
        
        if note.hit then continue end
        
        if note.get_time_to_end then
            note.press = note:get_time_to_end()
            note.release = note:get_time_to_end()
        end
        
        local _, press = NoteResult:timedelta_to_result(note.press, core)
        if press == 5 and not note.hit then
            note.hit = true
            spawn(function()
                if settings.hitdelay then
                    delay()
                end

                setThreadIdentity(2)
                firesignal(uis.InputBegan, {KeyCode = tracks[note.track], UserInputType = Enum.UserInputType.Keyboard}, false)
                
                local release
                repeat 
                    _, release = NoteResult:release_timedelta_to_result(note.release, core)
                    task.wait() 
                until release == 5
                
                if settings.hitdelay then
                    delay()
                end

                firesignal(uis.InputEnded, {KeyCode = tracks[note.track], UserInputType = Enum.UserInputType.Keyboard}, false)
                setThreadIdentity(7)
            end)
        end
    end
    
    task.wait() 
end
