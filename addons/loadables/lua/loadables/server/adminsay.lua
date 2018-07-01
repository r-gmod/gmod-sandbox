CreateConVar( "rg_adminsay", "1", { FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_LUA_SERVER }, "If enabled, team chat will relay to admin chat instead" )

hook.Add( "PlayerSay", "AdminSay", function( ply, text, team )
	if team then
		ulx.asay( ply, text )
		return ""
	end
end )
