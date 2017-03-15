#!/bin/bash

function deploy_clean(){
	rm -rf /root/bigdata/SSH-Batch*;
	rm -rf /root/bigdata/IPC-Run*;
	rm -rf /root/bigdata/Set-Scala*;
	rm -rf /root/bigdata/Net-OpenSS*;
	rm -rf /root/bigdata/TermReadKe*;
	rm -rf /root/bigdata/IO-Tt*;
	rm -rf /root/bigdata/File-Whic*;
	rm -rf /root/bigdata/File-HomeDi*;
}
function deploy(){
	deploy_clean;
	echo "start down IPC-Run3-0.048.tar.gz...";
		wget --no-check-certificate https://cpan.metacpan.org/authors/id/R/RJ/RJBS/IPC-Run3-0.048.tar.gz
		tar -xzvf IPC-Run3-0.048.tar.gz; cd IPC-Run3-0.048; perl Makefile.PL; make; make test; make install;
	echo "install IPC-Run3-0.048.tar.gz Success!";
	
	echo "start down Set-Scalar-1.23.tar.gz...";
		wget --no-check-certificate https://cpan.metacpan.org/authors/id/J/JH/JHI/Set-Scalar-1.23.tar.gz
		tar -xzvf Set-Scalar-1.23.tar.gz; cd Set-Scalar-1.23; perl Makefile.PL; make; make test; make install;
	echo "install Set-Scalar-1.23.tar.gz Success!";

	echo "start down TermReadKey-2.30.tar.gz...";
		wget --no-check-certificate https://cpan.metacpan.org/authors/id/J/JS/JSTOWE/TermReadKey-2.30.tar.gz
		tar -xzvf TermReadKey-2.30.tar.gz; cd TermReadKey-2.30; perl Makefile.PL; make; make test; make install;
	echo "install TermReadKey-2.30.tar.gz Success!";

	echo "start down IO-Tty-1.12.tar.gz...";
		wget --no-check-certificate https://cpan.metacpan.org/authors/id/T/TO/TODDR/IO-Tty-1.12.tar.gz
		tar -xzvf IO-Tty-1.12.tar.gz; cd IO-Tty-1.12; perl Makefile.PL; make; make test; make install;
	echo "install IO-Tty-1.12.tar.gz Success!";

	echo "start down File-HomeDir-1.00.tar.gz...";
		wget --no-check-certificate https://cpan.metacpan.org/authors/id/A/AD/ADAMK/File-HomeDir-1.00.tar.gz
		tar -xzvf File-HomeDir-1.00.tar.gz; cd File-HomeDir-1.00; perl Makefile.PL; make; make test; make install;
	echo "install File-HomeDir-1.00.tar.gz Success!";
	
	echo "start down File-Which-1.19.tar.gz...";
		wget --no-check-certificate https://cpan.metacpan.org/authors/id/P/PL/PLICEASE/File-Which-1.19.tar.gz
		tar -xzvf File-Which-1.19.tar.gz; cd File-Which-1.19; perl Makefile.PL; make; make test; make install;
	echo "install File-Which-1.19.tar.gz Success!";

	echo "start down Net-OpenSSH-0.34.tar.gz...";
		wget --no-check-certificate https://cpan.metacpan.org/authors/id/S/SA/SALVA/Net-OpenSSH-0.34.tar.gz
		tar -xzvf Net-OpenSSH-0.34.tar.gz; cd Net-OpenSSH-0.34; perl Makefile.PL; make; make test; make install;
	echo "install Net-OpenSSH-0.34.tar.gz Success!";

	echo "start down SSH-Batch-0.029.tar.gz...";
		wget --no-check-certificate https://cpan.metacpan.org/authors/id/A/AG/AGENT/SSH-Batch-0.029.tar.gz
		tar  -xzvf SSH-Batch-0.029.tar.gz; cd SSH-Batch-0.029; perl Makefile.PL; make; make test; make install;
	echo "install SSH-Batch-0.029.tar.gz Success!";
	perl -v;
}

function main(){
  deploy;
}
main;

