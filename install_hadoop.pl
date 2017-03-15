#! /usr/bin/perl

#安装依赖
#yum -y install mysql mysql-server mysql-devel
#cpan install DBI
#cpan install DBD::mysql
#cpan install Expect;
#yum install perl-DBD-mysql

use 5.010;

use Time::HiRes qw(gettimeofday);
use Expect;
#use UUID::Random;
use File::Basename;
use ConfigUtil;
use DBUtil;
use LogUtil;
#http://www.th7.cn/system/lin/201402/50472.shtml
my $log = new LogUtil(FH,'> install.log');#获取日志句柄
my $config = new ConfigUtil(DB,'< db.properties',$log);#读取配置文件
my $db = new DBUtil($config,$log);#获取数据库连接句柄

#my $perl_install_dir = $config->get('perl_install_dir');#perl安装bin目录
#my $hadoop_install_dir = $config->get('hadoop_install_dir');#hadoop默认安装目录
#my $global_hadoop_user = $config->get('global_hadoop_user');#hadoop用户
#my $os_hadoop_pass = $config->get('os_hadoop_pass');#hadoop用户密码
#my $global_hive_port = $config->get('global_hive_port');#hive端口号

#my $install_template_dir = $config->get('install_template_dir');#模版文件所在目录

#my $os_root_pass = $config->get('os_root_pass');#系统root用户密码
#my $app_install_dir = $config->get('app_install_dir');#安装程序所在目录
#my $remote_upload_dir = $config->get('remote_upload_dir');#远程上传临时目录
#my $java_install_dir = $config->get('java_install_dir');#java安装目录

#my $global_hostname_prefix = $config->get('global_hostname_prefix');#节点hostname的前缀


my $perl_install_dir = '/usr/local/perl';#perl安装bin目录
my $hadoop_install_dir = '/usr/local/bigdata';#hadoop默认安装目录
my $global_hadoop_user = 'hadoop';#hadoop用户
my $os_hadoop_pass = 'ikang';#hadoop用户密码
my $global_hive_port = '55550';#hive端口号

my $os_root_pass = 'ikang';#系统root用户密码
my $app_install_dir = '/root/software';#安装程序所在目录
my $install_template_dir = "$app_install_dir/conf";#模版文件所在目录
my $remote_upload_dir = '/tmp';#远程上传临时目录
my $java_install_dir = '/usr/local/jvm';#java安装目录

my $global_hostname_prefix = 'bigdata-';#节点hostname的前缀

my $hadoop_dir_name = 'hadoop-2.6.0';#hadoop文件目录名

my $hadoop_install_name = 'bigdata_install_hadoop.tar.gz';#使用的Hadoop文件名
my $jdk_install_name = 'bigdata_install_jdk.tar.gz';#使用的JDK文件名
my $zk_install_name = 'bigdata_install_zookeeper.tar.gz';#使用的zk文件名

my $bigdata_tmpfile = '/root/bigdata/bigdata_tmp';



#***********************全局变量定义开始**************************************
my $sequence = 1000;#主机hostname序列
my $cluster = 1;#group组自增序列（Hadoop HA 特性）
my $alices = 1;#别名自增序列（Hadoop HA 特性,NameNode别名）
my $zk_server = 0;#zookeeper自增序列

#active与standby的划分实际上是由zk决定的
my @active_nn = ();#保存所有的activeNameNode的hostname
my @active_nn_ip = ();#保存所有的activeNameNode的ip 启动时用
my @standby_nn = ();#保存所有的standbyNameNode的hostname
my @standby_nn_ip = ();#保存所有的standbyNameNode的ip 启动时用
my @start_param = ();#hadoop和yarn启动参数
my @result_array = ();
my @name_services = ();#保存所有的dfs.nameservices

my $jn_ip = undef;
my $jn_ip_array = [];
my $job_history_ip = undef;#启动hadoop集群用
my $job_history_hostname = undef;
my $resource_manager_ip = undef;#启动hadoop集群用
my $resource_manager_hostname = undef;

my $hive_ip = undef; # hive所在机器ip
my $hive_hostname = undef;#hive所在机器域名
#***********************全局变量定义结束**************************************


#***********************数据结构定义开始**************************************
#存放所有应用的数组
my @service = [];
my $hash_ip={
	ips => {
		#192.168.10.13[6-9] => undef,
		#192.168.10.13[6-8] => undef,
		#192.168.10.13[6-8] => undef,
	},
	ip => {#集群所有去重后的ip
		#192.168.10.136 => undef,
		#192.168.10.137 => undef,
		#192.168.10.137 => undef,
	},
	localhost => undef,#当前机器ip
};
my $data = {
	#服务信息
	service => {
		#Hadoop => [NameNode,DataNode,JournalNode],
		#HBase => [...],
	},
	#节点信息
	nodeinfo => {
		#Hadoop_NameNode => {
		#	ip => '192.168.10.13.[6-9] 192.168.22.140 192.168.11.140',#支持多个空格分割的ip
		#	user => root,
		#	passwd => limengyu,
		#	port => 22,
		#	nodetype => Hadoop,
		#	nodename => NameNode,
		#}
	},
	app_ips => {
		#Hadoop => {
			#192.168.10.130 => host001, #去重后的ip、主机名映射
			#192.168.10.131 => host002,
		#},
	}
};
my %all_ip_hostname = ();
#***********************数据结构定义结束*****************************************
#初始化数据结构
sub init{
	#查询出所有的父节点
	my $table = $db->execute("select id,name from bigdata_node_type where pid = 0 order by id asc;");
	init_data_service($table,0,undef);
	
	#my @keys = keys $data->{service};
	#foreach $item(@keys){
	foreach my $item(@$service){
		$table = $db->execute("select ip,port,user,passwd,node_type,node_name". 
					" from bigdata_ssh_info".
					" where node_type = '$item' and install_status = 0;");
		init_data_nodeinfo($table);
	}
	#获取当前机器ip
#	my $ip = `ifconfig eth0|grep -oE '([0-9]{1,3}\.?){4}'|head -n 1`;
#	if ($ip) {
#		$hash_ip->{localhost}=$ip;
#	}
}

#递归获取server服务
#$table结果集
#$type=0代表父节点
#$p_name=父类名称
sub init_data_service{
	my ($table,$type,$p_name) = @_;
	foreach my $row (@$table) {
		my $id = $row->[0];
		my $name = $row->[1];
		$log->info("--------------$id------$name------$p_name--------");
		if (!$type) {
			#父节点
			$data->{service}->{$name} = [];
			push(@$service,$name);
			my $son_table = $db->execute("select id,name from bigdata_node_type where pid = ".$id." order by id asc");
			init_data_service($son_table,1,$name);
		}else{
			#p_name:Hadoop name:NameNode
			push($data->{service}->{$p_name},$name);
		}
	}
}

#获取nodeinfo服务
sub init_data_nodeinfo{
	my $table = shift;
	foreach $row (@$table) {
		my $ip = $row->[0];
		my $port = $row->[1];
		my $user = $row->[2];
		my $passwd = $row->[3];
		my $node_type = $row->[4];
		my $node_name = $row->[5];
		$hash_ip->{ips}->{$ip} = undef;#?
		$data->{nodeinfo}->{$node_type."_".$node_name}{ip} = $ip;
		$data->{nodeinfo}->{$node_type."_".$node_name}{port} = $port;
		$data->{nodeinfo}->{$node_type."_".$node_name}{user} = $user;
		$data->{nodeinfo}->{$node_type."_".$node_name}{passwd} = $passwd;
		$data->{nodeinfo}->{$node_type."_".$node_name}{node_type} = $node_type;
		$data->{nodeinfo}->{$node_type."_".$node_name}{node_name} = $node_name;
		if (ref($data->{app_ips}->{$node_type}) ne "HASH") {
			$data->{app_ips}->{$node_type} = {};
		}
		if ($ip) {
			my $ip_array = parse_ips($ip);#解析ip字符串成数组
			foreach $item (@$ip_array) {
				unless (exists($data->{app_ips}->{$node_type}{$item})) {
					#配置主机ip和主机域名的映射
					if (exists $all_ip_hostname{$item}) {
						$data->{app_ips}->{$node_type}->{$item} = $all_ip_hostname{$item};
					}else{
						my $currhostname = $global_hostname_prefix.++$sequence;
						$all_ip_hostname{$item} = $currhostname;
						$data->{app_ips}->{$node_type}->{$item} = $all_ip_hostname{$item};
					}
				}
			}
		}
	}
}

