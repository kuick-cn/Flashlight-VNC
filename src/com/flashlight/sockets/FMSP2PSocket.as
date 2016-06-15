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
	import flash.events.TimerEvent;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.SharedObject;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	import flash.utils.Timer;
	
	import mx.logging.ILogger;
	import mx.logging.Log;
	
	public class FMSP2PSocket extends EventDispatcher implements ISocket {
		private static const logger:ILogger = Log.getLogger("FMSSocket");
		
		private var readBuffer:ByteArray = new ByteArray();
		private var writeBuffer:ByteArray = new ByteArray();
		
		private var netConnection:NetConnection;
		private var peerId:String;
		
		private var stream:NetStream;
		
		private var closed:Boolean = false;
		
		// RTMFP bugfix: if a peak of data is sent followed by inactivity, data get stuck into the transmit buffer
		private var keepAliveTimer:Timer;
		
		public function FMSP2PSocket(connectionUrl:String, peerId:String) {
			logger.debug(">> init()");
			netConnection = new NetConnection();
			netConnection.addEventListener(AsyncErrorEvent.ASYNC_ERROR,onAsyncError);
			netConnection.addEventListener(IOErrorEvent.IO_ERROR,onIOError);
			netConnection.addEventListener(SecurityErrorEvent.SECURITY_ERROR,onSecurityError);
			netConnection.addEventListener(NetStatusEvent.NET_STATUS, onNetConnectionStatus);
			netConnection.connect.apply(netConnection,connectionUrl.split(";"));
			
			this.peerId = peerId;
			logger.debug("<< init()");
		}
		
		private function onNetConnectionStatus(event:NetStatusEvent):void {
			logger.debug(">> onNetConnectionStatus()");
			switch (event.info.level) {
				case 'status':
					logger.info(event.info.code);
					switch (event.info.code) {
						case 'NetConnection.Connect.Success':
							stream = new NetStream(netConnection,peerId);
							stream.addEventListener(AsyncErrorEvent.ASYNC_ERROR,onAsyncError);
							stream.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
							stream.addEventListener(NetStatusEvent.NET_STATUS, onNetStreamStatus);
							stream.client = this;
							stream.play("");
							dispatchEvent(new Event(Event.CONNECT));
							
							keepAliveTimer = new Timer(100);
							keepAliveTimer.addEventListener(TimerEvent.TIMER, onKeepAliveTimerTimer);
							keepAliveTimer.start();
							break;
						case 'NetStream.Connect.Closed':
							if (!closed) {
								close();
								dispatchEvent(new Event(Event.CLOSE));
							}
							break;
						default:
							logger.info(event.info.code);
					}
					break;
				
				case 'error':
					close();
					dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR,false,false,event.info.code));
					break;
			}
			logger.debug("<< onNetConnectionStatus()");
		}
		
		private function onKeepAliveTimerTimer(event:TimerEvent):void {
			stream.send("onData",new ByteArray());
		}
		
		private function onNetStreamStatus(event:NetStatusEvent):void {
			logger.debug(">> onNetStreamStatus()");
			switch (event.info.level) {
				case 'status':
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
			if (stream) {
				stream.removeEventListener(AsyncErrorEvent.ASYNC_ERROR,onAsyncError);
				stream.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
				stream.removeEventListener(NetStatusEvent.NET_STATUS, onNetStreamStatus);
				stream.client = {};
				stream.close();
			}
			if (netConnection) {
				netConnection.removeEventListener(AsyncErrorEvent.ASYNC_ERROR,onAsyncError);
				netConnection.removeEventListener(IOErrorEvent.IO_ERROR,onIOError);
				netConnection.removeEventListener(SecurityErrorEvent.SECURITY_ERROR,onSecurityError);
				netConnection.removeEventListener(NetStatusEvent.NET_STATUS, onNetConnectionStatus);
				netConnection.close();
			}
			keepAliveTimer.addEventListener(TimerEvent.TIMER,onKeepAliveTimerTimer);
			keepAliveTimer.stop();
			keepAliveTimer = null;
			stream = null;
			netConnection = null;
			closed = true;
			logger.debug("<< close()");
		}
		
		public function onData(packet:ByteArray):void {
			//logger.debug(">> onData()");
			
			//logger.info(">> in "+packetNumber+" "+data.length);
			if (packet.length > 0) {
				var newReadBuffer:ByteArray = new ByteArray();
				newReadBuffer.writeBytes(readBuffer,readBuffer.position,readBuffer.length-readBuffer.position);
				newReadBuffer.writeBytes(packet,0,packet.length);
				newReadBuffer.position = 0;
				
				readBuffer = newReadBuffer;
				dispatchEvent(new ProgressEvent(ProgressEvent.SOCKET_DATA,false,false,packet.length,0));
			}
			//logger.debug("<< onData()");
		}
		
		public function flush():void {
			//logger.debug(">> flush()");
			//logger.info("<< out "+writePacketNumber+" "+writeBuffer.length);
			stream.send("onData",writeBuffer);
			writeBuffer = new ByteArray();
			keepAliveTimer.reset();
			keepAliveTimer.start();
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