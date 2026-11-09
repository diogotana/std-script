-- STD_Delta.lua — Premium UI + Multi-Farm + Discord
-- game: Sorcerer Tower Defense | 17720162456

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService       = game:GetService("HttpService")

-- COLE O SEU WEBHOOK NOVO AQUI ENTRE AS ASPAS:
local URL_WEBHOOK = "https://discord.com/api/webhooks/1131677874563317791/czmm0YTkBViovqEyBlHFxBNxEtFTMGyykrz3LcX6cS4cBncNpfzSlwSo7eV8GnicYlut"

local lp = Players.LocalPlayer

local G = {
    AutoWave = false, AutoPlace = false, AutoUpgrade = false, AutoSell = false,
    WaveDelay = 1.5, MaxLevel = 5, PlaceSlot = 1, 
    UiScale = 1, Running = true,
    
    -- Macros
    IsRecording = false, RecordType = "", RecordStartTime = 0,
    MacroRaid = {}, MacroCassino = {}, MacroChall = {},
    ActiveMacro = "Raid",
    IsPlaying = false, IsLooping = true,

    -- Teleportes
    PosRaid = CFrame.new(11.12, 17.30, 3097.41), 
    PosCassino = CFrame.new(-362.99, 16.59, 2854.20), 
    PosEasy = CFrame.new(-340.54, 16.91, 3268.80), 
    PosNormal = CFrame.new(-364.12, 17.33, 3291.20), 
    PosHell = CFrame.new(-391.81, 16.70, 3314.83),
    
    AutoRaid = false, AutoCassino = false, AutoEasy = false, AutoNormal = false, AutoHell = false
}

-- ══════════════════════════════════════════════
--  SISTEMA DE WEBHOOK DISCORD
-- ══════════════════════════════════════════════
local function sendDiscordAlert(itemName)
    if URL_WEBHOOK == "COLE_SEU_WEBHOOK_AQUI" then
        game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Erro", Text = "Cole o link do seu Webhook no código!", Duration = 3})
        return
    end
    
    local data = {
        ["content"] = "🚨 **ITEM ENCONTRADO NO SORCERER TD!** 🚨",
        ["embeds"] = {{
            ["title"] = "Novo Drop!",
            ["description"] = "O item **" .. itemName .. "** foi encontrado e está pronto para ser pego!",
            ["color"] = 5763719,
            ["footer"] = {["text"] = "STD Macro Premium"}
        }}
    }
    
    pcall(function()
        HttpService:PostAsync(URL_WEBHOOK, HttpService:JSONEncode(data), Enum.HttpContentType.ApplicationJson)
        game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Sucesso", Text = "Aviso enviado para o Discord!", Duration = 3})
    end)
end

-- ══════════════════════════════════════════════
--  SISTEMA DE TELEPORTE
-- ══════════════════════════════════════════════
local function tpTo(cframe)
    if cframe and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        lp.Character.HumanoidRootPart.CFrame = cframe
    end
end

task.spawn(function()
    while G.Running do
        local char = lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            if G.AutoRaid and G.PosRaid and (hrp.Position - G.PosRaid.Position).Magnitude > 50 then task.wait(1) if G.AutoRaid then tpTo(G.PosRaid) end end
            if G.AutoCassino and G.PosCassino and (hrp.Position - G.PosCassino.Position).Magnitude > 50 then task.wait(1) if G.AutoCassino then tpTo(G.PosCassino) end end
            if G.AutoEasy and G.PosEasy and (hrp.Position - G.PosEasy.Position).Magnitude > 50 then task.wait(1) if G.AutoEasy then tpTo(G.PosEasy) end end
            if G.AutoNormal and G.PosNormal and (hrp.Position - G.PosNormal.Position).Magnitude > 50 then task.wait(1) if G.AutoNormal then tpTo(G.PosNormal) end end
            if G.AutoHell and G.PosHell and (hrp.Position - G.PosHell.Position).Magnitude > 50 then task.wait(1) if G.AutoHell then tpTo(G.PosHell) end end
        end
        task.wait(1)
    end
end)

