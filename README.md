# Tasmota32-Berry-Schema-Validator
 A berry schema validator similar to json schema validators but with a minimal footprint designed to run on the latest development version of Tasmota32 firmware.

 To use place sv.be in the filesystem via Main Menu | Consoles | Manage File System.

 To test the module use Main Menu | Consoles | Berry Scripting Console and try out the code in tests.be.

 The following berry types can be validated: `map`, `list`, `string`, `int`, `real`, `bool` and `nil`.

## Getting Started  

```berry
import sv

var schema = {
    "type": "map",
    "required": true,
    "properties": {
        "title": {
            "type": 'string',
            "required": true
        },
        "author": {
            "type": 'map',
            "required": true,
            "properties": {
                "name": {
                    "type": "string",
                    "required": true
                },
                "age": {
                    "type": 'int',
                    "required": true
                },
                "city": {
                    "type": 'string'
                }
            }
        },
        "related_titles": {
            "type": 'list',
            "required": true,
            "items": {
                "type": 'string'
            }
        }
    }
}

var data = {
    "title": 'A Game of Thrones',
    "author": {
        "name": 'George R. R. Martin'
    },
    "related_titles": [1, 2, 'A Song of Ice and Fire'],
    "extra": 'this will get removed'
}

var result = sv.validate(schema, data)
print(result)
# {
#   'is_valid': false, 
#   'data': {
#     'title': 'A Game of Thrones', 
#     'author': {
#       'name': 'George R. R. Martin'
#     }, 
#     'related_titles': ['A Song of Ice and Fire']
#   }, 
#   'errors': {
#     'related_titles.0': 'type must be string', 
#     'related_titles.1': 'type must be string', 
#     'author.age': 'is required'
#   }
# }
```
## `sv` module


After `import sv` all of the schema validation functionality can be accessed via the `sv` namespace.

Function|Parameters and details
:---|:---
sv.validate|`(schema:map, data:string) -> map`<br>Returns a result as `map`.<br><br> `is_valid` is a `bool` indicating success or failure.<br>`errors` is a `map`. Keys indicate the property path; values describe the validation error.<br>`data` is the cleaned data. Failed attributes are removed.<br><br>Example: `sv.validate({"type":"string", "size":3}, "abc")`
sv.formats</a>|`() -> list`<br>Returns a list of registered formats<br><br>Example: `sv.formats() -> ["%H:%M", "email"]`
sv.add_format|`(format:string, engine:[sv.regex, sv.time], label:string) -> nil`<br><br>Persists `format` to flash for future use. The `label` is used as the lookup key and is the value specified in the schema's format validator. The format validator uses the `engine` (currently either `sv.regex` or `sv.time`) to try and match data using the format. If `sv.regex` is specified, the format validator will treat `format` as a regex ccontaining regex conversion specifiers. If `sv.time` is specified, the format validator will interpret `format` as strftime conversion specifiers. <br><br>Examples:<br>`sv.add_format("^\\S+@\\S+$", sv.regex, "email")`<br>`sv.add_format("%H:%M", sv.time, "%H:%M")`<br>`sv.add_format("%FT%T", sv.time, "iso-8601")`<br><br>`var schema = {"type": "string", "format": "email"}`<br>`var schema = {"type": "string", "format": "%H:%M"}`<br>`var schema = {"type": "string", "format": "iso-8601"}`
sv.remove_format|`(label:string) -> nil`<br>Removes a format from flash using `label`.<br><br>Example: `sv.remove_format('email')`
 
## Validators

### type
* `string` Validates type of value. Can be one of:
  * `"string"`
  * `"int"`
  * `"real"`
  * `"bool"`
  * `"map"`
  * `"list"`

Example of schema:
```berry
{
  "productName": {
    "type": "string"
  }
}
```

Valid object:
```berry
{
  "productName": "ESP32"
}
```

Invalid object:
```berry
{
  "productName": 42
}
```
### required
* `bool` Validates that property exists and not nil.

Example of schema:
```berry
{
  "productName": {
    "required": true
  }
}
```

Valid object:
```berry
{
  "productName": "ESP32"
}
```

Invalid object:
```berry
{
  "productName": nil
}
```

### size
* `int` or `range` Validates that property has the required size. 
  Applies to `string` or `list`.

Example of schema:
```berry
{
  "productName": {
    "type": "string",
    "size": 10..13
  }
}
```

Valid object:
```berry
{
  "productName": "ESP32 Relay"
}
```

Invalid object:
```berry
{
  "productName": "very long product name"
}
```

### values
* `list` Validates that property has one of the provided values. If schema type is `int` or `real` the list of values can be a `range`, e.g., [0,1,10..15] validates if the property is 0, 1 or between 10 and 15.

