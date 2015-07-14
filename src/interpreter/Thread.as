/*
 * Scratch Project Editor and Player
 * Copyright (C) 2014 Massachusetts Institute of Technology
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

// Thread.as
// John Maloney, March 2010
//
// Thread is an internal data structure used by the interpreter. It holds the
// state of a thread so it can continue from where it left off, and it has
// a stack to support nested control structures and procedure calls.

package interpreter {
	import blocks.Block;

	public class Thread {
		
		internal var realBlock:Block;
	
		public var target:*;			// object that owns the stack
		public var topBlock:Block;		// top block of the stack
		public var tmpObj:*;			// temporary object (not saved on stack)
		public var startDelayCount:int;	// number of frames to delay before starting
	
		// the following state is pushed and popped when running substacks
		public var block:Block;
		public var isLoop:Boolean;
		public var firstTime:Boolean;	// used by certain control structures
		public var tmp:int;				// used by repeat and wait
		public var args:Array;			// arguments to a user-defined procedure
	
		// the stack
		private const stack:Vector.<StackFrame> = new Vector.<StackFrame>();
		private var sp:int;
	
		public function Thread(b:Block, targetObj:*, startupDelay:int = 0) {
			target = targetObj;
			stop();
			topBlock = b;
			startDelayCount = startupDelay;
			// initForBlock
			reset(b);
		}
		
		private function reset(b:Block):void
		{
			block = b;
			isLoop = false;
			firstTime = true;
			tmp = 0;
		}
		
		internal function onStoped():void
		{
			realBlock.hideRunFeedback();
		}
	
		public function pushStateForBlock(b:Block):void {
			if (sp >= (stack.length - 1)) growStack();
			var old:StackFrame = stack[sp++];
			old.save();
			// initForBlock
			reset(b);
		}
	
		public function popState():Boolean {
			if (sp == 0) return false;
			var old:StackFrame = stack[--sp];
			old.restore();
			return true;
		}
	
		public function stackEmpty():Boolean { return sp == 0 }
	
		public function stop():void {
			block = null;
			stack.length = 4;
			stack[0] = new StackFrame(this);
			stack[1] = new StackFrame(this);
			stack[2] = new StackFrame(this);
			stack[3] = new StackFrame(this);
			sp = 0;
		}
	
		public function isRecursiveCall(procCall:Block, procHat:Block):Boolean {
			var callCount:int = 5; // maximum number of enclosing procedure calls to examine
			for (var i:int = sp - 1; i >= 0; i--) {
				var b:Block = stack[i].block;
				if (b.op == Specs.CALL) {
					if (procCall == b) return true;
					if (procHat == target.procCache[b.spec]) return true;
				}
				if (--callCount < 0) return false;
			}
			return false;
		}
	
		public function returnFromProcedure():Boolean {
			for (var i:int = sp - 1; i >= 0; i--) {
				if (stack[i].block.op == Specs.CALL) {
					sp = i + 1;
					popState();
					return true;
				}
			}
			return false;
		}
	
		private function initForBlock(b:Block):void {
			block = b;
			isLoop = false;
			firstTime = true;
			tmp = 0;
		}
	
		private function growStack():void {
			// The stack is an array of Thread instances, pre-allocated for efficiency.
			// When growing, the current size is doubled.
			var s:int = stack.length;
			var n:int = s + s;
			stack.length = n;
			for (var i:int = s; i < n; ++i)
				stack[i] = new StackFrame(this);
		}
	
	}
}
