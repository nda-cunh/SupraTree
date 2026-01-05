vim9script

export def Create_HiColor()
	var bgcolor = synIDattr(synIDtrans(hlID('Normal')), 'bg')
	var fgcolor = synIDattr(synIDtrans(hlID('Normal')), 'fg')
	var darkened_bg: string

	if exists('g:SupraTreeForceColor') && g:SupraTreeForceColor != ''
		darkened_bg = g:SupraTreeForceColor
	else
		if bgcolor == '' || fgcolor == ''
			bgcolor = 'NONE'
			fgcolor = '#ABB2BF'
			darkened_bg = bgcolor 
		else
			if exists('g:SupraTreeDarkenAmount')
				darkened_bg = DarkenColor(bgcolor, g:SupraTreeDarkenAmount)
			else
				darkened_bg = DarkenColor(bgcolor, 15)
			endif
		endif
	endif
	hi clear TreeNormalDark
	execute 'hi TreeNormalDark guifg=' .. fgcolor .. ' guibg=' .. darkened_bg
enddef

def DarkenColor(_color: string, percent: number): string
	var color = _color
	if color[0] == '#'
		color = color[1 : ]
	endif

    var r: float = str2nr(color[0 : 1], 16) / 255.0
    var g: float = str2nr(color[2 : 3], 16) / 255.0
    var b: float = str2nr(color[4 : 5], 16) / 255.0

	var factor = (100.0 - percent) / 100.0
    r *= factor
    g *= factor
    b *= factor

	return printf('#%02X%02X%02X', float2nr(r * 255), float2nr(g * 255), float2nr(b * 255))
enddef
