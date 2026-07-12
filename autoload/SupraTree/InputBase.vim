vim9script

# Common interface for the input popups used by SupraTree.
# Two backends implement it: Input.vim (built-in fallback) and
# InputSupraPop.vim (delegates to the SupraPopup plugin when installed).

export interface IInput
	def SetInput(text: string)
	def GetInput(): string
	def SetPrompt(new_prompt: string)
	def GetPrompt(): string
	def AddCbEnter(Func: func(string))
	def AddCbChanged(Func: func(string, string))
	def AddCbQuit(Func: func())
	# Binds an extra key inside the popup; Func gets the current input line.
	def AddCbKey(key: string, Func: func(string))
	def Close()
	def GetWid(): number
endinterface
