vim9script

import autoload './Node.vim' as Node
import autoload './NodeType.vim' as NodeType
import autoload './Toggle.vim' as Toggle
import autoload './Utils.vim' as Utils 

export class FileNode extends Node.Node
	def new(this.parent, this.name, this.type, this.depth)
	enddef

	def GetKlassType(): string
		return 'File'
	enddef

	def Draw(is_end: bool = false)
		const singleton: any = g:supra_tree 
		const prefix = Utils.GetPrefixLine(this.depth)
		const full_path = this.parent .. '/' .. this.name
		var icon: string
		if this.type == NodeType.Deleted
			icon = Utils.GetIcons('', 3)
		else
			icon = Utils.GetIcons(full_path)
		endif

		if this.depth == 0
			singleton.NewAddLine(prefix .. '  ' .. icon .. ' ' .. this.GetSuffix(), this)
		else
			const line = '' .. prefix .. (this.is_last ? '╰ ' : '│ ') .. icon .. ' ' .. this.GetSuffix()
			singleton.NewAddLine(line, this)
		endif

		super.AddPropAttribute()
	enddef

	def Action(type: Toggle.Type)
		wincmd p
		const buf = bufnr('%')
		const full_path = this.GetFullPath()
		if type == Toggle.Enter
			if getbufvar(buf, '&modified') == true
				execute 'split ' .. full_path
			else
				execute 'edit ' .. full_path
			endif
		elseif type == Toggle.Split
			execute 'split ' .. full_path
		elseif type == Toggle.VSplit
			execute 'vsplit ' .. full_path
		elseif type == Toggle.NewTab
			execute 'tabnew ' .. full_path
		endif
	enddef
endclass
