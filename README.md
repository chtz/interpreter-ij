# The IJ Interpreter

> ⚠️ **DISCLAIMER: EXPERIMENTAL SOFTWARE AHEAD** ⚠️
>
> This is a highly experimental language and interpreter, created as a proof-of-concept that somehow evolved into a working (sort of) system. It's like Frankenstein's monster, but instead of body parts, it's made of duct tape, bubble gum, and questionable design decisions.
>
> The transpilation feature? It's basically magic that we don't fully understand ourselves. The interpreter? It's like a house of cards - it works until it doesn't. Quality and correctness were sacrificed at the altar of "it compiles, ship it!"
>
> **TL;DR:** This is not production-ready software. In fact, it's not even "ready" software. It's more like "we got it to work once and we're not touching it again" software. Please, for the love of all things holy, don't use this in any real project. We're not responsible for any existential crises that might occur from trying to debug this code.
>
> You've been warned! 🚧

> 🎮 **FYI: The Making Of This Madness**
>
> This entire project is the result of a series of hacking sessions during a vacation break, created purely for the sake of it. The journey went something like this:
>
> 1. Started with a JavaScript-based LL(1) interpreter, born from a vibe programming session with Cursor IDE and Claude 3.7
> 2. Ported that to a Java-based interpreter (because why not?)
> 3. Created the IJ language implementation of the interpreter as a semi-automated port of the Java version
> 4. Used some custom transpilation tools backed by ChatGPT 4.1 APIs to generate the initial IJ code
>    - Side note: As of May 2025, LLMs are still terrible at writing code in languages not present in their training set
> 5. Created a Golang runtime so that transpilation from IJ to Golang could happen in one pass
> 6. Used the Java-based interpreter as the runtime for the first transpilation of the IJ interpreter to Golang with capabilities implemented in the IJ interpreter itself
> 7. Finally got a native interpreter that could bootstrap itself, making the Java version obsolete
> 8. Cursor and Claude came up with an MCP server implementation, enabling LLMs to evaluate IJ scripts via a protocol.
> 9. Leveraged jules.google.com to automatically fix performance issues in the interpreter and runtime.
> 10. Used claude-4-opus-thinking to waste $50 on attempts to improve performance (with mixed results).
>
> It's like a game of telephone, but with programming languages. Each port probably introduced new bugs and quirks, but hey, that's part of the fun! 🎲

## Quick Start

The recommended way to run IJ scripts is via the `native_interpreter.sh` script, which automatically selects the correct native binary for your platform (macOS/arm64 or Linux/amd64):

```bash
# On macOS (arm64) or Linux (amd64):
echo "puts(22/7.0)" | ./native_interpreter.sh
```

*(See below for more details and platform-specific instructions)*

---

**Note:** Native binaries are provided for macOS (arm64) and Linux (amd64) as `interpreter_mac_arm64` and `interpreter_linux_amd64`. The `native_interpreter.sh` script will select the correct one for your system. For other platforms/architectures, you must build the binary yourself (see Compilation section below).

---

## Requirements

- **To run scripts:**
  - macOS (arm64) or Linux (amd64)
  - The corresponding native binary (`interpreter_mac_arm64` or `interpreter_linux_amd64`)
- **To compile IJ code to a native binary for your current platform:**
  - Go toolchain installed (`go` in your PATH)
- **To create a reproducible binary for a specific platform (macOS/arm64 or Linux/amd64):**
  - Go toolchain installed
  - Docker installed and running

---

## Table of Contents

