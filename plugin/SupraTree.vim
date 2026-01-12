vim9script

if has('patch-9.1.0850') == 0
	finish
endif


import autoload 'SupraTree/SupraTree.vim' as Tree 
import autoload 'SupraTree/DarkenColor.vim' as DarkenColor

noremap <c-g> 	<scriptcmd>Tree.ToggleTree()<cr>
inoremap <c-g> 	<scriptcmd>Tree.ToggleTree()<cr>

g:supratree_icons_glyph_func = 'g:WebDevIconsGetFileTypeSymbol'
g:supratree_icons_glyph_palette_func = 'SupraIcons#Palette#Apply'
g:supratree_filter_files = ['*.o', '*.class', '*.pyc', '*.exe', '*.dll', '*.so', '*.dylib']
g:supratree_show_hidden = true 
g:SupraTreeForceColor = ''
g:SupraTreeDarkenAmount = 22

hi SupraTreeDeleted ctermfg=9 guifg=#f44444 guibg=NONE
prop_type_add('SupraTreeDeletedProp', {highlight: 'SupraTreeDeleted', priority: 1060})

augroup SupraTree
	autocmd!
	autocmd VimEnter * call g:OpenTree()
	autocmd TabEnter * call Tree.OnTabEnter()
	autocmd WinClosed * call Tree.WhenClosingWindow()
	autocmd BufEnter * call Tree.CheckNeedClose()
augroup END

def g:ToggleTree()
	Tree.ToggleTree()
enddef

def g:OpenTree()
	g:supratree_isopen = true
	Tree.OpenWindow()
enddef

def g:CloseTree()
	g:supratree_isopen = false 
	Tree.CloseWindow()
enddef

DarkenColor.Create_HiColor()
