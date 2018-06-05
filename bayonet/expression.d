// Written in the D programming language.

import std.array, std.algorithm, std.range, std.conv, std.string;

import lexer, parser, scope_, declaration, util;

enum SemState{
	initial,
	started,
	completed,
	error,
}

abstract class Node{
	// debug auto cccc=0;
	Location loc;
	abstract @property string kind();

	// semantic information
	SemState sstate;
}


abstract class Expression: Node{
	int brackets=0;
	override string toString(){return _brk("{}()");}
	protected string _brk(string s){return std.array.replicate("(",brackets)~s~std.array.replicate(")",brackets); return s;}

	override @property string kind(){return "expression";}
	bool isCompound(){ return false; }
}

class TypeAnnotationExp: Expression{
	Expression e,t;
	this(Expression e, Expression t){
		this.e=e; this.t=t;
	}
	override @property string kind(){ return e.kind; }
	override string toString(){ return _brk(e.toString()~": "~t.toString()); }
}

// workaround for the bug:
UnaryExp!(Tok!"&") isAddressExp(Expression self){return cast(UnaryExp!(Tok!"&"))self;}

class ErrorExp: Expression{
	this(){}//{sstate = SemState.error;}
	override string toString(){return _brk("__error");}
}

class LiteralExp: Expression{
	Token lit;
	this(Token lit){ // TODO: suitable contract
		this.lit=lit;
	}
	override string toString(){
		return lit.toString();
	}
}

class Identifier: Expression{
	string name;
	// alias name this; // stupid compiler bug prevents this from being useful
	@property auto ptr(){return name.ptr;}
	@property auto length(){return name.length;}
	this(string name){ // TODO: make more efficient, this is a bottleneck!
		static string[string] uniq;
		auto n=uniq.get(name,null);
		if(n !is null) this.name = n;
		else this.name = uniq[name] = name;
		static int x = 0;
	}
	override string toString(){return _brk(name);}
	override @property string kind(){return "identifier";}

	// semantic information:
	Declaration meaning;
	Scope scope_;
}

class PlaceholderExp: Expression{
	Identifier ident;
	this(Identifier ident){ this.ident = ident; }
	override string toString(){ return _brk("?"); }
	override @property string kind(){ return "placeholder"; }
}


class UnaryExp(TokenType op): Expression{
	Expression e;
	this(Expression next){e = next;}
	override string toString(){
		import std.uni;
		return _brk(TokChars!op~(TokChars!op[$-1].isAlpha()?" ":"")~e.toString());
	}
	static if(op==Tok!"&"){
		override @property string kind(){
			return "address";
		}
		//override UnaryExp!(Tok!"&") isAddressExp(){return this;}
	}
}
class PostfixExp(TokenType op): Expression{
	Expression e;
	this(Expression next){e = next;}
	override string toString(){return _brk(e.toString()~TokChars!op);}
}

class IndexExp: Expression{ //e[a...]
	Expression e;
	Expression[] a;
	this(Expression exp, Expression[] args){e=exp; a=args;}
	override string toString(){
		return _brk(e.toString()~'['~join(map!(to!string)(a),",")~']');
	}
}

class CallExp: Expression{
	Expression e;
	Expression[] args;
	this(Expression exp, Expression[] args){e=exp; this.args=args;}
	override string toString(){
		return _brk(e.toString()~'('~join(map!(to!string)(args),",")~')');
	}
}

abstract class ABinaryExp: Expression{
	Expression e1,e2;
	this(Expression left, Expression right){e1=left; e2=right;}
	abstract @property string operator();
}

class BinaryExp(TokenType op): ABinaryExp{
	this(Expression left, Expression right){super(left,right);}

	static if(op==Tok!"@") static string delegate(Expression,Expression) toStringImpl;
	override string toString(){
		static if(op==Tok!"@") if(toStringImpl) return toStringImpl(e1,e2);
		return _brk(e1.toString() ~ " "~TokChars!op~" "~e2.toString());
	}
	//override string toString(){return e1.toString() ~ " "~ e2.toString~TokChars!op;} // RPN
	override @property string operator(){
		return TokChars!op;
	}
}

class IDBinaryExp: ABinaryExp{
	Identifier op;
	this(Expression left, Identifier op,Expression right){super(left,right); this.op=op;}

