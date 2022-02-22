#!/bin/bash

# 判断是否 bash, 如不是不导入
exeline=$(ls -l /proc/$$/exe)
exe=${exeline##*/}
if [ "${exe}" != "bash" ]; then
    echo "not bash to load bash lib func, exit"
    exit
fi

# turn on the script alias
shopt -s expand_aliases
alias func=function

CLEARCOLOR='\e[0m'
BLACK='\e30m'
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
MAGENTA='\e[35m'
CYAN='\e[36m'
WHITE='\e[37m'

func ClearLine() {
    perl -e '$len=`tput cols`-1;$space=" "x"$len";print "\r$space\r"' >&2
}

func WarnMsg() {
    local enter=true
    if [ "${1}" == "-n" ]; then
        enter="false"
        shift
    fi
    msg="$*"
    echo -ne "${YELLOW}"
    echo -n "${msg}" >&2
    echo -ne "${CLEARCOLOR}"
    if [ "${enter}" != "false" ]; then
        echo 
    fi
}

func CheckArgCount() {
    count=$1
    shift
    args=$*
    argCount=$#
    if [ "${count}" != "${argCount}" ]; then
        WarnMsg "arg count is not equal ${count}"
    fi
}

func DebugLog() {
    msg="$*"
    echo -ne "${GREEN}"
    echo "[$(date +%F\ %T) Debug:${BASH_LINENO}]: ${msg}"
    echo -ne "${CLEARCOLOR}"
}

func WarnLog() {
    msg="$*"
    echo -ne "${YELLOW}"
    echo "[$(date +%F\ %T) Warn:${BASH_LINENO}]: ${msg}"
    echo -ne "${CLEARCOLOR}"
}

func InfoLog() {
    msg="$*"
    echo -ne "${CYAN}"
    echo "[$(date +%F\ %T) Info:${BASH_LINENO}]: ${msg}"
    echo -ne "${CLEARCOLOR}"
}

func ErrorLog() {
    msg="$*"
    echo -ne "${RED}"
    echo "[$(date +%F\ %T) Error:${BASH_LINENO}]: ${msg}"
    echo -ne "${CLEARCOLOR}"
}

func CriticaLog() {
    msg="$*"
    echo -ne "${MAGENTA}"
    echo "[$(date +%F\ %T) Critical:${BASH_LINENO}]: ${msg}"
    echo -ne "${CLEARCOLOR}"
}

func Exit() {
    code=$1
    shift
    msg="$*"
    if [ ${#msg} == 0 ]; then
        echo "Exit: ${code}"
    else
        echo "Exit: ${msg}"
    fi
    exit ${code:-0}
}

func PausePoint() {
    # bash -vx run script to debug it
    set +x
    echo -e "\nNo: ${BASH_LINENO}"
    read -p "Enter to continue..." pause
    set -x
}

func GetOS() {
    awk -F'=' '/PRETTY_NAME=/ {gsub(/"/, "");print $2}' /etc/os-release
}

func GetIPv4() {
    device=$1
    if [ -n "${device}" ]; then
        ip a s ${device} | perl -lne 'print $1 if /inet ((?:\d+\.){3}\d+)/'
    else
        ip a s ${device} | perl -lne 'print $1 if /inet ((?:\d+\.){3}\d+)/' | grep -v '127.0.0.1' | head -1
    fi
}

func GetIPv6() {
    device=$1
    if [ -n "${device}" ]; then
        ip a s ${device} | perl -lne 'print $1 if /inet6 (.*)\/\d+/'
    else
        ip a s ${device} | perl -lne 'print $1 if /inet6 (.*)\/\d+/' | grep -v '::1' | head -1
    fi
}

func Year() {
    date +%Y
}

func Month() {
    date +%m
}

func Date() {
    date +%F
}

func Week() {
    date +%W
}

func Hour() {
    date +%H
}

func Minute() {
    date +%M
}

func Second() {
    date +%S
}

func Datetime() {
    date +%F\ %T
}

func UnixTime() {
    date +%s
}

func Max() {
    echo "$@" | perl -pe 's/\s+/\n/g' | sort -nr | head -1
}

func Min() {
    echo "$@" | perl -pe 's/\s+/\n/g' | sort -n | head -1
}

func Greather() {
    if [ "$(Max $*)" == "$1" ]; then
        return 0
    else
        return 1
    fi
}

func Less() {
    if [ "$(Min $*)" == "$1" ]; then
        return 0
    else
        return 1
    fi
}

func Sum() {
    CheckArgCount 2 $*
    echo $* | awk '{print $1 + $2}'
}

func Sub() {
    CheckArgCount 2 $*
    echo $* | awk '{print $1 - $2}'
}

func Mult() {
    CheckArgCount 2 $*
    echo $* | awk '{print $1 * $2}'
}

func Div() {
    CheckArgCount 2 $*
    echo $* | awk '{print $1 / $2}'
}

func Pow() {
    CheckArgCount 2 $*
    echo $* | awk '{print $1 ^ $2}'
}

func Mod() {
    CheckArgCount 2 $*
    echo $* | awk '{print $1 % $2}'
}

func Ceil() {
    CheckArgCount 1 $*
    echo $1 | awk '{printf "%.f", $1}'
}

func Floor() {
    CheckArgCount 1 $* 
    echo ${1%.*}
}

func Random() {
    digit=$1
    if [ -z "${digit}" ]; then 
        Random $(Random 1) 
    else 
        num=$(echo "${digit}" | perl -ne 'print if /^\d+$/')
        if [ -z "$num" ]; then
            WarnMsg "syntax error"
            return 
        fi
        eval echo $(perl -e 'print "\$[ \$RANDOM % 10 ]"x'$num''); 
    fi
}

func CheckPIDAlived() {
    pid=$1
    CheckArgCount 1 $*
    kill -0 ${pid} > /dev/null 2>&1 
    if [ "$?" == "0" ]; then
        echo true
    else 
        echo false
    fi
}

func GetCpuIdle() {
    time=$1
    statBefore=$(awk '/cpu\s/ {$1="";print}' /proc/stat)
    WarnMsg -n "wait ${time:-1}s..." >&2
    sleep ${time:-1}
    statAfter=$(awk '/cpu\s/ {$1="";print}' /proc/stat)
    ClearLine
    idleBefore=$(echo ${statBefore} | awk '{print $4}')
    idleAfter=$(echo ${statAfter} | awk '{print $4}')
    totalBefore=$(echo ${statBefore} | perl -lne '@line=split;foreach(@line){$total+=$_};print $total')
    totalAfter=$(echo ${statAfter} | perl -lne '@line=split;foreach(@line){$total+=$_};print $total')
    idle=$(Sub ${idleAfter} ${idleBefore})
    total=$(Sub ${totalAfter} ${totalBefore})
    Div ${idle} ${total}
}

func GetCpuUsage() {
    time=$1
    idle=$(GetCpuIdle ${time})
    Sub 1 ${idle}
}

func GetMemAvailable() {
    availableMem=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
    totalMem=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    Div ${availableMem} ${totalMem}
}

func GetMemUsage() {
    availableMemPer=$(GetMemAvailable)
    Sub 1 ${availableMemPer}
}

func GetDiskUsage() {
    mountPoint=$1
    CheckArgCount 1 $*
    df -h | grep -w ${mountPoint} | awk '{sub("%", "");print $5/100}'
}

func ParseIni() {
    section=$1
    key=$2
    file=$3
    sed -n '/^\['${section}'\]/,/^\[.*\]/ p' ${file} | awk '/'${key}'/ { print $2 }'
}

# turn off the script alias
shopt -u expand_aliases

if [ "$0" == "${BASH_SOURCE[0]}" ]; then
    WarnMsg "source ./bash_lib_functions.sh to use this script"
fi

# TODO: Test
if [ "$1" == "test" ]; then
    Greather 4 3 2
    if [ $? != 0 ]; then
        Exit 1 "test Greather fail, exit"
    fi
    Less 2 3 5
    if [ $? != 0 ]; then
        Exit 1 "test Less fail, exit"
    fi
    Exit 0
fi
