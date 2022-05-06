#!/bin/bash

# Exit codes:
#  1 : 
#  2 : 
#  3 : 
#  4 : 


########################################################################
#
# CONSTANTS
#
########################################################################

# colors
BOLD="\e[1m"
GREEN="\e[32m"
LIGHTGREEN="${BOLD}${GREEN}"
RED="\033[1;31m"
LIGHTRED="\033[1;31m"
BLUE="\e[34m"
LIGHTBLUE="${BOLD}${BLUE}"
YELLOW="\e[33m"
LIGHTYELLOW="${BOLD}${YELLOW}"
WHITE="\033[0;37m"
RESET="\033[0;00m"

NOW="$(date +%Y%m%d%H%M%S)"

DEBUG=0
DEBUG=1

########################################################################
#
# / CONSTANTS
#
########################################################################

########################################################################
#
# VARIABLES
#
########################################################################

SCRIPTLOG="$(dirname `readlink -f $0`)/logs/$(basename $0 .sh)_script_${NOW}.log"
SCRIPTLOGERR="$(dirname `readlink -f $0`)/logs/$(basename $0 .sh)_script_${NOW}.err"

MINIMUMPASSWORDLENGTH=8
PASSWORDLENGTH=20
THEPASSWORD=""

########################################################################
#
# / VARIABLES
#
########################################################################



########################################################################
#
# FUNCTIONS
#
########################################################################


usage()
{
    printf "%s${LIGHTRED}USAGE:${RESET}
    $0 -u USERNAME -t TEMPLAGE_FILE [-h] [-D]
    
    -h                  this help
    -D                  DEBUG mode
"
}

printmsg()
{
   echo -e "$*"
}

output_log()
{
    if [[ "${QUIETOUTPUT}" == true ]]; then
        printmsg "$*" >> ${OUTPUTFILE}
    else
        printmsg "$*" | tee -a "${OUTPUTFILE}"
    fi
}

abort_message()
{
    printmsg "${LIGHTRED}ERROR${RESET}: $*"
    exit 1
}

# ssh_it uses variable ${DEBUGME}
ssh_it()
{
    if [[ "${DEBUGME}" && ${DEBUGME} -eq 0 ]] ; then
        ${SSHIT} $* 
    else
        ${SSHIT} $* 2>/dev/null
    fi

}

# debug_me uses variable ${DEBUGME}
debug_me()
{
    if [[ "${DEBUGME}" && ${DEBUGME} -eq 0 ]] ; then
        echo -e "${LIGHTBLUE}DEBUG: ${RESET}$*"
    fi
}

password_generator()
{
    export THEPASSWORD="$(tr -cd '[:alnum:]@#$%^&*()_+{}|<>?=' < /dev/urandom | fold -w${PASSWORDLENGTH} | head -n 1)"
}

check_password()
{
    echo -e "-- ${LIGHTYELLOW}CHECK:${RESET} password check"
    echo -e "-- $(echo ${THEPASSWORD} | egrep --color "\!|@|#|\\$|%|\^|\&|\*|\(|\)|_|\+|\{|\}|\||<|>|\?|=") "
    if [[ "$(echo ${THEPASSWORD} | egrep "\!|@|#|\\$|%|\^|\&|\*|\(|\)|_|\+|\{|\}|\||<|>|\?|=")" ]] ; then 
        RETURNVALUE=0
    else
        RETURNVALUE=1
    fi
    echo -e "-- ${LIGHTYELLOW}/CHECK:${RESET} password check"
    return ${RETURNVALUE}
}


########################################################################
#
# / FUNCTIONS
#
########################################################################

########################################################################
#
# MAIN
#
########################################################################


if [[ ${DEBUG} -eq 0 ]] ; then
    [[ ! -d $(dirname ${SCRIPTLOG}) ]] && mkdir -p $(dirname ${SCRIPTLOG})
    [[ ! -d $(dirname ${SCRIPTLOGERR}) ]] && mkdir -p $(dirname ${SCRIPTLOGERR})

    echo -e "${BLUE}DEBUGMODE${RESET} is on"
    echo -e "\t SCRIPTLOG will be ${SCRIPTLOG}"
    echo -e "\t SCRIPTLOGERR will be ${SCRIPTLOGERR}"
    #set -x
    #exec 2> ${SCRIPTLOGERR}
fi

while getopts "hDF" arg; do
  case $arg in
    h)
        usage
        ;;
    F)
        MAYTHEFORCEBEWITHYOU=true
        echo -e "${LIGHTBLUE}The force is strong in you?${RESET}"
        ;;
    D)
        DEBUG=0
        ;;
    *)
        usage
        ;;
  esac
done

password_generator
check_password
RES=$?
 
echo -e "
-- ##############################################
select dba.change_my_password('${THEPASSWORD}') ;
-- ##############################################
"

exit ${EXITCODE}

########################################################################
#
# / MAIN
#
########################################################################
