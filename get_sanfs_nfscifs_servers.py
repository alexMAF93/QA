#!/opt/SP/python/python/bin/python3.6


import sys, re, math, xlrd
import modules.tampering_files as fileop
import modules.asic_common as asicop


CRQ_DIR = "/opt/oquat/qualitycenter/web/files/" + sys.argv[1].replace(' ', '')   # the CRQ 
ITEM = sys.argv[2].replace(' ', '').upper()                                         # the server
TYPE = []                                                             # the type if OS, Unix or Windows
TYPE.append(sys.argv[3])                                                             # the type if OS, Unix or Windows)
ASIC_FILEs = fileop.get_ASIC(CRQ_DIR + '/')                                      # ASICs from the CRQ directory                            
OUTPUT_FILE = CRQ_DIR + '/' + ITEM + '_' + TYPE[0] + '.txt'                           # the file where the output of this script will be written
fileop.remove_output_file(OUTPUT_FILE)                                              # if the file already exists it will be deleted
f = open(OUTPUT_FILE, 'a', newline='\n')                                            # open the file in order to have it ready
verification = 0


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
        CELL_VALUE = str(asic_sheet.cell_value(current_row, search_column)).replace('\n','')
        column_server = current_column
        pattern_get_server = re.match (".*Server.*Name.*", CELL_VALUE, re.IGNORECASE) # if the cell with the value Server name is found,
        if pattern_get_server:
            while current_column < max_columns:  # we'll get the columns where the mount points, sizes, ownership and permissions are
                CELL_VALUE = str(asic_sheet.cell_value(current_row, current_column)).replace('\n','')
                pattern_mount_point = re.match(".*Mount.*Point.*", CELL_VALUE, re.IGNORECASE)
                if pattern_mount_point:
                    column_mount_point = current_column
                pattern_size = re.match(".*Size.*", CELL_VALUE, re.IGNORECASE)
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
                    is_there = 100   # we have this variable to tell us that at least a filesystem was found for our server
                    verification = 2 # the server was found, let's get the rest
            
        if verification == 2: 
            size = str(asic_sheet.cell_value(current_row, column_size))
            skip_size = re.match(".*choose.*|None|^$", size)
            if skip_size or size == "":
                size = 'NO'
            ownership = asic_sheet.cell_value(current_row, column_ownership).replace(':', ' ').replace(',', ' ').replace('.', ' ').replace('/', ' ')
            skip_ownership = re.match(".*choose.*|None|^$", ownership)
            if skip_ownership:
                ownership = 'NO NO'
            if len(ownership.split(' ')) < 2:
                ownership = ownership + ' NO'
            permissions = str(asic_sheet.cell_value(current_row, column_permissions)).replace('.0','')
            if re.match(".*choose.*|None|^$|.*Other.*|.*other.*", permissions):
                permissions = 'NO'
            skip_choose = re.match(".*choose.*|None|.*MountPoint.*|-", mount_point)
            if not skip_choose and not mount_point == "":
                f.write(str(mount_point).replace('exception:', '').replace('SoftLink:','').replace('\n','') +' '+ str(size) +' '+ str(ownership) +' '+ str(permissions) + '\n')
            verification = 1
        current_row += 1
    return verification + is_there

    
for ASIC_FILE in ASIC_FILEs:  # trying all ASICs from a CRQ
    ASIC = xlrd.open_workbook(CRQ_DIR + '/' + ASIC_FILE)
    sheets_check = asicop.is_there(ASIC, ITEM)
    if sheets_check[0] == 0:
        continue
    else:    # if the server is in that ASIC,
        sheets_type = asicop.get_sheets(TYPE, ASIC)
        if len(sheets_type) == 0:
            verification = 100
            break
        else:
            for sheet in asicop.get_sheets(TYPE, ASIC):
                verification = verification + get_nfs(ITEM, sheet) # the filesystems are retrieved
    break
f.close()


if len (ASIC_FILEs) == 0:
    print('MANUAL: No ASIC was saved in Documents')
    fileop.remove_output_file(OUTPUT_FILE)
elif sheets_check[0] == 0:
    print('NOT_OK: The server is not present in any of these ASICs: ', ASIC_FILEs)
    fileop.remove_output_file(OUTPUT_FILE)
elif len(sheets_type) == 0:
    print('N/A: There is no ' + TYPE[0] + ' sheet in ' + ASIC_FILE)
    fileop.remove_output_file(OUTPUT_FILE)
elif verification < 100:        # no filesystems have been found for that server
    print('N/A:' + ITEM + ' not found in ' + ASIC_FILE + ' in the ' + TYPE[0] + ' sheet(s)\n')
    fileop.remove_output_file(OUTPUT_FILE)
else:
    print('OK')
