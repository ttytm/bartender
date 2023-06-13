module main

import io
import os
import time
import bartender

// Example: Creating a bar reader from the file reader of `src_file` (with 500MiB dummy content)
// and copying its contents to `dst_file`.
fn main() {
	mut start := time.new_stopwatch()

	src_file_path := './examples/dummy-src-file.txt'
	dst_file_path := './examples/dummy-dst-file.txt'

	os.write_file(src_file_path, '123456789\n'.repeat(50 * 1024 * 1024))!

	mut src_file := os.open(src_file_path)!
	mut dst_file := os.create(dst_file_path)!
	defer {
		src_file.close()
		dst_file.close()
		os.rm(src_file_path) or { panic(err) }
		os.rm(dst_file_path) or { panic(err) }
	}

	bar := bartender.Bar{}
	// Pass src_file as `io.Reader` to use it in a bar reader.
	mut bar_reader := bar.reader(src_file, os.file_size(src_file_path))
	// Use the `bar_reader`
	io.cp(mut bar_reader, mut dst_file)!

	println('Completed in ${start.elapsed()}')
}
