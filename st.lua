-- STD_Delta.lua — Universal (Delta Mobile + Real PC)
-- game: Sorcerer Tower Defense | 17720162456

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService       = game:GetService("HttpService")

local lp = Players.LocalPlayer

local G = {
    AutoWave     = false,
    AutoPlace    = false,
    AutoUpgrade  = false,
    AutoSell     = false,
    WaveDelay    = 1.5,
    MaxLevel     = 5,
    Running      = true,

    -- Macro
    IsRecording  = false,
    IsPlaying    = false,
    MacroCache   = {},
    RecordStartTime = 0,

    -- Teleportes e Loop
    PosRaid      = nil,
    PosCassino   = nil,
    AutoRaid     = false,
    AutoCassino  = false,
}

-- ══════════════════════════════════════════════
--  SISTEMA DE SALVAR/CARREGAR MACRO
-- ══════════════════════════════════════════════
local MACRO_FILE = "STD_Macro.json"

local function saveMacroToFile()
    if #G.MacroCache == 0 then return false end
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(G.MacroCache)
    end)
    if success then
        local writeSuccess = pcall(function()
            writefile(MACRO_FILE, encoded)
        end)
        return writeSuccess
    end
    return false
end

local function loadMacroFromFile()
    local exists = pcall(function() return isfile(MACRO_FILE) end)
    if not exists then return false end
    
    local readSuccess, content = pcall(function()
        return readfile(MACRO_FILE)
    end)
    if readSuccess and content then
        local decodeSuccess, data = pcall(function()
            return HttpService:JSONDecode(content)
        end)
        if decodeSuccess and type(data) == "table" then
            G.MacroCache = data
            return true
        end
    end
    return false
end

-- ══════════════════════════════════════════════
--  SISTEMA DE TELEPORTE E AUTO-RETORNO
-- ══════════════════════════════════════════════
local function tpTo(cframe)
    if cframe and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        lp.Character.HumanoidRootPart.CFrame = cframe
    end
end

task.spawn(function()
    while G.Running do
        if G.AutoRaid and G.PosRaid then
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and (hrp.Position - G.PosRaid.Position).Magnitude > 50 then
                task.wait(2)
                if G.AutoRaid then tpTo(G.PosRaid) end
            end
        end

        if G.AutoCassino and G.PosCassino then
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and (hrp.Position - G.PosCassino.Position).Magnitude > 50 then
                task.wait(2)
                if G.AutoCassino then tpTo(G.PosCassino) end
            end
        end
        task.wait(1)
    end
end)

-- ══════════════════════════════════════════════
--  DETECÇÃO DE REMOTES
-- ══════════════════════════════════════════════
local REMOTES = { StartWave=nil, PlaceTower=nil, UpgradeTower=nil, SellTower=nil }
local PATTERNS = {
    StartWave    = {"wave","start","next","begin","round"},
    PlaceTower   = {"place","spawn","deploy","summon","set"},
    UpgradeTower = {"upgrade","level","improve","enhance"},
    SellTower    = {"sell","remove","refund"},
}

local function matchesPattern(name, list)
    name = name:lower()
    for _, p in ipairs(list) do
        if name:find(p) then return true end
    end
    return false
end

