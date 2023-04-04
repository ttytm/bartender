module main

import io
import os
import time
import term
import bartender

fn main() {
	mut start := time.ticks()

	// Create a smooth bar. Apply customizations.
	mut b := bartender.SmoothBar{
		pre: '│'
		post: fn (b bartender.SmoothBar) (string, string) {
			return '│ Saving... ${b.pct()}% ${term.blue(b.eta(20))}', '│ Saved!'
		}
	}
	b.colorize(.cyan)

	mut r := bartender.bar_reader(b, '1234567890'.repeat(50 * 1024 * 1024).bytes())
	mut f := os.create('testfile') or { panic(err) }
	io.cp(mut r, mut f)!
	f.close()

	println('Completed in ${f64(time.ticks() - start) / 1000:.2f}s')
	os.rm('testfile')!
}
