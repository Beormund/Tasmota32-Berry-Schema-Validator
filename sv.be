import persist

var sv = module('sv')

def gettype(data)
    var t = type(data)
    return t == 'instance' ? classname(data) : t
end

class PatternMatch
    static regex = "regex"
    static time = "strptime"
    static formats = {}
    static def load()
        if persist.has('sv_formats')
            PatternMatch.formats = persist.sv_formats
        else
            persist.sv_formats = {
                "%H:%M": {
                    "validator": "regex",
                    "pattern": "^(0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]$"
                }
            }
            PatternMatch.formats = persist.sv_formats
        end
    end
    static def get_formats()
        var l = []
        for k: PatternMatch.formats.keys()
            l.push(k)
        end
        return l 
    end
    static def add_format(pattern, engine, value)
        if type(pattern) != 'string' return end
        if type(value) != 'string' return end
        if engine != PatternMatch.regex && engine != PatternMatch.time
            return
        end
        PatternMatch.formats.setitem(
            value, {"validator": engine, "pattern": pattern}
        )
        persist.save()
    end
    static def remove_format(key)
        PatternMatch.formats.remove(key)
        persist.save()
    end
end

class FormatValidator
    var _compiled
    def init()
        self._compiled = {}
    end
    def match(format, value)
        var found = PatternMatch.formats.find(format)
        if found != nil
            var engine = self.invoke(found['validator'])
            if engine !=nil 
                return !!engine(self, found['pattern'], value)
            end
        end
        return !!self.regex(format, value)
    end
    def invoke(engine)
        return {
            PatternMatch.regex: self.regex,
            PatternMatch.time: self.strptime
        }.find(engine)
    end
    def regex(pattern, value)
        import re
        # If the compiled regex is not cached, compile and cache
        if !self._compiled.contains(pattern)
            self._compiled[pattern] = re.compile(pattern)
        end
        return self._compiled[pattern].match(value)
    end
    def strptime(pattern, value)
        return false
        # For future implementation of strptime()
    end
end
   
class Validate
    var node, name, path, errors, value, fv
    def addError(error)
        var path = self.path[1..]
        path.push(self.name)
        path = path.concat('.')
        self.errors[path] = error
    end
    def isValid(node, data, name, path, errors)
        self.node = node
        self.name = name
        self.path = path
        self.errors = errors
        self.value = data.contains(name) ? data[name] : nil
        if !self.isValidRequired()
            self.addError('is required')
            return false
        end
        if self.value == nil
            return true
        end
        if !self.isValidType()
            self.addError('type must be ' .. self.node['type'])
            return false;
        end
        if !self.isValidSize()
            self.addError('size must be '.. self.node['size'])
        end
        if !self.isValidValues()
            self.addError('Values must be '.. self.node['values'])
        end
        if !self.isValidFormat() 
            self.addError('Value does not match '.. self.node['format'])
        end
        return true
    end
    def isValidRequired()
        var required = self.node.find('required')
        return !(self.value == nil && required)
    end
    def isValidType()
        if !self.node.contains('type')
            return true
        end
        return gettype(self.value) == self.node['type']
    end
    def isValidSize()
        if !self.node.contains('size') 
            return true
        end
        var valType = gettype(self.value)
        if valType != 'list' && valType != 'string'
            return true
        end
        var sizeType = gettype(self.node['size'])
        if sizeType == 'int'
            return size(self.value) == self.node['size']
        elif sizeType == 'range'
            return size(self.value) >= self.node['size'].lower() &&
            size(self.value) <= self.node['size'].upper()
        else
            self.addError('schema size must be int or range')
            return false
        end
    end
    def isValidValues()
        if !self.node.contains('values')
            return true
        end
        if gettype(self.node['values']) != 'list'
            self.addError("schema values must be list")
            return false
        end
        return self.node['values'].find(self.value) != nil
    end
    def isValidFormat()
        if !self.node.contains('format')
            return true
        end
        # Lazy instantiate the FormatValidator if needed
        if !self.fv self.fv = FormatValidator() end
        return self.fv.match(self.node['format'], self.value)
    end
end

class Result
    var data, errors, isValid
    def init(data, errors)
        self.data = data
        self.errors = errors
        self.isValid = !self.errors.size()
    end
end

class SchemaValidator
    var data, errors, path, val
    def init(validate)
        self.data = {}
        self.errors = {}
        self.path = []
        self.val = Validate()
    end       
    def visit(parentNode, data, opt, cleanedData)
        data = data ? data : {}
        opt = opt ? opt : {}
        cleanedData = cleanedData ? cleanedData : {}
        if opt.contains('nodeName')
            self.path.push(opt['nodeName'])
        end        
        for name: parentNode.keys()
            var node = parentNode[name]
            var nodeType = gettype(node)
            # Expand schema list shortcut
            if nodeType == 'list'
                node = {
                    "items": node[0],
                    "type": 'list'
                }
                if node['items'].contains('size')
                    node['size'] = node['items']['size']
                    node['items'].remove('size')
                end
            end
            if !self.val.isValid(node, data, name, self.path, self.errors)
                continue
            end
            if data.find(name) == nil
                continue
            end
            if node['type'] == 'map'
                cleanedData[name] = {}
                self.visit(
                    node['properties'], 
                    data[name], 
                    {"nodeName": name}, 
                    cleanedData[name]
                )
                continue
            elif node['type'] == 'list'
                cleanedData[name] = []
                for idx: data[name].keys()
                    self.visit(
                        {idx: node['items']},
                        {idx: data[name][idx]},
                        {"nodeName": name},
                        cleanedData[name]
                    )
                end
                continue
            end
            if gettype(cleanedData) == 'list'
                cleanedData.push(data[name])
            else
                cleanedData[name] = data[name]
            end
        end
        if opt.contains('nodeName')
            self.path.pop()
        end
        if self.path.size() == 0
            self.data = cleanedData.find('root')
        end
        return self
    end    
end

def validatorFactory(schema, data)
    var validator = SchemaValidator()
        .visit({"root": schema}, {"root": data})
    return Result(validator.data, validator.errors)
end

# Load persisted regex patterns
PatternMatch.load()
# Exports
sv.regex = PatternMatch.regex
sv.time = PatternMatch.time
sv.formats = PatternMatch.get_formats
sv.add_format = PatternMatch.add_format
sv.remove_format = PatternMatch.remove_format
sv.validate = validatorFactory
return sv