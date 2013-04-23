#!/bin/sh

dumpPath="$HOME/Документы/"
usage()
{
	
echo "
 This script use phyton client library for interact with couchDb
 For using this script you may install it
 See for more details about library - https://pypi.python.org/pypi/CouchDB

 Script usage options: 
        -e | --export - full url to exporting host. Example: http://localhost:5984
        -i | --import - full url to importing host. See example in -e option
        -d | --dbname | --database - name of database for importing
	-p | --dumpto - absolute local path for storing dumps
        -h | --help - this message will be dispaying    
       "
exit 1
}
while [ "$1" != "" ]; do
    case $1 in
        -e | --export )         shift
                                exportUrl=$1
                                ;;
        -i | --import )    	shift
				importUrl=$1
                                ;;
	-d | --dbname | --database) 
				shift
				dbName=$1
				;;
	-p | --dumpto)
				shift
				dumpPath=$1
				;;
        -h | --help )          usage 
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

if [ -z $exportUrl ] 
then
	echo "Enter full url for export host: \n"
	read exportUrl
	echo "Set export url: $exportUrl \n"
fi

if [ -z $importUrl ]
then 
	
	echo "Enter full url for import host:"
	read importUrl
	echo "Set import url: $importUrl \n"
fi


if [ -z $dbName ]
then 
	echo "Enter dbname for export/import operation:"
	read dbName
	echo "Set db name: $dbName\n"
fi
if [ $# -eq 3 ] 
then 
	echo "Ok!\n"
	echo "The export url is $exportUrl and import url is $importUrl"
	echo "Db name is $dbName\n"
fi

dumpFile="$dumpPath$dbName.json"

echo "Start export operation from $exportUrl/$dbName ..."
couchdb-dump "$exportUrl/$dbName" > $dumpFile
echo "Export done! dumped to $dumpFile\n"

echo "Check if db $importUrl/$dbName is exists\n"

resultCheck=`curl -s -X GET "$importUrl/$dbName" | sed -e 's/[{}]/''/g' | awk -F ','  '{print $1}' | awk -F ':' '{print $2}' | tr -d '"'`

if [ $resultCheck = $dbName ]
then 
	echo "Database is exists! Dropping $importUrl/$dbName..."
	resultDropping=`curl -s -X DELETE "$importUrl/$dbName"` 
	echo "Status answer: $resultDropping\n"
else
	echo "Db not found."
fi

echo "Creating $importUrl/$dbName..."
resultCreating=`curl -s -X PUT "$importUrl/$dbName"`
echo "Status answer:$resultCreating\n"

echo "Start import opertaion to $importUrl/$dbName ..."
couchdb-load --input=$dumpFile "$importUrl/$dbName"
echo "Import done! Thank you for using this script.\n"