#执行命令（应用名称、执行的命令、命令描述）
sub exec_command{
	my ($appname,$command,$desc) = @_;
	$log->info("开始执行应用<$appname>的命令<$desc>：".$command);
	my $obj = Expect->spawn($command) or $log->info("Expect Couldn't exec command:$command.");
	#$obj->exp_internal(1);
	my ($pos,$err,$match,$before,$after) = $obj->expect(10,
			[ qr/Password:/i,
			  sub{ my $self = shift; $self->send("$os_root_pass\r"); exp_continue;}
			]
	);
	$obj->soft_close();		
	$log->info("完成执行应用<$appname>的命令<$desc>：");	
}


#执行命令（应用名称、执行的命令、命令描述）
sub exec_commands{
	my ($appname,$command,$desc) = @_;
	$log->info("开始执行应用<$appname>的命令<$desc>：".$command);
	my $command_exec = `$command`;
	$log->info("完成执行应用<$appname>的命令<$desc>：".$command_exec);	
}

#打印哈希
sub print_hash{
	my $hash = shift;
	while (($k, $v) = each %$hash) {
		say "$k =>";
		if (ref($v) eq 'HASH') {
			while (($x, $y) = each %$v) {
				if (ref($y) eq 'HASH') {
					say "\t$x => ";
					while (($z, $x) = each %$y) {
						if (ref($x) eq 'HASH') {
							say "\t\t$z => ";
						}else{
							say "\t\t$z => $x";
						}
					}
				}else{
					foreach $item (@$y) {
						say "\t$x => $item";
					}
				}
			}
		}else{
			say "\t$k => $v";
		}
	}
}

#打印数组service
sub print_service{
	my ($name,$array) = @_;
	say "数组$name：----->";
	foreach my $item (@$array) {
		if (ref($item) eq "ARRAY") {
			say "子数组：----->";
			print_service("",$item);
		}else{
			say "\t$item";
		}
	}
}

#修改某个用户的配置文件（.bashrc_profile）
#参数如：hadoop,'192.168.10.140 192.168.10.14[2-3] 192.168.10.144',
#$app_hash = {
#	'HIVE_HOME' => $hadoop_install_dir/hive,
#	'HADOOP_HOME' => $hadoop_install_dir/hadoop,
#}
#/usr/local/perl/bin/atnodes -u hadoop 'cat ~/.bash_profile' 192.168.98.57 192.168.99.92 192.168.98.201
#/usr/local/perl/bin/tonodes -u hadoop -L .bash_profile 192.168.98.57 192.168.99.92 192.168.98.201:/home/hadoop/.bash_profile
sub update_bashrc_profile{
	my ($username,$ipstr,$app_hash) = @_;
	my $targetfile = "/home/$username/.bash_profile";
	my @path_array = ();
	if (ref($app_hash) eq 'HASH') {
		while (my ($app_home,$app_path) = each %$app_hash) {
			#1.清理$APP_HOME、添加$APP_HOME
			#my $update_home_command = "/bin/sed -i -e '/$app_home=/d' -e '/PATH=/i export $app_home=$app_path' $targetfile;";
			my $update_home_command = $perl_install_dir."/bin/atnodes -L -w -u $username \"/bin/sed -i -e '/$app_home=/d' -e '/PATH=/i export $app_home=$app_path' $targetfile;\" $ipstr";
			exec_command("未知",$update_home_command,"修改配置文件$targetfile");
			if ($app_home =~ m/[A-Z]+_HOME$/g) {
				push(@path_array,":\\\${$app_home}\\\/bin");
			}
		} 
		#在每个节点上执行sed替换并添加:${APP_HOME}/bin
		foreach my $app_home(@path_array) {
			my $config_bashrc_command = $perl_install_dir."/bin/atnodes -w -L -u $username '/bin/sed -i -e \"s/$app_home//g\" -e \"/PATH=/s/\\\$/$app_home/\" $targetfile;source $targetfile;' $ipstr";
			exec_command("未知",$config_bashrc_command,"修改配置文件(添加$app_home)$targetfile");
		}
	}
}

#清理jdk安装目录和/etc/profile文件
sub clean_jdk{
	my ($appname,$ips) = @_;
	my $clean_command = $perl_install_dir."/bin/atnodes -w -L  -u root \"/bin/rm -rf ".$java_install_dir.";/bin/sed -i \"/JAVA_HOME=/d\" /etc/profile;/bin/sed -i \"/JRE_HOME=/d\" /etc/profile;/bin/sed -i \"/CLASSPATH=/d\" /etc/profile;/bin/sed -i \"/JAVA_HOME/d\" /etc/profile;/bin/sed -i \"/^\$/d\" /etc/profile;source /etc/profile;\" $ips";
	exec_command($appname,$clean_command,"清理JDK");
}

#清理hadoop用户和hadoop安装目录和/host/hadoop/.bash_profile文件
sub clean_hadoop_user{
	my $ips = shift;
	my $clear_command = $perl_install_dir."/bin/atnodes -w -L  -u root \" /usr/sbin/userdel -r $global_hadoop_user;/bin/rm -rf $hadoop_install_dir/$hadoop_dir_name;\" ".$ips;
	exec_command("Hadoop",$clear_command,"清理Hadoop用户");
}

#将数组$array转换成以$flag分割字符串
#默认以空格分割
sub array2str{
	my ($array,$flag) = @_;
	if (ref($array) eq 'ARRAY') {
		if (!$flag) {
			$flag = " ";
		}
		return join($flag,@$array);
	}
}

#创建安装目录,并且将安装文件解压到安装目录
sub init_install_dir{
	my $filename = shift;
	unless (-e $hadoop_install_dir) {
		my $create_init_dir_command = "/bin/mkdir $hadoop_install_dir;";
		my $create_init_dir_exec = `$create_init_dir_command`; 
	}
	my $unpack_command = "/bin/tar -xzvf $app_install_dir/$filename -C $hadoop_install_dir/";
	my $unpack_exec = `$unpack_command`;
}

#写k-v到某个文件
sub generate_key_value{
	my ($filename,$hash) = @_;
	my $command = undef;
	my $command_exec = undef;
	while (my ($key,$value) = each %$hash) {
		$command = "/bin/echo \"$key=$value\" >> $filename";
		$command_exec = `$command`;
	}
}

#向本地某个文件写入数据
sub echo_native_file{
	my ($file,$array) = @_;
	my $command = undef;
	my $command_exec = undef;
	foreach my $str (@$array) {
		$command = "/bin/echo \"$str\" >> $file";
		$command_exec = `$command`;
	}
}

#打包本地文件
#把$dir打包成$package
#pack_file('hive.tar.gz','hive');
sub pack_file{
	my ($package,$dir) = @_;	
	my $new_pack = "cd $hadoop_install_dir;/bin/tar -zcvf $package $dir";
	my $new_pack_exec = `$new_pack`;
}

#在hdfs上创建目录
sub mkdir_hdfs_dir{
	my $dir_name = shift;
	my $mkdir_command = $perl_install_dir."/bin/atnodes -w -L  -u $global_hadoop_user '$hadoop_install_dir/bin/hadoop fs -mkdir -R $dir_name ' ".$active_nn[0];
	exec_command("Hadoop",$mkdir_command,"在HDFS上创建目录");
}

#配置root用户ssh无密码登录
#$hash={ip=>hostname}
sub ssh_login_root{
	my ($app_name,$ipstr) = @_;
	my $ssh_command = $perl_install_dir."/bin/key2nodes -u root $ipstr";
	#$log->info("--------------应用： $app_name 开始批量配置 root 用户的ssh无密码登录！--------------$ssh_command");	
	#my $ssh_command_exec = `$ssh_command`;
	exec_command($app_name,$ssh_command,"批量配置 root 用户的ssh无密码登录");
	#$log->info("--------------应用： $app_name 完成批量配置 root 用户的ssh无密码登录！--------------");
}
#sub ssh_login_root{
	#my ($app_name,$ipstr) = @_;
	#my $ssh_command = "su - root -c \"$perl_install_dir/bin/key2nodes -u root $ipstr\"";
	#$log->info("--------------应用： $app_name 开始批量配置 root 用户的ssh无密码登录！--------------$ssh_command");
	#my $obj = Expect->spawn($ssh_command) or $log->info("Couldn't exec command:$ssh_command.");
	##$obj->exp_internal(1);
	#my ( $pos, $err, $match, $before, $after ) = $obj->expect(10,
			#[
				#'connecting (yes/no)',   
				 #sub { 
					#my $self = shift; 
					#$self->send("yes\n"); 
				 #} 
			#],
			#[
				#'Enter file in which to save the key',
				#sub{
						#my $self = shift;
						#$self->clear_accum();
						#exp_continue;
				#}
			#],
			#[
				#'Enter passphrase \\(empty for no passphrase\\): ',
				#sub{
						#my $self = shift;
						#$self->send("\r");
						#exp_continue;
				#}
			#],
			#[
				#'Enter same passphrase again: ',
				 #sub{
						#my $self = shift;
						#$self->send("\r");
						#exp_continue;
				#}
			#],
			#[ qr/[Pp]{1}assword:/i,
			  #sub{ my $self = shift; $self->send("$os_root_pass\r"); exp_continue;}
			#]
	#);
	#$obj->soft_close( );		
	#$log->info("--------------应用： $app_name 完成批量配置 root 用户的ssh无密码登录！--------------");
