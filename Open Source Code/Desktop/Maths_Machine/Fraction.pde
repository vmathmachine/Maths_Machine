import java.math.BigInteger;

public static class Fraction extends Number implements Comparable<Fraction> { //immutable fraction
  
  ///////////////// ATTRIBUTES ////////////////////////
  
  private BigInteger num; //numerator   (any integer)
  private BigInteger den; //denominator (always positive, should never be 0)
  
  ///////////////// CONSTRUCTORS ////////////////////////
  
  Fraction() { num=BigInteger.ZERO; den=BigInteger.ONE; } //default constructor (initialize to 0)
  
  Fraction(final BigInteger n, final BigInteger d) { num=n; den=d; checkDenom(); reduce(); } //constructor given numerator & denominator (also ensures reduction & denominator can't be negative)
  Fraction(final BigInteger n)                     { num=n; den=BigInteger.ONE;            } //constructor given integer numerator, with denominator set to 1
  
  private Fraction(final BigInteger n, final BigInteger d, final boolean t) { num=n; den=d; } //constructor given num & den, but WITHOUT reduction (only use when you can guarantee it's already reduced)
  
  Fraction(final long  n, final long  d) { this(BigInteger.valueOf(n), BigInteger.valueOf(d)); } //create the same n/d constructor given any regular integer datatype (casted to longs)
  Fraction(final long  n)                { this(BigInteger.valueOf(n));                        } //create the same n/1 constructor given any regular integer datatype
  
  Fraction(final String inp) { //construct from a String
    int ind = inp.indexOf('/'); //find the divide sign
    if(ind==-1) { num = new BigInteger(inp); den = BigInteger.ONE; } //if there's no divide sign, cast int to fraction
    else { num = new BigInteger(inp.substring(0,ind)); den = new BigInteger(inp.substring(ind+1)); checkDenom(); reduce(); } //if there is, cast each string to an integer, then check denominator and reduce
  }
  
  ///////////////// INHERITED METHODS //////////////////////
  
  @Override
  public Fraction clone() { return new Fraction(num, den, true); } //returns a deep copy
  
  @Override
  boolean equals(final Object obj) {
    return obj instanceof Fraction && num.equals(((Fraction)obj).num) && den.equals(((Fraction)obj).den); //returns whether they equal
  }
  
  @Override
  int hashCode() { return num.hashCode()*31 + den.hashCode(); }
  
  @Override
  String toString() { //returns result as a string
    String result = num.toString();   //create numerator as string
    if(!den.equals(BigInteger.ONE)) { //if denominator isn't 1:
      result += "/"+den.toString();   //concat a / and the denominator
    }
    return result;
  }
  
  ///////////////// GENERAL UTILITIES //////////////////////
  
  Fraction copy() { return new Fraction(num, den, true); } //returns a deep copy
  
  int compareTo(Fraction f) { //compares 2 fractions (inequality)
    BigInteger cross = num.multiply(f.den).subtract(f.num.multiply(den)); //cross multiply numerator & denominator
    return cross.signum();                                                //returns 1 if +, -1 if -, 0 if 0
  }
  
  /////////////////////// OTHER UTILITIES ////////////////////////
  
  private void checkDenom() { if(den.signum()==-1) { num=num.negate(); den=den.negate(); } } //ensures denominator is not negative
  
  private Fraction reduce() { //reduces fraction to its simplest form
    if(den.equals(BigInteger.ZERO)) { throw new ArithmeticException("Cannot form fraction with 0 denominator"); }
    
    BigInteger gcd = num.gcd(den);    //find the gcd
    if(!gcd.equals(BigInteger.ONE)) { //if it's not 1:
      num = num.divide(gcd); den = den.divide(gcd); //divide the num & den by the gcd
    }
    return this;
  }
  
  //////////////////// INEQUALITIES ////////////////////
  
  boolean nEquals(Fraction f) { return !equals(f);       }
  boolean greater(Fraction f) { return compareTo(f)==1;  }
  boolean less   (Fraction f) { return compareTo(f)==-1; }
  boolean gEquals(Fraction f) { return compareTo(f)!=-1; }
  boolean lEquals(Fraction f) { return compareTo(f)!=1;  }
  
  boolean equals(long l) { return den.equals(BigInteger.ONE) && num.equals(BigInteger.valueOf(l)); } //returns true if it's an integer & the numerator equals the long
  boolean nEquals(long l) { return !equals(l); }
  
  /////////////////////// GETTERS /////////////////////////
  
  BigInteger getNum() { return num; } //get numerator
  BigInteger getDen() { return den; } //get denominator
  
  //////////////// ARITHMETIC /////////////////////
  
  Fraction add(Fraction a) { //returns the sum
    BigInteger num1 = num.multiply(a.den); //find num1*den2
    BigInteger num2 = a.num.multiply(den); //find den1*num2
    return new Fraction(num1.add(num2), den.multiply(a.den)); //add numerators, multiply denominators (auto reduce)
  }
  
  Fraction sub(Fraction a) { //returns the difference
    BigInteger num1 = num.multiply(a.den); //find num1*den2
    BigInteger num2 = a.num.multiply(den); //find den1*num2
    return new Fraction(num1.subtract(num2), den.multiply(a.den)); //subtract numerators, multiply denominators (auto reduce)
  }
  
