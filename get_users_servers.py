#!/opt/SP/python/python/bin/python3.6


import sys, os, re, xlrd
import modules.tampering_files as fileop
import modules.asic_common as asicop


CRQ_DIR = "/opt/oquat/qualitycenter/web/files/" + sys.argv[1].replace(' ', '')  # the CRQ 
ITEM = sys.argv[2].replace(' ', '').upper()                                        # the server
ASIC_FILEs = fileop.get_ASIC(CRQ_DIR + '/')                                        # the ASICs from the CRQ directory                             
OUTPUT_FILE = CRQ_DIR + '/' + ITEM + '_users.txt'                                 # the file where the output of this script will be written
fileop.remove_output_file(OUTPUT_FILE)                                             # if the file already exists it will be deleted
f = open(OUTPUT_FILE, 'a', newline='\n')                                           # open the file in order to have it ready
verification = 0


def get_users(SERVER, current_sheet):   # function that gets all the local users from a UNIX sheet
    asic_sheet = ASIC.sheet_by_name(current_sheet)
    max_rows = asic_sheet.nrows
    max_columns = asic_sheet.ncols
    search_column = 2
    current_row = 0
    current_column = 2
    verification = 0 # variable used to determine if the server was found or not in the sheet
    column_account_desc = max_columns - 1  # sometimes the column account description does not exist

    while current_row < max_rows:  # loops through all rows, but only on the C column
        CELL_VALUE = str(asic_sheet.cell_value(current_row, search_column)).replace('\n','')
        pattern_get_server = re.match (".*Server Name.*", CELL_VALUE, re.IGNORECASE) # if the cell with the value Server name is found,
        if pattern_get_server:
            search_column_server = search_column + 1
            server = asic_sheet.cell_value(current_row,search_column_server).replace('\n','')
            pattern_find_server = re.match(".*" + SERVER + ".*", server, re.IGNORECASE) # and the name of the server is in the next cell,
            if pattern_find_server:
                verification = 1 # the verification variable becomes 1

        if verification == 1:
            pattern_get_users = re.match (".*USERNAME.*", CELL_VALUE, re.IGNORECASE) # if this cell is found,
            if pattern_get_users:
                column_username = search_column
                verification = 2

        if verification == 2:  # it will get the columns where the home directory and the user's groups are
            while current_column < max_columns:
                CELL_VALUE = asic_sheet.cell_value(current_row, current_column).replace('\n','')
                pattern_home_directory = re.match(".*Home Directory.*", CELL_VALUE, re.IGNORECASE)
                if pattern_home_directory:
                    column_home_directory = current_column
                pattern_primary_group = re.match("^Primary.*", CELL_VALUE, re.IGNORECASE)
                if pattern_primary_group:
                    column_primary_group = current_column
                pattern_secondary_group = re.match(".*Second.*", CELL_VALUE, re.IGNORECASE)
                if pattern_secondary_group:
                    column_secondary_group = current_column
                pattern_account_desc = re.match(".*Account description.*", CELL_VALUE, re.IGNORECASE)
                if pattern_account_desc: # in case it's a personal account
                    column_account_desc = current_column
                current_column += 1
            verification = 3
            current_row += 1
            continue
            
        pattern_end_users = re.match("^etc..*|For.*Build.*|Send.*applicative.*|.*Additional users will be requested.*",CELL_VALUE,re.IGNORECASE) # this should be the value of the cell where the list of users ends
        if verification == 3:
            if pattern_end_users:
                break
            username = asic_sheet.cell_value(current_row, column_username).replace(" ","")
            home_directory = asic_sheet.cell_value(current_row, column_home_directory).replace('exception','').replace('Exception','').replace(':','')
            if home_directory == None or home_directory == "":
                home_directory = "NO"
            primary_group = asic_sheet.cell_value(current_row, column_primary_group)
            secondary_groups = str(asic_sheet.cell_value(current_row, column_secondary_group)).replace(',',' ').replace(';', ' ')
            skip_choose = re.match(".*choose.*|None|Addtheserver.*", username)
            skip_LDAP = re.match("LDAP",home_directory) # sometimes when the user is a LDAP user, they write in the home directory cell "LDAP"
            account_desc = str(asic_sheet.cell_value(current_row, column_account_desc))
            skip_personal = re.match(".*personal user.*|.*personal account.*|.*pers.*local.*", account_desc, re.IGNORECASE) # or write that in the Account Description column
            if skip_choose or username == "" or skip_LDAP or skip_personal:
                pass
            else:
                f.write(str(username).replace('\n','') +' '+ str(home_directory).replace('\n','') +' '+ str(primary_group).replace('\n','') +' '+ str(secondary_groups).replace('\n',' ') + '\n')
        current_row += 1
    return verification


for ASIC_FILE in ASIC_FILEs:    # going through all ASICs from the CRQ
    ASIC = xlrd.open_workbook(CRQ_DIR + '/' + ASIC_FILE)
    sheets_check = asicop.is_there(ASIC, ITEM) # checking if the server is in the ASIC
    if sheets_check[0] == 1:     # if it is,
        sheet = sheets_check[1]
        verification = get_users(ITEM, sheet) # we get the users out of there
        break
f.close()

        
if len(ASIC_FILEs) == 0:
    print('MANUAL: No ASIC is saved in Documents')
    fileop.remove_output_file(OUTPUT_FILE)
elif sheets_check[0] == 0:
    print('NOT_OK: The server is not present in any of these ASICs: ', ASIC_FILEs)
    fileop.remove_output_file(OUTPUT_FILE)
elif os.stat(OUTPUT_FILE).st_size == 0: # if the file is empty its size will be 0
    print('N/A: No users requested')
    fileop.remove_output_file(OUTPUT_FILE) 
else:
    print('OK')
