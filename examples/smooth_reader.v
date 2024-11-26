module main

import io
import os
import time
import term
import bartender

struct MyCustomReader {
	data []u8 @[required]
	size int  @[required]
mut:
	pos int
}

fn (mut r MyCustomReader) read(mut buf []u8) !int {
	n := copy(mut buf, r.data[r.pos..r.pos + buf.cap])
	time.sleep(1 * time.millisecond)
	r.pos += n
	if r.pos >= r.size {
		return io.Eof{}
	}
	return n
}

fn main() {
	// Create a customized smooth bar
	mut b := bartender.SmoothBar{
		pre:  '│'
		post: fn (b bartender.SmoothBar) (string, string) {
			return '│ Saving... ${b.pct()}% ${term.blue(b.eta(20))}', '│ Saved!'
		}
	}
	b.colorize(.cyan)

	// Prepare dummy files
	mut file_path := './examples/dummy-file.txt'
	mut file := os.create(file_path)!
	defer {
		file.close()
		os.rm(file_path) or { panic(err) }
	}

	// Create a reader
	data := [u8(1), 2, 3, 4, 5, 6, 7, 8, 9, `\n`].repeat(5 * 1024 * 1024 / 10) // 5MiB
	mut r := io.new_buffered_reader(
		reader: MyCustomReader{
			data: data
			size: data.len
		}
		cap:    8 * 1024 // 8 KiB
	)
	// Create a bar reader with reader `r`
	mut bar_reader := b.reader(r, u64(data.len))

	// Use the progress bar reader
	io.cp(mut bar_reader, mut file)!
}
