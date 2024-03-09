script_name('Departament')
script_author('KyRDa')
script_description('/depset')
script_version('3.0.2')

require('lib.moonloader')
local ffi = require("ffi")

ffi.cdef([[
    typedef struct { float x, y, z; } CVector;
    int MessageBoxA(
        void* hWnd,
        const char* lpText,
        const char* lpCaption,
        unsigned int uType
    );
]])

req, require = require, function(str, downloadUrl) -- from https://www.blast.hk/threads/154860/
    local result, data = pcall(req, str)
    if not result then
        ffi.C.MessageBoxA(ffi.cast('void*', readMemory(0x00C8CF88, 4, false)), ('Error, lib "%s" not found. Download: %s'):format(str,
                                   downloadUrl or '������ �� �������', str, downloadUrl or '������ �� �������'), 'Departament error', 0x50000)
        if downloadUrl then
            os.execute('explorer "'..downloadUrl..'"')
        end
        error('Lib '..str..' not found!')
    end
    return data
end

local imgui = require('mimgui', 'https://www.blast.hk/threads/66959/')
local encoding = require('encoding')
encoding.default = 'CP1251'
local u8 = encoding.UTF8
local inicfg = require("inicfg")
local sampev = require("lib.samp.events", 'https://www.blast.hk/threads/14624/')

