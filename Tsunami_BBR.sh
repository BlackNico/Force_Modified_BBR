#!/bin/bash
Green_font="\033[32m" && Yellow_font="\033[33m" && Red_font="\033[31m" && Font_suffix="\033[0m"
Info="${Green_font}[Info]${Font_suffix}"
Error="${Red_font}[Error]${Font_suffix}"
reboot="${Yellow_font}重启${Font_suffix}"
echo -e "${Green_font}
#================================================
# Project:  tcp_nanqinlang general
# Modified by: LeitboGioro
# Platform: --Debian --KVM
# Branch:   --pro
# Version:  3.4.2.1
# Author:   nanqinlang
# Blog:     https://sometimesnaive.org
# Github:   https://github.com/nanqinlang
#================================================
${Font_suffix}"

dpkg_updates="/var/lib/dpkg/updates"
sort="?C=M;O=A"
kernel_url="https://kernel.ubuntu.com/~kernel-ppa/mainline/"
cert_file="index"

check_system(){
	#cat /etc/issue | grep -q -E -i "debian" && release="debian"
	#[[ "${release}" != "debian" ]] && echo -e "${Error} only support Debian !" && exit 1
	[[ -z "`cat /etc/issue | grep -iE "debian"`" ]] && echo -e "${Error} only support Debian !" && exit 1
}

check_root(){
	[[ "`id -u`" != "0" ]] && echo -e "${Error} must be root user !" && exit 1
}

check_kvm(){
    if [ -f `$dpkg_updates` ]; then
	    rm -r /var/lib/dpkg/updates
	    mkdir /var/lib/dpkg/updates
    fi
	apt-get update
	apt-get install -y virt-what ca-certificates apt-transport-https -y 
	#virt=`virt-what`
	#[[ "${virt}" = "openvz" ]] && echo -e "${Error} OpenVZ not support !" && exit 1
	[[ "`virt-what`" != "kvm" ]] && echo -e "${Error} only support KVM !" && exit 1
}

directory(){
	[[ ! -d /home/tcp_nanqinlang ]] && mkdir -p /home/tcp_nanqinlang
	cd /home/tcp_nanqinlang
}

get_version(){
    wget -O ${cert_file} ${kernel_url}${sort}
	get_kernel_ver=`awk '{print $5}' index | grep "v4.9." | sed -n '$p' | sed -r 's/.*href=\"(.*)\">v4.9.*/\1/' | sed 's/.$//' | sed 's/^.//g'`
	echo -e "${Info} 输入你想要的内核版本号(仅支持版本号: 4.9.3 ~ 4.13.16，目前 4.9.179 存在问题，选择 4.9.179 版本会被自动替换成 4.9.178):"
	if [[ ${get_kernel_ver} == "4.9.179" ]]; then
	    get_kernel_ver="4.9.178"
	fi
	read -p "(输入版本号，例如: ${get_kernel_ver}，默认安装 v${get_kernel_ver}):" required_version
	if [[ ${required_version} == "4.9.179" ]]; then
	    required_version="4.9.178"
	fi
	[[ -z "${required_version}" ]] && required_version=${get_kernel_ver}
	rm -rf ${cert_file}
}

get_url(){
	get_version
	headers_all_name=`wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v${required_version}/ | grep "linux-headers" | awk -F'\">' '/all.deb/{print $2}' | cut -d'<' -f1 | head -1`
	headers_all_url="http://kernel.ubuntu.com/~kernel-ppa/mainline/v${required_version}/${headers_all_name}"
	bit=`uname -m`
	if [[ "${bit}" = "x86_64" ]]; then
		image_name=`wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v${required_version}/ | grep "linux-image" | grep "lowlatency" | awk -F'\">' '/amd64.deb/{print $2}' | cut -d'<' -f1 | head -1`
		image_url="http://kernel.ubuntu.com/~kernel-ppa/mainline/v${required_version}/${image_name}"
		headers_bit_name=`wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v${required_version}/ | grep "linux-headers" | grep "lowlatency" | awk -F'\">' '/amd64.deb/{print $2}' | cut -d'<' -f1 | head -1`
		headers_bit_url="http://kernel.ubuntu.com/~kernel-ppa/mainline/v${required_version}/${headers_bit_name}"
	elif [[ "${bit}" = "i386" ]]; then
		image_name=`wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v${required_version}/ | grep "linux-image" | grep "lowlatency" | awk -F'\">' '/i386.deb/{print $2}' | cut -d'<' -f1 | head -1`
		image_url="http://kernel.ubuntu.com/~kernel-ppa/mainline/v${required_version}/${image_name}"
		headers_bit_name=`wget -qO- http://kernel.ubuntu.com/~kernel-ppa/mainline/v${required_version}/ | grep "linux-headers" | grep "lowlatency" | awk -F'\">' '/i386.deb/{print $2}' | cut -d'<' -f1 | head -1`
		headers_bit_url="http://kernel.ubuntu.com/~kernel-ppa/mainline/v${required_version}/${headers_bit_name}"
	else
		echo -e "${Error} not support bit !" && exit 1
	fi
}

