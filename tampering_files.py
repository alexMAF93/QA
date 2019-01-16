import os, re



def remove_output_file(file):		# used to delete the output file before rewriting it
	try:
		os.remove(file)
	except:							# in case it does not exist
		pass
		
		
def get_ASIC(dir, TYPE = "ASIC"):
	list_of_asics = []              # the ASICs from a CRQ folder
	list_of_timestamps = []         # the date each ASIC was added
	ASIC = []						# the list with ASICs in reverse chronological order
	for i in os.listdir(dir):
		p = re.match(".*" + TYPE + ".*", i, re.IGNORECASE)
		if p:
			if i[0] != "~":         # to avoid trying to get data from an open file
				list_of_asics.append(i)
				list_of_timestamps.append(os.path.getctime(dir+"/"+i))
	while len(list_of_timestamps) > 0:
		the_most_recent_asic = max(list_of_timestamps)
		index_the_most_recent_asic = list_of_timestamps.index(the_most_recent_asic)
		ASIC.append(list_of_asics[index_the_most_recent_asic])
		list_of_asics.remove(list_of_asics[index_the_most_recent_asic])
		list_of_timestamps.remove(list_of_timestamps[index_the_most_recent_asic])
	return ASIC					# ASICs in reverse chronological order
