#!/bin/bash
#A script for initial the arch minmal

# set bash option
#set -nx
#set -o errexit
set -o nounset
set -o errtrace
set -o pipefail

# root permission prompt
if [[ ! $EUID = 0 ]] 
then
  echo "We are sorry but you must be root to run the arch initial script."
  exit
fi

# alert
alert(){
  printf "You are suggested to run this script in tmux.\n\n"
  read -p "Are you sure to continue? [Yes | No]: " choice
  case ${choice} in
    [Yy]|[Yy]es)
      ;;
    *)
      echo "Farewell ashen one."
      exit
  esac

  clear
  echo "Here we go!"
  sleep 0.5
}

alert

# location
get_location(){
  if curl -s myip.ipip.net | grep -q '中国'
  then
    location=China
    echo "Oops, your server is inside GFW."
  else
    location=Worldwide
    echo "Congratulations, your server connect to the true network."
  fi
}

get_location

# setup the system environment 
envset(){
  if [[ $(hostname) = "localhost" ]]
  then
    echo "Hostname has not been set yet."
    read -p "Set your hostname here: " hostname
    hostnamectl set-hostname ${hostname}
  fi

  if [[ "${location}" = "China" ]]
  then 
    timedatectl set-timezone Asia/Shanghai
  else
    echo "Your current time zone is: $(timedatectl | awk '/zone/ {print $3}')"
    echo "Need a change?(Asia/Shanghai for example.)"
    echo "######BLANK or wrong format will keep it DEFAULT######"
    read -p "set your timezone here: " timezone
    case ${timezone} in
      [A-Z]*/[A-Z]*)
        if timedatectl set-timezone ${timezone}
        then
          echo "Your time zone has been set as ${timezone}."
        fi
        ;;
      "")
        echo "We did not chang the time zone."
        ;;
    esac
  fi

  localectl set-locale LANG="en_US.UTF-8"
  sed -i s/#en_US.UTF-8/en_US.UTF-8/g /etc/locale.gen
  locale-gen 1>/dev/null
}

envset

# set DNS for the system
china_dns(){
  dnsconf=/etc/resolv.conf
  if lsattr ${dnsconf} | grep -q i
  then
    echo "${dnsconf} was unable to modify."
  else
    cat >${dnsconf}<<-EOF
options timeout:1 attempts:1 rotate
nameserver 180.76.76.76
nameserver 119.29.29.29
nameserver 223.5.5.5
EOF
    chattr +i ${dnsconf}
    echo "System DNS has been update."
  fi
}

setdns(){
  if [[ "${location}" = "China" ]]
  then
    china_dns
  fi
}

setdns

# update the mirrorlist to the local sever
mirrorupdate(){
  mirrorlist=/etc/pacman.d/mirrorlist
  if [[ ! -f ${mirrorlist} ]]
  then
    touch ${mirrorlist}
  fi

  if ! grep -q 'reflector -f' ${mirrorlist}
  then
    mv ${mirrorlist} ${mirrorlist}.bak
    echo "Updating the mirrorlist ..."
    echo "It will take a hell lot of time just keep waiting ..."
    echo "The time spent depends on your network performance."
    echo "Normally less then 5 minutes."
    reflector -f 5 --save ${mirrorlist}
    echo "mirrorlist has been seccessfully updated"
  fi
}

mirrorupdate

# enable AUR
aur(){
  aurconf=/etc/pacman.conf
  if ! grep -q archlinuxfr ${aurconf}
  then
    cat >>$aurconf<<-EOF

    [archlinuxfr]
    SigLevel = Never
    Server = http://repo.archlinux.fr/\$arch
EOF
  echo "AUR has been successfully enabled."
  fi
}

aur

# BBR enable
bbr_enable(){
  bbrconf=/etc/sysctl.d/99-sysctl.conf
  touch ${bbrconf}
  cat >${bbrconf}<<-EOF
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
EOF

  sysctl --system 1>/dev/null
  echo "BBR has been successfully enable."
}

bbr_enable

# install the base-devel
arch_devel(){
  echo "Arch base-devel is proccessing installing, please be patients."
  echo "The time spent depends on your network performance."
  echo "Normally less then 5 minutes."
  pacman -Sy base-devel python-pip tmux vim lua nmap yaourt zmap git zsh \
    bash-completion net-tools dnsutils vnstat htop bc shadowsocks-libev zip \
    simple-obfs unzip haveged lsof rsync strace httpie gnu-netcat strace \
    nghttp2 the_silver_searcher jq tcpdump shellcheck speedtest-cli inxi \
    thefuck --noconfirm &>/dev/null
}

arch_devel

