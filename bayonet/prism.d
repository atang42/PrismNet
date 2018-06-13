import std.conv, std.algorithm, std.range, std.array, std.string;
import lexer, expression, declaration, util;

import std.typecons: Q=Tuple,q=tuple;

//TODO: Duplicate state variable names in multiple modules

class PrismBuilder{
    class Variable{
        string name;
        string type;
        Expression init_;
        this(string name,string type,Expression init_=null){
            this.name=name;
            this.type=type;
            this.init_=init_;
        }
        string toPRISM(){
            return "Variable.toPsi: "~name~": "~type;
        }
        string toPRISMInit()in{assert(!!init_);}body{
            return "Variable.toPsiInit: "~name~" = "~init_.toString()~";";
        }
    }
    class Program{
        string name;
        Expression prgbody;
        string[] pFields;
        //TODO: Get correct capacity
        int inCapacity = 2;
        int outCapacity = 1;

        this(string name, Expression prgbody){
            this.name=name;
            this.prgbody = prgbody;
        }
        void addState(string name, expression.Expression init_=null){
            state~=new Variable(name,name=="pkt"?"Packet":"int",init_);
            stateSet[name]=[];
        }
        string toPRISM(){
            //TODO: Get correct value ranges
            string r="module "~name~"\n";

            // Input queue state
            string inStatements = "";
            for(int i = 0; i < inCapacity; i++)
            {
                inStatements ~= name ~ "_in"~to!string(i)~"_port: [0..k];\n";
                foreach(Variable var; packetFields) {
                    inStatements ~= name ~ "_in"~to!string(i)~"_pkt_"~var.name~": [0..k];\n";
                }
            }

            // Output queue state
            string outStatements = "";
            for(int i = 0; i < outCapacity; i++)
            {
                outStatements ~= name ~ "_out"~to!string(i)~"_port: [0..k];\n";
                foreach(Variable var; packetFields) {
                    outStatements ~= name ~ "_out"~to!string(i)~"_pkt_"~var.name~": [0..k];\n";
                }
            }

            // Queue size state
            string inSizeDecl;
            if(this == programs[0]) {
                inSizeDecl = name ~ "_in_size : [0.."~inCapacity.to!string~"] init 1;\n";
            }
            else {
                inSizeDecl = name ~ "_in_size : [0.."~inCapacity.to!string~"];\n";
            }
            string outSizeDecl = name ~ "_out_size : [0.."~outCapacity.to!string~"];\n";

            r~=indent(
                inStatements ~
                outStatements ~
                inSizeDecl ~
                outSizeDecl ~
                "\n"
                );

            // User defined state
            foreach(string var; stateSet.keys.sort) {
                r~= indent(var ~ ": [0..MAX_VAR_VALUE];\n");
            }

            string[] fields = packetFields.map!(v => v.name).array;
            PrismProgramTranslator ppt = new PrismProgramTranslator();
            PrismProgramTranslator.ProgramPath paths = ppt.getAllExecutions(prgbody, stateSet.keys, name, fields);

            r~= indent(paths.getPrismFlipDecl()) ~ "\n";
            r~= indent(paths.getPrismGenRand()) ~ "\n";
            r~= indent(paths.getPrismStep()) ~ "\n";

            r~= indent(getPRISMLinks(name)) ~ "\n";

            r~="endmodule\n";
            return r;
        }
        void[0][string] stateSet;
        private:
        Variable[] state;
    }
    Program addProgram(string name, Expression expr){
        auto r=new Program(name, expr);
        programs~=r;
        return r;
    }
    void addPacketField(string name){
        packetFields~=new Variable(name,"int");
    }
    void addNode(string name)in{assert(name !in nodeId);}body{
        nodeId[name]=cast(int)nodes.length;
        nodes~=name;
    }
    void addProgram(string node,string name)in{assert(node in nodeId);}body{
        foreach(i,p;programs) if(p.name==name){ // TODO: replace linear lookup
            nodeProg[nodeId[node]]=cast(int)i;
            return;
        }
        assert(0);
    }
    void addLink(InterfaceDecl a,InterfaceDecl b){
        auto x=q(a.node.name,a.port), y=q(b.node.name,b.port);
        links[x[0]][x[1]]=y;
        links[y[0]][y[1]]=x;
    }
    void addParam(ParameterDecl p){
        params~=p;
    }
    void addScheduler(FunctionDef scheduler){
        this.scheduler=scheduler;
    }
    void addPostObserve(Expression decl){
        postObserves~=decl;
    }
    void addNumSteps(NumStepsDecl numSteps){
        this.num_steps = numSteps.num_steps;
    }
    void addQueueCapacity(QueueCapacityDecl capacity){
        this.capacity = capacity.capacity;
    }
    void addQuery(QueryDecl query){
        queries~=query.query;
    }

