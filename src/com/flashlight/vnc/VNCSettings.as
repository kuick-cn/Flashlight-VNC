/*

	Copyright (C) 2009 Marco Fucci

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

package com.flashlight.vnc
{
	import flash.events.EventDispatcher;
	import flash.net.SharedObject;
	
	import mx.events.PropertyChangeEvent;
	import mx.logging.ILogger;
	import mx.logging.Log;
	
	public class VNCSettings extends EventDispatcher {
		private static const logger:ILogger = Log.getLogger("VNCSettings");
		
		public static const CONNECTION_DIRECT:String = "direct";
		public static const CONNECTION_REPEATER:String = "repeater";
		public static const CONNECTION_FMS:String = "fms";
		public static const CONNECTION_P2P_FMS:String = "p2pfms";
		
		[Bindable] public var connectionType:String = CONNECTION_DIRECT;
		[Bindable] public var fmsServerUrl:String = "rtmfp://localhost/myApp";
		[Bindable] public var p2pFmsServerUrl:String = "rtmfp://localhost/myApp";
		[Bindable] public var streamName:String = "vnc";
		[Bindable] public var fallbackToFms:Boolean = false;
		[Bindable] public var host:String = "localhost";
		[Bindable] public var port:int = 5900;
		[Bindable] public var repeaterHost:String;
		[Bindable] public var repeaterPort:int;
		[Bindable] public var useSecurity:Boolean = true;
		[Bindable] public var securityPort:int = 1234;
		[Bindable] public var encoding:int = VNCConst.ENCODING_TIGHT;
		[Bindable] public var colorDepth:int = 24;
		[Bindable] public var jpegCompression:int = 6;
		[Bindable] public var viewOnly:Boolean = true;
		[Bindable] public var shared:Boolean = true;
		[Bindable] public var scale:Boolean = false;
		[Bindable] public var useRemoteCursor:Boolean = true;
		
		private var so:SharedObject;
		
		public function bindToSharedObject():void {
			so = SharedObject.getLocal("settings");
			if (so != null && so.data != null) {
				if (so.data.connectionType !== undefined) connectionType = so.data.connectionType;
				if (so.data.host != undefined) host = so.data.host;
				if (so.data.port != undefined) port = so.data.port;
				if (so.data.repeaterHost != undefined) repeaterHost = so.data.repeaterHost;
				if (so.data.repeaterPort != undefined) repeaterPort = so.data.repeaterPort;
				if (so.data.fmsServerUrl != undefined) fmsServerUrl = so.data.fmsServerUrl;
				if (so.data.p2pFmsServerUrl != undefined) p2pFmsServerUrl = so.data.p2pFmsServerUrl;
				if (so.data.streamName != undefined) streamName = so.data.streamName;
				if (so.data.fallbackToFms != undefined) fallbackToFms = so.data.fallbackToFms;
				if (so.data.useSecurity != undefined) useSecurity = so.data.useSecurity;
				if (so.data.securityPort != undefined) securityPort = so.data.securityPort;
				if (so.data.encoding != undefined) encoding = so.data.encoding;
				if (so.data.colorDepth != undefined) colorDepth = so.data.colorDepth;
				if (so.data.jpegCompression != undefined) jpegCompression = so.data.jpegCompression;
				if (so.data.viewOnly != undefined) viewOnly = so.data.viewOnly;
				if (so.data.shared != undefined) shared = so.data.shared;
				if (so.data.scale != undefined) scale = so.data.scale;
				if (so.data.useRemoteCursor != undefined) useRemoteCursor = so.data.useRemoteCursor;
				
				addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, onPropertyChange);
			}
		}
		
		private function onPropertyChange(event:PropertyChangeEvent):void {
			
			if (so != null && so.data != null) {
				so.data.connectionType = connectionType;
				so.data.fmsServerUrl = fmsServerUrl;
				so.data.p2pFmsServerUrl = p2pFmsServerUrl;
				so.data.streamName = streamName;
				so.data.fallbackToFms = fallbackToFms;
				so.data.repeaterHost = repeaterHost;
				so.data.repeaterPort = repeaterPort;
				so.data.host = host;
				so.data.port = port;
				so.data.useSecurity = useSecurity;
				so.data.securityPort = securityPort;
				so.data.encoding = encoding;
				so.data.colorDepth = colorDepth;
				so.data.jpegCompression = jpegCompression;
				so.data.viewOnly = viewOnly;
				so.data.shared = shared;
				so.data.scale = scale;
				so.data.remoteCursor = useRemoteCursor;
				
				so.flush();
			}
		}

	}
}