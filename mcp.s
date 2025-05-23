def mcp() {

// Helper function to skip whitespace characters
def skipWhitespace(s, index) {
    while (index < len(s)) {
        let ch = char(s, index);
        if (ch == " " || ch == chr(9) || ch == chr(10) || ch == chr(13)) {
            index = index + 1;
        } else {
            return index;
        }
    }
    return index;
}

// Helper function to parse a JSON string
def parseString(s, index) {
    if (index >= len(s) || char(s, index) != '"') {
        return {"error": "Expected quote at start of string", "index": index};
    }
    
    index = index + 1; // Skip opening quote
    let start = index;
    let result = "";
    
    while (index < len(s)) {
        let ch = char(s, index);
        if (ch == '"') {
            // End of string
            index = index + 1; // Skip closing quote
            return {"value": result, "index": index};
        } else {
            if (ch == '\') {
                // Handle escape sequences (simplified)
                index = index + 1;
                if (index < len(s)) {
                    let escaped = char(s, index);
                    if (escaped == "n") {
                        result = result + chr(10);
                    } else {
                        if (escaped == "t") {
                            result = result + chr(9);
                        } else {
                            if (escaped == "r") {
                                result = result + chr(13);
                            } else {
                                result = result + escaped;
                            }
                        }
                    }
                }
            } else {
                result = result + ch;
            }
        }
        index = index + 1;
    }
    
    return {"error": "Unterminated string", "index": index};
}

// Helper function to parse a JSON number
def parseNumber(s, index) {
    let start = index;
    let hasDecimal = false;
    
    // Handle negative sign
    if (index < len(s) && char(s, index) == chr(45)) {
        index = index + 1;
    }
    
    // Parse digits
    while (index < len(s)) {
        let ch = char(s, index);
        if (ord(ch) >= 48 && ord(ch) <= 57) {
            index = index + 1;
        } else {
            if (ch == chr(46) && !hasDecimal) {
                hasDecimal = true;
                index = index + 1;
            } else {
                // End of number
                let numStr = substr(s, start, index - start);
                let value = 0;
                
                // Simple number parsing (convert string to number)
                let i = 0;
                let negative = false;
                if (char(numStr, 0) == chr(45)) {
                    negative = true;
                    i = 1;
                }
                
                let intPart = 0;
                let fracPart = 0;
                let fracDigits = 0;
                let inFraction = false;
                
                while (i < len(numStr)) {
                    let digit = char(numStr, i);
                    if (digit == chr(46)) {
                        inFraction = true;
                    } else {
                        let digitVal = ord(digit) - 48;
                        if (inFraction) {
                            fracPart = fracPart * 10 + digitVal;
                            fracDigits = fracDigits + 1;
                        } else {
                            intPart = intPart * 10 + digitVal;
                        }
                    }
                    i = i + 1;
                }
                
                value = intPart;
                if (fracDigits > 0) {
                    let divisor = 1;
                    let j = 0;
                    while (j < fracDigits) {
                        divisor = divisor * 10;
                        j = j + 1;
                    }
                    value = value + fracPart / divisor;
                }
                
                if (negative) {
                    value = 0 - value;
                }
                
                return {"value": value, "index": index};
            }
        }
    }
    
    return {"error": "Invalid number", "index": index};
}

// Helper function to parse a JSON array
def parseArray(s, index) {
    if (index >= len(s) || char(s, index) != chr(91)) {
        return {"error": "Expected '[' at start of array", "index": index};
    }
    
    index = index + 1; // Skip opening bracket
    index = skipWhitespace(s, index);
    
    let result = [];
    
    // Handle empty array
    if (index < len(s) && char(s, index) == chr(93)) {
        return {"value": result, "index": index + 1};
    }
    
    // Parse array elements
    while (index < len(s)) {
        let valueResult = parseValue(s, index);
        if (valueResult["error"]) {
            return valueResult;
        }
        
        push(result, valueResult["value"]);
        index = valueResult["index"];
        index = skipWhitespace(s, index);
        
        if (index >= len(s)) {
            return {"error": "Unterminated array", "index": index};
        }
        
        let ch = char(s, index);
        if (ch == chr(93)) {
            return {"value": result, "index": index + 1};
        } else {
            if (ch == chr(44)) {
                index = index + 1;
                index = skipWhitespace(s, index);
            } else {
                return {"error": "Expected ',' or ']' in array", "index": index};
            }
        }
    }
    
    return {"error": "Unterminated array", "index": index};
}

// Helper function to parse a JSON object
def parseObject(s, index) {
    if (index >= len(s) || char(s, index) != chr(123)) {
        return {"error": "Expected '{' at start of object", "index": index};
    }
    
    index = index + 1; // Skip opening brace
    index = skipWhitespace(s, index);
    
    let result = {};
    
    // Handle empty object
    if (index < len(s) && char(s, index) == chr(125)) {
        return {"value": result, "index": index + 1};
    }
    
    // Parse object key-value pairs
    while (index < len(s)) {
        // Parse key (must be a string)
        let keyResult = parseString(s, index);
        if (keyResult["error"]) {
            return keyResult;
        }
        
        let key = keyResult["value"];
        index = keyResult["index"];
        index = skipWhitespace(s, index);
        
        // Expect colon
        if (index >= len(s) || char(s, index) != chr(58)) {
            return {"error": "Expected ':' after object key", "index": index};
        }
        index = index + 1;
        index = skipWhitespace(s, index);
        
        // Parse value
        let valueResult = parseValue(s, index);
        if (valueResult["error"]) {
            return valueResult;
        }
        
        result[key] = valueResult["value"];
        index = valueResult["index"];
        index = skipWhitespace(s, index);
        
        if (index >= len(s)) {
            return {"error": "Unterminated object", "index": index};
        }
        
        let ch = char(s, index);
        if (ch == chr(125)) {
            return {"value": result, "index": index + 1};
        } else {
            if (ch == chr(44)) {
                index = index + 1;
                index = skipWhitespace(s, index);
            } else {
                return {"error": "Expected ',' or '}' in object", "index": index};
            }
        }
    }
    
    return {"error": "Unterminated object", "index": index};
}

// Main function to parse any JSON value
def parseValue(s, index) {
    index = skipWhitespace(s, index);
    
    if (index >= len(s)) {
        return {"error": "Unexpected end of input", "index": index};
    }
    
    let ch = char(s, index);
    
    if (ch == chr(34)) {
        return parseString(s, index);
    } else {
        if (ch == chr(123)) {
            return parseObject(s, index);
        } else {
            if (ch == chr(91)) {
                return parseArray(s, index);
            } else {
                if ((ord(ch) >= 48 && ord(ch) <= 57) || ord(ch) == 45) {
                    return parseNumber(s, index);
                } else {
                    if (ch == chr(116)) {
                        // Check for "true"
                        if (index + 4 <= len(s) && substr(s, index, 4) == "true") {
                            return {"value": true, "index": index + 4};
                        }
                        return {"error": "Invalid literal", "index": index};
                    } else {
                        if (ch == chr(102)) {
                            // Check for "false"
                            if (index + 5 <= len(s) && substr(s, index, 5) == "false") {
                                return {"value": false, "index": index + 5};
                            }
                            return {"error": "Invalid literal", "index": index};
                        } else {
                            if (ch == chr(110)) {
                                // Check for "null"
                                if (index + 4 <= len(s) && substr(s, index, 4) == "null") {
                                    return {"value": null, "index": index + 4};
                                }
                                return {"error": "Invalid literal", "index": index};
                            } else {
                                return {"error": "Unexpected character: " + ch, "index": index};
                            }
                        }
                    }
                }
            }
        }
    }
}

// Main JSON parsing function
def parseJson(s) {
    let result = parseValue(s, 0);
    if (result["error"]) {
        return {"error": result["error"]};
    }
    return result["value"];
}

// Helper function to convert a string to JSON string format with proper escaping
def stringToJsonString(s) {
    let result = chr(34); // Start with quote
    let i = 0;
    while (i < len(s)) {
        let ch = char(s, i);
        if (ch == chr(10)) {
            // Newline -> \n
            result = result + chr(92) + "n";
        } else {
            if (ch == chr(9)) {
                // Tab -> \t
                result = result + chr(92) + "t";
            } else {
                if (ch == chr(13)) {
                    // Carriage return -> \r
                    result = result + chr(92) + "r";
                } else {
                    if (ch == chr(92)) {
                        // Backslash -> \\
                        result = result + chr(92) + chr(92);
                    } else {
                        if (ch == chr(34)) {
                            // Quote -> \"
                            result = result + chr(92) + chr(34);
                        } else {
                            // Regular character
                            result = result + ch;
                        }
                    }
                }
            }
        }
        i = i + 1;
    }
    result = result + chr(34); // End with quote
    return result;
}

// Helper function to convert array to JSON string
def arrayToJsonString(arr) {
    let result = chr(91); // [
    let i = 0;
    while (i < len(arr)) {
        if (i > 0) {
            result = result + chr(44); // ,
        }
        result = result + jsonToString(arr[i]);
        i = i + 1;
    }
    result = result + chr(93); // ]
    return result;
}

// Helper function to convert map to JSON string
def mapToJsonString(map) {
    let result = chr(123); // {
    let mapKeys = keys(map);
    let i = 0;
    while (i < len(mapKeys)) {
        if (i > 0) {
            result = result + chr(44); // ,
        }
        let key = mapKeys[i];
        // Convert key to string and add colon
        result = result + stringToJsonString("" + key) + chr(58) + jsonToString(map[key]);
        i = i + 1;
    }
    result = result + chr(125); // }
    return result;
}

// Main function to convert any IJ value to JSON string
def jsonToString(value) {
    if (isString(value)) {
        return stringToJsonString(value);
    } else {
        if (isNumber(value)) {
            return "" + value;
        } else {
                if (value == null) {
                    return "null";
                } else {
                    if (isArray(value)) {
                        return arrayToJsonString(value);
                    } else {
                        if (isMap(value)) {
                            return mapToJsonString(value);
                        } else {
                            if (isBoolean(value)) {
                                if (value) {
                                    return "true";
                                } else {
                                    return "false";
                                }
                            }
                        }
                    }
                }
            
        }
    }
}

// Command loop

/* def eval(s) {
    puts(s);
    return "FIXME " + s;
} */

def result(id,r) {
    return jsonToString({
        "jsonrpc": "2.0",
            "id": id,
            "result": r
        })
}

let line = gets();
while (line != null) {
    let p = parseJson(line);
    
    //puts(jsonToString(p));
    //puts(p);

    let method = p["method"]

    if ("initialize" == method) {
        puts(result(p["id"],{
          "protocolVersion": "2024-11-05",
          "capabilities": {
            "tools": {
              "listChanged": true
            },
            "resources": {
              "subscribe": false,
              "listChanged": false
            },
            "prompts": {
              "listChanged": false
            }
          },
          "serverInfo": {
            "name": "minimal-mcp-server",
            "version": "1.0.0"
          }
        }));
    }

    if ("tools/list" == method) {
        puts(result(p["id"],{
          "tools": [
            {
              "name": "execute_script",
              "description": "Executes a script in the IJ language.",
              "inputSchema": {
                "type": "object",
                "properties": {
                  "script": {
                    "type": "string",
                    "description": "The IJ script to execute."
                  }
                }
              }
            }
          ]
        }));
    }

    if ("tools/call" == method) {
        puts(result(p["id"],{
          "content": [
            {
              "type": "text",
              "text": eval(p["params"]["arguments"]["script"])
            }
          ]
        }));
    }

    /* if ("feature_discovery" == method) {
        puts(result({
            "methods": {
            "execute_script": {
                "description": "Executes a script in the IJ language.",
                "parameters": {
                "type": "object",
                "properties": {
                    "script": {
                    "type": "string",
                    "description": "The IJ script to execute."
                    }
                },
                "required": ["script"]
                }
            },
            "get_version": {
                "description": "Returns the version of the MCP server.",
                "parameters": {}
            }
            }
        }));
    }

    if ("execute_script" == method) {
        let script = p["params"]["script"];
        puts(result({
            "output": eval(script),
            "status": "success"
        }));
    }

    if ("get_version" == method) {
        puts(result({
            "version": "1.0.0",
            "language": "IJ"
        }));
    } */

    line = gets();
}

}
mcp();
