vim9script

import autoload './NodeType.vim' as NodeType
import autoload './Toggle.vim' as Toggle
import autoload './Utils.vim' as Utils
import autoload './Modified.vim' as AModified

type Modified = AModified.Modified

export abstract class Node
	public var parent: string 
	public var name: string
	public var type: NodeType.NodeType
	public var depth: number
	public var node_parent: Node 
	public var is_last: bool = false
	var name_before_rename: string

	# this function rename the node by the new name and set the
	# type to *Renamed* if the type was *SimpleFile*
	# if the Renamed file is renamed by the original name set the type back to *SimpleFile*
	def Rename(new_name: string)
		if this.type == NodeType.SimpleFile
			if new_name == this.name
				throw "You can't rename to the same name."
			endif
			this.type = NodeType.Renamed
			this.name_before_rename = this.name
			this.name = new_name
		elseif this.type == NodeType.Renamed
			if new_name == this.name_before_rename
				this.type = NodeType.SimpleFile
				this.name = this.name_before_rename
			else
				this.name = new_name
			endif
		else
			throw "Type " .. this.type .. "not supported to rename."
		endif
	enddef

	def GetAllSaveActions(modified: Modified)
		const full_path = this.parent .. '/' .. this.name
		if this.type == NodeType.Renamed
			if this.GetKlassType() == 'Dir'
				modified.Append_RenameDirectory(this.parent .. '/' .. this.name_before_rename, full_path)
			else
				modified.Append_RenameFile(this.parent .. '/' .. this.name_before_rename, full_path)
			endif
		elseif this.type == NodeType.Deleted
			if this.GetKlassType() == 'Dir'
				modified.Append_DeleteDirectory(full_path)
			else
				modified.Append_DeleteFile(full_path)
			endif
		elseif this.type == NodeType.NewFile
			if this.GetKlassType() == 'Dir'
				modified.Append_NewDirectory(full_path)
			else
				modified.Append_NewFile(full_path)
			endif
		endif
	enddef

	def AddChild(child: Node)
		# Do nothing here, only DirectoryNode will implement this method
	enddef

	def GetKlassType(): string
		return 'Node'
	enddef

	def GetPrefixLine(): string
		return Utils.GetPrefixLine(this.depth)
	enddef

	def RemoveChild(child: Node)
		# Do nothing here, only DirectoryNode will implement this method
	enddef

	def GetParent(): Node 
		return this.node_parent
	enddef

	def SetDeleted()
		if this.type == NodeType.SimpleFile
			this.type = NodeType.Deleted
		elseif this.type == NodeType.Deleted
			this.type = NodeType.SimpleFile
		elseif this.type == NodeType.Renamed
			this.Rename(this.name_before_rename)
			this.type = NodeType.Deleted
		elseif this.type == NodeType.NewFile
			this.node_parent.RemoveChild(this)
		else
			throw "Type " .. this.type .. "not supported to delete."
		endif
	enddef

	# this function return the name with suffix according to the type for drawing purpose
	def GetSuffix(): string
		if this.type == NodeType.NewFile
			return this.name .. ' (New)'
		elseif this.type == NodeType.Deleted
			return this.name .. ' (Deleted)'
		elseif this.type == NodeType.Renamed
			return this.name .. ' (Renamed)'
		else 
			return this.name
		endif
	enddef

	def AddPropAttribute()
		var singleton: any = g:supra_tree 
		if this.type == NodeType.Deleted
			prop_add(singleton.lnum - 1, 1, {type: 'SupraTreeDeletedProp', length: len(getline(singleton.lnum - 1)), bufnr: singleton.buf})
		elseif this.type == NodeType.NewFile
			prop_add(singleton.lnum - 1, 1, {type: 'SupraTreeNewFileProp', length: len(getline(singleton.lnum - 1)), bufnr: singleton.buf})
		elseif this.type == NodeType.Renamed
			prop_add(singleton.lnum - 1, 1, {type: 'SupraTreeRenamedProp', length: len(getline(singleton.lnum - 1)), bufnr: singleton.buf})
		endif
	enddef

	def GetFullPath(): string
		return this.parent .. '/' .. this.name
	enddef

	abstract def Draw(is_end: bool = false)
	abstract def Action(type: Toggle.Type)
endclass
