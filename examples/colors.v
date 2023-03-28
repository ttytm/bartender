module main

import bartender
import time
import term

const timeout = time.millisecond * 20

fn main() {
	// ===========================================================================
	mut b := bartender.Bar{
		width: 60
		label: ['Single Color', 'Done!']!
		border: ['[', ']']!
		runes: [`#`, `-`]!
		indicator: `❯`
	}
	b.colorize(term.green)
	for _ in 0 .. b.width {
		b.progress()
		time.sleep(timeout)
	}

	// ===========================================================================
	mut b2 := bartender.Bar{
		width: 60
		label: ['', 'Done!']!
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
		b2.label[0] = 'Multi Color (${b2.eta() / 1000:.1f}s)'
		b2.progress()
		time.sleep(timeout * 2)
	}

	// ===========================================================================
	mut b3 := bartender.Bar{
		width: 60
		label: ['Advanced Customization', 'Done!']!
		border: ['│', '│']!
		runes: [`═`, ` `]!
		indicator: `❯`
	}
	b3.colorize(bartender.BarColors{
		progress: [term.black, term.bg_cyan]!
		fill: [term.black, term.bg_black]!
		indicator: [term.magenta, term.bg_cyan]!
		border: [term.bright_black, term.bg_black]!
	})
	for _ in 0 .. b3.width {
		b3.progress()
		time.sleep(timeout)
	}
}
