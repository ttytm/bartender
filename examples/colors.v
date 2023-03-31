module main

import bartender { Affix, Bar, BarColor, BarRunes, Color, FgBg }
import time
import term

const timeout = time.millisecond * 20

fn main() {
	// ===========================================================================
	mut b := Bar{
		width: 60 // Default value
		pre: term.magenta('[')
		post: Affix{
			pending: '${term.magenta(']')} Single Color'
			finished: '${term.magenta(']')} Done!'
		}
		indicator: `❯`
	}
	// Colorize all components uniformly.
	b.colorize(Color.magenta)
	for _ in 0 .. b.iters {
		b.progress()
		time.sleep(timeout)
	}

	// ===========================================================================
	mut b2 := Bar{
		pre: term.bright_black('[')
		post: Affix{'${term.bright_black(']')} Multi Color', '${term.bright_black(']')} Done!'}
		runes: BarRunes{
			progress: `#`
			remaining: `-`
		}
		indicator: `❯`
	}
	// Component Colors
	b2.colorize(BarColor{
		progress: Color.cyan
		remaining: Color.bright_black
		indicator: Color.magenta
	})
	for _ in 0 .. b2.iters {
		b2.progress()
		time.sleep(timeout * 2)
	}

	// ===========================================================================
	mut b3 := Bar{
		pre: term.cyan('╒')
		runes: BarRunes{`═`, `─`}
		indicator: `❯`
	}
	b3.colorize(BarColor{
		progress: FgBg{
			fg: .cyan
			// Be specific about the foreground and/or background.
			// fg: .black
			// bg: .cyan
		}
		remaining: Color.black
		indicator: Color.magenta
	})
	for _ in 0 .. b3.iters {
		b3.post = term.cyan('╕') + ' Customized...'
		b3.progress()
		time.sleep(timeout * 2)
	}

	// ===========================================================================
	mut b4 := Bar{
		pre: term.cyan('│')
		post: term.cyan('│')
		runes: BarRunes{`█`, `░`}
	}
	b4.colorize(BarColor{
		progress: Color.cyan
		indicator: Color.cyan
	})
	for i in 0 .. b4.iters {
		j := term.bright_black('(${i + 1}/${b4.width})')
		b4.post = '${term.cyan('│')} ${j} ${term.blue(b4.spinner())}'
		b4.progress()
		time.sleep(timeout * 3)
	}
}
