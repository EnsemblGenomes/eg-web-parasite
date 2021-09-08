#!/usr/bin/env bash

DB_SERVER=mysql-ps-staging-2
DB_PORT=4467
PS_VERSION=16
ENS_VERSION=101

function generate_stat() {
	DB=$1
	species=`perl -e 'my $idx = index "$ARGV[0]", "_core"; print ucfirst substr "$ARGV[0]", 0, $idx' "$DB"`
	species_json="assembly_$species.json"
	echo "New json file: $species_json"

	bsub -o /dev/null -e /dev/null perl -I ensembl/modules/ eg-web-parasite/utils/assembly_stats.pl --host $DB_SERVER --port $DB_PORT --user ensro --busco-an --busco-as --assembly --dbname $DB --outfile /nfs/services/nobackup/ensweb/parasite/assembly_stats/$species_json
}

mysql -u ensro -h $DB_SERVER -NB -P $DB_PORT -e 'SHOW DATABASES LIKE "%core_'$PS_VERSION'_'$ENS_VERSION'%"' | while read db_core
do
        echo "Using $db_core"
        generate_stat $db_core;
done
