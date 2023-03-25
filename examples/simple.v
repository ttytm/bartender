module main

import bartender
import time
import term

fn main() {
	mut b := bartender.Bar{
		width: 60
		label: ['Loading...', 'Done!']!
		border: ['|', '|']!
	}
	mut b2 := bartender.Bar{
		width: 60
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

	b2.reset()
	b2.colorize(term.green)
	for _ in 0 .. b2.width {
		b2.progress()
		time.sleep(time.millisecond * 20)
	}

	mut b3 := bartender.Bar{
		width: 60
		border: ['[', ']']!
		runes: [`#`, `-`]!
		indicator: `❯`
	}
	b3.colorize(bartender.BarColor{term.bright_black, term.cyan, term.magenta})
	for _ in 0 .. b3.width {
		b3.progress()
		time.sleep(time.millisecond * 20)
	}
}
