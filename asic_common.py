import xlrd, re


def get_sheets(PATTERN, ASIC):                                                  # gets the sheet names from an excel file
    pattern = ".*" + PATTERN + ".*"                                              # using a search pattern
    list_of_sheets = []
    for i in ASIC.sheet_names():                                              # searches through the list with the sheet names
        is_a_match = re.match(pattern, str(i), re.IGNORECASE)            
        if is_a_match and ASIC.sheet_by_name(str(i)).visibility == 0:         # 0 for visible sheets
            list_of_sheets.append(str(i))
    return list_of_sheets
    

def is_there(ASIC, PATTERN, SERVER):
    sheets = get_sheets(PATTERN,ASIC)
    search_column = 2
    current_row = 0
    verification = 0
    for current_sheet in sheets:
        asic_sheet = ASIC.sheet_by_name(current_sheet)
        max_cols = asic_sheet.ncols
        max_rows = asic_sheet.nrows
        current_column = 0
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
                if verification == 1:
                    break
            current_row += 1
        if verification == 1:
            break        
    output_data = (verification, sheets)
    return output_data