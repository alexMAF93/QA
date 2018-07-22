#!/usr/bin/perl

use strict;
use DBI;



my $ORACLE_HOME = "/opt/oracle/product/11203_ee_64/db";
my $ORACLE_SID="DBNAME";
$ENV{ORACLE_HOME}=$ORACLE_HOME;
$ENV{ORACLE_SID}=$ORACLE_SID;
$ENV{PATH}="$ORACLE_HOME/bin";

my $i = @ARGV[0];


my $dbh = DBI->connect('dbi:Oracle:host=someserver-scan.dc-ratingen.de;service_name=DB.prod.vis;port=330','user', 'password', { RaiseError => 1, AutoCommit => 0 }) or die "Couldn't open database: $DBI::errstr \n; stopped";

        my $sth = $dbh->prepare("select TESTITEM.ID, NAME from TESTITEM 
where CRQ_ID = '$i' and TIER2_ID in ('100', '78', '39', '24', '29', '30', '6', '7', '8', '9') ORDER BY NAME ASC")
        or  die "Couldn't prepare statement: + $DBI::errstr; stopped";

        $sth->execute() or die "Couldn't execute statement: $DBI::errstr; stopped";

        while (my @row = $sth->fetchrow_array())

        {



                print($row[1]." - ");
                print($row[0]."  \n");

    }

END {
       $dbh->disconnect if defined($dbh);
    }


