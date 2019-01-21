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
_addon.name     = 'yellfilter';
_addon.version  = '1.0.0';

require 'common'

----------------------------------------------------------------------------------------------------
-- Variables
----------------------------------------------------------------------------------------------------
local default_config =
{
    disable = false,
    filters = {
        "WTS",
        "WTB",
        "LFG",
        "LFP",
        "LFM"
    },
    filters_regex = {
        "%d+K"
    }
};
local configs = default_config;
----------------------------------------------------------------------------------------------------
-- func: msg
-- desc: Prints out a message with the addon tag at the front.
----------------------------------------------------------------------------------------------------
function msg(s)
    local txt = '\31\200[\31\05' .. _addon.name .. '\31\200]\31\130 ' .. s;
    print(txt)
end

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

----------------------------------------------------------------------------------------------------
-- func: load
-- desc: Event called when the addon is being loaded.
----------------------------------------------------------------------------------------------------
ashita.register_event('load', function()
    -- Load the configuration file..
    configs = ashita.settings.load_merged(_addon.path .. '/settings/settings.json', configs);
end);

----------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Event called when the addon is being unloaded.
----------------------------------------------------------------------------------------------------
ashita.register_event('unload', function()
    -- Save the configuration file..
    ashita.settings.save(_addon.path .. '/settings/settings.json', configs);
end);

---------------------------------------------------------------------------------------------------
-- func: incoming_text
-- desc: Called when our addon receives a chat line.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_text', function(mode, chat)

    chat = ParseAutoTranslate(chat, false)
    -- print('mode: ' .. mode)
    -- print('chat: ' .. chat)

    -- yell mode == 11 (mode 3 is your own yells, not filtering those)
    -- if (mode == 11 or mode == 3) then
    if (mode == 11) then
        if (configs.disable) then
            return true
        end

        local allowed = false
        for _,filter in ipairs(configs.filters) do
            if (string.contains(chat, filter)) then
                allowed = true
                break
            end
        end

        for _,filter in ipairs(configs.filters_regex) do
            if (string.find(chat, filter)) then
                allowed = true
                break
            end
        end

        -- if(allowed == false) then
        --     print('filtered : ' .. chat)
        -- end

        return not(allowed)
    end

    return false
end);

---------------------------------------------------------------------------------------------------
-- func: Command
-- desc: Called when our addon receives a command.
---------------------------------------------------------------------------------------------------
ashita.register_event('command', function(cmd, nType)
    -- Skip commands that we should not handle..
    local args = cmd:args();
    if (args[1] ~= '/yellfilter') then
        return false;
    end

    if (args[2] == 'disable') then

        configs.disable = true;
        return true;
    end

    if (args[2] == 'enable') then

        configs.disable = false
        return true;
    end

    if (args[2] == 'add') then
        local rest = {}
        for i=3,#args do
            rest[#rest+1] = args[i]
        end
        local filter = table.concat(rest, " ")

        configs.filters[#configs.filters+1] = filter
        return true;
    end

    -- Prints the addon help..
    print_help('/yellfilter', {
        { '/yellfilter disable', '- Disables yell' },
        { '/yellfilter enable', '- Enables yell' },
        { '/yellfilter add {filter}', '- Adds a {filter} that will include yells that include it' }
    });
    return true;
end);