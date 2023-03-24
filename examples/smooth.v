module main

import bartender { SmoothBar, Theme, ThemeVariant }

fn main() {
	mut b := SmoothBar{
		label: ['Push Fill', 'Done!']!
		theme: Theme.push
	}
	mut b2 := SmoothBar{
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
	b = SmoothBar{
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

	mut b3 := SmoothBar{
		label: ['Merge', '100% Merge']!
		theme: Theme.merge
	}
	mut b4 := SmoothBar{
		label: ['Expand', '100% Expand']!
		theme: Theme.expand
	}
	for _ in 0 .. b3.width / 2 {
		b3.progress()
	}
	for _ in 0 .. b4.width / 2 {
		b4.progress()
	}
}
