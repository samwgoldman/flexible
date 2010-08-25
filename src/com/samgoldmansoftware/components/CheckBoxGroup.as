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
* The Original Code is com.samgoldmansoftware.components.CheckBoxGroup.
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
	import flash.events.Event;
	
	import mx.collections.ArrayCollection;
	import mx.core.ClassFactory;
	import mx.core.IVisualElement;
	import mx.core.mx_internal;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.FlexEvent;
	import mx.events.PropertyChangeEvent;
	import mx.events.PropertyChangeEventKind;
	
	import spark.components.DataGroup;
	import spark.components.IItemRenderer;
	import spark.events.RendererExistenceEvent;
	import spark.layouts.VerticalLayout;
	import spark.utils.LabelUtil;
	
	use namespace mx_internal;
	
	[Event(name="selectedItemsChange", type="spark.events.PropertyChangeEvent")]
	public class CheckBoxGroup extends DataGroup
	{
		/**
		 * Constructor
		 */
		public function CheckBoxGroup()
		{
			super();
			
			itemRenderer = new ClassFactory(CheckBoxRenderer);
			
			selectedItems = new ArrayCollection();
		}
		
		//-----------------------------------------------------------------------------------------
		// Variables
		//-----------------------------------------------------------------------------------------
		
		private var _selectedItems:ArrayCollection;
		
		private var _labelField:String;
		private var _labelFunction:Function;
		private var labelFieldOrFunctionChanged:Boolean = false;
		
		//-----------------------------------------------------------------------------------------
		// Properties
		//-----------------------------------------------------------------------------------------
		
		/**
		 * Specifies the objects from the dataProvider which are selected.
		 * 
		 * Those items which are selected will appear as checked.
		 */
		[Bindable("selectedItemsChange")]
		public function get selectedItems():ArrayCollection
		{
			return _selectedItems;
		}
		
		public function set selectedItems(value:ArrayCollection):void
		{
			if (_selectedItems === value)
				return;
			
			var event:PropertyChangeEvent = new PropertyChangeEvent("selectedItemsChange");
			event.kind = PropertyChangeEventKind.UPDATE;
			event.property 'selectedItems';
			event.oldValue = _selectedItems;
			event.newValue = value;
			event.source = this;
			
			if (_selectedItems)
			{
				_selectedItems.removeEventListener(CollectionEvent.COLLECTION_CHANGE,
					selectedItems_collectionChangeHandler);
			}
			
			_selectedItems = value;
			
			if (_selectedItems)
			{
				_selectedItems.addEventListener(CollectionEvent.COLLECTION_CHANGE,
					selectedItems_collectionChangeHandler, false, 0, true);
			}
			
			dispatchEvent(event);
		}
		
		/**
		 *  The name of the field in the data provider items to display 
		 *  as the label. 
		 *  The <code>labelFunction</code> property overrides this property.
		 */
		public function get labelField():String
		{
			return _labelField;
		}
		
		public function set labelField(value:String):void
		{
			if (_labelField == value)
				return;
			
			_labelField = value;
			labelFieldOrFunctionChanged = true;
			invalidateProperties();
		}
		
		/**
		 *  A user-supplied function to run on each item to determine its label.  
		 *  The <code>labelFunction</code> property overrides 
		 *  the <code>labelField</code> property.
		 *
		 *  <p>You can supply a <code>labelFunction</code> that finds the 
		 *  appropriate fields and returns a displayable string. The 
		 *  <code>labelFunction</code> is also good for handling formatting and 
		 *  localization. </p>
		 *
		 *  <p>The label function takes a single argument which is the item in 
		 *  the data provider and returns a String.</p>
		 *  <pre>
		 *  myLabelFunction(item:Object):String</pre>
		 */
		public function get labelFunction():Function
		{
			return _labelFunction;
		}
		
		public function set labelFunction(value:Function):void
		{
			if (_labelFunction === value)
				return;
			
			_labelFunction = value;
			labelFieldOrFunctionChanged = true;
			invalidateProperties();
		}
		
		//-----------------------------------------------------------------------------------------
		// Methods
		//-----------------------------------------------------------------------------------------
		
		private function updateRendererLabelProperty(itemIndex:int):void
		{
			var renderer:IItemRenderer = IItemRenderer(getElementAt(itemIndex));
			if (renderer)
			{
				renderer.label = itemToLabel(renderer.data); 
			}
		}
		
		//-----------------------------------------------------------------------------------------
		// DataGroup Overrides
		//-----------------------------------------------------------------------------------------
		
		/**
		 *  Given a data item, return the correct text a renderer
		 *  should display while taking the <code>labelField</code> 
		 *  and <code>labelFunction</code> properties into account. 
		 */
		override public function itemToLabel(item:Object):String
		{
			return LabelUtil.itemToLabel(item, labelField, labelFunction);
		}
		
		/**
		 *  @private
		 */
		override public function updateRenderer(_renderer:IVisualElement, itemIndex:int, data:Object):void
		{
			var renderer:IItemRenderer = IItemRenderer(_renderer);
			renderer.removeEventListener(Event.CHANGE, renderer_changeHandler);
			renderer.addEventListener(Event.CHANGE, renderer_changeHandler, false, 0, true);
			renderer.owner = this;
			renderer.selected = selectedItems.getItemIndex(data) != -1;
			renderer.label = itemToLabel(data);
			renderer.data = data;
		}
		
		/**
		 *  @private
		 */ 
		override protected function createChildren():void
		{
			if (!layout)
			{
				var layout:VerticalLayout = new VerticalLayout();
				layout.gap = 0;
				this.layout = layout;
			}
			
			super.createChildren();
		}
		
		//-----------------------------------------------------------------------------------------
		// UIComponent Overrides
		//-----------------------------------------------------------------------------------------
		
		/**
		 *  @private
		 */
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if (labelFieldOrFunctionChanged)
			{
				var n:int = numElements;
				for (var i:int = 0; i < n; i++)
				{
					updateRendererLabelProperty(i);
				}
				labelFieldOrFunctionChanged = false;
			}
		}
		
		//-----------------------------------------------------------------------------------------
		// Event Listeners
		//-----------------------------------------------------------------------------------------
		
		private function renderer_changeHandler(event:Event):void
		{
			var renderer:IItemRenderer = IItemRenderer(event.target);
			var data:Object = renderer.data;
			var index:int = selectedItems.getItemIndex(data);
			if (renderer.selected && index == -1)
			{
				selectedItems.addItem(data);
			}
			else if (!renderer.selected && index != -1)
			{
				selectedItems.removeItemAt(index);
			}
		}
		
		private function selectedItems_collectionChangeHandler(event:CollectionEvent):void
		{
			var n:uint, i:uint, renderer:IItemRenderer;
			switch (event.kind)
			{
				case CollectionEventKind.ADD:
				case CollectionEventKind.REMOVE:
					n = event.items.length;
					for (i = 0; i < n; i++)
					{
						renderer = getElementAt(dataProvider.getItemIndex(event.items[i])) as IItemRenderer;
						if (renderer)
						{
							renderer.selected = selectedItems.getItemIndex(renderer.data) != -1;
						}
					}
					break;
				case CollectionEventKind.REFRESH:
				case CollectionEventKind.RESET:
					n = numElements;
					for (i = 0; i < n; i++)
					{
						renderer = getElementAt(i) as IItemRenderer;
						if (renderer)
						{
							renderer.selected = selectedItems.getItemIndex(renderer.data) != -1;
						}
					}
					break;
				default:
					return;
			}
			invalidateDisplayList();
		}
		
		/**
		 *  @private
		 */
		override mx_internal function dataProvider_collectionChangeHandler(event:CollectionEvent):void
		{
			// Remove those items from selectedItems which are removed from the dataProvider.
			var i:int, n:int, index:int;
			selectedItems.disableAutoUpdate();
			switch (event.kind)
			{
				case CollectionEventKind.REMOVE:
					n = event.items.length;
					for (i = 0; i < n; i++)
					{
						index = selectedItems.getItemIndex(event.items[i]);
						if (index != -1)
						{
							selectedItems.removeItemAt(index);
						}
					}
					break;
				case CollectionEventKind.REFRESH:
				case CollectionEventKind.RESET:
					n = selectedItems.length;
					for (i = n - 1; i >= 0; i--)
					{
						index = dataProvider.getItemIndex(selectedItems.getItemAt(i));
						if (index == -1)
						{
							selectedItems.removeItemAt(i);
						}
					}
					break;
			}
			selectedItems.enableAutoUpdate();
			
			super.dataProvider_collectionChangeHandler(event);
		}
	}
}

import spark.components.CheckBox;
import spark.components.IItemRenderer;
import spark.skins.spark.CheckBoxSkin;

class CheckBoxRenderer extends CheckBox implements IItemRenderer
{
	public function CheckBoxRenderer()
	{
		super();
		percentWidth = 100;
		percentHeight = 100;
		setStyle("skinClass", Class(CheckBoxSkin));
	}
	
	private var _data:Object;
	public function get data():Object { return _data; }
	public function set data(value:Object):void { _data = value; }
	
	private var _dragging:Boolean;
	public function get dragging():Boolean { return _dragging; }
	public function set dragging(value:Boolean):void { _dragging = value; }
	
	private var _itemIndex:int;
	public function get itemIndex():int { return _itemIndex; }
	public function set itemIndex(value:int):void { _itemIndex = value; }
	
	private var _showsCaret:Boolean;
	public function get showsCaret():Boolean { return _showsCaret; }
	public function set showsCaret(value:Boolean):void { _showsCaret = value; }
}