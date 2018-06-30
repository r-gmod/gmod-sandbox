hook.Add ("Think","luadev_cmdsinit",function()
    hook.Remove ("Think", "luadev_cmdsinit")
    local function add (cmd, callback)
        if SERVER and aowl and aowl.AddCommand then
            aowl.AddCommand(cmd,function(ply,script,param_a,...)
                
                local a,b
                
                easylua.End() -- nesting not supported

                local ret,why = callback (ply, script, param_a, ...)
                if not ret then 
                    if why==false then
                        a,b = false,why or aowl.TargetNotFound(param_a or "notarget") or "H"
                    elseif isstring(why) then
                        ply:ChatPrint("FAILED: "..tostring(why))
                        a,b= false,tostring(why)
                    end
                end
            
                easylua.Start(ply)
                return a,b
                
            end, cmd=="lm" and "players" or "developers")
        elseif SERVER and sneeze and sneeze.AddOrdinance then
            sneeze.AddOrdinance (
                {
                    cmd,
                    {},
                    {"admin", "development", "network"}
                },
                function (strLine, ply)

                    local a, b
                    
                    easylua.End () -- nesting not supported
                    
                    local ret, why = callback (ply, strLine)
                    if not ret then
                        if isstring (why) then
                            -- ply:ChatPrint ("FAILED: " .. tostring (why))
                            ply:Notify (("Runtime Error: %s"):format (why), NOTIFY_ERROR, 5)
                            a, b = false, tostring (why)
                        end
                    end
                
                    easylua.Start (ply)
                    return a, b
                end
            )
        elseif ulx then
            objCommand = ulx.command (
                "Development",
                "ulx " .. cmd,
                function (calling_ply, strScript)
                    easylua.End () -- nesting not supported

                    local ret, strError = callback (calling_ply, strScript)
                    if not ret and isstring (strError) then
                        calling_ply:Notify (("Runtime Error: %s"):format (strError), NOTIFY_ERROR, 5)
                        calling_ply:Notify (("%s"):format (strScript), NOTIFY_ERROR, 5)
                    end

                    easylua.Start (calling_ply)
                end,
                "!" .. cmd
            )
            objCommand:addParam         ({
                type = ULib.cmds.StringArg,
                hint="command",
                ULib.cmds.takeRestOfLine
            })
            objCommand:defaultAccess    (ULib.ACCESS_SUPERADMIN)
        end
    end

    local function X (ply, i) return luadev.GetPlayerIdentifier (ply, "cmd:" .. i) end

    add("l", function (ply, line, target)
        if not line or line == "" then return false,"invalid script" end
        if luadev.ValidScript then local valid, err = luadev.ValidScript (line, "l") if not valid then return false,err end end
        return luadev.RunOnServer (line, X (ply,"l"), {ply = ply}) 
    end)

    add("ls", function (ply, line, target)
        if not line or line=="" then return false,"invalid script" end
        if luadev.ValidScript then local valid, err = luadev.ValidScript (line, "ls") if not valid then return false,err end end
        return luadev.RunOnShared (line, X (ply,"ls"), {ply = ply})
    end)

    add("lc", function(ply, line, target)
        if not line or line == "" then return end
        if luadev.ValidScript then local valid, err = luadev.ValidScript (line, "lc") if not valid then return false,err end end
        return luadev.RunOnClients (line,  X (ply,"lc"), {ply = ply})
    end)

    add("lsc", function(ply, line, target)
        local ent = easylua.FindEntity(target)
        if ent:IsPlayer() then
            local script = string.sub (line, string.find (line, target, 1, true) + #target + 1)
            if luadev.ValidScript then local valid, err = luadev.ValidScript (script, "lsc") if not valid then return false,err end end
            return luadev.RunOnClient (script,  ent, X (ply,"lsc"), {ply = ply}) 
        else
            return false
        end
    end)
    local sv_allowcslua = GetConVar"sv_allowcslua"
    add("lm", function(ply, line, target)
        if not line or line=="" then return end
        if luadev.ValidScript then local valid,err = luadev.ValidScript(line,"lm") if not valid then return false,err end end
        
        if not ply:IsAdmin() and not sv_allowcslua:GetBool() then return false,"sv_allowcslua is 0" end
        
        luadev.RunOnClient(line, ply,X(ply,"lm"), {ply=ply})
        
    end)

    add("lb", function(ply, line, target)
        if not line or line=="" then return end
        if luadev.ValidScript then local valid,err = luadev.ValidScript(line,"lb") if not valid then return false,err end end

        luadev.RunOnClient(line, ply, X(ply,"lb"), {ply=ply})
        return luadev.RunOnServer(line, X(ply,"lb"), {ply=ply}) 
    end)

    /**
    Sample debug.getinfo struct:
        currentline		=	-1
        func			=	function: 0xf1781360 (@addons/ahhkchu/lua/sneeze/sv_player_extension.lua 24-36)
        isvararg		=	false
        lastlinedefined	=	36
        linedefined		=	24
        namewhat		=	
        nparams			=	1
        nups			=	0
        short_src		=	addons/ahhkchu/lua/sneeze/sv_player_extension.lua
        source			=	@addons/ahhkchu/lua/sneeze/sv_player_extension.lua
        what			=	Lua
    */


    hook.Add ("LuaDevProcess", "Print Function Defines", function (iStage, _, _, _, _, _, _, tblCaptured)
        if iStage ~= 3 then return end

        mxData = tblCaptured [1]

        if type (mxData) ~= "function" then return end

        tblDebug 				= debug.getinfo (mxData)

        if tblDebug ['source'] == "=[C]" then
            return
        end

        tblAssembleOutput 		= {}

        if file.Exists (tblDebug ["short_src"], "GAME") then
            iDebugDefinedLineStart 	= tblDebug ["linedefined"]
            iDebugDefinedLineEnd 	= tblDebug ["lastlinedefined"]
            strDebugFileContents 	= file.Read (tblDebug ["short_src"], "GAME")
            tblLines 				= string.Explode ("\n", strDebugFileContents)

            for iLine = iDebugDefinedLineStart, iDebugDefinedLineEnd do
                table.insert (tblAssembleOutput, string.format ("\n%s", tblLines [iLine]))
            end
        elseif luadev.scripts [tblDebug ["short_src"]] then
            iDebugDefinedLineStart 	= tblDebug ["linedefined"]
            iDebugDefinedLineEnd 	= tblDebug ["lastlinedefined"]
            strDebugFileContents 	= tblDebug ["short_src"]
            strDebugFileContents 	= luadev.scripts [tblDebug ["short_src"]]
            tblLines 				= string.Explode ("\n", strDebugFileContents)

            for iLine = iDebugDefinedLineStart, iDebugDefinedLineEnd do
                table.insert (tblAssembleOutput, string.format ("\n%s", tblLines [iLine]))
            end	
        end



        MsgC (unpack (tblAssembleOutput))
        Msg  ("\n")
    end)

    add("print", function(ply, line, target)
        if not line or line=="" then return end
        if luadev.ValidScript then local valid,err = luadev.ValidScript("x("..line..")","print") if not valid then return false,err end end

        strAssembleOutput = luadev.RunOnServer ("print (tostring (" .. line .. ")) return " .. line,  X (ply, "print"), {ply = ply})

        return strAssembleOutput
    end)

    add("table", function(ply, line, target)
        if not line or line=="" then return end
        if luadev.ValidScript then local valid,err = luadev.ValidScript("x("..line..")","table") if not valid then return false,err end end

        return luadev.RunOnServer("PrintTable (" .. line .. ")",  X(ply,"table"), {ply=ply}) 
    end)

    add("keys", function(ply, line, target)
        if not line or line=="" then return end
        if luadev.ValidScript then local valid,err = luadev.ValidScript("x("..line..")","keys") if not valid then return false,err end end

        return luadev.RunOnServer("for k, v in pairs(" .. line .. ") do print (k) end",  X(ply,"keys"), {ply=ply})
    end)

    add("printc", function(ply, line, target)
        if not line or line=="" then return end
        line = "easylua.PrintOnServer(" .. line .. ")"
        if luadev.ValidScript then local valid,err = luadev.ValidScript(line,"printc") if not valid then return false,err end end

        return luadev.RunOnClients(line,  X(ply,"printc"), {ply=ply})
    end)

    add("printm", function(ply, line, target)
        if not line or line=="" then return end
        line = "easylua.PrintOnServer(" .. line .. ")"
        if luadev.ValidScript then local valid,err = luadev.ValidScript(line,"printm") if not valid then return false,err end end
        
        luadev.RunOnClient(line,  ply,  X(ply,"printm"), {ply=ply})
    end)

    add("printb", function(ply, line, target)
        if not line or line=="" then return end
        if luadev.ValidScript then local valid,err = luadev.ValidScript("x("..line..")","printb") if not valid then return false,err end end

        luadev.RunOnClient("easylua.PrintOnServer(" .. line .. ")",  ply, X(ply,"printb"), {ply=ply})
        return luadev.RunOnServer("print(" .. line .. ")",  X(ply,"printb"), {ply=ply})
    end)

end)