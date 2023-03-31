module main

import bartender
import time

const timeout = time.millisecond * 20

fn main() {
	mut b := bartender.Bar{
		width: 60
		// Add pre- and postfixes such as labels and borders.
		pre: '|'
		post: bartender.Affix{
			pending: '| Loading...'
			finished: '| Done!'
		}
	}
	mut b2 := bartender.Bar{
		width: 60
		// Set custom runes.
		runes: bartender.BarRunes{
			progress: `#`
			remaining: `-`
		}
		indicator: `❯`
		// Add percent and time.
		pre: '['
		post: fn (b bartender.Bar) (string, string) {
			return '] ${b.pct()}% (${b.eta(0)})', '] Done!'
		}
	}

	for _ in 0 .. b.iters {
		b.progress()
		time.sleep(timeout)
	}
	for _ in 0 .. b2.iters {
		b2.progress()
		time.sleep(timeout * 5)
	}
}
