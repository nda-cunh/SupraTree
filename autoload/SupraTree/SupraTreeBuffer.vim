vim9script

import autoload './Toggle.vim' as Toggle
import autoload './Input.vim' as Popup
import autoload './Utils.vim' as Utils
import autoload './Node.vim' as ANode
import autoload './SpecialNode.vim' as ASpecialNode
import autoload './DirectoryNode.vim' as ADirectoryNode
import autoload './FileNode.vim' as AFileNode
import autoload './NodeType.vim' as NodeType
import autoload './Modified.vim' as AModified
import autoload './PopupSave.vim' as PopupSave

type Input = Popup.Input
type Node = ANode.Node
type SpecialNode = ASpecialNode.SpecialNode
type DirectoryNode = ADirectoryNode.DirectoryNode
type FileNode = AFileNode.FileNode
type Modified = AModified.Modified

export class SupraTreeBuffer
	var buf: number # Buffer number
	var open_folders = [] # Contains the list of open folders
	var lnum: number # Current line number to write
	var table_actions: list<Node>
	var icon_work: bool
	var general_node: DirectoryNode
	var clipboard: list<Node> = []

	def new()
		const buf = bufadd('SupraTree')
		execute 'buffer ' .. buf
		g:supra_tree = this
		b:supra_tree = this

		setbufvar(buf, '&buflisted', 0)
		setbufvar(buf, '&buftype', 'acwrite')
		setbufvar(buf, '&bufhidden', 'hide')
		setbufvar(buf, '&modeline', 0)
		setbufvar(buf, '&swapfile', 0)
		setbufvar(buf, '&undolevels', -1)
		setbufvar(buf, '&nu', 0)
		setbufvar(buf, '&relativenumber', 0)
		setbufvar(buf, "&updatetime", 2500)
		setbufvar(buf, '&signcolumn', 'yes')
		setbufvar(buf, '&fillchars', 'vert:│,eob: ')
		setbufvar(buf, '&wrap', 0)
		setbufvar(buf, '&ea', 0)
		setbufvar(buf, '&relativenumber', 0)
		setbufvar(buf, '&winfixwidth', 1)
		setbufvar(buf, '&cursorline', 1)
		setbufvar(buf, '&winminwidth', 10)
		setbufvar(buf, '&wincolor', 'TreeNormalDark')
		setbufvar(buf, '&filetype', 'SupraTree')


		nnoremap <buffer> <cr>			<scriptcmd>b:supra_tree.OnClick(Toggle.Enter)<cr>
		nnoremap <buffer> <c-t>			<scriptcmd>b:supra_tree.OnClick(Toggle.NewTab)<cr>
		nnoremap <buffer> <c-h>			<scriptcmd>b:supra_tree.OnClick(Toggle.Split)<cr>
		nnoremap <buffer> <c-v>			<scriptcmd>b:supra_tree.OnClick(Toggle.VSplit)<cr>
		nnoremap <buffer> <2-LeftMouse>	<scriptcmd>b:supra_tree.OnClick(Toggle.Enter)<cr>
		nnoremap <buffer> <3-LeftMouse>	<scriptcmd>b:supra_tree.OnClick(Toggle.Enter)<cr>
		nnoremap <buffer> <4-LeftMouse>	<scriptcmd>b:supra_tree.OnClick(Toggle.Enter)<cr>
		nnoremap <buffer> <c-s>			<scriptcmd>b:supra_tree.SaveActions()<cr>
		nnoremap <buffer> r 			<scriptcmd>b:supra_tree.Refresh()<cr>
		nnoremap <buffer> dd			<scriptcmd>b:supra_tree.OnRemove(false)<cr>
		vnoremap <buffer> d				<esc><scriptcmd>b:supra_tree.OnRemove(true)<cr>
		nnoremap <buffer> i				<scriptcmd>b:supra_tree.OnRename()<cr>
		nnoremap <buffer> O 			<scriptcmd>b:supra_tree.OnNewFile(true)<cr>
		nnoremap <buffer> o 			<scriptcmd>b:supra_tree.OnNewFile(false)<cr>
		nnoremap <buffer> p				<scriptcmd>b:supra_tree.OnPaste()<cr>
		nnoremap <buffer> yy				<scriptcmd>b:supra_tree.OnYank(false)<cr>
		vnoremap <buffer> y				<esc><scriptcmd>b:supra_tree.OnYank(true)<cr>

		au BufWriteCmd <buffer>		if exists('b:supra_tree')	| b:supra_tree.SaveActions() | endif
		au BufWipeout <buffer>		SupraTreeBuffer.Quit()

		this.buf = buf
		this.general_node = DirectoryNode.new(getcwd(), '', NodeType.SimpleFile, -1)
		this.general_node.Open()
		this.Refresh()
	enddef

	def GetBuf(): number
		return this.buf
	enddef

	static def Quit()
		silent! unlet g:supratree_isopen
		silent! unlet t:supratree_isopen
		silent! unlet g:supra_tree
		silent! unlet b:supra_tree
	enddef

	def GoToPath(path: string)
		const total_lines = line('$')
		var lnum = 1
		while lnum <= total_lines
			const line_path = this.table_actions[lnum - 1].GetFullPath()
			if line_path == path
				cursor(lnum, 1)
				return
			endif
			lnum += 1
		endwhile
	enddef

	def RefreshKeepPos()
		const winsaveview = winsaveview()
		const pos = getpos('.')
		this.Refresh()
		call setpos('.', pos)
		call winrestview(winsaveview)
	enddef

	def Refresh()
		setbufvar(this.buf, '&modifiable', 1)
		# clear the buffer
		call setbufline(this.buf, 1, [])
		call deletebufline(this.buf, 1, '$')
		this.DrawHeader(getcwd())
		this.general_node.DrawChilds()
		# test if the function exist
		if exists('g:supratree_icons_glyph_palette_func')
			silent! call(g:supratree_icons_glyph_palette_func, [])
		endif
		setbufvar(this.buf, '&modified', 0)
		setbufvar(this.buf, '&modifiable', 0)
	enddef


	#######################################################
	# Save Actions  (called on BufWriteCmd) or with <C-S>
	#######################################################
	def SaveActions()
		var modified = Modified.new()

		this.general_node.GetAllSaveActions(modified)

		if modified.IsEmpty() == true
			throw "SupraTree: No changes to save."
		endif

		var SavePopup = PopupSave.PopupSave.new(modified) 

		SavePopup.OnYes(() => {
			modified.ApplyAll()
			this.general_node = DirectoryNode.new(getcwd(), '', NodeType.SimpleFile, -1)
			this.general_node.Open()
			this.RefreshKeepPos()
		})

		SavePopup.OnCancel(() => {
			this.general_node = DirectoryNode.new(getcwd(), '', NodeType.SimpleFile, -1)
			this.general_node.Open()
			this.RefreshKeepPos()
		})
	enddef

	# draw the tree header
	def DrawHeader(pwd: string)
		const path = substitute(pwd, '^' .. $HOME, '~', '')
		this.icon_work = Utils.TestIfIconsWork()
		this.lnum = 1
		this.table_actions = []

		this.NewAddLine(path .. '/', SpecialNode.new('ChangePath'))
		this.NewAddLine('', SpecialNode.new('null'))
		this.NewAddLine(Utils.GetIcons('', 2) .. ' ../', SpecialNode.new('prev'))
		# this.NewAddLine(, this.general_node)
	enddef

	def NewAddLine(line: string, node: Node)
		setbufline(this.buf, this.lnum, line)
		add(this.table_actions, node)
		this.lnum += 1
	enddef

	######################################
	# Events 
	######################################

	def OnNewFile(is_up: bool)
		const current_lnum = line('.')
		const target_lnum = is_up ? current_lnum - 1 : current_lnum

		var index = current_lnum + (is_up == true ? -1 : 0)
		var test_node: Node = this.table_actions[index - 1]
		var node_parent: Node
		if test_node->instanceof(DirectoryNode) == true
			node_parent = test_node
		else
			node_parent = test_node.GetParent()
		endif
		if node_parent->instanceof(SpecialNode)
			throw "Cannot create a new file here."
		endif

		setbufvar(this.buf, '&modifiable', 1)

		append(target_lnum, "")

		cursor(target_lnum + 1, 1)

		var input = CreatePopup('', '󰑕 New File')

		input.AddCbChanged((key, line) => {
			setbufline(this.buf, target_lnum + 1, '  ' .. input.GetPrompt() .. line)
		})

		input.AddCbQuit(() => {
			this.RefreshKeepPos()
		})

		input.AddCbEnter((new_name) => {
			# create the new file with the given name
			if len(new_name) == 0
				throw "File name cannot be empty."
			endif
			# test the filename with an regex for invalid characters
			var is_directory: bool
			if new_name[-1] == '/'
				# an directory is only word characters but end with / can't
				# contains more '/' but only at the end
				if !(new_name[0 : -2] =~# '\v^[a-zA-Z0-9._-]+$')
					throw "Invalid directory name."
				endif
				is_directory = true
			else
				if !(new_name =~# '\v^[a-zA-Z0-9._-]+$')
					throw "Invalid file name."
				endif
				is_directory = false
			endif

			var new_node: Node
			var parent_path: string
			if node_parent->instanceof(DirectoryNode) == true
				parent_path = node_parent.parent .. '/' .. node_parent.name
			else
				parent_path = node_parent.GetParent().parent .. '/' .. node_parent.node_parent.name
			endif

			if is_directory == true
				new_node = DirectoryNode.new(parent_path, new_name[0 : -2], NodeType.NewFile, node_parent.depth + 1)
			else
				new_node = FileNode.new(parent_path, new_name, NodeType.NewFile, node_parent.depth + 1)
			endif

			node_parent.AddChild(new_node)
			this.Refresh()
			input.Close()
			this.GoToPath(new_node.GetFullPath())
		})
	enddef

	def OnRename()
		const current_lnum = line('.')
		const node = this.table_actions[current_lnum - 1]

		if node->instanceof(SpecialNode)
			throw "Cannot rename this item."
		endif
		if node.type == NodeType.Deleted
			throw "Cannot rename a deleted file."
		endif

		noautocmd setbufvar(this.buf, '&modifiable', 1)

		var input = CreatePopup(node.name, '󰒓 Rename File')

		input.AddCbChanged((key, line) => {
			setbufline(this.buf, current_lnum, node.GetPrefixLine() .. '│ ' .. input.GetPrompt() .. line)
		})

		input.AddCbQuit(() => {
			this.RefreshKeepPos()
			setbufvar(this.buf, '&modifiable', 0)
		})

		input.AddCbEnter((new_name) => {
			node.Rename(new_name)
			this.Refresh()
			input.Close()
			this.GoToPath(node.GetFullPath())
			setbufvar(this.buf, '&modifiable', 0)
		})
	enddef

	def OnRemove(visual: bool)
		const lnum = line('.')
		const e = &filetype
		var min: number
		var max: number
		if visual
			min = getpos("'<")[1]
			max = getpos("'>")[1]
		else
			min = line('.')
			if exists('v:count') && v:count != 0
				max = min + v:count - 1
			else
				max = min
			endif
		endif

		if max > line('$')
			max = line('$')
		endif
	
		for nb in range(min, max)
			const node = this.table_actions[nb - 1]
			node.SetDeleted()
		endfor

		this.RefreshKeepPos()
	enddef

	# work like OnRemove for visual clip
	def OnYank(visual: bool)
		const lnum = line('.')
		const e = &filetype
		var min: number
		var max: number
		if visual
			min = getpos("'<")[1]
			max = getpos("'>")[1]
		else
			min = line('.')
			if exists('v:count') && v:count != 0
				max = min + v:count - 1
			else
				max = min
			endif
		endif

		if max > line('$')
			max = line('$')
		endif
		this.clipboard = []
		for nb in range(min, max)
			const node = this.table_actions[nb - 1]
			add(this.clipboard, node)
		endfor
		echo 'Yanked ' .. len(this.clipboard) .. ' items to clipboard.'
	enddef
			
	def OnPaste()
		if len(this.clipboard) == 0
			throw "Clipboard is empty."
		endif

		const current_lnum = line('.')
		var test_node: Node = this.table_actions[current_lnum - 1]
		var node_parent: Node
		if test_node->instanceof(DirectoryNode) == true
			node_parent = test_node
		else
			node_parent = test_node.GetParent()
		endif
		if node_parent->instanceof(SpecialNode)
			throw "Cannot paste here."
		endif

		for node in this.clipboard
			var new_node: Node
			var try_i = 1
			while try_i != 500
				try
					var new_name = node.name .. "_copy_" .. try_i
					if node->instanceof(DirectoryNode) == true
						new_node = DirectoryNode.new(node.parent, new_name, NodeType.Copy, node_parent.depth + 1)
					else
						new_node = FileNode.new(node.parent, new_name, NodeType.Copy, node_parent.depth + 1)
					endif
					node_parent.AddChild(new_node)
					new_node.MarkAsCopied(node.GetFullPath())
				catch
					try_i += 1
					continue
				endtry
				break
			endwhile
		endfor

		this.RefreshKeepPos()
		echo 'Pasted ' .. len(this.clipboard) .. ' items from clipboard.'
	enddef

	def OnClick(type: Toggle.Type)
		const node = this.table_actions[line('.') - 1]
		node.Action(type)
	enddef

endclass


##########################################
# Utility Functions
##########################################

def CreatePopup(initial_text: string, title: string): Input
	const icon = Utils.GetIcons(initial_text)
	var input = Input.new(icon .. ' ', {
		minwidth: 24,
		title: title,
		line: "cursor-3",
		col: "cursor+1",
		moved: [0, 2000]
	})
	input.SetInput(initial_text)
	input.AddCbChanged((key, line) => {
		const ic = Utils.GetIcons(line) # preload icon cache
		input.SetPrompt(ic .. ' ')
	})
	win_execute(input.popup, 'silent! call(g:supratree_icons_glyph_palette_func, [])')
	return input
enddef
