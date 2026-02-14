vim9script

import autoload './Toggle.vim' as Toggle
import autoload './SpecialNode.vim' as ASpecialNode
import autoload './DirectoryNode.vim' as ADirectoryNode
import autoload './NodeType.vim' as NodeType

type DirectoryNode = ADirectoryNode.DirectoryNode
type SpecialNode = ASpecialNode.SpecialNode

export class SpecialNodePrev extends SpecialNode
	def new()
		
	enddef

	def Action(type: Toggle.Type)
		const singleton: any = g:supra_tree
		var path = singleton.general_node.GetFullPath()
		
		if path == '' || path == '/' || path == '\\'
			return
		endif

		var clean_path = substitute(path, '[/\\]$', '', '')
    
		var parent_path = simplify(fnamemodify(clean_path, ':h'))

		var new_node = DirectoryNode.new(parent_path, '', NodeType.SimpleFile, -1)
		# singleton
		var last_node = singleton.general_node 
		# last_node.name = fnamemodify(clean_path, ':t')
		singleton.general_node = new_node
		singleton.general_node.OpenInsertNode(last_node)
		singleton.RefreshFileSystem()
	enddef
endclass
