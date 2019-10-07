#!/usr/bin/perl -I /home/vhosts/JKZ
#******************************************************
# @desc		delete junk session data
# @package	sweepSessionRecord
# @access	public
# @author	Iwahase Ryo
# @create	2008/04/13
#******************************************************
use JKZ::UsrWebDB;
use WebUtil;

my $cnt = 0;
my $dbh = JKZ::UsrWebDB::connect();
$dbh->do('USE ApacheSession');
my $sql = "SELECT a.id FROM ApacheSession.sessions a WHERE
 a.id NOT IN
 (SELECT k.sessid FROM HP_general.tKaraMailF k)
 AND a.updatetime < DATE_SUB(NOW(), INTERVAL 24 HOUR);
";
my $sth = $dbh->prepare($sql);
$sth->execute();
while (my $junkid = $sth->fetchrow_array()) {
	warn "\n sessionid : ", $junkid, " is now deleted \n";
	my $rc = $dbh->do ("DELETE FROM ApacheSession.sessions WHERE id=?", undef, $junkid);
	warn "\n","==="x10, "\n", "FAILED DELETING sessionid : $junkid \n" if $rc eq '0E0';
	warn "\n","==="x10, "\n", "SUCCESS  DELETING sessionid : $junkid \n" if $rc ne '0E0';

	++$cnt;
}

warn "\n TOTAL $cnt session records have been DELETED \n";

$dbh->disconnect();

exit();
