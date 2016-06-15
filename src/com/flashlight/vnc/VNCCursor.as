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
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.geom.Point;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import flash.ui.MouseCursorData;
	
	import mx.effects.easing.Back;
	import mx.logging.ILogger;
	import mx.logging.Log;
	
	public class VNCCursor extends Bitmap {
		private static var logger:ILogger = Log.getLogger("VNCCursor");
		
		private var cursorShape:BitmapData;
		private var hotSpot:Point;
		private var isXorMode:Boolean;
		
		private var useRemoteCursor:Boolean;
		private var isControlling:Boolean;
		private var useNativeCursor:Boolean = false;
		private var nativeCursorHidden:Boolean = false;
		
		public function VNCCursor(defaultCursorImage:DisplayObject,useRemoteCursor:Boolean,isControlling:Boolean) {
			bitmapData = new BitmapData(defaultCursorImage.width, defaultCursorImage.height,true,0);
			bitmapData.draw(defaultCursorImage);
			isXorMode = false;
			hotSpot = new Point(0,0);
			smoothing = true;
			updateCursorShape();
		}
		
		public function moveTo(newX:int,newY:int):void {
			if (!useNativeCursor) {
				x = newX - hotSpot.x;
				y = newY - hotSpot.y;
			}
		}
		
		public function changeShape(bitmapData:BitmapData, hotSpot:Point):void {
			var onlyWhite:Boolean = true;
			for (var x:int = 0; x<bitmapData.width; x++) {
				for (var y:int = 0; y<bitmapData.height; y++) {
					if (bitmapData.getPixel32(x,y) != 0x00000000 && bitmapData.getPixel32(x,y) != 0xFFFFFFFF) {
						onlyWhite = false;
						break;
					}
				}
			}
			this.hotSpot = hotSpot;
			this.cursorShape = bitmapData;
			this.isXorMode = onlyWhite;
			updateCursorShape();
		}
		
		public function setCursorMode(useRemoteCursor:Boolean, isControlling:Boolean):void {
			this.useRemoteCursor = useRemoteCursor;
			this.isControlling = isControlling;
			updateCursorShape();
		}
		
		private function updateCursorShape():void {
			var updateNativeCursor:Boolean = useRemoteCursor && isControlling && !isXorMode && Mouse.supportsNativeCursor;
			
			if (!updateNativeCursor) {
				if (useNativeCursor) {
					visible = true;
					useNativeCursor = false;
					Mouse.cursor = MouseCursor.AUTO;
					Mouse.unregisterCursor("vncCursor");
				}
				if (isControlling && !nativeCursorHidden) {
					Mouse.hide();
					nativeCursorHidden = true;
				}
				if (!isControlling && nativeCursorHidden) {
					Mouse.show();
					nativeCursorHidden = false;
				}
				this.bitmapData = cursorShape;
				x = x + this.hotSpot.x - hotSpot.x;
				y = y + this.hotSpot.y - hotSpot.y;
				if (isXorMode) {
					blendMode = BlendMode.INVERT;
				} else {
					blendMode = BlendMode.NORMAL;
				}
			} else {
				if (!useNativeCursor) {
					visible = false;
					useNativeCursor = true;
				}
				
				var cursorData:MouseCursorData = new MouseCursorData();
				cursorData.hotSpot = hotSpot;
				cursorData.data = new <BitmapData>[cursorShape];
				Mouse.registerCursor("vncCursor",cursorData);
				Mouse.cursor = "vncCursor";
				
				if (nativeCursorHidden) {
					Mouse.show();
					nativeCursorHidden = false;
				}
			}
		}

	}
}