local function scanRemotes()
    local found = 0
    local function scan(parent)
        for _, v in ipairs(parent:GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                for key, patterns in pairs(PATTERNS) do
                    if not REMOTES[key] and matchesPattern(v.Name, patterns) then
                        REMOTES[key] = v
                        found = found + 1
                    end
                end
            end
        end
    end
    pcall(scan, ReplicatedStorage)
    pcall(scan, workspace)
    return found
end

task.spawn(function()
    while G.Running do
        scanRemotes()
        task.wait(4)
    end
end)

local function safe(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then warn("[STD] " .. tostring(err)) end
end

-- ══════════════════════════════════════════════
--  UTILITÁRIOS DE JOGO
-- ══════════════════════════════════════════════
local slotCache, towerCache, cacheTime = {}, {}, 0
local CACHE_TTL = 2

local function refreshCache()
    if os.clock() - cacheTime < CACHE_TTL then return end
    cacheTime = os.clock()
    slotCache, towerCache = {}, {}
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local n = v.Name:lower()
            if n:find("slot") or n:find("node") or n:find("place") or n:find("point") then
                table.insert(slotCache, v)
            end
        elseif v:IsA("Model") then
            local ow = v:FindFirstChild("Owner") or v:FindFirstChild("PlayerId")
            if ow and (ow.Value == lp.UserId or ow.Value == lp.Name) then
                table.insert(towerCache, v)
            end
        end
    end
end

local function getSlots()   refreshCache() return slotCache  end
local function getMyTowers() refreshCache() return towerCache end

-- ══════════════════════════════════════════════
--  LOOPS DE AUTOMAÇÃO
-- ══════════════════════════════════════════════
task.spawn(function()
    while G.Running do
        if G.AutoWave and REMOTES.StartWave then
            safe(function() REMOTES.StartWave:FireServer() end)
        end
        task.wait(G.WaveDelay)
    end
end)

task.spawn(function()
    while G.Running do
        if G.AutoPlace and REMOTES.PlaceTower then
            local slots  = getSlots()
            local towers = getMyTowers()
            if #towers < #slots then
                for i = #towers + 1, math.min(#towers + 3, #slots) do
                    local slot = slots[i]
                    if slot then
                        safe(function() REMOTES.PlaceTower:FireServer(slot.CFrame) end)
                        safe(function() REMOTES.PlaceTower:FireServer(slot.Position) end)
                        task.wait(0.15)
                    end
                end
            end
        end
        task.wait(1)
    end
end)

task.spawn(function()
    while G.Running do
        if G.AutoUpgrade and REMOTES.UpgradeTower then
            for _, tower in ipairs(getMyTowers()) do
                local lvl = tower:FindFirstChild("Level") or tower:FindFirstChild("Upgrades") or tower:FindFirstChild("Tier")
                local cur = lvl and lvl.Value or 0
                if cur < G.MaxLevel then
                    safe(function() REMOTES.UpgradeTower:FireServer(tower) end)
                    task.wait(0.1)
                end
            end
        end
        task.wait(1.2)
    end
end)

task.spawn(function()
    while G.Running do
        if G.AutoSell and REMOTES.SellTower then
            for _, tower in ipairs(getMyTowers()) do
                local lvl = tower:FindFirstChild("Level")
                if lvl and lvl.Value >= G.MaxLevel then
                    safe(function() REMOTES.SellTower:FireServer(tower) end)
                    task.wait(0.2)
                end
            end
        end
        task.wait(2)
    end
end)

-- ══════════════════════════════════════════════
--  SISTEMA DE MACRO (GRAVAR/REPRODUZIR)
-- ══════════════════════════════════════════════
local recordConn = nil

local function startRecording()
    if G.IsRecording then return end
    G.IsRecording = true
    G.IsPlaying = false
    G.MacroCache = {}
    G.RecordStartTime = os.clock()

    recordConn = UserInputService.InputBegan:Connect(function(input, gp)
        if gp or not G.IsRecording then return end
        local now = os.clock() - G.RecordStartTime
        local entry
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            entry = { Type = "Click", X = input.Position.X, Y = input.Position.Y, Time = now }
        elseif input.UserInputType == Enum.UserInputType.Keyboard then
            entry = { Type = "Key", KeyCode = input.KeyCode.Name, Time = now }
        end
        if entry then table.insert(G.MacroCache, entry) end
    end)
end

local function stopRecording()
    if not G.IsRecording then return end
    G.IsRecording = false
    if recordConn then recordConn:Disconnect() recordConn = nil end
end

local playTask = nil

local function stopPlayback()
    G.IsPlaying = false
    if playTask then task.cancel(playTask) playTask = nil end
end

local function playMacro()
    if G.IsRecording or #G.MacroCache == 0 then return end
    G.IsPlaying = true

    playTask = task.spawn(function()
        while G.IsPlaying do
            local start = os.clock()
            for _, a in ipairs(G.MacroCache) do
                if not G.IsPlaying then break end
                local waitTime = (start + a.Time) - os.clock()
                if waitTime > 0 then task.wait(waitTime) end

                if a.Type == "Click" then
                    VirtualInputManager:SendMouseButtonEvent(a.X, a.Y, 0, true, game, 1)
                    task.wait(0.03)
                    VirtualInputManager:SendMouseButtonEvent(a.X, a.Y, 0, false, game, 1)
                elseif a.Type == "Key" then
                    local key = Enum.KeyCode[a.KeyCode]
                    if key then
                        VirtualInputManager:SendKeyEvent(true, key, false, game)
                        task.wait(0.05)
                        VirtualInputManager:SendKeyEvent(false, key, false, game)
                    end
                end
            end
            task.wait(0.5)
        end
    end)
end

-- ══════════════════════════════════════════════
--  GUI - DESIGN MELHORADO
-- ══════════════════════════════════════════════
local playerGui = lp:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("STD_Mobile") then
    playerGui:FindFirstChild("STD_Mobile"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "STD_Mobile"
ScreenGui.ResetOnSpawn   = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder   = 999
ScreenGui.Parent         = playerGui

local C = {
    BG      = Color3.fromRGB(12, 12, 18),
    Surface = Color3.fromRGB(22, 22, 35),
    Accent  = Color3.fromRGB(120, 60, 220),
    AccentL = Color3.fromRGB(160, 100, 255),
    Text    = Color3.fromRGB(240, 240, 250),
    Dim     = Color3.fromRGB(130, 130, 150),
    Green   = Color3.fromRGB(80, 220, 120),
    Red     = Color3.fromRGB(230, 70, 70),
    Border  = Color3.fromRGB(50, 50, 75),
}

local W = 310
local Main = Instance.new("Frame")
Main.Size              = UDim2.new(0, W, 0, 50)
Main.Position          = UDim2.new(0, 10, 0, 60)
Main.BackgroundColor3  = C.BG
Main.BorderSizePixel   = 0
Main.ClipsDescendants  = true
Main.Parent            = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)
local stroke = Instance.new("UIStroke", Main)
stroke.Color, stroke.Thickness, stroke.Transparency = C.Accent, 1.5, 0.2

-- Barra de título
local Bar = Instance.new("Frame")
Bar.Size             = UDim2.new(1, 0, 0, 50)
Bar.BackgroundColor3 = C.Surface
Bar.BorderSizePixel  = 0
Bar.ZIndex           = 5
Bar.Parent           = Main
Instance.new("UICorner", Bar).CornerRadius = UDim.new(0, 14)

local barFix = Instance.new("Frame")
barFix.Size             = UDim2.new(1, 0, 0.5, 2)
barFix.Position         = UDim2.new(0, 0, 0.5, 0)
barFix.BackgroundColor3 = C.Surface
barFix.BorderSizePixel  = 0
barFix.ZIndex           = 4
barFix.Parent           = Bar

local Title = Instance.new("TextLabel")
Title.Text             = "⟡  Sorcerer TD"
Title.Size             = UDim2.new(1, -100, 1, 0)
Title.Position         = UDim2.new(0, 16, 0, 0)
Title.BackgroundTransparency = 1
Title.TextColor3       = C.Text
Title.Font             = Enum.Font.GothamBold
Title.TextSize         = 15
Title.TextXAlignment   = Enum.TextXAlignment.Left
Title.ZIndex           = 6
Title.Parent           = Bar

local MinBtn = Instance.new("TextButton")
MinBtn.Text, MinBtn.Size, MinBtn.Position = "−", UDim2.new(0, 36, 0, 36), UDim2.new(1, -86, 0.5, -18)
MinBtn.BackgroundColor3, MinBtn.TextColor3 = C.Border, C.Text
MinBtn.Font, MinBtn.TextSize, MinBtn.BorderSizePixel = Enum.Font.GothamBold, 20, 0
MinBtn.ZIndex, MinBtn.Parent = 7, Bar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 8)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Text, CloseBtn.Size, CloseBtn.Position = "✕", UDim2.new(0, 36, 0, 36), UDim2.new(1, -44, 0.5, -18)
CloseBtn.BackgroundColor3, CloseBtn.TextColor3 = C.Red, Color3.new(1,1,1)
CloseBtn.Font, CloseBtn.TextSize, CloseBtn.BorderSizePixel = Enum.Font.GothamBold, 16, 0
CloseBtn.ZIndex, CloseBtn.Parent = 7, Bar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

-- Drag
do
    local drag, dragStart, startPos
    local function beginDrag(pos) drag = true dragStart = pos startPos = Main.Position end
    local function moveDrag(pos)
        if not drag then return end
        local d = pos - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
    local function endDrag() drag = false end
    Bar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then beginDrag(inp.Position) end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseMovement then moveDrag(inp.Position) end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then endDrag() end
    end)
