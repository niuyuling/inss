:

aixiao="${@}"

function inss_INIT() {
    null="/dev/null"
    bbox="/system/xbin/busybox"
    aixiao_inss="/data/local/aixiao.inss"
    ip_addr_array=(99) #4 43 31
    #填写自己需要的内网IP.IP第二个字节值.SHELL数组.
    ip_addr_array1=(10) #10
    #填写自己需要的内网IP.IP第一个字节值.SHELL数组.
    ip_rmnet="rmnet0"
    #填写自己的网卡.

    if ! ${bbox} &> /dev/null ; then echo "BusyBox No Found !" ; exit 1 ; fi
    if ! svc &> /dev/null ; then echo "Svc No Found !" ; exit 1 ; fi
    #判断必须要命令.否则退出子壳返回错误代码1.
    if ! netcfg &> /dev/null ; then export netstat="${bbox} netstat" ; export c="U" ; else export c="UP" ; fi
    #判断netcfg命令存在不存在.如果存在c等于UP.如果不存在c等于U.
    if ${bbox} [[ "${aixiao}" != "" ]] ; then
        ${bbox} echo ${aixiao} | grep [0-9] > /dev/null 2>&1 && ip_addr_array=(${aixiao})
    fi
    if ${bbox} [[ "${aixiao}" = "" ]] && ${bbox} [[ -e ${aixiao_inss}/etc/inss.conf ]] ; then
        . ${aixiao_inss}/etc/inss.conf
    fi
    if ${bbox} [[ "${ip_addr}" != "" ]] ; then
        ip_addr_array=(${ip_addr})
    fi
    if ${bbox} [[ "${ip_addr1}" != "" ]] ; then
        ip_addr_array1=(${ip_addr1})
    fi
}

function inss_VERSION() {
    #日志.
    echo "
#Ip network switch script.
#20150913 aixiao write.
  初步编写程序架构.
#20151101 aixiao modify.
  增加方案判断路由.
#20160208 aixiao modify.
  循环执行sleep直到营运商给手机分配IP,不会等待几秒,实时判断分配的IP.
#20160521 aixiao modify.
  增加选项&参数.
#20160614 aixiao modify.
  加密shell script留下"-t"选项.会先显示该指令及所下的参数.
#20160622 aixiao modify.
  增加配置文件(默认${aixiao_inss}/etc/inss.conf).
#20160628 aixiao modify.
  增加日志文件(默认${aixiao_inss}/log/ip_address.log).
#20160710 aixiao modify.
  规范代码,包括自定义函数自定义变量.
#20160819 aixiao modify.

#20170215 aixiao modify.
  全部函数调用.
inss by aixiao.
Email 1605227279@qq.com.
"
    exit 0
}

function inss_HELP() {
    #帮助
    ${bbox} cat << EOF
Ip network switch script.
Usage:
    ${0} [N] [N].
    inss [option] [parameter].
options:
    -t tarck.
    -c config file.
    -h print help.
    -v|-V print version information.

parameters:
    -c config file (default: ${aixiao_inss}/etc/inss.conf).

inss by aixiao.
Email 1605227279@qq.com.
EOF
    exit 0
}

function inss_ROOT(){
    #root用户.
    if ${bbox} [[ "`${bbox} id -u`" != "0" ]] ; then ${bbox} echo "ROOT user run ?" ; exit 1 ; fi
}

function inss_ip() {
    #写入日志文件.
    ip=$(${netstat} -r | ${bbox} grep ${ip_rmnet} | ${bbox} grep U | ${bbox} awk '{print $1}')
    if ${bbox} [[ -d ${aixiao_inss}/log ]] ; then
        today=$(date +"%Y%m%d%H%M%S")
        echo ${today} >> ${aixiao_inss}/log/ip_address.log
        echo ${ip} >> ${aixiao_inss}/log/ip_address.log
    fi
}

function inss_a() {
    #截取IP第二个字节值.
    if [[ "${1}" = "UP" ]] ; then
        ip_addres=`netcfg | ${bbox} grep UP | ${bbox} grep ${ip_rmnet} | ${bbox} grep -v "lo" | ${bbox} tr -s " " | ${bbox} cut -d "." -f 3`
        echo "${ip_addres}"
    elif [[ "${1}" = "U" ]] ; then
        ip_addres=`${netstat} -r | ${bbox} grep ${ip_rmnet} | ${bbox} grep U | ${bbox} awk '{print $1}' | ${bbox} cut -d "." -f 2`
        echo "${ip_addres}"
    fi
}