# http proxy for shell
ss_local(){
  pacman -Sy polipo --noconfirm &>/dev/null
  echo "Here we do some magic to bypass the GFW."
  read -p "ss-libev server: " server
  read -p "server_port: " serverport
  read -p "encrypt method: " method
  read -sp "password: " password
  printf "\n"
  read -p "local_port: " localport
  cat >/etc/shadowsocks.json<<-EOF
{
  "server":"${server}",
  "server_port":${serverport},
  "method":"${method}",
  "password":"${password}",
  "plugin":"obfs-local",
  "plugin_opts":"obfs=tls;obfs-host=www.baidu.com",
  "timeout":60,
  "local_port":${localport}
}
EOF
  echo "shadowsock.json done."

  cat >/etc/systemd/system/shadowsocks.service<<-EOF
[Uint]
Description=Shadowsocks-libev
Wants=network-online.target
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/ss-local -c /etc/shadowsocks.json -u --fast-open

[Install]
WantedBy=multi-user.target
EOF
  echo "shadowsock.service done."

  cat >/etc/polipo/config<<-EOF
proxyAddress = "0.0.0.0"
socksParentProxy = "localhost:8119"
socksProxyType = socks5
proxyPort = 1087
EOF
  echo "polipo.conf done."

  systemctl daemon-reload
  systemctl enable shadowsocks
  systemctl enable polipo
  systemctl start shadowsocks
  systemctl start polipo

  cat >>.bashrc<<-EOF
#http proxy
proxy(){
  no_proxy="127.0.0.1, localhost"
  export http_proxy="http://127.0.0.1:1087"
  export https_proxy=\$http_proxy
}

noproxy(){
  unset http_proxy
  unset https_proxy
}
EOF
}

gfw(){
  if [[ "${location}" = "China" ]]
  then
    ss_local
    echo "Fuck this forshaken land."
  fi
}

gfw

# ss_server
ss_server(){
  ss_serverconf=/etc/shadowsocks.json

  if telnet ds.test-ipv6.com 79 &>/dev/null
  then
    ipv6=true
  else
    ipv6=false
  fi

  read -p "input the amount of user account: " amount

  cat >${ss_serverconf}<<-EOF
{
  "server":["[::0]", "0.0.0.0"],
  "port_password":{
EOF

  for ((i=0; i<${amount}; i++))
  do
    read -p "port: " port
    read -sp "passwd: " passwd
    echo ""
    cat >>${ss_serverconf}<<-EOF
    "${port}":"${passwd}",
EOF
  done

  sed -i '$ s/,//' ${ss_serverconf}

  cat >>${ss_serverconf}<<-EOF
  },
  "_comment":{
    "left":"behind"
  },
  "timeout":600,
  "method":"aes-256-gcm",
  "fast_open":true,
  "plugin":"obfs-server",
  "plugin_opts":"obfs=tls",
  "dns_ipv6":${ipv6},
  "workers":${amount}
}
EOF
  echo "${amount} users added."

  ssservice=/etc/systemd/system/shadowsocks.service

  if [[ "${ipv6}" = "true" ]]
  then
    cat >${ssservice}<<-EOF
[Uint]
Description=Shadowsocks-libev
Wants=network-online.target
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/ss-manager --manager-address /tmp/ss-manager.sock --executable /usr/bin/ss-server -c /etc/shadowsocks.json -u -6 --fast-open

[Install]
WantedBy=multi-user.target
EOF
  else
    cat >${ssservice}<<-EOF
[Uint]
Description=Shadowsocks-libev
Wants=network-online.target
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/ss-manager --manager-address /tmp/ss-manager.sock --executable /usr/bin/ss-server -c /etc/shadowsocks.json -u --fast-open

[Install]
WantedBy=multi-user.target
EOF
  fi

  echo "ss_server setup successfully, enjoy it."
  systemctl daemon-reload
  systemctl enable shadowsocks
  systemctl start shadowsocks
}

set_ssserver(){
if [[ "${location}" = "Worldwide" ]]
then
  read -p "Your server is fine to set a ss_server, would you? [Yes | No]: " willing
  case ${willing} in
    [Yy]|[Yy]es)
      ss_server
      ;;
    *)
      echo "Nothing done."
      ;;
  esac
fi
}

set_ssserver

# add normal user
normal_user(){
  printf "Add a normal user:\n######BLANK to skip######\n"
  read -p "Set your username: " username
  case ${username} in
    [a-z]*)
      useradd -c ${username} -m -g users -G wheel -s $(which zsh) ${username}
      passwd ${username}
      mkdir /home/${username}/.ssh
      touch /home/${username}/.ssh/authorized_keys
      sed -i 's/^#%wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
      echo "Paste certificate and end with a blank line:"
      sshkey=$(sed '/^$/q')
      echo ${sshkey} >> /home/${username}/.ssh/authorized_keys
      echo "SSH Key has been added."
      chown -R ${username}:users /home/${username}/.ssh
      chmod 600 /home/${username}/.ssh/authorized_keys
      echo "User ${username} setup successfully."
      ;;
    ""|*[A-Z]*|*[0-9]*)
      echo "Wrog input."
      echo "You have not set a normal user, that's not a good idea."
      ;;
  esac
}

normal_user

# harden ssh
harden_ssh(){
  read -p "Define your SSH port: " sshport
  sshconf=/etc/ssh/sshd_config
  sed -i 's/^#Port 22/'"Port ${sshport}"'/' ${sshconf}
  sed -i 's/PermitRootLogin yes/PermitRootLogin no/' ${sshconf}
  sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' ${sshconf}
  sed -i 's/^#PermitEmptyPasswords no/PermitEmptyPasswords no/' ${sshconf}
  echo "Harden SSH finished."
}

whatever_ssh(){
  if [[ -n ${username} ]]
  then
    echo ${username}
    harden_ssh
  fi
}

whatever_ssh

# change into multi-user mode
systemctl set-default multi-user.target

# goodbye
sync
echo "Ashen one hearest thou my voice, still?"
