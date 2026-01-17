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
		return 6
	enddef
endclass

class DeletedDirectoryObject extends DeletedObject
	def new(path: string)
		this.path = simplify(path)
	enddef

	def GetWeight(): number
		return 5
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
		return 3
	enddef
endclass

class RenamedDirectoryObject extends RenamedObject
    def new(orig: string, newp: string)
        super.Init(orig, newp)
    enddef

	def GetWeight(): number
		return 4
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

    def Sort()
        this.modified_lst->sort((a, b) => {
            const order_a = a.GetWeight()
            const order_b = b.GetWeight()

            return order_a - order_b
        })
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
