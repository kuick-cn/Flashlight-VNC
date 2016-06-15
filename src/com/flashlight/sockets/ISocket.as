/*

Copyright (C) 2011 Marco Fucci

This program is free software; you can redistribute it and/or modify it under the terms of the
GNU General Public License as published by the Free Software Foundation;
either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program;
if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

Contact : mfucci@gmail.com

*/

package com.flashlight.sockets
{
	import com.flashlight.utils.IDataBufferedOutput;
	
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.utils.IDataInput;
	
	[Event(name=Event.CONNECT, type=Event)]
	[Event(name=Event.CLOSE, type=Event)]
	[Event(name=Event.SOCKET_DATA, type=ProgressEvent)]
	[Event(name=IOErrorEvent.IO_ERROR, type=IOErrorEvent)]
	[Event(name=SecurityErrorEvent.SECURITY_ERROR, type=SecurityErrorEvent)]
	
	public interface ISocket extends IDataBufferedOutput, IDataInput, IEventDispatcher {
		function close():void;
	}
}