vim9script

import autoload './Toggle.vim' as Toggle
import autoload './SpecialNode.vim' as ASpecialNode
import autoload './DirectoryNode.vim' as ADirectoryNode

type DirectoryNode = ADirectoryNode.DirectoryNode
type SpecialNode = ASpecialNode.SpecialNode

export class SpecialNodePrev extends SpecialNode
	var prev: DirectoryNode

	def new(this.prev)
		
	enddef

	# get the full path of the previous directory
	# get the path before it ex:
	# /Users/username/project/folder
	# /Users/username/project
	# Create a new node with /Users/username/project
	# and this.prev need point to that new node
	# Ignore type parameter
	def Action(type: Toggle.Type)
		var full_path = this.prev.GetFullPath()
		var parent_path = fnamemodify(full_path, ':h')
		var new_dir = DirectoryNode.new(this.prev.node_parent, fnamemodify(parent_path, ':t'), 'dir', this.prev.depth)
		this.prev = new_dir

	enddef
endclass
