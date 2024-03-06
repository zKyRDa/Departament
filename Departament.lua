script_name('Departament')
script_author('KyRDa')
script_description('/depset')
script_version('3')

require 'lib.moonloader'
local imgui = require 'mimgui'
local encoding = require 'encoding'
encoding.default = 'CP1251'
local u8 = encoding.UTF8
local inicfg = require "inicfg"
local ffi = require "ffi"
local sampev = require "lib.samp.events"

local Ini = inicfg.load({
    Settings = {
        Enable = false,
        Scobs = true,
        Chat = false,
        LineBreak = true, -- ������� ������
        Command = 'dep',
        Form = '[#] $ [#]:',
        lastChannel1 = 1,
        lastSymbol = 1,
        lastChannel2 = 1,
        PosX = 0.0,
        PosY = 0.0,
        WidgetPosX = 0.0,
        WidgetPosY = 0.0,
        WidgetTransparency = 1.0,
        MaxText = 80, -- ������������ ���������� �������� � ������� /d ��� ��������
        Widget = true,
        WidgetOff = false,
        Style = 0, -- ����� �����, 0 - ��������, 1 - ������
    },
    Channels = {
        '����'
    },
    Symbols = { -- Symbols - �������, � ���� ��� ����� ����� ������. ������ ����������� ������ ���� ������ ����� ������ '-', ����� ���������, � ��� �� �����
        '-'
    },
    CustomStyleBg = {
        r = 0.043,
        g = 0.039,
        b = 0.039,
    },
    CustomStyleButton = {
        r = 0.52,
        g = 0.07,
        b = 0.04,
    },
    CustomStyleElments = {
        r = 0.09,
        g = 0.09,
        b = 0.09,
    },
    FractionColor = {
        r = 0.52,
        g = 0.07,
        b = 0.04,
    }
}, "DepChannels")
inicfg.save(Ini, "DepChannels")

local tableu8 = {} -- �������� ������ �����
local tableu8Combo = {}
for _, value in ipairs(Ini.Channels) do
    table.insert(tableu8, u8(value))
    table.insert(tableu8Combo, u8(value))
end
local tableu8Symb = {} -- �������� ������ ������ ����� �����
local tableu8ComboSymb = {}
for _, value in ipairs(Ini.Symbols) do
    table.insert(tableu8Symb, u8(value))
    table.insert(tableu8ComboSymb, u8(value))
end

local MainMenu, SettingsMenu =  imgui.new.bool(), imgui.new.bool() -- ��� ��������/�������� ����

local inputCommand =            imgui.new.char[64](u8:encode(Ini.Settings.Command)) -- ��������� ������� ���������
local inputForm =               imgui.new.char[64](u8:encode(Ini.Settings.Form)) -- ����� (�����������) ����������
local inputChannels =           imgui.new.char[64]() -- �������� � ��� � ������
local inputSymbol =             imgui.new.char[64]() -- �������� � ������ � ������

local checkboxEnab =            imgui.new.bool(Ini.Settings.Enable) -- �������� �������
local checkboxChat =            imgui.new.bool(Ini.Settings.Chat) -- ������� ��������� ������ '������ � ���'
local checkboxline =            imgui.new.bool(Ini.Settings.LineBreak) -- ������� ��������� ������� ������

local radiobuttonStyle =        imgui.new.int(Ini.Settings.Style) -- ����� �����
local selectedChannel =         imgui.new.int(0) -- ��������� ������� ������� �����
local selectedSymbol =          imgui.new.int(0) -- ��������� ������� ������� ������ ����� �����
local selectedComboTag1 =       imgui.new.int(Ini.Settings.lastChannel1 - 1) -- ��������� ������ ��� � combo
local selectedComboSymbol =     imgui.new.int(Ini.Settings.lastSymbol - 1) -- ��������� ������ ����� ����� � combo
local selectedComboTag2 =       imgui.new.int(Ini.Settings.lastChannel2 - 1) -- ��������� ������ ��� � combo

