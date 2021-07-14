extends Node2D
class_name LayerSetter

export(Enums.Layers) var z_layer: int = 0
export(Enums.CanvasLayers) var canvas_layer: int = 0
export(Array, NodePath) var z_layer_nodes: = []
export(Array, NodePath) var canvas_layer_nodes: = []
export var apply_z_layer_to_parent: bool = true
export var apply_canvas_layer_to_parent: bool = false

func _ready():
	for path in z_layer_nodes + ([".."] if apply_z_layer_to_parent else []):
		var node: Node2D = get_node(path)
		node.z_as_relative = false
		node.z_index = z_layer
	for path in canvas_layer_nodes + ([".."] if apply_canvas_layer_to_parent else []):
		var node: CanvasLayer = get_node(path)
		node.layer = canvas_layer - 5
