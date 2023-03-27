module main

import bartender { SmoothBar, Theme, ThemeVariant }
import time
import term

const timeout = time.millisecond * 2

fn main() {
	// ===========================================================================
	mut b := SmoothBar{}
	// Add optional fields
	b.label = ['Push Fill', 'Push Fill Done!']!
	for _ in 0 .. b.iters {
		b.progress()
		time.sleep(timeout)
	}

	// ===========================================================================
	mut b2 := SmoothBar{
		label: ['Pull Fill', 'Completed!']!
		theme: Theme.pull
	}
	for _ in 0 .. b2.iters {
		// Add state to label
		// NOTE: Interpolation of current label with eta `${b.label[0]}${b.eta()}` doesn't work.
		// Concatenation with `+=` throws compiler error.
		b2.label[0] = 'Pull Fill ${b2.pct()}% (${b2.eta() / 1000:.2f}s)'
		b2.progress()
		time.sleep(timeout * 2)
	}

	// Re-use bars
	// ===========================================================================
	b = SmoothBar{
		label: ['Push Drain', 'Push Drain']!
		theme: ThemeVariant{.push, .drain}
	}
	for _ in 0 .. b.iters {
		b.progress()
		time.sleep(timeout)
	}

	// ===========================================================================
	b2.label = ['Pull Drain', 'Pull Drain']!
	b2.theme = ThemeVariant{.pull, .drain}
	b2.reset()
	for _ in 0 .. b2.iters {
		b2.progress()
		time.sleep(timeout)
	}

	// Dual-bar variants
	// ===========================================================================
	mut b3 := SmoothBar{
		label: ['Merge', 'Merge']!
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
		label: ['Expand', 'Expand']!
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
		label: ['Split', 'Split']!
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
