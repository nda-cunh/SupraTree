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
			# g:SupraTreeDarkenAmount 
			if IsLightColor(bgcolor)
				darkened_bg = LightenColor(bgcolor, get(g:, 'SupraTreeDarkenAmount', 15))
			else
				darkened_bg = DarkenColor(bgcolor, get(g:, 'SupraTreeDarkenAmount', 15))
			endif
		endif
	endif
	hi clear TreeNormalDark
	execute 'hi TreeNormalDark guifg=' .. fgcolor .. ' guibg=' .. darkened_bg
enddef

def IsLightColor(hex: string): number
    var color = hex
    if color[0] == '#'
        color = color[1 : ]
    endif

    # Extraction des composantes RGB
    const r = str2nr(color[0 : 1], 16)
    const g = str2nr(color[2 : 3], 16)
    const b = str2nr(color[4 : 5], 16)

    const luminance = (0.2126 * r + 0.7152 * g + 0.0722 * b)

    return luminance > 127.5 ? 1 : 0
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


# Like DarkenColor but lightens instead
def LightenColor(_color: string, percent: number): string
	var color = _color
	if color[0] == '#'
		color = color[1 : ]
	endif

	var r: float = str2nr(color[0 : 1], 16) / 255.0
	var g: float = str2nr(color[2 : 3], 16) / 255.0
	var b: float = str2nr(color[4 : 5], 16) / 255.0

	var factor = percent / 100.0
	r += (1.0 - r) * factor
	g += (1.0 - g) * factor
	b += (1.0 - b) * factor

	return printf('#%02X%02X%02X', float2nr(r * 255), float2nr(g * 255), float2nr(b * 255))
enddef
