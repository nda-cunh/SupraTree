vim9script



####################################
#   Abstract Classes for Modified  #
####################################

abstract class BaseObject
	abstract def ToString(): string
	abstract def GetWeight(): number
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
		return "Deleted File: " .. this.path
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

	def ToString(): string
		return "Deleted Directory: " .. this.path
	enddef
endclass


class RenamedFileObject extends RenamedObject
    def new(orig: string, newp: string)
        super.Init(orig, newp)
    enddef

    def ToString(): string
        return "Renamed File: " .. this.original_path .. " -> " .. this.new_path
    enddef

	def GetWeight(): number
		return 3
	enddef

    def Apply(): bool
        return rename(this.original_path, this.new_path) == 0
    enddef
endclass

class RenamedDirectoryObject extends RenamedObject
    def new(orig: string, newp: string)
        super.Init(orig, newp)
    enddef

	def GetWeight(): number
		return 4
	enddef

    def ToString(): string
        return "Renamed Directory: " .. this.original_path .. " -> " .. this.new_path
    enddef

    def Apply(): bool
        return rename(this.original_path, this.new_path) == 0
    enddef
endclass





class NewFileObject extends NewObject
	def new(path: string)
		this.path = simplify(path)
	enddef

	def GetWeight(): number
		return 2
	enddef

	def ToString(): string
		return "New File: " .. this.path
	enddef
endclass



class NewDirectoryObject extends NewObject
	def new(path: string)
		this.path = simplify(path)
	enddef

	def GetWeight(): number
		return 1
	enddef

	def ToString(): string
		return "New Directory: " .. this.path
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

	def Apply()
		this.Sort()
		for node in this.modified_lst
			echo node.Apply()
		endfor
	enddef

	def Print()
		this.Sort()
		for node in this.modified_lst
			echo node.ToString()
		endfor
	enddef

endclass
