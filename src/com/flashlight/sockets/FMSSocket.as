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
	import com.flashlight.sockets.ISocket;
	import com.flashlight.utils.BetterPopUpMenuButton;
	import com.flashlight.utils.IDataBufferedOutput;
	
	import flash.events.AsyncErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.SyncEvent;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.Responder;
	import flash.net.SharedObject;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	
	import mx.logging.ILogger;
	import mx.logging.Log;
	
	public class FMSSocket extends EventDispatcher implements ISocket {
		private static const logger:ILogger = Log.getLogger("FMSSocket");
		
		private var readBuffer:ByteArray = new ByteArray();
		private var writeBuffer:ByteArray = new ByteArray();
		
		private var netConnection:NetConnection;
		private var streamName:String;
		private var clientId:String;
		
		private var upStream:NetStream;
		private var downStream:NetStream;
		
		private var closed:Boolean = false;
		
		public function FMSSocket(connectionUrl:String,streamName:String) {
			logger.debug(">> init()");
			netConnection = new NetConnection();
			netConnection.addEventListener(AsyncErrorEvent.ASYNC_ERROR,onAsyncError);
			netConnection.addEventListener(IOErrorEvent.IO_ERROR,onIOError);
			netConnection.addEventListener(SecurityErrorEvent.SECURITY_ERROR,onSecurityError);
			netConnection.addEventListener(NetStatusEvent.NET_STATUS, onNetConnectionStatus);
			netConnection.connect.apply(netConnection,connectionUrl.split(";"));
			
			this.streamName = streamName;
			logger.debug("<< init()");
		}
		
		private function onNetConnectionStatus(event:NetStatusEvent):void {
			logger.debug(">> onNetConnectionStatus()");
			switch (event.info.level) {
				case 'status':
					switch (event.info.code) {
						case 'NetConnection.Connect.Success':
							var responder:Responder = new Responder(onClientId);
							netConnection.call("@getClientID",responder);
							dispatchEvent(new Event(Event.CONNECT));
							break;
						case 'NetStream.Connect.Closed':
							if (!closed) {
								close();
								dispatchEvent(new Event(Event.CLOSE));
							}
							break;
						default:
							logger.debug(event.info.code);
					}
					break;
				
				case 'error':
					close();
					dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR,false,false,event.info.code));
					break;
			}
			logger.debug("<< onNetConnectionStatus()");
		}
		
		private function onClientId(clientId:String):void {
			logger.debug(">> onClientId()");
			
			this.clientId = clientId;
			
			var controlStream:NetStream = new NetStream(netConnection);
			controlStream.addEventListener(AsyncErrorEvent.ASYNC_ERROR,onAsyncError);
			controlStream.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			controlStream.addEventListener(NetStatusEvent.NET_STATUS, onNetStreamStatus);
			controlStream.publish(streamName);
			controlStream.send("requestConnection",streamName+"_"+clientId);
			controlStream.close();
			
			upStream = new NetStream(netConnection);
			upStream.addEventListener(AsyncErrorEvent.ASYNC_ERROR,onAsyncError);
			upStream.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			upStream.addEventListener(NetStatusEvent.NET_STATUS, onNetStreamStatus);
			upStream.publish(streamName+"_"+clientId+"_c2s");
			
			logger.debug("<< onClientId()");
		}
		
		private function onNetStreamStatus(event:NetStatusEvent):void {
			logger.debug(">> onNetStreamStatus()");
			switch (event.info.level) {
				case 'status':
					switch (event.info.code) {
						case "NetStream.Publish.Start":
							if (event.target == upStream) {
								downStream = new NetStream(netConnection);
								downStream.addEventListener(AsyncErrorEvent.ASYNC_ERROR,onAsyncError);
								downStream.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
								downStream.addEventListener(NetStatusEvent.NET_STATUS, onNetStreamStatus);
								downStream.client = {
									onData: function(data:ByteArray):void {
										onData(data);
									}
								};
								downStream.play(streamName+"_"+clientId+"_s2c");
							}
							break;
						case "NetStream.Play.UnpublishNotify":
								if (event.target == downStream) {
								close();
								dispatchEvent(new Event(Event.CLOSE));
								}
							break;
						default:
							logger.debug(event.info.code);
					}
					break;
					logger.debug(event.info.code);
					break;
				
				case 'error':
					dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR,false,false,event.info.code));
			}
			logger.debug("<< onNetStreamStatus()");
		}
		
		public function close():void {
			if (closed) return;
			logger.debug(">> close()");
			if (upStream) {
				upStream.removeEventListener(AsyncErrorEvent.ASYNC_ERROR,onAsyncError);
				upStream.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
				upStream.removeEventListener(NetStatusEvent.NET_STATUS, onNetStreamStatus);
				upStream.close();
			}
			if (downStream) {
				downStream.removeEventListener(AsyncErrorEvent.ASYNC_ERROR,onAsyncError);
				downStream.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
				downStream.removeEventListener(NetStatusEvent.NET_STATUS, onNetStreamStatus);
				downStream.client = {};
				downStream.close();
			}
			if (netConnection) {
				netConnection.removeEventListener(AsyncErrorEvent.ASYNC_ERROR,onAsyncError);
				netConnection.removeEventListener(IOErrorEvent.IO_ERROR,onIOError);
				netConnection.removeEventListener(SecurityErrorEvent.SECURITY_ERROR,onSecurityError);
				netConnection.removeEventListener(NetStatusEvent.NET_STATUS, onNetConnectionStatus);
				netConnection.close();
			}
			downStream = null;
			upStream = null;
			netConnection = null;
			closed = true;
			logger.debug("<< close()");
		}
		
		public function onData(data:ByteArray):void {
			//logger.debug(">> onData()");
			
			// logger.info(">> in "+data.length);
			var newReadBuffer:ByteArray = new ByteArray();
			newReadBuffer.writeBytes(readBuffer,readBuffer.position,readBuffer.length-readBuffer.position);
			newReadBuffer.writeBytes(data,0,data.length);
			newReadBuffer.position = 0;
			
			readBuffer = newReadBuffer;
			dispatchEvent(new ProgressEvent(ProgressEvent.SOCKET_DATA,false,false,data.length,0));
			
			//logger.debug("<< onData()");
		}
		
		public function flush():void {
			//logger.debug(">> flush()");
			// logger.info("<< out "+writeBuffer.length);
			upStream.send("onData",writeBuffer);
			writeBuffer = new ByteArray();
			//logger.debug("<< flush()");
		}
		
		public function readBytes(bytes:ByteArray, offset:uint=0, length:uint=0):void {
			readBuffer.readBytes(bytes,offset,length);
		}
		
		public function readBoolean():Boolean {
			return readBuffer.readBoolean();
		}
		
		public function readByte():int {
			return readBuffer.readByte();
		}
		
		public function readUnsignedByte():uint {
			return readBuffer.readUnsignedByte();
		}
		
		public function readShort():int {
			return readBuffer.readShort();
		}
		
		public function readUnsignedShort():uint {
			return readBuffer.readUnsignedShort();
		}
		
		public function readInt():int {
			return readBuffer.readInt();
		}
		
		public function readUnsignedInt():uint {
			return readBuffer.readUnsignedInt();
		}
		
		public function readFloat():Number {
			return readBuffer.readFloat();
		}
		
		public function readDouble():Number {
			return readBuffer.readDouble();
		}
		
		public function readMultiByte(length:uint, charSet:String):String {
			return readBuffer.readMultiByte(length,charSet);
		}
		
		public function readUTF():String {
			return readBuffer.readUTF();
		}
		
		public function readUTFBytes(length:uint):String {
			return readBuffer.readUTFBytes(length);
		}
		
		public function get bytesAvailable():uint {
			return readBuffer.bytesAvailable;
		}
		
		public function readObject():* {
			return readBuffer.readObject();
		}
		
		public function get objectEncoding():uint {
			return readBuffer.objectEncoding;
		}
		
		public function set objectEncoding(version:uint):void {
			readBuffer.objectEncoding = version;
		}
		
		public function get endian():String {
			return readBuffer.endian;
		}
		
		public function set endian(type:String):void {
			readBuffer.endian = type;
		}
		
		public function writeBytes(bytes:ByteArray, offset:uint=0, length:uint=0):void {
			writeBuffer.writeBytes(bytes,offset,length);
		}
		
		public function writeBoolean(value:Boolean):void {
			writeBuffer.writeBoolean(value);
		}
		
		public function writeByte(value:int):void {
			writeBuffer.writeByte(value);
		}
		
		public function writeShort(value:int):void {
			writeBuffer.writeShort(value);
		}
		
		public function writeInt(value:int):void {
			writeBuffer.writeInt(value);
		}
		
		public function writeUnsignedInt(value:uint):void {
			writeBuffer.writeUnsignedInt(value);
		}
		
		public function writeFloat(value:Number):void {
			writeBuffer.writeFloat(value);
		}
		
		public function writeDouble(value:Number):void {
			writeBuffer.writeDouble(value);
		}
		
		public function writeMultiByte(value:String, charSet:String):void {
			writeBuffer.writeMultiByte(value,charSet);
		}
		
		public function writeUTF(value:String):void {
			writeBuffer.writeUTF(value);
		}
		
		public function writeUTFBytes(value:String):void {
			writeBuffer.writeUTFBytes(value);
		}
		
		public function writeObject(object:*):void {
			writeBuffer.writeObject(object);
		}
		
		private function onIOError(event:IOErrorEvent):void {
			dispatchEvent(event.clone());
		}
		
		private function onSecurityError(event:IOErrorEvent):void {
			dispatchEvent(event.clone());
		}
		
		private function onAsyncError(event:AsyncErrorEvent):void {
			dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR,false,false,event.text));
		}
	}
}