-- ══════════════════════════════════════════════
--  SISTEMA DE MACRO MULTI-MODO
-- ══════════════════════════════════════════════
local recordConn = nil
local function startRecording(typeName)
    G.IsRecording = true G.RecordType = typeName
    if typeName == "Raid" then G.MacroRaid = {} elseif typeName == "Cassino" then G.MacroCassino = {} else G.MacroChall = {} end
    G.RecordStartTime = os.clock()
    
    recordConn = UserInputService.InputBegan:Connect(function(input, gp)
        if gp or not G.IsRecording then return end
        local now = os.clock() - G.RecordStartTime
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local entry = { Type = "Click", X = input.Position.X, Y = input.Position.Y, Time = now }
            if G.RecordType == "Raid" then table.insert(G.MacroRaid, entry)
            elseif G.RecordType == "Cassino" then table.insert(G.MacroCassino, entry)
            else table.insert(G.MacroChall, entry) end
        end
    end)
end

local function stopRecording() G.IsRecording = false if recordConn then recordConn:Disconnect() end end

local playTask = nil
local function stopPlayback() G.IsPlaying = false if playTask then task.cancel(playTask) end end
local function playMacro()
    local macro = G.MacroChall
    if G.ActiveMacro == "Raid" then macro = G.MacroRaid
    elseif G.ActiveMacro == "Cassino" then macro = G.MacroCassino end

    if #macro == 0 then 
        game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Aviso", Text = "O Macro para " .. G.ActiveMacro .. " está vazio!", Duration = 3})
        return 
    end
    G.IsPlaying = true
    playTask = task.spawn(function()
        repeat
            local start = os.clock()
            for _, a in ipairs(macro) do
                if not G.IsPlaying then break end
                local waitTime = (start + a.Time) - os.clock()
                if waitTime > 0 then task.wait(waitTime) end
                if a.Type == "Click" then
                    VirtualInputManager:SendMouseButtonEvent(a.X, a.Y, 0, true, game, 1)
                    task.wait(0.03)
                    VirtualInputManager:SendMouseButtonEvent(a.X, a.Y, 0, false, game, 1)
                end
            end
            task.wait(0.5)
        until not G.IsLooping or not G.IsPlaying
        G.IsPlaying = false
    end)
end

