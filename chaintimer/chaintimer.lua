--[[
* Ashita - Copyright (c) 2014 - 2017 Mattyg
*
* This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
* To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/ or send a letter to
* Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
*
* By using Ashita, you agree to the above license and its terms.
*
*      Attribution - You must give appropriate credit, provide a link to the license and indicate if changes were
*                    made. You must do so in any reasonable manner, but not in any way that suggests the licensor
*                    endorses you or your use.
*
*   Non-Commercial - You may not use the material (Ashita) for commercial purposes.
*
*   No-Derivatives - If you remix, transform, or build upon the material (Ashita), you may not distribute the
*                    modified material. You are, however, allowed to submit the modified works back to the original
*                    Ashita project in attempt to have it added to the original project.
*
* You may not apply legal terms or technological measures that legally restrict others
* from doing anything the license permits.
*
* No warranties are given.
]]--

_addon.author   = 'Mattyg';
_addon.name     = 'chaintimer';
_addon.version  = '0.9.3';

require 'common'
require 'logging'
require 'ffxi.targets'

----------------------------------------------------------------------------------------------------
-- Configurations
----------------------------------------------------------------------------------------------------
local default_config =
{
    textColor = 0xFFFFFFFF,
    clearColor = 0xFFFF0000,
    warningColor = 0xFFFFFF00,
    defaultColor = 0xFF33FF33,
    font =
    {
        family      = 'Arial',
        size        = 10,
        bgcolor     = 0x80333333,
        bgvisible   = true,
    },
    timers =
    {
        {10,50,40,30,20,10,10},
        {20,100,80,60,40,20,20},
        {30,150,120,90,60,30,30},
        {40,200,160,120,80,40,40},
        {50,250,200,150,100,50,50},
        {60,300,240,180,120,90,60},
        {75,360,300,240,165,105,60}
    }
    
};
local configs = default_config;
local chaintimer = { };

chaintimer.label_str = '__chaintimer_label';
chaintimer.timer_str = '__chaintimer_timer';
chaintimer.chain_label_str = '__chaintimer_chain_label';
chaintimer.chain_num_str = '__chaintimer_chain_num';
chaintimer.timer_val = 0;
chaintimer.charLevel = 0;
chaintimer.lastChain = 0;

----------------------------------------------------------------------------------------------------
-- func: print_help
-- desc: Displays a help block for proper command usage.
----------------------------------------------------------------------------------------------------
local function print_help(cmd, help)
    -- Print the invalid format header..
    print('\31\200[\31\05' .. _addon.name .. '\31\200]\30\01 ' .. '\30\68Invalid format for command:\30\02 ' .. cmd .. '\30\01'); 

    -- Loop and print the help commands..
    for k, v in pairs(help) do
        print('\31\200[\31\05' .. _addon.name .. '\31\200]\30\01 ' .. '\30\68Syntax:\30\02 ' .. v[1] .. '\30\71 ' .. v[2]);
    end
end

local function get_countdown(num)

    -- 61-75 - need to mod by level
    local ctimers;
    for _,timers in ipairs(configs.timers) do
        --print(_);
        if (chaintimer.charLevel <= timers[1]) then
            ctimers =  timers;
            break
        end
    end

    if (ctimers == nil) then
        return false;
    end

    chaintimer.lastChain = num;

    if (num > 5) then
        num = 5;
    end

    chaintimer.timer_val = os.time() + ctimers[num + 2];


  -- look into imgui
    -- imgui.SetNextWindowSize(200, 100, ImGuiSetCond_Always);
    -- if (imgui.Begin('ChainTimer') == false) then
    --     imgui.End();
    --     return;
    -- end
    
    -- imgui.Text('Chain Timer:');
    -- imgui.Separator();
    
    -- -- Set the progressbar color for health..
    -- imgui.PushStyleColor(ImGuiCol_PlotHistogram, 1.0, 0.61, 0.61, 0.6);
    -- imgui.Text('Time: ');
    -- imgui.SameLine();
    -- imgui.PushStyleColor(ImGuiCol_Text, 1.0, 1.0, 1.0, 1.0);
    -- imgui.Text('15'); -- countdown
    -- imgui.PopStyleColor(2);
    
    -- imgui.PushStyleColor(ImGuiCol_Text, 1.0, 1.0, 1.0, 1.0);
    -- imgui.ProgressBar(20 / 100, -1, 14);
    -- imgui.PopStyleColor(1);
    
    -- imgui.End();

