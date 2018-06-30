CreateConVar( "rg_weapons", "1", { FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_LUA_SERVER }, "If enabled, each player will receive a crowbar and gravity gun on each spawn" )

if SERVER then
	hook.Add( "PlayerLoadout", "RGWeapons", function( ply )
		if GetConVar( "rg_weapons" ):GetBool( ) then
			ply:Give( "weapon_crowbar" )
			ply:Give( "weapon_physcannon" )
		end
	end )
end