// NOTE: This example is more of a file-write than a true download progress example.
// This is because we are loading the full response body and then performing the write operation.
// For a real download progress, we would need to chunk-download the body.
module main

import bartender
import net.http
import os
import time
import io
import term

struct ProgressReader {
	data []u8 [required]
	size int  [required]
mut:
	bar bartender.SmoothBar
	pos int
}

fn (mut r ProgressReader) read(mut buf []u8) !int {
	if r.pos >= r.size {
		return io.Eof{}
	}
	// max_bytes := 32 * 1024
	max_bytes := 100 // 32 KiB above is usual.
	end := if r.pos + max_bytes >= r.size { r.size } else { r.pos + max_bytes }
	n := copy(mut buf, r.data[r.pos..end])
	r.pos += n

	if (f64(r.pos) / r.size * r.bar.width) > r.bar.pos() {
		r.bar.progress()
		// Since this is a relatively small file, we delay the progress for visualization purposes.
		time.sleep(time.millisecond * 20)
	}
	return n
}

fn create_reader(data []u8) !&io.BufferedReader {
	mut bar := bartender.SmoothBar{
		pre: '│'
		post: fn (b bartender.SmoothBar) (string, string) {
			return '│ Downloading... ${b.pct()}% ${term.blue(b.eta(20))}', '│ Download completed!'
		}
	}
	bar.colorize(.cyan)

	return io.new_buffered_reader(
		reader: ProgressReader{
			data: data
			size: data.len
			bar: bar
		}
	)
}

fn main() {
	file_path := 'v_linux.zip'
	url := 'https://github.com/vlang/v/releases/latest/download/v_linux.zip'

	mut resp := http.get(url)!
	if resp.status_code != 200 {
		eprintln('[Error] Download failed with statuscode: ${resp.status_code}')
		exit
	}

	mut f := os.create(file_path)!
	mut r := create_reader(resp.body.bytes())!

	io.cp(mut r, mut f)!
	os.rm(file_path)!
}
