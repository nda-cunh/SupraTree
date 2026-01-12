vim9script

import autoload './Node.vim' as Node
import autoload './Toggle.vim' as Toggle

export class SpecialNode extends Node.Node
	var action: string

	def new(this.action)
	enddef

	def Draw(is_end: bool = false)
	enddef
	
	def Action(type: Toggle.Type)
		echom "SpecialNode Action: " .. this.action
	enddef
endclass

