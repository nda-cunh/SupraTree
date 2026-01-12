vim9script

export def TestIfIconsWork(): bool
	try
		call(g:supratree_icons_glyph_func, ['test.txt'])
		return true
	catch
		return false
	endtry
enddef

export def GetIcons(path: string, is_directory: number = 0): string
	# TODO: Check a global variable for test if the icon function work
	# if this.icon_work == false
		# return ''
	# endif
	if is_directory == 0
		try
			return call(g:supratree_icons_glyph_func, [path])
		catch
			return ''
		endtry
	elseif is_directory == 1
		return '󰉋'
	elseif is_directory == 2
		return ''
	else
		return ''
	endif
enddef

export def GetPrefixLine(depth: number): string
	if depth < 2
		return repeat('  ', depth)
	endif
	return '  ' .. repeat('│ ', depth - 1)
enddef
