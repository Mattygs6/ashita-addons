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
_addon.name     = 'dropwatch';
_addon.version  = '1.0.0';

require 'common'

local dropwatch = {
    data = {},
    status = 'running'
}

local function round(num, idp)
    local mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
end

local function getExistingDataKey(mob_name)
    for key, existing_kill_data in pairs(dropwatch.data) do
        if existing_kill_data.name == mob_name then
            return key
        end
    end

    return false
end

dropwatch.handle_incoming_message = function (mode, text)

    if text == '' or dropwatch.status == 'paused' then
        return false
    end

    if mode == 36 or mode == 121 then
        local kill_confirmation_regex = ' defeats the (.*)%.'
        local killed_mob_name = string.match(text, kill_confirmation_regex)
        local key

        if killed_mob_name then
            key = getExistingDataKey(killed_mob_name)
            if key == false then
                table.insert(dropwatch.data, {
                    name = killed_mob_name,
                    kills = 1,
                    drops = {}
                })
            else
                dropwatch.data[key].kills = dropwatch.data[key].kills + 1
            end
        end

        local drop_confirmation_regex = 'You find an? (.*) on the (.*)%.'
        local drop_name, drop_mob_name = string.match(text, drop_confirmation_regex)
        if drop_name and drop_mob_name then
            key = getExistingDataKey(drop_mob_name)
            if key == false then
                dropwatch.data[key].drops[drop_name] = 0
            else
                if dropwatch.data[key].drops[drop_name] then
                    dropwatch.data[key].drops[drop_name] = dropwatch.data[key].drops[drop_name] + 1
                else
                    dropwatch.data[key].drops[drop_name] = 1
                end
            end
        end
    end
    return false
end

dropwatch.handle_addon_command = function (cmd)

    local args = cmd:args()
    if (args[1] ~= '/dropwatch') then
        return false
    end

    local command = args[2]
    local action, kill_plural

    if command ~= nil then
        action = command:lower()
    end

    if action == 'report' then
        print('[dropwatch report]')
        for _, monster_data in pairs(dropwatch.data) do
            if monster_data.kills > 1 then
                kill_plural = 's'
            else
                kill_plural = ''
            end
            print(monster_data.name .. ': ' .. monster_data.kills .. ' kill' .. kill_plural)
            for drop_name, drop_amount in pairs(monster_data.drops) do
                print(' > ' .. drop_name .. ': ' .. drop_amount .. '/' .. monster_data.kills .. ' (' .. round(drop_amount / monster_data.kills * 100) .. '%)')
            end
        end
        return true
    end

    if action == 'reset' then
        dropwatch.data = {}
        return true
    end

    if action == 'pause' then
        dropwatch.pause()
        return true
    end

    if action == 'resume' then
        dropwatch.resume()
        return true
    end

    if action == 'status' then
        print(dropwatch.status)
        return true
    end

    -- Prints the addon help..
    print_help('/dropwatch', {
        { '/dropwatch report', '- Reports data.' },
        { '/dropwatch reset', '- Resets data.' },
        { '/dropwatch pause', '- Pauses collection of data.' },
        { '/dropwatch resume', '- Resumes collection of data.' },
        { '/dropwatch status', '- Prints the status of the addon [running,paused]' }
    });

end

dropwatch.pause = function ()
    dropwatch.status = 'paused'
end

dropwatch.resume = function ()
    dropwatch.status = 'running'
end

-- ashita.register_event('incoming_packet', function(id, size, data)
--     if (id == 0x000A) then
--         dropwatch.playerName = struct.unpack('s', data, 0x84 + 1);
--     end
--     return false;
-- end);
ashita.register_event('command', dropwatch.handle_addon_command);
ashita.register_event('incoming_text', dropwatch.handle_incoming_message);