# Project formatting



```python
signal this_is_a_signal

func foo_bar(used_parameter: Array, _unused_parameter: Dictionary = {}):
	var standard_variable: String = "Double quotes"
    var ClassVariable: PackedScene = preload("res://engine/scenes/samus/samus.tscn")
    var classInstance: KinematicBody2D = ClassVariable.instance()
    var class_instances: Array = [classInstance] + used_parameter
        
    for i in range(len(class_instances)):
		print(class_instances)
    
```