#}


#配置ssh无密码登录
#$hash={ip=>hostname}
sub ssh_login{
	my ($app_name,$user,$passwd,$ipstr) = @_;
	
	my $ssh_command = "su - $user -c \"$perl_install_dir/bin/key2nodes -u $user $ipstr\"";
	$log->info("--------------应用： $app_name 开始批量配置 $user 用户的ssh无密码登录！--------------$ssh_command");
	my $obj = Expect->spawn($ssh_command) or $log->info("Couldn't exec command:$ssh_command.");
	#$obj->exp_internal(1);
	my ( $pos, $err, $match, $before, $after ) = $obj->expect(10,
			[ qr/Password:/i,
			  sub{ my $self = shift; $self->send("$passwd\r"); exp_continue;}
			]
	);
	$obj->soft_close( );		
	$log->info("--------------应用： $app_name 完成批量配置 $user 用户的ssh无密码登录！--------------");
}

#批量创建用户
#$username 创建的用户名
#$passwd 创建的用户名的密码
#$ipstr操作的节点ip
sub useradd{
	my ($appname,$username,$passwd,$ipstr) = @_;
	if ($username) {
		$log->info("--------------应用： $app_name 开始批量创建用户！--------------");
		#创建用户设置密码
		my $useradd_command = $perl_install_dir."/bin/atnodes -w -L  -u root \"/usr/sbin/useradd ".$username.";echo \"$passwd\"  |  passwd  --stdin  $username ;\" ".$ipstr;
		exec_command($appname,$useradd_command,"批量创建\"$username\"用户");
	}
}

#安装jdk #/usr/bin/java -> /etc/alternatives/java
#上传tar包，解压包，修改配置文件，测试是否安装成功
sub install_jdk{
	my ($app_name,$ipstr) = @_;
	$log->info("--------------应用： $app_name 开始安装JDK！--------------$ipstr");
	#my $bit = `/usr/bin/getconf LONG_BIT`;
	#if (!$bit) {
		#$bit = "64";#默认64位
	#}
	#chomp($bit);
	my $app_dir = $app_install_dir."/$jdk_install_name";#安装包所在目录
	my $upload_dir = $remote_upload_dir."/$jdk_install_name";#远程上传目录
	#my $java_bin = `which java`;
	#if ($java_bin !~ m#/usr/bin/java#) {#如果不存在
		my $java_bin = "/usr/bin/java";
	#}
	#chomp($java_bin);
	
	#上传
	my $upload_command = $perl_install_dir."/bin/tonodes -w -L $app_dir -u root \"$ipstr\":$remote_upload_dir/";
	exec_commands($app_name,$upload_command,"分发上传JDK文件");
	#解压、配置环境变量
	my $tar_command = $perl_install_dir."/bin/atnodes -w -L  -u root \"/bin/mkdir ".$java_install_dir.";/bin/tar -xzvf ".$upload_dir."  -C  ".$java_install_dir.";/bin/mv -f ".$java_bin." ".$java_bin.".old;/bin/ln -s ".$java_install_dir."/java/bin/java ".$java_bin.";chcon -t texrel_shlib_t ".$java_install_dir."/java/jre/lib/i386/client/libjvm.so;\" ".$ipstr;
	exec_commands($app_name,$tar_command,"解压JDK");
	
	my $config_command = $perl_install_dir."/bin/atnodes -w -L  -u root '/bin/echo \"export JAVA_HOME=".$java_install_dir."/java\" >> /etc/profile;/bin/echo \"export JRE_HOME=\\\${JAVA_HOME}/jre\" >> /etc/profile;/bin/echo \"export CLASSPATH=.:\\\${JAVA_HOME}/lib:\\\${JRE_HOME}/lib\" >> /etc/profile;/bin/echo \"export PATH=\\\${JAVA_HOME}/bin:\\\$PATH \" >> /etc/profile;source /etc/profile' ".$ipstr;
	exec_command($app_name,$config_command,"配置JDK环境变量");
	
	#测试安装是否成功
	my $test_command = $perl_install_dir."/bin/atnodes -w -L  -u root \"java -version\" ".$ipstr;
	exec_command($app_name,$test_command,"测试JDK是否安装成功");
	$log->info("--------------应用： $app_name 完成安装JDK！--------------$ipstr");
}

#配置hostname和hosts
sub clean_config_hosts{
	my ($appname,$ip_hostname_hash) = @_;
	$log->info("--------------应用： $app_name  开始配置hosts和hostname！--------------");
	my $ips = $data->{app_ips}->{$appname};#哈希，存放ip和hostname映射
	my $keys = [keys %$ip_hostname_hash];#存放所有ip的数组
	while (($ip, $hostname) = each %$ip_hostname_hash) {
		#1、清理配置文件/etc/hosts和/etc/sysconfig/network
		my $clean_command = $perl_install_dir."/bin/atnodes -w -L  -u root \"/bin/sed -i \"/$global_hostname_prefix/d\" /etc/hosts;sed -i \"/HOSTNAME=/d\" /etc/sysconfig/network;\" $ip";
		exec_command($appname,$clean_command,"清理\"$ip\"的hosts和hostname");
		#2、修改hostname配置文件
		my $hostname_command = $perl_install_dir."/bin/atnodes -w -L  -u root \"/bin/echo \"HOSTNAME=$hostname\" >> /etc/sysconfig/network;/bin/hostname $hostname\" $ip";
		exec_command($appname,$hostname_command,"配置\"$ip\"的hostname");
	}
	foreach my $item (@$keys) {
		$log->info("开始配置《 $item 》hosts.");		
		while (($k, $v) = each %$ips) {
			my $hosts_command = $perl_install_dir."/bin/atnodes -w -L  -u root \"/bin/echo  $k               $v  >> /etc/hosts \" $item";
			exec_command($appname,$hosts_command,"配置hosts");
		}
		$log->info("完成配置《 $item 》hosts.");
	}
	#3、刷新配置文件
	my $flush_command = $perl_install_dir."/bin/atnodes -w -L  -u root \"service network restart;\" $ip";
	my $flush_exec = `$flush_command`;
	$log->info("--------------应用： $app_name  完成配置hosts和hostname！--------------");
}

#上传文件
#上传的文件名$full_name
#目标目录$targetdir /usr/local
#是否解压$ispack TRUE or FALSE
#ip地址
sub uploadFile{
	my($full_name,$targetdir,$ispack,$ipstr) = @_;
	my $filename = basename($full_name);
	create_remote_dir($targetdir,$ipstr);
	my $upload_command = $perl_install_dir."/bin/tonodes -w -L ".$full_name." -u root ".$ipstr.":".$targetdir."/";
	exec_commands("未知",$upload_command,"上传文件$full_name");
	if ($ispack eq TRUE) {
		my $pack_command = $perl_install_dir."/bin/atnodes -w -L  -u root \"/bin/tar -xzvf ".$targetdir."/".$filename." -C $targetdir/;\" $ipstr";
		exec_commands("未知",$pack_command,"解压文件$full_name");
	}
}

#配置
#$filename 目录+文件名
#ip地址
#$type操作类型，1为清理，2为更新
sub updateConfig{
	my($ip,$type) = @_;
	my $update_command = "";
	if ($type eq '1') {
		$update_command = $perl_install_dir."/bin/atnodes -w -L  -u root \"/bin/rm -rf $perl_install_dir ;/bin/mv -f /usr/bin/perl.bigdata /usr/bin/perl; \" $ip";
	}elsif($type eq '2'){
		$update_command = $perl_install_dir."/bin/atnodes -w -L  -u root \"/bin/mv -f /usr/bin/perl /usr/bin/perl.bigdata;ln -s ".$perl_install_dir."/bin/perl /usr/bin/perl; \" $ip"; 
	}
	exec_command("未知",$update_command,"更新配置文件$filename");
}

