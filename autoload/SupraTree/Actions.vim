vim9script

type ActionType = number
const DELETE = 0
const RENAME = 1
const CREATE_FILE = 2
const CREATE_FOLDER = 3

class Action
	var action_type: ActionType
	var prefix: string
	var line_num: number

	def new(type: ActionType, line_num: number, prefix: string = '')
		this.action_type = type
		this.prefix = prefix
		this.line_num = line_num
	enddef
endclass


export class Actions
	# Contains all action like
	# delete file, rename file, create file, create folder
	# and their associated line in the buffer
	var actions: list<Action>

	def new()
		this.actions = []
	enddef

	# This apply all the actions in the list
	def MakeActions()
		for action in this.actions
			echom 'Action type: ' .. action.action_type .. ' on line ' .. action.line_num
		endfor
	enddef

	def FileIsDeleted(prefix: string): bool
		for action in this.actions
			if action.action_type == DELETE
				if prefix == action.prefix
					return true
				endif
			endif
		endfor
		return false
	enddef

	def DeleteAction(lnum: number, path: string)
		# Check if the actions with 'path' already exist
		# if it exist, remove it from the list
		# else add a new action
		var existing_action_idx = -1
		var idx = 0
		while idx < len(this.actions)
			const action = this.actions[idx]
			if action.line_num == lnum && action.action_type == DELETE
				existing_action_idx = idx
				break
			endif
			idx += 1
		endwhile
		if existing_action_idx != -1
			# remove the action
			this.actions->remove(existing_action_idx)
			echom 'Removed delete action for ' .. path
		else
			# add a new action
			const new_action = Action.new(DELETE, lnum, path)
			this.actions->add(new_action)
			echom 'Added delete action for ' .. path
		endif
	enddef
endclass

