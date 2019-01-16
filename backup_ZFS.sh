#!/bin/bash


YESTERDAY=`date -d "yesterday" "+%Y_%m_%d"`
TODAY=`date -d "today" "+%Y_%m_%d"`
SID_NAME=$1


function check_files()
{

PARAMETER=$1
PARAMETER_FILE="${PARAMETER}_${SID_NAME}[0-9]*:${YESTERDAY}"
IS_ERROR=0
NUMBER_OF_FILES=`ls $PATH_TO_LOGS | grep $PARAMETER_FILE | grep -E rma$\|msg$\|zfs$ | wc -l`
ls $PATH_TO_LOGS | grep $PARAMETER_FILE | grep -E err$\|FAILED$\|ERROR$ >/dev/null 2>&1 && IS_ERROR=1

if [ $NUMBER_OF_FILES -eq 2 -a $IS_ERROR -eq 0 ]
then
                printf "OK: There are 2 $PARAMETER files from `date -d "yesterday" +"%d-%m-%Y"`, none of which are with errors\n"
elif [ $IS_ERROR -ne 0 ]
then
                printf "NOT_OK: These files are with errors:\n`ls $PATH_TO_LOGS/ | grep $PARAMETER_FILE | grep -E err$\|FAILED$\|ERROR$ `\n"
else
                printf "NOT_OK: There should be 2 $PARAMETER files. $NUMBER_OF_FILES $PARAMETER files exist.\n"
fi

}


printf "begin_version\n"


which locate >/dev/null 2>&1 && ORATAB=`locate -r "/var.*oratab$\|/etc.*oratab$"`
if [[ "$ORATAB" ]]
then
        for FILE in $ORATAB
        do
                if [[ `cat $FILE | grep -v "^#" | sed /^$/d | wc -l | cut -d ' ' -f 1` -ne 0 ]]
                then
                        ORATAB=$FILE
                        break
                fi
        done
else
        ORATAB=`find /var /etc -name oratab -print 2>/dev/null -quit`
        if [[ `cat $ORATAB | grep -v "^#" | sed /^$/d | wc -l | cut -d ' ' -f 1` -eq 0 ]]
        then
                printf "NOT_OK: The oratab file $ORATAB is empty\n"
                exit 7
        fi
fi


VERSION_RAW=`cat $ORATAB | grep $SID_NAME | sort | uniq | head -1 | tr ':' ' ' | cut -d " " -f 2 | cut -d '/' -f 5`

if [[ "$VERSION_RAW" == "" ]]
then
        printf "NOT_OK: $SID_NAME is not in the oratab file.\n"
        exit 27
else
        VERSION=${VERSION_RAW:0:2}
        printf "OK: Version found in oratab\n$VERSION_RAW \n"
fi

printf "end_version\n"

if [[ "$VERSION" == "12" ]]
then
        PATH_TO_LOGS=/app/oracle/admin/$SID_NAME/backup
else
        PATH_TO_LOGS=/app/oracle/$SID_NAME/admin/backup
fi

printf "begin_path_to_logs\n"

if [ ! -d $PATH_TO_LOGS ]
then
        printf "NOT_OK: The backup folder does not exist. The backup is not configured on ZFS.\n"
        exit 27
else
        printf "OK: The backup folder exist.\n$PATH_TO_LOGS\n"
fi

printf "end_path_to_logs\n"


printf "begin_incr_create_destroy\n"

for i in "INCRMERGE" "ZFSCREATE" "ZFSDESTROY"
do
        check_files $i
done

printf "end_incr_create_destroy\n"

printf "begin_arch_logs\n"

ARCHIVE_LOGS="archive_logs_${SID_NAME}[0-9]*:${TODAY}"
IS_ERROR_ARCHIVE_LOGS=0
NUMBER_OF_ARCHIVE_LOGS=`ls $PATH_TO_LOGS | grep $ARCHIVE_LOGS | grep -E rma$\|msg$ | wc -l`
ls $PATH_TO_LOGS | grep $ARCHIVE_LOGS | grep -E err$\|FAILED$\|ERROR$ >/dev/null 2>&1 && IS_ERROR_ARCHIVE_LOGS=1

if [ $NUMBER_OF_ARCHIVE_LOGS -gt 0 -a $IS_ERROR_ARCHIVE_LOGS -eq 0 ]
then
        printf "OK: There are $NUMBER_OF_ARCHIVE_LOGS archive logs from today, none of which are with errors\n"
elif [ $IS_ERROR_ARCHIVE_LOGS -ne 0 ]
then
        printf "NOT_OK: These files are with errors:\n`ls $PATH_TO_LOGS/ | grep $ARCHIVE_LOGS | grep -E err$\|FAILED$\|ERROR$`\n"
else
        printf "NOT_OK: Archive logs from today should exist\n"
fi

printf "end_arch_logs\n"

printf "begin_arch_to_zfs\n"

ARCHIVE_TO_ZFS="archive_to_zfs_${SID_NAME}[0-9]*:${TODAY}"
IS_ERROR_ARCHIVE_TO_ZFS=0
NUMBER_OF_ARCHIVE_TO_ZFS=`ls $PATH_TO_LOGS | grep $ARCHIVE_TO_ZFS | wc -l`
ls $PATH_TO_LOGS | grep $ARCHIVE_TO_ZFS | grep -E err$\|FAILED$\|ERROR$ >/dev/null 2>&1 && IS_ERROR_ARCHIVE_TO_ZFS=1

if [ $NUMBER_OF_ARCHIVE_TO_ZFS -gt 0 -a $IS_ERROR_ARCHIVE_TO_ZFS -eq 0 ]
then
        printf "OK: There are $NUMBER_OF_ARCHIVE_TO_ZFS archive to zfs files from today, none of which are with errors\n"
elif [ $IS_ERROR_ARCHIVE_TO_ZFS -ne 0 ]
then
        printf "NOT_OK: These files are with errors:\n`ls $PATH_TO_LOGS/ | grep $ARCHIVE_TO_ZFS | grep -E err$\|FAILED$\|ERROR$`\n"
else
        printf "NOT_OK: Archive to zfs logs from today should exist\n"
fi

printf "end_arch_to_zfs\n"

