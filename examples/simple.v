module main

import bartender
import time

fn main() {
	mut b := bartender.Bar{
		width: 60
		label: ['Loading...', 'Done!']!
		border: ['|', '|']!
	}
	mut b2 := bartender.Bar{
		width: 60
		label: ['Loading...', 'Done!']!
		border: ['[', ']']!
		runes: [`#`, `-`]!
		indicator: `❯`
	}

	for _ in 0 .. b.width {
		b.progress()
		time.sleep(time.millisecond * 20)
	}
	for _ in 0 .. b2.width {
		b2.progress()
		time.sleep(time.millisecond * 30)
	}
}
