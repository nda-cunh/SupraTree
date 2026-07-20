vim9script

var icon_cache: dict<string> = {}

export def ClearIconCache()
	icon_cache = {}
enddef

export def GetIcons(path: string, is_directory: number = 0): string
	if is_directory == 0
		if has_key(icon_cache, path)
			return icon_cache[path]
		endif
		var icon: string
		try
			icon = call(g:supratree_icons_glyph_func, [path])
		catch
			icon = ''
		endtry
		# Browsing a large project should not grow this without bound.
		if len(icon_cache) > 8192
			icon_cache = {}
		endif
		icon_cache[path] = icon
		return icon
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

export def IsLeft(winid: number): bool
	const pos = win_screenpos(winid)
	return pos[1] == 1
enddef

# Report an achievement metric, if the host provides the handler.
# No-op when g:SupraAchMetric is not defined.
export def Metric(name: string, value: number = 1)
	if exists('*g:SupraAchMetric')
		call g:SupraAchMetric(name, value)
	endif
enddef
