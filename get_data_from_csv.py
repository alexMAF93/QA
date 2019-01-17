#!/opt/SP/python/python/bin/python3.6



import csv, re, os
from sys import argv
from modules import tampering_files as tf


OPTION = argv[1]
CRQ = argv[2]
SERVER = argv[3].upper()
DIR = '/opt/oquat/qualitycenter/web/files/' + CRQ + '/'


def remove_empty(list):
    for i in range(0, len(list)):
        if list[i] == "":
            del list[i]


def write_to_file(filename, arg):
    with open(filename, 'w') as f:
        for item in arg:
            f.write(' '.join(item))
            f.write('\n')


def get_filesystems():
    filesystems = re.sub('<|>|:', ' ', data[line]['FS/Drive'].strip()).split(';')
    filesystems_list = []
    for item in filesystems:
        filesystem = item.split()
        filesystems_list.append(filesystem)
    if len(filesystems_list) == 0:
        print('N/A')
    else:
        print('OK')
        return filesystems_list


def get_users():
    user_list = []
    user_cell_line = data[line]['Existing Account'].strip().replace(':', ' ').split(';')
    for user_details_raw in user_cell_line:
        user_details = user_details_raw.split()
        for item in user_details:
            if item.isdigit():
                del user_details[user_details.index(item)]
        username = user_details[0]
        primary_group = user_details[1]
        home_directory = user_details[-1]
        if not home_directory.startswith('/'):
            home_directory = 'NO'
        secondary_groups = ' '.join(user_details[2:len(user_details) - 1]) + '\n'
        user_list.append([username, home_directory, primary_group, secondary_groups])
    if len(user_list) == 0:
        print('N/A')
    else:
        print('OK')
        return user_list


ASIC_LIST = tf.get_ASIC(DIR, 'RITM|specs')


if len(ASIC_LIST) == 0:
    print('NOT_OK: The build document was not saved')
else:
    for FILE in ASIC_LIST:
        with open(DIR + FILE) as f:
            reader = csv.DictReader(f)
            data = [r for r in reader]
        line = 0
        for i in range(0, len(data)):
            hostname = data[i]['HostName'].strip()
            findserver = re.match('.*' + SERVER + '.*', hostname, re.IGNORECASE)
            if findserver:
                line = i
        if line > 0:
            break


    if OPTION == "-f":
        write_to_file(DIR + SERVER + '_localfs.txt', get_filesystems())
    elif OPTION == "-u":
        write_to_file(DIR + SERVER + '_users.txt', get_users())
    else:
        print('UnKnown OPTION')

