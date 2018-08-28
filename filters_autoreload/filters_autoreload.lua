--[[
* Ashita - Copyright (c) 2014 - 2016 atom0s [atom0s@live.com]
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

_addon.author   = 'atom0s + mattyg';
_addon.name     = 'filters_autoreload';
_addon.version  = '3.0.0';

require 'common'

----------------------------------------------------------------------------------------------------
-- Variables
----------------------------------------------------------------------------------------------------
local filters       = { };
filters.pointer     = ashita.memory.findpattern('FFXiMain.dll', 0, 'C3C74004000000008B0D????????81C1', 0x0A, 0);
filters.pointer2    = 0;
filters.offset      = 0;
filters.current     = nil;

----------------------------------------------------------------------------------------------------
-- func: msg
-- desc: Prints out a message with the addon tag at the front.
----------------------------------------------------------------------------------------------------
function msg(s)
    local txt = '\31\200[\31\05' .. _addon.name .. '\31\200]\31\130 ' .. s;
    print(txt);
end

----------------------------------------------------------------------------------------------------
-- func: load
-- desc: Event called when the addon is being loaded.
----------------------------------------------------------------------------------------------------
ashita.register_event('load', function()
    -- Ensure the pointer was located..
    if (filters.pointer == 0) then
        print('[filters] (Error) Failed to find required pattern.');
        return;
    end

    -- Read the required pointer..
    local pointer = ashita.memory.read_uint32(filters.pointer);
    filters.pointer2 = pointer;

    -- Read the required offset..
    local offset = ashita.memory.read_uint32(filters.pointer + 6);
    filters.offset = offset;
end);

----------------------------------------------------------------------------------------------------
-- func: command
-- desc: Event called when a command was entered.
----------------------------------------------------------------------------------------------------
ashita.register_event('command', function(command, ntype)
    -- Get the command arguments..
    local args = command:args();
    if (args[1] ~= '/filters') then
        return false;
    end

    -- Loads a filter set from disk..
    if (#args >= 3 and args[2] == 'load') then
        local name = command:gsub('([\/%w]+) ', '', 2):trim();
        if (name:endswith('.txt') == false) then
            name = name .. '.txt';
        end

        -- Ensure the file exists..
        if (ashita.file.file_exists(_addon.path .. '/sets/' .. name) == false) then
            msg('Cannot load filter list, file does not exist: \31\04' .. name);
            return true;
        end

        -- Load the filter set..
        local f = ashita.settings.load(_addon.path .. '/sets/' .. name);
        if (type(f) ~= 'table' or type(f.filters) ~= 'table' or #f.filters == 0) then
            msg('Cannot load filter list, file is not value: \31\04' .. name);
            return true;
        end

        -- Write the filters to memory..
        local pointer = ashita.memory.read_uint32(filters.pointer2);
        filters.current = f.filters;

        -- Send the filter update packet..
        local packet = 
        {
            0xB4, 0x0C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x01, 0x40, 0x02, 0x00, 0x00, 0x00 
        };

        -- Set the packet filter info..
        for x = 1, #filters.current do
            packet[4 + x] = filters.current[x];
        end
        AddIncomingPacket(0xB4, packet);

        msg('Loaded filter set: \31\04' .. name);
        return true;
    end

    -- Saves a filter to the disk..
    if (#args >= 3 and args[2] == 'save') then
        if (filters.pointer2 == 0) then
            print('[filters] (Error) Required pointer is invalid, cannot save.');
            return true;
        end

        -- Get the file name..
        local name = command:gsub('([\/%w]+) ', '', 2):trim();
        if (name:endswith('.txt') == false) then
            name = name .. '.txt';
        end

        -- Read the current chat filter data..
        local pointer = ashita.memory.read_uint32(filters.pointer2); --
        local data = ashita.memory.read_array(pointer + filters.offset, 12);
        
        -- Save the filter data to the given file..
        ashita.file.create_dir(_addon.path .. '/sets/');
        ashita.settings.save(_addon.path .. '/sets/' .. name, {
            filters = data
        });

        msg('Saved filter set: \31\04' .. name);
        return true;
    end

    return true;
end);

    
---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Called when our addon receives an incoming packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_packet', function(id, size, data)
    if (id == 0xB4 and filters.current ~= nil and #filters.current > 0) then
        local realpacket = data:totable();

        -- Send the filter update packet..
        local packet = 
        {
            0xB4, 0x0C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x01, 0x40, 0x02, 0x00, 0x00, 0x00 
        };

        -- Set the packet filter info..
        for x = 1, #filters.current do
            packet[4 + x] = filters.current[x];
        end

        -- Set the name flag(?) field back to regular packet value..
        packet[0x05] = realpacket[0x05];
        packet[0x13] = realpacket[0x13];
        packet[0x14] = realpacket[0x14];
        packet[0x15] = realpacket[0x15];

        return packet;
     -- Zone In packet
    elseif (id == 0x000A) then
        if (filters.current ~= nil and #filters.current > 0) then
            -- Send the filter update packet..
            local packet = 
            {
                0xB4, 0x0C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x01, 0x40, 0x02, 0x00, 0x00, 0x00 
            };

            -- Set the packet filter info..
            for x = 1, #filters.current do
                packet[4 + x] = filters.current[x];
            end
            AddIncomingPacket(0xB4, packet);

            msg('ReLoaded filter set.');
        end
    end

    return false;
end);