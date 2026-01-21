vim9script

import autoload 'SupraTree/SupraTreeBuffer.vim' as NSupraTreeBuffer

type SupraTreeBuffer = NSupraTreeBuffer.SupraTreeBuffer

export def OpenTree()
	g:supratree_isopen = true
	SupraTree#SupraTree#OpenWindow()
enddef

export def CloseTree()
	g:supratree_isopen = false 
	SupraTree#SupraTree#CloseWindow()
enddef

export def ToggleTree()
	const value = get(g:, 'supratree_isopen', false)
	if value == true
		SupraTree#SupraTree#CloseTree()
	else
		SupraTree#SupraTree#OpenTree()
	endif
enddef


export def CheckNeedClose()
	var lst_tab = tabpagebuflist()
	if len(lst_tab) == 1
		const buf = lst_tab[0]
		if getbufvar(buf, '&filetype') == 'SupraTree'
			const winid = bufwinid(buf)
			timer_start(0, (_) => {
				noautocmd win_execute(winid, 'q')
			})
			unlet t:supratree_winid
		endif
	endif
enddef

export def WhenClosingWindow()
	# check if the filetype of the closed window is SupraTree
	const winid = str2nr(expand('<afile>'))
	const buf = winbufnr(winid)
	if getbufvar(buf, '&filetype') != 'SupraTree'
		return
	endif
	silent! unlet t:supratree_winid
	g:supratree_isopen = false
enddef

export def OnTabEnter()
	var value = get(g:, 'supratree_isopen', false)
	if value == true
		timer_start(0, (_) => {
			SupraTree#SupraTree#OpenWindow()
		})
	else
		SupraTree#SupraTree#CloseWindow()
	endif
enddef

##############################
## Window Management Functions
##############################

# Just close the window containing the tree buffer
export def CloseWindow()
	if exists('t:supratree_winid')
		var winid: number = t:supratree_winid
		noautocmd win_execute(winid, 'q')
		unlet t:supratree_winid
	endif
enddef

# Just open a new window and load the SupraTree buffer
export def OpenWindow()
	if exists('t:supratree_winid')
		return
	endif

	const size = get(g:, 'SupraTreeWidth', 26)

	# If the position is left, open a topleft vertical split
	if get(g:, 'SupraTreePosition', 'left') == 'left'
		execute 'noautocmd topleft vertical :new'
	else
		execute 'noautocmd rightbelow vertical :new'
	endif

	# Set the width of the window
	execute ':' .. size .. ' wincmd |'

	t:supratree_winid = win_getid()
	if exists('g:supra_tree')	
		const tree: SupraTreeBuffer = g:supra_tree
		const buf = tree.GetBuf()

		execute 'b ' .. buf
		if line('$', t:supratree_winid) < 3
			# echom "SupraTree: Refreshing SupraTree Buffer..."
			tree.Refresh()
		endif
	else
		# Init The SupraTree Buffer
		var instance = SupraTreeBuffer.new()
		g:supra_tree = instance
		b:supra_tree = instance
	endif
	wincmd p
enddef

export def RefreshTree()
	if exists('g:supra_tree')
		const tree: SupraTreeBuffer = g:supra_tree
		tree.RefreshFileSystem()
	endif
enddef
