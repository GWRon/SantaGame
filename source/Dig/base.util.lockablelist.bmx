Rem
	====================================================================
	Lockable TLists
	====================================================================

	Lists extended to allow locking modification.
	

	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2015 Ronny Otto, digidea.de

	This software is provided 'as-is', without any express or
	implied warranty. In no event will the authors be held liable
	for any	damages arising from the use of this software.

	Permission is granted to anyone to use this software for any
	purpose, including commercial applications, and to alter it
	and redistribute it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented; you
	   must not claim that you wrote the original software. If you use
	   this software in a product, an acknowledgment in the product
	   documentation would be appreciated but is not required.

	2. Altered source versions must be plainly marked as such, and
	   must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source
	   distribution.
	====================================================================
EndRem
SuperStrict
Import Brl.LinkedList




Type TLockableList Extends TList
	Field locked:int = False

	
	Method AddFirst:TLink( value:Object )
		Assert not locked Else "Can't insert into a locked list"
		return Super.AddFirst(value)
	End Method


	Method AddLast:TLink( value:Object )
		Assert not locked Else "Can't insert into a locked list"
		return Super.AddLast(value)
	End Method


	Method RemoveFirst:Object()
		Assert not locked Else "Can't remove from a locked list"
		return Super.RemoveFirst()
	End Method


	Method RemoveLast:Object()
		Assert not locked Else "Can't remove from a locked list"
		return Super.RemoveLast()
	End Method


	Method InsertBeforeLink:TLink( value:Object,succ:TLink )
		Assert not locked Else "Can't insert into a locked list"
		return Super.InsertBeforeLink(value, succ)
	End Method


	Method InsertAfterLink:TLink( value:Object,pred:TLink )
		Assert not locked Else "Can't insert into a locked list"
		return Super.InsertAfterLink(value, pred)
	End Method


	Method Remove( value:Object )
		Assert not locked Else "Can't remove from a locked list"
		Super.Remove(value)
	End Method


	Method Copy2:TLockableList()
		Local list:TLockableList = New TLockableList

		Local link:TLink=_head._succ
		While link<>_head
			list.AddLast link._value
			link=link._succ
		Wend
'		Return list


'		list._head = Super.Copy()._head
		list.locked = locked
		Return list
	End Method


	Method Reverse()
		Assert not locked Else "Can't reverse a locked list"
		Super.Reverse()
	End Method


	Method Reversed2:TLockableList()
		Local list:TLockableList = New TLockableList
		Local link:TLink=_head._succ
		While link<>_head
			list.AddFirst link._value
			link=link._succ
		Wend
		list.locked = locked
		Return list
	End Method


	Method Sort( ascending:int=True, compareFunc( o1:Object,o2:Object )=CompareObjects )
		Assert not locked Else "Can't sort a locked list"
		Super.Sort(ascending, compareFunc)
	End Method


	Function FromTList:TLockableList( list:TList )
		if not list then return Null
		
		Local newList:TLockableList = New TLockableList
		newList._head = list.Copy()._head
		newList.locked = False
		Return newList
	End Function


	Function FromArray:TLockableList( arr:Object[] )
		Local list:TLockableList = New TLockableList
		list._head = Super.FromArray(arr)._head
		list.locked = False
		Return list
	End Function
End Type