libssl(){
# for Kernel Headers
	echo -e "\ndeb http://ftp.us.debian.org/debian jessie main\c" >> /etc/apt/sources.list
	apt-get update && apt-get install -y libssl1.0.0
	sed  -i '/deb http:\/\/ftp\.us\.debian\.org\/debian jessie main/d' /etc/apt/sources.list
	#mv /etc/apt/sources.list /etc/apt/sources.list.backup
	#echo -e "\ndeb http://cdn-fastly.deb.debian.org/ jessie main\c" > /etc/apt/sources.list
	#apt-get update && apt-get install -y libssl1.0.0
	#sed  -i '/deb http:\/\/cdn-fastly\.deb\.debian\.org\/ jessie main/d' /etc/apt/sources.list
	#mv -f /etc/apt/sources.list.backup /etc/apt/sources.list
	apt-get update
}

gcc4.9(){
# for Debian 7
	#sys_ver=`grep -oE  "[0-9.]+" /etc/issue`
	if [[ "`grep -oE  "[0-9.]+" /etc/issue`" = "7" ]]; then
		mv /etc/apt/sources.list /etc/apt/sources.list.backup
		wget https://raw.githubusercontent.com/nanqinlang/sources.list/master/hk.sources.list && mv hk.sources.list /etc/apt/sources.list
		apt-get update && apt-get install -y build-essential
		mv -f /etc/apt/sources.list.backup /etc/apt/sources.list
		apt-get update
	else
		apt-get install -y build-essential
	fi
}

delete_surplus_image(){
	for((integer = 1; integer <= ${surplus_total_image}; integer++))
	do
		 surplus_sort_image=`dpkg -l|grep linux-image | awk '{print $2}' | grep -v "${required_version}" | head -${integer}`
		 apt-get purge -y ${surplus_sort_image}
	done
	apt-get autoremove -y
	if [[ "${surplus_total_image}" = "0" ]]; then
		 echo -e "${Info} uninstall all surplus images successfully, continuing"
	fi
}

delete_surplus_headers(){
	for((integer = 1; integer <= ${surplus_total_headers}; integer++))
	do
		 surplus_sort_headers=`dpkg -l|grep linux-headers | awk '{print $2}' | grep -v "${required_version}" | head -${integer}`
		 apt-get purge -y ${surplus_sort_headers}
	done
	apt-get autoremove -y
	if [[ "${surplus_total_headers}" = "0" ]]; then
		 echo -e "${Info} uninstall all surplus headers successfully, continuing"
	fi
}

install_image(){
	if [[ -f "${image_name}" ]]; then
		 echo -e "${Info} deb file exist"
	else echo -e "${Info} downloading image" && wget ${image_url}
	fi
	if [[ -f "${image_name}" ]]; then
		 echo -e "${Info} installing image" && dpkg -i ${image_name}
	else echo -e "${Error} image download failed, please check !" && exit 1
	fi
}

install_headers(){
	if [[ -f ${headers_all_name} ]]; then
		 echo -e "${Info} deb file exist"
	else echo -e "${Info} downloading headers_all" && wget ${headers_all_url}
	fi
	if [[ -f ${headers_all_name} ]]; then
		 echo -e "${Info} installing headers_all" && dpkg -i ${headers_all_name}
	else echo -e "${Error} headers_all download failed, please check !" && exit 1
	fi

	if [[ -f ${headers_bit_name} ]]; then
		 echo -e "${Info} deb file exist"
	else echo -e "${Info} downloading headers_bit" && wget ${headers_bit_url}
	fi
	if [[ -f ${headers_bit_name} ]]; then
		 echo -e "${Info} installing headers_bit" && dpkg -i ${headers_bit_name}
	else echo -e "${Error} headers_bit download failed, please check !" && exit 1
	fi
}