local Ini = inicfg.load({
    Settings = {
        Enable = false,
        Chat = false,
        LineBreak = true, -- ������� ������
        Command = 'dep',
        Form = '[#1] $ [#2]:',
        lastChannel1 = 1,
        lastWave = 1,
        lastChannel2 = 1,
        PosX = 0,
        PosY = 0,
        Widget = true,
        NotHideWidget = false,
        WidgetPosX = 0,
        WidgetPosY = 0,
        WidgetTransparency = 1.0,
        WidgetFontSize = 13.5,
        AlternativeFilling = false,
        MaxText = 80, -- ������������ ���������� �������� � ������� /d ��� ��������
        Style = 0, -- ����� �����, 0 - �������� (�����������), 1 - ������
    },
    Channels = {
        '����'
    },
    Waves = { -- Waves - �������, � ���� ��� ����� ����� ������. ������ ����������� ������ ���� ������ ����� ������ '-', ����� ���������, � ��� �� �����
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

local tableu8ListTags = {} -- �������� ������ �����
local tableu8ModifiedListTags = {}
for _, value in ipairs(Ini.Channels) do
    table.insert(tableu8ListTags, u8:encode(value))
    table.insert(tableu8ModifiedListTags, u8:encode(value))
end

local tableu8ListWaves = {} -- �������� ������ ������ ����� �����
local tableu8ModifiedListWaves = {}
for _, value in ipairs(Ini.Waves) do
    table.insert(tableu8ListWaves, u8:encode(value))
    table.insert(tableu8ModifiedListWaves, u8:encode(value))
end

local MainMenu, SettingsMenu =  imgui.new.bool(), imgui.new.bool() -- �����

local inputCommand =                    imgui.new.char[64](u8:encode(Ini.Settings.Command)) -- ��������� ������� ���������
local inputForm =                       imgui.new.char[64](u8:encode(Ini.Settings.Form)) -- ����� (�����������) ����������
local inputChannels =                   imgui.new.char[64]() -- �������� � ��� � ������
local inputWave =                       imgui.new.char[64]() -- �������� � ������ � ������

local checkboxEnab =                    imgui.new.bool(Ini.Settings.Enable) -- �������� �������
local checkboxChat =                    imgui.new.bool(Ini.Settings.Chat) -- ������� ��������� ������ '������ � ���'
local checkboxline =                    imgui.new.bool(Ini.Settings.LineBreak) -- ������� ��������� ������� ������
local checkboxWidg =                    imgui.new.bool(Ini.Settings.Widget) -- ��� ������
local checkboxNotHideWidget =           imgui.new.bool(Ini.Settings.NotHideWidget) -- �� �������� ������
local checkboxAlternativeFilling =      imgui.new.bool(Ini.Settings.AlternativeFilling) -- ��� ������

local radiobuttonStyle =                imgui.new.int(Ini.Settings.Style) -- ����� �����
local selectedChannel =                 imgui.new.int(0) -- ��������� ������� ������� �����
local selectedWave =                    imgui.new.int(0) -- ��������� ������� ������� ������ ����� �����
local selectedComboTag1 =               imgui.new.int(Ini.Settings.lastChannel1) -- ��������� ������ ��� � combo
local selectedComboWave =               imgui.new.int(Ini.Settings.lastWave) -- ��������� ������ ����� ����� � combo
local selectedComboTag2 =               imgui.new.int(Ini.Settings.lastChannel2) -- ��������� ������ ��� � combo

local colorEditStyleBg =                imgui.new.float[3](Ini.CustomStyleBg.r, Ini.CustomStyleBg.g, Ini.CustomStyleBg.b) -- ����� ����� ���� ���� (��������� ����)
local colorEditStyleButton =            imgui.new.float[3](Ini.CustomStyleButton.r, Ini.CustomStyleButton.g, Ini.CustomStyleButton.b) -- ����� ����� ������ (��������� ����)
local colorEditStyleElments =           imgui.new.float[3](Ini.CustomStyleElments.r, Ini.CustomStyleElments.g, Ini.CustomStyleElments.b) -- ����� ����� ��������� (��������� ����)
local widgetTransparency =              imgui.new.float[1](Ini.Settings.WidgetTransparency) -- ����� ������������ ��� �������
local widgetFontSize =                  imgui.new.float[1](Ini.Settings.WidgetFontSize) -- ����� ������������ ��� �������

local ListTags =                        imgui.new['const char*'][#tableu8ListTags](tableu8ListTags) -- ������ �����, ���������� ������ � ���������
local ListWaves =                       imgui.new['const char*'][#tableu8ListWaves](tableu8ListWaves) -- ������ �������� �����, ���������� ������ � ���������

imgui.OnFrame(function() return SettingsMenu[0] and not isPauseMenuActive() and not sampIsScoreboardOpen() end, function() -- ���������
    imgui.SetNextWindowPos(imgui.ImVec2(500, 500), imgui.Cond.FirstUseEver, imgui.ImVec2(1, 1))
    imgui.Begin('Departament Settings', SettingsMenu, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoFocusOnAppearing + imgui.WindowFlags.NoCollapse)
    
    if imgui.BeginChild('MainSettings', imgui.ImVec2(225, 213), true, imgui.WindowFlags.AlwaysAutoResize) then
        imgui.Text(u8'�����:\n'..Ini.Settings.Form)
        imgui.SameLine()

        imgui.SetCursorPosX(140)
        if imgui.Button(u8'��������', imgui.ImVec2(80, 30)) then -- ����������� ���������� ����� ������, ����� ���� ����������� ������� ����
            imgui.OpenPopup('FormSetting')
        end
        if imgui.IsItemHovered() then imgui.SetMouseCursor(7) end -- hand
        
        if imgui.BeginPopupModal('FormSetting', _, imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoCollapse) then
            function imgui.PopupCenterText(text)
                imgui.SetCursorPosX(imgui.GetWindowWidth()-imgui.CalcTextSize(text).x/2 - 345)
                imgui.Text(text)
            end

            imgui.PopupCenterText(u8'������� ����� �������� ���������')
            imgui.PopupCenterText(u8'������������ ������ �������:')
            
            
            imgui.PushItemWidth(270)
            imgui.InputText('##formInput', inputForm, 32)
            imgui.PopItemWidth()
            
            
            if imgui.Button(u8'�������� � �������', imgui.ImVec2(270, 30)) then -- ����������� ���������� ����� ������, ����� ���� ����������� ������� ����
                imgui.CloseCurrentPopup()
                
                Ini.Settings.Form = u8:decode(ffi.string(inputForm))
                inicfg.save(Ini, "DepChannels")
            end
            if imgui.IsItemHovered() then
                imgui.SetMouseCursor(7) -- hand
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
        imgui.ToggleButton(u8'������', checkboxWidg)
        imgui.Hind(u8'��� �������� ����, �������� ������ ��� ����� �����, � �������� ����������.')
        
        if checkboxWidg[0] then -- ���� ������ �������
            imgui.ToggleButton(u8'�� �������� ������', checkboxNotHideWidget)
            imgui.Hind(u8'������ ����� ����� ������.')

            imgui.PushItemWidth(88)

            imgui.Text(u8'������ ������:')
            imgui.SameLine()
            imgui.SetCursorPosX(132)
            imgui.DragFloat("##widgetFontSize", widgetFontSize, 0.05, 0, 100, "%.3f", 1)
            imgui.Hind(u8'�������� ������ ������ �������.')
            if imgui.IsItemHovered() then imgui.SetMouseCursor(7) end -- hand
            if imgui.IsItemActive() then imgui.SetMouseCursor(4) end -- resize EW
            
            imgui.Text(u8'������������ ����:')
            imgui.SameLine()
            imgui.DragFloat("##widgetTransparency", widgetTransparency, 0.005, 0, 1, "%.3f", 1)
            imgui.Hind(u8'�������� ������������ ���� �������.')
            if imgui.IsItemHovered() then imgui.SetMouseCursor(7) end -- hand
            if imgui.IsItemActive() then imgui.SetMouseCursor(4) end -- resize EW
        
            imgui.PopItemWidth()

            imgui.ToggleButton(u8'�������������� ����', checkboxAlternativeFilling)
            imgui.Hind(u8'�� ������� ��������� ����� ����� � �������!')
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
            for _, value in ipairs(tableu8ListTags) do -- ������ �� ������� �����
                if value == ffi.string(inputChannels) then
                    sampAddChatMessage('{cb2821}[Departament]:{FFFFFF} ������� � ������ � ����� ��������� ��� ����������!', -1)
                    v = value
                    break
                end
            end
            if v ~= ffi.string(inputChannels) then
                table.insert(tableu8ListTags, u8(u8:decode(ffi.string(inputChannels))))
                ListTags = imgui.new['const char*'][#tableu8ListTags](tableu8ListTags)
            end
        end
        if imgui.IsItemHovered() then imgui.SetMouseCursor(7) end -- hand

        imgui.PushStyleColor(imgui.Col.HeaderHovered, imgui.ImVec4(1, 0, 0, 0.431))
        imgui.PushStyleColor(imgui.Col.HeaderActive, imgui.ImVec4(1, 0, 0, 0.8))
        imgui.PushItemWidth(179)

        if imgui.ListBoxStr_arr('##list', selectedChannel, ListTags, #tableu8ListTags) then -- listbox
            table.remove(tableu8ListTags, selectedChannel[0] + 1)
            ListTags = imgui.new['const char*'][#tableu8ListTags](tableu8ListTags)
        end

        imgui.PopStyleColor(2)
        if imgui.IsItemHovered() then imgui.SetMouseCursor(7) end -- hand
        imgui.Hind(u8'������� ��� ��������.')
        imgui.PopItemWidth()

        imgui.EndChild()
    end

    imgui.SameLine()
    if imgui.BeginChild('Wave', imgui.ImVec2(194, 178), true) then
        imgui.PushItemWidth(107)
        imgui.InputTextWithHint('', u8'����� �����', inputWave, 64)
        imgui.PopItemWidth()
        imgui.SameLine()
        if imgui.Button(u8'��������') then -- �������� ����� ���
            local v
            for _, value in ipairs(tableu8ListWaves) do -- ������ �� ������� �����
                if value == ffi.string(inputWave) then
                    sampAddChatMessage('{cb2821}[Departament]:{FFFFFF} ������� � ������ � ����� ��������� ��� ����������!', -1)
                    v = value
                    break
                end
            end
            if v ~= ffi.string(inputWave) then
                table.insert(tableu8ListWaves, ffi.string(inputWave))
                ListWaves = imgui.new['const char*'][#tableu8ListWaves](tableu8ListWaves)
            end
        end

        if imgui.IsItemHovered() then imgui.SetMouseCursor(7) end -- hand
        imgui.PushItemWidth(179)
        imgui.PushStyleColor(imgui.Col.HeaderHovered, imgui.ImVec4(1, 0, 0, 0.431))
        imgui.PushStyleColor(imgui.Col.HeaderActive, imgui.ImVec4(1, 0, 0, 0.8))

        if imgui.ListBoxStr_arr('##list', selectedWave, ListWaves, #tableu8ListWaves) then -- listbox
            table.remove(tableu8ListWaves, selectedWave[0] + 1)
            ListWaves = imgui.new['const char*'][#tableu8ListWaves](tableu8ListWaves)
        end

        imgui.PopStyleColor(2)
        if imgui.IsItemHovered() then imgui.SetMouseCursor(7) end -- hand
        imgui.Hind(u8'������� ��� ��������.')
        imgui.PopItemWidth()

        imgui.EndChild()
    end

    if imgui.BeginPopup('AdditionalSettings') then -- �������� �������, ����������� ���� ��� ������� ������ "������"
        imgui.Text(u8'������� ���������:')
        imgui.SameLine()

        imgui.PushItemWidth(135)
        imgui.SetCursorPos(imgui.ImVec2(135, 6))
        imgui.InputText('##inputcommand', inputCommand, 32)
        imgui.Hind(u8"������� ���� ������� ������� ��� '/' ��� ������ �������� ����.")
        imgui.PopItemWidth()

        imgui.ToggleButton(u8'������ ����� � ���', checkboxChat, 222)
        if imgui.IsItemHovered() then
            imgui.BeginTooltip()
            imgui.Text(u8'��� ��������� ����� ��������� ������ �� ����� ������������� ����������� ���� ���\n��������� � ��� ������������, � � ������� ���� �������� ������ "������ � ���".')
            imgui.TextColored(imgui.ImVec4(1.0, 0.0, 0.0, 1.0 ), u8'��������: ������� ������ �� ����� ��������.')
            imgui.EndTooltip()
        end

        -- Style Editor
        imgui.Spacing()
        for i = 0, 1 do
            imgui.SameLine()
            if imgui.RadioButtonIntPtr(styles[i].name, radiobuttonStyle, i) then
                radiobuttonStyle[0] = i
                styles[i].func(imgui.ImVec4(Ini.FractionColor.r, Ini.FractionColor.g, Ini.FractionColor.b, 1))
            end
            if imgui.IsItemHovered() then imgui.SetMouseCursor(7) end -- hand
        end

        if radiobuttonStyle[0] == 1 then
            imgui.SetCursorPosX(47)
            imgui.PushItemWidth(20)
            if imgui.ColorEdit3(u8'���', colorEditStyleBg, imgui.ColorEditFlags.NoInputs) then
                styles[1].func()
            end
            if imgui.IsItemHovered() then imgui.SetMouseCursor(7) end -- hand
            imgui.SameLine()
            if imgui.ColorEdit3(u8'������', colorEditStyleButton, imgui.ColorEditFlags.NoInputs) then
                styles[1].func()
            end
            if imgui.IsItemHovered() then imgui.SetMouseCursor(7) end -- hand
            imgui.SameLine()
            if imgui.ColorEdit3(u8'��������', colorEditStyleElments, imgui.ColorEditFlags.NoInputs) then
                styles[1].func()
            end
            if imgui.IsItemHovered() then imgui.SetMouseCursor(7) end -- hand

            imgui.PopItemWidth()
        end
        imgui.EndPopup()
    end

    imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(5, 7))
    
    imgui.SetCursorPos(imgui.ImVec2(240, 212))
    if imgui.Button(u8'������', imgui.ImVec2(60, 30)) then
        imgui.OpenPopup('AdditionalSettings')
    end
    if imgui.IsItemHovered() then imgui.SetMouseCursor(7) end -- hand

    imgui.SameLine()
    if tonumber(string.format('%.3f', widgetFontSize[0])) ~= Ini.Settings.WidgetFontSize then
        if imgui.Button(u8'��������� � �������������', imgui.ImVec2(331, 30)) then
            script.reload(thisScript())
            Save()
        end
    else
        if imgui.Button(u8'��������� � �������', imgui.ImVec2(331, 30)) then
            SettingsMenu[0] = false
            Save()
        end
    end
    if imgui.IsItemHovered() then imgui.SetMouseCursor(7) end -- hand

    imgui.PopStyleVar()
    imgui.End()
end)

imgui.OnFrame(function() return MainMenu[0] and not isPauseMenuActive() and not sampIsScoreboardOpen() end, function(self) -- ������� ����
    if isKeyDown(32) and self.HideCursor == false then -- Space, ������ ������ ���� ����� ������
        self.HideCursor = true
    elseif not isKeyDown(32) then -- Space
        self.HideCursor = false
    end

    imgui.SetNextWindowPos(imgui.ImVec2(500, 500), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.Begin('Departament', MainMenu, imgui.WindowFlags.NoResize + imgui.WindowFlags.AlwaysAutoResize)
    imgui.PushItemWidth(150)
    imgui.PushStyleVarVec2(imgui.StyleVar.FramePadding, imgui.ImVec2(7, 4))
    imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(8, 8))
    
    imgui.Text(u8'������ ���:')
    imgui.SameLine()
    imgui.SetCursorPosX(100)
    if imgui.DepCombo('##tag1', selectedComboTag1, tableu8ModifiedListTags, false) then
        Ini.Settings.lastChannel1 = selectedComboTag1[0]
    end
    imgui.Text(u8'�����:')
    imgui.SameLine()
    imgui.SetCursorPosX(imgui.GetWindowWidth() - 100)
    if imgui.DepCombo('##Wavecombo', selectedComboWave, tableu8ModifiedListWaves, false) then
        Ini.Settings.lastWave = selectedComboWave[0]
    end

    imgui.Text(u8'������ ���:')
    imgui.SameLine()
    imgui.SetCursorPosX(100)
    if imgui.DepCombo('##tag2', selectedComboTag2, tableu8ModifiedListTags, false) then
        Ini.Settings.lastChannel2 = selectedComboTag2[0]
    end
    

    if checkboxChat[0] then
        if imgui.Button(u8'������ � ���', imgui.ImVec2(244, 26)) then
            sampSetChatInputEnabled(true) -- �������� ����
            sampSetChatInputText('/d '..GetCompletedForm())
        end
    else
        if imgui.ToggleButton(u8'���������������', checkboxEnab, 195) then
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

imgui.OnFrame(function() return Ini.Settings.Widget and isSampAvailable() and checkboxNotHideWidget[0]  or sampIsChatInputActive() or SettingsMenu[0] end, function() -- ������
    -- isSampAvailable() � ���������� ������ - ����������� �����, ���������� � ���������� "�� �������� ������"
    local colors = imgui.GetStyle().Colors
    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(colors[imgui.Col.WindowBg].x, colors[imgui.Col.WindowBg].y, colors[imgui.Col.WindowBg].z, widgetTransparency[0]))
    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0, 0, 0, 0))

    function GetChatPosition() -- one time
        local in1 = sampGetInputInfoPtr()
        local in1 = getStructElement(in1, 0x8, 4)
        local in2 = getStructElement(in1, 0x8, 4)
        local in3 = getStructElement(in1, 0xC, 4)

        local posX = in2 + 180
        local posY = in3 + 78

        return posX, posY
    end

    imgui.SetNextWindowPos(imgui.ImVec2(GetChatPosition()), imgui.Cond.FirstUseEver, imgui.ImVec2(1, 1))--imgui.Cond.FirstUseEver
    imgui.Begin('Widget', SettingsMenu, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.AlwaysAutoResize)


    imgui.PushFont(font_widget)
    if checkboxAlternativeFilling[0] then
        if imgui.DepCombo('##tag1', selectedComboTag1, tableu8ModifiedListTags, true) then
            Ini.Settings.lastChannel1 = selectedComboTag1[0]
        end
        imgui.Hind(u8'������ ���')

        imgui.SameLine()
        if imgui.DepCombo('##Wavecombo', selectedComboWave, tableu8ModifiedListWaves, true) then
            Ini.Settings.lastWave = selectedComboWave[0]
        end
        imgui.Hind(u8'�����')

        imgui.SameLine()
        if imgui.DepCombo('##tag2', selectedComboTag2, tableu8ModifiedListTags, true) then
            Ini.Settings.lastChannel2 = selectedComboTag2[0]
        end
        imgui.Hind(u8'������ ���')

        imgui.SameLine()
        if checkboxEnab[0] and not checkboxChat[0] then
            imgui.TextColored(imgui.ImVec4(0.0, 1.0, 0.0, 1.0), u8'��������')
        else
            imgui.TextColored(imgui.ImVec4(1.0, 0.0, 0.0, 1.0), u8'���������')
        end
        imgui.Hind(u8'��������/��������� � /'..Ini.Settings.Command)
    else
        if checkboxEnab[0] and not checkboxChat[0] then
            imgui.TextColored(imgui.ImVec4(0.0, 1.0, 0.0, 1.0), u8'��������')
        else
            imgui.TextColored(imgui.ImVec4(1.0, 0.0, 0.0, 1.0), u8'���������')
        end

        imgui.SameLine()
        imgui.Text(u8:encode(GetCompletedForm()))
    end
    imgui.PopFont()

    imgui.End()
    imgui.PopStyleColor(2)
end).HideCursor = true

function GetCompletedForm()
    local form = string.gsub(Ini.Settings.Form, '#1', Ini.Channels[Ini.Settings.lastChannel1])
    form = string.gsub(form, '%$', Ini.Waves[Ini.Settings.lastWave])
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
    if text:find('^/d%s+.+%s*') and not checkboxChat[0] and checkboxEnab[0] and not text:find(GetCompletedForm()) and Message ~= text and firstMessage ~= text and secondMessage ~= text then
        local dtext = text:match('^/d%s+(.+)%s*')
        Message = string.format('/d %s %s', GetCompletedForm(), dtext)

        if #Message:sub(3) > Ini.Settings.MaxText and Ini.Settings.LineBreak then -- ������� ������
            firstMessage = string.match(dtext:sub(1, Ini.Settings.MaxText), "(.*) (.*)") -- ������ (.*) - ����� � ������ �������, ������ - ������� ������ 
            
            if firstMessage == nil then
                return sampAddChatMessage('{cb2821}[Departament]:{FFFFFF} ������� ������ ��������� ������ ����� � ���������. ��������� ��� ������� ����� � /depset', -1)
            end

            secondMessage = string.match(string.sub(dtext, #firstMessage+2, 119), "(.*)") -- ������ ����� � ������� ��������

            -- formation
            firstMessage = string.format('/d %s %s ...', GetCompletedForm(), firstMessage)
            secondMessage = string.format('/d %s ... %s', GetCompletedForm(), secondMessage)

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

function Save() -- Save Settings
    Ini.Settings.Command = u8:decode(ffi.string(inputCommand))
    sampRegisterChatCommand(Ini.Settings.Command, function() MainMenu[0] = not MainMenu[0] end) -- ����������� ����� ������� �������� � input

    Ini.Settings.Chat = checkboxChat[0]
    Ini.Settings.LineBreak = checkboxline[0]
    
    Ini.Settings.Widget = checkboxWidg[0]
    Ini.Settings.NotHideWidget = checkboxNotHideWidget[0]
    Ini.Settings.WidgetTransparency = widgetTransparency[0]
    Ini.Settings.WidgetFontSize = tonumber(string.format('%.3f', widgetFontSize[0]))
    Ini.Settings.AlternativeFilling = checkboxAlternativeFilling[0]
    
    Ini.Settings.Style = radiobuttonStyle[0]
    Ini.CustomStyleBg.r, Ini.CustomStyleBg.g, Ini.CustomStyleBg.b = colorEditStyleBg[0], colorEditStyleBg[1], colorEditStyleBg[2]
    Ini.CustomStyleButton.r, Ini.CustomStyleButton.g, Ini.CustomStyleButton.b = colorEditStyleButton[0], colorEditStyleButton[1], colorEditStyleButton[2]
    Ini.CustomStyleElments.r, Ini.CustomStyleElments.g, Ini.CustomStyleElments.b = colorEditStyleElments[0], colorEditStyleElments[1], colorEditStyleElments[2]

    if #Ini.Channels ~= #tableu8ListTags or #Ini.Waves ~= #tableu8ListWaves then
        Ini.Settings.lastChannel1 = 1
        Ini.Settings.lastWave = 1
        Ini.Settings.lastChannel2 = 1
        
        selectedComboTag1[0] = Ini.Settings.lastChannel1
        selectedComboWave[0] = Ini.Settings.lastWave
        selectedComboTag2[0] = Ini.Settings.lastChannel2
    end

    -- List Saves
    Ini.Channels = {}
    tableu8ModifiedListTags = {}
    
    for _, value in ipairs(tableu8ListTags) do
        table.insert(Ini.Channels, u8:decode(ffi.string(value)))
        table.insert(tableu8ModifiedListTags, value)
    end

    if rawequal(next(tableu8ListTags), nil) then -- ���� ������ �����, ��
        sampAddChatMessage("{cb2821}[Departament]:{FFFFFF} ������ ��������� ������ ������!", -1)
        table.insert(Ini.Channels, u8'����')
        table.insert(tableu8ModifiedListTags, u8'����')
        table.insert(tableu8ListTags, u8'����')
        ListTags = imgui.new['const char*'][#tableu8ListTags](tableu8ListTags)
    end


    Ini.Waves = {}
    tableu8ModifiedListWaves = {}

    for _, value in ipairs(tableu8ListWaves) do
        table.insert(Ini.Waves, u8:decode(ffi.string(value)))
        table.insert(tableu8ModifiedListWaves, value)
    end

    if rawequal(next(tableu8ListWaves), nil) then -- ���� ������ �����, ��
        sampAddChatMessage("{cb2821}[Departament]:{FFFFFF} ������ ��������� ������ ������!", -1)
        table.insert(Ini.Waves, '-')
        table.insert(tableu8ModifiedListWaves, '-')
        table.insert(tableu8ListWaves, '-')
        ListWaves = imgui.new['const char*'][#tableu8ListWaves](tableu8ListWaves)
    end

    inicfg.save(Ini, "DepChannels")
end

-- mimgui functions
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
            colors[clr.CheckMark] =         imgui.ImVec4(StyleColor.x, StyleColor.y, StyleColor.z, 0.588)
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
            colors[clr.CheckMark] =         imgui.ImVec4(colorEditStyleButton[0], colorEditStyleButton[1], colorEditStyleButton[2], 1)
        end
    }
}

imgui.OnInitialize(function()
    Theme()
    font_widget = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', Ini.Settings.WidgetFontSize, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    imgui.Loaded = true
end)

function imgui.CenterText(text) -- ������������ ������
    imgui.SetCursorPosX(imgui.GetWindowWidth()/2-imgui.CalcTextSize(text).x/2)
    imgui.Text(text)
end

function imgui.Hind(text) -- ���������
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.Text(text)
        imgui.EndTooltip()
    end
end

LastActiveTime = {}
LastActive = {}
function imgui.ToggleButton(label, bool, distance) -- The basis is taken from https://github.com/AnWuPP/mimgui-addons
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
    
    if imgui.IsItemHovered() then
        imgui.SetMouseCursor(7) -- hand
    end
	return rBool
end

function imgui.DepCombo(label, v, array, widget)
    local rBool = false

    function max(list) -- return width widest line
        local boldLine = ''

        for _, value in ipairs(list) do
            boldLine = #value > #boldLine and value or boldLine
        end

        local result = imgui.CalcTextSize(boldLine).x
        result = imgui.CalcTextSize(boldLine).x < 30 and 30 or result

        return result
    end

    
    if not widget then imgui.SetCursorPosX(imgui.GetWindowWidth() - max(array) * 2.1 - 8) end
    imgui.PushItemWidth(max(array) * 2.1)

    if widget then
        imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0,0,0,0))
    end
    
    if imgui.BeginCombo(label, array[v[0]]) then
        for value, text in pairs(array) do
            if imgui.Selectable(text, array[0] == value) then
                v[0] = value
                rBool = true
            end
            if imgui.IsItemHovered() then imgui.SetMouseCursor(7) end -- hand
        end
        imgui.EndPopup()
    end
    if imgui.IsItemHovered() then imgui.SetMouseCursor(7) end -- hand
    
    imgui.PopItemWidth()
    if widget then imgui.PopStyleColor(2) end
    return rBool
end