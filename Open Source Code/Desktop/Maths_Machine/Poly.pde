public static class Polynomial implements Iterable<Term> {
  /////////////// ATTRIBUTES /////////////////
  
  HashMap<Term, Complex> terms = new HashMap<Term, Complex>(); //the list of all the terms, paired with their corresponding numerical coefficient
  
  /////////////// CONSTRUCTORS ///////////////////
  
  Polynomial() { } //default constructor forms 0
  
  Polynomial(Object[][] trms) { //forms from list whose elements are each pairs of the coefficient and term
    for(Object[] obj : trms) { //loop through all the terms
      addTerm((Complex)obj[0], (Term)obj[1]); //add each term multiplied by the correct coefficient
    }
  }
  
  Polynomial(Object[][][] trms) { //forms from list whose elements are each lists of first 2 numbers (frac coef), then of variables & their powers
    for(Object[][] arr : trms) { //loop through all the terms
      Complex coef = new Complex(((Number)arr[0][0]).doubleValue(), ((Number)arr[0][1]).doubleValue()); //grab coefficient
      Term term = new Term(arr, 1); //grab term
      addTerm(coef, term); //add each term times their coefficient
    }
  }
  
  //////////////// GETTERS / SETTERS /////////////////////
  
  public boolean hasTerm(Term term) { return terms.containsKey(term); }
  public Complex getCoef(Term term) { return hasTerm(term) ? terms.get(term) : Cpx.zero(); }
  
  public int size() { return terms.size(); }
  public boolean isEmpty() { return terms.isEmpty(); }
  
  private void addTerm(Complex coef, Term term) {
    if(coef.equals(0)) { return; } //TODO see if this is necessary
    
    Complex coef2 = getCoef(term).add(coef); //find the new coefficient for this term
    if(coef2.equals(0)) { terms.remove(term); } //if 0, remove term
    else { terms.put(term, coef2); } //otherwise, set the term to that coefficient
  }
  
  //////////////// INHERITED METHODS /////////////////////
  
  @Override public boolean equals(final Object obj) {
    return obj instanceof Polynomial && ((Polynomial)obj).terms.equals(terms);
  }
  
  @Override Polynomial clone() {
    Polynomial clone = new Polynomial();
    clone.terms = (HashMap<Term,Complex>)terms.clone();
    return clone;
  }
  
  @Override public int hashCode() { return ~terms.hashCode(); }
  
  @Override public String toString() {
    return toString(-1);
  }
  
  public String toString(int dig) {
    if(isEmpty()) { return "0"; }
    
    StringBuilder sb = new StringBuilder();
    boolean began=false;
    
    List<Term> sorted = new ArrayList<>(terms.keySet()); //in order to display these in a logical order,
    sorted.sort(Term.comparator); //we will sort these by power of earliest token
    
    for(Term term : sorted) {
      Complex coef = terms.get(term);
      
      /*if(began && (term.isEmpty() ? coef.isRoot() : ) { sb.append("+"); } //put + signs before numbers that don't start with a - sign
      
      if(term.isEmpty()) { sb.append(coef); }
      else {
        if(coef.equals(-1)) { sb.append("-"); }
        else if(!coef.equals(1)) { sb.append(coef).append("*"); }
        
        sb.append(term);
        //TODO test
      }*/
      
      if(began && !(coef.im==0 && coef.re<0)) { sb.append("+"); } //put a plus sign between terms (unless it's a negative term)
      
      if(term.isEmpty()) { //if the term is empty, just print the coefficient
        if(coef.im==0) { sb.append(coef.toString(dig)); }
        else { sb.append("(").append(coef).append(")"); } //if complex, wrap in parentheses
      }
      else {
        if(coef.equals(-1)) { sb.append("-"); } //if the term is -1, just put a - sign
        else if(coef.im!=0) { sb.append("(").append(coef.toString(dig)).append(")"); } //if the term is complex, put in the coefficient wrapped in parentheses
        else if(!coef.equals(1)) { sb.append(coef.toString(dig)); } //otherwise, just put in the coefficient (unless it's 1, then don't)
        
        sb.append(term);
        //TODO test
      }
      
      began = true;
    }
    return sb.toString();
  }
  
  @Override Iterator<Term> iterator() { return new Iterator<Term>() {
    private Iterator<Map.Entry<Term, Complex>> iter = terms.entrySet().iterator();
    
    @Override boolean hasNext() { return iter.hasNext(); }
    @Override Term next() { return iter.next().getKey(); }
  }; }
  
  //////////////////////// ARITHMETIC //////////////////////////
  
  public Polynomial add(Polynomial p) { return clone().addeq(p); }
  public Polynomial sub(Polynomial p) { return clone().subeq(p); }
  
  private Polynomial addeq(Polynomial p) {
    for(Map.Entry<Term,Complex> entry : p.terms.entrySet()) {
      addTerm(entry.getValue(), entry.getKey()); //add each term multiplied by the correct coefficient
    }
    return this;
  }
  
  private Polynomial subeq(Polynomial p) {
    for(Map.Entry<Term,Complex> entry : p.terms.entrySet()) {
      addTerm(entry.getValue().neg(), entry.getKey()); //add each term multiplied by the correct coefficient
    } //TODO see if you should add a "subTerm" method?
    return this;
  }
  
  public Polynomial neg() {
    Polynomial prod = new Polynomial();
    for(Map.Entry<Term,Complex> entry : terms.entrySet()) {
      prod.terms.put(entry.getKey(), entry.getValue().neg());
    }
    return prod;
  }
  
  public Polynomial negeq() {
    HashMap<Term, Complex> newTerms = new HashMap<Term, Complex>(terms.size()); //create replacement hashmap
    for(Map.Entry<Term,Complex> term : terms.entrySet()) { //loop through all entries
      newTerms.put(term.getKey(), term.getValue().neg()); //put the same entry in, but negated
    }
    terms = newTerms; //replace the terms
    return this;      //return result
  }
  
  public Polynomial mul(Complex f) {
    if(f.equals(0)) { return new Polynomial(); }
    
    Polynomial prod = new Polynomial();
    for(Map.Entry<Term,Complex> entry : terms.entrySet()) {
      prod.terms.put(entry.getKey(), entry.getValue().mul(f));
    }
    return prod;
  }
  public Polynomial mul(double d) {
    if(d==0) { return new Polynomial(); }
    
    Polynomial prod = new Polynomial();
    for(Map.Entry<Term,Complex> entry : terms.entrySet()) {
      prod.terms.put(entry.getKey(), entry.getValue().mul(d));
    }
    return prod;
  }
  public Polynomial muleq(Complex f) {
    if(f.equals(0)) { terms.clear(); return this; }
    
    for(Map.Entry<Term,Complex> entry : terms.entrySet()) {
      entry.getValue().muleq(f);
    }
    return this;
  }
  public Polynomial muleq(double d) {
    if(d==0) { terms.clear(); return this; }
    
    for(Map.Entry<Term,Complex> entry : terms.entrySet()) {
      entry.getValue().muleq(d);
    }
    return this;
  }
  public Polynomial diveq(Complex f) { return muleq(f.inv()); }
  public Polynomial diveq(double d) { return muleq(1d/d); }
  
  
  public Polynomial mul(Term t) {
    if(t.isEmpty()) { return clone(); }
    
    Polynomial prod = new Polynomial();
    for(Map.Entry<Term,Complex> entry : terms.entrySet()) {
      prod.terms.put(entry.getKey().mul(t), entry.getValue());
    }
    return prod;
  }
  
  public Polynomial mul(Complex f, Term t) {
    if(f.equals(0)) { return new Polynomial(); }
    if(f.equals(1)) { return mul(t); }
    if(t.isEmpty()) { return mul(f); }
    
    Polynomial prod = new Polynomial();
    for(Map.Entry<Term,Complex> entry : terms.entrySet()) {
      prod.terms.put(entry.getKey().mul(t), entry.getValue().mul(f));
    }
    return prod;
  }
  
  public Polynomial div(Complex f) { return mul(f.inv()); }
  public Polynomial div( double d) { return mul(1d/d); }
  public Polynomial div(Term t) { return mul(t.inv()); }
  public Polynomial div(Complex f, Term t) { return mul(f.inv(), t.inv()); }
  
  
  
  
  public Polynomial mul(Polynomial p) {
    Polynomial prod = new Polynomial();
    
    for(Map.Entry<Term,Complex> entry : p.terms.entrySet()) {
      prod.addeq(mul(entry.getValue(), entry.getKey()));
    }
    
    return prod;
  }
  
  public Polynomial sq() { return mul(this); }
  
  public Polynomial pow(int pow) { //TODO make this non-recursive
    if(pow<0) { throw new IllegalArgumentException("Cannot raise polynomial to negative power"); }
    if(pow==0) { return new Polynomial(new Object[][][] {{{1,0}}}); }
    if(pow==1) { return clone(); }
    
    Polynomial f = pow(pow>>1).sq();
    return (pow&1)==0 ? f : f.mul(this);
  }
  
  
  ////////////////// PLUG ///////////////////////
  
  Polynomial plug(Term template, Polynomial replacement) {
    Polynomial result = new Polynomial();
    
    for(Term term : this) {
      int log = term.log(template); //find how many times this term is divisible by the template
      if(log==0) {
        result.addTerm(getCoef(term), term); // if it's not divisible at all, just add this term as is
      } else { //otherwise,
        Term remainder = term.logRemainder(template, log); //compute the logarithmic remainder
        result.addeq(replacement.pow(log).mul(getCoef(term), remainder)); //add the replacement to the power of the logarithm, multiplied by the remainder
      }
    }
    return result;
  }
  
  
  
  ////////////////// DIFFERENTIATION //////////////////
  
  Polynomial partialDiff(String wrt) {
    Polynomial result = new Polynomial();
    
    for(Term term : this) {
      int pow = term.getPow(wrt);
      if(pow==0) { continue; }
      result.addTerm(getCoef(term).mul(new Complex(pow)), term.div(new Token(wrt)));
    }
    
    return result;
  }
}
