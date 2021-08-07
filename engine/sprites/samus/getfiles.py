import os, shutil

asset_path = "/home/spectre7/Desktop/ASSETS/sprites/"

def insert(source_str, insert_str, pos):
    return source_str[:pos]+insert_str+source_str[pos:]

def get_nested_files(dir_path: str, allowed_types=None):
	ret = []
	if not dir_path.endswith("/"):
		dir_path += "/"
	for path in os.listdir(dir_path):
		if os.path.isdir(dir_path + path):
			ret += get_nested_files(dir_path + path, allowed_types)
		elif path.split(".")[-1] in allowed_types:
			ret.append(dir_path + path)
	return ret

def main():
	files_to_process = get_nested_files(os.getcwd(), ["png"])
	assets = os.listdir(asset_path)
	
	for file in files_to_process:

		filename = file.split("/")[-1]
		new_filename = insert(filename, "G", 1)

		if new_filename in assets:
			shutil.copyfile(asset_path + new_filename, file)
		else:
			print(filename)

		# print(filename, new_filename)
		# if "NEEDSATTENTION_" in filename:
		# 	os.rename(file, file.replace("NEEDSATTENTION_", ""))
			# shutil.copyfile(asset_path + new_filename, file)



if __name__ == '__main__':
	main()