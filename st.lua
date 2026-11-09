-- STD_Delta.lua — Premium UI Edition (FINAL)
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
    PlaceSlot    = 1,
    UiScale      = 1,
    Running      = true,
    IsRecording  = false,
    IsPlaying    = false,
    MacroCache   = {},
    RecordStartTime = 0,
    PosRaid      = nil,
    PosCassino   = nil,
    AutoRaid     = false,
    AutoCassino  = false,
}

-- ══════════════════════════════════════════════
--  TELEPORTE E AUTO-RETORNO
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
                task.wait(2) if G.AutoRaid then tpTo(G.PosRaid) end
            end
        end
        if G.AutoCassino and G.PosCassino then
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and (hrp.Position - G.PosCassino.Position).Magnitude > 50 then
                task.wait(2) if G.AutoCassino then tpTo(G.PosCassino) end
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
    for _, p in ipairs(list) do if name:find(p) then return true end end
    return false
end

local function scanRemotes()
    local found = 0
    local function scan(parent)
        for _, v in ipairs(parent:GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                for key, patterns in pairs(PATTERNS) do
                    if not REMOTES[key] and matchesPattern(v.Name, patterns) then
                        REMOTES[key] = v found = found + 1
                    end
                end
            end
        end
    end
    pcall(scan, ReplicatedStorage)
    pcall(scan, workspace)
    return found
end

task.spawn(function() while G.Running do scanRemotes() task.wait(4) end end)

local function safe(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then warn("[STD] " .. tostring(err)) end
end

-- ══════════════════════════════════════════════
--  UTILITÁRIOS E LOOPS
-- ══════════════════════════════════════════════
local slotCache, towerCache, cacheTime = {}, {}, 0
local CACHE_TTL = 2

local function refreshCache()
    if os.clock() - cacheTime < CACHE_TTL then return end
    cacheTime = os.clock() slotCache, towerCache = {}, {}
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

local function getSlots() refreshCache() return slotCache end
local function getMyTowers() refreshCache() return towerCache end

task.spawn(function()
    while G.Running do
        if G.AutoWave and REMOTES.StartWave then safe(function() REMOTES.StartWave:FireServer() end) end
        task.wait(G.WaveDelay)
    end
end)

task.spawn(function()
    while G.Running do
        if G.AutoPlace and REMOTES.PlaceTower then
            local slots, towers = getSlots(), getMyTowers()
            if #towers < #slots then
                for i = #towers + 1, math.min(#towers + 3, #slots) do
                    local slot = slots[i]
                    if slot then
                        safe(function() REMOTES.PlaceTower:FireServer(G.PlaceSlot, slot.CFrame) end)
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
                if (lvl and lvl.Value or 0) < G.MaxLevel then
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
--  MACRO
-- ══════════════════════════════════════════════
local recordConn = nil
local function startRecording()
    if G.IsRecording then return end
    G.IsRecording = true G.IsPlaying = false G.MacroCache = {} G.RecordStartTime = os.clock()
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
local function stopPlayback() G.IsPlaying = false if playTask then task.cancel(playTask) playTask = nil end end
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
                        VirtualInputManager:SendKeyEvent(true, key, false, game) task.wait(0.05)
                        VirtualInputManager:SendKeyEvent(false, key, false, game)
                    end
                end
            end
            task.wait(0.5)
        end
    end)
end

-- ══════════════════════════════════════════════
--  PREMIUM UI
-- ══════════════════════════════════════════════
local playerGui = lp:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("STD_Mobile") then playerGui:FindFirstChild("STD_Mobile"):Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "STD_Mobile" ScreenGui.ResetOnSpawn = false ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling ScreenGui.DisplayOrder = 999
ScreenGui.Parent = playerGui

local Theme = {
    BG      = Color3.fromRGB(15, 15, 20),
    Surface = Color3.fromRGB(24, 24, 32),
    Accent  = Color3.fromRGB(138, 43, 226),
    AccentL = Color3.fromRGB(180, 100, 255),
    Text    = Color3.fromRGB(240, 240, 245),
    Dim     = Color3.fromRGB(140, 140, 155),
    Green   = Color3.fromRGB(50, 200, 100),
    Red     = Color3.fromRGB(220, 60, 60),
    Border  = Color3.fromRGB(45, 45, 60)
}

local W, H = 340, 520
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, W, 0, 50)
Main.Position = UDim2.new(0.5, -W/2, 0.5, -25)
Main.BackgroundColor3 = Theme.BG
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", Main)
stroke.Color = Theme.Border stroke.Thickness = 1.5

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 50)
TopBar.BackgroundColor3 = Theme.Surface
TopBar.BorderSizePixel = 0
TopBar.Parent = Main
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Text, Title.Size, Title.Position = "⟡ Sorcerer TD", UDim2.new(1, -120, 1, 0), UDim2.new(0, 16, 0, 0)
Title.BackgroundTransparency, Title.TextColor3 = 1, Theme.Text
Title.Font, Title.TextSize, Title.TextXAlignment, Title.Parent = Enum.Font.GothamBold, 15, Enum.TextXAlignment.Left, TopBar