function inss_b() {
    #网络状态.
    if [[ "${1}" = "UP" ]] ; then
        ip_rmnet0=`netcfg | ${bbox} grep ${ip_addres} | ${bbox} grep -v "lo" | ${bbox} awk '{print $2}'`
        echo "$ip_rmnet0"
    elif [[ "${1}" = "U" ]] ; then
        ip_rmnet0=`${netstat} -r | ${bbox} grep ${ip_addres} | ${bbox} awk 'NR==1 {print $4}'`
        echo "${ip_rmnet0}"
    fi
}

function inss_c() {
    #循环执行sleep直到营运商给手机分配IP.
    while [ "`${netstat} -r | ${bbox} grep ${ip_rmnet} | ${bbox} grep U | ${bbox} awk '{print $1}' | ${bbox} cut -d "." -f 2`" = "" ] ; do
               sleep 3
               inss_a ${c}
    done
}

function inss_d() {
    #打印完整IP.
    ${netstat} -r | ${bbox} grep ${ip_rmnet} | ${bbox} grep U | ${bbox} awk '{print $1}'
}

function inss_e() {
    #截取IP第一个字节值.
    if [[ "${1}" = "UP" ]] ; then
        ip_addres=`netcfg | ${bbox} grep UP | ${bbox} grep ${ip_rmnet} | ${bbox} grep -v "lo" | ${bbox} tr -s " " | ${bbox} cut -d "." -f 3`
        echo "${ip_addres}"
    elif [[ "${1}" = "U" ]] ; then
        ip_addres=`${netstat} -r | ${bbox} grep ${ip_rmnet} | ${bbox} grep U | ${bbox} awk '{print $1}' | ${bbox} cut -d "." -f 1`
        echo "${ip_addres}"
    fi
}

function inss_MAIN {
    if ${bbox} [[ "`inss_b ${c} 2> /dev/null`" != "${c}" ]] ; then   #这行判断网络是否开启.
        echo "数据连接已经关闭..."    
        echo "数据连接正在打开..."
    else
        echo "数据连接已经开启..."
        for zhy in ${ip_addr_array[@]} ; do                          #如果开启还要检查IP对不对.
            if ${bbox} [[ `inss_a ${c}` = $zhy ]] ; then
                for zhn in ${ip_addr_array1[@]} ; do
                    if ${bbox} [[ `inss_e ${c}` = $zhn ]] ; then
                        inss_ip                                      #调用自定义函数inss_ip把路由存入日至文件.
                        exit 1                                       #如果IP的第二个字节值对的话退出.如果不对就进入下面循环.
                    fi
                done
            fi
        done
    fi

    while true ; do                                                 #循环结构.
        svc data disable                                             #关闭网络.
        sleep 5                                                      #等待5秒.
        svc data enable                                              #开启网络.
        inss_c                                                       #调用自定义函数c,开启网络后3秒循环打印IP第二字节值,直到营运商给我分配IP.
        inss_d                                                       #调用自定义函数inss_d打印路由.
        for zhy in ${ip_addr_array[@]} ; do         
            if ${bbox} [[ `inss_a ${c}` = $zhy ]] ; then             #一直循环直到IP的第二个字节值为我想要的.
                for zhn in ${ip_addr_array1[@]} ; do                 #把数组元素赋值给变量zhn.
                    if ${bbox} [[ `inss_e ${c}` = $zhn ]] ; then     #判断数组元素是否等于自定义函数打印的值.
                        inss_ip
                        exit 1                                       #然后退出.
                    fi
                done
            fi
        done   
    done
}

inss_INIT
while getopts :tc:hvV lm
do
case ${lm} in
    t)
        log=t
        ;;
    c)
        #载入配置文件.
        . $OPTARG
        ;;
    h)
        inss_HELP
        ;;
    v|V)
        inss_VERSION
        ;;
esac
done
shift $((OPTIND-1))
test "${log}" = "t" && set -x
inss_INIT
inss_ROOT
inss_a ${c}                                                      #调用自定义函数a打印一下IP的第二个字节值.
inss_e ${c}
inss_d
inss_b ${c} 2> ${null}                                           #调用自定义函数b打印一下网络的状态.主要给我看的.
inss_MAIN
exit
AIXIAO.
