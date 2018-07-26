function Do_You_want_It()
{
param ( [string]$input_str )
$yn_test = read-host -prompt "Do you want to extract the $input_str ? [Y/y] or [N/n] "
if ( $yn_test -match "Y" ) 
{ $return_value = 1 }
elseif ( $yn_test -match "N") 
{ $return_value = 0 }
else 
{ $return_value = "Invalid choice ..." }
return $return_value
}


$scripts_path = "C:\\Users\\mitroia2\\Documents\\scripturi, Doamne ajuta\\XLRD\"
$servers_file = "C:\\Users\\mitroia2\\Documents\\scripturi, Doamne ajuta\\XLRD\test.txt"

write-output "## By Alex, 2018 ##"
write-output "Please list the servers you want in the notepad before calling this script`n"
write-output "This is the content at the moment:`n"
get-content $servers_file
sleep 2
$open_notepad = read-host -prompt "`n`nDo you want to open the notepad file ? [Y/y] or [N/n] "
if ( $open_notepad -match "Y" )
{ notepad $servers_file }
elseif ( $open_notepad -match "N" )
{ write-output "Moving on ..." }
else {write-output "Invalid choice ... Moving on ..."}

$move_on = read-host -prompt "Do you want to continue ? [Y/y] or [N/n]  "
if ( $move_on -match "N" )
{
	write-output "Closing the script..."
	sleep 4
}
elseif ( $move_on -match "Y" )
{
	$CRQ = read-host -prompt "CRQ Number: "
	$yn_users = Do_You_want_It "users"
	$yn_localfs = Do_You_want_It "local filesystems"
	$yn_SAN = Do_You_want_It "SAN filesystems"
	$yn_CIFS = Do_You_want_It "NFS CIFS filesystems"
	if ( ($yn_users -is [int] ) -and ($yn_localfs -is [int]) -and ($yn_SAN -is [int]) -and ($yn_CIFS -is [int]) )
	{ $another_move_on = 1 }
	else
	{ $another_move_on = 0 }
	
	if ( $another_move_on -eq 1 )
	{
		foreach ( $item in get-content $servers_file )
		{	
			$ITEM = $item.replace(' ','')
			write-output "`n====== $ITEM ======`n"
			if ( $yn_users -eq 1 )
			{ 	
				write-output "`nGetting the users ...`n"
				python $scripts_path\get_users_servers.py $CRQ.replace(' ','') $ITEM "UNIX" 
			}
			if ( $yn_localfs -eq 1 )
			{ 
				write-output "`nGetting the local filesystems ...`n"
				python $scripts_path\get_localfs_servers.py $CRQ.replace(' ','') $ITEM "UNIX" 
			}
			if ( $yn_SAN -eq 1 )
			{ 
				write-output "`nGetting the SAN filesystems ...`n"
				python $scripts_path\get_sanfs_nfscifs_servers.py $CRQ.replace(' ','') $ITEM "SAN" "UNIX" 
			}
			if ( $yn_CIFS -eq 1 )
			{ 
				write-output "`nGetting the NFS CIFS filesystems ...`n"
				python $scripts_path\get_sanfs_nfscifs_servers.py $CRQ.replace(' ','') $ITEM "CIFS" "UNIX" 
			}
			
		}
	}
	read-host "Press ENTER to exit..."
}
else
{write-output "Invalid choice"}

