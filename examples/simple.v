module main

import bartender
import time
import term

const timeout = time.millisecond * 20

fn main() {
	mut b := bartender.Bar{
		width: 60
		label: ['Loading...', 'Done!']!
		border: ['|', '|']!
	}
	mut b2 := bartender.Bar{
		width: 60
		label: ['', 'Done!']!
		border: ['[', ']']!
		runes: [`#`, `-`]!
		indicator: `❯`
	}

	for _ in 0 .. b.width {
		b.progress()
		time.sleep(timeout)
	}
	for _ in 0 .. b2.width {
		// Add percent and time to label
		b2.label[0] = '${b2.pct()}% (${b2.eta() / 1000:.1f}s)'
		b2.progress()
		time.sleep(timeout * 5)
	}
}
