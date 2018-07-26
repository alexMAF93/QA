import sys, re, math, xlrd
import modules.tampering_files as fileop # common files operations
import modules.asic_common as asicop     # common asic operations


CRQ_DIR = "\\\\qualitycenter.vodafone.com\\data\\" + sys.argv[1].replace(' ', '')  # the CRQ 
ITEM = sys.argv[2].replace(' ', '').upper()                                        # the server
TIER2 = sys.argv[3]                                                                # the tier (UNIX, Windows, etc) ->> this one is important because it's also the name of the sheet from where the data will be gathered
ASIC_FILEs = fileop.get_ASIC(CRQ_DIR + '\\')                                   # the ASICs from the CRQ directory                             
OUTPUT_FILE = CRQ_DIR + '\\' + ITEM + '_localfs.txt'                               # the file where the output of this script will be written
fileop.remove_output_file(OUTPUT_FILE)                                             # if the file already exists it will be deleted
f = open(OUTPUT_FILE, 'a', newline='\n')                                           # open the file in order to have it ready
verification = 0

def isfloat(value): # function that checks if a number is a real number
  try:              # this function is required because the xlrd module
    float(value)    # extracts the size values from ASIC as real values
    return True     # e.g.: 30.0 GB;  but the bash script does not work with
  except ValueError:# real values
    return False


def get_local_fs(SERVER, current_sheet): # function that gets all the local filesystems from an ASIC UNIX sheet
    asic_sheet = ASIC.sheet_by_name(current_sheet)
    max_rows = asic_sheet.nrows
    max_columns = asic_sheet.ncols
    search_column = 2
    current_row = 0
    current_column = 2
    verification = 0

    while current_row < max_rows: # loops through all rows, but only on the C column
        CELL_VALUE = str(asic_sheet.cell_value(current_row, search_column)).replace('\n','')
        pattern_get_server = re.match (".*Server Name.*", CELL_VALUE, re.IGNORECASE) # if the cell with the value Server name is found,
        if pattern_get_server:
            search_column_server = search_column + 1
            server = asic_sheet.cell_value(current_row,search_column_server).replace('\n','')
            pattern_find_server = re.match(".*" + SERVER + ".*", server, re.IGNORECASE) # and the name of the server is in the next cell,
            if pattern_find_server:      
                verification = 1  # the verification variable becomes 1

        if verification == 1:
            pattern_get_fs = re.match (".*local filesystems.*", CELL_VALUE, re.IGNORECASE)  # if this cell is found
            if pattern_get_fs:
                verification = 2
                current_row += 1
                continue

        if verification == 2:  # it will get the columns where the sizes, the ownership and the permissions for the filesystems are
            while current_column < max_columns:
                CELL_VALUE = str(asic_sheet.cell_value(current_row, current_column)).replace('\n','')
                pattern_mount_point = re.match("^Mount Point.*", CELL_VALUE, re.IGNORECASE)
                if pattern_mount_point:
                    column_mount_point = current_column
                pattern_size = re.match("^Size.*", CELL_VALUE, re.IGNORECASE)
                if pattern_size:
                    column_size = current_column
                pattern_ownership = re.match(".*Owner.*", CELL_VALUE, re.IGNORECASE)
                if pattern_ownership:
                    column_ownership = current_column
                pattern_permissions = re.match(".*Permission.*", CELL_VALUE, re.IGNORECASE)
                if pattern_permissions:
                    column_permissions = current_column
                pattern_notes = re.match(".*Notes.*", CELL_VALUE, re.IGNORECASE) # sometimes the mount point is written in the notes column
                if pattern_notes:                                                # sometimes you can find the permissions there
                    column_notes = current_column                                # God help us all 
                current_column += 1        
            verification = 3
            
        pattern_end_fs = re.match("^Total",CELL_VALUE,re.IGNORECASE)   # this should be the value of the cell where the list of filesystems ends
        if verification == 3:
            if pattern_end_fs:
                break
            mount_point = asic_sheet.cell_value(current_row, column_mount_point).replace(" ","") # we do not want white spaces in our mountpoints
            size = asic_sheet.cell_value(current_row, column_size)
            if isfloat(size):
                size = math.ceil(float(asic_sheet.cell_value(current_row, column_size)))
            else:
                skip_size = re.match(".*choose.*|None", size)
                if skip_size:
                    size = 'NO'
            ownership = asic_sheet.cell_value(current_row, column_ownership).replace(':', ' ').replace(',', ' ').replace('.', ' ')
            skip_ownership = re.match(".*choose.*|None|^$", ownership)
            if skip_ownership:
                ownership = 'NO NO'
            if len(ownership.split(' ')) < 2:  # sometimes they just write the user or concatenate the user and the group
                ownership = ownership + ' NO'
            permissions = str(asic_sheet.cell_value(current_row, column_permissions)).replace('.0','') # I guess the isfloat function is pointless now
            if re.match(".*choose.*|None|^$|.*other.*|.*Other.*", permissions):
                permissions = 'NO'
            notes = asic_sheet.cell_value(current_row, column_notes).replace(" ", "")
            notes_exception = re.match(".*exception.*|.*Exception.*", mount_point)
            skip_choose = re.match(".*choose.*|None|.*MountPoint.*", mount_point)
            if notes_exception:
                f.write(str(notes) +' '+ str(size) +' '+ str(ownership) +' '+ str(permissions) + '\n')
            elif skip_choose or mount_point == "":
                pass
            else:
                f.write(str(mount_point).replace('exception:', '') +' '+ str(size) +' '+ str(ownership) +' '+ str(permissions) + '\n')
        current_row += 1
    return verification

    
for ASIC_FILE in ASIC_FILEs:
    ASIC = xlrd.open_workbook(CRQ_DIR + '\\' + ASIC_FILE)
    sheets_check = asicop.is_there(ASIC, TIER2, ITEM)
    if sheets_check[0] == 1:
        print(sheets_check, ASIC_FILE)
        sheets_list = sheets_check[1]                                       # the list of sheets whose names match the TIER2 variable
        for sheet in sheets_list:  # loops through all TIER2 sheets
            verification = get_local_fs(ITEM, sheet)
            if verification == 3:  # if the server was found in one of them, the check ends
                break

        if verification != 0:   # if the server was found, we stop checking other ASICs
            break
            
if verification == 0:   # if the server was not found, an error will be appended to the file
    f.write('MANUAL:' + ITEM + ' not found in ASIC')
	
f = open(OUTPUT_FILE, 'r')
print(f.readlines())
f.close()