local function createTopBtn(text, posX, color, callback)
    local btn = Instance.new("TextButton")
    btn.Text, btn.Size, btn.Position = text, UDim2.new(0, 34, 0, 34), UDim2.new(1, posX, 0.5, -17)
    btn.BackgroundColor3, btn.TextColor3 = color, Theme.Text
    btn.Font, btn.TextSize, btn.BorderSizePixel = Enum.Font.GothamBold, 16, 0
    btn.Parent = TopBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- BOTÃO DE REDIMENSIONAR (O que você pediu)
local ScaleBtn = createTopBtn("⤢", -128, Theme.Border, function()
    if G.UiScale == 1 then
        G.UiScale = 0.75
    elseif G.UiScale == 0.75 then
        G.UiScale = 1.2
    else
        G.UiScale = 1
    end
    TweenService:Create(Main, TweenInfo.new(0.2), {Size = UDim2.new(0, W * G.UiScale, 0, (Main.Visible and (expanded and H or 50) or 50) * G.UiScale)}):Play()
end)

createTopBtn("✕", -44, Theme.Red, function() G.Running = false ScreenGui:Destroy() end)
local MinBtn = createTopBtn("−", -86, Theme.Border, function() end)

-- Drag
local dragging, dragInput, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true dragStart = input.Position startPos = Main.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Tabs
local TabContainer = Instance.new("Frame")
TabContainer.Size, TabContainer.Position = UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 50)
TabContainer.BackgroundColor3, TabContainer.BorderSizePixel = Theme.BG, 0
TabContainer.Parent = Main

local TabList = Instance.new("Frame")
TabList.Size, TabList.Position = UDim2.new(1, -16, 1, -8), UDim2.new(0, 8, 0, 4)
TabList.BackgroundTransparency = 1 TabList.Parent = TabContainer

local TabLayout = Instance.new("UIListLayout", TabList)
TabLayout.FillDirection = Enum.FillDirection.Horizontal TabLayout.Padding = UDim.new(0, 6)
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local Pages = Instance.new("Frame")
Pages.Size, Pages.Position = UDim2.new(1, 0, 1, -90), UDim2.new(0, 0, 0, 90)
Pages.BackgroundTransparency = 1 Pages.Parent = Main

local function switchTab(activeBtn, activePage)
    for _, v in ipairs(TabList:GetChildren()) do
        if v:IsA("TextButton") then TweenService:Create(v, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Surface, TextColor3 = Theme.Dim}):Play() end
    end
    for _, v in ipairs(Pages:GetChildren()) do
        if v:IsA("ScrollingFrame") then v.Visible = false end
    end
    TweenService:Create(activeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Text}):Play()
    activePage.Visible = true