local ImItems =                 imgui.new['const char*'][#tableu8](tableu8) -- ������ �����, ���������� ������ � ���������
local ImItemsIni =              imgui.new['const char*'][#tableu8Combo](tableu8Combo) -- ������ �����, ���������� �����
local ImItemsSymb =             imgui.new['const char*'][#tableu8Symb](tableu8Symb) -- ������ �������� �����, ���������� ������ � ���������
local ImItemsIniSymb =          imgui.new['const char*'][#tableu8ComboSymb](tableu8ComboSymb) -- ������ �����, ���������� �����
local checkboxWidg =            imgui.new.bool(Ini.Settings.Widget) -- ��� ������
local checkboxWidgNotOff =      imgui.new.bool(Ini.Settings.WidgetOff) -- �� �������� ������
local colorEditStyleBg =        imgui.new.float[3](Ini.CustomStyleBg.r, Ini.CustomStyleBg.g, Ini.CustomStyleBg.b) -- ����� ����� ���� ���� (��������� ����)
local colorEditStyleButton =    imgui.new.float[3](Ini.CustomStyleButton.r, Ini.CustomStyleButton.g, Ini.CustomStyleButton.b) -- ����� ����� ������ (��������� ����)
local colorEditStyleElments =   imgui.new.float[3](Ini.CustomStyleElments.r, Ini.CustomStyleElments.g, Ini.CustomStyleElments.b) -- ����� ����� ��������� (��������� ����)
local widgetTransparency =      imgui.new.float[1](Ini.Settings.WidgetTransparency) -- ����� ������������ ��� �������

imgui.OnFrame(function() return SettingsMenu[0] and not isPauseMenuActive() and not sampIsScoreboardOpen() end, function() -- ���������
    imgui.SetNextWindowPos(imgui.ImVec2(Ini.Settings.PosX, Ini.Settings.PosY), imgui.Cond.FirstUseEver, imgui.ImVec2(1, 1))
    imgui.Begin('Settings', SettingsMenu, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoFocusOnAppearing + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.AlwaysAutoResize)

    if imgui.BeginPopup('WidgetSettings') then -- �������� �������, ����������� ���� ��� ������� ������ "������"
        for i = 0, 1 do
            imgui.SameLine()
            if imgui.RadioButtonIntPtr(styles[i].name, radiobuttonStyle, i) then
                radiobuttonStyle[0] = i
                styles[i].func(imgui.ImVec4(Ini.FractionColor.r, Ini.FractionColor.g, Ini.FractionColor.b, 1))
            end
        end
        if radiobuttonStyle[0] == 1 then
            imgui.SetCursorPosX(47)
            imgui.PushItemWidth(20)
            if imgui.ColorEdit3(u8'���', colorEditStyleBg, imgui.ColorEditFlags.NoInputs) then
                styles[1].func()
            end
            imgui.SameLine()
            if imgui.ColorEdit3(u8'������', colorEditStyleButton, imgui.ColorEditFlags.NoInputs) then
                styles[1].func()
            end
            imgui.SameLine()
            if imgui.ColorEdit3(u8'��������', colorEditStyleElments, imgui.ColorEditFlags.NoInputs) then
                styles[1].func()
            end
            imgui.PopItemWidth()
        end
        imgui.ToggleButton(u8'�������� ������', checkboxWidg, 260)
        imgui.Hind(u8'�������� ������, ��� ����� �����, � �������� �� ����������, ��� ���������� ������� ������.')
        if checkboxWidg[0] then -- ���� ������ �������
            imgui.ToggleButton(u8'�� �������� ������', checkboxWidgNotOff, 260)
            imgui.Hind(u8'������ ����� ����� ���� ���� ������� ����� ���������.')
            if imgui.Button(u8'����������� ������', imgui.ImVec2(300, 25)) then
                lua_thread.create(function()
                    replace = true
                    imgui.SetNextWindowFocus()
                    while replace do
                        WidgetPosX, WidgetPosY = getCursorPos()
                        if isKeyDown(32) then -- Space
                            replace = false
                            Ini.Settings.WidgetPosX, Ini.Settings.WidgetPosY = WidgetPosX, WidgetPosY
                            inicfg.save(Ini, "DepChannels")
                            return
                        end
                        wait(0)
                    end
                end)
            end
            imgui.PushItemWidth(127)
            imgui.SliderFloat(u8"������������ ���� �������", widgetTransparency, 0.0, 1.0)
            imgui.PopItemWidth()
        end
        imgui.EndPopup()
    end

    -- main
    if imgui.BeginChild('MainSettings', imgui.ImVec2(225, 213), true, imgui.WindowFlags.NoScrollbar) then
        imgui.Text(u8'������� ���������:')
        imgui.SameLine()
        imgui.PushItemWidth(74)
        imgui.SetCursorPosX(145)
        imgui.InputText('##inputcommand', inputCommand, 32)
        imgui.Hind(u8"������� ���� ������� ������� ��� '/' ��� ������ �������� ����.")
        imgui.PopItemWidth()
        imgui.ToggleButton(u8'������ ����� � ���', checkboxChat)
        if imgui.IsItemHovered() then
            imgui.BeginTooltip()
            imgui.Text(u8'��� ��������� ����� ��������� ������ �� ����� ������������� ����������� ���� ���\n��������� � ��� ������������, � � ������� ���� �������� ������ "������ � ���".')
            imgui.TextColored(imgui.ImVec4(1.0, 0.0, 0.0, 1.0 ), u8'��������: ������� ������ �� ����� ��������.')
            imgui.EndTooltip()
        end
        
        imgui.Separator()
        imgui.Text(u8'�����:\n'..Ini.Settings.Form)
        imgui.SameLine()
        imgui.SetCursorPosX(140)
        if imgui.Button(u8'��������', imgui.ImVec2(80, 30)) then -- ����������� ���������� ����� ������, ����� ���� ����������� ������� ����
            imgui.OpenPopup('FormSetting')
        end

        if imgui.BeginPopupModal('FormSetting', _, imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoCollapse) then
            function imgui.PopupCenterText(text)
                imgui.SetCursorPosX(imgui.GetWindowWidth()-imgui.CalcTextSize(text).x/2 - 345)
                imgui.Text(text)
            end
            imgui.PopupCenterText(u8'������� ����� �������� ���������')
            imgui.PopupCenterText(u8'������������ ������ �������:')
            
            
            imgui.PushItemWidth(270)
            imgui.InputText('', inputForm, 32)
            imgui.PopItemWidth()
            
            
            if imgui.Button(u8'�������� � �������', imgui.ImVec2(270, 30)) then -- ����������� ���������� ����� ������, ����� ���� ����������� ������� ����
                imgui.CloseCurrentPopup()
                
                Ini.Settings.Form = u8:decode(ffi.string(inputForm))
                inicfg.save(Ini, "DepChannels")
            end

            imgui.SetCursorPos(imgui.ImVec2(280, 25))
            if imgui.BeginChild('form_description', imgui.ImVec2(200, -1), true) then
                imgui.Spacing()
                imgui.CenterText(u8'����������:')
                imgui.CenterText(u8'#1 � ������ ��������� ���')
                imgui.CenterText(u8'#2 � ������ ��������� ���')
                imgui.CenterText(u8'$ � �����')
                imgui.EndChild()
            end

            imgui.EndPopup()
        end

        imgui.Separator()
        imgui.ToggleButton(u8'������� ��������� /d', checkboxline)
        imgui.Hind(u8"��� ��������� ����� ��������� ��� ��������� /d ����� ��������������.\n����� �� �������� ���������, �������������� � ���� ������, ������ �������� ���.")
        
        imgui.EndChild()
    end
    imgui.SameLine()
    if imgui.BeginChild('Channels', imgui.ImVec2(194, 178), true) then -- ������ �����
        imgui.PushItemWidth(107)
        imgui.InputTextWithHint('', u8'����� ���', inputChannels, 64)
        imgui.PopItemWidth()
        imgui.SameLine()
        if imgui.Button(u8'��������') then -- �������� ����� ���
            local v
            for _, value in ipairs(tableu8) do -- ������ �� ������� �����
                if value == ffi.string(inputChannels) then
                    sampAddChatMessage('{cb2821}[Departament]:{FFFFFF} ������� � ������ � ����� ��������� ��� ����������!', -1)
                    v = value
                    break
                end
            end
            if v ~= ffi.string(inputChannels) then
                table.insert(tableu8, u8(u8:decode(ffi.string(inputChannels))))
                ImItems = imgui.new['const char*'][#tableu8](tableu8)
            end
        end
        imgui.PushItemWidth(179)
        if imgui.ListBoxStr_arr('##list', selectedChannel, ImItems, #tableu8) then -- listbox
            table.remove(tableu8, selectedChannel[0] + 1)
            ImItems = imgui.new['const char*'][#tableu8](tableu8)
        end
        imgui.Hind(u8'������� ��� ��������.')
        imgui.PopItemWidth()
        imgui.EndChild()
        -- imgui.SetCursorPos(imgui.ImVec2(240, 212))
    end
    imgui.SameLine()
    if imgui.BeginChild('Symbol', imgui.ImVec2(194, 178), true) then
        imgui.PushItemWidth(107)
        imgui.InputTextWithHint('', u8'����� �����', inputSymbol, 64)
        imgui.PopItemWidth()
        imgui.SameLine()
        if imgui.Button(u8'��������') then -- �������� ����� ���
            local v
            for _, value in ipairs(tableu8Symb) do -- ������ �� ������� �����
                if value == ffi.string(inputSymbol) then
                    sampAddChatMessage('{cb2821}[Departament]:{FFFFFF} ������� � ������ � ����� ��������� ��� ����������!', -1)
                    v = value
                    break
                end
            end
            if v ~= ffi.string(inputSymbol) then
                table.insert(tableu8Symb, ffi.string(inputSymbol))
                ImItemsSymb = imgui.new['const char*'][#tableu8Symb](tableu8Symb)
            end
        end
    end
    imgui.PushItemWidth(179)
    if imgui.ListBoxStr_arr('##list', selectedSymbol, ImItemsSymb, #tableu8Symb) then -- listbox
        table.remove(tableu8Symb, selectedSymbol[0] + 1)
        ImItemsSymb = imgui.new['const char*'][#tableu8Symb](tableu8Symb)
    end
    imgui.Hind(u8'������� ��� ��������.')
    imgui.PopItemWidth()
    imgui.EndChild()
    imgui.SetCursorPos(imgui.ImVec2(240, 212))
    imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(5, 7))
    if imgui.Button(u8'������', imgui.ImVec2(60, 30)) then
        imgui.OpenPopup('WidgetSettings')
    end
    imgui.SameLine()
    if imgui.Button(u8'��������� � �������', imgui.ImVec2(331, 30)) then -- ����������
        Save()
    end
    imgui.PopStyleVar()
    imgui.End()
end)

imgui.OnFrame(function() return MainMenu[0] and not isPauseMenuActive() and not sampIsScoreboardOpen() end, function(self) -- ������� ����
    if isKeyDown(32) and self.HideCursor == false then -- ������ ������ ���� ����� ������
        self.HideCursor = true
    elseif not isKeyDown(32) then
        self.HideCursor = false
    end
    imgui.SetNextWindowPos(imgui.ImVec2(Ini.Settings.PosX, Ini.Settings.PosY), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.Begin('Departament', MainMenu, imgui.WindowFlags.NoResize + imgui.WindowFlags.AlwaysAutoResize)
    imgui.PushItemWidth(150)
    imgui.PushStyleVarVec2(imgui.StyleVar.FramePadding, imgui.ImVec2(7, 4))
    imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(8, 8))
    imgui.Text(u8'������ ���:')
    imgui.SameLine()
    imgui.SetCursorPosX(100)
    if imgui.Combo('##tag1', selectedComboTag1, ImItemsIni, #tableu8Combo, imgui.ComboFlags.HeightLargest) then
        Ini.Settings.lastChannel1 = selectedComboTag1[0] + 1
        local pos = imgui.GetWindowPos() -- �������� ��������������� ����
        Ini.Settings.PosX, Ini.Settings.PosY = pos.x, pos.y -- ���������� �������
        inicfg.save(Ini, "DepChannels")
    end

    imgui.Text(u8'����� �����:')
    imgui.SameLine()
    imgui.SetCursorPosX(100)
    if imgui.Combo('##symbolcombo', selectedComboSymbol, ImItemsIniSymb, #tableu8ComboSymb, imgui.ComboFlags.HeightLargest) then
        Ini.Settings.lastSymbol = selectedComboSymbol[0] + 1
        local pos = imgui.GetWindowPos()
        Ini.Settings.PosX, Ini.Settings.PosY = pos.x, pos.y
        inicfg.save(Ini, "DepChannels")
    end

    imgui.Text(u8'������ ���:')
    imgui.SameLine()
    imgui.SetCursorPosX(100)
    if imgui.Combo('##tag2', selectedComboTag2, ImItemsIni, #tableu8Combo, imgui.ComboFlags.HeightLargest) then
        Ini.Settings.lastChannel2 = selectedComboTag2[0] + 1
        local pos = imgui.GetWindowPos()
        Ini.Settings.PosX, Ini.Settings.PosY = pos.x, pos.y
        inicfg.save(Ini, "DepChannels")
    end
    if checkboxChat[0] then
        if imgui.Button(u8'������ � ���', imgui.ImVec2(244, 26)) then
            local pos = imgui.GetWindowPos()
            Ini.Settings.PosX, Ini.Settings.PosY = pos.x, pos.y
            inicfg.save(Ini, "DepChannels")
            sampSetChatInputEnabled(true) -- �������� ����
            sampSetChatInputText('/d '..GetCompletedForm())
        end
    else
        if imgui.ToggleButton(u8'�������� �������', checkboxEnab, 195) then
            Ini.Settings.Enable = checkboxEnab[0]
            inicfg.save(Ini, "DepChannels")
        end
    end
    imgui.PopStyleVar(2)

    imgui.Separator()
    imgui.CenterText(u8'������������')
    imgui.CenterText(u8:encode(GetCompletedForm()))
    imgui.End()
end)

imgui.OnFrame(function() -- ������
    local reason = checkboxWidgNotOff[0] and checkboxWidg[0] or checkboxWidg[0] and checkboxEnab[0] -- ���� �������� '�� �������� ������' � ��� ������ ������� �� ���������� ���� ����� ���� ������� ��������, �������� ������ 
    return reason or replace and not isPauseMenuActive() and not sampIsScoreboardOpen() end, function()
    imgui.SetNextWindowPos(imgui.ImVec2(WidgetPosX, WidgetPosY), imgui.Cond.Always, imgui.ImVec2(1, 1))
    
    if replace then
        imgui.GetBackgroundDrawList():AddTextFontPtr(font_alert, 50, imgui.ImVec2(Ini.Settings.PosX * 0.72, Ini.Settings.PosY), imgui.GetColorU32Vec4(imgui.ImVec4(0.796, 0.156, 0.129, 1)), u8'SPACE ��� ����������')
    end

    local colors = imgui.GetStyle().Colors
    local clr = imgui.Col
    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(colors[clr.WindowBg].x, colors[clr.WindowBg].y, colors[clr.WindowBg].z, widgetTransparency[0]))
    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(colors[clr.Border].x, colors[clr.Border].y, colors[clr.Border].z, widgetTransparency[0] - 0.6))
    imgui.PushStyleColor(imgui.Col.Separator, imgui.ImVec4(colors[clr.Separator].x, colors[clr.Separator].y, colors[clr.Separator].z, widgetTransparency[0] - 0.5))

    imgui.Begin('Widget', SettingsMenu, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.AlwaysAutoResize)
    
    imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(8, 7))
    imgui.CenterText('Departament')

    imgui.Separator()
    imgui.CenterText(u8:encode(GetCompletedForm()))

    imgui.PopStyleVar()
    imgui.PopStyleColor(3)
    imgui.End()
end).HideCursor = true

function GetCompletedForm()
    local form = string.gsub(Ini.Settings.Form, '#1', Ini.Channels[Ini.Settings.lastChannel1])
    form = string.gsub(form, '%$', Ini.Symbols[Ini.Settings.lastSymbol])
    form = string.gsub(form, '#2', Ini.Channels[Ini.Settings.lastChannel2])

    return form
end

function sampev.onServerMessage(color, text) -- ������� �������� ������, ���� � id ��� ����������� �������� ������
    if text:find('%[D%] (.+)% '..myname..'%[(%d+)%]:') then
        local rank, id = text:match('%[D%] (.+)% '..myname..'%[(%d+)%]: ')
        text = '[D] '..rank..' '..myname..'['..id..']: '
        Ini.Settings.MaxText = 119 - #text
        inicfg.save(Ini, "DepChannels")
    end
end

local firstMessage -- ���������� ��� ��������
local secondMessage
local Message -- ��������� ������������ ������ � /d
function sampev.onSendCommand(text)
    if not checkboxChat[0] and checkboxEnab[0] and text:find('^/d%s+.+%s*') and Message ~= text and firstMessage ~= text and secondMessage ~= text then
        local dtext = text:match('^/d%s+(.+)%s*')
        Message = string.format('/d %s %s', GetCompletedForm(), dtext)

        if #Message:sub(3) > Ini.Settings.MaxText and Ini.Settings.LineBreak then -- ������� ������
            firstMessage = string.match(dtext:sub(1, Ini.Settings.MaxText), "(.*) (.*)") -- ������ (.*) - ����� � ������ �������, ������ - ������� ������ 
            
            if firstMessage == nil then
                return sampAddChatMessage('{cb2821}[Departament]:{FFFFFF} ������� ������ ��������� ������ ����� � ���������. ��������� ��� ������� ����� � /depset', -1)
            end

            secondMessage = string.match(string.sub(dtext, #firstMessage+2, 119), "(.*)") -- ������ ����� � ������� ��������

            -- formation
            firstMessage = string.format('/d %s %s', GetCompletedForm(), firstMessage)
            secondMessage = string.format('/d %s %s', GetCompletedForm(), secondMessage)

            -- Send
            lua_thread.create(function()
                sampSendChat(firstMessage)
                wait(2000) -- 2 sec
                sampSendChat(secondMessage)
            end)
        else
            sampSendChat(Message)
        end

        return false
    end
end

function main()
    while not isSampAvailable() do wait(0) end
    sampRegisterChatCommand(Ini.Settings.Command, function()
        if radiobuttonStyle[0] == 0 then DetermineFractionColor() end
        MainMenu[0] = not MainMenu[0]
    end)
    sampRegisterChatCommand('depset', function()
        if radiobuttonStyle[0] == 0 then DetermineFractionColor() end
        SettingsMenu[0] = not SettingsMenu[0]
    end)
    sampRegisterChatCommand('depget', function()
        sampAddChatMessage(GetCompletedForm(), -1)
    end)

    myname = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))) -- ��������� ����� ������ ���������

    sampAddChatMessage("{cb2821}[Departament]:{FFFFFF} ������ ��������. �������: /"..Ini.Settings.Command.." /depset. �����: KyRDa", -1)
end

function DetermineFractionColor()
    local rgbCode = sampGetPlayerColor(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))
    local r = bit.band(bit.rshift(rgbCode, 16), 0xFF)
    local g = bit.band(bit.rshift(rgbCode, 8), 0xFF)
    local b = bit.band(rgbCode, 0xFF)

    if r + g + b < 757 and r + g + b ~= 292 and sampIsLocalPlayerSpawned() and imgui.Loaded then -- 757 = white ([ARZ]��� ������ � ���� = 253, 252, 252; ��� ������ ����� = 255, 255, 255), 292 = grey
        styles[Ini.Settings.Style].func(imgui.ImVec4(r, g, b, 1))
        
        Ini.FractionColor.r, Ini.FractionColor.g, Ini.FractionColor.b = r, g, b
        inicfg.save(Ini, "DepChannels")
    end
end

-- �����
function Theme()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    style.FrameRounding = 5
    style.ChildRounding = 4
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
    style.ScrollbarSize = 17
    colors[imgui.Col.Header] = imgui.ImVec4(0, 0, 0, 0)
    colors[imgui.Col.CheckMark] = imgui.ImVec4(1, 1, 1, 1)
    styles[Ini.Settings.Style].func(imgui.ImVec4(Ini.FractionColor.r, Ini.FractionColor.g, Ini.FractionColor.b, 1))
end
styles = {
    [0] = {
        name = u8'����������� ����',
        func = function(StyleColor)
            local colors = imgui.GetStyle().Colors
            local clr = imgui.Col
            
            colors[clr.WindowBg] =          imgui.ImVec4(0.043, 0.039, 0.039, 0.941)
            colors[clr.PopupBg] =           imgui.ImVec4(0.043, 0.039, 0.039, 1)
            colors[clr.ChildBg] =           imgui.ImVec4(0.043, 0.039, 0.039, 0.3)
            colors[clr.Border] =            imgui.ImVec4(0.5, 0.5, 0.5, 0.4)
            colors[clr.Separator] =         imgui.ImVec4(0.5, 0.5, 0.5, 0.7)

            colors[clr.TitleBgActive] =     imgui.ImVec4(StyleColor.x, StyleColor.y, StyleColor.z, 0.8)
            colors[clr.TitleBg] =           imgui.ImVec4(StyleColor.x, StyleColor.y, StyleColor.z, 0.8)
            colors[clr.FrameBg] =           imgui.ImVec4(StyleColor.x, StyleColor.y, StyleColor.z, 0.078)
            colors[clr.FrameBgHovered] =    imgui.ImVec4(StyleColor.x, StyleColor.y, StyleColor.z, 0.431)
            colors[clr.FrameBgActive] =     imgui.ImVec4(StyleColor.x, StyleColor.y, StyleColor.z, 0.431)
            colors[clr.Button] =            imgui.ImVec4(StyleColor.x, StyleColor.y, StyleColor.z, 0.588)
            colors[clr.ButtonHovered] =     imgui.ImVec4(StyleColor.x, StyleColor.y, StyleColor.z, 0.8)
            colors[clr.ButtonActive] =      imgui.ImVec4(StyleColor.x, StyleColor.y, StyleColor.z, 1)
            colors[clr.HeaderHovered] =     imgui.ImVec4(StyleColor.x, StyleColor.y, StyleColor.z, 0.8)
            colors[clr.HeaderActive] =      imgui.ImVec4(StyleColor.x, StyleColor.y, StyleColor.z, 1)
            colors[clr.SliderGrab] =        imgui.ImVec4(StyleColor.x, StyleColor.y, StyleColor.z, 0.5)
            colors[clr.SliderGrabActive] =  imgui.ImVec4(StyleColor.x, StyleColor.y, StyleColor.z, 1)
        end
    },
    [1] = {
        name = u8'��������� ����',
        func = function()
            local colors = imgui.GetStyle().Colors
            local clr = imgui.Col

            colors[clr.WindowBg] =          imgui.ImVec4(colorEditStyleBg[0], colorEditStyleBg[1], colorEditStyleBg[2], 0.99)
            colors[clr.PopupBg] =           imgui.ImVec4(colorEditStyleBg[0], colorEditStyleBg[1], colorEditStyleBg[2], 1)
            colors[clr.TitleBg] =           imgui.ImVec4(colorEditStyleButton[0], colorEditStyleButton[1], colorEditStyleButton[2], 1)
            colors[clr.TitleBgActive] =     imgui.ImVec4(colorEditStyleButton[0], colorEditStyleButton[1], colorEditStyleButton[2], 1)
            colors[clr.ChildBg] =           imgui.ImVec4(colorEditStyleBg[0] - 0.70, colorEditStyleBg[1] - 0.70, colorEditStyleBg[2] - 0.70, 0.3)
            colors[clr.FrameBg] =           imgui.ImVec4(colorEditStyleElments[0], colorEditStyleElments[1], colorEditStyleElments[2], 0.7)
            colors[clr.FrameBgHovered] =    imgui.ImVec4(colorEditStyleElments[0] + 0.122, colorEditStyleElments[1] + 0.122, colorEditStyleElments[2] + 0.122, 1)
            colors[clr.FrameBgActive] =     imgui.ImVec4(colorEditStyleElments[0] + 0.122, colorEditStyleElments[1] + 0.122, colorEditStyleElments[2] + 0.122, 0.6)
            colors[clr.Border] =            imgui.ImVec4(colorEditStyleElments[0], colorEditStyleElments[1], colorEditStyleElments[2], 0.4)
            colors[clr.Separator] =         imgui.ImVec4(colorEditStyleElments[0], colorEditStyleElments[1], colorEditStyleElments[2], 0.7)
            colors[clr.HeaderHovered] =     imgui.ImVec4(colorEditStyleElments[0] + 0.122, colorEditStyleElments[1] + 0.122, colorEditStyleElments[2] + 0.122, 1)
            colors[clr.HeaderActive] =      imgui.ImVec4(colorEditStyleElments[0] + 0.122, colorEditStyleElments[1] + 0.122, colorEditStyleElments[2] + 0.122, 0.6)
            colors[clr.Button] =            imgui.ImVec4(colorEditStyleButton[0], colorEditStyleButton[1], colorEditStyleButton[2], 1)
            colors[clr.ButtonHovered] =     imgui.ImVec4(colorEditStyleButton[0] + 0.102, colorEditStyleButton[1] + 0.204, colorEditStyleButton[2] + 0.177, 1)
            colors[clr.ButtonActive] =      imgui.ImVec4(colorEditStyleButton[0] + 0.102, colorEditStyleButton[1] + 0.349, colorEditStyleButton[2] + 0.393, 1)
            colors[clr.SliderGrab] =        imgui.ImVec4(colorEditStyleButton[0], colorEditStyleButton[1], colorEditStyleButton[2], 0.5)
            colors[clr.SliderGrabActive] =  imgui.ImVec4(colorEditStyleButton[0], colorEditStyleButton[1], colorEditStyleButton[2], 1)
        end
    }
}

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    if Ini.Settings.PosX == 0 then
        local posX, posY = getScreenResolution()
        Ini.Settings.PosX, Ini.Settings.PosY = posX/2, posY/2
        Ini.Settings.WidgetPosX, Ini.Settings.WidgetPosY = posX * 0.1, posY * 0.7
        inicfg.save(Ini, "DepChannels")
    end
    WidgetPosX, WidgetPosY = Ini.Settings.WidgetPosX, Ini.Settings.WidgetPosY -- ����������� ���������� � ����������� ������
    font_alert = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 50, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())

    Theme()

    imgui.Loaded = true
end)
-- ������������ ������
function imgui.CenterText(text)
    imgui.SetCursorPosX(imgui.GetWindowWidth()/2-imgui.CalcTextSize(text).x/2)
    imgui.Text(text)
end
-- ���������
function imgui.Hind(text)
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.Text(text)
        imgui.EndTooltip()
    end
end
-- ���������� ��������
function Save()
    Ini.Settings.Style = radiobuttonStyle[0]
    Ini.Settings.Command = u8:decode(ffi.string(inputCommand))
    Ini.Settings.Chat = checkboxChat[0] and true or false
    Ini.Settings.LineBreak = checkboxline[0] and true or false
    Ini.Settings.Widget = checkboxWidg[0] and true or false
    Ini.Settings.WidgetOff = checkboxWidgNotOff[0] and true or false
    Ini.Settings.WidgetPosX, Ini.Settings.WidgetPosY = WidgetPosX, WidgetPosY
    Ini.CustomStyleBg.r, Ini.CustomStyleBg.g, Ini.CustomStyleBg.b = colorEditStyleBg[0], colorEditStyleBg[1], colorEditStyleBg[2]
    Ini.CustomStyleButton.r, Ini.CustomStyleButton.g, Ini.CustomStyleButton.b = colorEditStyleButton[0], colorEditStyleButton[1], colorEditStyleButton[2]
    Ini.CustomStyleElments.r, Ini.CustomStyleElments.g, Ini.CustomStyleElments.b = colorEditStyleElments[0], colorEditStyleElments[1], colorEditStyleElments[2]
    Ini.Settings.WidgetTransparency = widgetTransparency[0]
    for value, _ in pairs(Ini.Channels) do -- ���������� ������ ����� � Combo � Ini
        Ini.Channels[value] = nil
        tableu8Combo[value] = nil
    end
    for _, value in ipairs(tableu8) do
        table.insert(Ini.Channels, u8:decode(ffi.string(value)))
        table.insert(tableu8Combo, value)
    end
    if rawequal(next(tableu8), nil) then -- ���� ������ �����, ��
        sampAddChatMessage("{cb2821}[Departament]:{FFFFFF} ������ ��������� ������ ������!", -1)
        table.insert(Ini.Channels, u8'����')
        table.insert(tableu8Combo, u8'����')
        table.insert(tableu8, u8'����')
        ImItems = imgui.new['const char*'][#tableu8](tableu8)
    end
    ImItemsIni = imgui.new['const char*'][#tableu8Combo](tableu8Combo)
    sampRegisterChatCommand(Ini.Settings.Command, function() MainMenu[0] = not MainMenu[0] end) -- ����������� ����� ������� �������� � input
     -- ���������� ������ ������ �����
    for value, _ in pairs(Ini.Symbols) do -- ���������� ������ ������ ����� ����� � Combo � Ini
        Ini.Symbols[value] = nil
        tableu8ComboSymb[value] = nil
    end
    for _, value in ipairs(tableu8Symb) do
        table.insert(Ini.Symbols, u8:decode(ffi.string(value)))
        table.insert(tableu8ComboSymb, value)
    end
    if rawequal(next(tableu8Symb), nil) then -- ���� ������ �����, ��
        sampAddChatMessage("{cb2821}[Departament]:{FFFFFF} ������ ��������� ������ ������!", -1)
        table.insert(Ini.Symbols, '-')
        table.insert(tableu8ComboSymb, '-')
        table.insert(tableu8Symb, '-')
        ImItemsSymb = imgui.new['const char*'][#tableu8Symb](tableu8Symb)
    end
    ImItemsIniSymb = imgui.new['const char*'][#tableu8ComboSymb](tableu8ComboSymb)

    inicfg.save(Ini, "DepChannels")
end
-- �������
LastActiveTime = {}
LastActive = {}
function imgui.ToggleButton(label, bool, distance)
    local rBool = false

    distance = distance or 170 -- ���� �������� ��������� �� �����, �� �� ����� 170

	local function ImSaturate(f)
		return f < 0.0 and 0.0 or (f > 1.0 and 1.0 or f)
	end

    local height = imgui.GetTextLineHeightWithSpacing() * 1.1
	local width = height * 1.55
	local radius = height / 2
	local ANIM_SPEED = 0.10

    local dl = imgui.GetWindowDrawList()
	local p = imgui.GetCursorScreenPos()

	if imgui.InvisibleButton(label, imgui.ImVec2(width + radius + distance, height + 2)) then
		bool[0] = not bool[0]
		rBool = true
		LastActiveTime[tostring(label)] = os.clock()
		LastActive[tostring(label)] = true
	end

	local t = bool[0] and 1.0 or 0.0

	if LastActive[tostring(label)] then
		local time = os.clock() - LastActiveTime[tostring(label)]
		if time <= ANIM_SPEED then
			local t_anim = ImSaturate(time / ANIM_SPEED)
			t = bool[0] and t_anim or 1.0 - t_anim
		else
			LastActive[tostring(label)] = false
		end
	end

	local col_bg = imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col.Button]) -- ���� ���������������

    if bool[0] then
        dl:AddText(imgui.ImVec2(p.x, p.y + radius - (radius / 2) - (imgui.CalcTextSize(label).y / 5)), imgui.GetColorU32Vec4(imgui.ImVec4(1, 1, 1, 1)), label) -- �����
        dl:AddRectFilled(imgui.ImVec2(p.x + distance, p.y), imgui.ImVec2(p.x + width + 10 + distance, p.y + height), col_bg, 12) -- ������� �������������
    else
        dl:AddText(imgui.ImVec2(p.x, p.y + radius - (radius / 2) - (imgui.CalcTextSize(label).y / 5)), imgui.GetColorU32Vec4(imgui.ImVec4(1, 1, 1, 0.5)), label)
        dl:AddRectFilled(imgui.ImVec2(p.x + distance, p.y), imgui.ImVec2(p.x + width + 10 + distance, p.y + height), imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col.FrameBg]), 12)
        dl:AddRect(imgui.ImVec2(p.x + distance, p.y), imgui.ImVec2(p.x + width + 10 + distance, p.y + height), col_bg, 12) -- ������� ������ ��������������
    end
    dl:AddCircleFilled(imgui.ImVec2(p.x + radius + t * (width + 10 - radius * 2.0) + distance, p.y + radius), radius * 0.55, imgui.GetColorU32Vec4(imgui.ImVec4(1, 1, 1, 1)), 12) -- ����� ������ ������

	return rBool
end