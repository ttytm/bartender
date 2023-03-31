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
		pre: '['
		post: bartender.Affix{'] Loading...', '] Done!'}
		// Set custom runes.
		runes: bartender.BarRunes{
			progress: `#`
			remaining: `-`
		}
		indicator: `❯`
	}

	for _ in 0 .. b.iters {
		b.progress()
		time.sleep(timeout)
	}
	for _ in 0 .. b2.iters {
		// TODO: update example.
		// Add percent and time.
		b2.post = '] ${b2.pct()}% (${b2.eta(0)})'
		b2.progress()
		time.sleep(timeout * 5)
	}
}
