// Basic arithmetic and variable tests
let x = 10;
let y = 20;
assert(x + y == 30, "Basic addition");
assert(x * y == 200, "Basic multiplication");
assert(y - x == 10, "Basic subtraction");
assert(y / x == 2, "Basic division");
assert(y % x == 0, "Basic modulo");

// Comparison operators
assert(x < y, "Less than comparison");
assert(y > x, "Greater than comparison");
assert(x <= y, "Less than or equal comparison");
assert(y >= x, "Greater than or equal comparison");
assert(x == x, "Equality comparison");
assert(x != y, "Inequality comparison");

// Boolean operations
assert(true && true, "Logical AND with true values");
assert(!(true && false), "Logical AND with mixed values");
assert(true || false, "Logical OR with mixed values");
assert(!false, "Logical NOT");

// Variable assignment and scope
let a = 5;
a = 10;
assert(a == 10, "Variable reassignment");

{
  let b = 15;
  assert(b == 15, "Block scope variable");
}
// assert(typeof(b) == "undefined", "Block scope variable should not be accessible");

// Conditionals
let result = "";
if (true) {
  result = "true branch";
} else {
  result = "false branch";
}
assert(result == "true branch", "If statement (true branch)");

result = "";
if (false) {
  result = "true branch";
} else {
  result = "false branch";
}
assert(result == "false branch", "If statement (false branch)");

// While loops
let counter = 0;
let sum = 0;
while (counter < 5) {
  sum = sum + counter;
  counter = counter + 1;
}
assert(sum == 10, "While loop summation");
assert(counter == 5, "While loop counter");

// Functions
def add(a, b) {
  return a + b;
}
assert(add(3, 4) == 7, "Basic function call");

// Recursion
def factorial(n) {
  if (n <= 1) {
    return 1;
  }
  return n * factorial(n - 1);
}
assert(factorial(5) == 120, "Recursive function (factorial)");

// Closures
def makeAdder(x) {
  def inner(y) {
    return x + y;
  }
  return inner;
}
let add5 = makeAdder(5);
assert(add5(10) == 15, "Closure creation and execution");

// Arrays
let arr = [1, 2, 3, 4, 5];
assert(len(arr) == 5, "Array length");
assert(arr[0] == 1, "Array indexing");

let arrSum = 0;
let i = 0;
while (i < len(arr)) {
  arrSum = arrSum + arr[i];
  i = i + 1;
}
assert(arrSum == 15, "Array element sum");

// Array mutation
arr[0] = 10;
assert(arr[0] == 10, "Array element assignment");

push(arr, 6);
assert(len(arr) == 6, "Array push operation");
assert(arr[5] == 6, "Array push value check");

let popped = pop(arr);
assert(popped == 6, "Array pop return value");
assert(len(arr) == 5, "Array length after pop");

// Maps
let person = {"name": "Alice", "age": 30};
assert(person["name"] == "Alice", "Map key access");
assert(person["age"] == 30, "Map key access with number value");

person["name"] = "Bob";
assert(person["name"] == "Bob", "Map key assignment");

let mapKeys = keys(person);
assert(len(mapKeys) == 2, "Map keys count");

// String operations
let greeting = "Hello";
let name = "World";
assert(greeting + " " + name == "Hello World", "String concatenation");
assert(substr(greeting, 1, 3) == "ell", "Substring extraction");
assert(len(greeting) == 5, "String length");

// Nested data structures
let matrix = [[1, 2], [3, 4]];
assert(matrix[0][1] == 2, "Nested array access");

//matrix[0][1] = 99; //FIXME not supported (yet)
let x = matrix[0];
x[1] = 99
assert(matrix[0][1] == 99, "Nested array assignment");

// Type checks
assert(typeof(5) == "number", "Type check for number");
assert(typeof("hello") == "string", "Type check for string");
assert(typeof(true) == "boolean", "Type check for boolean");
assert(typeof([]) == "array", "Type check for array");
assert(typeof({}) == "map", "Type check for map");
assert(typeof(null) == "null" || typeof(null) == "object", "Type check for null");

// Truthy/falsy values
def nassert(t,m) {
  assert(!t,m)
}

assert(1, "Number 1 is truthy");
nassert(0, "Number 0 is falsy");
assert("hello", "Non-empty string is truthy");
nassert("", "Empty string is falsy");
assert(true, "Boolean true is truthy");
nassert(false, "Boolean false is falsy");
nassert(null, "Null is falsy");

// Complex expressions
assert((5 + 3) * 2 == 16, "Complex expression with parentheses");
assert(5 + 3 * 2 == 11, "Complex expression with precedence");

// Fibonacci sequence test
def fib(n) {
  if (n <= 1) {
    return n;
  }
  return fib(n-1) + fib(n-2);
}
assert(fib(7) == 13, "Fibonacci calculation");

// String and char functions
assert(char("hello", 1) == "e", "Character extraction");
assert(ord("A") == 65, "Character to ASCII code");
assert(chr(65) == "A", "ASCII code to character");

// All tests passed

puts("All tests completed successfully!");