end

local CONTENT_H = 600
local Content = Instance.new("ScrollingFrame")
Content.Size, Content.Position = UDim2.new(1, 0, 0, CONTENT_H), UDim2.new(0, 0, 0, 50)
Content.BackgroundTransparency, Content.BorderSizePixel = 1, 0
Content.ScrollBarThickness, Content.ScrollBarImageColor3 = 4, C.Accent
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.Parent = Main

local Layout = Instance.new("UIListLayout", Content)
Layout.Padding, Layout.SortOrder = UDim.new(0, 8), Enum.SortOrder.LayoutOrder
local Pad = Instance.new("UIPadding", Content)
Pad.PaddingLeft, Pad.PaddingRight = UDim.new(0, 12), UDim.new(0, 12)
Pad.PaddingTop, Pad.PaddingBottom = UDim.new(0, 10), UDim.new(0, 10)

local expanded = false
local function setExpanded(v)
    expanded = v
    MinBtn.Text = v and "−" or "+"
    TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(0, W, 0, v and (50 + CONTENT_H) or 50)}):Play()
end
MinBtn.MouseButton1Click:Connect(function() setExpanded(not expanded) end)
CloseBtn.MouseButton1Click:Connect(function()
    G.Running = false
    ScreenGui:Destroy()
end)

