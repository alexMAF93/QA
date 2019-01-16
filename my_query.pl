#!/usr/bin/perl

use strict;
use DBI;



my $ORACLE_HOME = "/opt/oracle/product/11203_ee_64/db";
my $ORACLE_SID="OQUATPRD";
$ENV{ORACLE_HOME}=$ORACLE_HOME;
$ENV{ORACLE_SID}=$ORACLE_SID;
$ENV{PATH}="$ORACLE_HOME/bin";

my $i = @ARGV[0];

my $dbh = DBI->connect('dbi:Oracle:host=vopo01cl-scan.dc-ratingen.de;service_name=OQUATPRD_TAF.prod.vis;port=33000','oquatadmin', 'Qa_Sch_0', { RaiseError => 1, AutoCommit => 0 }) or die "Couldn't open database: $DBI::errstr \n; stopped";

        my $sth = $dbh->prepare("$i")
        or  die "Couldn't prepare statement: + $DBI::errstr; stopped";

        $sth->execute() or die "Couldn't execute statement: $DBI::errstr; stopped";

        while (my @row = $sth->fetchrow_array())

        {

		for(@row) {
                        if ($_ eq "")
			{
			printf("%-30s", '*empty*');
			}
			else
			{
			printf("%-30s", "$_");
			}
			print(' | ');
}
		print("\n");

    }

END {
       $dbh->disconnect if defined($dbh);
    }


my $history_file_location = "QUERIES/queries_history.txt";
open (my $history_file, ">>", $history_file_location) or die $!;
print $history_file "[".localtime(time)."]\n";
print $history_file $i;
print $history_file "\n\n\n";
close $history_file

