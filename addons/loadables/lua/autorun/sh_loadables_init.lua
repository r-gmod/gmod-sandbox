/**
	Loadables
	Created by Potatofactory <mrpotatofactory@gmail.com>

	For public use
**/

local funcFormat    = string.format
local include       = include
local AddCSLuaFile  = SERVER and AddCSLuaFile or nil

local LOADABLE_SERVER = 1
local LOADABLE_CLIENT = 2
local LOADABLE_SHARED = 3

local tblRealmActions = SERVER and
{
    [LOADABLE_SERVER] = function (strScript)
        include (funcFormat (
            "loadables/server/%s",
            strScript
        ))
    end,
    [LOADABLE_CLIENT] = function (strScript)
        AddCSLuaFile (funcFormat (
            "loadables/client/%s",
            strScript
        ))
    end,
    [LOADABLE_SHARED] = function (strScript)
        local strFullPath = funcFormat (
            "loadables/%s",
            strScript
        )

        include         (strFullPath)
        AddCSLuaFile    (strFullPath)
    end
}

or 

{
    [LOADABLE_SERVER] = function (strScript)
        ErrorNoHalt (funcFormat (
            "[loadables] Client has server-side script: %s",
            strScript
        ))
    end,
    [LOADABLE_CLIENT] = function (strScript)
        include (funcFormat (
            "loadables/client/%s",
            strScript
        ))
    end,
    [LOADABLE_SHARED] = function (strScript)
        include (funcFormat (
            "loadables/%s",
            strScript
        ))
    end 
}

if SERVER then
    AddCSLuaFile ()
end

_G.loadables = {}

function loadables:RefreshIndex ()
    loadables.index = {
        {file.Find ("loadables/server/*",  "LUA")},
        {file.Find ("loadables/client/*",  "LUA")},
        {file.Find ("loadables/*",         "LUA")}
    }

    return loadables.index
end

function loadables:ReloadAll ()
    local tblIndex = loadables:RefreshIndex ()

    for iteration = 1, #tblIndex do
        local tblScripts = tblIndex [iteration][1]
        for iteration_script = 1, #tblScripts do
            tblRealmActions [iteration] (tblScripts [iteration_script])
        end
    end
end

////////////////////////////////////////
//   Do not touch the line below.     //
////////////////////////////////////////
        loadables:ReloadAll ()
////////////////////////////////////////
