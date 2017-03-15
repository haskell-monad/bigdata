package DBUtil;

=start
DBUtil读取数据库工具类
=cut
use 5.010;
use DBI;

sub new{
	my($pack,$config,$log) = @_;
	#my $database = $config->get('db.database');
	#my $hostname = $config->get('db.hostname');
	#my $user = $config->get('db.user');
	#my $port = $config->get('db.port');
	#my $password = $config->get('db.password');

	my $database = "bigdata";
	my $hostname = '127.0.0.1';
	my $port = '3306';
	my $user = 'root';
	my $password = 'root';

	my $dsn = "DBI:mysql:database=$database;host=$hostname;port=$port";
	my $dbh = DBI->connect($dsn, $user, $password) or $log->info("不可以连接到数据库-->".$dsn);
	my $self = {
		log => $log,
		dbh => $dbh,
	};
	return bless $self,$pack;
}

sub insert{
	my ($self,$key) = @_;
	$dbh->do("INSERT INTO info(name,position,sex,age,edu,exper,area,updatetime,pay,work_exper,edu_exper,introduce,other,photo,phone)VALUES()");

}

sub execute{
	my ($self,$sql) = @_;
	my $dbh = $self->{dbh};
	my $sth = $dbh->prepare($sql);
	my $log = $self->{log};
	$log->info("开始执行sql：".$sql);
	$sth->execute;
	my $numRows = $sth->rows;
	my $table = $sth->fetchall_arrayref;
	$sth->finish;
	$log->info("完成执行sql：".$numRows."行:".$sql);
	return $table;
}

#关闭数据库客户端
sub closeClient{
	my $self = shift;
	my $dbh = $self->{dbh};
	my $log = $self->{log};
	$dbh->disconnect;
	$log->info("已经关闭数据库连接.");
}

1;