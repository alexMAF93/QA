import sys, re, math, xlrd
import modules.tampering_files as fileop  # common files operations
import modules.asic_common as asicop      # common asic operations


CRQ_DIR = "\\\\qualitycenter.vodafone.com\\data\\" + sys.argv[1].replace(' ', '') # the CRQ 
ITEM = sys.argv[2].replace(' ', '').upper()                                       # the server
TIER2 = sys.argv[3]                                                               # the tier (UNIX, Windows, etc) ->> this one is important because it's also the name of the sheet from where the data will be gathered
ASIC_FILEs = fileop.get_ASIC(CRQ_DIR + '\\')                                       # the ASICs from the CRQ directory
OUTPUT_FILE = CRQ_DIR + '\\' + ITEM + '_BS.txt'                                   # the file where the output of this script will be written
fileop.remove_output_file(OUTPUT_FILE)                                            # if the file already exists it will be deleted
f = open(OUTPUT_FILE, 'a', newline='\n')                                          # open the file in order to have it ready
verification = 0


def get_Environment(SERVER, current_sheet): # function used to get the Environment
    asic_sheet = ASIC.sheet_by_name(current_sheet)
    max_rows = asic_sheet.nrows
    max_columns = asic_sheet.ncols
    search_column = 2 # the C column
    current_row = 0
    current_column = 2
    ENVIRONMENT = "Not Found"   # default values
    
    while current_row < max_rows:    # loops through all rows, but only on the C column
        CELL_VALUE = str(asic_sheet.cell_value(current_row, search_column)).replace('\n','')
        pattern_get_env = re.match (".*Environment.*", CELL_VALUE, re.IGNORECASE) # if it finds the cell with the value Environment
        if pattern_get_env:
            search_column_env = search_column + 2   # it will keep the value that is two cells to the right
            ENVIRONMENT = str(asic_sheet.cell_value(current_row,search_column_env)).replace('\n','') 
            if ENVIRONMENT == "" or ENVIRONMENT == "other": # if nothing is found, it will also check the Notes column
                search_column_env = search_column_env + 1
                ENVIRONMENT = str(asic_sheet.cell_value(current_row,search_column_env)).replace('\n','')
            break
        current_row += 1
    return ENVIRONMENT
    

def get_BS(SERVER, current_sheet):  # function used to get the Business Service Name and the Service Class
    asic_sheet = ASIC.sheet_by_name(current_sheet)
    max_rows = asic_sheet.nrows
    max_columns = asic_sheet.ncols
    search_column = 2
    current_row = 0
    current_column = 2
    verification = 0  # variable used to determine if the server was found or not in the sheet

    while current_row < max_rows:
        CELL_VALUE = str(asic_sheet.cell_value(current_row, search_column)).replace('\n','')
        pattern_get_server = re.match (".*Server Name.*", CELL_VALUE, re.IGNORECASE)   # if the cell with the value Server name is found,
        if pattern_get_server:
            search_column_server = search_column + 1
            server = asic_sheet.cell_value(current_row,search_column_server).replace('\n','') # it will take the value of the next cell to the right
            pattern_find_server = re.match(".*" + SERVER + ".*", server, re.IGNORECASE)       # if the value matches the name of the server, verification=1
            if pattern_find_server:
                verification = 1

        if verification >= 1: # if the searched server was found,
            pattern_get_bs = re.match (".*Business.*Service.*", CELL_VALUE, re.IGNORECASE)    # searches the cells where is BS and Service Class are
            if pattern_get_bs:
                business_service = str(asic_sheet.cell_value(current_row, search_column + 1)).replace('\n','')
                verification = 2
            pattern_get_sc = re.match (".*Service.*Class.*", CELL_VALUE, re.IGNORECASE)
            if pattern_get_sc:
                service_class = str(asic_sheet.cell_value(current_row, search_column + 1)).replace('\n','')
                verification = 3
        
        if verification == 3: # if both have been found, exits the loop
            break
        current_row += 1
        
    f.write(str(business_service) + '\n' + str(service_class) + '\n') # and writes the result in the output file
    return verification


for ASIC_FILE in ASIC_FILEs:
	ASIC = xlrd.open_workbook(CRQ_DIR + '\\' + ASIC_FILE)
	sheets_check = asicop.is_there(ASIC, TIER2, ITEM)
	if sheets_check[0] == 1:
		sheets_list = sheets_check[1]
		for sheet in sheets_list: # loops through all TIER2 sheets
			verification = get_BS(ITEM, sheet)
			if verification == 3: # if the server was found in one of them, the check ends
				break
					
		for sheet in asicop.get_sheets("PROJECT", ASIC):
			ENVIRONMENT = re.sub('\s+', ' ', get_Environment(ITEM, sheet).replace('&', ' '))
		f.write(ENVIRONMENT)
		if verification != 0:
			break
			
if verification == 0: # if the server was not found, an error will be appended to the file
	f.write('MANUAL:' + ITEM + ' not found in ASIC')
f.close()