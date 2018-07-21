import xlrd, re


def get_sheets(PATTERN, ASIC):											      # gets the sheet names from an excel file
    pattern = ".*" + PATTERN + ".*"											  # using a search pattern
    list_of_sheets = []
    for i in ASIC.sheet_names():											  # searches through the list with the sheet names
        is_a_match = re.match(pattern, str(i), re.IGNORECASE)			
        if is_a_match and ASIC.sheet_by_name(str(i)).visibility == 0:         # 0 for visible sheets
            list_of_sheets.append(str(i))
    return list_of_sheets