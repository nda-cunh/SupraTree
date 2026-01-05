vim9script

import autoload 'SupraTree/Actions.vim' as MActions
import autoload 'SupraTree/Toggle.vim' as Toggle
import autoload 'SupraTree/Input.vim' as Popup 

type Input = Popup.Input
type Actions = MActions.Actions

def TestIfIconsWork(): bool
	try
		call(g:supratree_icons_glyph_func, ['test.txt'])
		return true
	catch
		return false
	endtry
enddef

export class SupraTreeBuffer
	var buf: number # Buffer number
	var open_folders = [] # Contains the list of open folders
	var lnum: number # Current line number to write
	var table_prefix: list<string> # Contains the full path for each line
	var actions: Actions # Contains all the actions to be done
	var icon_work: bool # Test if the icon function work

	def GetBuf(): number
		return this.buf
	enddef


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
		setbufvar(buf, '&wincolor', 'NormalDark')
		setbufvar(buf, '&filetype', 'SupraTree')


		map <buffer> <cr>			<scriptcmd>b:supra_tree.OnClick(Toggle.Enter)<cr>
		map <buffer> <c-t>			<scriptcmd>b:supra_tree.OnClick(Toggle.NewTab)<cr>
		map <buffer> <c-h>			<scriptcmd>b:supra_tree.OnClick(Toggle.Split)<cr>
		map <buffer> <c-v>			<scriptcmd>b:supra_tree.OnClick(Toggle.VSplit)<cr>
		map <buffer> <2-LeftMouse>	<scriptcmd>b:supra_tree.OnClick(Toggle.Enter)<cr>
		map <buffer> <3-LeftMouse>	<scriptcmd>b:supra_tree.OnClick(Toggle.Enter)<cr>
		map <buffer> <4-LeftMouse>	<scriptcmd>b:supra_tree.OnClick(Toggle.Enter)<cr>
		map <buffer> <c-s>			<scriptcmd>b:supra_tree.SaveActions()<cr>
		map <buffer> r 				<scriptcmd>b:supra_tree.Refresh()<cr>
		map <buffer> dd				<scriptcmd>b:supra_tree.OnRemove()<cr>
		map <buffer> i				<scriptcmd>b:supra_tree.OnRename()<cr>
		map <buffer> O 				<scriptcmd>b:supra_tree.OnNewFile(true)<cr>
		map <buffer> o 				<scriptcmd>b:supra_tree.OnNewFile(false)<cr>

		au BufWriteCmd <buffer>		if exists('b:supra_tree')	| b:supra_tree.SaveActions() | endif | quit
		au BufWipeout <buffer>		SupraTreeBuffer.Quit()	

		this.actions = Actions.new()
		# Add a match for deleted files
		this.buf = buf
		this.Refresh()
	enddef

	static def Quit()
		echoerr "SupraTree: Remove instance ..."
		silent! unlet g:supratree_isopen
		silent! unlet t:supratree_isopen
		silent! unlet g:supra_tree
		silent! unlet b:supra_tree
	enddef


	def SaveActions() 
		# Save the actions to a file or variable
		this.actions.MakeActions()
		# echom "SupraTree: Actions saved."
	enddef


	def CreatePopup(initial_text: string, title: string): Input
		const icon = this.GetIcons(initial_text)
		var input = Input.new(icon .. ' ', {
			minwidth: 24,
			title: title,
			line: "cursor-3",
			col: "cursor+1",
			moved: 'WORD'
		})
		input.SetInput(initial_text)
		input.AddCbChanged((key, line) => {
			const ic = this.GetIcons(line) # preload icon cache
			input.SetPrompt(ic .. ' ')
		})
		win_execute(input.popup, 'silent! call(g:supratree_icons_glyph_palette_func, [])')
		return input
	enddef

	def OnNewFile(is_up: bool)
		const lnum = line('.')
		const full_path = this.table_prefix[lnum - 1]
		setbufvar(this.buf, '&modifiable', 1)
		append(lnum, '')
		cursor(lnum + 1, 1)

		var input = this.CreatePopup('', '󰑕 New File')
		input.AddCbChanged((key, line) => {
			setbufline(this.buf, lnum + 1, '  ' .. input.GetPrompt() .. line)
		})
		input.AddCbQuit(() => {
			this.RefreshKeepPos()
		})
		input.AddCbEnter((new_name) => {
			# create the new file with the given name
			if len(new_name) == 0
				return
			endif
			echom "Creating new file: " .. new_name
			var new_path: string
			if isdirectory(full_path)
				new_path = full_path .. '/' .. new_name
			else
				new_path = fnamemodify(full_path, ':h') .. '/' .. new_name
			endif
			# if the file already exist, do nothing and print an error
			if filereadable(new_path) || isdirectory(new_path)
				echom "Error: File or directory already exists."
				return
			endif

			# test if it's a directory creation or a file creation 
			if new_name[-1] == '/'
				mkdir(new_path, 'p')
				# open the directory containing the new folder
				var parent_dir = fnamemodify(new_path[0 : -2], ':h')
				if index(this.open_folders, parent_dir) == -1
					this.open_folders->add(parent_dir)
				endif
			else
				# create the new file
				call writefile([], new_path)
				# open the directory containing the new file
				var parent_dir = fnamemodify(new_path, ':h')
				if index(this.open_folders, parent_dir) == -1
					this.open_folders->add(parent_dir)
				endif
			endif


			this.RefreshKeepPos()
			setbufvar(this.buf, '&modifiable', 0)
			if new_name[-1] == '/'
				this.GoToPath(new_path[0 : -2])
			else
				this.GoToPath(new_path)
			endif
			input.Close()
		})
	enddef

	def OnRename()
		var line = line('.')
		const full_path = this.table_prefix[line - 1]
		var input = this.CreatePopup(fnamemodify(full_path, ':t'), '󰑕 Rename')
		input.AddCbEnter((new_name) => {
			if len(new_name) == 0 || new_name == fnamemodify(full_path, ':t')
				return
			endif
			const new_path = fnamemodify(full_path, ':h') .. '/' .. new_name
			rename(full_path, new_path)
			this.RefreshKeepPos()
			this.GoToPath(new_path)
			input.Close()
		})
	enddef

	def OnRemove()
		const lnum = line('.')
		this.actions.DeleteAction(lnum, this.table_prefix[lnum - 1])
		this.RefreshKeepPos()
	enddef

	def OnClick(type: Toggle.Type)
		const lnum = line('.')
		const full_path = this.table_prefix[lnum - 1]
		if isdirectory(full_path) && type == Toggle.Enter
			if index(this.open_folders, full_path) != -1
				# close folder
				const idx = index(this.open_folders, full_path)
				this.open_folders->remove(idx)
			else
				# open folder
				this.open_folders->add(full_path)
			endif
		else
			wincmd p
			# check if the buffer actual is modified
			const buf = bufnr('%')
			if type == Toggle.Enter
				if getbufvar(buf, '&modified') == true
					execute 'split ' .. fnameescape(full_path)
				else
					execute 'edit ' .. fnameescape(full_path)
				endif
			elseif type == Toggle.Split
				execute 'split ' .. fnameescape(full_path)
			elseif type == Toggle.VSplit
				execute 'vsplit ' .. fnameescape(full_path)
			elseif type == Toggle.NewTab
				execute 'tabnew ' .. fnameescape(full_path)
			endif
			return
		endif
		this.RefreshKeepPos()
	enddef

	def GoToPath(path: string)
		const total_lines = line('$')
		var lnum = 1
		while lnum <= total_lines
			const line_path = this.table_prefix[lnum - 1]
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
		const pwd = getcwd()
		this.Draw(pwd)
		this.RecursiveDraw(pwd, 0)
		# test if the function exist
		if exists('g:supratree_icons_glyph_palette_func')
			silent! call(g:supratree_icons_glyph_palette_func, [])
		endif
		setbufvar(this.buf, '&modifiable', 0)
		setbufvar(this.buf, '&modified', 0)
	enddef


	# draw the tree header
	def Draw(pwd: string)
		this.icon_work = TestIfIconsWork()
		this.table_prefix = ['', '', '', '', '']
		# setbufline(this.buf, 1, '     󰥨 SupraTree')
		# draw the default folder path change $HOME to ~
		var path = substitute(pwd, '^' .. $HOME, '~', '')
		this.lnum = 1
		var name = fnamemodify(pwd, ':t')
		setbufline(this.buf, 1, path .. '/')
		this.AddLine(path .. '/', '@SupraTree@ChangePath')
		this.AddLine('', '@SupraTree@null')
		this.AddLine(this.GetIcons('', 2) .. ' ../', '@SupraTree@prev')
	enddef



	def AddLine(line: string, path: string)
		setbufline(this.buf, this.lnum, line)
		this.table_prefix[this.lnum - 1] = path
		this.lnum += 1
	enddef


	###################################
	# Get the icon for a file
	###################################

	def GetIcons(path: string, is_directory: number = 0): string
		if this.icon_work == false
			return ''
		endif
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



	######################################################
	## Read all files and folders and return an array
	######################################################
	def GetCustomFileList(path: string): list<string>
		var dirs: list<string> = []
		var files: list<string> = []
		var filter_pattern: string 

		# Create the combined filter pattern for the best performance
		if g:supratree_show_hidden == false
			filter_pattern = '\%(^\.'
		else
			filter_pattern = '\%('
		endif
		if exists('g:supratree_filter_files') && len(g:supratree_filter_files) > 0
			if filter_pattern == '\%(^\.'
				filter_pattern ..= '\|'
			endif
			filter_pattern = filter_pattern .. g:supratree_filter_files
				->mapnew((_, val) => glob2regpat(val))
				->join('\|')
		endif
		filter_pattern ..= '\)'

		const entries = readdirex(path, (n) => (filter_pattern == '' || n.name !~ filter_pattern), {sort: 'none'})

		for entrie in entries
			if entrie.type == 'dir'
				dirs->add(entrie.name)
			else
				files->add(entrie.name)
			endif
		endfor
		return sort(dirs, 'i') + sort(files, 'i')
	enddef

	def GetPrefixLine(depth: number): string
		if depth < 2
			return repeat('  ', depth)
		endif 
		return '  ' .. repeat('│ ', float2nr(depth / 2))
	enddef

	########################################################################
	# draw the path recursively with a depth parameter
	# but open the folder is the path is in the array 'open_folders'
	########################################################################
	def RecursiveDraw(path: string, depth: number)
		const file_list = this.GetCustomFileList(path)
		const len_list = len(file_list)

		var index = 0
		while index < len_list
			const name = file_list[index]
			const full_path = path .. '/' .. name
			# const prefix = repeat(' ', depth)
			const prefix = this.GetPrefixLine(depth)
			const is_deleted = this.actions.FileIsDeleted(full_path)


			if isdirectory(full_path)
				if index(this.open_folders, full_path) != -1
					this.AddLine(prefix .. ' ' .. this.GetIcons('', 2) .. ' ' .. name, full_path)
					if is_deleted == true
						call prop_add(this.lnum - 1, 1, {type: 'SupraTreeDeletedProp', length: len(getline(this.lnum - 1)), bufnr: this.buf})
					endif
					this.RecursiveDraw(full_path, depth + 1)
				else
					this.AddLine(prefix .. ' ' .. this.GetIcons('', 1) .. ' ' .. name, full_path)
					if is_deleted == true
						call prop_add(this.lnum - 1, 1, {type: 'SupraTreeDeletedProp', length: len(getline(this.lnum - 1)), bufnr: this.buf})
					endif
				endif
			else
				var icon: string
				if is_deleted == true
					icon = this.GetIcons('', 3)
				else
					icon = this.GetIcons(full_path)
				endif
				if depth == 0
					if index == len_list - 1
						this.AddLine(prefix .. '  ' .. icon .. ' ' .. name, full_path)
					else
						this.AddLine(prefix .. '  ' .. icon .. ' ' .. name, full_path)
					endif
				else
					if index == len_list - 1
						this.AddLine(prefix .. '╰ ' .. icon .. ' ' .. name, full_path)
					else
						this.AddLine(prefix .. '│ ' .. icon .. ' ' .. name, full_path)
					endif
				endif


				if is_deleted == true
					call prop_add(this.lnum - 1, 1, {type: 'SupraTreeDeletedProp', length: len(getline(this.lnum - 1)), bufnr: this.buf})
				endif
			endif
			index += 1
		endwhile
	enddef
endclass
