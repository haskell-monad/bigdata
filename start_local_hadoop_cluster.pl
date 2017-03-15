#! /usr/bin/perl 

use 5.01;


sub start{
	my $command_list = [
		#启动zk集群
		"/usr/local/perl/bin/atnodes -u hadoop \"/usr/local/bigdata/zookeeper/bin/zkServer.sh start\" bigdata-[1002-1004]",	
		#启动JournalNode集群
		"/usr/local/perl/bin/atnodes -u hadoop \"/usr/local/bigdata/hadoop-2.6.0/sbin/hadoop-daemon.sh start journalnode\" bigdata-[1001-1003]",
		#启动hadoop001
		"/usr/local/perl/bin/atnodes -u hadoop \"/usr/local/bigdata/hadoop-2.6.0/sbin/hadoop-daemon.sh start namenode\" bigdata-1001",
		#启动hadoop002
		"/usr/local/perl/bin/atnodes -u hadoop \"/usr/local/bigdata/hadoop-2.6.0/sbin/hadoop-daemon.sh start namenode\" bigdata-1002",
		#启动hadoop003
		"/usr/local/perl/bin/atnodes -u hadoop \"/usr/local/bigdata/hadoop-2.6.0/sbin/hadoop-daemon.sh start namenode\" bigdata-1003",
		#启动hadoop004
		"/usr/local/perl/bin/atnodes -u hadoop \"/usr/local/bigdata/hadoop-2.6.0/sbin/hadoop-daemon.sh start namenode\" bigdata-1004",
		#启动所有的DataNode
		"/usr/local/perl/bin/atnodes -u hadoop \"/usr/local/bigdata/hadoop-2.6.0/sbin/hadoop-daemons.sh start datanode\" bigdata-1001",
		#启动Yarn
		"/usr/local/perl/bin/atnodes -u hadoop \"/usr/local/bigdata/hadoop-2.6.0/sbin/start-yarn.sh\" bigdata-1001",
		#启动JobHistory Server
		"/usr/local/perl/bin/atnodes -u hadoop \"/usr/local/bigdata/hadoop-2.6.0/sbin/mr-jobhistory-daemon.sh start historyserver\" bigdata-1001",
		#启动ZooKeeperFailoverController
		"/usr/local/perl/bin/atnodes -u hadoop \"/usr/local/bigdata/hadoop-2.6.0/sbin/hadoop-daemon.sh start zkfc\" bigdata-[1001-1004]",
	];
	say "*******************************************************";
	say "开始启动Hadoop集群....";
	my $command_exec = undef;
	foreach my $command (@$command_list){
		$command_exec = `$command`;
	}
	say "启动Hadoop集群完成....";
	say "*******************************************************";
	status();
	say "NameNode：";
	say "	http://192.168.98.120:50070";
	say "	http://192.168.98.201:50070";
	say "	http://192.168.98.57:50070";
	say "	http://192.168.99.92:50070";
	say "Yarn：";
	say "	http://192.168.98.120:8088/cluster";
	say "NodeManager: ";
	say "	http://192.168.98.201:8042/node";
	say "	http://192.168.98.57:8042/node";
	say "	http://192.168.99.92:8042/node";
}

sub stop{
	my $command_list = [
		#关闭hadoop集群
		"/usr/local/perl/bin/atnodes -u hadoop \"/usr/local/bigdata/hadoop-2.6.0/sbin/stop-all.sh\" bigdata-1001",
		#关闭Zookeeper
		"/usr/local/perl/bin/atnodes -u hadoop \"/usr/local/bigdata/zookeeper/bin/zkServer.sh stop\" bigdata-[1002-1004]",
		#关闭ZooKeeperFailoverController
		"/usr/local/perl/bin/atnodes -u hadoop \"/usr/local/bigdata/hadoop-2.6.0/sbin/hadoop-daemon.sh stop zkfc\" bigdata-[1001-1004]",
		#打印进程
		"/usr/local/perl/bin/atnodes -u hadoop \"/usr/local/jvm/java/bin/jps\" bigdata-[1001-1004]",
	];
	say "**********************************************************";
	say "开始关闭Hadoop集群....";
	my $command_exec = undef;
        foreach my $command (@$command_list){
                $command_exec = `$command`;
        }
	say "完成关闭Hadoop集群....";
	say "***********************************************************";
	status();
}

sub status{
	my $command_list = [
		#查看zk集群
		"/usr/local/perl/bin/atnodes -u hadoop \"/usr/local/bigdata/zookeeper/bin/zkServer.sh status\" bigdata-[1002-1004]",
		#查看进程
		"/usr/local/perl/bin/atnodes -u hadoop \"/usr/local/jvm/java/bin/jps\" bigdata-[1001-1004]",
		#查看集群内存信息
		"/usr/local/perl/bin/atnodes -u hadoop \"free;df;\"bigdata-[1001-1004]",
	];
	say "**********************************************************";
        say "开始检测Hadoop集群....";
        my $command_exec = undef;
        foreach my $command (@$command_list){
                $command_exec = `$command`;
		say $command_exec;
        }
        say "完成检测Hadoop集群信息....";
        say "***********************************************************";
}		

my $method = $ARGV[0];
if($method eq "start"){
	start();
}elsif($method eq "stop"){
	stop();
}elsif($method eq "status"){
	status();
}else{
	say "please Use: \n\t perl start_local_hadoop_cluster.pl (start | stop | status)";
}


























