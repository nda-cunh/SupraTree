vim9script

import autoload './Toggle.vim' as Toggle
import autoload './SpecialNode.vim' as ASpecialNode
import autoload './DirectoryNode.vim' as ADirectoryNode
import autoload './NodeType.vim' as NodeType
import autoload './Input.vim' as AInput
import autoload './Utils.vim' as Utils
import autoload 'SupraTree/SupraTreeBuffer.vim' as NSupraTreeBuffer

type DirectoryNode = ADirectoryNode.DirectoryNode
type SpecialNode = ASpecialNode.SpecialNode
type Input = AInput.Input

export class SpecialNodeCD extends SpecialNode
	def new()
	enddef

	def Action(type: Toggle.Type)
		const tree: any = g:supra_tree
		const icon = ''
		var input = Input.new(icon .. ' ', {
			minwidth: 24,
			title: 'Change Directory',
			line: "cursor-3",
			col: "cursor+1",
			moved: [0, 2000]
		})
		input.SetInput(tree.general_node.GetFullPath())
		input.AddCbChanged((key, line) => {
			const ic = icon # preload icon cache
			input.SetPrompt(ic .. ' ')
		})
		input.AddCbEnter((line) => {
			var new_path = line
			tree.ChangeDirectory(new_path)
		})
		win_execute(input.popup, 'silent! call(g:supratree_icons_glyph_palette_func, [])')
	enddef
endclass