end

local function createTab(name, order)
    local btn = Instance.new("TextButton")
    btn.Size, btn.BackgroundColor3 = UDim2.new(0.33, -4, 1, 0), Theme.Surface
    btn.Text, btn.TextColor3, btn.Font, btn.TextSize, btn.BorderSizePixel = name, Theme.Dim, Enum.Font.GothamSemibold, 12, 0
    btn.LayoutOrder, btn.Parent = order, TabList
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    local page = Instance.new("ScrollingFrame")
    page.Size, page.Position = UDim2.new(1, -16, 1, -16), UDim2.new(0, 8, 0, 8)
    page.BackgroundTransparency, page.BorderSizePixel = 1, 0
    page.ScrollBarThickness, page.ScrollBarImageColor3 = 3, Theme.Accent
    page.CanvasSize, page.AutomaticCanvasSize = UDim2.new(0, 0, 0, 0), Enum.AutomaticSize.Y
    page.Visible, page.Parent = false, Pages
    
    local pageLayout = Instance.new("UIListLayout", page)
    pageLayout.Padding, pageLayout.SortOrder = UDim.new(0, 8), Enum.SortOrder.LayoutOrder

    btn.MouseButton1Click:Connect(function() switchTab(btn, page) end)
    return btn, page
end

local expanded = false
local function setExpanded(v)
    expanded = v
    MinBtn.Text = v and "−" or "+"
    TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, W * G.UiScale, 0, (v and H or 50) * G.UiScale)
    }):Play()
    TabContainer.Visible, Pages.Visible = v, v
end

MinBtn.MouseButton1Click:Connect(function() setExpanded(not expanded) end)

-- Componentes
local function createSection(text, order, parent)
    local lbl = Instance.new("TextLabel")
    lbl.Size, lbl.BackgroundTransparency = UDim2.new(1, 0, 0, 20), 1
    lbl.Text, lbl.TextColor3, lbl.Font, lbl.TextSize = string.upper(text), Theme.AccentL, Enum.Font.GothamBold, 11
    lbl.TextXAlignment, lbl.LayoutOrder, lbl.Parent = Enum.TextXAlignment.Left, order, parent
end

local function createToggle(lbl, desc, order, parent, getF, setF)
    local frame = Instance.new("Frame")
    frame.Size, frame.BackgroundColor3, frame.BorderSizePixel = UDim2.new(1, 0, 0, 50), Theme.Surface, 0
    frame.LayoutOrder, frame.Parent = order, parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    
    local title = Instance.new("TextLabel")
    title.Size, title.Position, title.BackgroundTransparency = UDim2.new(1, -60, 0, 20), UDim2.new(0, 12, 0, 8), 1
    title.Text, title.TextColor3, title.Font, title.TextSize = lbl, Theme.Text, Enum.Font.GothamSemibold, 13
    title.TextXAlignment, title.Parent = Enum.TextXAlignment.Left, frame
    
    local sub = Instance.new("TextLabel")
    sub.Size, sub.Position, sub.BackgroundTransparency = UDim2.new(1, -60, 0, 14), UDim2.new(0, 12, 0, 28), 1
    sub.Text, sub.TextColor3, sub.Font, sub.TextSize = desc, Theme.Dim, Enum.Font.Gotham, 11
    sub.TextXAlignment, sub.Parent = Enum.TextXAlignment.Left, frame
    
    local pill = Instance.new("Frame")
    pill.Size, pill.Position = UDim2.new(0, 44, 0, 24), UDim2.new(1, -56, 0.5, -12)
    pill.BackgroundColor3, pill.BorderSizePixel, pill.Parent = getF() and Theme.Accent or Theme.Border, 0, frame
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
    
    local knob = Instance.new("Frame")
    knob.Size, knob.Position = UDim2.new(0, 18, 0, 18), getF() and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    knob.BackgroundColor3, knob.BorderSizePixel, knob.Parent = Color3.new(1,1,1), 0, pill
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    
    local btn = Instance.new("TextButton")
    btn.Size, btn.BackgroundTransparency, btn.Text, btn.ZIndex = UDim2.new(1,0,1,0), 1, "", 3
    btn.Parent = frame
    
    btn.MouseButton1Click:Connect(function()
        local state = not getF() setF(state)
        TweenService:Create(pill, TweenInfo.new(0.15), {BackgroundColor3 = state and Theme.Accent or Theme.Border}):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {Position = state and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,3,0.5,-9)}):Play()
    end)
