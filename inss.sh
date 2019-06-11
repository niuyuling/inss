#!/system/bin/sh


function INIT_() {
    ARGV="$@";
    null="/dev/null";
    bbox="/system/xbin/busybox";
    inss="/data/local/inss";
    
    #填写自己需要的内网IP.IP第一个字节值.SHELL数组.
    ip_addr_array1=(10); # 10

    #填写自己需要的内网IP.IP第二个字节值.SHELL数组.
    ip_addr_array2=(70); # 4 43 31 70


    #填写自己的网卡.
    NIC="rmnet_data0";

    #网卡开启状态.
    NIC_STATUS="U";
    
    #等待7秒.
    SLEEP="7";

    if ! ${bbox} &> /dev/null; then echo "BusyBox No Found !"; exit 1; fi
    
    svc_="$(${bbox} which svc)";
    settings_="$(${bbox} which settings)";
    am_="$(${bbox} which am)";
    netcfg_="$(${bbox} which netcfg)";
    setenforce_="$(${bbox} which setenforce)";

    #判断必须要命令.否则退出子壳返回错误代码1.
    if ${bbox} [[ "${svc_}" = "" ]]; then echo "Svc Command No Found !"; exit 1; fi
    if ${bbox} [[ "${settings_}" = "" ]]; then echo "Settings Command No Found !"; exit 1; fi
    if ${bbox} [[ "${am_}" = "" ]]; then echo "Am Command No Found !"; exit 1; fi
    if ${bbox} [[ "${setenforce_}" = "" ]]; then echo "Setenforce Command No Found !"; exit 1; fi
    
    
    #开启飞行模式(关闭网络)
    STOP="settings put global airplane_mode_on 1 &> /dev/null; am broadcast -a android.intent.action.AIRPLANE_MODE &> /dev/null; ${svc_} data disable";
    #关闭飞行模式(开启网络)
    START="settings put global airplane_mode_on 0 &> /dev/null; am broadcast -a android.intent.action.AIRPLANE_MODE &> /dev/null; ${svc_} data enable";


    if ${bbox} test -n "${ARGV}"; then
        ip_addr_array2=(${ARGV});
    fi

    #设置SElinux状态
    setenforce 0
    
    ROOT_;                                                          # 判断ROOT用户执行.
}

function HELP_() {
#帮助
    ${bbox} cat << EOF
INSS
Ip network switch script.
Usage:
    ${0} [N] [N].
    ${0} [-xch] [-c FILE].
options:
    -x  : print debug.
    -c  : config file.
    -h  : print help.

inss by aixiao@aixiao.me
EOF
    exit 0;
}

# 判断参数是不是全部参数
function parameter_() {
    for n in ${@}; do
        if ${bbox} test -n "$(echo $n | ${bbox} sed -n "/^[0-9]\+$/p")"; then
            :
        else
            echo $n 'Not a number.'
            exit 1;
        fi
    done
    
}

function ROOT_(){
    # root用户.
    if ${bbox} [[ "`${bbox} id -u`" != "0" ]]; then ${bbox} echo "ROOT user run ?"; exit 1; fi
}

function LOG_() {
    # 写入日志文件.
    ip=$(${bbox} netstat -r | ${bbox} grep ${NIC} | ${bbox} grep ${NIC_STATUS} | ${bbox} awk '{print $1}');
    if ${bbox} [[ -d ${inss}/log ]]; then
        today=$(date +"%Y%m%d%H%M%S");
        echo ${today} >> ${inss}/log/ip_address.log;
        echo ${ip} >> ${inss}/log/ip_address.log;
    fi
}

function one_() {
    # 截取IP第一个字节值.
    ip_addres1=`${bbox} netstat -r | ${bbox} grep ${NIC} | ${bbox} grep ${NIC_STATUS} | ${bbox} awk '{print $1}' | ${bbox} cut -d "." -f 1`;
    echo "${ip_addres1}";
}

function two_() {
    # 截取IP第二个字节值.
    ip_addres2=`${bbox} netstat -r | ${bbox} grep ${NIC} | ${bbox} grep ${NIC_STATUS} | ${bbox} awk '{print $1}' | ${bbox} cut -d "." -f 2`;
    echo "${ip_addres2}";
}

function INSTATUS_() {
    # 网络状态.
    ip_rmnet0=`${bbox} netstat -r | ${bbox} grep ${NIC} | ${bbox} grep ${NIC_STATUS} | ${bbox} awk 'NR==1 {print $4}'`;
    echo "${ip_rmnet0}";
}

function IPSTATUS_() {
    # 打印完整IP.
    ${bbox} netstat -r | ${bbox} grep ${NIC} | ${bbox} grep ${NIC_STATUS} | ${bbox} awk '{print $1}';
}

function LOOP_() {
    # 循环执行sleep直到营运商给手机分配IP.
    while ${bbox} [[ "`two_`" = "" ]]; do
        ${bbox} sleep 7;
        two_;
    done
}

function MAIN_ {
    if ${bbox} [[ "`INSTATUS_ 2> /dev/null`" != "${NIC_STATUS}" ]]; then    # 判断网络是否开启.
        #echo "数据连接已经关闭...";
        #echo "数据连接正在打开...";
        :
    else
        #echo "数据连接已经开启..."
        for o in ${ip_addr_array1[@]}; do                            # 开启还要检查IP对不对.
            if ${bbox} [[ "`one_`" = "${o}" ]]; then
                for t in ${ip_addr_array2[@]}; do
                    if ${bbox} [[ "`two_`" = "${t}" ]]; then
                        LOG_;                                        # 调用自定义函数LOG_, 把路由存入日至文件.
                        exit 1;                                      # IP第二个字节值匹配的话退出, 不匹配进入下面循环.
                    fi
                done
            fi
        done
    fi

    while true; do                                                   # 循环结构.
        eval ${STOP};
        ${bbox} sleep ${SLEEP};                                      # 等待.
        eval ${START};
        LOOP_;                                                       # 调用自定义函数LOOP_, 直到营运商给我分配IP.
        IPSTATUS_;                                                   # 调用自定义函数IPSTATUS_, 打印完整IP.
        for o in ${ip_addr_array1[@]} ; do         
            if ${bbox} [[ "`one_`" = "${o}" ]]; then                 # 循环直到IP的第二个字节值为我想要的.
                for t in ${ip_addr_array2[@]}; do                    # 数组元素赋值给变量t.
                    if ${bbox} [[ "`two_`" = "${t}" ]]; then         # 数组元素是否等于自定义函数返回值.
                        LOG_;
                        exit 1;                                      # 退出.
                    fi
                done
            fi
        done   
    done
}


while getopts :xc:h? l; do
case ${l} in
    x)
        debug=x;
        ;;
    c)
        # 载入配置文件.
        . $OPTARG;
        ;;
    h|?)
        HELP_;
        ;;
    *)
        HELP_;
        ;;
esac
done
shift $((OPTIND-1));
test "${debug}" = "x" && set -x;
INIT_ $@
parameter_ ${@};
MAIN_;
exit $?;
201812262344
201904011601
201905041759
错误:
cmd: Failure calling service settings: Failed transaction (2147483646)
cmd: Failure calling service activity: Failed transaction (2147483646)
必须修改SElinux状态

by aixiao@aixiao.me