#解析ip集合，返回数组
#ips=192.18.10.14.[0-9] 192.18.10.130 192.18.10.12.[0-3]
sub parse_ips{
	my $ips = shift;
	#$ips =~ s/,/ /g;
	my $parse_command = "$perl_install_dir/bin/fornodes $ips";
	my $parse_result = `$parse_command`;
	my @parse_array = split(/\s+/,$parse_result);
	return \@parse_array;
}

#生成property标签
sub generateXML{
	my ($full_name,$hash) = @_;
	$log->info("开始修改配置文件：".$full_name);
	my $str = undef;
	while (($key, $value) = each %$hash) {
		$str = $str."\t<property>\n\t\t<name>$key</name>\n\t\t<value>$value</value>\n\t</property>\n";
	}
	
	if ($str) {
		open TMP, ">$bigdata_tmpfile"; #写入文件名
		say TMP $str;
		close(TMP);
		my $insert_command = "/bin/sed -i '/<configuration>/r $bigdata_tmpfile' $full_name";
		exec_command("未知",$insert_command,"插入数据$full_name");
	}
	$log->info("完成修改配置文件：".$full_name);
}

#生成generateHDFSSite标签
#hdfs-site.xml文件中只能配置一个dfs.namenode.shared.edits.dir属性
#<name>dfs.namenode.shared.edits.dir</name> 
#<value>qjournal://hadoop002:8485;hadoop003:8485;hadoop004:8485/hadoop-cluster2</value> 
#$array数组引用
sub generateHDFSSite{
	my ($array,$journal_array,$ip_hostname_hash,$flag) = @_;
	my $full_name = $hadoop_install_dir."/hdfs-site.xml";
	my $str = "\t<property>\n\t\t<name>dfs.replication</name>\n\t\t<value>1</value>\n\t</property>\n";
	my $nameservice = "";
	my $nameservices = "";
	my $first_nn_alice = "";
	my $first_nn_hostname = "";
	my $second_nn_alice = "";
	my $second_nn_hostname = "";
	my $first_nn_ip = undef;
	my $second_nn_ip = undef;
	my $journal_str = "";
	foreach my $item (@$journal_array) {
		$journal_str = $journal_str.$ip_hostname_hash->{$item}.":8485;";
	}
	chop($journal_str);#去掉最后一个分号
	foreach my $item (@$array) {
		if (ref($item) eq "ARRAY") {
			#hadoop-cluster1,nn1,nn2,host1,host2,nn1_ip,nn2_ip
			#hadoop-cluster2,nn3,nn4,host3,host4,nn3_ip,nn4_ip
			$nameservice = @$item[0];
			$nameservices = $nameservices.$nameservice.",";
			$first_nn_alice = @$item[1];
			$second_nn_alice = @$item[2];
			$first_nn_hostname = @$item[3];
			$second_nn_hostname = @$item[4];
			$first_nn_ip = @$item[5];
			$second_nn_ip = @$item[6];
			$str = $str."\t<property>\n\t\t<name>dfs.ha.namenodes.$nameservice</name>\n\t\t<value>$first_nn_alice,$second_nn_alice</value>\n\t</property>\n";

			$str = $str."\t<property>\n\t\t<name>dfs.namenode.rpc-address.$nameservice.$first_nn_alice</name>\n\t\t<value>$first_nn_hostname:8020</value>\n\t</property>\n";

			$str = $str."\t<property>\n\t\t<name>dfs.namenode.rpc-address.$nameservice.$second_nn_alice</name>\n\t\t<value>$second_nn_hostname:8020</value>\n\t</property>\n";

			$str = $str."\t<property>\n\t\t<name>dfs.namenode.http-address.$nameservice.$first_nn_alice</name>\n\t\t<value>$first_nn_hostname:50070</value>\n\t</property>\n";

			$str = $str."\t<property>\n\t\t<name>dfs.namenode.http-address.$nameservice.$second_nn_alice</name>\n\t\t<value>$second_nn_hostname:50070</value>\n\t</property>\n";
			
			$str = $str."\t<property>\n\t\t<name>dfs.ha.automatic-failover.enabled.$nameservice</name>\n\t\t<value>true</value>\n\t</property>\n";

			$str = $str."\t<property>\n\t\t<name>dfs.client.failover.proxy.provider.$nameservice</name>\n\t\t<value>org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider</value>\n\t</property>\n";
			#特殊的属性值
			if ($flag eq $nameservice) {
				$str = $str."\t<property>\n\t\t<name>dfs.namenode.shared.edits.dir</name>\n\t\t<value>qjournal://$journal_str/$nameservice</value>\n\t</property>\n";
			}
		}
	}
	if ($nameservices) {
		chop($nameservices);
	}
	
	$str = "\t<property>\n\t\t<name>dfs.nameservices</name>\n\t\t<value>$nameservices</value>\n\t</property>\n".$str;
	$str = $str."\t<property>\n\t\t<name>dfs.namenode.name.dir</name>\n\t\t<value>file://$hadoop_install_dir/$hadoop_dir_name/tmp/namenode</value>\n\t</property>\n\t<property>\n\t\t<name>dfs.datanode.data.dir</name>\n\t\t<value>file://$hadoop_install_dir/$hadoop_dir_name/tmp/datanode</value>\n\t</property>\n\t<property>\n\t\t<name>dfs.ha.automatic-failover.enabled</name>\n\t\t<value>true</value>\n\t</property>\n\t<property>\n\t\t<name>dfs.journalnode.edits.dir</name>\n\t\t<value>$hadoop_install_dir/$hadoop_dir_name/tmp/journal/</value>\n\t</property>\n\t<property>\n\t\t<name>dfs.ha.fencing.methods</name>\n\t\t<value>sshfence</value>\n\t</property>\n\t<property>\n\t\t<name>dfs.ha.fencing.ssh.private-key-files</name>\n\t\t<value>/home/$global_hadoop_user/.ssh/id_rsa</value>\n\t</property>\n\t";

	open TMP, ">$bigdata_tmpfile"; #写入文件名
	say TMP $str;
	close(TMP);

	my $insert_command = "/bin/sed -i '/<configuration>/r $bigdata_tmpfile' $full_name";
	
	exec_command("未知",$insert_command,"插入数据$full_name");
}

#同步文件到相应节点
sub sync_node_file{
	my ($sourcefile,$node,$targetfile) = @_;
	my $upload_command = $perl_install_dir."/bin/tonodes -w -L -u root $sourcefile \"$node\":$targetfile";
	exec_command("未知",$upload_command,"同步文件到相应节点$targetfile");
}

#配置slaves文件
#所有的DataNode节点的hostname
sub generateSlaves{
	my $full_name = $hadoop_install_dir."/$hadoop_dir_name/etc/hadoop/slaves";
	my $command = undef;
	my $exec = undef;
	my $clear_command = "echo \"\" > $full_name";
	exec_command("Hadoop",$clear_command,"清理slaves文件");
	$log->info("开始配置slaves文件。");
	my $ipstr = $data->{nodeinfo}->{Hadoop_DataNode}->{ip};#获取所有的DataNode节点
	my $ip_hostname_hash = $data->{app_ips}->{Hadoop};#获取hadoop集群中的所有节点
	my $ip_array = parse_ips($ipstr);
	my $hostname = undef;
	foreach my $ip (@$ip_array) {
		$hostname = $ip_hostname_hash->{$ip};
		$command = "echo \"$hostname\" >> $full_name";
		$exec = `$command`;
	}
	$log->info("完成配置slaves文件。");
}

#创建远程目录
#ipstr ip字符串
#dir 需要创建的远程目录
sub create_remote_dir{
	my($dir,$ipstr) = @_;
	my $update_command = $perl_install_dir."/bin/atnodes -w -L  -u root \" mkdir $dir;\" $ipstr";
	exec_command("未知",$update_command,"创建远程目录$dir");
}

#修改远程文件的所属用户和所属用户组
sub update_remote_dir_auth{
	my ($file,$user,$group,$ipstr) = @_;
	my $update_command = $perl_install_dir."/bin/atnodes -w -L  -u root \" /bin/chown -R $user:$group $file \" $ipstr";
	exec_command("未知",$update_command,"修改文件所属用户和所属组$file");
}