Example of schema:
```berry
{
  "productName": {
    "type": "string",
    "values": ["pixel", "android"]
  }
}
```

Valid object:
```berry
{
  "productName": "android"
}
```

Invalid object:
```berry
{
  "productName": "iphone"
}
```

### items
* `map` Declares schema for list items. Applies only to type: `list`.

Example of schema:
```berry
{
  "tags": {
    "type": "list",
    "items": {
      "type": "string"
    }
  }
}
```

Valid object:
```berry
{
  "tags": [ "mobile", "phone" ]
}
```

Invalid object:
```berry
{
  "tags": [ 42 ]
}
```
### format

* `string` Declares format string for value. Can be regex or time format string

Example of scheme:

```berry
{
  "time": {
    "type": "string",
    "format": "%H:%M"
  }
}
```

Valid object:
```berry
{
  "time": "10:30"
}
```

Invalid object:
```berry
{
  "productName": "00,15"
}
```

The validator will compile and cache formats should they be used multiple times in the same schema.

## Shortcuts

### Lists
Lists can be declared in two ways:
1. full syntax using `items` validator:
    ```berry
    {
      "tags": {
        "type": "list",
        "items": {
          "type": "string"
        }
      }
    }
    ```
2. shortcut syntax using `[]` (to imply a list) with single element:
    ```berry
    {
      "tags": [{
        "type": "string"
      }]
    }
    ```

The validator expands this shortcut into the full form. Both variants are identical.

## Unknown Keys

* All unknown keys are discarded from the data output.



## Examples

```berry
 import sv

 var schema = {
                "type": "map",
                "properties": {
                    "id": {
                        "type": "int"
                    },
                    "on": {
                        "type": "string",
                        "size": 5,
                        "format": "%H:%M" 
                    },
                    "off": {
                        "type": "string",
                        "size": 5,
                        "format": '%H:%M'
                    },
                    "days": [{
                        "type": "int",
                        "values": [0,1],
                        "size": 7
                    }],
                    "zones": [{
                        "type": "int",
                        "values": [0,1]
                    }],
                    "enabled": {
                        "type": "bool",
                        "required": false
                    },
                    "fruit": {
                        "type": "string",
                        "values": ["apple", "orange"]
                    },
                    "nested": {
                        "type": "map",
                        "properties": {
                            "prop1": {
                                "type": "list",
                                "items": {
                                    "type": "int"
                                }
                            }
                        }
                    }
                }
            }

var data = {
    "id": 9,
    "on": "14:15",
    "off": "10:30",
    "days": [1,0,1,1,1,1,0],
    "zones": [1,0,1],
    "enabled": true,
    "fruit": "apple",
    "nested": {
        "prop1": [1,2,3,4,5,6]
    },
    "another": {}
}

var result = sv.validate(schema, data)
print(result)
# {
#     'is_valid': true, 
#     'data': {
#         'id': 9, 
#         'fruit': 'apple', 
#         'off': '10:30', 
#         'days': [1, 0, 1, 1, 1, 1, 0], 
#         'zones': [1, 0, 1], 
#         'nested': {
#             'prop1': [1, 2, 3, 4, 5, 6]
#         }, 
#         'enabled': true, 
#         'on': '14:15'
#     },
#     'errors': {}
# }

var schema = {
  "type": "string",
  "size": 4 
}
var data = 3
var result = sv.validate(schema,data)
print(result)
# {
#   'is_valid': false, 
#   'data': nil, 
#   'errors': {
#     'root': 'type must be string'
#    }
# }

var schema = [{
  "type": "int",
  "values": [1,2,3],
  "size": 4
}]
var data = [4,2,3,3]
var result = sv.validate(schema, data)
print(result)
# {
#   'is_valid': false, 
#   'data': [2, 3, 3], 
#   'errors': {
#     '0': 'Values must be [1, 2, 3]'
#   }
# }

sv.add_format("^\\S+@\\S+$", sv.regex, "email")

sv.formats()
# ['%H:%M', 'email']

var schema = {
  "type": "string",
  "format": "email",
  "size": 5..50
}
var data = "johnsmith$notreal"
var result = sv.validate(schema,data)
print(result)
# {
#   'is_valid': false, 
#   'data': nil, 
#   'errors': {
#     'root': 'Value does not match email'
#   }
# }

sv.remove_format("email")

var schema = {
  "type": "string",
  "format": "^\\S+@\\S+$",
  "size": 5..50
}
var data = "johnsmith@notreal.com"
var result = sv.validate(schema,data)
print(result)
# {
#   'is_valid': true, 
#   'data': 'johnsmith@notreal.com', 
#   'errors': {}
# }
```

