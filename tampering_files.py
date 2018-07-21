import os, re



def remove_output_file(file):		# used to delete the output file before rewriting it
	try:
		os.remove(file)
	except:							# in case it does not exist
		pass
		
		
def get_ASIC(dir):
	list_of_asics = []              # the ASICs from a CRQ folder
	list_of_timestamps = []         # the date each ASIC was added
	for i in os.listdir(dir):
		p = re.match(".*ASIC.*", i, re.IGNORECASE)
		if p:
			if i[0] != "~":         # to avoid trying to get data from an open file
				list_of_asics.append(i)
				list_of_timestamps.append(os.path.getctime(dir+"\\"+i))
	if len(list_of_asics) == 0:		# if the list is empty, no ASIC was found
		print("NOT_OK:No ASIC found")
	else:
		the_most_recent_asic = max(list_of_timestamps)
		ASIC = list_of_asics[list_of_timestamps.index(the_most_recent_asic)]
		return ASIC					# only the latest ASIC is needed