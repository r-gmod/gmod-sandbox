
syntax = {}
local syntax = syntax

syntax.DEFAULT    = 1
syntax.KEYWORD    = 2
syntax.IDENTIFIER = 3
syntax.STRING     = 4
syntax.NUMBER     = 5
syntax.OPERATOR   = 6

syntax.types = {
    "default",
    "keyword",
    "identifier",
    "string",
    "number",
    "operator",
    "ccomment",
    "cmulticomment",
    "comment",
    "multicomment"
}

syntax.patterns = {
    [2]  = "([%a_][%w_]*)",
    [4]  = "(\".-\")",
    [5]  = "([%d]+%.?%d*)",
    [6]  = "([%+%-%*/%%%(%)%.,<>~=#:;{}%[%]])",
    [7]  = "(//[^\n]*)",
    [8]  = "(/%*.-%*/)",
    [9]  = "(%-%-[^%[][^\n]*)",
    [10] = "(%-%-%[%[.-%]%])",
    [11] = "(%[%[.-%]%])",
    [12] = "('.-')",
    [13] = "(!+)",
}

syntax.colors = {
    Color(255, 255, 255),
    Color(127, 159, 191),
    Color(223, 223, 223),
    Color(191, 127, 127),
    Color(127, 191, 127),
    Color(191, 191, 159),
    Color(159, 159, 159),
    Color(159, 159, 159),
    Color(159, 159, 159),
    Color(159, 159, 159),
    Color(191, 159, 127),
    Color(191, 127, 127),
    Color(255,   0,   0),
}

syntax.keywords = {
    ["local"]    = true,
    ["function"] = true,
    ["return"]   = true,
    ["break"]    = true,
    ["continue"] = true,
    ["end"]      = true,
    ["if"]       = true,
    ["not"]      = true,
    ["while"]    = true,
    ["for"]      = true,
    ["repeat"]   = true,
    ["until"]    = true,
    ["do"]       = true,
    ["then"]     = true,
    ["true"]     = true,
    ["false"]    = true,
    ["nil"]      = true,
    ["in"]       = true
}

function syntax.process(code)
    local output, finds, types, a, b, c = {}, {}, {}, 0, 0, 0

    while true do
        local temp = {}

        for k, v in pairs(syntax.patterns) do
            local aa, bb = code:find(v, b + 1)
            if aa then
                table.insert(temp, {k, aa, bb})
            end
        end

        if #temp == 0 then break end
        table.sort(temp, function(a, b) return (a[2] == b[2]) and (a[3] > b[3]) or (a[2] < b[2]) end)
        c, a, b = unpack(temp[1])

        table.insert(finds, a)
        table.insert(finds, b)

        table.insert(types, c == 2 and (syntax.keywords[code:sub(a, b)] and 2 or 3) or c)
    end

    for i = 1, #finds - 1 do
        local asdf = (i - 1) % 2
        local sub = code:sub(finds[i + 0] + asdf, finds[i + 1] - asdf)

        table.insert(output, asdf == 0 and syntax.colors[types[1 + (i - 1) / 2]] or Color(0, 0, 0, 255))
        table.insert(output, (asdf == 1 and sub:find("^%s+$")) and sub:gsub("%s", " ") or sub)
    end

    return output
end

local methods = {
    ["b"]		= "api",
    ["l"]      	= "server",
    ["lb"]	   	= "both",
    ["lc"]     	= "clients",
    ["lm"]     	= "self",
    ["ls"]     	= "shared",
    ["p"]      	= "server",
    ["pc"]     	= "clients",
    ["pm2"]    	= "self",
    ["pm"]     	= "self",
    ["ps"]     	= "shared",
    ["print"]  	= "server",
    ["printb"] 	= "both",
    ["printc"] 	= "clients",
    ["printm"] 	= "self",
    ["table"]  	= "server table",
    ["keys"]   	= "server keys",
    ["cl"]     	= "xserver",
    ["cl1"]    	= "#1",
    ["cl2"]    	= "#2",
    ["cl3"]    	= "#3",
    ["cl4"]    	= "#4",
    ["cl5"]    	= "#5",
    ["lfind"]  	= "server find",
    ["lmfind"] 	= "self find",
}

local col_server = Color(191, 159, 127)
local col_client = Color(127, 191, 191)
local col_cross  = Color(100, 200, 100)
local col_misc   = Color(127, 191, 191)
local col_pserver= Color(230, 109, 220)
local col_pclient= Color(125, 109, 220)
local col_command= Color(191, 159, 127)

local colors = {
    ["b"]		= col_server,
    ["l"]      	= col_server,
    ["lc"]     	= col_client,
    ["lm"]	   	= col_client,
    ["p"]	   	= col_pserver,
    ["pc"]     	= col_pclient,
    ["pm2"]    	= col_pclient,
    ["pm"]     	= col_pclient,
    ["print"]  	= col_pserver,
    ["printc"] 	= col_pclient,
    ["printm"] 	= col_pclient,
    ["table"]  	= col_pserver,
    ["keys"]   	= col_pserver,
    ["cl"]     	= col_cross,
    ["cl1"]    	= col_cross,
    ["cl2"]    	= col_cross,
    ["cl3"]    	= col_cross,
    ["cl4"]    	= col_cross,
    ["cl5"]    	= col_cross,
    ["lfind"]  	= col_pserver,
    ["lmfind"] 	= col_pclient,
    ["•"]      	= col_command,
}

local grey = Color(191, 191, 191)

hook.Add("OnPlayerChat", "syntax", function(pCaller, strMessage, iTeam, bDead)
    local method, color -- for overrides
    local cmd, code = strMessage:match("^• (l[bcms]?) (.*)$") 
    if not code then cmd, code = strMessage:match("^• (p[sc]?) (.*)$") end
    if not code then cmd, code = strMessage:match("^• (pm[2]?) (.*)$") end
    if not code then cmd, code = strMessage:match("^• (print[bcm]?) (.*)$") end
    if not code then cmd, code = strMessage:match("^• (table) (.*)$") end
    if not code then cmd, code = strMessage:match("^• (keys) (.*)$") end
    if not code then cmd, code = strMessage:match("^• (cl[15]?) (.*)$") end
    if not code then cmd, code = strMessage:match("^• (l[m]?find) (.*)$") end
    if not code then cmd, code = strMessage:match("^• (b) (.*)$") end
    if not code then cmd, code = strMessage:match("^(•) (.*)$") end

    if not code then
        method, code = strMessage:match("^~lsc ([^,]+),(.*)$")
        color = colors["lc"]
        method = easylua.FindEntity(method)
        method = IsValid(method) and (method.Nick and method:Nick()) or tostring(method)
    end

    if not code then return end

    local method = method or methods[cmd]
    if pCaller:IsAdmin () then
        chat.AddText (pCaller:Nick ():lower (), grey, cmd == "•" and "" or '@', color or colors[cmd] or col_misc, cmd == "•" and " sneezes" or method, grey, ": ", unpack(syntax.process(code)))
        return ""
    end
end)
