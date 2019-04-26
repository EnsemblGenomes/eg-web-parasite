DIR=/hps/nobackup/production/ensemblgenomes/parasite/parasite-release/release-${PARASITE_VERSION}
EG_VERSION=43
echo $DIR
mkdir -p $DIR
cd $DIR

if [ "$1" == '--delete' ]; then
  rm *
fi

# Dump all the databases into the tmp space
# Be careful of Database locking time which might lead to infinity running time  
echo "Dumping and loading databases"
databaselist=$($PARASITE_STAGING_MYSQL -NB -e 'SHOW DATABASES LIKE "%_core%_'${ENSEMBL_VERSION}'_%"')
databases=( `echo ${databaselist}` ncbi_taxonomy ensembl_metadata ensembl_compara_parasite_${PARASITE_VERSION}_${ENSEMBL_VERSION} ensembl_ontology_${ENSEMBL_VERSION} ensembl_website_${ENSEMBL_VERSION} ensemblgenomes_info_${EG_VERSION} ensemblgenomes_stable_ids_${PARASITE_VERSION}_${ENSEMBL_VERSION} )
stagingurl=$(echo $($PARASITE_STAGING_MYSQL details url) | awk '{ sub(/^mysql:\/\//,""); print }' | awk '{ sub(/\/$/,""); print }')


copy-to-ps-rest-rel() {
  echo "Loading to mysql-ps-rest-rel for $DB"
  mysql-ps-rest-rel-ensrw -e "CREATE DATABASE $DB"
  mysql-ps-rest-rel-ensrw $DB < $DB.sql
  mysql-ps-rest-rel-ensrw mysqlcheck -o $DB
  mysqldbcompare --server1=$stagingurl --server2=$(echo $(mysql-ps-rest-rel-ensrw details url) | awk '{ sub(/^mysql:\/\//,""); print }' | awk '{ sub(/\/$/,""); print }') $DB:$DB --run-all-tests	
}

copy-to-ps-rel() {
  echo "Loading to mysql-ps-rel for $DB"
  mysql-ps-rel-ensrw -e "CREATE DATABASE $DB"
  mysql-ps-rel-ensrw $DB < $DB.sql
  mysql-ps-rel-ensrw mysqlcheck -o $DB
  mysqldbcompare --server1=$stagingurl --server2=$(echo $(mysql-ps-rel details url) | awk '{ sub(/^mysql:\/\//,""); print }' | awk '{ sub(/\/$/,""); print }') $DB:$DB --run-all-tests
}

copy-to-int-rel() {
  echo "Loading to mysql-ps-intrel for $DB"
  mysql-ps-intrel-ensrw -e "CREATE DATABASE $DB"
  mysql-ps-intrel-ensrw $DB < $DB.sql
  mysql-ps-intrel-ensrw mysqlcheck -o $DB
  mysqldbcompare --server1=$stagingurl --server2=$(echo $(mysql-ps-intrel details url) | awk '{ sub(/^mysql:\/\//,""); print }' | awk '{ sub(/\/$/,""); print }') $DB:$DB --run-all-tests
}

echo $stagingurl
for DB in "${databases[@]}"
do
  echo "Start processing $DB"
  $PARASITE_STAGING_MYSQL mysqldump $DB > $DB.sql
  #copy-to-ps-rest-rel >> ps-rest-rel.out 2>&1 &
  #copy-to-ps-rel >> ps-rel.out 2>&1  &
  copy-to-int-rel >> ps-int-rel.out 2>&1
  #wait
done
# Compress the archive then push to the EBI Archive Freezer
#echo "Creating release archive for the EBI Freezer"
#tar -zcvf release-${PARASITE_VERSION}.tar.gz *.sql
#rm *.sql
#ear-put release-${PARASITE_VERSION}.tar.gz

