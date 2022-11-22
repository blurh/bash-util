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
    # 只能用于交互式 shell, 不能用于脚本

    perl -e '$len=`tput cols`-1;$space=" "x"$len";print "\r$space\r"' >&2
}

func WarnMsg() {
    # print msg to stderr
    local msg="$*"

    local enter=true
    if [ "${1}" == "-n" ]; then
        enter="false"
        shift
    fi
    echo -ne "${YELLOW}"
    echo -n "${msg}" >&2
    echo -ne "${CLEARCOLOR}"
    if [ "${enter}" != "false" ]; then
        echo 
    fi
}

func DebugLog() {
    local msg="$*"

    echo -ne "${GREEN}"
    echo "[$(date +%F\ %T) Debug:${BASH_LINENO}]: ${msg}"
    echo -ne "${CLEARCOLOR}"
}

func WarnLog() {
    local msg="$*"

    echo -ne "${YELLOW}"
    echo "[$(date +%F\ %T) Warn:${BASH_LINENO}]: ${msg}"
    echo -ne "${CLEARCOLOR}"
}

func InfoLog() {
    local msg="$*"

    echo -ne "${CYAN}"
    echo "[$(date +%F\ %T) Info:${BASH_LINENO}]: ${msg}"
    echo -ne "${CLEARCOLOR}"
}

func ErrorLog() {
    local msg="$*"

    echo -ne "${RED}"
    echo "[$(date +%F\ %T) Error:${BASH_LINENO}]: ${msg}"
    echo -ne "${CLEARCOLOR}"
}

func CriticaLog() {
    local msg="$*"

    echo -ne "${MAGENTA}"
    echo "[$(date +%F\ %T) Critical:${BASH_LINENO}]: ${msg}"
    echo -ne "${CLEARCOLOR}"
}

func Exit() {
    local code=$1; shift
    local msg="$*";

    if [ "${#msg}" == "0" ]; then
        WarnMsg "Exit: ${code}"
    else
        WarnMsg "Exit: ${msg}"
    fi
    exit ${code:-0}
}

func Assert() {
    local lastRetCode=$?
    local errMsg="$1"
    local isExit="$2"

    if [ "${lastRetCode}" != "0" ]; then
        if [ "${isExit}" == "1" ]; then
            WarnMsg "${errMsg}"
            Exit 1 "last return code: ${lastRetCode}"
        else 
            WarnMsg "${errMsg}"
            WarnMsg "last return code: ${lastRetCode}"
        fi 
    fi
}

func CheckArgsCount() {
    local count=$1; shift
    local args=$*
    local argCount=$#

    if [ "${count}" != "${argCount}" ]; then
        WarnMsg "error: arg count is not equal ${count}" 
        exit
    fi 
}

func PausePoint() {
    # bash -vx run script to debug it
    set +x
    echo -e "\nNo: ${BASH_LINENO}"
    read -p "Enter to continue..." pause
    set -x
}

func GetCmdDir() {
    local CmdDir=$(cd $(dirname $0); pwd)
    echo "${CmdDir}"
}

func GetOS() {
    awk -F'=' '/PRETTY_NAME=/ {gsub(/"/, "");print $2}' /etc/os-release
}

func GetIPv4() {
    local device=$1

    if [ -n "${device}" ]; then
        ip a s ${device} | perl -lne 'print $1 if /inet ((?:\d+\.){3}\d+)/'
    else
        ip a | perl -lne 'print $1 if /inet ((?:\d+\.){3}\d+)/' | grep -v '127.0.0.1' | head -1
    fi
}

func GetIPv6() {
    local device=$1

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
    CheckArgsCount 2 $*
    echo $* | awk '{print $1 + $2}'
}

func Sub() {
    CheckArgsCount 2 $*
    echo $* | awk '{print $1 - $2}'
}

func Mult() {
    CheckArgsCount 2 $*
    echo $* | awk '{print $1 * $2}'
}

func Div() {
    CheckArgsCount 2 $*
    echo $* | awk '{print $1 / $2}'
}

func Pow() {
    CheckArgsCount 2 $*
    echo $* | awk '{print $1 ^ $2}'
}

func Mod() {
    CheckArgsCount 2 $*
    echo $* | awk '{print $1 % $2}'
}

func Ceil() {
    CheckArgsCount 1 $*
    echo $1 | awk '{printf "%.f", $1}'
}

func Floor() {
    CheckArgsCount 1 $* 
    echo ${1%.*}
}

func Random() {
    local digit=$1

    if [ -z "${digit}" ]; then 
        # 没有长度参数的时候, 随机输出长度 9 以内随机数
        Random $(Random 1)
    else 
        local num=$(echo "${digit}" | perl -ne 'print if /^\d+$/')
        if [ -z "$num" ]; then
            WarnMsg "syntax error"
            return 
        fi
        eval echo $(perl -e 'print "\$[ \$RANDOM % 10 ]"x'$num''); 
    fi
}

func CheckPIDAlived() {
    local pid=$1

    CheckArgsCount 1 $*
    kill -0 ${pid} > /dev/null 2>&1 
    if [ "$?" == "0" ]; then
        echo true
    else 
        echo false
    fi
}

func GetCpuIdle() {
    local time=$1

    local statBefore=$(awk '/cpu\s/ {$1="";print}' /proc/stat)
    WarnMsg -n "wait ${time:-1}s..." >&2
    sleep ${time:-1}
    local statAfter=$(awk '/cpu\s/ {$1="";print}' /proc/stat)
    ClearLine
    local idleBefore=$(echo ${statBefore} | awk '{print $4}')
    local idleAfter=$(echo ${statAfter} | awk '{print $4}')
    local totalBefore=$(echo ${statBefore} | perl -lne '@line=split;foreach(@line){$total+=$_};print $total')
    local totalAfter=$(echo ${statAfter} | perl -lne '@line=split;foreach(@line){$total+=$_};print $total')
    local idle=$(Sub ${idleAfter} ${idleBefore})
    local total=$(Sub ${totalAfter} ${totalBefore})
    Div ${idle} ${total}
}

func GetCpuUsage() {
    local time=$1

    local idle=$(GetCpuIdle ${time})
    Sub 1 ${idle}
}

func GetMemAvailable() {
    local availableMem=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
    local totalMem=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    Div ${availableMem} ${totalMem}
}

func GetMemUsage() {
    local availableMemPer=$(GetMemAvailable)
    Sub 1 ${availableMemPer}
}

func GetDiskUsage() {
    local mountPoint=$1

    CheckArgsCount 1 $*
    df -h | grep -w ${mountPoint} | awk '{sub("%", "");print $5/100}'
}

func ParseIni() {
    # 解析 .ini 文件
    # Usage: ParseIni <章节名> <key> <文件名>
    local section=$1
    local key=$2
    local file=$3

    sed -n '/^\['${section}'\]/,/^\[.*\]/ p' ${file} | awk '/'${key}'/ { print $2 }'
}

# turn off the script alias
shopt -u expand_aliases

if [ "$0" == "${BASH_SOURCE[0]}" ]; then
    WarnMsg "source $0 to use this script"
fi


# TODO: Test
if [ "$1" == "test" ]; then
    Greather 4 3 2
    Assert "test Greather fail, exit" 1
    Less 2 3 5
    Assert "test Less fail, exit"
    Exit 0
fi