	override string toString(){
		return _brk(e1.toString() ~ " "~op.toString()~" "~e2.toString());
	}
	//override string toString(){return e1.toString() ~ " "~ e2.toString~TokChars!op;} // RPN
	override @property string operator(){
		return op.toString();
	}
}


class FieldExp: Expression{
	Expression e;
	Identifier f;

	this(Expression e,Identifier f){ this.e=e; this.f=f; }
	override string toString(){
		return _brk(e.toString()~"."~f.toString());
	}
}

class IteExp: Expression{
	Expression cond;
	CompoundExp then, othw;
	this(Expression cond, CompoundExp then, CompoundExp othw){
		this.cond=cond; this.then=then; this.othw=othw;
	}
	override string toString(){return _brk("if "~cond.toString() ~ " " ~ then.toString() ~ (othw?" else " ~ (othw.s.length==1&&cast(IteExp)othw.s[0]?othw.s[0].toString():othw.toString()):""));}

	override bool isCompound(){ return true; }
}

class RepeatExp: Expression{
	Expression num;
	CompoundExp bdy;
	this(Expression num, CompoundExp bdy){
		this.num=num; this.bdy=bdy;
	}
	override string toString(){ return _brk("repeat "~num.toString()~" "~bdy.toString()); }
	override bool isCompound(){ return true; }
}

class CompoundExp: Expression{
	Expression[] s;
	this(Expression[] ss){s=ss;}

	override string toString(){return "{\n"~indent(join(map!(a=>a.toString()~(a.isCompound()?"":";"))(s),"\n"))~"\n}";}
	override bool isCompound(){ return true; }

	// semantic information
	BlockScope blscope_;
}

class TupleExp: Expression{
	Expression[] e;
	this(Expression[] e){
		this.e=e;
	}
	override string toString(){ return "("~e.map!(to!string).join(",")~")"; }
	final @property size_t length(){ return e.length; }
}

class LambdaExp: Expression{
	FunctionDef fd;
	this(FunctionDef fd){
		this.fd=fd;
	}
	override string toString(){
		return "("~join(map!(to!string)(fd.params),",")~")"~fd.body_.toString();
	}
}

class ArrayExp: Expression{
	Expression[] e;
	this(Expression[] e){
		this.e=e;
	}
	override string toString(){ return "["~e.map!(to!string).join(",")~"]";}
}

class ReturnExp: Expression{
	Expression e;
	this(Expression e){
		this.e=e;
	}
	override string toString(){ return "return"~(e?" "~e.toString():""); }

	string expected;
}

class ForExp: Expression{
	Identifier var;
	bool leftExclusive;
	Expression left;
	bool rightExclusive;
	Expression right;
	CompoundExp bdy;
	this(Identifier var,bool leftExclusive,Expression left,bool rightExclusive,Expression right,CompoundExp bdy){
		this.var=var;
		this.leftExclusive=leftExclusive; this.left=left;
		this.rightExclusive=rightExclusive; this.right=right;
		this.bdy=bdy;
	}
	override string toString(){ return _brk("for "~var.toString()~" in "~
											(leftExclusive?"(":"[")~left.toString()~".."~right.toString()~
											(rightExclusive?")":"]")~bdy.toString()); }
	override @property string kind(){ return "for loop"; }
	override bool isCompound(){ return true; }
}

class AssertExp: Expression{
	Expression e;
	this(Expression e){
		this.e=e;
	}
	override string toString(){ return "assert("~e.toString()~")"; }
}

class ObserveExp: Expression{
	Expression e;
	this(Expression e){
		this.e=e;
	}
	override string toString(){ return "observe("~e.toString()~")"; }
}

class CObserveExp: Expression{
	Expression var;
	Expression val;
	this(Expression var,Expression val){
		this.var=var; this.val=val;
	}
	override string toString(){ return "cobserve("~var.toString()~","~val.toString()~")"; }
}

class BuiltInExp: Expression{
	TokenType which;
	this(TokenType which)in{assert(util.among(which,Tok!"new",Tok!"fwd",Tok!"dup",Tok!"drop",Tok!"FwdQ",Tok!"RunSw"));}body{
		this.which=which;
	}
	override string toString(){ return TokenTypeToString(which); }
}

class AtExp: Expression{
	Identifier name;
	Expression node;
	this(Identifier name, Expression node){
		this.name=name;
		this.node=node;
	}
	override string toString(){ return _brk(name.toString()~"@"~node.toString()); }
}
