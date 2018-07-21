import sys, re, math, xlrd
import modules.tampering_files as fileop
import modules.asic_common as asicop


CRQ_DIR = "\\\\qualitycenter.vodafone.com\\data\\" + sys.argv[1].replace(' ', '')  # the CRQ 
ITEM = sys.argv[2].replace(' ', '').upper()                                        # the server
TIER2 = sys.argv[3]                                                                # the tier (UNIX, Windows, etc) ->> this one is important because it's also the name of the sheet from where the data will be gathered
ASIC_FILE = fileop.get_ASIC(CRQ_DIR + '\\')                                        # the most recent ASIC
ASIC = xlrd.open_workbook(CRQ_DIR + '\\' + ASIC_FILE)                              
OUTPUT_FILE = CRQ_DIR + '\\' + ITEM + '_users.txt'                                 # the file where the output of this script will be written
fileop.remove_output_file(OUTPUT_FILE)                                             # if the file already exists it will be deleted
f = open(OUTPUT_FILE, 'a', newline='\n')                                           # open the file in order to have it ready
sheets_list = asicop.get_sheets(TIER2, ASIC)                                       # the list of sheets whose names match the TIER2 variable


def get_users(SERVER, current_sheet):   # function that gets all the local users from a UNIX sheet
    asic_sheet = ASIC.sheet_by_name(current_sheet)
    max_rows = asic_sheet.nrows
    max_columns = asic_sheet.ncols
    search_column = 2
    current_row = 0
    current_column = 2
    verification = 0 # variable used to determine if the server was found or not in the sheet

    while current_row < max_rows:  # loops through all rows, but only on the C column
        CELL_VALUE = asic_sheet.cell_value(current_row, search_column)
        pattern_get_server = re.match (".*Server Name.*", CELL_VALUE, re.IGNORECASE) # if the cell with the value Server name is found,
        if pattern_get_server:
            search_column_server = search_column + 1
            server = asic_sheet.cell_value(current_row,search_column_server).replace('\n','')
            pattern_find_server = re.match(".*" + SERVER + ".*", server, re.IGNORECASE) # and the name of the server is in the next cell,
            if pattern_find_server:
                verification = 1 # the verification variable becomes 1

        if verification == 1:
            pattern_get_users = re.match (".*local functional user.*", CELL_VALUE, re.IGNORECASE) # if this cell is found,
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
                else:
                    column_account_desc = max_columns - 1 # sometimes this column does not exist
                current_column += 1
            verification = 3
            current_row += 1
            continue
            
        pattern_end_users = re.match("^etc..*",CELL_VALUE,re.IGNORECASE) # this should be the value of the cell where the list of users ends
        if verification == 3:
            if pattern_end_users:
                break
            username = asic_sheet.cell_value(current_row, column_username).replace(" ","")
            home_directory = asic_sheet.cell_value(current_row, column_home_directory).replace('exception','').replace(':','')
            if home_directory == None or home_directory == "":
                home_directory = "NO"
            primary_group = asic_sheet.cell_value(current_row, column_primary_group)
            secondary_groups = str(asic_sheet.cell_value(current_row, column_secondary_group)).replace(',',' ')
            skip_choose = re.match(".*choose.*|None", username)
            skip_LDAP = re.match("LDAP",home_directory) # sometimes when the user is a LDAP user, they write in the home directory cell "LDAP"
            account_desc = str(asic_sheet.cell_value(current_row, column_account_desc))
            skip_personal = re.match(".*Personal user.*", account_desc, re.IGNORECASE) # or write that in the Account Description column
            if skip_choose or username == "" or skip_LDAP or skip_personal:
                pass
            else:
                f.write(str(username) +' '+ str(home_directory) +' '+ str(primary_group) +' '+ str(secondary_groups) + '\n')
        current_row += 1
    return verification


if len(sheets_list) == 0:   # if there are no sheets that match the name of the tier2 variable, the script ends
	f.write('MANUAL:No ' + TIER2 + ' sheet found')
else:
	for sheet in sheets_list: # loops through all TIER2 sheets
		verification = get_users(ITEM, sheet)
		if verification == 3: # if the server was found in one of them, the check ends
			break

	if verification == 0: # if the server was not found, an error will be appended to the file
		f.write('MANUAL:' + ITEM + ' not found in ASIC')
f.close()