    // Find the node name for a given program
    string prgToNode(string prgname) {
        foreach(string s; nodes) {
            if(programs[nodeProg[nodeId[s]]].name == prgname)
                return s;
        }
        assert(0, "Cannot find node for " ~ prgname);
    }        

    string getPRISMLinks(string name) {
        // TODO: implement queueing
        string node = prgToNode(name);
        Program prg = programs[nodeProg[nodeId[node]]];
        string[] fields = packetFields.map!(v => v.name).array;
        string ret;
        // For each link
        foreach(int port; links[node].keys) {
            string neighbor = links[node][port][0];
            int neighborPort = links[node][port][1];
            Program neighborPrg = programs[nodeProg[nodeId[neighbor]]];

            //writeln(node, " ", port, " ", name, " <-> ", neighbor, " ", neighborPrg.name, " ", neighborPort);

            // Sender Actions
            {
                string action = "["~node~"_"~neighbor~"_link] ";
                string condition = name ~ "_out_size > 0"                                   // Sender has packet
                         ~ " & " ~ name ~ "_out0_port = " ~ port.to!string ~ " -> ";        // Sender port is to destination
                string sendSizeAction = "(" ~ name ~ "_out_size' = " ~ name ~ "_out_size-1)";
                string pktActions = "";
                foreach(string field; fields) {
                    // Shift output queue
                    for(int i = prg.outCapacity-2; i >= 0; i--) {
                        pktActions ~= " & (" ~ prg.name ~ "_out" ~ i.to!string ~ "_pkt_" ~ field ~ "'" 
                                    ~ " = " ~ prg.name ~ "_out" ~ (i+1).to!string ~ "_pkt_" ~ field ~ ")";
                    }
                }
                pktActions ~= ";\n";

                ret ~= action ~ condition ~ sendSizeAction ~ pktActions;
                //writeln(action, condition, sendSizeAction, pktActions);
            }
            ret ~= "\n";
            // Receiver Actions
            for(int recvQSize = 0; recvQSize <= prg.inCapacity; recvQSize++) {

                string action = "["~neighbor~"_"~node~"_link] ";
                string condition = name ~ "_in_size = " ~ recvQSize.to!string   // Size of receiving queue
                         ~ " & " ~ neighborPrg.name ~ "_out_size > 0"                                   // Sender has packet
                         ~ " & " ~ neighborPrg.name ~ "_out0_port = " ~ neighborPort.to!string ~ " -> ";        // Sender port is to destination
                // Drop packet if max capacity
                string portAction = "";
                string recvSizeAction = "";
                string pktActions = "";
                if( recvQSize < prg.inCapacity) {
                    portAction = "(" ~ name ~ "_in" ~ recvQSize.to!string ~ "_port' = " ~ port.to!string ~ ")"; 
                    recvSizeAction = " & (" ~ name ~ "_in_size' = " ~ name ~ "_in_size+1)";
                    foreach(string field; fields) {
                        pktActions ~= " & (" ~ name ~ "_in" ~ recvQSize.to!string ~ "_pkt_" ~ field ~ "'"
                                    ~ " = " ~ neighborPrg.name ~ "_out0_pkt_" ~ field ~ ")";
                    }
                }
                else {
                    pktActions = "true";
                }
                pktActions ~= ";\n";

                ret ~= action ~ condition ~ portAction ~ recvSizeAction ~ pktActions;
                //writeln(action, condition, portAction, recvSizeAction, pktActions);
            }
            ret ~= "\n";
        }
        return ret;
    }


