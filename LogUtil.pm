package LogUtil;

=start
LogUtil日志工具类
my $log = new LogUtil(FH,'>> log');
$log->info('aaaaaaa');
$log->info('cccccc');
$log->closeHandler;
=cut
use 5.010;

sub new{
	my($pack,$filehandler,$filaname) = @_;
	my $fh = <$filehandler>;
	open($fh,$filaname) or die "Can't open file : $!";	
	my $self = {
		filehandler => $fh,
		filaname => $filaname,
	};
	return bless $self,$pack;
}
#写日志
sub info{
	my ($self,$content) = @_;
	my $fh = $self->{filehandler};
	my($sec,$min,$hour,$day,$mon,$year) = localtime();
	$mon++;$year += 1900;
	my $data_now = sprintf("%04d-%02d-%02d %02d:%02d:%02d:%02d",$year,$mon,$day,$hour,$min,$sec);
	say $fh $data_now."-->".$content;
}
#关闭句柄
sub closeHandler{
	my $self = shift;
	my $fh = $self->{filehandler};
	close($fh) or die "Can't close file : $!";
}

1;
