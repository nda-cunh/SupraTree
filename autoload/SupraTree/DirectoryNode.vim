vim9script

import autoload './Node.vim' as ANode
import autoload './NodeType.vim' as NodeType
import autoload './Toggle.vim' as Toggle
import autoload './Utils.vim' as Utils
import autoload './ReadAllNodes.vim' as ReadAllNodes
import autoload './Modified.vim' as AModified

type Node = ANode.Node
type Modified = AModified.Modified

export class DirectoryNode extends Node
	var is_open: bool
	var children: list<Node>

	def GetKlassType(): string
		return 'Dir'
	enddef

	def new(this.parent, this.name, this.type, this.depth)
		this.is_open = false
		this.children = []
	enddef

	def GetAllSaveActions(modified: Modified)
		super.GetAllSaveActions(modified)
		for child in this.children
			child.GetAllSaveActions(modified)
		endfor
	enddef

	def AddChild(new_child: Node)
		this.Open()

		if !empty(this.children)
			this.children[-1].is_last = false
		endif

		var is_dir: bool
		if new_child.GetKlassType() == 'Dir'
			is_dir = true
		else
			is_dir = false
		endif

		new_child.node_parent = this
		var inserted = false
		for i in range(len(this.children))
			const it = this.children[i]
			if new_child.name == it.name
				echoerr "Error: A node with the name '" .. new_child.name .. "' already exists in this directory."
				return
			endif
			if is_dir == false
				if it.GetKlassType() != 'Dir' && new_child.name < it.name
					this.children->insert(new_child, i)
					inserted = true
					break
				endif
			else
				if it.GetKlassType() == 'File'
					this.children->insert(new_child, i)
					inserted = true
					break
				endif
				if new_child.name < it.name
					this.children->insert(new_child, i)
					inserted = true
					break
				endif
			endif
		endfor

		if !inserted
			this.children->add(new_child)
		endif

		if !empty(this.children)
			this.children[-1].is_last = true
		endif
	enddef

	def Draw(is_end: bool = false)
		const singleton: any = g:supra_tree
		const prefix = Utils.GetPrefixLine(this.depth)
		if this.is_open
			singleton.NewAddLine(prefix .. ' ' .. Utils.GetIcons('', 2) .. ' ' .. this.GetSuffix(), this)
		else
			singleton.NewAddLine(prefix .. ' ' .. Utils.GetIcons('', 1) .. ' ' .. this.GetSuffix(), this)
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

	def RemoveChild(child_to_remove: Node)
		for i in range(len(this.children))
			const it = this.children[i]
			if it == child_to_remove
				this.children->remove(i)
				break
			endif
		endfor
		if !empty(this.children)
			this.children[-1].is_last = true
		endif
	enddef

	def Open()
		if this.is_open == true
			return
		endif
		this.is_open = true
		var singleton: any = g:supra_tree
		var full_path: string
		if this.type == NodeType.Renamed
			full_path = this.parent .. '/' .. this.name_before_rename .. '/'
		else
			full_path = this.parent .. '/' .. this.name .. '/'
		endif
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
		if this.type == NodeType.Deleted
			throw "Error: Cannot open a deleted directory."
		elseif this.type == NodeType.NewFile
			throw "Error: Cannot open a new directory."
		endif
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