    string toPRISM(){
        auto maxvaldef="const int MAX_VAR_VALUE = " ~ text(this.maxValue) ~ ";\n";
        auto nodedef="const int k = "~text(nodes.length)~";\n"~iota(nodes.length).map!(k=>text("const int ",nodes[k]," = ",k)).join(";\n")~(nodes.length?";\n":"");

        auto initToType = (string s) => (indexOf(s, ".") != -1 ? " double " : " int ");
        auto paramdef=params.map!(p=>"const" ~ initToType(p.init_.toString()) ~ p.name.toString()~" = "~(p.init_?p.init_.toString():"?"~p.name.toString())).join(";\n")~(params.length?";\n\n":"");

        return nodedef~maxvaldef~paramdef~programs.map!(a=>a.toPRISM()~"\n").join;
    }

    Variable[] packetFields;
    private:
    Program[] programs;
    string[] nodes;
    ParameterDecl[] params;
    int[string] nodeId;
    int[int] nodeProg;
    Q!(string,int)[int][string] links;
    FunctionDef scheduler;
    Expression[] queries;
    Expression num_steps;
    Expression capacity;
    Expression[] postObserves;
    // TODO: Set proper maxValue
    int maxValue = 10;
}

class PrismProgramTranslator {

    this () {}

    // The state of a program after executing one branch
    class State {
        Expression condition;
        Expression[string] mapping;

        this(Expression c, Expression[string] m) {
            this.condition = condition;
            this.mapping = m;
        }

        this(string[] variables) {
            condition = null;
            foreach(string var; variables) {
                mapping[var] = new Identifier(var);
            }
        }

        State copy() {
            State c = new State(mapping.keys);
            c.condition = this.condition;
            foreach(string s, Expression e; this.mapping) {
                c.mapping[s] = e;
            }
            return c;
        }

        override string toString() {
            string r = (condition is null ? "" : condition.toString())  ~ "\n";
            foreach(string s; mapping.keys.sort) {
                r ~= "\t" ~ s ~ " " ~ mapping[s].toString() ~ "\n";
            }
            return r;
        }
    }

    // All states possible from program
    class ProgramPath {
        State[] states;
        int numFlips;
        Expression[] flipProbs;
        string prgname;
        string[] fields;
        //TODO: Get correct capacity
        int inCapacity = 2;
        int outCapacity = 1;

        this () {}

        this(string[] variables, string prgname, string[] packetFields) {
            void[0][string] queueVariables;
            queueVariables[prgname~"_in_size"] = [];
            queueVariables[prgname~"_out_size"] = [];
            for(int i = 0; i < inCapacity; i++) {
                queueVariables[prgname~"_in"~to!string(i)~"_port"] = [];
                foreach(string f; packetFields) {
                    queueVariables[prgname~"_in"~to!string(i)~"_pkt_"~f] = [];
                }
            }
            for(int i = 0; i < outCapacity; i++) {
                queueVariables[prgname~"_out"~to!string(i)~"_port"] = [];
                foreach(string f; packetFields) {
                    queueVariables[prgname~"_out"~to!string(i)~"_pkt_"~f] = [];
                }
            }
            states = [new State(variables~queueVariables.keys)];
            this.prgname = prgname;
            this.fields = packetFields;
        }

        // Create copy of this object;
        ProgramPath copy() {
            ProgramPath c = new ProgramPath();
            c.numFlips = this.numFlips;
            c.flipProbs = this.flipProbs;
            c.prgname = this.prgname;
            c.fields = this.fields;
            c.inCapacity = this.inCapacity;
            c.outCapacity = this.outCapacity;
            c.states = new State[this.states.length];
            foreach(int i, State s; this.states) {
                c.states[i] = s.copy();
            }
            return c;
        }