end

-- ashita.register_event('load', function()
--     -- Load the configuration file..
--     -- configs = ashita.settings.load_merged(_addon.path .. '/settings/settings.json', configs);

-- end);

----------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Event called when the addon is being unloaded.
----------------------------------------------------------------------------------------------------
ashita.register_event('unload', function()
    -- Cleanup the font objects..

    AshitaCore:GetFontManager():Delete(chaintimer.label_str);
    AshitaCore:GetFontManager():Delete(chaintimer.timer_str);
    AshitaCore:GetFontManager():Delete(chaintimer.chain_label_str);
    AshitaCore:GetFontManager():Delete(chaintimer.chain_num_str);
end);

ashita.register_event('load', function()
    -- Load the configuration file..
    -- configs = ashita.settings.load_merged(_addon.path .. '/settings/settings.json', configs);

    -- Pull config info for positions
    chaintimer.window_x = AshitaCore:GetConfigurationManager():get_int32('boot_config', 'window_x', 800);
    chaintimer.window_y = AshitaCore:GetConfigurationManager():get_int32('boot_config', 'window_y', 800);
    chaintimer.menu_x   = AshitaCore:GetConfigurationManager():get_int32('boot_config', 'menu_x', 0);
    chaintimer.menu_y   = AshitaCore:GetConfigurationManager():get_int32('boot_config', 'menu_y', 0);

    -- Ensure the menu sizes have a valid resolution..
    if (chaintimer.menu_x <= 0) then
        chaintimer.menu_x = chaintimer.window_x;
    end
    if (chaintimer.menu_y <= 0) then
        chaintimer.menu_y = chaintimer.window_y;
    end

    -- Calculate the scaling based on the resolution..
    chaintimer.scale_x = chaintimer.window_x / chaintimer.menu_x;
    chaintimer.scale_y = chaintimer.window_y / chaintimer.menu_y;

    local posx = chaintimer.window_x - (600 * chaintimer.scale_x);
    local posy = chaintimer.window_y - (15 * chaintimer.scale_y);

    -- Create the text object
    local f = AshitaCore:GetFontManager():Create(chaintimer.label_str);
    f:SetColor(configs.textColor);
    f:SetFontFamily(configs.font.family);
    f:SetFontHeight(configs.font.size * chaintimer.scale_y);
    f:SetRightJustified(true);
    f:SetPositionX(posx);
    f:SetPositionY(posy);
    f:SetText('ChainTimer: ');
    f:SetLocked(true);
    f:SetVisibility(true);
    f:GetBackground():SetColor(configs.font.bgcolor);
    f:GetBackground():SetVisibility(configs.font.bgvisible);

    local d = AshitaCore:GetFontManager():Create(chaintimer.timer_str);
    d:SetColor(configs.defaultColor);
    d:SetFontFamily(configs.font.family);
    d:SetFontHeight(configs.font.size * chaintimer.scale_y);
    d:SetBold(true);
    d:SetRightJustified(false);
    d:SetPositionX(posx + (chaintimer.scale_x));
    d:SetPositionY(posy);
    d:SetText('-');
    d:SetLocked(true);
    d:SetVisibility(true);
    d:GetBackground():SetColor(configs.font.bgcolor);
    d:GetBackground():SetVisibility(configs.font.bgvisible);

    local c = AshitaCore:GetFontManager():Create(chaintimer.chain_label_str);
    c:SetColor(configs.textColor);
    c:SetFontFamily(configs.font.family);
    c:SetFontHeight(configs.font.size * chaintimer.scale_y);
    c:SetRightJustified(true);
    c:SetPositionX(posx + (70 * chaintimer.scale_x));
    c:SetPositionY(posy);
    c:SetText('Chain: ');
    c:SetLocked(true);
    c:SetVisibility(true);
    c:GetBackground():SetColor(configs.font.bgcolor);
    c:GetBackground():SetVisibility(configs.font.bgvisible);

    local b = AshitaCore:GetFontManager():Create(chaintimer.chain_num_str);
    b:SetColor(configs.defaultColor);
    b:SetFontFamily(configs.font.family);
    b:SetFontHeight(configs.font.size * chaintimer.scale_y);
    b:SetBold(true);
    b:SetRightJustified(false);
    b:SetPositionX(posx + (70 * chaintimer.scale_x));
    b:SetPositionY(posy);
    b:SetText('-');
    b:SetLocked(true);
    b:SetVisibility(true);
    b:GetBackground():SetColor(configs.font.bgcolor);
    b:GetBackground():SetVisibility(configs.font.bgvisible);

end);

