puts('What is your name (Ctrl-D to exit)?');

let name = gets();
while (name != null) {
	puts("Hello " + name);
	name = gets();
}
