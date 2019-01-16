#!/opt/SP/python/python/bin/python3.6


import re, os, sys, tarfile
from subprocess import Popen, PIPE


if len(sys.argv) < 3:
    print('Usage: ' + sys.argv[0] + ' CRQ_FOLDER CRQ_ID\n\n')
    print('The CRQ_FOLDER should be in /home/oquat/malex/DIVERSE/OFFLINE_QA/')
    sys.exit(7)


DIR = '/home/oquat/malex/DIVERSE/OFFLINE_QA/' + sys.argv[1] + '/'
list_of_tars = []
hostnames_ids = {}


# all the tar files from the folder
for file in os.listdir(DIR):
    list_of_tars.append(file)
    
    
# the IDs for each server
list_of_ids = Popen(['/home/oquat/malex/DIVERSE/get_offline_IDs.pl', sys.argv[2]], stdout=PIPE)

for bytes in list_of_ids.stdout:
    line = bytes.decode().replace(' ','').split('\n')
    for item in line:
        if item != "":
            server=item.split('_')[0]
            ID=item.split('_')[1]
            hostnames_ids[server] = ID


print('These are the item IDs for each server in this CRQ:', hostnames_ids)


for server, ID in hostnames_ids.items():
    print('\nRenaming files for', server, ',id', ID)
    for file in list_of_tars:
        search_tar = re.match('.*' + server + '.*', file, re.IGNORECASE)
        if search_tar:
            NEW_DIR = '/opt/oquat/qualitycenter/data/raw/' + ID + '/'
            if not os.path.isdir(NEW_DIR):
                os.mkdir(NEW_DIR)
            if not os.path.isdir(NEW_DIR + 'manual/'):
                NEW_DIR += 'manual/'
                os.mkdir(NEW_DIR)
            tar = tarfile.open(DIR + file)
            tar.extractall(path=NEW_DIR)
            tar.close()
            for raw_file in os.listdir(NEW_DIR):
                search_whoami = re.match(".*whoami.*", raw_file, re.IGNORECASE)
                search_cr_os = re.match(".*cr_os.*", raw_file, re.IGNORECASE)
                search_Linux = re.match(".*Linux.*", raw_file, re.IGNORECASE)
                if search_whoami:
                    os.rename(NEW_DIR + raw_file, NEW_DIR + 'whoami.raw')
                elif search_cr_os:
                    os.rename(NEW_DIR + raw_file, NEW_DIR + 'custreq.raw')
                elif search_Linux:
                    os.rename(NEW_DIR + raw_file, NEW_DIR + 'os.raw')
                else:
                    os.remove(NEW_DIR + raw_file)
