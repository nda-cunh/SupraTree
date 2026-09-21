vim9script

import autoload './Utils.vim' as Utils

const WEIGHTS: dict<number> = {
	copied_file: 1,
	copied_directory: 2,
	renamed_file: 3,
	renamed_directory: 4,
	deleted_file: 5,
	deleted_directory: 6,
	new_directory: 7,
	new_file: 8,
}

# Native recursive directory copy (no shell, injection-safe and cross-platform).
# Preserves file permissions to keep the `cp -p` semantics.
def CopyTree(src: string, dst: string): bool
	if !isdirectory(dst)
		mkdir(dst, 'p')
	endif
	for entry in readdirex(src)
		const from = src .. '/' .. entry.name
		const to = dst .. '/' .. entry.name
		if entry.type == 'dir' || entry.type == 'linkd'
			if !CopyTree(from, to)
				return false
			endif
		else
			const data = readfile(from, 'b')
			if writefile(data, to, 'b') != 0
				return false
			endif
		endif
		const perm = getfperm(from)
		if perm != ''
			setfperm(to, perm)
		endif
	endfor
	return true
enddef

####################################
#   Abstract Classes for Modified  #
####################################

abstract class BaseObject
	abstract def ToString(): string
	abstract def GetWeight(): number
	abstract def Apply(): bool
	# The single path this operation ultimately affects/produces, regardless
	# of its concrete type. Lets generic code (conflict/cycle detection)
	# reason about "where does this node end up" without an instanceof chain.
	# For a deletion this is the path being removed, not a "new" path -- the
	# name is kept generic on purpose so every subclass can share it.
	abstract def TargetPath(): string
endclass

abstract class NewObject extends BaseObject
	var path: string
	def TargetPath(): string
		return this.path
	enddef
endclass

abstract class DeletedObject extends BaseObject
	var path: string
	def TargetPath(): string
		return this.path
	enddef
endclass

abstract class RenamedObject extends BaseObject
	var original_path: string
	var new_path: string

	def ToString(): string
		const icon_1 = Utils.GetIcons(this.original_path)
		const icon_2 = Utils.GetIcons(this.new_path)

		return "[Rename]       " .. icon_1 .. ' ' .. this.original_path .. ' → ' .. icon_2 .. ' ' .. this.new_path
	enddef

	def TargetPath(): string
		return this.new_path
	enddef

	def Apply(): bool
		return rename(this.original_path, this.new_path) == 0
	enddef

	def Init(orig: string, newp: string)
		this.original_path = simplify(orig)
		this.new_path = simplify(newp)
	enddef
endclass

abstract class CopiedObject extends BaseObject
	var original_path: string
	var new_path: string

	def TargetPath(): string
		return this.new_path
	enddef
endclass



####################################
#   Concrete Classes for Modified  #
####################################

class DeletedFileObject extends DeletedObject
	def new(path: string)
		this.path = simplify(path)
	enddef

	def ToString(): string
		return "[Deleted File] " .. Utils.GetIcons(this.path) .. ' ' .. this.path
	enddef

	def Apply(): bool
		return delete(this.path) == 0
	enddef

	def GetWeight(): number
		return WEIGHTS.deleted_file
	enddef
endclass

class DeletedDirectoryObject extends DeletedObject
	def new(path: string)
		this.path = simplify(path)
	enddef

	def GetWeight(): number
		return WEIGHTS.deleted_directory
	enddef

	def Apply(): bool
		return delete(this.path, 'rf') == 0
	enddef

	def ToString(): string
		return "[Deleted Dir] " .. Utils.GetIcons(this.path) .. ' ' .. this.path
	enddef
endclass


class RenamedFileObject extends RenamedObject
	def new(orig: string, newp: string)
		super.Init(orig, newp)
	enddef

	def GetWeight(): number
		return WEIGHTS.renamed_file
	enddef
endclass

class RenamedDirectoryObject extends RenamedObject
	def new(orig: string, newp: string)
		super.Init(orig, newp)
	enddef

	def GetWeight(): number
		return WEIGHTS.renamed_directory
	enddef
endclass


class CopiedFileObject extends CopiedObject

	def new(orig: string, newp: string)
		this.original_path = simplify(orig)
		this.new_path = simplify(newp)
	enddef

	def GetWeight(): number
		return WEIGHTS.copied_file
	enddef

	def ToString(): string
		const icon_1 = Utils.GetIcons(this.original_path)
		const icon_2 = Utils.GetIcons(this.new_path)

		return "[Copy File]    " .. icon_1 .. ' ' .. this.original_path .. ' → ' .. icon_2 .. ' ' .. this.new_path
	enddef

	def Apply(): bool
		# Make sure the destination directory exists
		const dest_dir = fnamemodify(this.new_path, ':h')
		if !isdirectory(dest_dir)
			mkdir(dest_dir, 'p')
		endif

		var data = readfile(this.original_path, 'b')
		return writefile(data, this.new_path, 'b') == 0
	enddef
endclass


class CopiedDirectoryObject extends CopiedObject

	def new(orig: string, newp: string)
		this.original_path = simplify(orig)
		this.new_path = simplify(newp)
	enddef

	def GetWeight(): number
		return WEIGHTS.copied_directory
	enddef

	def ToString(): string
		const icon_1 = Utils.GetIcons(this.original_path)
		const icon_2 = Utils.GetIcons(this.new_path)

		return "[Copy Dir]     " .. icon_1 .. ' ' .. this.original_path .. ' → ' .. icon_2 .. ' ' .. this.new_path
	enddef

	def Apply(): bool
		# Make sure the destination's parent directory exists
		const dest_parent = fnamemodify(this.new_path, ':h')
		if !isdirectory(dest_parent)
			mkdir(dest_parent, 'p')
		endif

		return CopyTree(this.original_path, this.new_path)
	enddef
