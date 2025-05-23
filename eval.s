// cat interpreter.s|./until.rb "interpreter is ready" > interpreter_base.s

let result = "";
def newPuts(s) {
    if (len(result) > 0) {
        result = result + chr(10);
    }
    result = result + s[0];
}
let oldStdIOLibraryFunctionsInitializer = StdIOLibraryFunctionsInitializer;
def StdIOLibraryFunctionsInitializer(context) {
    oldStdIOLibraryFunctionsInitializer(context);
    context["registerFunction"](context, "puts", newPuts);
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
        return result;
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