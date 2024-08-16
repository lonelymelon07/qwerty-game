class_name Nullable
extends RefCounted

var _value: Variant
var type: Variant.Type
var is_none: bool:
	get:
		return _value == null
var is_some: bool:
	get:
		return _value != null

func _init(val: Variant, type_: Variant.Type, _force: bool = false):
	if not _force:
		push_warning("do not call Nullable.new() directly. Instead use one of either some() or none()")
	
	_value = val
	type = type_

static func some(val: Variant) -> Nullable:
	return Nullable.new(val, typeof(val), true)
	
static func none(type_: Variant.Type) -> Nullable:
	return Nullable.new(null, type_, true)

static func maybe(val: Variant, type_: Variant.Type) -> Nullable:
	if val == null:
		return Nullable.none(type_)
	else:
		return Nullable.some(val)

func unwrap(silent := false) -> Variant:
	if is_none and not silent:
		push_error("Nullable.unwrap() was a none value")
	return _value

func unwrap_or(default: Variant) -> Variant:
	return _value if is_some else default

func unwrap_or_else(f: Callable) -> Variant:
	return _value if is_some else f.call()

func expect(message: String, warning := false) -> Variant:
	if is_none:
		if warning:
			push_warning(message)
		else:
			push_error(message)
	
	return _value
