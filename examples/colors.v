module main

import bartender { Affix, Bar, BarColor, BarRunes, Color, FgBg }
import time
import term

const timeout = time.millisecond * 20

fn main() {
	// ===========================================================================
	mut b := Bar{
		width: 60
		pre: term.green('[')
		post: Affix{
			pending: '${term.green(']')} Single Color'
			finished: '${term.green(']')} Done!'
		}
		indicator: `❯`
	}
	b.colorize(Color.green)
	for _ in 0 .. b.width {
		b.progress()
		time.sleep(timeout)
	}

	// ===========================================================================
	mut b2 := Bar{
		width: 60
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
	for _ in 0 .. b2.width {
		b2.progress()
		time.sleep(timeout)
	}

	// ===========================================================================
	mut b3 := Bar{
		width: 59
		pre: term.cyan('╘')
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
	for _ in 0 .. b3.width {
		b3.post = term.cyan('╕') + ' ' + term.cyan(b3.spinner()) + ' Customized...'
		b3.progress()
		time.sleep(timeout * 3)
	}
}
