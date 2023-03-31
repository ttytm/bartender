module main

import bartender
import time

const timeout = time.millisecond * 30

fn main() {
	// Default bar
	// ===========================================================================
	mut b := bartender.Bar{}
	for _ in 0 .. b.iters {
		b.progress()
		time.sleep(timeout)
	}

	// Add config fields
	// ===========================================================================
	mut b2 := bartender.Bar{
		width: 60
		pre: '['
		post: bartender.Affix{
			pending: '| Loading...'
			finished: '| Done!'
		}
	}
	for _ in 0 .. b2.iters {
		b2.progress()
		time.sleep(timeout)
	}

	// ===========================================================================
	mut b3 := bartender.Bar{
		width: 60
		// Set custom runes
		runes: bartender.BarRunes{
			progress: `#`
			remaining: `-`
		}
		indicator: `❯`
		pre: '['
		// Customize percent and time
		post: fn (b bartender.Bar) (string, string) {
			return '] ${b.pct()}% (${b.eta(0)})', '] Done!'
		}
	}
	for _ in 0 .. b3.iters {
		b3.progress()
		time.sleep(timeout * 5)
	}
}
