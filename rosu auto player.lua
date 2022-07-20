local core
local NoteResult
local notes = {}

local autoplayer
local playing
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
                    playing = true
                    
                    local old2 = core.teardown_game
                    core.teardown_game = function(...)
                        playing = false
                        table.clear(notes)
                        return old2(...) 
                    end
                    
                    return core
                end)
                
            elseif source == "=ReplicatedStorage.Local.Note" then
                local old3; old3 = hookfunc(v.new, function(self, b, track, ...)
                    local note = old3(self, b, track, ...)

                    notes[#notes + 1] = note    
                    note.track = track
                    
                    return note
                end)
            
            elseif source == "=ReplicatedStorage.Local.HeldNote" then
                local old4; old4 = hookfunc(v.new, function(self, b, track, _1, _2, p6, p7, ...)
                    local heldnote = old4(self, b, track, _1, _2, p6, p7, ...)
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

local orion = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local window = orion:MakeWindow({
    Name = "rosu! Perfect Autoplayer | Made By avg#1496",
    HidePremium = false,
    SaveConfig = false,
    ConfigFolder = "OrionTest"
})
local autoplayer_tab = window:MakeTab({
    Name = "Autoplayer",
    Icon = "",
    PremiumOnly = false
})

autoplayer_tab:AddToggle({
    Name = "Autoplayer Toggle",
    Default = false,
    Callback = function(bool)
        autoplayer = bool
    end
})

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

local uis = game:GetService("UserInputService")
while true do
    if not autoplayer or not playing then task.wait(1) continue end
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
                setThreadIdentity(2)
                firesignal(uis.InputBegan, {KeyCode = tracks[note.track], UserInputType = Enum.UserInputType.Keyboard}, false)
                
                local release
                repeat 
                    _, release = NoteResult:release_timedelta_to_result(note.release, core)
                    task.wait() 
                until release == 5
                
                firesignal(uis.InputEnded, {KeyCode = tracks[note.track], UserInputType = Enum.UserInputType.Keyboard}, false)
                setThreadIdentity(7)
            end)
        end
    end
    
    task.wait() 
end