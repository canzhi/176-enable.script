/etc/rc.d/
├── rc.local				#开机后,所有其他初始化服务都启动后,才执行这个脚本;我们可以将自定义的任务放到这.
├── run_service.sh		＃根启动脚本
└── start_all_service.sh　　＃能力平台启动脚本



在rc.local中追加一行

```shell
/etc/rc.d/run_service.sh
```



