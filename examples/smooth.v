module main

import bartender { SmoothBar, Theme, ThemeVariant }
import time
import term

const timeout = time.millisecond * 2

fn main() {
	// ----------------------------------------------
	mut b := SmoothBar{}
	// Add optional fields
	b.label = ['Push Fill', 'Done!']!
	b.timeout = timeout
	for _ in 0 .. b.width {
		b.progress()
	}

	// ----------------------------------------------
	mut b2 := SmoothBar{
		label: ['Pull Fill', 'Finished!']!
		theme: Theme.pull
		timeout: timeout
	}
	for _ in 0 .. b2.width {
		b2.progress()
	}

	// Re-use e.g.: b, b2
	// ----------------------------------------------
	b = SmoothBar{
		label: ['Push Drain', 'Completed!']!
		theme: ThemeVariant{.push, .drain}
		timeout: timeout
	}
	b.reset()
	for _ in 0 .. b.width {
		b.progress()
	}

	// ----------------------------------------------
	b2.label = ['Pull Drain', 'Ready!']!
	b2.theme = ThemeVariant{.pull, .drain}
	b2.reset()
	for _ in 0 .. b2.width {
		b2.progress()
	}

	// Dual-bar variants
	// ----------------------------------------------
	mut b3 := SmoothBar{
		label: ['Merge', '100% Merge']!
		theme: Theme.merge
		timeout: timeout
		border: ['│', '│']!
		width: 78
	}
	b3.colorize(term.cyan)
	for _ in 0 .. b3.width / 2 {
		b3.progress()
	}

	// ----------------------------------------------
	mut b4 := SmoothBar{
		label: ['Expand', '100% Expand']!
		theme: Theme.expand
		timeout: timeout
		border: ['│', '│']!
		width: 78
	}
	b4.colorize(term.bright_black)
	for _ in 0 .. b4.width / 2 {
		b4.progress()
	}

	// ----------------------------------------------
	mut b5 := SmoothBar{
		label: ['Split', '100% Split']!
		theme: Theme.split
		timeout: timeout
		border: ['│', '│']!
		width: 78
	}
	b5.colorize(bartender.SmoothBarColor{term.green, term.blue})
	for _ in 0 .. b5.width / 2 {
		b5.progress()
	}
}
