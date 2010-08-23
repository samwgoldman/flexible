/* ***** BEGIN LICENSE BLOCK *****
* Version: MPL 1.1
*
* The contents of this file are subject to the Mozilla Public License Version
* 1.1 (the "License"); you may not use this file except in compliance with
* the License. You may obtain a copy of the License at
* http://www.mozilla.org/MPL/
*
* Software distributed under the License is distributed on an "AS IS" basis,
* WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
* for the specific language governing rights and limitations under the
* License.
*
* The Original Code is com.samgoldmansoftware.components.XHTMLTableGrid.
*
* The Initial Developer of the Original Code is
* Sam Goldman <samwgoldman at gmail dot com>.
* Portions created by the Initial Developer are Copyright (C) 2010
* the Initial Developer. All Rights Reserved.
*
* Contributor(s):
*
* ***** END LICENSE BLOCK ***** */

package com.samgoldmansoftware.components
{
	import mx.containers.Grid;
	import mx.containers.GridItem;
	import mx.containers.GridRow;
	import mx.core.UIComponent;
	import mx.core.UITextField;
	
	public class XHTMLTableGrid extends UIComponent
	{
		public function XHTMLTableGrid()
		{
			super();
		}
		
		//---------------------------------------------------------------------
		// Variables
		//---------------------------------------------------------------------
		
		private var grid:Grid;
		
		private var xhtmlTableToGridMap:Object = {
			"table": Grid,
			"tr": GridRow,
			"td": GridItem,
			"th": GridItem
		};
		
		//---------------------------------------------------------------------
		// Properties
		//---------------------------------------------------------------------
		
		private var _tableXHTML:XML;
		private var tableXHTMLChanged:Boolean = false;
		
		public function get tableXHTML():XML
		{
			return _tableXHTML;
		}
		
		public function set tableXHTML(value:XML):void
		{
			if (_tableXHTML !== value)
			{
				_tableXHTML = value;
				tableXHTMLChanged = true;
				invalidateSize();
				invalidateProperties();
				invalidateDisplayList();
			}
		}
		
		//---------------------------------------------------------------------
		// Methods
		//---------------------------------------------------------------------
		
		private function parse(xml:XML):UIComponent
		{
			var value:UIComponent = xhtmlTableToGrid(xml);
			
			if (xml.hasSimpleContent())
			{
				var content:UITextField = new UITextField();
				content.text = xml.toString();
				if (value)
				{
					value.addChild(content);
				}
			}
			else
			{
				switch (xml.nodeKind())
				{
					case "processing-instruction":
					case "comment":
					case "attribute":
						break;
					
					case "text":
					case "element":
						var children:XMLList = xml.children();
						for each (var node:XML in children)
					{
						var child:UIComponent = parse(node);
						if (child)
						{
							value.addChild(child);
						}
					}
						break;
				}
			}
			
			return value;
		}
		
		private function xhtmlTableToGrid(node:XML):UIComponent
		{
			var value:UIComponent;
			
			// Get the name of the root element.
			var nodeName:String;
			if (node.name() is QName)
			{
				nodeName = QName(node.name()).localName;
			}
			
			// Map the root element to a Grid component.
			if (nodeName && xhtmlTableToGridMap.hasOwnProperty(nodeName))
			{
				// The mapping can be a simple class, or a function returning the component.
				var mapping:* = xhtmlTableToGridMap[nodeName];
				if (mapping is Class)
				{
					var klass:Class = Class(mapping);
					value = new klass();
				}
				else if (mapping is Function)
				{
					var fn:Function = mapping as Function;
					value = fn(node);
				}
			}
			
			return value;
		}
		
		//---------------------------------------------------------------------
		// UIComponent overrides
		//---------------------------------------------------------------------
		
		override protected function measure():void
		{
			super.measure();
			
			if (grid)
			{
				measuredWidth = grid.getExplicitOrMeasuredWidth();
				measuredHeight = grid.getExplicitOrMeasuredHeight();
			}
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if (tableXHTMLChanged)
			{
				grid = parse(_tableXHTML) as Grid;
				if (grid)
				{
					addChild(grid);
				}
				tableXHTMLChanged = false;
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			if (grid)
			{
				grid.width = unscaledWidth;
				grid.height = unscaledHeight;
			}
		}
	}
}