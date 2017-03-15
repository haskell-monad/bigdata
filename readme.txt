使用perl编写的hadoop集群部署工具，可以使用正则匹配多个域名和ip并行部署
bigdata目录是web操作页面，部署成功后会生成相应服务器拓扑图，需导入mysql表bigdata.sql

1、将root.software.rar解压出来的内容放到/root/software目录下
2、mysql依赖
#yum -y install mysql mysql-server mysql-devel
#yum install perl-DBD-mysql
3、脚本相关文件放到/root/bigdata目录下
--------/root/software
--------/root/bigdata
		-----ConfigUtil.pm
		-----DBUtil.pm
		-----LogUtil.pm
		-----db.properties			配置信息
		-----bigdata.sql			mysql表结构（需导入mysql）

		-----install_perl_sshbatch.sh		安装perl相关依赖
			2、需手动安装以下依赖
			#cpan install DBI
			#cpan install DBD::mysql
			#cpan install Expect;
		-----install_hadoop.pl			安装hadoop集群
		-----start_local_hadoop_cluster.pl	启动hadoop集群

3、结构
service =>
        Hadoop => NameNode
        Hadoop => DataNode
        Hadoop => JournalNode
        Hadoop => ResourceManager
        Hadoop => NodeManager
        Hadoop => HistoryServer
nodeinfo =>
        Hive_Hive =>
                node_name => Hive
                node_type => Hive
                ip =>
                port => 22
                passwd => ikang
                user => root
        Hadoop_JournalNode =>
                ip => 192.168.98.[120,57,201]
                port => 22
                user => root
                passwd => ikang
                node_name => JournalNode
                node_type => Hadoop
        Hadoop_NameNode =>
                passwd => ikang
                user => root
                port => 22
                ip => 192.168.98.[120,57,201] 192.168.99.92
                node_type => Hadoop
                node_name => NameNode
        Hadoop_ResourceManager =>
        Hadoop_DataNode =>
                node_type => Hadoop
                node_name => DataNode
                user => root
                passwd => ikang
                port => 22
                ip => 192.168.98.[57,201] 192.168.99.92
        Zookeeper_Zookeeper =>
                node_name => Zookeeper
                node_type => Zookeeper
                ip => 192.168.98.[57,201] 192.168.99.92
                port => 22
                user => root
                passwd => ikang
        Hadoop_HistoryServer =>
app_ips =>
        Zookeeper =>
                192.168.99.92 => bigdata-1007
                192.168.98.201 => bigdata-1005
                192.168.98.57 => bigdata-1006
        Hadoop =>
                192.168.99.92 => bigdata-1004
                192.168.98.120 => bigdata-1001
                192.168.98.201 => bigdata-1002
                192.168.98.57 => bigdata-1003
        Hive =>

