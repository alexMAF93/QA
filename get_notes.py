#!/opt/SP/python/python/bin/python3.6


import sys,csv, os, re, xlrd


OUTPUT_FILE = 'output.txt'
U_CODE = ['\u25cb', '\u2019', '\xa0', '\uf075', '\u2013', '\uf0a7', '\u201d','\u2022', '\u2026', '\u201c', '\u201e']


def get_ASIC(dir):
   list_of_ASICs = []

   for i in os.listdir(dir):
       list_of_ASICs.append(i)

   return list_of_ASICs


def get_sheets(PATTERN):                                                  # gets the sheet names from an excel file
    list_of_sheets = []
    for ppattern in PATTERN:
        pattern = ".*" + ppattern + ".*"                                              # using a search pattern
        for i in ASIC.sheet_names():                                              # searches through the list with the sheet names
            is_a_match = re.match(pattern, str(i), re.IGNORECASE)            
            if is_a_match and ASIC.sheet_by_name(str(i)).visibility == 0:         # 0 for visible sheets
                list_of_sheets.append(str(i))
    return list_of_sheets



def get_data_notes(current_sheet):
    asic_sheet = ASIC.sheet_by_name(current_sheet)
    max_rows = asic_sheet.nrows
    max_columns = asic_sheet.ncols
    search_column = 2
    current_row = 2
    current_column = 2


    def search_through_notes(limit):
        counter = 0
        for current_row in range(1,limit):
            for CELL in asic_sheet.row(current_row):
                for i in U_CODE:
                    CELL.value = CELL.value.replace(i,'')
                if CELL.value != "" and CELL.value != "NOTES" and CELL.value != "Notes" and CELL.value != "notes":
                    counter += 1
                    try:
                        f.write(CELL.value + '\n')
                    except:
                        print('something awful happened ')
        if counter == 0:
            f.write('Empty field\n')

    
    if max_rows < 100:
         search_through_notes(max_rows)
    else:
         search_through_notes(100)


def get_CRQ_project(current_sheet):
    asic_sheet = ASIC.sheet_by_name(current_sheet)
    max_rows = asic_sheet.nrows
    max_columns = asic_sheet.ncols
    search_column = 2
    current_row = 2
    current_column = 2
    counter = 0
    CRQ = asic[asic.find('CRQ'):asic.find('CRQ')+15]
    f.write('CRQ: ' + CRQ + '\n')
    while current_row < max_rows:
        CELL_VALUE = str(asic_sheet.cell_value(current_row, search_column)).replace('\n','')
        pattern_get_ProjectRLM = re.match (".*CRQ.*", CELL_VALUE,re.IGNORECASE)
        if pattern_get_ProjectRLM:
            current_column +=2
            CELL_VALUE = str(asic_sheet.cell_value(current_row, current_column)).replace('\n','')
            f.write("\n\n\nRLM/CRQ: " + CELL_VALUE + '\n')
            break
        current_row += 1


def get_notes_UWOS(current_sheet):
    asic_sheet = ASIC.sheet_by_name(current_sheet)
    max_rows = asic_sheet.nrows
    max_columns = asic_sheet.ncols
    search_column = 2
    current_row = 2
    current_column = 2
    verification = 0
    counter = 0
    CONFIGURATION_ITEM = "NOT_AVAILABLE"
    NOTES = ""

    while current_row < max_rows:
        CELL_VALUE = asic_sheet.cell_value(current_row, search_column)
        for i in U_CODE:
            CELL_VALUE = CELL_VALUE.replace(i,'')
        pattern_sql_sheet = re.match (".*SQL.*", str(current_sheet), re.IGNORECASE)
        if pattern_sql_sheet:
            pattern_databases = re.match("DATABASES.*", CELL_VALUE, re.IGNORECASE)
            if pattern_databases:
                search_row = current_row + 1
                DBs_NAMES = [] 
                CONFIGURATION_ITEM = ""
                while search_row < max_rows:
                    CELL_VALUE = str(asic_sheet.cell_value(search_row, search_column))
                    for i in U_CODE:
                        CELL_VALUE = CELL_VALUE.replace(i,'')
                    pattern_stop_sql = re.match("add more lines.*|USERS\*.*", CELL_VALUE, re.IGNORECASE)
                    if CELL_VALUE != "" and not pattern_stop_sql:
                        DBs_NAMES.append(CELL_VALUE)
                    if pattern_stop_sql and len(DBs_NAMES) > 0:
                        for name in DBs_NAMES:
                            CONFIGURATION_ITEM += str(name) + ' '
                        break
                    search_row += 1
                if CONFIGURATION_ITEM == "":
                    CONFIGURATION_ITEM = "NOT_AVAILABLE"
                if NOTES == "":
                    NOTES = "Empty field"
                f.write('Configuration Item(s): ' + CONFIGURATION_ITEM + '\n\nNotes:\n' + NOTES + '\n')
                counter += 1
                NOTES = ""

                
                
        pattern_db_server = re.match('DB.*Name.*|Server.*Name.*', CELL_VALUE, re.IGNORECASE)
        if pattern_db_server and not pattern_sql_sheet:
            CONFIGURATION_ITEM = str(asic_sheet.cell_value(current_row, search_column + 1)).replace('\n', ' ') 
        pattern_get_notes = re.match (".*Please.*specify.*all.*additional.*or.*non.*standard.*configuration.*requirements.*below.*", CELL_VALUE,re.IGNORECASE)
        pattern_stop = re.match(".*add more boxes for more unix-server.*|^$|DATABASES \#.*|UNIX.*SERVER.*\#.*|WINDOWS.*SERVER.*\#.*", CELL_VALUE, re.IGNORECASE)
        if pattern_get_notes:
            current_row += 1
            verification = 1
            continue
    
        if verification == 1 and not pattern_stop and CELL_VALUE != "" and not pattern_sql_sheet:
           try:
               f.write('Configuration Item(s): ' + CONFIGURATION_ITEM + '\n\nNotes:\n' + CELL_VALUE + '\n')
               counter += 1
           except:
               print('Something happened :O')
        elif verification == 1 and not pattern_stop and CELL_VALUE != "" and pattern_sql_sheet:
           NOTES += CELL_VALUE + '\n'
        if pattern_stop:
            verification = 0
    
        current_row += 1
    if counter == 0:
        f.write('Empty field\n')


cnt = 0
for asic in get_ASIC('frozen ASICs/'):
    FILE='frozen ASICs/'+asic
    ASIC=xlrd.open_workbook(FILE)
    print(cnt,FILE)
    f = open(OUTPUT_FILE, 'w', newline='\r\n')
    get_CRQ_project(get_sheets(["Project"])[0])
    for sheet in get_sheets(["UNIX", "WINDOWS", "ORACLE", "SQL"]):
        f.write('\n'+'-'*50+'\n')
        f.write(sheet+' sheet notes:\n'+'-'*50+'\n')
        get_notes_UWOS(sheet)
    for sheet in get_sheets(["Notes"]):
        f.write('\n'+'-'*50+'\n')
        f.write(sheet+' sheet notes:\n'+'-'*50+'\n')
        get_data_notes(sheet)
    f.write('\n' + '#'*100+'\n\n')
    f.write('#'*100+'\n\n')
    f.write('#'*100+'\n\n')
    f.close()

    with open('output.txt', 'r') as in_file:
        stripped = (line.strip() for line in in_file)
        lines = (line.split(",") for line in stripped if line)
        with open('result.csv', 'a') as out_file:
            writer = csv.writer(out_file, delimiter='|', lineterminator='\n')
            writer.writerows(lines)



    cnt+=1
