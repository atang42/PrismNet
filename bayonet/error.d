
import std.stdio;
import std.string, std.range, std.array, std.uni;
import std.conv: text;

import lexer, util;


abstract class ErrorHandler{
	//string source;
	//string code;
	int nerrors=0;
	private int tabsize=8;


	void error(lazy string err, Location loc)in{assert(loc.line>=1&&loc.rep);}body{nerrors++;}   // in{assert(loc.rep);}body
	void note(lazy string note, Location loc)in{assert(loc.rep);}body{};

	void message(string msg){ stderr.write(msg); }

	bool showsEffect(){ return true; }

	int getTabsize(){ return tabsize; }

	this(){
		tabsize=getTabSize();
	}
}
class SimpleErrorHandler: ErrorHandler{
	override void error(lazy string err, Location loc){
		if(loc.line == 0 && !loc.rep.ptr){ // just here for robustness
			stderr.writeln("(location missing): "~err);
			return;
		}
		nerrors++;
		stderr.writeln(loc.source.name,'(',loc.line,"): error: ",err);
	}
}

// TODO: remove code duplication

class VerboseErrorHandler: ErrorHandler{
	override void error(lazy string err, Location loc){
		nerrors++;
		impl(err, loc, false);
	}
	override void note(lazy string err, Location loc){
		impl(err, loc, true);
	}
	private void impl(lazy string err, Location loc, bool isNote){
		if(loc.line == 0&&!loc.rep.ptr){ // just here for robustness
			stderr.writeln("(location missing): "~err);
			return;
		}
		auto src = loc.source;
		auto source = src.name;
		auto line = src.getLineOf(loc.rep);
		if(loc.rep.ptr<line.ptr) loc.rep=loc.rep[line.ptr-loc.rep.ptr..$];
		auto column=getColumn(loc,tabsize);
		write(source, loc.line, column, err, isNote);
		if(line.length&&line[0]&&loc.rep.length){
			display(line);
			highlight(column, loc.rep);
		}		
	}
protected:
	void write(string source, int line, int column, string error, bool isNote = false){
		stderr.writeln(source,':',line?text(line,":",column,":"):"",isNote?" note: ":" error: ",error);
	}
	void display(string line){
		stderr.writeln(line);
	}
	void highlight(int column, string rep){
		if(!rep.length) return;
		foreach(i;0..column-1) stderr.write(" ");
		stderr.write("^");
		rep.popFront();
		foreach(dchar x;rep){if(isNewLine(x)) break; stderr.write("~");}
		stderr.writeln();		
	}
}

import terminal;
class FormattingErrorHandler: VerboseErrorHandler{
protected:
	override void write(string source, int line, int column, string error, bool isNote = false){
		if(isATTy(stderr)){
			if(isNote) stderr.writeln(BOLD,source,':',line,":",column,": ",BLACK,"note:",RESET,BOLD," ",error,RESET);
			else stderr.writeln(BOLD,source,':',line,":",column,": ",RED,"error:",RESET,BOLD," ",error,RESET);
		}else super.write(source, line, column, error, isNote);
	}
	override void highlight(int column, string rep){
		if(isATTy(stderr)){
			foreach(i;0..column-1) stderr.write(" ");
			//stderr.write(CSI~"A",GREEN,";",CSI~"D",CSI~"B");
			stderr.write(BOLD,GREEN,"^");
			rep.popFront();
			foreach(dchar x;rep){if(isNewLine(x)) break; stderr.write("~");}
			stderr.writeln(RESET);
		}else super.highlight(column, rep);
	}
}

string formatError(string msg,Location loc){
	import std.conv;
	return text(loc.line,": ",msg); // TODO: column
}
