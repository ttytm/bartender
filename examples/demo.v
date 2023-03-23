module main

import bartender
import term { hide_cursor, show_cursor }

fn main() {
	mut b := bartender.Bar{
		label: ['Push Fill', 'Done!']!
	}
	mut b2 := bartender.Bar{
		label: ['Pull Fill', 'Finished!']!
		theme: bartender.Pull{.fill}
	}

	hide_cursor()

	for _ in 0 .. b.width {
		b.progress()
	}
	for _ in 0 .. b2.width {
		b2.progress()
	}

	// Re-used bars
	b.label = ['Push Drain', 'Completed!']!
	b.theme = bartender.Push{.drain}
	b.prep()
	for _ in 0 .. b.width {
		b.progress()
	}
	b2.label = ['Pull Drain', 'Ready!']!
	b2.theme = bartender.Pull{.drain}
	b2.prep()
	for _ in 0 .. b2.width {
		b2.progress()
	}

	show_cursor()
}
