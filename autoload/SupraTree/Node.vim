vim9script

import autoload './NodeType.vim' as NodeType
import autoload './Toggle.vim' as Toggle

export abstract class Node
	public var parent: string 
	public var name: string
	public var type: NodeType.NodeType
	public var depth: number
	public var node_parent: any 
	public var is_last: bool = false

	def AddChild(child: Node)
		# Do nothing here, only DirectoryNode will implement this method
	enddef

	def GetParent(): Node 
		return this.node_parent
	enddef

	def SetDeleted()
		echom "Remove file: " .. this.parent .. '/' .. this.name
		if this.type == NodeType.SimpleFile
			this.type = NodeType.Deleted
		elseif this.type == NodeType.Deleted
			this.type = NodeType.SimpleFile
		endif
	enddef

	def AddPropAttribute()
		var singleton: any = g:supra_tree 
		if this.type == NodeType.Deleted
			prop_add(singleton.lnum - 1, 1, {type: 'SupraTreeDeletedProp', length: len(getline(singleton.lnum - 1)), bufnr: singleton.buf})
		endif
	enddef

	def GetFullPath(): string
		return this.parent .. '/' .. this.name
	enddef

	abstract def Draw(is_end: bool = false)
	abstract def Action(type: Toggle.Type)
endclass