---------------------------------------------------------------------------------------------------
-- func: Command
-- desc: Called when our addon receives a command.
---------------------------------------------------------------------------------------------------
ashita.register_event('command', function(cmd, nType)
    -- Skip commands that we should not handle..
    local args = cmd:args();
    if (args[1] ~= '/chaintimer') then
        return false;
    end

    return true;
end);

----------------------------------------------------------------------------------------------------
-- func: render
-- desc: Event called when the addon is being rendered.
----------------------------------------------------------------------------------------------------
-- ashita.register_event('render', function()

-- end);

---------------------------------------------------------------------------------------------------
-- func: incoming_text
-- desc: Called when our addon receives a chat line.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_text', function(mode, chat)
    
    if(mode == 131 or mode == 121) then
        if (string.match(chat, 'Limit chain') or string.match(chat, 'EXP chain')) then

            local i,j = string.find(
                chat,
                '%d+'
            );

            if(i == nil or j == nil) then
                get_countdown(0);
                return false;
            end

            --print(mode);

            local num = tonumber(string.sub(chat, i, j));

            if (num == nil) then
                num = 0;
            end

            get_countdown(num);

        elseif (string.match(chat, 'limit points') or string.match(chat, 'experience points')) then

            --print(mode);
            get_countdown(0);
        -- else
        --     print('nothing');
        end
    end

    return false;
end);

---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Called when our addon receives an incoming packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_packet', function(id, size, data)
    -- Zone In packet
    if (id == 0x000A) then

        chaintimer.charLevel = AshitaCore:GetDataManager():GetParty():GetMemberMainJobLevel(0);

    -- Character Sync packet
    elseif (id == 0x0067) then
        chaintimer.charLevel = AshitaCore:GetDataManager():GetParty():GetMemberMainJobLevel(0);
    end

    return false;
end);

----------------------------------------------------------------------------------------------------
-- func: render
-- desc: Event called when the addon is being rendered.
----------------------------------------------------------------------------------------------------
ashita.register_event('render', function()
    -- Calculate offset position starting points..

    local f = AshitaCore:GetFontManager():Get(chaintimer.timer_str);

    if(chaintimer.timer_val == 0) then
        f:SetText('-');
    else
        local countdown = chaintimer.timer_val - os.time();

        if (countdown < 0) then
             chaintimer.timer_val = 0;
        elseif (countdown < 5) then
            f:SetColor(configs.clearColor);
        elseif (countdown < 15) then
            f:SetColor(configs.warningColor);
        else
            f:SetColor(configs.defaultColor);
        end

        f:SetText(tostring(countdown));
    end

    local b = AshitaCore:GetFontManager():Get(chaintimer.chain_num_str);
    b:SetText(tostring(chaintimer.lastChain)); -- .. ' - Lvl. ' ..  chaintimer.charLevel);

    f:SetVisibility(true);
end);