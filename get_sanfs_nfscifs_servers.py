import sys, re, math, xlrd
import modules.tampering_files as fileop
import modules.asic_common as asicop


CRQ_DIR = "\\\\qualitycenter.vodafone.com\\data\\" + sys.argv[1].replace(' ', '')   # the CRQ 
ITEM = sys.argv[2].replace(' ', '').upper()                                         # the server
TYPE = sys.argv[3]  # can be either CIFS or SAN                                       whether the check is for SAN or CIFS filesystems ->> this one is important because it's also the name of the sheet from where the data will be gathered
ASIC_FILE = fileop.get_ASIC(CRQ_DIR + '\\')                                         # the most recent ASIC
ASIC = xlrd.open_workbook(CRQ_DIR + '\\' + ASIC_FILE)                               
OUTPUT_FILE = CRQ_DIR + '\\' + ITEM + '_' + TYPE + '.txt'                           # the file where the output of this script will be written
fileop.remove_output_file(OUTPUT_FILE)                                              # if the file already exists it will be deleted
f = open(OUTPUT_FILE, 'a', newline='\n')                                            # open the file in order to have it ready
sheets_list = asicop.get_sheets(TYPE, ASIC)                                         # the list of sheets whose names match the TIER2 variable
verification = 0


def isfloat(value):  # function that checks if a number is a real number
  try:               # this function is required because the xlrd module
    float(value)     # extracts the size values from ASIC as real values
    return True      # e.g.: 30.0 GB;  but the bash script does not work with
  except ValueError: # real values
    return False


def get_nfs(SERVER, current_sheet):  # function that gets all the NFS CIFS or SAN filesystem from an ASIC
    asic_sheet = ASIC.sheet_by_name(current_sheet)
    max_rows = asic_sheet.nrows
    max_columns = asic_sheet.ncols
    search_column = 2
    current_row = 0
    current_column = 2
    verification = 0
    is_there = 0

    while current_row < max_rows: # loops through all rows, but only on the C column
        CELL_VALUE = str(asic_sheet.cell_value(current_row, search_column))
        column_server = current_column
        pattern_get_server = re.match (".*Server.*Name.*", CELL_VALUE, re.IGNORECASE) # if the cell with the value Server name is found,
        if pattern_get_server:
            while current_column < max_columns:  # we'll get the columns where the mount points, sizes, ownership and permissions are
                CELL_VALUE = asic_sheet.cell_value(current_row, current_column)
                pattern_mount_point = re.match("^Mount.*Point.*", CELL_VALUE, re.IGNORECASE)
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
                current_column += 1        
            current_row += 1
            verification = 1
            continue  # the columns have been identified
            
        if verification >= 1:  # if the columns have been identified and/or mount points for the server have already been found
            pattern_server = re.match (".*" + SERVER + ".*|.*all.*|^$", str(CELL_VALUE).replace('\n', ' '), re.IGNORECASE)
            if pattern_server:  # if the server is found, or "all" or nothing at all,
                mount_point = asic_sheet.cell_value(current_row, column_mount_point).replace(" ","")
                skip_choose = re.match(".*choose.*|None|.*MountPoint.*", mount_point)
                if skip_choose or mount_point == "":
                    pass
                else:
                    is_there = 10   # we have this variable to tell us that at least a filesystem was found for our server
                    verification = 2 # the server was found, let's get the rest
            
        if verification == 2: 
            size = asic_sheet.cell_value(current_row, column_size)
            if isfloat(size):
                size = math.ceil(float(asic_sheet.cell_value(current_row, column_size)))
            else:
                skip_size = re.match(".*choose.*|None|^$", size)
                if skip_size:
                    size = 'NO'
            ownership = asic_sheet.cell_value(current_row, column_ownership).replace(':', ' ').replace(',', ' ').replace('.', ' ')
            skip_ownership = re.match(".*choose.*|None|^$", ownership)
            if skip_ownership:
                ownership = 'NO NO'
            if len(ownership.split(' ')) < 2:
                ownership = ownership + ' NO'
            permissions = str(asic_sheet.cell_value(current_row, column_permissions)).replace('.0','')
            if re.match(".*choose.*|None|^$|.*Other.*|.*other.*", permissions):
                permissions = 'NO'
            skip_choose = re.match(".*choose.*|None|.*MountPoint.*", mount_point)
            if not skip_choose and not mount_point == "":
                f.write(str(mount_point).replace('exception:', '') +' '+ str(size) +' '+ str(ownership) +' '+ str(permissions) + '\n')
        current_row += 1
    return verification + is_there


if len(sheets_list) == 0:  # if there are no SAN/NFS CIFS sheets, the test is not applicable
    f.write('N/A:No ' + TYPE + ' sheet found')
else:
    for sheet in sheets_list:
        verification = verification + get_nfs(ITEM, sheet)

    if verification == 1:  # if there are no requeste NFS CIFS/SAN filesystems for the server, the test is not applicable
        f.write('N/A:' + ITEM + ' not found in ASIC in the ' + TYPE + ' sheet(s)')
f.close()