-- ══════════════════════════════════════════════
--  REMOTES E COMBATE
-- ══════════════════════════════════════════════
local REMOTES = { StartWave=nil, PlaceTower=nil, UpgradeTower=nil, SellTower=nil }
local PATTERNS = { StartWave = {"wave","start"}, PlaceTower = {"place","spawn","deploy"}, UpgradeTower = {"upgrade","level"}, SellTower = {"sell","remove"} }
local function matchesPattern(name, list) name = name:lower() for _, p in ipairs(list) do if name:find(p) then return true end end return false end
local function scanRemotes()
    local function scan(parent)
        for _, v in ipairs(parent:GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                for key, patterns in pairs(PATTERNS) do if not REMOTES[key] and matchesPattern(v.Name, patterns) then REMOTES[key] = v end end
            end
        end
    end
    pcall(scan, ReplicatedStorage) pcall(scan, workspace)
end
task.spawn(function() while G.Running do scanRemotes() task.wait(4) end end)
local function safe(fn, ...) local ok, err = pcall(fn, ...) if not ok then warn("[STD] " .. tostring(err)) end end

local slotCache, towerCache, cacheTime = {}, {}, 0
local function getSlots() if os.clock() - cacheTime < 2 then return slotCache end cacheTime = os.clock() slotCache = {} for _, v in ipairs(workspace:GetDescendants()) do if v:IsA("BasePart") and (v.Name:lower():find("slot") or v.Name:lower():find("node") or v.Name:lower():find("point")) then table.insert(slotCache, v) end end return slotCache end
local function getMyTowers() if os.clock() - cacheTime < 2 then return towerCache end towerCache = {} for _, v in ipairs(workspace:GetDescendants()) do if v:IsA("Model") then local ow = v:FindFirstChild("Owner") or v:FindFirstChild("PlayerId") if ow and (ow.Value == lp.UserId or ow.Value == lp.Name) then table.insert(towerCache, v) end end end return towerCache end

task.spawn(function() while G.Running do if G.AutoWave and REMOTES.StartWave then safe(function() REMOTES.StartWave:FireServer() end) end task.wait(G.WaveDelay) end end)
task.spawn(function() while G.Running do if G.AutoPlace and REMOTES.PlaceTower then local slots, towers = getSlots(), getMyTowers() if #towers < #slots then for i = #towers + 1, math.min(#towers + 3, #slots) do local slot = slots[i] if slot then safe(function() REMOTES.PlaceTower:FireServer(G.PlaceSlot, slot.CFrame) end) task.wait(0.15) end end end end task.wait(1) end end)
task.spawn(function() while G.Running do if G.AutoUpgrade and REMOTES.UpgradeTower then for _, tower in ipairs(getMyTowers()) do local lvl = tower:FindFirstChild("Level") or tower:FindFirstChild("Upgrades") or tower:FindFirstChild("Tier") if (lvl and lvl.Value or 0) < G.MaxLevel then safe(function() REMOTES.UpgradeTower:FireServer(tower) end) task.wait(0.1) end end end task.wait(1.2) end end)
task.spawn(function() while G.Running do if G.AutoSell and REMOTES.SellTower then for _, tower in ipairs(getMyTowers()) do local lvl = tower:FindFirstChild("Level") if lvl and lvl.Value >= G.MaxLevel then safe(function() REMOTES.SellTower:FireServer(tower) end) task.wait(0.2) end end end task.wait(2) end end)

-- ══════════════════════════════════════════════
--  PREMIUM UI
-- ══════════════════════════════════════════════
local playerGui = lp:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("STD_Mobile") then playerGui:FindFirstChild("STD_Mobile"):Destroy() end
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name, ScreenGui.ResetOnSpawn, ScreenGui.IgnoreGuiInset, ScreenGui.Parent = "STD_Mobile", false, true, playerGui

local Theme = {
    BG = Color3.fromRGB(15, 15, 20), Surface = Color3.fromRGB(24, 24, 32),
    Accent = Color3.fromRGB(138, 43, 226), AccentL = Color3.fromRGB(180, 100, 255),
    Text = Color3.fromRGB(240, 240, 245), Dim = Color3.fromRGB(140, 140, 155),
    Green = Color3.fromRGB(50, 200, 100), Red = Color3.fromRGB(220, 60, 60), Border = Color3.fromRGB(45, 45, 60)
}

local W, H = 340, 520
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, W, 0, 50) Main.Position = UDim2.new(0.5, -W/2, 0.5, -25)
Main.BackgroundColor3 = Theme.BG Main.ClipsDescendants = true Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", Main) stroke.Color = Theme.Border stroke.Thickness = 1.5

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 50) TopBar.BackgroundColor3 = Theme.Surface TopBar.Parent = Main
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 12)
local Title = Instance.new("TextLabel")
Title.Text, Title.Size, Title.Position = "⟡ Sorcerer TD", UDim2.new(1, -120, 1, 0), UDim2.new(0, 16, 0, 0)
Title.BackgroundTransparency, Title.TextColor3, Title.Font, Title.TextSize = 1, Theme.Text, Enum.Font.GothamBold, 15
Title.TextXAlignment, Title.Parent = Enum.TextXAlignment.Left, TopBar

local function createTopBtn(text, posX, color, callback)
    local btn = Instance.new("TextButton")
    btn.Text, btn.Size, btn.Position = text, UDim2.new(0, 34, 0, 34), UDim2.new(1, posX, 0.5, -17)
    btn.BackgroundColor3, btn.TextColor3 = color, Theme.Text
    btn.Font, btn.TextSize, btn.BorderSizePixel = Enum.Font.GothamBold, 16, 0
    btn.Parent = TopBar Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(callback) return btn
end

createTopBtn("⤢", -128, Theme.Border, function() G.UiScale = (G.UiScale == 1 and 0.75) or (G.UiScale == 0.75 and 1.2) or 1 TweenService:Create(Main, TweenInfo.new(0.2), {Size = UDim2.new(0, W * G.UiScale, 0, (expanded and H or 50) * G.UiScale)}):Play() end)
createTopBtn("✕", -44, Theme.Red, function() G.Running = false ScreenGui:Destroy() end)
local MinBtn = createTopBtn("−", -86, Theme.Border, function() end)

local dragging, dragInput, dragStart, startPos
TopBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true dragStart = input.Position startPos = Main.Position end end)
UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local delta = input.Position - dragStart Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)

local TabContainer = Instance.new("Frame")
TabContainer.Size, TabContainer.Position = UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 50)
TabContainer.BackgroundColor3, TabContainer.Parent = Theme.BG, Main
local TabList = Instance.new("Frame")
TabList.Size, TabList.Position = UDim2.new(1, -16, 1, -8), UDim2.new(0, 8, 0, 4)
TabList.BackgroundTransparency, TabList.Parent = 1, TabContainer
local TabLayout = Instance.new("UIListLayout", TabList)
TabLayout.FillDirection, TabLayout.Padding, TabLayout.SortOrder = Enum.FillDirection.Horizontal, UDim.new(0, 6), Enum.SortOrder.LayoutOrder
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
local Pages = Instance.new("Frame")
Pages.Size, Pages.Position = UDim2.new(1, 0, 1, -90), UDim2.new(0, 0, 0, 90)
Pages.BackgroundTransparency, Pages.Parent = 1, Main