#启动hadoop集群和yarn
#$start_param数组保存节点信息
#$jn_ip,$resource_manager_ip,$job_history_ip
sub start_hadoop_cluster{
	my $flag = shift;#是否需要初始化数据
	if ($flag eq TRUE) {
		init_hadoop_data();
	}
	$log->info("开始启动Hadoop集群....");
	my $nameservice = undef;
	my $first_nn_alice = undef;
	my $first_nn_ip = undef;
	my $first_nn_hostname = undef;
	my $second_nn_alice = undef;
	my $second_nn_ip = undef;
	my $second_nn_hostname = undef;
	my $hadoop_home = $hadoop_install_dir."/$hadoop_dir_name";#$hadoop_home
	#my $clusterId = "hadoop-cluster";#clusterId
	my $master_nn_ip = $start_param[0][2];#master_nn_ip,first_namenode_ip
	
	#step_0 启动zookeeper集群
	start_zk_cluster();

	#step_0_1格式化ZooKeeper集群，目的是在ZooKeeper集群上建立HA的相应节点。（在nn1和nn3节点上）
	my $formatzk_ip = array2str(\@active_nn_ip);
	my $formatzk_command = $perl_install_dir."/bin/atnodes -w -L  -u $global_hadoop_user \"$hadoop_home/bin/hdfs zkfc –formatZK\" $formatzk_ip";
	my $formatzk_command_exec = `$formatzk_command`;

	#step_1 启动JournalNode集群
	my $start_journalnode_command = $perl_install_dir."/bin/atnodes -w -L  -u $global_hadoop_user \"$hadoop_home/sbin/hadoop-daemon.sh start journalnode\" $jn_ip";
	exec_command("Hadoop",$start_journalnode_command,"开始启动journalnode服务");

	foreach my $item (@start_param) {
		if (ref($item) eq 'ARRAY') {
			$nameservice = @$item[0];
			$first_nn_alice = @$item[1];
			$first_nn_ip = @$item[2];
			$first_nn_hostname = @$item[3];
			$second_nn_alice = @$item[4];
			$second_nn_ip = @$item[5];	
			$second_nn_hostname = @$item[6];
			#step_2 格式化nn1，并启动
			my $first_nn_format_start_command = $perl_install_dir."/bin/atnodes -w -L  -u $global_hadoop_user \" $hadoop_home/bin/hdfs namenode -format -clusterId $nameservice;$hadoop_home/sbin/hadoop-daemon.sh start namenode; \" $first_nn_ip";
			my $first_nn_format_start_exec = `$first_nn_format_start_command`;
			$log->info("NameNode_$first_nn_alice 地址：http://$first_nn_ip:50070/");
			#step_3 在nn2上同步nn1的元数据信息 and step_4 启动nn2
			my $second_nn_sync_start_command = $perl_install_dir."/bin/atnodes -w -L  -u $global_hadoop_user \" $hadoop_home/bin/hdfs namenode -bootstrapStandby;$hadoop_home/sbin/hadoop-daemon.sh start namenode; \" $second_nn_ip";
			my $second_nn_sync_start_exec = `$second_nn_sync_start_command`;
			$log->info("NameNode_$second_nn_alice 地址：http://$second_nn_ip:50070/");
			#step_5	将nn1设置为ActiveNameNode（手动启动），改为由zookeeper启动
			#my $first_nn_active_command = $perl_install_dir."/bin/atnodes -w -L  -u $global_hadoop_user \" $hadoop_home/bin/hdfs haadmin -ns $nameservice -transitionToActive $first_nn_alice;\" $first_nn_ip";
			#my $first_nn_active_exec = `$first_nn_active_command`;
		}
	}
	#step_6 在nn1上启动所有的datanode
	if ($master_nn_ip) {
		my $master_nn_start_datanode = $perl_install_dir."/bin/atnodes -w -L  -u $global_hadoop_user \" $hadoop_home/sbin/hadoop-daemons.sh start datanode; \" $master_nn_ip";
		my $master_nn_start_exec = `$master_nn_start_datanode`;
	}
	#step_7 启动Yarn
	if ($resource_manager_ip) {
		my $yarn_start_command = $perl_install_dir."/bin/atnodes -w -L  -u $global_hadoop_user \" $hadoop_home/sbin/start-yarn.sh; \" $resource_manager_ip";
		exec_command("Hadoop",$yarn_start_command,"开始启动Yarn");
		$log->info("ResourceManager地址：http://$resource_manager_ip:8088/cluster");
		$log->info("NodeManager地址：http://\${NodeManagerip}:8042/node");
	}else{
		$log->info("没有配置resource_manager,跳过启动ResourceManager.");
	}
	#step_8 启动JobHistory Server
	if ($job_history_ip) {
		my $jobhistory_start_command = $perl_install_dir."/bin/atnodes -w -L  -u $global_hadoop_user \" $hadoop_home/sbin/mr-jobhistory-daemon.sh start historyserver; \" $job_history_ip";
		exec_command("Hadoop",$jobhistory_start_command,"开始启动JobHistory Server");
	}else{
		$log->info("没有配置JobHistory Server.,跳过启动JobHistory Server.");
	}
	#step_9在所有NameNode节点上启动ZooKeeperFailoverController，产生java进程DFSZKFailoverController
	my $all_nn_ip_array = parse_ips($data->{nodeinfo}->{Hadoop_NameNode}->{ip});
	my $all_nn_ip_str = array2str($all_nn_ip_array);
	my $start_controller_command = $perl_install_dir."/bin/atnodes -w -L  -u $global_hadoop_user \"$hadoop_home/sbin/hadoop-daemon.sh start zkfc;\" $all_nn_ip_str";
	exec_command("Hadoop",$start_controller_command,"开始启动ZooKeeperFailoverController");

	#step_10 执行jsp命令测试是否启动
	$log->info("完成启动Hadoop集群");
}

#初始化hadoop的一些数据
sub init_hadoop_data{
	$log->info("开始初始化Hadoop数据....");
	#2.获取所有的journalnode节点并存放到数组中
	$jn_ip = $data->{nodeinfo}->{Hadoop_JournalNode}->{ip};#可能是多个空格分割的ip地址
	$jn_ip_array = parse_ips($jn_ip);
	my $jn_ip_array_leg = scalar(@$jn_ip_array);
	if (!(($jn_ip_array_leg & 1) != 0 && $jn_ip_array_leg > 1)) {
		$log->info("JournalNode至少需要三台节点，并且需要使用奇数。");
	}
	#获取JobHistory节点的ip
	$job_history_ip = $data->{nodeinfo}->{Hadoop_HistoryServer}->{ip};#可能是多个空格分割的ip地址 应该只有一个ip
	if ($job_history_ip) {
		$job_history_hostname = $data->{app_ips}->{Hadoop}->{$job_history_ip};
	}
	#获取ResourceManager节点的ip
	$resource_manager_ip = $data->{nodeinfo}->{Hadoop_ResourceManager}->{ip};#可能是多个空格分割的ip地址 应该只有一个ip
	if ($resource_manager_ip) {
		$resource_manager_hostname = $data->{app_ips}->{Hadoop}->{$resource_manager_ip};
	}
	#3.获取所有的namenode节点并存放到数组中
	my $nn_ip = $data->{nodeinfo}->{Hadoop_NameNode}->{ip};#可能是多个空格分割的ip地址
	my $nn_ip_array = parse_ips($nn_ip);
	my $nn_ip_array_leg = scalar(@$nn_ip_array);

	my $ips = $data->{app_ips}->{Hadoop};#哈希，存放ip和hostname映射
	
	if ($nn_ip_array_leg > 0) {
		#说明有多个namenode，需要检查journalnode
		my $nn_group = 0;#分组数
		if ($nn_ip_array_leg % 2 == 0) {
			$nn_group = $nn_ip_array_leg / 2;
		}#else{
		#	$nn_group = ($nn_ip_array_leg / 2) + 1;
		#}
		my $first_nn_ip = undef;
		my $second_nn_ip = undef;
		my $first_nn_hostname = undef;
		my $second_nn_hostname = undef;
		my $nameservices = undef;
		my $first_nn_alice = undef;
		my $second_nn_alice = undef;
		for (my $k = 0; $k < $nn_group;$k++) {
			$first_nn_ip = shift @$nn_ip_array;
			$second_nn_ip = shift @$nn_ip_array;
			if ($first_nn_ip && $second_nn_ip) {
				$first_nn_hostname = $ips->{$first_nn_ip};
				$second_nn_hostname = $ips->{$second_nn_ip};
				$nameservices = "hadoop-cluster".$cluster++;
				$first_nn_alice = "nn".$alices++;
				$second_nn_alice = "nn".$alices++;
				push(@name_services,$nameservices);#生成hdfs-site.xml时用
				push(@active_nn,$first_nn_hostname);
				push(@active_nn_ip,$first_nn_ip);#启动时用
				push(@standby_nn,$second_nn_hostname);
				push(@active_nn_ip,$second_nn_ip);#启动时用
				push(@result_array,[$nameservices,$first_nn_alice,$second_nn_alice,$first_nn_hostname,$second_nn_hostname,$first_nn_ip,$second_nn_ip]);
				push(@start_param,[$nameservices,$first_nn_alice,$first_nn_ip,$first_nn_hostname,$second_nn_alice,$second_nn_ip,$second_nn_hostname]);
			}
		}
	}else{
		$log->info("没有配置NameNode,请配置。");
	}
	
	print_service("\@name_services",\@name_services);
	print_service("\@active_nn",\@active_nn);
	print_service("\@active_nn_ip",\@active_nn_ip);
	print_service("\@standby_nn",\@standby_nn);
	print_service("\@result_array",\@result_array);
	print_service("\@start_param",\@start_param);

	$log->info("完成初始化Hadoop数据....");
}

