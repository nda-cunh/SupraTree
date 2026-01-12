vim9script

import autoload './Node.vim' as NodeModule
import autoload './DirectoryNode.vim' as ADirectoryNode
import autoload './FileNode.vim' as AFileNode
import autoload './NodeType.vim' as NodeType

type Node = NodeModule.Node
type DirectoryNode = ADirectoryNode.DirectoryNode
type FileNode = AFileNode.FileNode

export def GetCustomNodes(path: string, depth: number = 0): list<Node>
	var dir_nodes: list<Node> = []
	var file_nodes: list<Node> = []

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

	# readdirex est génial car il donne déjà .name et .type
	const entries = readdirex(path, (n) => (filter_pattern == '' || n.name !~ filter_pattern), {sort: 'none'})

	for entry in entries
		if entry.type == 'dir'
			# echom "Found directory: " .. path .. '/' .. entry.name .. 'depth: ' .. depth
			dir_nodes->add(DirectoryNode.new(path, entry.name, NodeType.SimpleFile, depth))
		else
			file_nodes->add(FileNode.new(path, entry.name, NodeType.SimpleFile, depth))
		endif
	endfor

	# On trie les listes d'objets par la propriété 'name'
	sort(dir_nodes, (a: Node, b: Node): number => a.name >? b.name ? 1 : -1)
	sort(file_nodes, (a: Node, b: Node): number => a.name >? b.name ? 1 : -1)

	return dir_nodes + file_nodes
enddef