end

local function createButton(txt, order, parent, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size, btn.BackgroundColor3 = UDim2.new(1, 0, 0, 36), color
    btn.Text, btn.TextColor3, btn.Font, btn.TextSize, btn.BorderSizePixel = txt, Theme.Text, Enum.Font.GothamBold, 12, 0
    btn.LayoutOrder, btn.Parent = order, parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = color:Lerp(Color3.new(1,1,1), 0.1)}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = color}):Play() end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- SLIDER (A opção que você pediu de volta)
local function createSlider(lbl, order, parent, minV, maxV, getF, setF, fmt)
    local frame = Instance.new("Frame")
    frame.Size, frame.BackgroundColor3, frame.BorderSizePixel = UDim2.new(1, 0, 0, 56), Theme.Surface, 0
    frame.LayoutOrder, frame.Parent = order, parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    
    local title = Instance.new("TextLabel")
    title.Size, title.Position, title.BackgroundTransparency = UDim2.new(0.65,0,0,18), UDim2.new(0,12,0,8), 1
    title.Text, title.TextColor3, title.Font, title.TextSize = lbl, Theme.Text, Enum.Font.GothamSemibold, 12
    title.TextXAlignment, title.Parent = Enum.TextXAlignment.Left, frame
    
    local vLbl = Instance.new("TextLabel")
    vLbl.Size, vLbl.Position, vLbl.BackgroundTransparency = UDim2.new(0.3,0,0,18), UDim2.new(0.68,0,0,8), 1
    vLbl.Text, vLbl.TextColor3, vLbl.Font, vLbl.TextSize = string.format(fmt, getF()), Theme.AccentL, Enum.Font.GothamBold, 12
    vLbl.TextXAlignment, vLbl.Parent = Enum.TextXAlignment.Right, frame
    
    local track = Instance.new("Frame")
    track.Size, track.Position = UDim2.new(1,-24,0,8), UDim2.new(0,12,0,36)
    track.BackgroundColor3, track.BorderSizePixel, track.Parent = Theme.Border, 0, frame
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)
    
    local pct = (getF()-minV)/(maxV-minV)
    local fill = Instance.new("Frame")
    fill.Size, fill.BackgroundColor3, fill.BorderSizePixel, fill.Parent = UDim2.new(pct,0,1,0), Theme.Accent, 0, track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)
    
    local knob = Instance.new("Frame")
    knob.Size, knob.Position = UDim2.new(0,16,0,16), UDim2.new(pct,-8,0.5,-8)
    knob.BackgroundColor3, knob.BorderSizePixel, knob.Parent = Color3.new(1,1,1), 0, track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
    
    local dragging = false
    local function update(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = minV + (maxV - minV) * rel
        if maxV - minV >= 4 then val = math.floor(val + 0.5) end
        setF(val) vLbl.Text = string.format(fmt, val)
        local p = (val - minV) / (maxV - minV)
        fill.Size, knob.Position = UDim2.new(p,0,1,0), UDim2.new(p,-8,0.5,-8)
    end
    
    local hit = Instance.new("TextButton")
    hit.Size, hit.BackgroundTransparency, hit.Text, hit.ZIndex = UDim2.new(1,0,1,0), 1, "", 5
    hit.Parent = track
    hit.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true update(inp.Position.X) end end)
    UserInputService.InputChanged:Connect(function(inp) if dragging and (inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseMovement) then update(inp.Position.X) end end)
    UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
