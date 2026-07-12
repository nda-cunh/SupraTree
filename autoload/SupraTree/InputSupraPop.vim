vim9script

# SupraPopup backend. This file is only sourced when SupraPopup is installed,
# see Input.Create(): the imports below stay unresolved otherwise.

import autoload 'SupraPop/Input.vim' as ASupraPop
import autoload 'SupraPop/Base.vim' as ASupraPopBase
import autoload './InputBase.vim' as AInputBase

type IInput = AInputBase.IInput
type SupraPopInput = ASupraPop.Input

export class InputSupraPop implements IInput
	var input: SupraPopInput

	var cb_enter: list<func(string)> = []
	var cb_changed: list<func(string, string)> = []
	var cb_quit: list<func()> = []
	var cb_keys: dict<list<func(string)>> = {}

	def new(prompt: string, ops: dict<any>)
		var options = copy(ops)
		# SupraPopup exposes the popup minimal width as `width`
		if options->has_key('minwidth')
			options.width = remove(options, 'minwidth')
		endif
		options.prompt = prompt

		this.input = SupraPopInput.new(options)

		this.input.AddEventInputEnter((_: any) => {
			const line = this.input.GetInput()
			for Func in this.cb_enter
				Func(line)
			endfor
		})
		this.input.AddEventInputChanged((_: any, key: string, line: string) => {
			for Func in this.cb_changed
				Func(key, line)
			endfor
		})
		this.input.AddEventClose((_: any) => {
			for Func in this.cb_quit
				Func()
			endfor
		})
		# Runs before the editing keys, so a bound key always wins
		this.input.AddEventKeyPressedFocus((_: any, key: string): number => {
			if !this.cb_keys->has_key(key)
				return ASupraPopBase.CONTINUE
			endif
			const line = this.input.GetInput()
			for Func in this.cb_keys[key]
				Func(line)
			endfor
			return ASupraPopBase.BLOCK
		})
	enddef

	def AddCbEnter(Func: func(string))
		this.cb_enter->add(Func)
	enddef

	def AddCbChanged(Func: func(string, string))
		this.cb_changed->add(Func)
	enddef

	def AddCbQuit(Func: func())
		this.cb_quit->add(Func)
	enddef

	def AddCbKey(key: string, Func: func(string))
		if !this.cb_keys->has_key(key)
			this.cb_keys[key] = []
		endif
		this.cb_keys[key]->add(Func)
	enddef

	def SetInput(text: string)
		this.input.SetInput(text)
	enddef

	def GetInput(): string
		return this.input.GetInput()
	enddef

	def SetPrompt(new_prompt: string)
		this.input.SetPrompt(new_prompt)
	enddef

	def GetPrompt(): string
		return this.input.prompt
	enddef

	def Close()
		this.input.Close()
	enddef

	def GetWid(): number
		return this.input.GetWid()
	enddef
endclass

export def Create(prompt: string, ops: dict<any>): IInput
	return InputSupraPop.new(prompt, ops)
enddef
