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
_addon.name     = 'tick';
_addon.version  = '1.1.0';

require 'common'

----------------------------------------------------------------------------------------------------
-- Configurations
----------------------------------------------------------------------------------------------------
local default_config =
{
    tickColor = 0xFF00FF00,
    warningColor = 0xFFFFFF00,
    defaultColor = 0xFFFFFFFF,
    font =
    {
        family      = 'Arial',
        size        = 8,
        bgcolor     = 0x80333333,
        bgvisible   = true,
    }
};
local configs = default_config;
local tick = { };

tick.backdrop_str = '__tick_backdrop';
tick.enabled = false;
tick.timer_str = '__tick_timer';
tick.timer_val = 0;
tick.mp = 0;
tick.mp_delta = 0;
tick.mp_delta_str = '__tick_mp_delta';
tick.refresh_set_name = nil;
tick.mp_refresh = 0;
tick.mp_refresh_str = '__tick_mp_refresh';
tick.mp_refresh_count = 0;
tick.healing = 0;
tick.init = false;
tick.id = 0;
tick.targid = 0;
tick.sync = 0;

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

local function assign_refresh_items()
    -- make collection of refresh items, by slot, name, and level
    -- and equip based on that logic.
    local level = AshitaCore:GetDataManager():GetParty():GetMemberMainJobLevel(0);
    if (level > 58) then
        tick.refresh_set_name = 'Refresh'; -- TODO: This could be a setting.
    else
        tick.refresh_set_name = nil;
    end
end

ashita.register_event('load', function()
    -- Load the configuration file..
    -- configs = ashita.settings.load_merged(_addon.path .. '/settings/settings.json', configs);

    -- Pull config info for positions
    tick.window_x = AshitaCore:GetConfigurationManager():get_int32('boot_config', 'window_x', 800);
    tick.window_y = AshitaCore:GetConfigurationManager():get_int32('boot_config', 'window_y', 800);
    tick.menu_x   = AshitaCore:GetConfigurationManager():get_int32('boot_config', 'menu_x', 0);
    tick.menu_y   = AshitaCore:GetConfigurationManager():get_int32('boot_config', 'menu_y', 0);

    -- Ensure the menu sizes have a valid resolution..
    if (tick.menu_x <= 0) then
        tick.menu_x = tick.window_x;
    end
    if (tick.menu_y <= 0) then
        tick.menu_y = tick.window_y;
    end

    -- Calculate the scaling based on the resolution..
    tick.scale_x = tick.window_x / tick.menu_x;
    tick.scale_y = tick.window_y / tick.menu_y;

    local timerx = tick.window_x - (110 * tick.scale_x);
    local posy = tick.window_y - (15 * tick.scale_y);

    local deltax = tick.window_x - (80 * tick.scale_x);

    -- Create the text object
    local f = AshitaCore:GetFontManager():Create(tick.timer_str);
    f:SetColor(configs.defaultColor);
    f:SetFontFamily(configs.font.family);
    f:SetFontHeight(configs.font.size * tick.scale_y);
    f:SetBold(true);
    f:SetRightJustified(true);
    f:SetPositionX(timerx);
    f:SetPositionY(posy);
    f:SetText('-');
    f:SetLocked(true);
    f:SetVisibility(false);
    f:GetBackground():SetColor(configs.font.bgcolor);
    f:GetBackground():SetVisibility(configs.font.bgvisible);

    local d = AshitaCore:GetFontManager():Create(tick.mp_delta_str);
    d:SetColor(configs.tickColor);
    d:SetFontFamily(configs.font.family);
    d:SetFontHeight(configs.font.size * tick.scale_y);
    d:SetBold(true);
    d:SetRightJustified(true);
    d:SetPositionX(deltax);
    d:SetPositionY(posy);
    d:SetText(tostring(tick.mp_delta));
    d:SetLocked(true);
    d:SetVisibility(false);
    d:GetBackground():SetColor(configs.font.bgcolor);
    d:GetBackground():SetVisibility(configs.font.bgvisible);

    local r = AshitaCore:GetFontManager():Create(tick.mp_refresh_str);
    r:SetColor(configs.tickColor);
    r:SetFontFamily(configs.font.family);
    r:SetFontHeight(configs.font.size * tick.scale_y);
    r:SetBold(true);
    r:SetRightJustified(true);
    r:SetPositionX(deltax + (20 * tick.scale_x));
    r:SetPositionY(posy);
    r:SetText(tostring(tick.mp_refresh));
    r:SetLocked(true);
    r:SetVisibility(false);
    r:GetBackground():SetColor(configs.font.bgcolor);
    r:GetBackground():SetVisibility(configs.font.bgvisible);

end);