        // Update a variable with an expression
        void updateState(string var, Expression exp) {
            exp = replaceFlips(exp);
            foreach(State s; states) {
                s.mapping[var] = substituteExpression(exp, s, prgname);
            }
        }

        // Add an extra constraint on the paths
        void updateCondition(Expression cond) {
            cond = replaceFlips(cond);
            foreach(State s; states) {
                if(s.condition is null) {
                    s.condition = substituteExpression(cond, s, prgname);
                }
                else {
                    s.condition = new BinaryExp!(Tok!"and")(substituteExpression(cond, s, prgname), s.condition);
                }
            }
        }

        // Recursively traverse Expression tree replacing flip() with variables
        Expression replaceFlips(Expression exp) {
            if(auto lit = cast(LiteralExp)exp) {
                assert(lit.lit.type==Tok!"0",text("TODO: ",lit));
                return lit;
            }
            else if(auto fe = cast(FieldExp)exp) {
                return fe;
            }
            else if(auto be = cast(ABinaryExp)exp) {
                be.e1 = replaceFlips(be.e1);
                be.e2 = replaceFlips(be.e2);
                return be;
            }
            else if(auto be = cast(UnaryExp!(Tok!"!"))exp) {
                be.e = replaceFlips(be.e);
                return be;
            }
            else if(auto id = cast(Identifier)exp) {
                return id;
            }
            else if(auto call = cast(CallExp)exp) {
                if(auto fname = cast(Identifier)call.e) {
                    assert(fname.name == "flip", text("TODO: ", exp));
                    assert(call.args.length == 1, text("TODO: ", exp));

                    flipProbs ~= call.args[0];
                    string flipName = getFlipVar(numFlips);
                    numFlips++;
                    return new Identifier(flipName);
                }
                return call;
            }
            assert(0,text("TODO: ", typeid(exp), exp));
        }

        // Output Step Actions
        string getPrismStep() {
            string action = "[" ~ prgname ~ "Step] ";

            string ret = "";
            string queueNotEmpty = inSizeVar(prgname) ~ " > 0 ";
            string outNotFull = " & " ~ outSizeVar(prgname) ~ " < " ~ outCapacity.to!string ~ " ";
            string hasFlipsCond = numFlips > 0 ? " & "~prgname~"HasFlips" : "";
            string hasFlipsZero = numFlips > 0 ? "(" ~prgname~"HasFlips'=false)" : "";

            foreach(State st; this.states) {

                string prismCond;
                if(st.condition !is null) {
                    string cond = st.condition.toString.replace("and", "&");
                    cond = cond.replace(" or ", " | ");
                    cond = cond.replace("==", "=");
                    prismCond = queueNotEmpty ~ outNotFull ~ hasFlipsCond ~ " & " ~ cond;
                }
                else {
                    prismCond = queueNotEmpty ~ hasFlipsCond;
                }

                string prismActions;
                string prismBoundsCheck;
                bool first = true;
                foreach(string s, Expression exp; st.mapping) {
                    if(s.equal(exp.toString())) {
                        continue;
                    }
                    if(indexOf(exp.toString(), "+") != -1) {
                        // Adds bound condition if next is defined by adding constant
                        // TODO: Does not cover all cases
                        prismBoundsCheck ~= " & " ~ exp.toString() ~ " < MAX_VAR_VALUE ";
                    }
                    if(!first) {
                        prismActions ~= " & ";
                    }
                    first = false;
                    prismActions ~= "(" ~ s ~ "'=" ~ exp.toString() ~ ")";
                }

                if(!first && numFlips > 0) {
                    prismActions ~= " & ";
                    prismActions ~= hasFlipsZero;
                }
                else if(first) {
                    prismActions ~= "true";
                }
                ret ~= action ~ prismCond ~ prismBoundsCheck ~ " -> " ~ prismActions ~ ";\n";
            }
            return ret;
        }

