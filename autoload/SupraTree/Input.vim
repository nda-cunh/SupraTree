vim9script

export class Input
	var prompt: string
	var prompt_charlen: number
	var input_line: list<string>
	var cur_pos: number
	var mid: number
	var max_pos: number
	public var popup: number

	var cb_enter: list<func(string)> = []
	var cb_changed: list<func(string, string)> = []
	var cb_quit: list<func()> = []

	def new(prompt: string, ops: dict<any>)
		this.prompt = prompt
		this.prompt_charlen = len(prompt)
		var default_ops = {
			tabpage: -1,
			zindex: 300,
			drag: 0,
			wrap: 0,
			border: [1],
			borderhighlight: ['Normal', 'Normal', 'Normal', 'Normal'],
			borderchars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
			highlight: 'Normal',
			padding: [0, 1, 0, 1],
			mapping: 0,
			fixed: 1,
			filter: this.FilterInput,
			callback: (_, _) => {
				for Func in this.cb_quit
					Func()
				endfor
			},
		}

		extend(ops, default_ops, 'keep')
		this.popup = popup_create([], ops)
		this.input_line = []
		this.cur_pos = 0
		this.mid = 0
		this.max_pos = 0
		this.SetText([this.prompt .. ' '])
		this.ActualiseCursor(this.popup, 0)
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

	def FilterInput(wid: number, key: string): number
		var ascii_val = char2nr(key)
		var cur_pos = this.cur_pos
		var line = this.input_line
		var max_pos = this.max_pos

		var is_changed = false

		if (len(key) == 1 && ascii_val >= 32 && ascii_val <= 126)
				|| (ascii_val >= 19968 && ascii_val <= 205743) # chinese or more character support
			is_changed = true
			if cur_pos == len(line)
				line->add(key)
			else
				var pre = cur_pos - 1 >= 0 ? line[: cur_pos - 1] : []
				line = pre + [key] + line[cur_pos :]
			endif
			cur_pos += 1
		elseif key == "\<esc>"
			this.Close()
			return 0
		elseif key == "\<bs>"
			is_changed = true
			if cur_pos == 0
				return 1
			endif
			if cur_pos == len(line)
				line = line[: -2]
			else
				var before = cur_pos - 2 >= 0 ? line[: cur_pos - 2] : []
				line = before + line[cur_pos :]
			endif
			cur_pos = max([ 0, cur_pos - 1 ])
		elseif key == "\<Enter>" || key == "\<CR>"
			var copy_line = join(copy(this.input_line), '')
			for Func in this.cb_enter
				Func(copy_line)
			endfor
			return 1
		elseif key == "\<C-v>"
			echo "Paste from clipboard"
			var content = getreg('"')
			content = substitute(content, '\n', '', 'g') # Remove newlines
			if len(content) == 0
				return 0
			endif
			is_changed = true
			const len_content = len(content)
			if cur_pos == len(line)
				for i in content
					add(line, i)
				endfor
			else
				var pre = cur_pos - 1 >= 0 ? line[: cur_pos - 1] : []
				line = pre + [content] + line[cur_pos :]
			endif
			cur_pos += len_content
		elseif key == "\<Left>"
			cur_pos = max([ 0, cur_pos - 1 ])
		elseif key == "\<Right>"
			cur_pos = min([ max_pos, cur_pos + 1 ])
		elseif key == "\<End>"
			cur_pos = max_pos
		elseif key == "\<Home>"
			cur_pos = 0
		elseif key ==? "\<Del>"
			is_changed = true
			if cur_pos == max_pos
				return 1
			endif
			if cur_pos == 0
				line = line[1 : ]
			else
				var before = cur_pos - 1 >= 0 ? line[: cur_pos - 1] : []
				line = before + line[cur_pos + 1 :]
			endif
			max_pos -= 1
		elseif key ==? "\<LeftMouse>" || key ==? "\<2-LeftMouse>"
			var pos = getmousepos()
			if pos.winid != wid
				return 0
			endif
			var promptchar_len = this.prompt_charlen
			cur_pos = pos.wincol - promptchar_len - 1
			if cur_pos > max_pos
				cur_pos = max_pos
			endif
			if cur_pos < 0
				cur_pos = 0
			endif
		else
			return 0
		endif
		# Draw the line and actualise the cursor position
		this.SetText([this.prompt .. join(line, '') .. ' '])
		max_pos = len(line)
		this.input_line = line
		this.cur_pos = cur_pos
		this.max_pos = max_pos

		# Draw the cursor
		this.ActualiseCursor(wid, cur_pos)
		if is_changed
			if len(this.cb_changed) == 0
				return 1
			endif
			var copy_line: string
			if len(this.input_line) == 0
				copy_line = ''
			else
				copy_line = join(copy(this.input_line), '')
			endif
			for Func in this.cb_changed
				Func(key, copy_line)
			endfor
		endif
		return 1
	enddef

	def Close()
		if this.mid != 0
			matchdelete(this.mid, this.popup)
		endif
		popup_close(this.popup)
	enddef

	def ActualiseCursor(wid: number, cur_pos: number)
		const promptchar_len = this.prompt_charlen
		var hl = 'Cursor'
		if this.mid != 0
			matchdelete(this.mid, wid)
		endif
		var hi_end_pos = promptchar_len + 1
		if cur_pos > 0
			hi_end_pos += len(join(this.input_line[: cur_pos - 1], ''))
		endif
		this.mid = matchaddpos(hl, [[1, hi_end_pos]], 10, -1, {window: wid})
	enddef

	def SetTitle(new_title: string)
		popup_setoptions(this.popup, {title: new_title})
	enddef

	def SetPrompt(new_prompt: string)
		this.prompt = new_prompt
		this.prompt_charlen = len(new_prompt)
		var current_input = join(this.input_line, '')
		this.SetText([this.prompt .. current_input .. ' '])
		this.ActualiseCursor(this.popup, this.cur_pos)
	enddef

	def GetPrompt(): string
		return this.prompt
	enddef

	def GetInput(): string
		return join(this.input_line, '')
	enddef

	def SetInput(text: string)
		this.input_line = []
		for i in text
			add(this.input_line, i)
		endfor
		this.cur_pos = len(this.input_line)
		this.max_pos = this.cur_pos
		this.SetText([this.prompt .. text .. ' '])
		this.ActualiseCursor(this.popup, this.cur_pos)
	enddef

	def SetText(lines: list<string>)
		popup_settext(this.popup, lines)
	enddef

endclass