endclass


class NewFileObject extends NewObject
	def new(path: string)
		this.path = simplify(path)
	enddef

	def GetWeight(): number
		return WEIGHTS.new_file
	enddef

	def Apply(): bool
		const dir_path = fnamemodify(this.path, ':h')
		if !isdirectory(dir_path)
			mkdir(dir_path, 'p')
		endif
		var ok = writefile([], this.path) == 0
		if ok
			Utils.Metric('supratree_create', 1)
		endif
		return ok
	enddef

	def ToString(): string
		return '[New File]     ' .. Utils.GetIcons(this.path) .. ' ' .. this.path
	enddef
endclass



class NewDirectoryObject extends NewObject
	def new(path: string)
		this.path = simplify(path)
	enddef

	def GetWeight(): number
		return WEIGHTS.new_directory
	enddef

	def Apply(): bool
		return mkdir(this.path, 'p') == 0
	enddef

	def ToString(): string
		return '[New Dir]      ' .. Utils.GetIcons(this.path, 2) .. ' ' .. this.path
	enddef
endclass


export class Modified
	var modified_lst: list<BaseObject> = []
	var opened_dirs: list<string> = []

	def Append_RenameFile(path: string, new_path: string)
		this.modified_lst->add(RenamedFileObject.new(path, new_path))
	enddef

	def Append_RenameDirectory(path: string, new_path: string)
		this.modified_lst->add(RenamedDirectoryObject.new(path, new_path))
	enddef

	def Append_DeleteFile(path: string)
		this.modified_lst->add(DeletedFileObject.new(path))
	enddef

	def Append_DeleteDirectory(path: string)
		this.modified_lst->add(DeletedDirectoryObject.new(path))
	enddef

	def Append_NewFile(path: string)
		this.modified_lst->add(NewFileObject.new(path))
	enddef

	def Append_NewDirectory(path: string)
		this.modified_lst->add(NewDirectoryObject.new(path))
	enddef

	def Append_CopiedFile(orig: string, newp: string)
		this.modified_lst->add(CopiedFileObject.new(orig, newp))
	enddef

	def Append_CopiedDirectory(orig: string, newp: string)
		this.modified_lst->add(CopiedDirectoryObject.new(orig, newp))
	enddef

	def Sort()
		this.modified_lst->sort((a, b) => {
			const order_a = a.GetWeight()
			const order_b = b.GetWeight()

			return order_a - order_b
		})
	enddef

	def GetOpenedDirectories(): list<string>
		return this.opened_dirs
	enddef

	def AddOpenDirectory(path: string)
		add(this.opened_dirs, simplify(path))
	enddef

	# Applies every staged operation and returns the list of failures (empty
	# list = all good). Never throws: a partial failure still needs the
	# caller to refresh the tree and show what actually happened, so we
	# collect problems instead of raising on the first one.
	def ApplyAll(): list<string>
		this.Sort()
		var errors: list<string> = []
		for node in this.modified_lst
			if !node.Apply()
				errors->add('Échec : ' .. node.ToString())
			endif
		endfor
		return errors
	enddef

	def IsEmpty(): bool
		return len(this.modified_lst) == 0
	enddef

	def Count(): number
		return len(this.modified_lst)
	enddef

	def GetStringList(): list<string>
		var lst: list<string> = []
		this.Sort()

		for node in this.modified_lst
			lst->add(node.ToString())
		endfor
		return lst
	enddef

	# Two staged operations that both end up targeting the same path (e.g. a
	# rename and a new-file landing on the same name, or two copies into the
	# same destination) would silently overwrite one another during Apply().
	# Caught here so SaveActions() can refuse to save instead.
	def DetectConflicts(): list<string>
		var targets: dict<string> = {}   # final path -> description of the op that claimed it
		var errors: list<string> = []

		this.Sort()
		for node in this.modified_lst
			const dest = node.TargetPath()
			if has_key(targets, dest)
				errors->add($"Conflit : '{targets[dest]}' et '{node.ToString()}' ciblent le même chemin : {dest}")
			else
				targets[dest] = node.ToString()
			endif
		endfor

		return errors
	enddef

	# A rename cycle (a -> b, b -> a; or a -> b -> c -> a) corrupts data if
	# applied sequentially: rename() silently overwrites its destination if
	# one already exists, so the first step in the cycle destroys a file
	# that a later step still needed to move. Rather than resolving this
	# automatically (temp-file juggling has too many silent edge cases for
	# the benefit), we detect it and block the save with a clear message.
	def DetectRenameCycles(): list<string>
		var src_to_dst: dict<string> = {}
		for node in this.modified_lst
			if node->instanceof(RenamedObject)
				src_to_dst[node.original_path] = node.TargetPath()
			endif
		endfor

		var errors: list<string> = []
		var seen: dict<bool> = {}

		for start in keys(src_to_dst)
			if get(seen, start, false) | continue | endif

			var chain = [start]
			var cur = src_to_dst[start]
			while has_key(src_to_dst, cur) && index(chain, cur) == -1
				chain->add(cur)
				cur = src_to_dst[cur]
			endwhile

			for p in chain
				seen[p] = true
			endfor

			if cur == start && len(chain) > 1
				errors->add("Cycle de renommage détecté : " .. join(chain, ' → ') .. ' → ' .. chain[0]
					.. ". Sauvegardez ces changements en deux fois (renommez d'abord vers un nom temporaire).")
			endif
		endfor

		return errors
	enddef

	# Convenience for SaveActions(): everything that must block a save,
	# combined in one call.
	def Validate(): list<string>
		return this.DetectConflicts() + this.DetectRenameCycles()
	enddef
endclass