- [Overview](#overview)
- [The IJ Language Grammar (EBNF)](#the-ij-language-grammar-ebnf)
- [IJ Language Samples](#ij-language-samples)
  - [Simple Calculator](#simple-calculator)
  - [Array Sorting](#array-sorting)
  - [Functional Programming](#functional-programming)
  - [Closures](#closures)
- [Tests](#tests)
- [How to Run IJ Scripts](#how-to-run-ij-scripts)
  - [One Liners](#one-liners)
  - [Run the Native Interpreter](#run-the-native-interpreter)
  - [Run the IJ-based Interpreter](#run-the-ij-based-interpreter)
  - [Run the Self-Hosted Interpreter](#run-the-self-hosted-interpreter)
  - [Transpile IJ Code to Golang](#transpile-ij-code-to-golang)
  - [Re-create the Native Interpreter](#re-create-the-native-interpreter)
- [Shell Scripts Overview](#shell-scripts-overview)
- [Compilation](#compilation)
- [MCP Server (Model Control Protocol)](#mcp-server-model-control-protocol)
- [AI-Assisted Development with Claude](#ai-assisted-development-with-claude)
  - [The Experience](#the-experience-or-how-i-learned-to-stop-worrying-and-love-obscure-programming-languages)
  - [Technical Setup](#technical-setup-or-the-sacred-incantations-required)
  - [Significance](#significance-or-why-this-changes-everything-forever)
  - [Build and test native MCP server](#build-and-test-native-mcp-server)

## Overview

The IJ interpreter is written in the IJ language itself and the native IJ interpreter is generated by the IJ interpreter's Golang transpilation feature (so the binary has been generated by itself – solving the classic "chicken and egg" problem of self-hosting interpreters, where the interpreter is capable of building itself from its own source code).

## The IJ Language Grammar (EBNF)

The following EBNF (Extended Backus-Naur Form) grammar defines the syntax of IJ scripts:

```ebnf
/* Program structure */
Program             ::= Statement*

/* Statements */
Statement           ::= VariableDeclaration
                      | FunctionDeclaration
                      | IfStatement
                      | WhileStatement
                      | ReturnStatement
                      | BlockStatement
                      | AssignmentStatement
                      | IndexAssignmentStatement
                      | ExpressionStatement

/* Declarations */
VariableDeclaration ::= "let" Identifier "=" Expression (";" | <newline>)?
FunctionDeclaration ::= "def" Identifier "(" Parameters? ")" BlockStatement
Parameters          ::= Identifier ("," Identifier)*

/* Control flow */
IfStatement         ::= "if" "(" Expression ")" BlockStatement
                       ("else" (BlockStatement))?
WhileStatement      ::= "while" "(" Expression ")" BlockStatement
ReturnStatement     ::= "return" Expression? (";" | <newline>)?

/* Blocks and Assignments */
BlockStatement           ::= "{" Statement* "}"
AssignmentStatement      ::= Identifier "=" Expression (";" | <newline>)?
IndexAssignmentStatement ::= Identifier "[" Expression "]" "=" Expression (";" | <newline>)?
ExpressionStatement      ::= Expression (";" | <newline>)?

/* Expressions */
Expression               ::= OrExpression
OrExpression             ::= AndExpression ("||" AndExpression)*
AndExpression            ::= EqualityExpression ("&&" EqualityExpression)*
EqualityExpression       ::= ComparisonExpression (("==" | "!=") ComparisonExpression)*
ComparisonExpression     ::= AdditiveExpression (("<" | ">" | "<=" | ">=") AdditiveExpression)*
AdditiveExpression       ::= MultiplicativeExpression (("+" | "-") MultiplicativeExpression)*
MultiplicativeExpression ::= PrefixExpression (("*" | "/" | "%") PrefixExpression)*
PrefixExpression         ::= ("-" | "!") PrefixExpression | CallExpression
CallExpression           ::= IndexExpression ("(" Arguments? ")")*
IndexExpression          ::= PrimaryExpression ("[" Expression "]")*
Arguments                ::= Expression ("," Expression)*
PrimaryExpression        ::= Identifier 
                            | NumberLiteral 
                            | StringLiteral
                            | BooleanLiteral
                            | NullLiteral
                            | ArrayLiteral
                            | MapLiteral
                            | "(" Expression ")"

/* Literals and Identifiers */
Identifier         ::= [a-zA-Z_][a-zA-Z0-9_]*
NumberLiteral      ::= [0-9]+ ("." [0-9]+)?
StringLiteral      ::= '"' [^"\n]* '"'
                      | "'" [^'\n]* "'"
BooleanLiteral     ::= "true" | "false"
NullLiteral        ::= "null"
ArrayLiteral       ::= "[" (Expression ("," Expression)*)? "]"
MapLiteral         ::= "{" (MapEntry ("," MapEntry)*)? "}"
MapEntry           ::= Expression ":" Expression

/* Comments */
Comment            ::= SingleLineComment | MultiLineComment
SingleLineComment  ::= "//" [^\n]*
MultiLineComment   ::= "/*" .* "*/"
```

## IJ Language Samples

### Simple Calculator

```ij
// A simple calculator with basic operations
def calculate(a, b, operation) {
  if (operation == "+") {
    return a + b;
  } else {
    if (operation == "-") {
      return a - b;
    } else {
      if (operation == "*") {
        return a * b;
      } else {
        if (operation == "/") {
          if (b == 0) {
            return "Error: Division by zero";
          }
          return a / b;
        } else {
          return "Error: Unknown operation";
        }
      }
    }
  }
}

// Test different operations
puts(calculate(15, 5, "+"));  // Output: 20
puts(calculate(15, 5, "-"));  // Output: 10
puts(calculate(15, 5, "*"));  // Output: 75
puts(calculate(15, 5, "/"));  // Output: 3
puts(calculate(15, 0, "/"));  // Output: Error: Division by zero
```

### Array Sorting

```ij
// Simple bubble sort implementation
def bubbleSort(arr) {
  let n = len(arr);
  let i = 0;
  
  while (i < n) {
    let j = 0;
    let swapped = false;
    
    while (j < n - i - 1) {
      if (arr[j] > arr[j + 1]) {
        // Swap elements
        let temp = arr[j];
        arr[j] = arr[j + 1];
        let jPlusOne = j + 1;
        arr[jPlusOne] = temp;
        swapped = true;
      }
      j = j + 1;
    }
    
    // If no swapping occurred in this pass, array is sorted
    if (!swapped) {
      return arr;
    }
    
    i = i + 1;
  }
  
  return arr;
}

// Test the bubble sort
let numbers = [64, 34, 25, 12, 22, 11, 90];
bubbleSort(numbers);

// Print sorted array
let i = 0;
let output = "Sorted array: ";
while (i < len(numbers)) {
  output = output + numbers[i];
  if (i < len(numbers) - 1) {
    output = output + ", ";
  }
  i = i + 1;
}
puts(output);  // Output: Sorted array: 11, 12, 22, 25, 34, 64, 90
```

### Functional Programming

```ij
// Map function: apply a function to each element in an array
def map(arr, fn) {
  let result = [];
  let i = 0;
  while (i < len(arr)) {
    push(result, fn(arr[i]));
    i = i + 1;
  }
  return result;
}

// Filter function: select elements that satisfy a predicate
def filter(arr, predicate) {
  let result = [];
  let i = 0;
  while (i < len(arr)) {
    if (predicate(arr[i])) {
      push(result, arr[i]);
    }
    i = i + 1;
  }
  return result;
}

// Reduce function: combine elements into a single value
def reduce(arr, fn, initial) {
  let result = initial;
  let i = 0;
  while (i < len(arr)) {
    result = fn(result, arr[i]);
    i = i + 1;
  }
  return result;
}

// Test data
let numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

// Double each number with map
def double(x) { return x * 2; }
let doubled = map(numbers, double);
puts("Doubled: " + doubled[0] + ", " + doubled[1] + ", " + doubled[2] + "...");  
// Output: Doubled: 2, 4, 6...

// Get even numbers with filter
def isEven(x) { return x % 2 == 0; }
let evens = filter(numbers, isEven);
puts("Evens: " + evens[0] + ", " + evens[1] + ", " + evens[2] + "...");  
// Output: Evens: 2, 4, 6...

// Sum all numbers with reduce
def add(acc, x) { return acc + x; }
let sum = reduce(numbers, add, 0);
puts("Sum: " + sum);  // Output: Sum: 55

// Chain operations: Sum of doubled even numbers
let result = reduce(
  map(
    filter(numbers, isEven),
    double
  ),
  add,
  0
);
puts("Sum of doubled evens: " + result);  // Output: Sum of doubled evens: 60
```

### Closures

```ij
def createCounter() {
  let count = 0;
  def counter() {
    count = count + 1;
    return count;
  }
  return counter;
}

let counter = createCounter();
let counter2 = createCounter();

puts(counter()); // Outputs: 1
puts(counter2()); // Outputs: 1

puts(counter()); // Outputs: 2
puts(counter()); // Outputs: 3

puts(counter2()); // Outputs: 2
puts(counter2()); // Outputs: 3
```

### Tests

To run the test suite, simply execute:

```bash
./test.sh
```

This runs all tests in `test.s` using the interpreter. The `test.s` script contains a comprehensive suite of IJ language tests, covering arithmetic, variables, control flow, functions, closures, arrays, maps, strings, type checks, truthy/falsy values, and more.

See also `test.s` for more samples...

```bash
echo|./native_interpreter.sh test.s
```

## How to Run IJ Scripts

Native binaries are provided for macOS (arm64) and Linux (amd64). The `native_interpreter.sh` script will automatically select the correct binary for your platform. For other platforms/architectures, you must build the binary yourself (see Compilation section).

### Running Scripts

#### One Liners

```bash
# On macOS (arm64) or Linux (amd64):
echo "puts(22/7.0)" | ./native_interpreter.sh
```

The IJ interpreter accepts the script source code from SYSIN, so you need to utilize the wrapper scripts for multiline input and scripts that perform I/O (reading lines from SYSIN and writing lines to SYSOUT). If you run a script that does not expect input to read with `gets()`, you need to make sure the wrapper script doesn't wait for input:

```bash
echo|./native_interpreter.sh foo_not_expecting_input.s
```

#### Run the Native Interpreter

Runs the sample script with the native interpreter (auto-selected for your platform):

```bash
./native_interpreter.sh sample.s
```

#### Run the IJ-based Interpreter

Run the sample script with the interpreter (`interpreter.s`) which is executed by the native interpreter (auto-selected for your platform):

```bash
./interpreter.sh sample.s
```

#### Run the Self-Hosted Interpreter

Run the sample script with the interpreter (`interpreter.s`) which is executed by the interpreter (`interpreter.s`) which is executed by the native interpreter (auto-selected for your platform). Grab a coffee, bootstrapping will take a very long time (minutes, not seconds).

```bash
./selfhosted_interpreter.sh sample.s
```

## Shell Scripts Overview

| Script                    | Description                                                                                   |
|--------------------------|-----------------------------------------------------------------------------------------------|
| `build.sh`               | Re-creates all binaries (interpreter and MCP server) for all supported platforms. Requires Go and Docker. Also runs tests. |
| `compile.sh`             | Transpiles IJ to Go and builds a native binary for your current platform.                      |
| `compile-mac.sh`         | Cross-compiles a reproducible binary for macOS/arm64 using Docker.                             |
| `compile-linux.sh`       | Cross-compiles a reproducible binary for Linux/amd64 using Docker.                             |
| `native_interpreter.sh`  | Runs the correct native interpreter for your platform.                                         |
| `interpreter.sh`         | Runs the interpreter implemented in IJ, using the native interpreter.                         |
| `selfhosted_interpreter.sh` | Bootstraps the interpreter by running the interpreter in itself.                              |
| `test.sh`                | Runs the test suite.                                                                           |
| `mcp.sh`                 | Builds and runs the MCP server in interpreted mode.                                            |
| `native_mcp.sh`          | Runs the native MCP server for your platform.                                                  |
| `until.rb`               | Helper for waiting for a string in output (used in build scripts).                             |

## Compilation

### Compiling Everything (Recommended)

To re-create all binaries (interpreter and MCP server) for all supported platforms, use `build.sh`. This script requires both Go and Docker to be installed and running. It will build all native binaries, run tests, and build the MCP server binaries for both macOS/arm64 and Linux/amd64.

```bash
./build.sh
```

### Compiling for Your Current Platform

To transpile an IJ script to Go and build a native binary for your *current* platform, use `compile.sh`. This requires the Go toolchain installed and available in your PATH. The resulting binary will run on your current OS/architecture. This method does **not** guarantee reproducible builds.

```bash
./compile.sh sample.s sample_binary
./sample_binary
```

### Reproducible Cross-Platform Builds

To create a reproducible binary for a specific platform (macOS/arm64 or Linux/amd64), use `compile-mac.sh` or `compile-linux.sh`. These scripts require both Go and Docker installed and running. They use a fixed build environment and timestamps to ensure reproducibility.

```bash
# For macOS/arm64:
./compile-mac.sh sample.s sample_mac_arm64

# For Linux/amd64:
./compile-linux.sh sample.s sample_linux_amd64
```

The output binary will be for the specified target platform, regardless of your host system.

### Re-create the Native Interpreter

To re-create the native interpreter binary for your platform, use the appropriate compile script as described above. For reproducible builds, use the Docker-based scripts. For a quick local build, use `compile.sh`.

We aim for reproducible builds: compiling `interpreter.s` to `interpreter_mac_arm64` or `interpreter_linux_amd64` using the Docker-based scripts should produce a binary with the same hash, ensuring consistency and verifiability.

```bash
./compile-mac.sh interpreter.s interpreter_mac_arm64
./compile-linux.sh interpreter.s interpreter_linux_amd64
```

## MCP Server (Model Control Protocol)

The MCP server allows LLMs (such as Claude Desktop) to evaluate IJ scripts via a simple JSON-RPC protocol. This is useful for integrating the IJ interpreter as a tool in AI environments.

There are two ways to run the MCP server:

- **Interpreted mode:**
  ```bash
  ./mcp.sh
  ```
  This builds and runs the MCP server using the interpreter.

- **Native mode:**
  ```bash
  ./native_mcp.sh
  ```
  This runs the native MCP server binary for your platform (`mcp_mac_arm64` or `mcp_linux_amd64`).

### Claude Desktop Config Example

To use the MCP server with Claude Desktop, add the following to your config:

```json
{
  "mcpServers": {
    "ijscript": {
      "command": "/.../interpreter-ij/mcp_mac_arm64",
      "args": [],
      "transport": {
        "type": "stdio"
      }
    }
  }
}
```
