hook.Add( "PlayerSay", "AdminSay", function( ply, text, team )
	if team then
		ulx.asay( ply, text )
		return ""
	end
end )