local function switchTab(activeBtn, activePage)
    for _, v in ipairs(TabList:GetChildren()) do if v:IsA("TextButton") then TweenService:Create(v, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Surface, TextColor3 = Theme.Dim}):Play() end end
    for _, v in ipairs(Pages:GetChildren()) do if v:IsA("ScrollingFrame") then v.Visible = false end end
    TweenService:Create(activeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Text}):Play()
    activePage.Visible = true
end

local function createTab(name, order)
    local btn = Instance.new("TextButton")
    btn.Size, btn.BackgroundColor3, btn.Text, btn.TextColor3 = UDim2.new(0.24, -4, 1, 0), Theme.Surface, name, Theme.Dim
    btn.Font, btn.TextSize, btn.LayoutOrder, btn.Parent = Enum.Font.GothamSemibold, 11, order, TabList
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local page = Instance.new("ScrollingFrame")
    page.Size, page.Position, page.BackgroundTransparency = UDim2.new(1, -16, 1, -16), UDim2.new(0, 8, 0, 8), 1
    page.ScrollBarThickness, page.ScrollBarImageColor3, page.CanvasSize = 3, Theme.Accent, UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize, page.Visible, page.Parent = Enum.AutomaticSize.Y, false, Pages
    local layout = Instance.new("UIListLayout", page) layout.Padding, layout.SortOrder = UDim.new(0, 8), Enum.SortOrder.LayoutOrder
    btn.MouseButton1Click:Connect(function() switchTab(btn, page) end) return btn, page
end

local expanded = false
local function setExpanded(v)
    expanded = v MinBtn.Text = v and "−" or "+"
    TweenService:Create(Main, TweenInfo.new(0.25), {Size = UDim2.new(0, W * G.UiScale, 0, (v and H or 50) * G.UiScale)}):Play()
    TabContainer.Visible, Pages.Visible = v, v
end
MinBtn.MouseButton1Click:Connect(function() setExpanded(not expanded) end)

local function createSection(text, order, parent)
    local lbl = Instance.new("TextLabel")
    lbl.Size, lbl.BackgroundTransparency, lbl.Text = UDim2.new(1, 0, 0, 20), 1, string.upper(text)
    lbl.TextColor3, lbl.Font, lbl.TextSize, lbl.LayoutOrder, lbl.Parent = Theme.AccentL, Enum.Font.GothamBold, 11, order, parent
end

local function createToggle(lbl, desc, order, parent, getF, setF)
    local frame = Instance.new("Frame")
    frame.Size, frame.BackgroundColor3, frame.BorderSizePixel, frame.LayoutOrder, frame.Parent = UDim2.new(1, 0, 0, 50), Theme.Surface, 0, order, parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local title = Instance.new("TextLabel")
    title.Size, title.Position, title.BackgroundTransparency, title.Text = UDim2.new(1, -60, 0, 20), UDim2.new(0, 12, 0, 8), 1, lbl
    title.TextColor3, title.Font, title.TextSize, title.Parent = Theme.Text, Enum.Font.GothamSemibold, 13, frame
    local sub = Instance.new("TextLabel")
    sub.Size, sub.Position, sub.BackgroundTransparency, sub.Text = UDim2.new(1, -60, 0, 14), UDim2.new(0, 12, 0, 28), 1, desc
    sub.TextColor3, sub.Font, sub.TextSize, sub.Parent = Theme.Dim, Enum.Font.Gotham, 11, frame
    local pill = Instance.new("Frame")
    pill.Size, pill.Position, pill.BackgroundColor3 = UDim2.new(0, 44, 0, 24), UDim2.new(1, -56, 0.5, -12), getF() and Theme.Accent or Theme.Border
    pill.Parent = frame Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("Frame")
    knob.Size, knob.Position, knob.BackgroundColor3, knob.Parent = UDim2.new(0, 18, 0, 18), getF() and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 3, 0.5, -9), Color3.new(1,1,1), pill
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local btn = Instance.new("TextButton")
    btn.Size, btn.BackgroundTransparency, btn.Text, btn.ZIndex, btn.Parent = UDim2.new(1,0,1,0), 1, "", 3, frame
    btn.MouseButton1Click:Connect(function()
        local state = not getF() setF(state)
        TweenService:Create(pill, TweenInfo.new(0.15), {BackgroundColor3 = state and Theme.Accent or Theme.Border}):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {Position = state and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,3,0.5,-9)}):Play()
    end)
