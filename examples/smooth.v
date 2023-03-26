module main

import bartender { SmoothBar, Theme, ThemeVariant }
import time
import term

const timeout = time.millisecond * 2

fn main() {
	// ===========================================================================
	mut b := SmoothBar{}
	// Add optional fields
	b.label = ['Push Fill', 'Done!']!
	for _ in 0 .. b.iters {
		b.progress()
		time.sleep(timeout)
	}

	// ===========================================================================
	mut b2 := SmoothBar{
		label: ['Pull Fill', 'Finished!']!
		theme: Theme.pull
	}
	for _ in 0 .. b2.iters {
		b2.progress()
		time.sleep(timeout)
	}

	// ===========================================================================
	b = SmoothBar{
		label: ['Push Drain', 'Completed!']!
		theme: ThemeVariant{.push, .drain}
	}
	for _ in 0 .. b.iters {
		b.progress()
		time.sleep(timeout)
	}

	// ===========================================================================
	b2.label = ['Pull Drain', 'Ready!']!
	b2.theme = ThemeVariant{.pull, .drain}
	b2.reset()
	for _ in 0 .. b2.iters {
		b2.progress()
		time.sleep(timeout)
	}

	// Dual-bar variants
	// ===========================================================================
	mut b3 := SmoothBar{
		label: ['Merge', '100% Merge']!
		theme: Theme.merge
		border: ['│', '│']!
		width: 78
	}
	b3.colorize(term.cyan)
	for _ in 0 .. b3.iters {
		b3.progress()
		time.sleep(timeout * 2)
	}

	// ===========================================================================
	mut b4 := SmoothBar{
		label: ['Expand', '100% Expand']!
		theme: Theme.expand
		border: ['│', '│']!
		width: 78
	}
	// Colorize
	b4.colorize(term.bright_black)
	for _ in 0 .. b4.iters {
		b4.progress()
		time.sleep(timeout * 2)
	}

	// ===========================================================================
	mut b5 := SmoothBar{
		label: ['Split', '100% Split']!
		theme: Theme.split
		border: ['│', '│']!
		width: 78
	}
	b5.colorize(bartender.SmoothBarColor{term.green, term.blue})
	for _ in 0 .. b5.iters {
		b5.progress()
		time.sleep(timeout * 2)
	}
}