        string getFlipVar(int i) {
            return prgname ~ "_flip_" ~ i.to!string;
        }

        // Output flip variable declarations
        string getPrismFlipDecl() {
            string ret = "";
            if(numFlips > 0) {
                for(int i = 0; i < numFlips; i++) {
                    ret ~= getFlipVar(i) ~ ": [0..1];\n";
                }
                ret ~= prgname~"HasFlips : bool;\n";
            }
            return ret;
        }

        // Output randomness generation
        string getPrismGenRand() {
            //TODO: May be incorrect if Expressions are not numbers
            if(numFlips > 0) {
                string ret = "[" ~ prgname ~"GenRand] !"~prgname~"HasFlips -> ";
                ret ~= genRandHelper(0, "1", "("~prgname~"HasFlips'=true)");
                ret ~= ";\n";
                return ret;
            }
            return "";
        }

        string genRandHelper(int i, string probAcc, string assignAcc) {
            if(i >= flipProbs.length) {
                return probAcc ~ " : " ~ assignAcc;
            }
            auto invProb = (string s) => ("1-("~s~")");
            // one case
            string oneProb = probAcc ~ " * (" ~ flipProbs[i].toString() ~")";
            string oneAsgn = assignAcc ~ " & (" ~ getFlipVar(i) ~ "'=1)";
            // zero case
            string zeroProb = probAcc ~ " * (" ~ invProb(flipProbs[i].toString()) ~")";
            string zeroAsgn = assignAcc ~ " & (" ~ getFlipVar(i) ~"'=0)";

            return genRandHelper(i+1, oneProb, oneAsgn) ~ " + " ~ genRandHelper(i+1, zeroProb, zeroAsgn);
        }


        override string toString() {
            string r = "numFlips = " ~ to!string(numFlips) ~ "\n";
            r ~= "prgname = " ~ prgname ~ "\n";
            foreach(State s; states) {
                r ~= s.toString();
            }
            return r;
        }
    }

    string inFieldVar(string prgname, string field, int i) {
        return prgname ~ "_in" ~ to!string(i) ~ "_pkt_" ~ field;
    }

    string inPortVar(string prgname, int i) {
        return prgname ~ "_in" ~ to!string(i) ~ "_port";
    }

    string inSizeVar(string prgname) {
        return prgname ~ "_in_size";
    }

    string outFieldVar(string prgname, string field, int i) {
        return prgname ~ "_out" ~ to!string(i) ~ "_pkt_" ~ field;
    }

    string outPortVar(string prgname, int i) {
        return prgname ~ "_out" ~ to!string(i) ~ "_port";
    }

    string outSizeVar(string prgname) {
        return prgname ~ "_out_size";
    }

    // Create an Expression for the "drop" statement
    Expression generateDrop(string prgname, int capacity, string[] fields) {
        // Shift packets forward
        alias AssignExp = BinaryExp!(Tok!"=");
        Expression[] assigns;
        for(int i = 0; i < capacity - 1; i++)
        {
            Expression lhsPort = new Identifier(inPortVar(prgname, i));
            Expression rhsPort = new Identifier(inPortVar(prgname, i+1));
            assigns ~= new AssignExp(lhsPort, rhsPort);
            foreach(string f; fields) {
                Expression lhsField = new Identifier(inFieldVar(prgname, f, i));
                Expression rhsField = new Identifier(inFieldVar(prgname, f, i+1));
                assigns ~= new AssignExp(lhsField, rhsField);
            }
        }
        Expression sizeVar = new Identifier(inSizeVar(prgname));
        Token tok = Token(Tok!"0");
        tok.int64 = 1;
        Expression minusExpr = new BinaryExp!(Tok!"-")(sizeVar, new LiteralExp(tok));
        assigns ~= new AssignExp(sizeVar, minusExpr);

        CompoundExp compound = new CompoundExp(assigns);

        // Add condition for input queue size greater than zero
        Token capTok = Token(Tok!"0");
        capTok.int64 = 0;

        Expression condition = new BinaryExp!(Tok!">")(sizeVar, new LiteralExp(capTok));
        Expression ret = new IteExp(condition, compound, new CompoundExp([]));
        
        return ret;
    }

