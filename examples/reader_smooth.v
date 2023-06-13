module main

import io
import os
import time
import term
import bartender

const max_bytes = 8 * 1024 // 8 KiB

pub struct MyCustomReader {
	data []u8 [required]
	size int  [required]
mut:
	pos int
}

fn (mut r MyCustomReader) read(mut buf []u8) !int {
	if r.pos >= r.size {
		return io.Eof{}
	}
	end := if r.pos + max_bytes >= r.size { r.size } else { r.pos + max_bytes }
	n := copy(mut buf, r.data[r.pos..end])
	time.sleep(1 * time.millisecond)
	r.pos += n
	return n
}

fn main() {
	// Create a smooth bar. Apply customizations
	mut b := bartender.SmoothBar{
		pre: '│'
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

	// Create reader.
	data := [u8(1), 2, 3, 4, 5, 6, 7, 8, 9, `\n`].repeat(5 * 1024 * 1024 / 10) // 5MiB
	mut r := io.new_buffered_reader(
		reader: MyCustomReader{
			data: data
			size: data.len
		}
	)

	// Create bar readre based on reader.
	mut bar_reader := b.reader(r, u64(data.len))
	// Use bar reader.
	io.cp(mut bar_reader, mut file)!
}
