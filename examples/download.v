module main

import bartender
import net.http
import os
import time
import io

struct ProgressReader {
	data []u8 [required]
	size int  [required]
mut:
	bar bartender.SmoothBar
	state        int
	pos          int
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
	if (f64(r.pos) / r.size * r.bar.width) > r.bar.state {
		r.bar.progress()
		// Since this is a relatively small file, delay the progress for visualization purposes.
		time.sleep(time.millisecond * 2)
	}
	return n
}

fn create_reader(data []u8) !&io.BufferedReader {
	return io.new_buffered_reader(
		reader: ProgressReader{
			data: data
			size: data.len
			bar: bartender.SmoothBar{
				width: 60
				label: ['Downloading...', 'Download completed!']!
				border: ['│', '│']!
			}
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

	mut f := os.create(file_path) or { panic(err) }
	mut r := create_reader(resp.body.bytes()) or { panic(err) }

	io.cp(mut r, mut f) or { panic(err) }
	os.rm(file_path) or { panic(err) }
}
