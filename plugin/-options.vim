vim9script

if has('patch-9.1.0850') == 0
	finish
endif

if !exists('*supraconfig#RegisterMany')
	finish
endif

import autoload '../autoload/SupraTree/SupraTree.vim' as Tree
import autoload '../autoload/SupraTree/DarkenColor.vim' as Darken


supraconfig#RegisterGroup('supratree', 'SupraTree file explorer settings')

supraconfig#RegisterMany([
	# --- SUPRATREE ---
	{
		id: 'supratree/open',
		type: 'bool',
		default: true,
		lore: 'Display the file explorer on startup',
		handler: (v) => {
			g:supratree_open_on_startup = v 
		}
	},
	{
		id: 'supratree/winsize',
		type: 'number',
		default: 26,
		lore: 'Default width of the explorer window',
		handler: (v) => {
			g:supratree_width = v
			Tree.Resize()
		}
	},
	{
		id: 'supratree/show_hidden',
		type: 'bool',
		default: false,
		lore: 'Show hidden files in the explorer',
		handler: (v) => {
			g:supratree_show_hidden = v
		}
	},
	{
		id: 'supratree/sort_ascending',
		type: 'bool',
		default: true,
		lore: 'Sort explorer files in ascending order',
		handler: (v) => {
			g:supratree_sortascending = v
		}
	},
	{
		id: 'supratree/theme_darken_percent',
		type: 'number',
		default: 18,
		lore: 'Percentage to darken the explorer background',
		handler: (v: number) => {
			g:supratree_darken_amount = v
			Darken.Create_HiColor()
		}
	},
	{
		id: 'supratree/theme_forcecolor',
		type: 'string',
		default: "",
		lore: 'Force a specific hex color for the explorer (e.g. #adedb8)',
		handler: (v) => {
			g:supratree_force_color = v
		}
	},
	{
		id: 'supratree/position',
		type: 'string',
		options: ['left', 'right'],
		default: 'left',
		lore: 'Position of the explorer window (left or right)',
		handler: (v) => {
			g:supratree_position = v
			Tree.Move()
		}
	}
])
