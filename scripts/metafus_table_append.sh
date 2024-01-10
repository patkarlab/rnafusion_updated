#!/usr/bin/bash
excel=$1
echo "#!/bin/bash"
echo -e "# Script to update \"clinical_fusions\" or \"false_positives\" tables\n"
echo "# Absolute path to database"
echo -e "database=/Users/maposto/MetaFusion-Clinical/MWE/historical_database.db\n"

echo "# Absolute path to excel spreadsheet with selected calls"
echo -e "# Only needed if doing \"add\" operation. Can use placeholder path for \"view\""
echo "excel=/Users/maposto/${excel}"
echo -e "#excel=/placeholder/file/path/nothing.xlsx\n"
echo -e "# Operation \"add\", \"view\""
echo "operation=add"
echo -e "#operation=view\n"
echo "# Table to view or update database tables"
echo "table=clinical_fusions"
echo "#table=false_positives"
echo -e "#table=historical_fusions\n"
echo "# Run update script"
echo "scripts=/Users/maposto/MetaFusion-Clinical/scripts"
#echo "cd  /Users/maposto/MetaFusion-Clinical/MWE"

echo "Rscript \$scripts/update_fusion_database_tables.R --excel=\$excel --database=\$database --table=\$table --operation=\$operation"

#echo "cd /Users/maposto/MetaFusion-Clinical/scripts"
