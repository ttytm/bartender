module bartender

import term
import os
import sync
import time

fn (mut b BarBase) set_fit_width() {
	term_width, _ := term.get_terminal_size()
	affix_width := utf8_str_visible_length(term.strip_ansi(b.pre_)) +
		utf8_str_visible_length(term.strip_ansi(b.post_))

	if term_width > b.width_ + affix_width {
		return
	}
	new_width := u16(term_width - affix_width)
	diff := b.width_ - new_width

	if diff > b.state.pos {
		b.state.pos = 0
	} else {
		b.state.pos -= diff
	}

	b.width_ = new_width
}

fn watch_(bars MultiBarType, mut wg sync.WaitGroup) {
	// NOTE: Same operation for Bars and SmoothBars (re-check with V's progression if this can be grouped).
	if bars is []&Bar {
		bars.ensure_mutli() or {
			eprintln(err)
			exit(0)
		}
		for {
			if bars.draw() {
				term.show_cursor()
				break
			}
			// Slow down redraw loop interval to reduce load.
			time.sleep(time.millisecond * 5)
		}
	}
	if bars is []&SmoothBar {
		bars.ensure_mutli() or {
			eprintln(err)
			exit(0)
		}
		for {
			if bars.draw() {
				term.show_cursor()
				break
			}
			// Slow down redraw loop interval to reduce load.
			time.sleep(time.millisecond * 5)
		}
	}
	wg.done()
}

fn handle_interrupt(signal os.Signal) {
	term.show_cursor()
	exit(0)
}
