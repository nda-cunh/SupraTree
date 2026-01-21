vim9script

import autoload './Utils.vim' as Utils

####################################
#   Abstract Classes for Modified  #
####################################

abstract class BaseObject
	abstract def ToString(): string
	abstract def GetWeight(): number
	abstract def Apply(): bool 
endclass

abstract class NewObject extends BaseObject
	var path: string
endclass

abstract class DeletedObject extends BaseObject
	var path: string
endclass

abstract class RenamedObject extends BaseObject
    var original_path: string
    var new_path: string

    def ToString(): string
		const icon_1 = Utils.GetIcons(this.original_path)
		const icon_2 = Utils.GetIcons(this.new_path)

		return "[Rename]       " .. icon_1 .. ' ' .. this.original_path .. ' → ' .. icon_2 .. ' ' .. this.new_path
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
		return 7
	enddef
endclass

class DeletedDirectoryObject extends DeletedObject
	def new(path: string)
		this.path = simplify(path)
	enddef

	def GetWeight(): number
		return 8
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
		return 5
	enddef
endclass

class RenamedDirectoryObject extends RenamedObject
    def new(orig: string, newp: string)
        super.Init(orig, newp)
    enddef

	def GetWeight(): number
		return 6
	enddef
endclass


class CopiedFileObject extends CopiedObject

	def new(orig: string, newp: string)
		this.original_path = simplify(orig)
		this.new_path = simplify(newp)
	enddef

	def GetWeight(): number
		return 4
	enddef

	def ToString(): string
		const icon_1 = Utils.GetIcons(this.original_path)
		const icon_2 = Utils.GetIcons(this.new_path)

		return "[Copy File]    " .. icon_1 .. ' ' .. this.original_path .. ' → ' .. icon_2 .. ' ' .. this.new_path
	enddef

	def Apply(): bool
		# S'assurer que le répertoire de destination existe
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
		return 3
	enddef

	def ToString(): string
		const icon_1 = Utils.GetIcons(this.original_path)
		const icon_2 = Utils.GetIcons(this.new_path)

		return "[Copy Dir]     " .. icon_1 .. ' ' .. this.original_path .. ' → ' .. icon_2 .. ' ' .. this.new_path
	enddef

	def Apply(): bool
		# S'assurer que le dossier parent de la destination existe
		const dest_parent = fnamemodify(this.new_path, ':h')
		if !isdirectory(dest_parent)
			mkdir(dest_parent, 'p')
		endif

		var cmd: string
		if has('win32')
			cmd = $'xcopy "{this.original_path}" "{this.new_path}" /E /I /H /Y'
		else
			cmd = $'cp -rp "{this.original_path}" "{this.new_path}"'
		endif

		system(cmd)

		return v:shell_error == 0
	enddef
endclass


class NewFileObject extends NewObject
	def new(path: string)
		this.path = simplify(path)
	enddef

	def GetWeight(): number
		return 2
	enddef

	def Apply(): bool
		const dir_path = fnamemodify(this.path, ':h')
		if !isdirectory(dir_path)
			mkdir(dir_path, 'p')
		endif
		return writefile([], this.path) == 0
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
		return 1
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

	def ApplyAll()
		this.Sort()
		for node in this.modified_lst
			echo node.Apply()
		endfor
	enddef

	def IsEmpty(): bool
		return len(this.modified_lst) == 0
	enddef

	def GetStringList(): list<string>
		var lst: list<string> = []
		this.Sort()

		for node in this.modified_lst
			lst->add(node.ToString())
		endfor
		return lst
	enddef

endclass
