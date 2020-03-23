#!/bin/bash

mas(){
 echo -e  "\033[36m 1,2为免密钥登陆 \033[0m"
 echo '1) 生成密钥'
 echo '2) 密钥复制'
 echo '3)复制hosts文件到客户端'
 echo '4)时间同步'
 read -p '请输入一个数:' num
 case $num in
  1)
   mercury
   ;;
  2)
   copykey
   ;;
  3)
   copyhosts
   ;;
  4)
   timesyn
   ;;
  *)
   ;;
 esac

}

mercury(){
/usr/bin/expect<<EOF
  set time 30
  spawn ssh-keygen
  expect {
         "/root/.ssh/id_rsa"  {send "\r";exp_continue}
         "empty for no passphrase" {send "\r";exp_continue}
         "Enter same passphrase again:"  {send "\r"}
         }
  expect  eof
EOF
}
#复制密钥
copykey(){
name='192.168.0.140'
while read -a line
do
 if [ "${line[0]}" != "$name" ]
 then 
   ./ex.exp ${line[0]}
 fi 
done </etc/hosts
}
copyhosts(){
 name=`hostname`
 while read -a line
 do
  if [ "${line[1]}" != "$name" ];then
   scp /etc/hosts ${line[1]}:/etc/
  fi
 done</etc/hosts 
}
#时间同步
timesyn(){
  name=`hostname`
  ip='192.168.0.140'
  yum install ntp -y
  sed -i  '/centos.pool.ntp.org/s/^/#&/' /etc/ntp.conf
  sed  -i '/restrict/s/#/ /' /etc/ntp.conf
  sed -i '24a\fudge 127.127.1.0 stratum 10' /etc/ntp.conf
  sed -i '24a\server 127.127.1.0'  /etc/ntp.conf
  sed -i "/noquery/s/default/$ip/" /etc/ntp.conf
  sed -i '/mask/d' /etc/ntp.conf
  sed -i "16a\restrict `netstat -rn  | awk '{print $2}' | awk 'NR==3{print}'`  mask 255.255.255.0 nomodify notrap" /etc/ntp.conf
  systemctl start ntpd
  systemctl enable ntpd
  while read -a line
  do
    if [ "$name" != "${line[1]}" ];then 
      ssh ${line[1]}  "yum install ntp -y" </dev/null
      ssh ${line[1]}  "sed -i '/centos.pool.ntp.org/s/^/#&/' /etc/ntp.conf"  </dev/null
      ssh ${line[1]}  "sed  -i '/restrict/s/#/ /' /etc/ntp.conf" </dev/null
      ssh ${line[1]}  "sed -i "/noquery/s/default/${line[0]}/"  /etc/ntp.conf" </dev/null
      ssh ${line[1]}  "sed -i  '24a\fudge $ip  stratum 10'  /etc/ntp.conf" </dev/null
      ssh ${line[1]}  "sed -i  '24a\server $ip'  /etc/ntp.conf" </dev/null
      ssh ${line[1]}  "sed -i '/mask/d' /etc/ntp.conf" </dev/null
      ssh ${line[1]}  "sed -i '16a\restrict `netstat -rn  | awk '{print $2}' | awk 'NR==3{print}'` mask 255.255.255.0 nomodify notrap' /etc/ntp.conf" </dev/null
      ssh ${line[1]}   systemctl start ntpd </dev/null
      ssh ${line[1]}   systemctl enable ntpd </dev/null
    fi
 done</etc/hosts
}
mas
