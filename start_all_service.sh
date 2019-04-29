#!/bin/sh

#Author:Chen Xiaohui
#Date:2019-04-28

##### 注意:一定要将本文件上传到灵云智能能力平台的bin/目录下 #####

HCICLOUD_HOME="/home/hcicloud8216/cloud/"
source ~/.bash_profile

cd $HCICLOUD_HOME/bin/

./servicefx_license_server -d
./servicefx_slb -d
./servicefx_http_server -d
./servicefx_mrcp_svc -d
./servicefx_asr_cp -d
./servicefx_nlu -d
./servicefx_nlu_sync -d
