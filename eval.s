// cat interpreter.s|./until.rb "interpreter is ready" > interpreter_base.s

def newInput() {
    let self = {}

    def clear() {
        self["lines"] = [];
        self["index"] = 0;
    }
    self["clear"] = clear;
    clear();

    def initialize(s) {
        self["lines"] = split(s,chr(10));
        self["index"] = 0;
    }
    self["initialize"] = initialize;

    def next() {
        let index = self["index"];
        let lines = self["lines"];
        if (index < len(lines)) {
            self["index"] = index + 1;
            return lines[index];
        }
        else {
            return null;
        }
    }
    self["next"] = next;

    return self;
}
let input = newInput();
def newGets(s) {
    return input["next"]();
}

let result = "";
def newPuts(s) {
    if (len(result) > 0) {
        result = result + chr(10);
    }
    result = result + s[0];
}
def clearOutput() {
    result = "";
}
let oldStdIOLibraryFunctionsInitializer = StdIOLibraryFunctionsInitializer;
def StdIOLibraryFunctionsInitializer(context) {
    oldStdIOLibraryFunctionsInitializer(context);
    context["registerFunction"](context, "puts", newPuts);
    context["registerFunction"](context, "gets", newGets);
}

let assertOutput = "";
def assert(c, s) { // FIXME we need a proper way to deal with errors
    if (!c) {
        if (len(assertOutput) > 0) {
            assertOutput = assertOutput + chr(10);
        }
        assertOutput = assertOutput + "ASSERTION FAILED: " + s;
    }
}
def clearAssertOutput() {
    assertOutput = "";
}
let oldDefaultLibraryFunctionsInitializer = DefaultLibraryFunctionsInitializer;
def DefaultLibraryFunctionsInitializer(context) {
    oldDefaultLibraryFunctionsInitializer(context);
    context["registerFunction"](context, "assert", twoWrapper(assert));
}

interpreter = makeInterpreter();

def eval(source) {
    result = "";
    let parseResult = interpreter["parse"](interpreter, source);
    if (!(parseResult["success"])) {
        return "Parse failed with errors: " + parseResult["errors"]; //FIXME BACKPORT
    } else {
        let evalResult = interpreter["evaluate"](interpreter);
        if (!evalResult["success"]) {
            return "Evaluation failed with errors: " + interpreter["formatErrors"](interpreter, evalResult["errors"]);
        }
        let r = evalResult["result"];

        if (len(assertOutput) > 0) {
            return assertOutput;
        }
        else {
            return result;
        }
    }
}

def ast(source) {
    result = "";
    let parseResult = interpreter["parse"](interpreter, source);
    if (!(parseResult["success"])) {
        return "Parse failed with errors: " + parseResult["errors"]; //FIXME BACKPORT
    } else {
        let astJson = interpreter["getAstJson"](interpreter);
        if (astJson != null) {
            return astJson;
        } else {
            return "No AST to show.";
        }
    }
}

/*
let srcs = [
    "puts('hi');",
    "puts(1+2);",
    "puts('ha');" + chr(10) + "puts('lo')",
    "puts('ha');" + chr(13)
];
let i = 0;
while (i < len(srcs)) {
    puts(i + ":");
    puts(eval(srcs[i]));
    i = i + 1;
}
*/