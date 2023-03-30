module main

import bartender { Color, SmoothBar, Theme, ThemeVariant }
import time
import term

const timeout = time.millisecond * 2

fn main() {
	// ===========================================================================
	mut b := SmoothBar{}
	// Add optional fields
	b.post = ' Push Fill'
	for _ in 0 .. b.iters {
		b.progress()
		time.sleep(timeout)
	}

	// ===========================================================================
	mut b2 := SmoothBar{
		post: ' Pull Fill'
		theme: Theme.pull
	}
	for _ in 0 .. b2.iters {
		b2.progress()
		time.sleep(timeout)
	}

	// Re-use bars
	// ===========================================================================
	b = SmoothBar{
		post: ' Push Drain'
		theme: ThemeVariant{.push, .drain}
	}
	for _ in 0 .. b.iters {
		b.progress()
		time.sleep(timeout)
	}

	// ===========================================================================
	b2 = SmoothBar{
		post: ' Pull Drain'
		theme: ThemeVariant{.pull, .drain}
	}
	for _ in 0 .. b2.iters {
		b2.progress()
		time.sleep(timeout)
	}
	time.sleep(timeout)

	// Dual-bar variants
	// ===========================================================================
	mut b3 := SmoothBar{
		post: bartender.Affix{
			pending: ' Merge'
			finished: ' 🐿️ ShipIt!'
		}
		theme: Theme.merge
	}
	b3.colorize(Color.cyan)
	for _ in 0 .. b3.iters {
		b3.progress()
		time.sleep(timeout * 2)
	}

	// ===========================================================================
	mut b4 := SmoothBar{
		theme: Theme.expand
		post: bartender.Affix{' Expand', ' 🌌 Expanded!'}
	}
	b4.colorize(Color.bright_black)
	for _ in 0 .. b4.iters {
		b4.progress()
		time.sleep(timeout * 2)
	}

	// Further customization
	// ===========================================================================
	mut b5 := SmoothBar{
		pre: term.blue('│')
		theme: Theme.split
	}
	b5.width -= 2
	b5.colorize(Color.green)
	for i in 0 .. b5.iters {
		// Add percentage and time to the label.
		// The accuracy of an ETA calculation increases as a process progresses.
		// In this example, showing the ETA is delayed. In the meantime, a spinner is displayed.
		eta := term.colorize(term.blue, if i <= f32(b.iters) * 0.1 {
			b5.spinner()
		} else {
			'${b5.eta() / 1000:.1f}s'
		})
		b5.post = bartender.Affix{
			pending: '${term.bright_black('│')} Split ${b5.pct()}% ${eta}'
			finished: '${term.bright_black('│')} 🪄 Done!'
		}
		b5.progress()
		time.sleep(timeout * 10)
	}
}