end

-- ══════════════════════════════════════════════
--  MONTAGEM DAS ABAS
-- ══════════════════════════════════════════════

-- HOME
local TabHome, PageHome = createTab("HOME", 1)
createSection("Status de Conexão", 1, PageHome)
local statusLbl = Instance.new("TextLabel")
statusLbl.Size, statusLbl.BackgroundColor3 = UDim2.new(1, 0, 0, 30), Theme.Surface
statusLbl.Text, statusLbl.TextColor3, statusLbl.Font, statusLbl.TextSize = "● Aguardando Remotes...", Theme.Dim, Enum.Font.Gotham, 12
statusLbl.LayoutOrder, statusLbl.Parent = 2, PageHome
Instance.new("UICorner", statusLbl).CornerRadius = UDim.new(0, 8)

task.spawn(function()
    while G.Running do
        local list = {}
        for k, v in pairs(REMOTES) do if v then table.insert(list, k) end end
        if #list > 0 then statusLbl.Text, statusLbl.TextColor3 = "● " .. table.concat(list, " · "), Theme.Green
        else statusLbl.Text, statusLbl.TextColor3 = "● Aguardando conexão com a partida...", Theme.Dim end
        task.wait(1.5)
    end
end)

createSection("Auto-Retorno Lobby", 3, PageHome)
createButton("📍 Salvar Posição: Raid", 4, PageHome, Theme.Border, function()
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then G.PosRaid = lp.Character.HumanoidRootPart.CFrame end
end)
createButton("📍 Salvar Posição: Cassino", 5, PageHome, Theme.Border, function()
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then G.PosCassino = lp.Character.HumanoidRootPart.CFrame end
end)
createToggle("Loop Auto Raid", "Volta ao lobby automaticamente", 6, PageHome, function() return G.AutoRaid end, function(v) G.AutoRaid = v end)
createToggle("Loop Auto Cassino", "Volta ao cassino automaticamente", 7, PageHome, function() return G.AutoCassino end, function(v) G.AutoCassino = v end)

-- MACRO
local TabMacro, PageMacro = createTab("MACRO", 2)
createSection("Gravação de Cliques", 1, PageMacro)
local recBtn = createButton("● Iniciar Gravação", 2, PageMacro, Theme.Red, function()
    if G.IsRecording then stopRecording() recBtn.Text, recBtn.BackgroundColor3 = "● Iniciar Gravação", Theme.Red
    else startRecording() recBtn.Text, recBtn.BackgroundColor3 = "■ Parar Gravação", Theme.Border end
end)
local playBtn = createButton("▶ Reproduzir Macro", 3, PageMacro, Theme.Green, function()
    if G.IsPlaying then stopPlayback() playBtn.Text, playBtn.BackgroundColor3 = "▶ Reproduzir Macro", Theme.Green
    elseif #G.MacroCache > 0 then playMacro() playBtn.Text, playBtn.BackgroundColor3 = "■ Parar Reprodução", Theme.Border end
end)

createSection("Gerenciamento de Macro", 4, PageMacro)
createButton("💾 Salvar Macro", 5, PageMacro, Color3.fromRGB(50, 80, 150), function()
    if saveMacroToFile() then game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Sucesso", Text = "Macro Salvo!", Duration = 3})
    else game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Erro", Text = "Falha ao salvar.", Duration = 3}) end
end)
createButton("📂 Carregar Macro", 6, PageMacro, Color3.fromRGB(150, 100, 50), function()
    if loadMacroFromFile() then game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Sucesso", Text = "Macro Carregado!", Duration = 3})
    else game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Erro", Text = "Nenhum salvo.", Duration = 3}) end
end)

-- AUTO (Configurações e Toggles)
local TabAuto, PageAuto = createTab("AUTO", 3)
createSection("Combate", 1, PageAuto)
createToggle("Auto
