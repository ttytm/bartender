module bartender

import term
import time
import sync

fn watch_(bars MultiBarType, mut wg sync.WaitGroup) ! {
	// NOTE: Same operation for Bars and SmoothBars (re-check with V's progression if this can be grouped).
	// Tested match statements and alias types for arrays with bar references.
	if bars is []&Bar {
		ensure_multi(bars)!
		for {
			if bars.draw() {
				term.show_cursor()
				break
			}
			// Slow down redraw loop interval to reduce load.
			time.sleep(time.millisecond * 15)
		}
	} else if bars is []&SmoothBar {
		ensure_multi(bars)!
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

fn ensure_multi(bars MultiBarType) ! {
	// Same operation for both types.
	if bars is []&Bar {
		mut not_multi := []int{}
		for i, bar in bars {
			if !bar.multi {
				not_multi << i
			}
		}
		if not_multi.len > 0 {
			return bar_error(.missing_multi, not_multi.str())
		}
	} else if bars is []&SmoothBar {
		mut not_multi := []int{}
		for i, bar in bars {
			if !bar.multi {
				not_multi << i
			}
		}
		if not_multi.len > 0 {
			return bar_error(.missing_multi, not_multi.str())
		}
	}
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