-- Status
local StatusRow = Instance.new("Frame")
StatusRow.Size, StatusRow.BackgroundColor3 = UDim2.new(1, 0, 0, 26), C.Surface
StatusRow.BorderSizePixel, StatusRow.LayoutOrder, StatusRow.Parent = 0, 0, Content
Instance.new("UICorner", StatusRow).CornerRadius = UDim.new(0, 6)

local StatusLbl = Instance.new("TextLabel")
StatusLbl.Size, StatusLbl.Position = UDim2.new(1, -12, 1, 0), UDim2.new(0, 10, 0, 0)
StatusLbl.BackgroundTransparency = 1
StatusLbl.Text, StatusLbl.TextColor3 = "● aguardando remotes...", C.Dim
StatusLbl.Font, StatusLbl.TextSize, StatusLbl.TextXAlignment = Enum.Font.Gotham, 11, Enum.TextXAlignment.Left
StatusLbl.Parent = StatusRow

task.spawn(function()
    while G.Running do
        local list = {}
        for k, v in pairs(REMOTES) do if v then table.insert(list, k) end end
        if #list > 0 then StatusLbl.Text, StatusLbl.TextColor3 = "● " .. table.concat(list, "  ·  "), C.Green
        else StatusLbl.Text, StatusLbl.TextColor3 = "● aguardando — entre em partida", C.Dim end
        task.wait(1.5)
    end
end)

-- Construtores
local function sectionLbl(text, order)
    local f = Instance.new("TextLabel")
    f.Size, f.BackgroundTransparency = UDim2.new(1, 0, 0, 18), 1
    f.Text, f.TextColor3, f.Font, f.TextSize = "  " .. text:upper(), C.AccentL, Enum.Font.GothamBold, 11
    f.TextXAlignment, f.LayoutOrder, f.Parent = Enum.TextXAlignment.Left, order, Content
end

