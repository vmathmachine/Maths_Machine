public static class Token { // Represents a variable raised to an integer power. These are multiplied together to make Terms.
  
  /////////////////// ATTRIBUTES ////////////////////////////
  
  private String variable; //the variable name
  private int power;       //its power
  
  ////////////////// CONSTRUCTORS //////////////////////////
  
  Token(String v) { variable=v; power=1; }
  
  Token(String v, int p) {
    if(v==null) { throw new IllegalArgumentException(); }
    variable=v; power=p;
  }
  
  ////////////////// GETTERS / SETTERS ///////////////////////
  
  public String getVar() { return variable; }
  public int    getPow() { return    power; }
  
  //private void setVar(final String s) { variable=s; }
  //private void setPow(final    int p) { power   =p; }
  
  ////////////////// INHERITED METHODS ///////////////////////
  
  @Override boolean equals(final Object obj) {
    if(obj instanceof Token) {
      Token t = (Token)obj;
      return power==t.power && variable.equals(t.variable);
    }
    return false;
  }
  
  @Override Token clone() { return new Token(variable, power); }
  
  @Override int hashCode() { return 31*variable.hashCode() + power; }
  
  @Override String toString() {
    switch(power) {
      case 1: return variable;
      case 2: return variable+"²";
      default: return variable+"^"+power;
    }
  }
  
  ////////////// ARITHMETIC ///////////////////////
  
  Token inv() { return new Token(variable,-power); }
  Token sq() { return new Token(variable,power<<1); }
  Token pow(final int n) { return new Token(variable,power*n); }
}
