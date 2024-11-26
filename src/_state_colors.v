module bartender

type BarColorType = BarColor | Color
type ColorType = Color | FgBg

pub struct BarColor {
pub:
	progress  ColorType = Color.white
	remaining ColorType = Color.bright_black
	indicator ColorType = Color.white
}

pub struct FgBg {
	fg Color = .white
	bg Color = .reset
}

enum Surface {
	fg
	bg
}

pub enum Color {
	reset
	black
	red
	green
	yellow
	blue
	magenta
	cyan
	white
	gray
	bright_black
	bright_red
	bright_green
	bright_yellow
	bright_blue
	bright_magenta
	bright_cyan
	bright_white
}