end

local function createButton(txt, order, parent, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size, btn.BackgroundColor3, btn.Text, btn.TextColor3 = UDim2.new(1, 0, 0, 36), color, txt, Theme.Text
    btn.Font, btn.TextSize, btn.LayoutOrder, btn.Parent = Enum.Font.GothamBold, 12, order, parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(callback) return btn
end

local function createSlider(lbl, order, parent, minV, maxV, getF, setF, fmt)
    local frame = Instance.new("Frame")
    frame.Size, frame.BackgroundColor3, frame.LayoutOrder, frame.Parent = UDim2.new(1, 0, 0, 56), Theme.Surface, order, parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local title = Instance.new("TextLabel")
    title.Size, title.Position, title.BackgroundTransparency, title.Text = UDim2.new(0.65,0,0,18), UDim2.new(0,12,0,8), 1, lbl
    title.TextColor3, title.Font, title.TextSize, title.Parent = Theme.Text, Enum.Font.GothamSemibold, 12, frame
    local vLbl = Instance.new("TextLabel")
    vLbl.Size, vLbl.Position, vLbl.BackgroundTransparency, vLbl.Text = UDim2.new(0.3,0,0,18), UDim2.new(0.68,0,0,8), 1, string.format(fmt, getF())
    vLbl.TextColor3, vLbl.Font, vLbl.TextSize, vLbl.TextXAlignment, vLbl.Parent = Theme.AccentL, Enum.Font.GothamBold, 12, Enum.TextXAlignment.Right, frame
    local track = Instance.new("Frame")
    track.Size, track.Position, track.BackgroundColor3, track.Parent = UDim2.new(1,-24,0,8), UDim2.new(0,12,0,36), Theme.Border, frame
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)
    local pct = (getF()-minV)/(maxV-minV)
    local fill = Instance.new("Frame")
    fill.Size, fill.BackgroundColor3, fill.Parent = UDim2.new(pct,0,1,0), Theme.Accent, track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)
    local knob = Instance.new("Frame")
    knob.Size, knob.Position, knob.BackgroundColor3, knob.Parent = UDim2.new(0,16,0,16), UDim2.new(pct,-8,0.5,-8), Color3.new(1,1,1), track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
    local dragging = false
    local function update(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = minV + (maxV - minV) * rel if maxV - minV >= 4 then val = math.floor(val + 0.5) end
        setF(val) vLbl.Text = string.format(fmt, val)
        local p = (val - minV) / (maxV - minV) fill.Size, knob.Position = UDim2.new(p,0,1,0), UDim2.new(p,-8,0.5,-8)
    end
    local hit = Instance.new("TextButton")
    hit.Size, hit.BackgroundTransparency, hit.Text, hit.ZIndex, hit.Parent = UDim2.new(1,0,1,0), 1, "", 5, track
    hit.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true update(inp.Position.X) end end)
    UserInputService.InputChanged:Connect(function(inp) if dragging then update(inp.Position.X) end end)
    UserInputService.InputEnded:Connect(function() dragging = false end)
end

-- ══════════════════════════════════════════════
--  MONTAGEM DAS ABAS
-- ══════════════════════════════════════════════
local TabHome, PageHome = createTab("HOME", 1)
createSection("Status", 1, PageHome)
local statusLbl = Instance.new("TextLabel")
statusLbl.Size, statusLbl.BackgroundColor3, statusLbl.Text, statusLbl.TextColor3 = UDim2.new(1, 0, 0, 30), Theme.Surface, "● Aguardando Remotes...", Theme.Dim
statusLbl.Font, statusLbl.TextSize, statusLbl.LayoutOrder, statusLbl.Parent = Enum.Font.Gotham, 12, 2, PageHome
Instance.new("UICorner", statusLbl).CornerRadius = UDim.new(0, 8)

