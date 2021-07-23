#!/bin/python3

import filecmp
import os

path = "/home/spectre7/Projects/Godot/TNM/scenes/Samus/animations/power_armed.tres"
file = open(path, "r")
to_replace = []

for i, line in enumerate(file.readlines()):
	if not line.startswith('[ext_resource path="res://sprites/samus/power/'):
		continue
	asset = line.split('"')[1].replace("res://", "/home/spectre7/Projects/Godot/TNM/")
	if not os.path.exists(asset.replace("power", "power_armed")):
		continue

	if not filecmp.cmp(asset, asset.replace("power", "power_armed"), shallow=False):
		to_replace.append(line.split('"')[1])

file.close()
file = open(path, "r")
data = file.read()
file.close()

for replacement in to_replace:
	print(data)
	data = data.replace(replacement, replacement.replace("power", "power_armed"))

file = open(path, "w")
file.write(data)
file.close()