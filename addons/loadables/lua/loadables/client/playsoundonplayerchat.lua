CreateClientConVar( "rg_chatsound", "0", true, false )
CreateClientConVar( "rg_chatsound_self", "1", true, false )

hook.Add( "OnPlayerChat", "PlaySoundOnPlayerChat", function( ply )
	if GetConVar( "rg_chatsound" ):GetBool( ) and ( ply ~= LocalPlayer( ) or GetConVar( "rg_chatsound_self" ):GetBool( ) ) then
		chat.PlaySound( )
	end
end )
