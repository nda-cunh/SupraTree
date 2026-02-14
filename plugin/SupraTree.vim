vim9script noclear

if has('patch-9.1.0850') == 0
	finish
endif

if exists('g:loaded_supratree')
	finish
endif

g:loaded_supratree = 1

import autoload 'SupraTree/SupraTree.vim' as Tree 
import autoload 'SupraTree/DarkenColor.vim' as DarkenColor

noremap <c-g> 	<scriptcmd>Tree.ToggleTree()<cr>
inoremap <c-g> 	<scriptcmd>Tree.ToggleTree()<cr>

g:supratree_icons_glyph_func         = get(g:, 'supratree_icons_glyph_func', 'g:WebDevIconsGetFileTypeSymbol')
g:supratree_icons_glyph_palette_func = get(g:, 'supratree_icons_glyph_palette_func', 'SupraIcons#Palette#Apply')
g:supratree_filter_files             = get(g:, 'supratree_filter_files', ['*.o', '*.class', '*.pyc', '*.exe', '*.dll', '*.so', '*.dylib'])
g:supratree_show_hidden              = get(g:, 'supratree_show_hidden', true)
g:supratree_force_color              = get(g:, 'supratree_force_color', '')
g:supratree_darken_amount            = get(g:, 'supratree_darken_amount', 22)
g:supratree_position                 = get(g:, 'supratree_position', 'left')
g:supratree_width                    = get(g:, 'supratree_width', 26)
g:supratree_open_on_startup          = get(g:, 'supratree_open_on_startup', true)
g:supratree_sortascending            = get(g:, 'supratree_sortascending', true)

command! SupraTreeToggle  Tree.ToggleTree()
command! SupraTreeOpen    Tree.OpenTree()
command! SupraTreeClose   Tree.CloseTree()
command! SupraTreeRefresh Tree.RefreshTree()

hi SupraTreeGitAdded ctermfg=10 guifg=#48BF84 guibg=NONE
hi SupraTreeGitModified ctermfg=14 guifg=#48A8BF guibg=NONE
hi SupraTreeGitDeleted ctermfg=9 guifg=#f44444 guibg=NONE
hi SupraTreeGitRenamed ctermfg=14 guifg=#48A8BF guibg=NONE

sign define SupraTreeGitModified     text=~ texthl=SupraTreeGitModified
sign define SupraTreeGitAdded   text=+ texthl=SupraTreeGitAdded
sign define SupraTreeGitDeleted     text=- texthl=SupraTreeGitDeleted
sign define SupraTreeGitRenamed	 text=r texthl=SupraTreeGitModified

hi SupraTreeDeleted ctermfg=9 guifg=#f44444 guibg=NONE
hi SupraTreeNewFile ctermfg=10 guifg=#48BF84 guibg=NONE
hi SupraTreeRenamed ctermfg=14 guifg=#48A8BF guibg=NONE
hi SupraTreeCopy ctermfg=13 guifg=#ab3db9 guibg=NONE

prop_type_add('SupraTreeDeletedProp', {highlight: 'SupraTreeDeleted', priority: 5060})
prop_type_add('SupraTreeNewFileProp', {highlight: 'SupraTreeNewFile', priority: 5060})
prop_type_add('SupraTreeRenamedProp', {highlight: 'SupraTreeRenamed', priority: 5060})
prop_type_add('SupraTreeCopyProp', {highlight: 'SupraTreeCopy', priority: 5060})

augroup SupraTree
	autocmd!
	if get(g:, 'supratree_open_on_startup', true) == true
		autocmd VimEnter * call Tree.OpenTree()
	endif
	autocmd TabEnter * call Tree.OnTabEnter()
	autocmd WinClosed * call Tree.WhenClosingWindow()
	autocmd BufEnter * call Tree.CheckNeedClose()
	autocmd ColorScheme * call DarkenColor.Create_HiColor()
	autocmd WinResized * call Tree.OnResize()
	autocmd BufWritePost * if exists('g:supra_tree') | g:supra_tree.GitRefresh() | endif
augroup END

DarkenColor.Create_HiColor()