#check/install required version and remove surplus kernel
check_kernel(){
	get_url

	#when kernel version = required version, response required version number.
	digit_ver_image=`dpkg -l | grep linux-image | awk '{print $2}' | awk -F '-' '{print $3}' | grep "${required_version}"`
	digit_ver_headers=`dpkg -l | grep linux-headers | awk '{print $2}' | awk -F '-' '{print $3}' | grep "${required_version}"`

	#total digit of kernel without required version
	surplus_total_image=`dpkg -l|grep linux-image | awk '{print $2}' | grep -v "${required_version}" | wc -l`
	surplus_total_headers=`dpkg -l|grep linux-headers | awk '{print $2}' | grep -v "${required_version}" | wc -l`

	if [[ -z "${digit_ver_image}" ]]; then
		 echo -e "${Info} installing required image" && install_image
	else echo -e "${Info} image already installed a required version"
	fi

	if [[ "${surplus_total_image}" != "0" ]]; then
		 echo -e "${Info} removing surplus image" && delete_surplus_image
	else echo -e "${Info} no surplus image need to remove"
	fi

	if [[ "${surplus_total_headers}" != "0" ]]; then
		 echo -e "${Info} removing surplus headers" && delete_surplus_headers
	else echo -e "${Info} no surplus headers need to remove"
	fi

	if [[ -z "${digit_ver_headers}" ]]; then
		 echo -e "${Info} installing required headers" && install_headers
	else echo -e "${Info} headers already installed a required version"
	fi

	update-grub
}

dpkg_list(){
	echo -e "${Info} 这是当前已安装的所有内核的列表："
    dpkg -l | grep linux-image   | awk '{print $2}'
    dpkg -l | grep linux-headers | awk '{print $2}'
	echo -e "${Info} 这是需要安装的所有内核的列表：\nlinux-image-${required_version}-lowlatency\nlinux-headers-${required_version}\nlinux-headers-${required_version}-lowlatency"
	echo -e "${Info} 请确保上下两个列表一致！"
}

ver_current(){
	[[ ! -f /lib/modules/`uname -r`/kernel/net/ipv4/tcp_nanqinlang.ko ]] && compiler
	[[ ! -f /lib/modules/`uname -r`/kernel/net/ipv4/tcp_nanqinlang.ko ]] && echo -e "${Error} load mod failed, please check !" && exit 1
}
compiler(){
	#mkdir make && cd make

	# kernel source code：https://www.kernel.org/pub/linux/kernel
	# kernel v4.13.x is different from the other older kernel
	ver_4_13=`dpkg -l | grep linux-image | awk '{print $2}' | awk -F '-' '{print $3}' | grep "4.13"`
	if [[ ! -z "${ver_4_13}" ]]; then
		wget https://raw.githubusercontent.com/tcp-nanqinlang/general/master/General/Debian/source/kernel-v4.13/tcp_nanqinlang.c
	else
		wget https://raw.githubusercontent.com/tcp-nanqinlang/general/master/General/Debian/source/kernel-v4.12andbelow/tcp_nanqinlang.c
	fi

	[[ ! -f tcp_nanqinlang.c ]] && echo -e "${Error} failed download tcp_nanqinlang.c, please check !" && exit 1

	#sys_ver=`grep -oE  "[0-9.]+" /etc/issue`
	if [[ "`grep -oE  "[0-9.]+" /etc/issue`" = "9" ]]; then
		wget -O Makefile https://raw.githubusercontent.com/tcp-nanqinlang/general/master/Makefile/Makefile-Debian9
	else
		wget -O Makefile https://raw.githubusercontent.com/tcp-nanqinlang/general/master/Makefile/Makefile-Debian7or8
	fi

	[[ ! -f Makefile ]] && echo -e "${Error} failed download Makefile, please check !" && exit 1

	make && make install
}

