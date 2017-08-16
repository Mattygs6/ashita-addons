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
_addon.name     = 'attendance';
_addon.version  = '1.0.0';

require 'common'
require 'logging'
require 'ffxi.targets'

----------------------------------------------------------------------------------------------------
-- Configurations
----------------------------------------------------------------------------------------------------
local default_config =
{
};
local configs = default_config;

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

-- ashita.register_event('load', function()
--     -- Load the configuration file..
--     -- configs = ashita.settings.load_merged(_addon.path .. '/settings/settings.json', configs);

-- end);

----------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Event called when the addon is being unloaded.
----------------------------------------------------------------------------------------------------
-- ashita.register_event('unload', function()
--     -- Cleanup the font objects..

-- end);

---------------------------------------------------------------------------------------------------
-- func: Command
-- desc: Called when our addon receives a command.
---------------------------------------------------------------------------------------------------
ashita.register_event('command', function(cmd, nType)
    -- Skip commands that we should not handle..
    local args = cmd:args();
    if (args[1] ~= '/attendance') then
        return false;
    end

    local party = AshitaCore:GetDataManager():GetParty();
    local zone = party:GetMemberZone(0);
    local target = ashita.ffxi.targets.get_target('t');
    local targetName = 'HNM';
    if (target ~= nil) then
        targetName = target.Name;
    end

    ashita.logging.normal('Zone', tostring(zone));
    ashita.logging.normal('Boss', targetName);

    print('[Attendance] -> Zone: ' .. tostring(zone));
    print('[Attendance] -> Boss: ' .. targetName);

    -- Handle the players local party..
    for x = 0, 17 do
        local playerName = party:GetMemberName(x);
        if(zone == party:GetMemberZone(x)) then
            ashita.logging.normal('Attendance', playerName);
            print('[Attendance] -> ' .. playerName);
        else
            if (playerName ~= nil and playerName ~= '') then
                ashita.logging.normal('Attendance: Wrong Zone', playerName .. ' -> ZoneId = ' .. tostring(party:GetMemberZone(x)));
                print('[Attendance] -> Wrong Zone: ' .. playerName .. ' -> ZoneId = ' .. tostring(party:GetMemberZone(x)));
            end
        end
    end

    return true;
end);

----------------------------------------------------------------------------------------------------
-- func: render
-- desc: Event called when the addon is being rendered.
----------------------------------------------------------------------------------------------------
-- ashita.register_event('render', function()

-- end);



-- matty, this is taken from logs.lua at0m0s made for outputting chat for v3
---------------------------------------------------------------------------------------------------
-- func: incoming_text
-- desc: Event called when the addon is asked to handle an incoming chat line.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_text', function(mode, message, modifiedmode, modifiedmessage, blocked)
    -- Ignore invalid data..
    if (name == nil or string.len(message) == 0) then
        return false;
    end

    -- Create the file name and ensure the path to it exists..
    local d = os.date('*t');
    local n = string.format('%s_%.2u.%.2u.%.4u.log', name, d.month, d.day, d.year);
    local p = string.format('%s/%s/', AshitaCore:GetAshitaInstallPath(), 'chatlogs');
    if (not ashita.file.dir_exists(p)) then
        ashita.file.create_dir(p);
    end

    -- Append the new chat line to the file..
    local f = io.open(string.format('%s/%s', p, n), 'a');
    if (f ~= nil) then
        local t = os.date(timestamp, os.time());
        f:write(t .. ' ' .. clean_str(message) .. '\n');
        f:close();
    end
    
    return false;
end);