local function makeButton(txt, order, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = color
    btn.Text, btn.TextColor3 = txt, Color3.new(1,1,1)
    btn.Font, btn.TextSize, btn.BorderSizePixel = Enum.Font.GothamBold, 13, 0
    btn.LayoutOrder, btn.Parent = order, Content
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function makeToggle(lbl, sub, order, getF, setF)
    local row = Instance.new("Frame")
    row.Size, row.BackgroundColor3 = UDim2.new(1, 0, 0, 60), C.Surface
    row.BorderSizePixel, row.LayoutOrder, row.Parent = 0, order, Content
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

    local t = Instance.new("TextLabel")
    t.Size, t.Position = UDim2.new(1,-72,0,20), UDim2.new(0,12,0,10)
    t.BackgroundTransparency, t.Text, t.TextColor3 = 1, lbl, C.Text
    t.Font, t.TextSize, t.TextXAlignment, t.Parent = Enum.Font.GothamSemibold, 13, Enum.TextXAlignment.Left, row

    local s = Instance.new("TextLabel")
    s.Size, s.Position = UDim2.new(1,-72,0,16), UDim2.new(0,12,0,32)
    s.BackgroundTransparency, s.Text, s.TextColor3 = 1, sub, C.Dim
    s.Font, s.TextSize, s.TextXAlignment, s.Parent = Enum.Font.Gotham, 11, Enum.TextXAlignment.Left, row

    local pill = Instance.new("Frame")
    pill.Size, pill.Position = UDim2.new(0,50,0,28), UDim2.new(1,-62,0.5,-14)
    pill.BackgroundColor3, pill.BorderSizePixel, pill.Parent = getF() and C.Accent or C.Border, 0, row
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("Frame")
    knob.Size, knob.Position = UDim2.new(0,22,0,22), getF() and UDim2.new(1,-25,0.5,-11) or UDim2.new(0,3,0.5,-11)
    knob.BackgroundColor3, knob.BorderSizePixel, knob.Parent = Color3.new(1,1,1), 0, pill
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

    local function refresh()
        local on = getF()
        TweenService:Create(pill, TweenInfo.new(0.15), {BackgroundColor3 = on and C.Accent or C.Border}):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {Position = on and UDim2.new(1,-25,0.5,-11) or UDim2.new(0,3,0.5,-11)}):Play()
    end

    local btn = Instance.new("TextButton")
    btn.Size, btn.BackgroundTransparency, btn.Text, btn.ZIndex = UDim2.new(1,0,1,0), 1, "", 3
    btn.Parent = row
    btn.MouseButton1Click:Connect(function() setF(not getF()) refresh() end)
end

