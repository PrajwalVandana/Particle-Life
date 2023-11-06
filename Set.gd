class_name Set
extends Object


var _dict: Dictionary = {}
var _iteration_list: Array[Variant] = []
var _cur_iter: Variant


func _init():
    _dict = Dictionary()


func add(v: Variant) -> void:
    _dict[v] = true


func erase(v: Variant) -> void:
    _dict.erase(v)


func has(v: Variant) -> bool:
    return _dict.has(v)


func size() -> int:
    return _dict.size()


func clear() -> void:
    _dict.clear()


func find(v: Variant) -> Variant:
    return _dict.find_key(v)


func is_empty() -> bool:
    return _dict.is_empty()


func merge(other: Set) -> void:
    _dict.merge(other._dict)


func _should_continue_iter() -> bool:
    return _cur_iter < _iteration_list.size()


func _iter_init(_arg):
    _iteration_list = _dict.keys()
    _cur_iter = 0
    return _should_continue_iter()


func _iter_next(_arg):
    _cur_iter += 1
    return _should_continue_iter()


func _iter_get(_arg):
    return _iteration_list[_cur_iter]