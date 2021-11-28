import sv

sv.formats()
# ['%H:%M']

var schema = {
                "type": "map",
                "properties": {
                    "id": {
                        "type": "int"
                    },
                    "on": {
                        "type": "string",
                        "size": 5..7,
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
print(result.isValid)
print(result.errors)
print(result.data)
# true
# {}
# {'id': 9, 'fruit': 'apple', 'off': '10:30', 'days': [1, 0, 1, 1, 1, 1, 0], 'zones': [1, 0, 1], 'nested': {'prop1': [1, 2, 3, 4, 5, 6]}, 'enabled': true, 'on': '14:15'}

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
        "name": 'George R. R. Marti'
    },
    "related_titles": [1, 2, 'A Song of Ice and Fire'],
    "extra": 'this will get removed'
}

var result = sv.validate(schema, data)
print(result.isValid)
print(result.errors)
print(result.data)
# false
# {'related_titles.0': 'type must be string', 'related_titles.1': 'type must be string', 'author.age': 'is required'}
# {'title': 'A Game of Thrones', 'author': {'name': 'George R. R. Marti'}, 'related_titles': ['A Song of Ice and Fire']}

var schema = {
  "type": "string",
  "size": 4 
}
var data = 'test'
var result = sv.validate(schema, data)
print(result.isValid)
print(result.errors)
print(result.data)
# true
# {}
# test

var schema = {
  "type": "string",
  "size": 4 
}
var data = 3
var result = sv.validate(schema,data)
print(result.isValid)
print(result.errors)
print(result.data)
# false
# {'root': 'type must be string'}
# nil

var schema = [{
  "type": "int",
  "values": [1,2,3],
  "size": 4
}]
var data = [4,2,3,3]
var result = sv.validate(schema, data)
print(result.isValid)
print(result.errors)
print(result.data)
# false
# {'0': 'Values must be [1, 2, 3]'}
# [4, 2, 3, 3]


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
print(result.isValid)
print(result.errors)
print(result.data)
# false
# {'root': 'Value does not match email'}
# johnsmith$notreal

sv.remove_format("email")

var schema = {
  "type": "string",
  "format": "^\\S+@\\S+$",
  "size": 5..50
}
var data = "johnsmith@notreal.com"
var result = sv.validate(schema,data)
print(result.isValid)
print(result.errors)
print(result.data)
# true
# {}
# johnsmith@notreal.com

var schema = [{
  "type": "real",
  "size": 4
}]
var data = [4.3,2.2,3.4,3.7]
var result = sv.validate(schema, data)
print(result.isValid)
print(result.errors)
print(result.data)
# true
# {}
# [4.3, 2.2, 3.4, 3.7]
