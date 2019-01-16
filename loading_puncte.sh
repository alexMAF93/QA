G='\033[1;32m' # Escape sequence for Green
R='\033[1;31m'   # Escape sequence for Red
B='\033[1;34m'
Y='\033[1;33m'
C='\033[1;36m'
NC='\033[0m'       # Escape sequence no color


echo
echo
echo

function intrerupere {
  if [[ $1 == "q" ]] || [[ $1 == "Q" ]]
  then
	cat /home/oquat/malex/OLD_SCRIPTS/output
  break
  fi
}

while true

do
echo -ne "		               ${R}.${NC}         \r"
read -t 1 -N 1 input
intrerupere $input

sleep 1
echo -ne "		               ${R}.${NC}${G}.${NC}        \r"
read -t 1 -N 1 input
intrerupere $input

sleep 1
echo -ne "		               ${R}.${NC}${G}.${NC}${B}.${NC}       \r"
read -t 1 -N 1 input
intrerupere $input

sleep 1
echo -ne "		               ${R}.${NC}${G}.${NC}${B}.${NC}${Y}.${NC}       \r"
read -t 1 -N 1 input
intrerupere $input

sleep 1
echo -ne "		               ${R}.${NC}${G}.${NC}${B}.${NC}${Y}.${NC}${C}.${NC}       \r"
read -t 1 -N 1 input
intrerupere $input


sleep 1
echo -ne " 		               ${R}.${NC}${G}.${NC}${B}.${NC}${Y}.${NC}${C}.${NC}       \r"
read -t 1 -N 1 input
intrerupere $input

sleep 1
echo -ne "                              ${R}.${NC}${G}.${NC}${B}.${NC}${Y}.${NC}       \r"
read -t 1 -N 1 input
intrerupere $input


sleep 1
echo -ne "                              ${R}.${NC}${G}.${NC}${B}.${NC}       \r"
read -t 1 -N 1 input
intrerupere $input


sleep 1
echo -ne "                              ${R}.${NC}${G}.${NC}        \r"
read -t 1 -N 1 input
intrerupere $input

sleep 1
echo -ne "                              ${R}.${NC}         \r"
read -t 1 -N 1 input
intrerupere $input
sleep 1

done