    // Create an Expression for the "new" statement
    Expression generateNew(string prgname, int capacity, string[] fields) {
        alias AssignExp = BinaryExp!(Tok!"=");

        // Shift input queue back
        Expression[] assigns;
        for(int i = capacity-2; i >= 0; i--)
        {
            Expression lhsPort = new Identifier(inPortVar(prgname, i+1));
            Expression rhsPort = new Identifier(inPortVar(prgname, i));
            assigns ~= new AssignExp(lhsPort, rhsPort);
            foreach(string f; fields) {
                Expression lhsField = new Identifier(inFieldVar(prgname, f, i+1));
                Expression rhsField = new Identifier(inFieldVar(prgname, f, i));
                assigns ~= new AssignExp(lhsField, rhsField);
            }
        }
        Expression sizeVar = new Identifier(inSizeVar(prgname));
        Token tok = Token(Tok!"0");
        tok.int64 = 1;
        Expression plusExpr = new BinaryExp!(Tok!"+")(sizeVar, new LiteralExp(tok));
        assigns ~= new AssignExp(sizeVar, plusExpr);

        CompoundExp compound = new CompoundExp(assigns);

        // If input queue size less than capacity
        Token capTok = Token(Tok!"0");
        capTok.int64 = capacity;

        Expression condition = new BinaryExp!(Tok!"<")(sizeVar, new LiteralExp(capTok));
        Expression ret = new IteExp(condition, compound, new CompoundExp([]));
        return ret;
    }   
    // Create an Expression for the "fwd" statement
    Expression generateFwd(string prgname, int capacity, string[] fields, Expression destPort) {
        //TODO: Add condition size > 0
        alias AssignExp = BinaryExp!(Tok!"=");
        Expression[] assigns;

        // Move from in queue to out queue
        //TODO: Add output queueing
        Expression outPort = new Identifier(outPortVar(prgname, 0));
        assigns ~= new AssignExp(outPort, destPort);
        foreach(string f; fields) {
            Expression outField = new Identifier(outFieldVar(prgname, f, 0));
            Expression inField = new Identifier(inFieldVar(prgname, f, 0));
            assigns ~= new AssignExp(outField, inField);
        }
        Expression outSize = new Identifier(outSizeVar(prgname));
        Token ztok = Token(Tok!"0");
        ztok.str = "1";
        assigns ~= new AssignExp(outSize, new LiteralExp(ztok));

        // Shift elements in input queue
        for(int i = 0; i < capacity - 1; i++)
        {
            Expression lhsPort = new Identifier(inPortVar(prgname, i));
            Expression rhsPort = new Identifier(inPortVar(prgname, i+1));
            assigns ~= new AssignExp(lhsPort, rhsPort);
            foreach(string f; fields) {
                Expression lhsField = new Identifier(inFieldVar(prgname, f, i));
                Expression rhsField = new Identifier(inFieldVar(prgname, f, i+1));
                assigns ~= new AssignExp(lhsField, rhsField);
            }
        }
        Expression sizeVar = new Identifier(inSizeVar(prgname));
        Token tok = Token(Tok!"0");
        tok.str = "1";
        Expression minusExpr = new BinaryExp!(Tok!"-")(sizeVar, new LiteralExp(tok));
        assigns ~= new AssignExp(sizeVar, minusExpr);

        Expression ret = new CompoundExp(assigns);
        return ret;
    }       

    class MyBinExp: ABinaryExp {
        string op;
        this(Expression left, string op, Expression right) { super(left, right); this.op = op; }

        override string toString() {
            return _brk("(" ~ e1.toString() ~ " " ~ op ~ " " ~ e2.toString() ~ ")");
        }
        override @property string operator() { return op; }
    }

