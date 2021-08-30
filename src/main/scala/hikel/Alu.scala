// Arithmetic Logic Unit

package hikel

import chisel3._
import chisel3.util._

import SimpleAlu._

// The Alu op is extracted directly from inst[14:12]
object SimpleAlu {
	val ALU_ADD 	= "b000".U(3.W)
	val ALU_SLT 	= "b010".U(3.W)
	val ALU_SLTU	= "b011".U(3.W)
	val ALU_XOR		= "b100".U(3.W)
	val ALU_OR 		= "b110".U(3.W)
	val ALU_AND		= "b111".U(3.W)
	val ALU_SLL		= "b001".U(3.W)
	val ALU_SRL 	= "b101".U(3.W)

	def apply(width: Int) = {
		assert(32 == width || 64 == width || 128 == width)
		new SimpleAlu(width)
	}
}

// This is the internal implementation of ALU for computing
class SimpleAlu(val width: Int) extends Module {
	val io = IO(new Bundle {
		val op = Input(UInt(3.W))
		val arith = Input(Bool())		// is shift arithmetic?
		val in0 = Input(UInt(width.W))
		val in1 = Input(UInt(width.W))
		val shmt = Input(UInt(log2Ceil(width).W))
		val result = Output(UInt(width.W))
	})

	io.result := MuxLookup(io.op, 0.U, Array(
		ALU_ADD 	-> (io.in0 + io.in1),
		ALU_SLT 	-> (io.in0.asSInt < io.in1.asSInt),
		ALU_SLTU 	-> (io.in0 < io.in1),
		ALU_XOR 	-> (io.in0 ^ io.in1),
		ALU_OR 		-> (io.in0 | io.in1),
		ALU_AND 	-> (io.in0 & io.in1),
		ALU_SLL 	-> (io.in0 << io.shmt),
		ALU_SRL 	-> Mux(io.arith, (io.in0.asSInt >> io.shmt).asUInt, io.in0 >> io.shmt)
	))
}

class Alu(val width: Int) extends Module {
	val io = IO(new Bundle {
		val op = Input(UInt(3.W))
		val arith = Input(Bool())		// arithmetic
		val word = Input(Bool())			// word operation 
		val in0 = Input(UInt(width.W))
		val in1 = Input(UInt(width.W))
		val shmt = Input(UInt(log2Ceil(width).W))
		val result = Output(UInt(width.W))
	})

	// in case of sub, io.arith is asserted 
	val in1 = Mux(io.arith, ~io.in1+1.U, io.in1)

	val _alu = Module(SimpleAlu.apply(width))
	_alu.io.op := io.op
	_alu.io.arith := io.arith
	_alu.io.in0 := io.in0
	_alu.io.in1 := in1
	_alu.io.shmt := io.shmt

	// in case of 'w' instructions in RV64
	io.result := Mux(io.word,
		Cat(Fill(width-32, _alu.io.result(31)), _alu.io.result(31, 0)),
		_alu.io.result
	)
}