----------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Event called when the addon is being unloaded.
----------------------------------------------------------------------------------------------------
ashita.register_event('unload', function()
    -- Cleanup the font objects..
    AshitaCore:GetFontManager():Delete(tick.timer_str);
    AshitaCore:GetFontManager():Delete(tick.mp_delta_str);
    AshitaCore:GetFontManager():Delete(tick.mp_refresh_str);
end);

---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Called when our addon receives an incoming packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_packet', function(id, size, data)
    -- TODO: Somehow if taking dmg

    -- Zone In packet
    if (id == 0x000A) then
        tick.id = struct.unpack('I', data, 0x04 + 1);
        tick.targid = struct.unpack('H', data, 0x08 + 1);
        tick.max_mp = struct.unpack('i', data, 0xEC + 1);

        if (tick.max_mp > 25) then
            tick.enabled = true;
        else
            tick.enabled = false;
            -- redraw
            AshitaCore:GetFontManager():Get(tick.mp_delta_str):SetVisibility(false);
            AshitaCore:GetFontManager():Get(tick.mp_refresh_str):SetVisibility(false);
            AshitaCore:GetFontManager():Get(tick.timer_str):SetVisibility(false);
        end

        local playerName = struct.unpack('s', data, 0x84 + 1);

        assign_refresh_items();

        -- print('zone:')
        -- print('id->' .. tick.id);
        -- print('targid->' .. tick.targid);
    -- Character Sync packet
    elseif (id == 0x0067) then
        if (not tick.enabled) then
            return false;
        end
        
        --local a = struct.unpack('H', data, 0x00 + 1); -- 5223

        --local sync = struct.unpack('i', data, 0x10 +1);
        local tid = struct.unpack('I', data, 0x08 + 1);
        local targid = struct.unpack('H', data, 0x06 + 1);

        -- print('sync:');
        -- print('id->' .. tid);
        -- print('targid->' .. targid);
        -- print('sync->' .. sync);
        -- print('a->' .. a);

        if (tick.id ~= tid or tick.targid ~= targid) then
            if (tick.id == 0 or tick.targid == 0) then
                print('[tick] Cannot identify char id, zoning required for addon to work properly.');
            end
            return false;
        end

        assign_refresh_items();

        -- TODO: see if same for multiple char
        -- toggle healing timer
        --if (a == 5223) then
            -- print('toggling');
            if (tick.healing == 1) then
                if (tick.timer_val == 0) then
                    tick.timer_val = os.time() + 20;
                    tick.mp_refresh_count = 0;
                    if (tick.refresh_set_name ~= nil) then
                        AshitaCore:GetChatManager():QueueCommand('/ac set ' .. tick.refresh_set_name, 1);
                        AshitaCore:GetChatManager():QueueCommand('/ac disable', 1);
                    end
                end
            else
                -- print('healing stopped');
                local f = AshitaCore:GetFontManager():Get(tick.timer_str);
                f:SetColor(configs.defaultColor);
                tick.timer_val = 0;
            end
        --end
    -- Character Health packet
    elseif (id == 0x00DF) then
        if (not tick.enabled) then
            return false;
        end