    Expression substituteExpression(Expression exp, State state, string prgname) {
        if(auto lit = cast(LiteralExp)exp) {
            assert(lit.lit.type==Tok!"0",text("TODO: ",lit));
            return lit;
        }
        else if(auto fe = cast(FieldExp)exp) {
            string fieldstring = inFieldVar(prgname, fe.f.name, 0); 
            return state.mapping[fieldstring];
            return fe;
        }
        else if(auto be = cast(ABinaryExp)exp) {

            Expression e1 = substituteExpression(be.e1, state, prgname);
            Expression e2 = substituteExpression(be.e2, state, prgname);
            Expression myBin = new MyBinExp(e1, be.operator, e2);
            return myBin;
        }
        else if(auto be = cast(UnaryExp!(Tok!"!"))exp) {
            be.e = substituteExpression(be.e, state, prgname);
            return be;
        }

        else if(auto id = cast(Identifier)exp) {
            Expression* e = (id.name in state.mapping);
            if (e !is null) {
                return *e;
            }
            else if(id.name == "port") {
                return state.mapping[inPortVar(prgname, 0)];
            }
            return id;
        }
        /*
           else if(auto call = cast(CallExp)exp) {
           if(auto fname = cast(Identifier)call.e) {
           assert(fname.name == "flip", text("TODO: ", exp));
           numFlips++;
           string flipName = "flip_"~to!string(numFlips);
           return new Identifier(flipName);
           }
           return call;
           }
         */
        assert(0,text("TODO: ",exp));
    }

    // Prepend prgname to Identifiers to ensure names are unique
    Expression changeStateVarName(Expression exp, string prgname) {
        if(auto lit = cast(LiteralExp)exp) {
            assert(lit.lit.type==Tok!"0",text("TODO: ",lit));
            return lit;
        }
        else if(auto fe = cast(FieldExp)exp) {
            return fe;
        }
        else if(auto be = cast(ABinaryExp)exp) {

            Expression e1 = changeStateVarName(be.e1, prgname);
            Expression e2 = changeStateVarName(be.e2, prgname);
            Expression myBin = new MyBinExp(e1, be.operator, e2);
            return myBin;
        }
        else if(auto be = cast(UnaryExp!(Tok!"!"))exp) {
            be.e = changeStateVarName(be.e, prgname);
            return be;
        }

        else if(auto id = cast(Identifier)exp) {
            if(id.name == "port") {
                return id;
            }
            return new Identifier(prgname~"_"~id.name);
        }
        else if(auto call = cast(CallExp)exp) {
            return call;
        }
         
        assert(0,text("TODO: ",exp));
    }

