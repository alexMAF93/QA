#!/bin/bash


NAME=$1;shift
TIER2=$1;shift
TYPE=$*
DIM_ITEM=${#NAME}
result=0


function test_Customer()
{
    START_LETTER=$1
    END_LETTER=$2
    declare -a CC=("AL" "CZ" "EG" "DE" "GH" "GR" "HU" "IN" "IE" "IT" "MT" "PT" "QA" "RO" "ZA" "ES" "TR" "UK" "NL" "DB" "VA" "VO" "PP" "GS" "VG")
    DIM_CC=${#CC[@]}
    CC_ITEM=${NAME:$START_LETTER:$END_LETTER}
    cnt=0
    while [ $cnt -lt $DIM_CC ]
    do
        if [[ "$CC_ITEM" == "${CC[cnt]}" ]]
        then
            result_cc=1
            break
        else
            result_cc=0
        fi
        cnt=$((cnt+1))
    done
}


function test_Technology()
{
	T_ITEM=${NAME:$((DIM_ITEM-2)):1}
	if [[ "$TIER2" == "Virtual" ]]
	then
		declare -a T=("A" "C" "I" "L" "M" "O" "S" "T" "V" "X" "Y" "Z" "T")
	elif [[ "$TIER2" == "Logical" ]]
	then
		declare -a T=("A" "C" "I" "L" "M" "O" "S" "T" "D" "H")
	#else
	#	declare -a T=("A" "C" "D" "H" "I" "L" "M" "O" "S" "T" "V" "X" "Y" "Z")
	fi
    declare -A Tech=([A]="Google Box" [C]="Sun Zones" [D]="Physical Dell" [H]="Physical HP" [I]="IBM" [L]="Solaris LDOM" [M]="HP-UX VM" [O]="Appliance" [S]="Sun/Oracle" [T]="HP-UX Container" [V]="VMware" [X]="ESP/CI/HCI" [Y]="ESP/CI/HCI" [Z]="ESP/CI/HCI")
    DIM_T=${#T[@]}
    cnt=0
    while [ $cnt -lt $DIM_T ]
    do
        if [[ "$T_ITEM" == "${T[cnt]}" ]]
        then
            result_t=1
            Technology=${Tech["$T_ITEM"]}
            break
        else
            result_t=0
        fi
        cnt=$((cnt+1))
    done
}


function test_OS()
{
    OS_ITEM=${NAME:$((DIM_ITEM-1)):1}
    declare -a O=("A" "C" "E" "G" "H" "M" "R" "S" "U" "V" "W" "T")
    declare -A OS=([A]="AIX" [C]="Cluster" [E]="ESX" [G]="Other" [H]="HP-UX" [M]="AIX" [R]="Red Hat Enterprise Linux Server" [S]="SunOS" [U]="Other" [V]="AIX" [W]="Microsoft Windows Server" [T]="True 64")
    DIM_OS=${#O[@]}
    cnt=0
    while [ $cnt -lt $DIM_OS ]
    do
        if [[ "$OS_ITEM" == "${O[cnt]}" ]]
        then
            Operating_System=${OS["$OS_ITEM"]}
            if [[ "$Operating_System" == "$TYPE" ]]
            then
                result_os=1
            else
                result_os=0
            fi
            break
        else
            result_os=0
        fi
    cnt=$((cnt+1))
    done
}


function test_Exadata()
{
	THIRD=${NAME:2:1}
	if [ $DIM_ITEM -eq 9 ]
	then
		if [[ "$THIRD" == "E" ]]
		then
			result_third=1
		else
			result_third=0
		fi
		DB=${NAME:5:2}
		if [[ "$DB" == "DB" ]]
		then
			result_db_cel=1
		else
			result_db_cel=0
		fi
	elif [ $DIM_ITEM -eq 10 ]
	then
		if [[ "$THIRD" == "E" ]]
		then
			result_third=1
		else
			result_third=0
		fi
		CEL=${NAME:5:3}
		if [[ "$CEL" == "CEL" ]]
		then
			result_db_cel=1
		else
			result_db_cel=0
		fi
	else
		result_third=0
		result_db_cel=0
	fi
}


function test_ESX()
{
	if [[ "${NAME:0:3}" == "VMH" ]]
	then
		result_vmh=1
	else
		result_vmh=0
	fi
	if [ $DIM_ITEM -eq 8 ]
	then
		result_dim=1
	elif [ $DIM_ITEM -eq 15 ]
	then
		if [[ "${NAME:5:2}" == "AZ" && "${NAME:9:1}" == "B" && "${NAME:12:1}" == "S" ]]
		then
			result_dim=1
		else
			result_dim=0
		fi
	elif [ $DIM_ITEM -eq 9 ]
	then
		result_vmh=1
		result_cc=1
		if [[ "${NAME:0:3}" == "HCI" && "${NAME:3:1}" =~ "V"|"A" && "${NAME:4:2}" =~ "IE"|"DE"|"IT" ]]
		then
			result_dim=1
		else
			result_dim=0
		fi
	else
		result_dim=0
	fi
}


function test_Citrix()
{
	TYPE="Microsoft Windows Server"
	if [ $DIM_ITEM -eq 11 ]
	then
		test_Technology
		test_OS
		result_dim=1
	else
		result_t=0
		result_os=0
		result_dim=0
	fi
}


function test_Cluster_ESXi()
{
	if [ $DIM_ITEM -eq 10 ]
	then
		if [[ "${NAME:2:2}" =~ "VM"|"NX" ]]
		then
			result_clus=1
		else
			result_clus=0
		fi
	else
		result_clus=0
	fi
}


function test_Cluster_RAC()
{
	if [ $DIM_ITEM -eq 11 ]
	then
		if [[ "${NAME:8:3}" == "-CL" ]]
		then
			result_clus=1
		else
			result_clus=0
		fi
	else
		result_clus=0
	fi
}


function test_Cluster_Veritas()
{
	result=3
}


function test_Cluster_MWS()
{
	if [ $DIM_ITEM -eq 8 ]
	then
		if [[ "${NAME:6:2}" == "CL" ]]
		then
			result_clus=1
		else
			result_clus=0
		fi
	else
		result_clus=0
	fi
}


function test_CIN()
{
	if [ $DIM_ITEM -eq 15 ]
	then
		if [[ "${NAME:0:3}" == "CIN" ]] && [ "${NAME:3:12}" -eq "${NAME:3:12}" ] 2>/dev/null
		then
			result=1
		elif [[ "${NAME:0:4}" == "CINZ" ]] && [ "${NAME:4:11}" -eq "${NAME:4:11}" ] 2>/dev/null
		then
			result=1
		else
			result=0
		fi
	
	else
		result=0
	fi
}


function test_DBaaS()
{
	if [ $DIM_ITEM -eq 6 ]
	then

		if [[ "${NAME:2:1}" == "E" && "${NAME:3:1}" =~ "D"|"M"|"R" ]]
		then
			CATEGORY="DBaaS"
			result_location=1
		else
			result_location=0
		fi		
	fi
	if [ $DIM_ITEM -eq 10 ]
	then
		if [[ "${NAME:2:1}" == "E" && "${NAME:3:1}" =~ "D"|"M"|"R" ]]
		then
			if [[ "${NAME:6:1}" == "D" ]]
			then
				CATEGORY="DBaaS"
				result_location=1
			fi
		else
			result_location=0
		fi
	fi
	if [ $DIM_ITEM -eq 11 ]
	then
		if [[ "${NAME:2:1}" == "E" && "${NAME:3:1}" =~ "D"|"M"|"R" ]]
		then
			if [[ "${NAME:6:3}" == "CEL" ]]
			then
				CATEGORY="DBaaS"
				result_location=1
			fi
		else
			result_location=0
		fi
	fi
}


function test_Big_Data()
{
	if [[ "${NAME:5:2}" == "BD" ]]
	then
		CATEGORY="Big Data"
		result_bd=1
	else
		result_bd=0
	fi
}


function test_ITEM ()
{
	if [[ "$TYPE" =~ "AIX"|"Microsoft Windows Server"|"SunOS"|"HP-UX"|"Other" ]] && [[ "$TIER2" =~ "Virtual"|"Logical" ]]
	then
		CATEGORY="Standard Server"
		test_Customer 0 2
		test_Technology
		test_OS
		if [ $DIM_ITEM -eq 8 ]
		then
			result=$(($result_cc*$result_os*$result_t))
		else
			result=0
		fi
	elif [[ "$TYPE" == "Red Hat Enterprise Linux Server" ]] && [ $DIM_ITEM -eq 8 ]
	then
		CATEGORY="Standard Server"
		test_Customer 0 2
		test_Technology
		test_OS
		result=$(($result_cc*$result_os*$result_t))
	elif [[ "$TYPE" == "Red Hat Enterprise Linux Server" ]] && [ $DIM_ITEM -eq 6 -o $DIM_ITEM -eq 10 -o $DIM_ITEM -eq 11 ]
	then
		CATEGORY="Standard Server"
		test_Customer 0 2
		test_DBaaS
		result=$(($result_cc*$result_location))
	elif [[ "$TYPE" == "Red Hat Enterprise Linux Server" ]] && [ $DIM_ITEM -eq 9 ]
	then
		CATEGORY="Standard Server"
		test_Customer 0 2
		test_Technology
		test_OS
		test_Big_Data
		result=$(($result_cc*$result_os*$result_t*$result_bd))
	elif [[ "$TYPE" == "Red Hat Enterprise Linux Server" ]]
	then
		CATEGORY="Standard Server"
	elif [[ "$TYPE" == "Exadata" ]]
	then
		CATEGORY="Exadata"
		test_Exadata
		test_Customer 0 2
		result=$(($result_cc*$result_third*$result_db_cel))
	elif [[ "$TYPE" == "ESX VMware" ]]
	then
		CATEGORY="CI VMware Cluster"
		test_Customer 3 2
		test_ESX
		result=$(($result_cc*$result_vmh*$result_dim))
	elif [[ "$TYPE" == "CitrixServer" ]]
	then
		CATEGORY="Citrix"
		test_Customer 0 2
		test_Citrix
		result=$(($result_cc*$result_os*$result_t*$result_dim))
	elif [[ "$TYPE" == "VMWare" ]]
	then
		CATEGORY="ESXi Cluster"
		test_Customer 0 2
		test_Cluster_ESXi
		result=$(($result_cc*$result_clus))
	elif [[ "$TYPE" == "Oracle RAC" ]]
	then
		CATEGORY="Oracle RAC Cluster"
		test_Customer 0 2
		test_Cluster_RAC
		result=$(($result_cc*$result_clus))
	elif [[ "$TYPE" == "Veritas" ]]
	then
		CATEGORY="Veritas Cluster"
		test_Cluster_Veritas
	elif [[ "$TYPE" =~ "Citrix"|"LPAR"|"Other"|"Sun Zone"|"Teradata" ]]
	then
		CATEGORY="$TYPE Cluster"
		result=5
	elif [[ "$TYPE" == "MS Cluster" ]]
	then
		CATEGORY="Microsoft Cluster"
		test_Customer 0 2
		test_Cluster_MWS
		result=$(($result_cc*$result_clus))
	elif [[ "$TYPE" =~ "Hosting"|"Switch" ]]
	then
		CATEGORY="Chassis"
		test_CIN
	fi
		
	if [ $result -eq 1 ]
	then
		printf "OK %s\n" "$CATEGORY"
	elif [ $result -eq 0 ]
	then
		printf "NOT_OK %s\n" "$CATEGORY"
	elif [ $result -eq 3 ]
	then
		printf "MANUAL %s\n" "$CATEGORY"
	else
		printf "N/A %s\n" "$CATEGORY"
	fi 
}


test_ITEM
