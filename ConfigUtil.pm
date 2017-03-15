package ConfigUtil;

=start
ConfigUtil读取配置文件工具类
my $config = new ConfigUtil(DB,'< db.properties',$log);
my $value = $config->get('db.database');
say $value;
=cut
use 5.010;

sub new{
	my($pack,$filehandler,$filename,$log) = @_;
	my $fh = <$filehandler>;
	my %hash;
	open($fh,$filename) or $log->info("Can't open config file \"$filename\" : $!");
	$log->info("开始读取配置文件 \"$filename\"");
	while(<$fh>) {
		chomp;
		next if /^#|^$/;
		my ($k,$v) = split/\s*\=\s*/;
		chomp( $k );
		chomp( $v );
		$hash{$k} = $v;
	}
	$log->info("读取配置文件结束 \"$filename\"");
	close($fh) or $log->info("Can't close config file \"$filename\" : $!");
	my $self = {
		filehandler => $fh,
		hash => \%hash,
		log => $log,
	};
	return bless $self,$pack;
}

sub get{
	my ($self,$key) = @_;
	my $value = $self->{hash}{$key};
	return $value;
}

sub set{
	my ($self,$key,$value) = @_;
	$self->{hash}{$key} = $value;
}

sub getAll{
	my $self = shift;
	return $self->{hash};
}

1;