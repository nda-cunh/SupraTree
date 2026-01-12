vim9script

import autoload './Node.vim' as Node
import autoload './NodeType.vim' as NodeType
import autoload './Toggle.vim' as Toggle
import autoload './Utils.vim' as Utils
import autoload './ReadAllNodes.vim' as ReadAllNodes

export class DirectoryNode extends Node.Node
	var is_open: bool
	var children: list<Node.Node>

	def new(this.parent, this.name, this.type, this.depth)
		this.is_open = false
		this.children = []
	enddef

	def AddChild(child: Node.Node)
		this.Open()
		this.children[-1].is_last = false
		this.children->add(child)
		this.children[-1].is_last = true
	enddef

	def Draw(is_end: bool = false)
		const singleton: any = g:supra_tree
		const prefix = Utils.GetPrefixLine(this.depth)
		if this.is_open
			singleton.NewAddLine(prefix .. ' ' .. Utils.GetIcons('', 2) .. ' ' .. this.name, this)
		else
			singleton.NewAddLine(prefix .. ' ' .. Utils.GetIcons('', 1) .. ' ' .. this.name, this)
		endif
		# Adding Properties
		super.AddPropAttribute()

		# Draws ALL children
		this.DrawChilds()
	enddef

	def DrawChilds()
		for child in this.children
			child.Draw()
		endfor
	enddef

	def Open()
		if this.is_open == true
			return
		endif
		this.is_open = true
		var singleton: any = g:supra_tree
		var full_path = this.parent .. '/' .. this.name .. '/'
		var child_nodes = ReadAllNodes.GetCustomNodes(full_path, this.depth + 1)
		if !empty(child_nodes) == true
			child_nodes[-1].is_last = true
		endif
		this.children = child_nodes
		for child in this.children
			child.node_parent = this
		endfor
		singleton.RefreshKeepPos()
	enddef

	def Close()
		var singleton: any = g:supra_tree
		this.is_open = false
		this.children = []
		singleton.RefreshKeepPos()
	enddef

	def Action(type: Toggle.Type)
		if type == Toggle.NewTab
			execute 'tabnew ' .. fnameescape(this.parent .. '/' .. this.name)
		else
			if this.is_open == false
				this.Open()
			else
				this.Close()
			endif
		endif
	enddef
endclass