task.spawn(function()
    while G.Running do
        local list = {} for k, v in pairs(REMOTES) do if v then table.insert(list, k) end end
        if #list > 0 then statusLbl.Text, statusLbl.TextColor3 = "● " .. table.concat(list, " · "), Theme.Green
        else statusLbl.Text, statusLbl.TextColor3 = "● Aguardando...", Theme.Dim end
        task.wait(1.5)
    end
end)

-- ABA MULTI-MACRO
local TabMult, PageMult = createTab("MODOS", 2)

createSection("Selecionar Modo Ativo", 1, PageMult)
local activeLbl = Instance.new("TextLabel")
activeLbl.Size, activeLbl.BackgroundColor3, activeLbl.Text, activeLbl.TextColor3 = UDim2.new(1, 0, 0, 36), Theme.Border, "Modo Ativo: RAID", Theme.Text
activeLbl.Font, activeLbl.TextSize, activeLbl.LayoutOrder, activeLbl.Parent = Enum.Font.GothamBold, 13, 2, PageMult
Instance.new("UICorner", activeLbl).CornerRadius = UDim.new(0, 8)

local function changeActiveMode(mode)
    G.ActiveMacro = mode
    activeLbl.Text = "Modo Ativo: " .. string.upper(mode)
end

createButton("Setar Macro: RAID", 3, PageMult, Theme.Surface, function() changeActiveMode("Raid") end)
createButton("Setar Macro: CASSINO", 4, PageMult, Theme.Surface, function() changeActiveMode("Cassino") end)
createButton("Setar Macro: CHALLENGES", 5, PageMult, Theme.Surface, function() changeActiveMode("Chall") end)

createSection("Gravação de Macro", 6, PageMult)
local function makeRecBtn(txt, order, typeName)
    local btn = createButton(txt, order, PageMult, Theme.Border, function()
        if G.IsRecording then
            stopRecording()
            btn.Text = txt
            btn.BackgroundColor3 = Theme.Border
        else
            startRecording(typeName)
            btn.Text = "■ Parar Gravação (" .. typeName .. ")"
            btn.BackgroundColor3 = Theme.Red
        end
    end)
end
makeRecBtn("Gravar Cliques: Raid", 7, "Raid")
makeRecBtn("Gravar Cliques: Cassino", 8, "Cassino")
makeRecBtn("Gravar Cliques: Challenges", 9, "Chall")

createSection("Controle do Loop", 10, PageMult)
local playBtn = createButton("▶ Iniciar Loop do Modo Ativo", 11, PageMult, Theme.Green, function()
    if G.IsPlaying then
        stopPlayback()
        playBtn.Text = "▶ Iniciar Loop do Modo Ativo"
        playBtn.BackgroundColor3 = Theme.Green
    else
        playMacro()
        playBtn.Text = "■ Parar Loop"
        playBtn.BackgroundColor3 = Theme.Red
    end
end)

-- NOVO BOTÃO DE AVISO NO DISCORD
createSection("Aviso no Discord", 12, PageMult)
createButton("Avisar no Discord (Webhook)", 13, PageMult, Color3.fromRGB(88, 101, 242), function()
    sendDiscordAlert("Mythic Shard / Item Desejado")
end)

-- ABA AUTO
local TabAuto, PageAuto = createTab("AUTO", 3)
createSection("Combate", 1, PageAuto)
createToggle("Auto Wave", "Inicia onda automaticamente", 2, PageAuto, function() return G.AutoWave end, function(v) G.AutoWave = v end)
createToggle("Auto Place", "Coloca torres", 3, PageAuto, function() return G.AutoPlace end, function(v) G.AutoPlace = v end)
createToggle("Auto Upgrade", "Sobe torres", 4, PageAuto, function() return G.AutoUpgrade end, function(v) G.AutoUpgrade = v end)
createToggle("Auto Sell", "Vende torres", 5, PageAuto, function() return G.AutoSell end, function(v) G.AutoSell = v end)
createSection("Configurações (Sliders)", 6, PageAuto)
createSlider("Delay entre ondas", 7, PageAuto, 0.5, 5, function() return G.WaveDelay end, function(v) G.WaveDelay = v end, "%.1fs")
createSlider("Nível máximo", 8, PageAuto, 1, 20, function() return G.MaxLevel end, function(v) G.MaxLevel = math.floor(v) end, "%d")
createSlider("Slot da Unidade", 9, PageAuto, 1, 6, function() return G.PlaceSlot end, function(v) G.PlaceSlot = math.floor(v) end, "%d")

switchTab(TabHome, PageHome)
print("[STD] UI Premium com Discord Webhook carregada.")
