module bartender

import term
import time
import sync

fn watch_(mut bars MultiBarType, mut wg sync.WaitGroup) {
	// NOTE: Same operation for Bars and SmoothBars (re-check with V's progression if this can be grouped).
	// Tested match statements and alias types for arrays with bar references.
	if mut bars is []&Bar {
		for mut b in bars {
			b.multi = true
		}
		for {
			if bars.draw() {
				term.show_cursor()
				break
			}
			// Slow down redraw loop interval to reduce load.
			time.sleep(time.millisecond * 15)
		}
	} else if mut bars is []&SmoothBar {
		for mut b in bars {
			b.multi = true
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

fn (bars []&Bar) draw() bool {
	mut finished := true
	mut formatted := []string{}
	for b in bars {
		formatted << b.format()
		if b.state.pos > 0 && b.state.pos < b.width_ {
			finished = false
		}
	}
	println(formatted.join_lines())
	if !finished {
		term.cursor_up(bars.len)
	}
	return finished
}

fn (bars []&SmoothBar) draw() bool {
	mut finished := true
	mut formatted := []string{}
	for b in bars {
		formatted << b.format()
		if b.state.pos < b.width_ {
			finished = false
		}
	}
	println(formatted.join_lines())
	if !finished {
		term.cursor_up(bars.len)
	}
	return finished
}