  Fraction mul(Fraction a) { //returns the product
    return new Fraction(num.multiply(a.num), den.multiply(a.den)); //multiply num*num & den*den (auto reduce)
  }
  
  Fraction div(Fraction a) { //returns the quotient
    return new Fraction(num.multiply(a.den), den.multiply(a.num)); //multiply num*den & den*num (auto reduce)
  }
  
  Fraction inv() { //returns the reciprocal
    Fraction inv = new Fraction(den, num, true); //flip numerator & denominator
    inv.checkDenom();                            //check denominator
    return inv;                                  //return result
  }
  
  Fraction neg() { return new Fraction(num.negate(),den); } //returns the negative
  
  /*Fraction addeq(Fraction a)  { return set(add(a)); } //add-assign
  Fraction subeq(Fraction a)  { return set(sub(a)); } //sub-assign
  Fraction muleq(Fraction a)  { return set(mul(a)); } //mul-assign
  Fraction diveq(Fraction a)  { return set(div(a)); } //div-assign
  Fraction negeq() { num=num.negate(); return this; } //negate-assign
  Fraction inveq()            { return set(inv());  } //invert-assign*/
  
  //add, subtract, multiply, divide, exponenentiate
  //negate, invert, 
  
  ////////////////// MIXED/IMPROPER FRACTION STUFF //////////////////////
  
  float  floatValue () { return num. floatValue()/den. floatValue(); } //to float
  double doubleValue() { return num.doubleValue()/den.doubleValue(); } //to double
  
  int    intValue   () { return intPart().intValue (); } //to int
  long   longValue  () { return intPart().longValue(); } //to long
  
  BigInteger intPart() { //returns the integer part
    return num.divide(den); //do the built in division (and yes, the weird negative behavior is "desirable" here)
  }
  
  Fraction fracPart() { //returns the fractional part
    Fraction result = new Fraction(num.mod(den),den,true); //numerator % denominator
    if(num.signum()==-1 && !isInt()) {       //if negative and not an integer:
      result.num = result.num.subtract(den); //subtract from the numerator to make it negative
    }
    return result; //return result
  }
  
  BigInteger floor() { //returns the floor
    if(isInt()) { return num; } //if it's an integer, return the numerator
    
    if(isPositive()) { return intPart(); } //if it's positive, return the integer part
    else { return intPart().subtract(BigInteger.ONE); } //if it's negative, return the integer part - 1
  }
  
  BigInteger ceil() { //returns the ceiling
    if(isInt()) { return num; } //if it's an integer, return the numerator
    
    return floor().add(BigInteger.ONE); //otherwise, return the floor + 1
  }
  
  BigInteger round() { //rounds to the nearest integer (rounds up if it's halfway between)
    return add(new Fraction(1,2)).floor(); //incidentally, this is the same as adding 1/2, then taking the floor
  }
  
  Fraction fracPartPos() { //returns this minus the floor
    return new Fraction(num.mod(den),den,true); //numerator % denominator
  }
  
  ////////////////// OTHER MATHEMATICAL STUFF ///////////////////////////
  
  int signum() { return num.signum(); } //return the numerator's signum (since the denominator is positive)
  
  Fraction abs() { return new Fraction(num.abs(), den, true); } //absolute value
  
  Fraction pow(int n) { //raises fraction to integer power
    if(n==0) { return ONE; }                           //0 exponent: return 1
    if(n<0) { return inv().pow(-n); }                  //- exponent: return inverse to + exponent
    return new Fraction(num.pow(n), den.pow(n), true); //+ exponent: return num^n / den^n
  }
  Fraction sq() { return mul(this); } //return the square
  
  Fraction min(Fraction f) { //returns the minimum of the 2 fractions
    if(less(f)) { return this; } //if less than f, return a copy of this
    return f;                    //else, return a copy of f
  }
  Fraction max(Fraction f) { //returns the maximum of the 2 fractions
    if(greater(f)) { return this; } //if greater than f, return a copy of this
    return f;                       //else, return a copy of f
  }
  
  ///////////////// CLASSIFICATION ////////////////////////
  
  boolean isInt() { return den.equals(BigInteger.ONE); } //returns true if it's an integer
  boolean isPositive() { return signum()==1; }  boolean isNegative() { return signum()==-1; }  boolean isZero() { return signum()==0; } //sign classification
  boolean isWhole() { return den.equals(BigInteger.ONE) && signum()!=-1; } //returns true if it's a whole number (int >=0)
  boolean isNatural() { return den.equals(BigInteger.ONE) && signum()==1; } //returns true if it's a natural number (int >0)
  
  //////////////// CONSTANTS ///////////////////////
  
  final public static Fraction ZERO = new Fraction(BigInteger.ZERO, BigInteger.ONE, true);
  final public static Fraction  ONE = new Fraction(BigInteger. ONE, BigInteger.ONE, true);
  final public static Fraction  TWO = new Fraction(BigInteger.valueOf(2), BigInteger.ONE, true);
  final public static Fraction MINUS_ONE = new Fraction(BigInteger.valueOf(-1), BigInteger.ONE, true);
}