-- TODO: look into auto reset issue.. more logic
        if (tick.healing == 0 and tick.timer_val ~= 0 and (tick.timer_val - os.time() < -5)) then
            AshitaCore:GetChatManager():QueueCommand('/tick reset', 1);
        end

        local tid = struct.unpack('I', data, 0x04 + 1);
        --local hp = struct.unpack('i', data, 0x08 + 1);
        local mp = struct.unpack('i', data, 0x0C + 1);
        local targid = struct.unpack('H', data, 0x14 + 1)

        -- print('health:')
        -- print('id->' .. tid);
        -- print('targid->' .. targid);

        if (tick.id ~= tid or tick.targid ~= targid) then
            if (tick.id == 0 or tick.targid == 0) then
                print('[tick] Cannot identify char id, zoning required for addon to work properly.');
            end
            return false;
        end

        if (not tick.init) then
            local party = AshitaCore:GetDataManager():GetParty();
            tick.mp = AshitaCore:GetDataManager():GetParty():GetMemberCurrentMP(0);
            tick.init = true;
        end

        local delta = mp - tick.mp;
        
        tick.mp = mp;

        if (delta > 11 or delta < 0) then
            tick.mp_delta = delta;
            if (tick.healing == 1 and tick.timer_val < os.time() + 10) then
                tick.timer_val = os.time() + 10;

                if (tick.refresh_set_name ~= nil) then
                    AshitaCore:GetChatManager():QueueCommand('/ac set ' .. tick.refresh_set_name, 1);
                    AshitaCore:GetChatManager():QueueCommand('/ac disable', 1);
                end
            end
        elseif (delta > 0) then
            tick.mp_refresh = delta;
            if (tick.healing == 1) then
                if (tick.timer_val ~= 0) then
                    tick.mp_refresh_count = tick.mp_refresh_count + 1;

                    if (tick.refresh_set_name ~= nil and (tick.timer_val - os.time()) < 4) then
                        AshitaCore:GetChatManager():QueueCommand('/ac enable', 1);
                    end
                end
            end
        end

        local d = AshitaCore:GetFontManager():Get(tick.mp_delta_str);
        d:SetText(tostring(tick.mp_delta));
        d:SetVisibility(tick.enabled);

        local r = AshitaCore:GetFontManager():Get(tick.mp_refresh_str);
        r:SetText(tostring(tick.mp_refresh));
        r:SetVisibility(tick.enabled);
    end

    -- if (id == 0x0037) then
    --     local x = struct.unpack('L', data, 0x4C +1);

    --     print(x);
    --     print(string.format("%x", x));
    -- end
    return false;
end);

ashita.register_event('outgoing_packet', function(id, size, data)
    if (not tick.enabled) then
        return false;
    end
    if (id == 0x00E8) then
        -- local d = struct.unpack('h', data, 0x00);
        -- local e = struct.unpack('h', data, 0x02);
        -- local f = struct.unpack('h', data, 0x04);

        -- print(string.format("%x", d));
        -- print(string.format("%x", e));
        -- print(string.format("%x", f));

        if (tick.healing == 0 and tick.timer_val == 0) then
            -- print('starting healing');
            tick.healing = 1;
        end

        if (tick.healing == 1 and tick.timer_val ~= 0) then
            -- print('stopping healing');
            if (tick.refresh_set_name ~= nil) then
                AshitaCore:GetChatManager():QueueCommand('/ac enable', 1);
            end

            print('[tick] RefreshCount: ' .. tick.mp_refresh_count);
            tick.healing = 0;
        end
    end
    return false;
end);

---------------------------------------------------------------------------------------------------
-- func: Command
-- desc: Called when our addon receives a command.
---------------------------------------------------------------------------------------------------
ashita.register_event('command', function(cmd, nType)
    -- Skip commands that we should not handle..
    local args = cmd:args();
    if (args[1] ~= '/tick') then
        return false;
    end

    if (args[2] == 'reset') then
        tick.timer_val = 0;
        tick.healing = 0;
        local f = AshitaCore:GetFontManager():Get(tick.timer_str);
        f:SetColor(configs.defaultColor);

        if (tick.refresh_set_name ~= nil) then
            AshitaCore:GetChatManager():QueueCommand('/ac enable', 1);
        end

        return true;
    end

    -- Prints the addon help..
    print_help('/tick', {
        { '/tick reset', '- Resets the tick timer (should display "-" when not resting)' }
    });
    return true;
end);

----------------------------------------------------------------------------------------------------
-- func: render
-- desc: Event called when the addon is being rendered.
----------------------------------------------------------------------------------------------------
ashita.register_event('render', function()
    if (tick.enabled) then
        local f = AshitaCore:GetFontManager():Get(tick.timer_str);

        if(tick.timer_val == 0) then
            f:SetText('-');
        else
            local countdown = tick.timer_val - os.time();

            if (countdown < 1) then
                f:SetColor(configs.tickColor);
            elseif (countdown < 4) then
                f:SetColor(configs.warningColor);
            else
                f:SetColor(configs.defaultColor);
            end

            f:SetText(tostring(countdown));
        end

        f:SetVisibility(true);
    end
end);