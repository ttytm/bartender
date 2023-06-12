module main

import io
import os
import time
import term
import bartender

struct MyCustomReader {
	size u64 [required]
mut:
	reader io.Reader [required]
	pos    int
}

fn (mut r MyCustomReader) read(mut buf []u8) !int {
	if r.pos >= r.size {
		return io.Eof{}
	}
	n := r.reader.read(mut buf)!
	r.pos += n
	time.sleep(10 * time.millisecond)
	return n
}

fn main() {
	// Prepare dummy files.
	src_file_path := './examples/dummy-src-file.txt'
	dst_file_path := './examples/dummy-dst-file.txt'
	os.write_file(src_file_path, '123456789\n'.repeat(10 * 1024 * 1024))!
	mut src_file := os.open(src_file_path)!
	mut dst_file := os.create(dst_file_path)!
	defer {
		src_file.close()
		dst_file.close()
		os.rm(src_file_path) or { panic(err) }
		os.rm(dst_file_path) or { panic(err) }
	}

	// Create a smooth bar. Apply customizations.
	mut b := bartender.SmoothBar{
		pre: '│'
		post: fn (b bartender.SmoothBar) (string, string) {
			return '│ Saving... ${b.pct()}% ${term.blue(b.eta(20))}', '│ Saved!'
		}
	}
	b.colorize(.cyan)

	r := MyCustomReader{
		reader: src_file
		size: os.file_size(src_file_path)
	}

	mut bar_reader := b.reader(r, r.size)
	io.cp(mut bar_reader, mut dst_file)!
}
