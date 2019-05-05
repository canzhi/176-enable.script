#!/bin/sh

#Author:Chen Xiaohui
#Date:2019-04-28

##### 全局变量 #####

##### 防火墙的全局变量 #####
#IPTABLES_HOME="/root"
#IPTABLES_ACCOUNT="root"

##### redis的全局变量 #####
REDIS_HOME="/usr/local/redis"
REDIS_ACCOUNT="root"

#####　jTTS的全局变量 #####
jTTS_HOME="/home/hcitts/jTTS-6.3.8"
jTTS_ACCOUNT="hcitts"

##### MRCP的全局变量 #####
MRCP_HOME="/home/hcitts/unimrcp"
MRCP_ACCOUNT="hcitts"


##### FreeSWITCH的全局变量 #####
FREESWITCH_HOME="/usr/local/freeswitch"
FREESWITCH_ACCOUNT="root"

##### ES的全局变量 #####
ES_HOME="/usr/local/elasticsearch"
ES_ACCOUNT="hcicloud"


##### Tomcat的全局变量 #####
TOMCAT_HOME="/usr/local/apache-tomcat-7.0.42"
TOMCAT_ACCOUNT="root"
TOMCAT_SERVER_IP="10.248.17.6"
TOMCAT_PORT="8080"

##### 能力平台的全局变量 #####
HCICLOUD_HOME="/home/hcicloud8216/cloud"
HCICLOUD_ACCOUNT="hcicloud8216"

##### Nginx的全局变量 #####
#NGINX_HOME="/usr/local/nginx"
NGINX_ACCOUNT="root"
NGINX_SERVER_IP="10.248.17.6"
NGINX_PORT="8666"

##### 小睿的全局变量 #####
XR_HOME="/root/dev"
XR_ACCOUNT="root"



LOG_DATE=`date "+%Y-%m-%d"`
LOG_FILE="/var/log/run_service.${LOG_DATE}.log"

if [ ! -f ${LOG_FILE} ];then
	touch ${LOG_FILE}
fi

function LOG() {
	message=$1
	LOG_TIME=`date "+%Y-%m-%d %H:%M:%S"`
	echo "${LOG_TIME} ${message}" |  tee -a ${LOG_FILE}	
}



