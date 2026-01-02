public static class Term implements Iterable<Token> { // Represents the product of powers of variables. These are added up together to form a polynomial.
  ///////////////// ATTRIBUTES /////////////////
  
  private HashMap<String,Integer> tokens = new HashMap<String,Integer>(); //all the tokens, represented as a mapping from variables as strings to powers as integers
  
  //////////////// CONSTRUCTORS //////////////////
  
  Term() { } //default constructor
  
  Term(Token... ts) {
    for(Token t : ts) { multiplyByToken(t.getVar(), t.getPow()); }
  }
  
  Term(Object[][] os, int startInd) {
    for(int i = startInd; i<os.length; i++) {
      Object[] o = os[i];
      if(o.length!=2) { throw new IllegalStateException("Object array must exclusively contain length-2 arrays"); }
      multiplyByToken((String)o[0], (Integer)o[1]);
    }
  }
  
  Term(Object[][] os) { this(os, 0); }
  
  ////////////////// GETTERS / SETTERS ///////////////////////
  
  public int getPow(String v) { return tokens.getOrDefault(v, 0); } //get the power of a specific variable
  public boolean hasVar(String v) { return tokens.containsKey(v); }
  
  public int size() { return tokens.size(); }
  public boolean isEmpty() { return tokens.isEmpty(); }
  
  
  private HashMap<String,Integer> copyTokens() { return (HashMap<String,Integer>)tokens.clone(); }
  
  
  private void multiplyByToken(String v, int p) { //ONLY TO BE USED IN CONSTRUCTION
    if(p==0) { return; } //TODO see if necessary
    int pow = getPow(v) + p;
    
    if(pow==0) { tokens.remove(v);  }
    else       { tokens.put(v,pow); }
  }
  
  private void setPow(String v, int p) { //ONLY TO BE USED IN CONSTRUCTION
    if(p==0) { tokens.remove(v); }
    else     { tokens.put(v,p);  }
  }
  
  ///////////////// INHERITED METHODS ////////////////////////
  
  @Override public boolean equals(final Object obj) {
    return obj instanceof Term && tokens.equals(((Term)obj).tokens);
  }
  
  @Override Term clone() {
    Term copy = new Term();
    copy.tokens = copyTokens();
    return copy;
  }
  
  @Override public int hashCode() { return tokens.hashCode(); }
  
  @Override public String toString() { // TODO make it alphabetize the variables
    if(isEmpty()) { return "1"; }
    
    List<String> keys = new ArrayList<>(tokens.keySet());
    Collections.sort(keys); //sort all the tokens in lexicographical order
    
    StringBuilder result = new StringBuilder(); //init result
    
    boolean useTimes = false; //whether to use a times symbol
    for(String key : keys) { //loop through strings alphabetically
      if(useTimes) { result.append("*"); } //if told to, append a times sign
      result.append(key); //list the token
      
      int power = tokens.get(key); //take the power
      switch(power) {
        case 1: useTimes=true; break; //^1: don't list the power, but do put in a * sign if there's a next token
        case 2: useTimes=false; result.append("²"); break; //^2: use the squared symbol. Don't use * sign
        default: useTimes=false; result.append("^").append(power); break; //Otherwise, just list the power. Again, we don't need a times sign
      }
    }
    
    return result.toString(); //return result
  }
  
  @Override public Iterator<Token> iterator() { return new Iterator<Token>() {
    private Iterator<Map.Entry<String,Integer>> iter = tokens.entrySet().iterator(); //allows us to iterate through the token list
    
    public boolean hasNext() { return iter.hasNext(); }
    public Token next() {
      Map.Entry<String,Integer> entry = iter.next();
      return new Token(entry.getKey(), entry.getValue());
    }
  }; }
  
  ///////////////// ARITHMETIC //////////////////////
  
  public Term mul(Token t) {
    Term prod = clone();
    prod.multiplyByToken(t.getVar(), t.getPow());
    return prod;
  }
  
  public Term mul(Term t) {
    Term prod = clone();
    for(Token tok : t) { prod.multiplyByToken(tok.getVar(), tok.getPow()); }
    return prod;
  }
  
  public Term div(Token t) {
    Term quot = clone();
    quot.multiplyByToken(t.getVar(), -t.getPow());
    return quot;
  }
  
  public Term div(Term t) {
    Term quot = clone();
    for(Token tok : t) { quot.multiplyByToken(tok.getVar(), -tok.getPow()); }
    return quot;
  }
  
  public Term inv() {
    Term inv = new Term();
    for(Token t : this) {
      inv.tokens.put(t.getVar(), -t.getPow());
    }
    return inv;
  }
  
  public Term sq() {
    Term sq = new Term();
    for(Token t : this) {
      sq.tokens.put(t.getVar(), t.getPow()<<1);
    }
    return sq;
  }
  
  public Term pow(final int p) {
    Term power = new Term();
    if(p!=0) { for(Token t : this) {
      power.tokens.put(t.getVar(), t.getPow()*p);
    } }
    return power;
  }
  
  
  
  
  
  public int log(final Term base) { //find how many times we are divisible by this base w/out having negative exponents
    //NOTE: we assume this is only being used for non-negative exponents
    
    if(base.isEmpty()) { throw new ArithmeticException("Cannot take a base 1 logarithm of a polynomial term"); }
    
    int log = Integer.MAX_VALUE; //the logarithm
    for(Map.Entry<String,Integer> entry : base.tokens.entrySet()) { //we need to loop through the tokens in the base
      int powBase = entry.getValue(), powMe = getPow(entry.getKey()); //find the power for both the base and this thing
      
      log = min(log, powMe/powBase); //find how many timees the base fits into this. The end result is the minimum among tokens
      if(log==0) { break; } //short circuit
    }
    
    return log; //return the computed logarithm
  }
  
  public Term logRemainder(final Term base, final int log) {
    Term rem = new Term();
    
    for(Map.Entry<String,Integer> entry : tokens.entrySet()) {
      String key = entry.getKey();
      rem.setPow(key, entry.getValue()-log*base.getPow(key));
    }
    
    return rem;
  }
  
  
  
  public static Comparator<Term> comparator = new Comparator<Term>() { //we can use this to determine which order to show terms
    @Override public int compare(Term a, Term b) {
      Set<String> union = new HashSet<>(a.tokens.keySet()); union.addAll(b.tokens.keySet()); //take the set of tokens in either term
      List<String> sorted = new ArrayList<>(union); Collections.sort(sorted); //now sort them lexicographically
      
      for(String s : sorted) {
        int powDiff = Integer.compare(b.getPow(s), a.getPow(s)); //compare a's power of this to b's power of this
        if(powDiff!=0) { return powDiff; } //if nonzero, return result. Otherwise, continue to next token
      }
      
      return 0; //if they both have the same tokens raised to the same powers, then they're equal
    }
  };
}
