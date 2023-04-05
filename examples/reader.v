module main

import io
import os
import time
import bartender

// This example shows the progress of writing content to an io.Writer (i.e., a file).
fn main() {
	mut start := time.ticks()

	// Create a reader with byte content to be written.
	// In this example, 500 megabytes of dummy content.
	mut r := bartender.bar_reader(bartender.Bar{}, '1234567890'.repeat(50 * 1024 * 1024).bytes())
	mut f := os.create('testfile')!
	io.cp(mut r, mut f)!
	f.close()

	println('Completed in ${f64(time.ticks() - start) / 1000:.2f}s')
	// Cleanup - delete written file.
	os.rm('testfile')!
}
