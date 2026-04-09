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
	public var children: list<Node>
	var is_open: bool

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

    def Load()
        if this.is_open | return | endif

        this.is_open = true
        var full_path = ""
        if this.type == NodeType.Renamed
            full_path = simplify(this.parent .. '/' .. this.name_before_rename .. '/')
        else
            full_path = simplify(this.parent .. '/' .. this.name .. '/')
        endif

        var child_nodes = ReadAllNodes.GetCustomNodes(full_path, this.depth + 1)
        if !empty(child_nodes)
            child_nodes[-1].is_last = true
        endif

        this.children = child_nodes
        for child in this.children
            child.node_parent = this
        endfor
    enddef

    def OpenPath(target_path: string)
        this.Load()

        var target = simplify(target_path)

		for child in this.children
			var child_path = simplify(child.GetFullPath())
			var len_child = len(child_path)

			if stridx(target, child_path) == 0
				if len(target) == len_child || target[len_child] == '/' || target[len_child] == '\'
					if child->instanceof(DirectoryNode)
						var dir_child = <DirectoryNode>child
						dir_child.OpenPath(target)
					endif
					break
				endif
			endif
		endfor
    enddef

	def IsOpen(): bool
		return this.is_open
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

	def UpdateDepth(new_depth: number)
		this.depth = new_depth
		if this->instanceof(DirectoryNode)
			var dir = <DirectoryNode>this
			for child in dir.children
				child.UpdateDepth(new_depth + 1)
			endfor
		endif
	enddef

	# Like Open but insert this Node
	def OpenInsertNode(node: Node)
		this.is_open = true

		var current_name = (this.type == NodeType.Renamed) ? this.name_before_rename : this.name
		var full_path = simplify(this.parent .. '/' .. current_name .. '/')

		var disk_nodes = ReadAllNodes.GetCustomNodes(full_path, this.depth + 1)

		var final_children: list<Node> = []
		var target_path = simplify(node.GetFullPath())
		target_path = substitute(target_path, '[/\\]$', '', '')

		for disk_node in disk_nodes
			var disk_path = simplify(disk_node.GetFullPath())

			if disk_path == target_path
				node.node_parent = this
				final_children->add(node)
				node.name = simplify(disk_node.name)
				node.parent = simplify(this.GetFullPath())
				node.UpdateDepth(this.depth + 1)
			else
				disk_node.node_parent = this
				final_children->add(disk_node)
			endif
		endfor

		this.children = final_children

		for c in this.children | c.is_last = false | endfor
		if !empty(this.children)
			this.children[-1].is_last = true
		endif
	enddef

	def Open()
		this.Load()

		var lst_opened_dirs: list<string> = get(t:, 'OpenedDirs', [])
        for child in this.children
            if child->instanceof(DirectoryNode)
                var dirnode = <DirectoryNode>child
                if index(lst_opened_dirs, child.GetFullPath()) != -1
                    dirnode.Open()
                endif
            endif
        endfor
	enddef

	def Close()
		var singleton: any = g:supra_tree
		this.is_open = false
		this.children = []
		singleton.RefreshKeepPos()
	enddef

	def Action(type: Toggle.Type)
		# Only support open the directory when it's a simple file or deleted, otherwise throw
		if this.type != NodeType.Deleted && this.type != NodeType.SimpleFile
			if this.type == NodeType.NewFile
				throw "Save the new directory before opening."
			elseif this.type == NodeType.Renamed
				throw "Save the renamed directory before opening."
			elseif this.type == NodeType.Copy
				throw "Save the copied directory before opening."
			else
				throw "Type " .. this.type .. " not supported to open."
			endif
		endif
		if type == Toggle.NewTab
			execute 'tabnew ' .. this.GetFullPath()
		else
			if this.is_open == false
				this.Open()
				var singleton: any = g:supra_tree
				singleton.RefreshKeepPos()
			else
				this.Close()
			endif
		endif
	enddef
endclass