#安装hadoop
sub install_hadoop{
	my ($app_name,$ip_hostname_hash) = @_;
	my $ip_str = array2str([keys %$ip_hostname_hash]);#获取以空格分割ip字符串
	print_hash($ip_hostname_hash);
	#ssh_login_root($app_name,$ip_str);#配置root用户ssh登录
	clean_config_hosts($app_name,$ip_hostname_hash);#配置hosts和hostname
	clean_jdk($app_name,$ip_str);#安装前清理jdk
	install_jdk($app_name,$ip_str);#上传并安装jdk
	clean_hadoop_user($ip_str);#清理hadoop用户
	useradd($app_name,$global_hadoop_user,$os_hadoop_pass,$ip_str);#批量创建hadoop用户
	#ssh -l hadoop 192.168.10.140
	ssh_login($app_name,$global_hadoop_user,$os_hadoop_pass,$ip_str);#配置hadoop用户ssh登录
	#1.解压Hadoop安装包到Hadoop安装目录(目录不存在则创建)
	init_install_dir("$hadoop_install_name");
	#2.修改配置文件hadoop-env.sh
#	my $hadoop_env_sh_command = "/bin/sed -i -e \"/JAVA_HOME=/d\" -e \"/HADOOP_COMMON_LIB_NATIVE_DIR=/d\" -e \"/-Djava.library.path=/d\" -e \"/^\$/d\" ".$hadoop_install_dir."/$hadoop_dir_name/etc/hadoop/hadoop-env.sh;/bin/echo 'export JAVA_HOME=".$java_install_dir."/java \n export HADOOP_COMMON_LIB_NATIVE_DIR=\${HADOOP_HOME}/lib/native \n export HADOOP_OPTS=\"-Djava.library.path=\$HADOOP_HOME/lib\"' >> ".$hadoop_install_dir."/$hadoop_dir_name/etc/hadoop/hadoop-env.sh";
	my $hadoop_env_sh_command = "/bin/sed -i -e \"/JAVA_HOME=/d\" -e \"/^\$/d\" $hadoop_install_dir/$hadoop_dir_name/etc/hadoop/hadoop-env.sh;/bin/echo 'export JAVA_HOME=".$java_install_dir."/java' >> $hadoop_install_dir/$hadoop_dir_name/etc/hadoop/hadoop-env.sh;";
	my $hadoop_env_sh_exec = `$hadoop_env_sh_command`;
	
	#初始化hadoop数据
	#2.获取所有的journalnode节点并存放到数组中
	#获取JobHistory节点的ip
	#获取ResourceManager节点的ip
	#3.获取所有的namenode节点并存放到数组中
	init_hadoop_data();

	$log->info('@active_nn_ip: '.scalar(@active_nn_ip));

	if (scalar(@active_nn_ip) > 0) {
		my @zk_server_host = values $data->{app_ips}->{Zookeeper};#获取zk的主机名和端口
		my $zk_server_host_str = undef;
		foreach my $zk_host (@zk_server_host) {
			$zk_server_host_str .= $zk_host.":2888,";
		}
		chop($zk_server_host_str);#去掉最后一个逗号
		#配置core-site.xml
		my $core_site_hash = {
			#'fs.default.name' => "hdfs://".$active_nn[0].":8020",
			'fs.defaultFS' => $name_services[0],
			'hadoop.tmp.dir' => "$hadoop_install_dir/$hadoop_dir_name/tmp",
			'ha.zookeeper.quorum' => $zk_server_host_str,
		};
		generateXML("$hadoop_install_dir/$hadoop_dir_name/etc/hadoop/core-site.xml",$core_site_hash);
		#配置mapred-site.xml
		my $mapred_site_hash = {
			'mapreduce.framework.name' => "yarn",
			'mapreduce.jobhistory.address' => $job_history_hostname.":10020",
			'mapreduce.jobhistory.webapp.address'	=> $job_history_hostname.":19888",
		};
		generateXML("$hadoop_install_dir/$hadoop_dir_name/etc/hadoop/mapred-site.xml",$mapred_site_hash);
		#配置yarn-site.xml
		my $yarn_site_hash = {
			'yarn.resourcemanager.hostname' => "$resource_manager_hostname",
			'yarn.resourcemanager.address' => '${yarn.resourcemanager.hostname}:8032',
			'yarn.resourcemanager.scheduler.address'	=> '${yarn.resourcemanager.hostname}:8030',
			'yarn.resourcemanager.webapp.address'	=>	'${yarn.resourcemanager.hostname}:8088',
			'yarn.resourcemanager.webapp.https.address'		=>	'${yarn.resourcemanager.hostname}:8090',
			'yarn.resourcemanager.resource-tracker.address'		=>	'${yarn.resourcemanager.hostname}:8031',
			'yarn.resourcemanager.admin.address'	=>	'${yarn.resourcemanager.hostname}:8033',
			#'yarn.resourcemanager.scheduler.class'	=>	'org.apache.hadoop.yarn.server.resourcemanager.scheduler.fair.FairScheduler',
			#'yarn.scheduler.fair.allocation.file'	=>	'${yarn.home.dir}/etc/hadoop/fairscheduler.xml',
			'yarn.nodemanager.local-dirs'	=>	$hadoop_install_dir."/$hadoop_dir_name/tmp/yarn/local",
			'yarn.log-aggregation-enable'	=>	'true',
			'yarn.nodemanager.remote-app-log-dir'	=>	$hadoop_install_dir."/$hadoop_dir_name/tmp/nodemanager",
			'yarn.nodemanager.resource.memory-mb'	=>	30720,
			'yarn.nodemanager.resource.cpu-vcores'	=>	12,
			'yarn.nodemanager.aux-services'	=>	'mapreduce_shuffle',
		};
		generateXML("$hadoop_install_dir/$hadoop_dir_name/etc/hadoop/yarn-site.xml",$yarn_site_hash);
		
		#配置slaves（所有的DataNode节点hostname）
		generateSlaves();
		#打包配置好的Hadoop文件
		pack_file($hadoop_install_name,$hadoop_dir_name);
		#上传Hadoop文件到各个节点上、解压
		uploadFile("$hadoop_install_dir/$hadoop_install_name",$hadoop_install_dir,TRUE,$ip_str);
		
		#配置hdfs-site.xml
		#1.copy一个hdfs-site.xml模板到安装目录
		#2.根据nameservice生成对应节点的hdfs-site.xml文件
		#3.拷贝相应文件到相应节点上hadoop-cluster1:hadoop001:hadoop002
		foreach my $item (@result_array) {
			my $copy_command = "/bin/cp -f $install_template_dir/hdfs-site.xml $hadoop_install_dir";
			exec_commands($app_name,$copy_command,"拷贝hdfs-site.xml模板");
			my $hadoop_cluster_flag = @$item[0];
			#$hadoop_cluster_flag：hadoop-cluster1
			$log->info("\$hadoop_cluster_flag: $hadoop_cluster_flag");
			#$node_hostname: bigdata-[1001,1002]
			#my $node = $global_hostname_prefix."[".substr(@$item[3],length($global_hostname_prefix),length(@$item[3])-length($global_hostname_prefix)).",".substr(@$item[4],length($global_hostname_prefix),length(@$item[4])-length($global_hostname_prefix))."]";
			my $node = @$item[5]." ".@$item[6];
			$log->info("\$node_ip: $node");
			generateHDFSSite(\@result_array,$jn_ip_array,$ip_hostname_hash,$hadoop_cluster_flag);
			sync_node_file($hadoop_install_dir."/hdfs-site.xml",$node,"$hadoop_install_dir/$hadoop_dir_name/etc/hadoop/");
		}

		#更改hadoop目录的用户和用户组
		update_remote_dir_auth($hadoop_install_dir."/$hadoop_dir_name",$global_hadoop_user,$global_hadoop_user,$ip_str);
		
		#创建远程目录
		#create_remote_dir("/tmp/logs",$ip_str);
		#update_remote_dir_auth("/tmp/logs",$global_hadoop_user,$global_hadoop_user,$ip_str);

		#配置/home/hadoop/.bash_profile文件
		my $bashrc_profile_hash = {
			'HADOOP_HOME' => $hadoop_install_dir."/$hadoop_dir_name",
			'HADOOP_COMMON_LIB_NATIVE_DIR' => '${HADOOP_HOME}/lib/native',
			'HADOOP_OPTS' => '\"-Djava.library.path=$HADOOP_HOME/lib\"',
		};
		update_bashrc_profile($global_hadoop_user,$ip_str,$bashrc_profile_hash);
		#启动Hadoop集群
		#start_hadoop_cluster(FALSE);
	}elsif($nn_ip_array_leg == 1){
		#说明只有一个namenode

	}else{
		#说明没有设置namenode

	}
}