##### 检测Tomcat redis 启动ES服务状态并尝试循环启动####
for i in `seq 10`
do
	LOG "第$i次检测"
	sleep 1

	##### 1.启动防火墙 #####
	#LOG "准备启动防火墙"
	#IPTABLES_NUM=`iptables -nL | wc -l`
	#if [ ${IPTABLES_NUM} -ne 8 ];then
	#	LOG "防火墙已启动"
	#else
	#	LOG "正在启动防火墙"
	#	cd ${IPTABLES_HOME}
	#	./add_iptables.sh
	#	sleep 10
	#fi

	##### 2.启动redis #####
	LOG "准备启动redis..."
	REDIS_NUM=`ps -ef |grep redis-server |grep -v grep | wc -l`
	if [ ${REDIS_NUM} -ne 0 ];then
		LOG "redis服务已启动"
	else
		LOG "正在启动redis... ..."
		#su - ${REDIS_ACCOUNT} -c "cd ${REDIS_HOME};./redis-server ./redis.conf" 
		cd ${REDIS_HOME}
		./redis-server ./redis.conf
		sleep 10
	fi
	

	##### 4.启动jTTS #####
	LOG "准备启动jTTS..."
	jTTS_NUM=`ps -ef | grep "jTTSService4.exe" |grep -v grep |grep ${jTTS_ACCOUNT} |wc -l`
	if [ ${jTTS_NUM} -ne 0 ];then
		LOG "jTTS服务已启动"
	else
		LOG "正在启动jTTS... ..."
		su - ${jTTS_ACCOUNT} -c "cd ${jTTS_HOME}/bin/;./jtts.sh start"
		sleep 10
	fi

	##### 5.启动MRCP #####
	LOG "准备启动MRCP"
	MRCP_NUM=`ps -ef |grep unimrcpserver |grep -v grep |grep ${MRCP_ACCOUNT} |wc -l`
	if [ ${MRCP_NUM} -ne 0 ];then
		LOG "MRCP服务已启动"
	else
		LOG "正在启动MRCP... ..."
		su - ${MRCP_ACCOUNT} -c "cd ${MRCP_HOME}/bin/;./mrcp.sh start"
		sleep 10
	fi

	##### 6.启动FreeSWITCH #####
	LOG "准备启动FreeSWITCH..."
	FREESWITCH_NUM=`ps -ef | grep freeswitch |grep -v grep |wc -l`
	if [ ${FREESWITCH_NUM} -ne 0 ];then
		LOG "FreeSWITCH服务已启动"
	else
		LOG "正在启动FreeSWITCH... ..."
		cd ${FREESWITCH_HOME}/bin/
		./freeswitch -nc
		sleep 10
	fi

	##### 7.启动ES #####
	LOG "准备启动Elasticsearch..."
	ES_NUM=`ps -ef |grep  java | grep -v grep |grep ${ES_HOME} |wc -l `
	if [ ${ES_NUM} -ne 0 ];then
		LOG "Elasticsearch服务已启动"
	else 
		LOG "正在启动Elasticsearch... ..."
		su - ${ES_ACCOUNT} -c "cd ${ES_HOME}/bin/;./elasticsearch -d -p pid"
		sleep 5
	fi

	##### 8.启动Tomcat #####
	LOG "准备启动tomcat..."
	nc -z -w 10 ${TOMCAT_SERVER_IP} ${TOMCAT_PORT}   
	if [ $? -eq 0 ];then
		LOG "Tomcat服务已启动"
	else
		LOG "正在启动Tomcat... ..."
		cd ${TOMCAT_HOME}/bin/
		./startup.sh
		sleep 20
	fi
done


##### 8.启动能力平台 #####
LOG "启动所有能力组件..."
HCICLOUD_NUM=`ps -ef |grep servicefx | grep -v grep |wc -l`
if [ ${HCICLOUD_NUM} -ne 7 ];then
	su - ${HCICLOUD_ACCOUNT} -c "cd /etc/rc.d/;./start_all_service.sh"
fi
sleep 5

# 检查能力组件是否启动
NAME_LIST="servicefx_license_server servicefx_slb servicefx_http_server servicefx_mrcp_svc servicefx_asr_cp servicefx_nlu servicefx_nlu_sync"
for PROCESS_NAME in ${NAME_LIST}
do
	SERVICE_NUM=`ps -ef |grep ${PROCESS_NAME} |grep -v grep |wc -l`
	if [ ${SERVICE_NUM} -ne 0 ];then
		LOG "启动${PROCESS_NAME}成功"
	else
		LOG "启动${PROCESS_NAME}失败"
		exit
	fi
done


##### 其他任务 #####
LOG "启动其他服务..."
##### 9.启动Nginx #####
LOG "准备启动Nginx服务..."
nc -z -w 10 ${NGINX_SERVER_IP} ${NGINX_PORT}  
if [ $? -eq 0 ];then
	LOG "Nginx服务已启动"
else
	LOG "正在启动Nginx... ..."
	nginx
	sleep 5
fi


##### 10.启动小睿平台 ##### 
LOG "准备启动小睿平台..."
XR_NUM=`ps -ef |grep xrserver |grep -v grep |wc -l`
if [ ${XR_NUM} -ne 0 ];then
	LOG "小睿平台已启动"
else
	LOG "正在启动小睿平台... ..."
	cd ${XR_HOME}
	XR_PACKAGE=`ls -tr *.jar |tail -1`
	nohup java -jar "${XR_PACKAGE}" &
fi

LOG "开机启动完毕"