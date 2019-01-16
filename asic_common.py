import xlrd, re


def get_sheets(PATTERN, ASIC):                                                  # gets the sheet names from an excel file
    list_of_sheets = []
    for ppattern in PATTERN:
        pattern = ".*" + ppattern + ".*"                                              # using a search pattern
        for i in ASIC.sheet_names():                                              # searches through the list with the sheet names
            is_a_match = re.match(pattern, str(i), re.IGNORECASE)            
            if is_a_match and ASIC.sheet_by_name(str(i)).visibility == 0:         # 0 for visible sheets
                list_of_sheets.append(str(i))
    return list_of_sheets
    

def is_there(ASIC, SERVER):         # function used to find the ASIC where a server is requested when there are multiple ASICs
    PATTERN = [ 'UNIX', 'NODE', 'VM' ]
    sheets = get_sheets(PATTERN, ASIC)        # in a CRQ
    search_column = 2                        # this function returns a tuple made of an integer that 
    current_row = 0                            # is 1 if the server is in the ASIC or 0 otherwise
    verification = 0                        # and the sheet where the server was found
    for current_sheet in sheets:    
        asic_sheet = ASIC.sheet_by_name(current_sheet)
        max_cols = asic_sheet.ncols
        max_rows = asic_sheet.nrows
        current_column = 0
        current_row = 0
        while current_row < max_rows:
            current_column = search_column
            CELL_VALUE = str(asic_sheet.cell_value(current_row, search_column)).replace('\n','')
            pattern_server_name = re.match ('.*Server.*Name.*', CELL_VALUE, re.IGNORECASE)
            if pattern_server_name:
                current_column += 1
                while current_column < max_cols:
                    CELL_VALUE = str(asic_sheet.cell_value(current_row, current_column)).replace('\n','')
                    server_is_there = re.match ('.*' + SERVER + '.*', CELL_VALUE, re.IGNORECASE)
                    if server_is_there:
                        verification = 1
                        break
                    current_column += 1
                    continue
                if verification == 1:
                    break
            current_row += 1
        if verification == 1:
            break        
    output_data = (verification, current_sheet)  # this is the tuple
    return output_data