#安装Zookeeper
#1.判断节点数是否是奇数
#2.解压安装包到安装目录,修改配置文件
#3.打包修改好的配置文件
#4.上传安装包到安装节点
#5.解压安装包，启动Zookeeper
sub install_zookeeper{
	my ($app_name,$ip_hostname_hash) = @_;
	my $all_ip = [keys %$ip_hostname_hash];
	my $ip_str = array2str($all_ip);#获取以空格分割ip字符串
	
	my $clean_command = $perl_install_dir."/bin/atnodes -w -L  -u root \"/bin/rm -rf ".$hadoop_install_dir."/zookeeper;/bin/rm -rf ".$hadoop_install_dir."/$zk_install_name;/bin/rm -rf /tmp/hsperfdata_* \" $ip_str";
	exec_command($app_name,$clean_command,"安装Zookeeper前的清理工作");
	
	if (scalar(@$all_ip) >= 3) {
		#1.解压安装文件
		init_install_dir($zk_install_name);
		#2.配置安装文件
		my $data_dir = $hadoop_install_dir."/zookeeper/data";
		my $data_log_dir = $hadoop_install_dir."/zookeeper/datalog";
		my $zoo_cfg_hash = {
			'dataDir' => $data_dir,#配置数据所在目录
			'dataLogDir' => $data_log_dir,
			#'server.0'	=>	"hadoop0:2888:3888",
		};
		generate_key_value($hadoop_install_dir.'/zookeeper/conf/zoo.cfg',$zoo_cfg_hash);
		undef %$zoo_cfg_hash;
		my $temp_ip_myid_hash = {};#ip和server的映射关系
		while (my($ip,$hostname) = each %$ip_hostname_hash) {
			$zoo_cfg_hash->{server.".".$zk_server}="$hostname:2888:3888";	
			$temp_ip_myid_hash->{$ip}=$zk_server;
			$zk_server++;
		}
		generate_key_value($hadoop_install_dir.'/zookeeper/conf/zoo.cfg',$zoo_cfg_hash);
		#3.打包配置好的安装文件
		pack_file($zk_install_name,"zookeeper");
		#4.上传配置好的zookeeper安装包到zookeeper安装节点并解压到zookeeper安装目录
		uploadFile("$hadoop_install_dir/$zk_install_name",$hadoop_install_dir,TRUE,array2str([keys $ip_hostname_hash]));
		#5.配置zookeeper安装目录权限
		update_remote_dir_auth($hadoop_install_dir."/zookeeper",$global_hadoop_user,$global_hadoop_user,array2str([keys $ip_hostname_hash]));
		#6.创建myid文件并修改文件
		my $touch_myid_command = undef;
		my $touch_myid_command_exec = undef;
		while (my($ip,$id) = each %$temp_ip_myid_hash) {
			$touch_myid_command = $perl_install_dir."/bin/atnodes -L -u $global_hadoop_user '/bin/echo \"$id\" > $data_dir/myid;' $ip";
			exec_command("$app_name",$touch_myid_command,"创建myid文件并修改文件");
		}
		#7.配置ZOOKEEPER_HOME
		my $app_hash = {
			'ZOOKEEPER_HOME' => $hadoop_install_dir."/zookeeper"
		};
		update_bashrc_profile($global_hadoop_user,array2str([keys %$ip_hostname_hash]),$app_hash);
		#8.设置启动权限
		my $exec_flag_command = $perl_install_dir."/bin/atnodes -w -L -u root '/bin/chmod +x $hadoop_install_dir/zookeeper/bin/*' $ip_str";
		exec_command("$app_name",$exec_flag_command,"修改可执行权限");
		#9.启动zookeeper
		#start_zk_cluster();
	}else{
		$log->info("Zookeeper最少需要3个节点.");
		$log->info(scalar(%$ip_hostname_hash));
		$log->info(scalar(%$ip_hostname_hash)>= 3);
		$log->info($ip_str);
	}
}

#启动zk集群
sub start_zk_cluster{
	my $ip = $data->{nodeinfo}->{Zookeeper}->{ip};#获取zk所在节点ip 可能是多个逗号分割的ip
	if ($ip) {
		$ip =~ s/,/ /g;
		#9.启动zookeeper
		my $start_zk_server = $perl_install_dir."/bin/atnodes -w -L  -u $global_hadoop_user '$hadoop_install_dir/zookeeper/bin/zkServer.sh start' $ip";
		exec_command("Zookeeper",$start_zk_server,"开始启动Zookeeper");
		#10.测试zookeeper
		my $status_zk_server = $perl_install_dir."/bin/atnodes -w -L  -u $global_hadoop_user '$hadoop_install_dir/zookeeper/bin/zkServer.sh status' $ip";
		exec_command("Zookeeper",$status_zk_server,"测试Zookeeper集群是否启动成功");
	}else{
		$log->info("启动Zookeeper失败,没有配置Zookeeper节点.");
	}
}

#安装HBase
#1.解压HBase安装包到HBase安装目录
#2.修改配置文件
#3.打包修改的好的安装文件
#4.上传修改的HBase安装包到安装节点上
#5.启动HBase集群
#6.测试HBase集群
sub install_hbase{
	my ($app_name,$ip_hostname_hash) = @_;
	my $ip_str = array2str([keys %$ip_hostname_hash]);#获取以空格分割ip字符串
	if (scalar(@$active_nn)) {	#检测是否配置了Hadoop_NameNode
		print_hash($ip_hostname_hash);	
		ssh_login_root($app_name,$ip_str);#配置root用户ssh登录
		init_install_dir('hbase.tar.gz');
		my $hbase_master_ip = $data->{nodeinfo}->{HBase_HMaster}->{ip};#获取所有的HBase Master节点（默认只有一个HMaster节点）应该只有一个ip
		my $hbase_master_hostname = $data->{app_ips}->{$app_name}->{$hbase_master_ip};
		my $zk_server_hash = $data->{app_ips}->{Zookeeper};#zk-hash
		my @zk_hostname = values %$zk_server_hash;
		my $zk_hostname_str = join(",",@zk_hostname);
		if ($zk_hostname_str) {
			$log->info("没有发现Zookeeper集群.");
		}
		#配置HBase配置文件
		my $hbase_site_hash = {
			'hbase.rootdir' => "hdfs://".$active_nn[0].":8020/hbase",
			'hbase.master'	=> "$hbase_master_ip:60000",
			'hbase.master.port'	=>	"60000",	
			'hbase.cluster.distributed' => 'true',
			'hbase.zookeeper.quorum'	=> "$zk_hostname_str",
			'hbase.zookeeper.property.clientPort'	=>	'2888',
			'hbase.zookeeper.property.dataDir'	=> $hadoop_install_dir."/zookeeper/data",
			'dfs.replication'	=>	scalar(%$ip_hostname_hash),
		};
		generateXML("$hadoop_install_dir/hbase/conf/hbase-site.xml",$hbase_site_hash);
		my $hbase_env_hash = {
			'export HBASE_MANAGES_ZK' => 'false',
		};
		generate_key_value($hadoop_install_dir.'/hbase/bin/hbase-env.sh',$hbase_env_hash);
		#配置regionservers文件(写入数据)
		my $dn_ip = $data->{nodeinfo}->{Hadoop_DataNode}->{ip};#获取所有的DataNode节点
		my $dn_ip_array = parse_ips($dn_ip);
		echo_native_file($hadoop_install_dir.'/hbase/conf/regionservers',$dn_ip_array);
		#打包修改好的安装包
		pack_file("hbase.tar.gz","hbase");
		#上传配置好的hbase安装包到hbase安装节点并解压到hbase安装目录
		uploadFile($app_install_dir."/hbase.tar.gz",$hadoop_install_dir,TRUE,$ip_str);
		#配置hbase安装目录权限
		update_remote_dir_auth($hadoop_install_dir."/hbase",$global_hadoop_user,$global_hadoop_user,$ip_str);
		#配置/home/hadoop/.bash_profile文件PATH=$PATH:$HOME/bin
		my $app_hash = {
			'HBASE_HOME' => $hadoop_install_dir."/hbase",
		};
		update_bashrc_profile($global_hadoop_user,$ip_str,$app_hash);
		#创建HBase在hdfs上的目录(/hbase)
		mkdir_hdfs_dir("/hbase");
		#启动hbase
		my $start_hbase_command = $perl_install_dir."/bin/atnodes -w -L  -u $global_hadoop_user '$hadoop_install_dir/hbase/bin/start-hbase.sh' $hbase_master_ip";
		exec_command($app_name,$start_hbase_command,"启动HBase");
		$log->info("查看HBase状态: http://$hbase_master_ip:60000/master-status");
		$log->info("查看HBase状态: http://$hbase_master_hostname:60000/master-status");
		$log->info("完成启动HBase: ".$start_hbase_command_exec);
	}
}

