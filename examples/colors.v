module main

import bartender
import time
import term

fn main() {
	mut b := bartender.Bar{
		width: 60
		label: ['Loading...', 'Done!']!
		border: ['[', ']']!
		runes: [`#`, `-`]!
		indicator: `❯`
	}
	b.colorize(term.green)
	for _ in 0 .. b.width {
		b.progress()
		time.sleep(time.millisecond * 20)
	}

	mut b2 := bartender.Bar{
		width: 60
		label: ['Loading...', 'Done!']!
		border: ['[', ']']!
		runes: [`#`, `-`]!
		indicator: `❯`
	}
	b2.colorize(bartender.BarColor{
		progress: term.cyan
		fill: term.bright_black
		indicator: term.magenta
		border: term.bright_black
	})
	for _ in 0 .. b2.width {
		b2.progress()
		time.sleep(time.millisecond * 20)
	}

	mut b3 := bartender.Bar{
		width: 60
		border: ['[', ']']!
		runes: [`═`, ` `]!
		indicator: `❯`
	}
	b3.colorize(bartender.BarColors{
		progress: [term.black, term.bg_green]!
		fill: [term.black, term.bg_black]!
		indicator: [term.red, term.bg_green]!
		border: [term.bright_black, term.bg_black]!
	})
	for _ in 0 .. b3.width {
		b3.progress()
		time.sleep(time.millisecond * 20)
	}
}