check_status(){
	#status_sysctl=`sysctl net.ipv4.tcp_congestion_control | awk '{print $3}'`
	#status_lsmod=`lsmod | grep nanqinlang`
	if [[ "`lsmod | grep nanqinlang`" != "" ]]; then
		echo -e "${Info} tcp_nanqinlang is installed !"
			if [[ "`sysctl net.ipv4.tcp_congestion_control | awk '{print $3}'`" = "nanqinlang" ]]; then
				 echo -e "${Info} tcp_nanqinlang is running !"
			else echo -e "${Error} tcp_nanqinlang is installed but not running !"
			fi
	else
		echo -e "${Error} tcp_nanqinlang not installed !"
	fi
}



###################################################################################################
install(){
	check_system
	check_root
	check_kvm
	directory
	gcc4.9
	libssl
	check_kernel
	dpkg_list
	echo -e "${Info} 确认内核安装无误后, ${reboot}你的VPS, 开机后再次运行该脚本的第二项！"
	reboot
}

start(){
	check_system
	check_root
	check_kvm
	directory
	ver_current
	sed -i '/net\.core\.default_qdisc/d' /etc/sysctl.conf
	sed -i '/net\.ipv4\.tcp_congestion_control/d' /etc/sysctl.conf
	echo -e "\n#Enable BBR Congestion Control Protocol" >> /etc/sysctl.conf
	echo -e "net.core.default_qdisc=fq" >> /etc/sysctl.conf
	echo -e "net.ipv4.tcp_congestion_control=nanqinlang\c" >> /etc/sysctl.conf
	sysctl -p
	check_status
	rm -rf /home/tcp_nanqinlang
}

optimize(){
    if [[ ! `cat /etc/rc.local | grep "ulimit -n 51200"` ]] || [ ! -d "/etc/rc.local" ]; then
        ulimit -n 51200 && echo ulimit -n 51200 >> /etc/rc.local
    fi

    if [[ ! `cat /etc/security/limits.conf | grep "* soft nofile 51200"` ]]; then
        echo "* soft nofile 51200" >> /etc/security/limits.conf
    fi

    if [[ ! `cat /etc/security/limits.conf | grep "* hard nofile 51200"` ]]; then
        echo "* hard nofile 51200" >> /etc/security/limits.conf
    fi

    if [[ ! `cat /etc/sysctl.conf | grep "#TCP Optimizations"` ]] && [[ ! `cat /etc/sysctl.conf | grep "fs.file-max = 51200"` ]]; then
        echo -e '\n' >> /etc/sysctl.conf
cat >> /etc/sysctl.conf<<-EOF
#TCP Optimizations
#Optimize File System Operation Performance
fs.file-max = 51200
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.rmem_default = 65536
net.core.wmem_default = 65536
net.core.netdev_max_backlog = 8192
net.core.somaxconn = 8192
#Enhance Network Transport/Exchange Performance
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_fin_timeout = 600
net.ipv4.tcp_keepalive_time = 10800
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mem = 25600 51200 102400
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_mtu_probing = 1
net.ipv4.ip_local_port_range = 1 65536
#END OF LINE
EOF
    fi
    sysctl -p >/dev/null 2>&1
    echo "Optimizations are finished, exiting......"
    exit 1
}

status(){
	check_status
}

uninstall(){
	check_root
	sed -i '/net\.core\.default_qdisc=/d'          /etc/sysctl.conf
	sed -i '/net\.ipv4\.tcp_congestion_control=/d' /etc/sysctl.conf
	sysctl -p
	rm  /lib/modules/`uname -r`/kernel/net/ipv4/tcp_nanqinlang.ko
	echo -e "${Info} please remember ${reboot} to stop tcp_nanqinlang !"
}

echo -e "${Info} 选择你要使用的功能: "
echo -e "1.安装内核\n2.安装并开启算法\n3.优化网络参数\n4.检查算法运行状态\n5.卸载算法"
read -p "输入数字以选择:" function

while [[ ! "${function}" =~ ^[1-5]$ ]]
	do
		echo -e "${Error} 无效输入"
		echo -e "${Info} 请重新选择" && read -p "输入数字以选择:" function
	done

if   [[ "${function}" == "1" ]]; then
	install
elif [[ "${function}" == "2" ]]; then
	start
elif [[ "${function}" == "3" ]]; then
        optimize
elif [[ "${function}" == "4" ]]; then
	status
else
	uninstall
fi