#初始化hive数据（获取hive的ip）
sub init_hive_data{
	my $ip_hostname_hash = $data->{app_ips}->{Hive};
	while (my($k,$v) = each %$ip_hostname_hash) {
		$hive_ip = $k;
		$hive_histname = $v;
		last;
	}
}
#the method for install hive
#step1 install mysql and launch mysql
#step1.1 config mysql and init user and table
#step2 upload hive package,config hive what use mysql as default store
#step3 launch hive
#step4 test mysql and hive
#hive 建议安装在某个namenode机器节点中（方便操作）
sub install_hive{
	my ($app_name,$ip_hostname_hash) = @_;
	my $ip_str = array2str([keys %$ip_hostname_hash]);#获取以空格分割ip字符串
	print_hash($ip_hostname_hash);
	ssh_login_root($app_name,$ip_str);#配置root用户ssh登录
	init_hive_data();#初始化hive数据
	#安装、配置、启动mysql（mysql和hive默认是在一台机器）
	my $mysql_command_list = [
		'yum -y install mysql mysql-server mysql-devel',
		'/sbin/service mysqld restart',
		'/sbin/chkconfig mysqld on',
		'/usr/bin/mysql -Bse "CREATE USER \"hive\" IDENTIFIED BY \"hive\";"',
		'/usr/bin/mysql -Bse "GRANT ALL PRIVILEGES ON *.* TO \"hive\"@\"localhost\" WITH GRANT OPTION;"',
		'/usr/bin/mysql -Bse "update mysql.user set password=password(\"hive\") where user=\"hive\";"',
		'/usr/bin/mysql -Bse "flush privileges;"',
		'/usr/bin/mysql -uhive -phive -Bse "create database hive;"',
	];
	my $remote_command = undef;
	my $remote_command_exec = undef;;
	foreach my $command (@$mysql_command_list) {
		$remote_command = $perl_install_dir."/bin/atnodes -w -L  -u root '$command' $hive_ip";
		exec_command($app_name,$remote_command,"");
	}
	#1.解压hive到hive安装目录(目录不存在则创建)
	init_install_dir('hive.tar.gz');
	#2.修改hive-site.xml配置文件#http://www.aboutyun.com/thread-7548-1-1.html hive配置
	my $hive_site_hash = {
		'hive.aux.jars.path' => "file://$hadoop_install_dir/hive/lib/hive-contrib-0.11.0.jar",
		'hive.metastore.local' => 'true',
		'javax.jdo.option.ConnectionURL'	=> 'jdbc:mysql://localhost:3306/hive?characterEncoding=UTF-8',
		'javax.jdo.option.ConnectionDriverName'	=>	'com.mysql.jdbc.Driver',
		'javax.jdo.option.ConnectionUserName'	=> 'hive',
		'javax.jdo.option.ConnectionPassword'	=>	'hive',
		'hive.exec.parallel'	=> 'true',
		'hive.exec.mode.local.auto'	=>	'true',
	};
	generateXML("$hadoop_install_dir/hive/conf/hive-site.xml",$hive_site_hash);
	#3.修改hive-env.sh配置文件
	my $hive_env_command = "/bin/sed -i -e \"/HADOOP_HOME=/d\" -e \"/export HIVE_CONF_DIR=/d\";/bin/echo 'HADOOP_HOME=$hadoop_install_dir/$hadoop_dir_name \n export HIVE_CONF_DIR=$hadoop_install_dir/hive/conf ' >> $hadoop_install_dir/hive/conf/hive-env.sh";
	#4.打包配置好的hive文件
	pack_file("hive.tar.gz","hive");
	#5.上传配置好的hive安装包到hive安装节点并解压到hive安装目录
	uploadFile($app_install_dir."/hive.tar.gz",$hadoop_install_dir,TRUE,$hive_ip);
	#6.配置hive安装目录权限
	update_remote_dir_auth($hadoop_install_dir."/hive",$global_hadoop_user,$global_hadoop_user,$hive_ip);
	#7.配置/home/hadoop/.bash_profile文件PATH=$PATH:$HOME/bin
	my $app_hash = {
		'HIVE_HOME' => $hadoop_install_dir."/hive",
	};
	update_bashrc_profile($global_hadoop_user,$hive_ip,$app_hash);
	#8.启动hive
	#start_hive(FALSE);
}

#启动hive
sub start_hive{
	my $flag = shift;
	if ($flag eq TRUE) {
		init_hive_data();
	}
	if ($hive_ip) {
		my $start_hive_command = $perl_install_dir."/bin/atnodes -w -L  -u $username '$hadoop_install_dir/hive/bin/hive --service hiveserver -p $global_hive_port >> $hadoop_install_dir/hive/hive_thrift_server.log 2>&1 &' $hive_ip";
		exec_command("Hive",$start_hive_command,"启动Hive");
	}else{
		$log->info("启动Hive失败,没有配置Hive节点.");
	}
}

#安装Ganglia
sub install_ganglia{
	my $app_name = shift;
	if (ref($data->{app_ips}->{$app_name}) eq 'HASH') {
		my $ips = $data->{app_ips}->{$app_name};#应用的所有的ip(哈希)
		if (scalar(%$ips)) {

		}
	}
}

#安装Storm
sub install_storm{
	


}

#安装kafka
sub install_kafka{



}


#安装spark
sub install_spark{



}

#清理工作
sub clean{
	$db->closeClient();#关闭数据库连接
}


sub run{
	my ($start_sec, $start_usec) = gettimeofday();
	init;
	foreach $app_name (@$service) {
		$log->info("-------------".$app_name."  Install Start -------------");
		if (ref($data->{app_ips}->{$app_name}) eq 'HASH') {#如果$app_name下有配置ip的话
			my $ip_hostname_hash = $data->{app_ips}->{$app_name};#获取应用的所有的ip-hostname(哈希)
			if (scalar(%$ip_hostname_hash)) {
				#if ($app_name eq 'Hadoop') {
					#install_hadoop($app_name,$ip_hostname_hash);
				#}
				if($app_name eq 'Zookeeper'){
					install_zookeeper($app_name,$ip_hostname_hash);
				}
			}
		}
		$log->info("-------------".$app_name."  Install end -------------");
	}
	#start_zk_cluster();#启动zookeeper集群
	#start_hadoop_cluster(TRUE);启动hadoop集群
	#start_hive(TRUE);#启动hive
	print_service("\@service",\@service);
	print_hash($data);
	clean;
	my ($end_sec, $end_usec) = gettimeofday();
	my $timeDelta = ($end_usec - $start_usec) / 1000 + ($end_sec - $start_sec) * 1000;
	$log->info("一共用时：".$timeDelta);
}
run;