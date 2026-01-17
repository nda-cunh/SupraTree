vim9script

import autoload './Popup.vim' as Popup
import autoload './Modified.vim' as AModified

type Modified = AModified.Modified

export class PopupSave extends Popup.Popup
	var Cb_cancel: func()
	var Cb_yes: func()

	def new(modified: Modified)
		var options = {
			filter: this.FilterSave,
		}
		super.Init(options)

		const width = float2nr(&columns * 0.6)
		const nb_minus: number = (width / 2)
		const nb_space = repeat(' ', (nb_minus))
		var lines = []
		extend(lines, modified.GetStringList())
		add(lines, nb_space .. ' [(Y)es] [(N)o] [(C)ancel] ' .. nb_space)
		super.SetText(lines)
	enddef

	def OnCancel(Cb: func())
		this.Cb_cancel = Cb
	enddef

	def OnYes(Cb: func())
		this.Cb_yes = Cb
	enddef

	def FilterSave(wid: number, key: string): number
		if key ==? 'q' || key ==? 'n' || key == "\<Esc>"
			this.Close()
		elseif key ==? 'c'
			if this.Cb_cancel != null
				this.Cb_cancel()
			endif
			this.Close()
		elseif key ==? 'y'
			if this.Cb_yes != null
				this.Cb_yes()
			endif
			this.Close()
		endif
		return 1
	enddef
endclass
