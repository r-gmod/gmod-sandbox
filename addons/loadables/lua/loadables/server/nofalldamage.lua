hook.Add( "GetFallDamage", "DisableFallDamage", function( ply, speed )
	if GetConVar( "sbox_godmode" ):GetBool( ) then
		return 0
	end
end )
