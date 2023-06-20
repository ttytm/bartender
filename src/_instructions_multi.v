module bartender

import term
import time
import sync

fn watch_(mut bars MultiBarType, mut wg sync.WaitGroup) {
	// NOTE: Operation for Bars and SmoothBars can be grouped potentially
	// (comma separation won't work atm. Re-check with V's progression).
	match mut bars {
		[]&Bar {
			for mut b in bars {
				b.multi = true
				b.setup()
			}
			time.sleep(time.millisecond * 15)
			for {
				if bars.draw() {
					term.show_cursor()
					break
				}
				// Slow down redraw loop interval to reduce load.
				time.sleep(time.millisecond * 15)
			}
		}
		[]&SmoothBar {
			for mut b in bars {
				b.multi = true
				b.setup()
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
	}
	wg.done()
}

fn (bars []&Bar) draw() bool {
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
