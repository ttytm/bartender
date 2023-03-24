module main

import bartender { Theme, ThemeVariant }

fn main() {
	mut b := bartender.Bar{
		label: ['Push Fill', 'Done!']!
		theme: Theme.push
		border: ['│', '│']!
	}
	mut b2 := bartender.Bar{
		label: ['Pull Fill', 'Finished!']!
		theme: Theme.pull
	}

	for _ in 0 .. b.width {
		b.progress()
	}
	for _ in 0 .. b2.width {
		b2.progress()
	}

	// Re-use bars
	b = bartender.Bar{
		label: ['Push Drain', 'Completed!']!
		theme: ThemeVariant{.push, .drain}
		border: ['', '']!
	}
	b.prep()
	for _ in 0 .. b.width {
		b.progress()
	}
	b2.label = ['Pull Drain', 'Ready!']!
	b2.theme = ThemeVariant{.pull, .drain}
	b2.prep()
	for _ in 0 .. b2.width {
		b2.progress()
	}
}