local function makeSlider(lbl, order, minV, maxV, getF, setF, fmt)
    fmt = fmt or "%g"
    local row = Instance.new("Frame")
    row.Size, row.BackgroundColor3 = UDim2.new(1,0,0,64), C.Surface
    row.BorderSizePixel, row.LayoutOrder, row.Parent = 0, order, Content
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,10)

    local t = Instance.new("TextLabel")
    t.Size, t.Position = UDim2.new(0.65,0,0,20), UDim2.new(0,12,0,10)
    t.BackgroundTransparency, t.Text, t.TextColor3 = 1, lbl, C.Text
    t.Font, t.TextSize, t.TextXAlignment, t.Parent = Enum.Font.GothamSemibold, 13, Enum.TextXAlignment.Left, row

    local vLbl = Instance.new("TextLabel")
    vLbl.Size, vLbl.Position = UDim2.new(0.3,0,0,20), UDim2.new(0.68,0,0,10)
    vLbl.BackgroundTransparency, vLbl.Text, vLbl.TextColor3 = 1, string.format(fmt, getF()), C.AccentL
    vLbl.Font, vLbl.TextSize, vLbl.TextXAlignment, vLbl.Parent = Enum.Font.GothamBold, 12, Enum.TextXAlignment.Right, row

    local track = Instance.new("Frame")
    track.Size, track.Position = UDim2.new(1,-24,0,10), UDim2.new(0,12,0,40)
    track.BackgroundColor3, track.BorderSizePixel, track.Parent = C.Border, 0, row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)

    local pct = (getF()-minV)/(maxV-minV)
    local fill = Instance.new("Frame")
    fill.Size, fill.BackgroundColor3, fill.BorderSizePixel, fill.Parent = UDim2.new(pct,0,1,0), C.Accent, 0, track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("Frame")
    knob.Size, knob.Position = UDim2.new(0,18,0,18), UDim2.new(pct,-9,0.5,-9)
    knob.BackgroundColor3, knob.BorderSizePixel, knob.Parent = Color3.new(1,1,1), 0, track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

    local dragging = false
    local function updateFromX(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = minV + (maxV - minV) * rel
        if maxV - minV >= 4 then val = math.floor(val + 0.5) end
        setF(val)
        vLbl.Text = string.format(fmt, val)
        local p = (val - minV) / (maxV - minV)
        fill.Size, knob.Position = UDim2.new(p,0,1,0), UDim2.new(p,-9,0.5,-9)
    end

    local hit = Instance.new("TextButton")
    hit.Size, hit.BackgroundTransparency, hit.Text, hit.ZIndex = UDim2.new(1,0,1,0), 1, "", 5
    hit.Parent = track
    hit.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateFromX(inp.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseMovement) then
            updateFromX(inp.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

-- ══════════════════════════════════════════════
--  MONTAGEM DA INTERFACE
-- ══════════════════════════════════════════════

-- Seção de Macro
sectionLbl("Macro (Gravar Cliques)", 1)
local RecBtn = makeButton("● Iniciar Gravação", 2, Color3.fromRGB(180, 50, 50), function()
    if G.IsRecording then
        stopRecording()
        RecBtn.Text = "● Iniciar Gravação"
        RecBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    else
        startRecording()
        RecBtn.Text = "■ Parar Gravação"
        RecBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
    end
end)
local PlayBtn = makeButton("▶ Reproduzir Macro", 3, Color3.fromRGB(50, 150, 80), function()
    if G.IsPlaying then
        stopPlayback()
        PlayBtn.Text = "▶ Reproduzir Macro"
        PlayBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 80)
    else
        if #G.MacroCache > 0 then
            playMacro()
            PlayBtn.Text = "■ Parar Reprodução"
            PlayBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
        end
    end
end)

-- NOVOS BOTÕES DE SALVAR E CARREGAR MACRO
local SaveBtn = makeButton("💾 Salvar Macro (PC/Mobile)", 4, Color3.fromRGB(50, 80, 150), function()
    if #G.MacroCache > 0 then
        if saveMacroToFile() then
            SaveBtn.Text = "✅ Macro Salvo!"
            task.wait(2)
            SaveBtn.Text = "💾 Salvar Macro (PC/Mobile)"
        else
            SaveBtn.Text = "❌ Erro ao Salvar"
            task.wait(2)
            SaveBtn.Text = "💾 Salvar Macro (PC/Mobile)"
        end
    else
        SaveBtn.Text = "⚠️ Nada Gravado"
        task.wait(2)
        SaveBtn.Text = "💾 Salvar Macro (PC/Mobile)"
    end
end)

local LoadBtn = makeButton("📂 Carregar Macro", 5, Color3.fromRGB(150, 100, 50), function()
    if loadMacroFromFile() then
        LoadBtn.Text = "✅ Macro Carregado!"
        task.wait(2)
        LoadBtn.Text = "📂 Carregar Macro"
    else
        LoadBtn.Text = "❌ Nenhum Macro Salvo"
        task.wait(2)
        LoadBtn.Text = "📂 Carregar Macro"
    end
end)

-- Seção de Teleporte / Auto-Retorno
sectionLbl("Auto-Retorno Lobby", 6)
makeButton("Salvar Posição: Raid", 7, Color3.fromRGB(60, 60, 85), function()
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        G.PosRaid = lp.Character.HumanoidRootPart.CFrame
    end
end)
makeButton("Salvar Posição: Cassino", 8, Color3.fromRGB(60, 60, 85), function()
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        G.PosCassino = lp.Character.HumanoidRootPart.CFrame
    end
end)
makeToggle("Loop Auto Raid", "Volta pra Raid sozinho", 9, function() return G.AutoRaid end, function(v) G.AutoRaid = v end)
makeToggle("Loop Auto Cassino", "Volta pro Cassino sozinho", 10, function() return G.AutoCassino end, function(v) G.AutoCassino = v end)

-- Seção de Automação
sectionLbl("Automação de Jogo", 11)
makeToggle("Auto Wave", "Inicia onda automaticamente", 12, function() return G.AutoWave end, function(v) G.AutoWave = v end)
makeToggle("Auto Place", "Coloca torres nos slots livres", 13, function() return G.AutoPlace end, function(v) G.AutoPlace = v end)
makeToggle("Auto Upgrade", "Sobe torres até o nível máximo", 14, function() return G.AutoUpgrade end, function(v) G.AutoUpgrade = v end)
makeToggle("Auto Sell", "Vende torres no nível máximo", 15, function() return G.AutoSell end, function(v) G.AutoSell = v end)

-- Configurações
sectionLbl("Configurações", 16)
makeSlider("Delay entre ondas", 17, 0.5, 5, function() return G.WaveDelay end, function(v) G.WaveDelay = v end, "%.1fs")
makeSlider("Nível máximo", 18, 1, 20, function() return G.MaxLevel end, function(v) G.MaxLevel = math.floor(v) end, "%d")

print("[STD] GUI pronta e atualizada.")
