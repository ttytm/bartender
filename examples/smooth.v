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
		label: ['Pull Fill', 'Completed!']!
		theme: Theme.pull
	}
	for _ in 0 .. b2.iters {
		b2.progress()
		time.sleep(timeout)
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
	// Single color for bar and borders
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
	// Div color for bar and borders
	b5.colorize(bartender.SmoothBarColor{term.green, term.blue})
	for i in 0 .. b5.iters {
		// Add percentage and time to the label.
		// The precision for calculating the ETA grows the more advanced the process.
		// In this example, showing the time is delayed until 20% is completed. Until then, a spinner is displayed.
		eta := term.colorize(term.blue, if i <= f32(b.iters) * 0.2 {
			b5.spinner()
		} else {
			'${b5.eta() / 1000:.1f}s'
		})
		// NOTE: '${b5.label[0]}' does not work atm!
		b5.label[0] = 'Split ${b5.pct()}% ${eta}'
		b5.progress()
		time.sleep(timeout * 10)
	}
}