    ProgramPath getAllExecutions(Expression stm, ProgramPath paths) {
        if(auto be=cast(ABinaryExp)stm){

            if(cast(BinaryExp!(Tok!"="))be){
                Identifier id = cast(Identifier)be.e1;
                FieldExp fe = cast(FieldExp)be.e1;
                if(id && id.name in paths.states[0].mapping) {
                    paths.updateState(id.name, be.e2);
                }
                else if (fe){
                    string fieldstring = inFieldVar(paths.prgname, fe.f.name, 0); 
                    if(fieldstring in paths.states[0].mapping) {
                        paths.updateState(fieldstring, be.e2);
                    }
                    else {
                        writeln("TODO: FieldExp: " ~ fe.toString() ~ " " ~ fieldstring);
                        writeln(be);
                    }
                }
                else {
                    write("TODO: BinaryExp: ");
                    writeln(be);
                    paths.replaceFlips(be.e2);
                }
                return paths;
            }else assert(0,text(stm));
        }else if(auto ite=cast(IteExp)stm){
            ProgramPath p1 = paths.copy();
            ProgramPath p2 = paths.copy();

            p1.updateCondition(ite.cond);
            p1 = getAllExecutions(ite.then, p1);
            p2.numFlips = p1.numFlips;          // Keep flip counts correct
            p2.flipProbs = p1.flipProbs;          // Keep flip counts correct
            p2.updateCondition(new UnaryExp!(Tok!"!")(ite.cond));
            p2 = getAllExecutions(ite.othw, p2);

            paths.states = new State[p1.states.length + p2.states.length];
            paths.states[] = p1.states ~ p2.states;
            paths.numFlips = p2.numFlips;
            paths.flipProbs = p2.flipProbs;

            return paths;
        }else if(auto be=cast(BuiltInExp)stm){
            // TODO: Replace with builtin state changes
            if(be.which==Tok!"new") {
                ProgramPath p = getAllExecutions(generateNew(paths.prgname, paths.inCapacity, paths.fields), paths);
                return p;
            }
            if(be.which==Tok!"dup") return paths;
            if(be.which==Tok!"drop") {
                ProgramPath p = getAllExecutions(generateDrop(paths.prgname, paths.inCapacity, paths.fields), paths);
                return p;
            }
        }else if(auto ce=cast(CallExp)stm){
            auto be=cast(BuiltInExp)ce.e;
            assert(be&&be.which==Tok!"fwd");
            assert(ce.args.length==1);
            ProgramPath p = getAllExecutions(generateFwd(paths.prgname, paths.inCapacity, paths.fields, ce.args[0]), paths);
            return p;
        }else if(auto ce=cast(CompoundExp)stm){
            if(ce.s.length){
                foreach(int i, Expression expr;ce.s){
                    paths = getAllExecutions(expr, paths); 
                }
            }
            return paths;
        }
        return paths;
        //assert(0,text("TODO: ",stm));
    }

    ProgramPath getAllExecutions(Expression stm, string[] vars, string prgname, string[] packetFields) {

        ProgramPath paths =  getAllExecutions(stm, new ProgramPath(vars, prgname, packetFields));
        return paths;
    }
}


string translate(Expression[] exprs, PrismBuilder bld){
    Expression[][typeof(typeid(Object))] byTid;
    foreach(expr;exprs){
        assert(cast(Declaration)expr && expr.sstate==SemState.completed,text(expr));
        byTid[typeid(expr)]~=expr;
    }
    auto all(T)(){ return cast(T[])byTid.get(typeid(T),[]); }
    auto topology=all!TopologyDecl[0];
    foreach(n;topology.nodes) bld.addNode(n.name.name);
    foreach(l;topology.links) bld.addLink(l.a,l.b);
    auto params=all!ParametersDecl.length?all!ParametersDecl[0]:null;
    if(params) foreach(prm;params.params) bld.addParam(prm);
    auto pfld=all!PacketFieldsDecl[0];
    foreach(f;pfld.fields) bld.addPacketField(f.name.name);
    auto pdcl=all!ProgramsDecl[0];
    bld.addNumSteps(all!NumStepsDecl[0]);
    if(all!QueueCapacityDecl.length) bld.addQueueCapacity(all!QueueCapacityDecl[0]);
    foreach(q;all!QueryDecl) bld.addQuery(q);
    void translateFun(FunctionDef fdef){
        auto prg=bld.addProgram(fdef.name.name, fdef.body_);
        if(fdef.state)
            foreach(sd;fdef.state.vars)
                prg.addState(sd.name.name,sd.init_);

        string[] packetFields = bld.packetFields.map!(p => p.name).array;
        //PrismProgramTranslator ppt = new PrismProgramTranslator();
        //PrismProgramTranslator.ProgramPath paths = ppt.getAllExecutions(fdef.body_, prg.stateSet.keys, prg.name, packetFields);
    }
    foreach(fdef;all!FunctionDef){
        if(fdef.name.name=="scheduler") bld.addScheduler(fdef);
        else translateFun(fdef);
    }
    foreach(m;pdcl.mappings) bld.addProgram(m.node.name,m.prg.name);
    foreach(p;all!PostObserveDecl) bld.addPostObserve(p.e);
    return bld.toPRISM();
}
