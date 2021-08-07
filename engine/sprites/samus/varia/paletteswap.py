import os
from PIL import Image

colour_swap_data = {
	"4A2A57": "732100",
	"A542B5": "F76B00",
	"FF8484": "FFBD00",
	"01205A": "003000",
	"02476C": "006300",
	"03A5FC": "00F870",
	"0279B9": "21AD31",
	"FFFFAD": "FFFFAD"
}

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

def hex2rgb(hex: str):
	return tuple(int(hex[i:i+2], 16) for i in (0, 2, 4))
def rgb2hex(rgb: tuple):
	return '{:02x}{:02x}{:02x}'.format(*rgb).upper()

def main():
	files = get_nested_files(os.getcwd(), ["png"])
	for file in files:
		img = Image.open(file)
		pixels = img.load()

		changes_made = False
		for y in range(0, img.size[1]):
		    for x in range(0, img.size[0]):
		    	pixel_colour = rgb2hex(pixels[x,y])
		    	if pixel_colour in colour_swap_data:
		    		changes_made = True
		    		pixels[x,y] = hex2rgb(colour_swap_data[pixel_colour])
		if changes_made:
			img.save(file)


		# for pixel in img.getdata():
		# 	print(pixel.__class__)
		


if __name__ == '__main__':
	main()