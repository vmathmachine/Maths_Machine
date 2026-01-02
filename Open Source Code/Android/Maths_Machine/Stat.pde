import java.util.Comparator;
import java.util.Arrays;

//norm, unif, discUnif, binom, pois, exp, chi2, chi, erlang, t, cauchy, geom, negBinom, logNorm, laplace,
//beta, f, hypGeo

//gamma, invGamma,
//As well as possibly:
//pareto, ray, weibull

static Complex mean(Complex[] inps) {
  if(inps.length==0) { return new Complex(); }
  Complex sum = new Complex();
  for(Complex inp : inps) { sum.addeq(inp); }
  return sum.diveq(inps.length);
}

static Complex variance(Complex[] inps, boolean sample) {
  if(inps.length<=1) { return new Complex(); }
  
  Complex sum = new Complex(), sumsq = new Complex();
  for(Complex inp : inps) { sum.addeq(inp); sumsq.addeq(inp.mul(inp)); }
  double inv = 1d/inps.length;
  sumsq.subeq(sum.sq().mul(inv));
  
  return sample ? sumsq.diveq(inps.length-1) : sumsq.muleq(inv);
}

static Complex std(Complex[] inps, boolean sample) { return variance(inps, sample).sqrt(); }

static Complex[] cums(Complex[] inps, int amt, boolean sample) {
  Complex[] cums = new Complex[amt+1];
  cums[0] = Cpx.zero();
  if(amt==0) { return cums; }
  
  int len = inps.length;
  double inv = 1d/len;
  Complex mean = Cpx.zero();
  for(Complex inp : inps) { mean.addeq(inp); }
  mean.muleq(inv);
  cums[1] = mean;
  
  if(amt==1) { return cums; }
  
  for(int n=2;n<cums.length;n++) { cums[n] = new Complex(); }
  
  Complex diff = new Complex();
  
  for(Complex inp : inps) {
    diff.set(inp); diff.subeq(mean);
    Complex pow = diff.copy();
    for(int n=2;n<cums.length;n++) {
      pow.muleq(diff);
      cums[n].addeq(pow);
    }
  }
  
  if(sample) {
    if(amt>=6) { throw new RuntimeException("Sample cumulants not implemented past 5th"); }
    if(amt>=5) { cums[5].muleq(len+5d).subeq(Cpx.mul(10d*(len-1), cums[2],cums[3])).muleq(len/((len-1d)*(len-2)*(len-3)*(len-4))); }
    if(amt>=4) { cums[4].muleq(len*(len+1d)/((len-1d)*(len-2)*(len-3))).subeq(cums[2].sq().muleq(3d/((len-2d)*(len-3)))); }
    if(amt>=3) { cums[3].muleq(len/((len-1d)*(len-2))); }
    cums[2].diveq(len-1d);
  } else {
    for(int n=2;n<cums.length;n++) { cums[n].muleq(inv); }
    if(amt>=4) { cums[4].subeq(cums[2].sq().muleq(3)); }
    if(amt>=5) { cums[5].subeq(Cpx.mul(10,cums[2],cums[3])); }
    if(amt>=6) { cums[6].subeq(Cpx.mul(15d,cums[2],cums[4].add(cums[2].sq()))).subeq(cums[3].sq().muleq(10)); } //yes, it's all accounted for, the fact these were already edited and whatnot
    //if(amt>=7) { cums[7].subeq(Cpx.mul(21d,cums[2],cums[5]).subeq(Cpx.mul(35d,cums[3],cums[4])).subeq(
    
    if(amt>=7) { throw new RuntimeException("Non-sample cumulants not implemented past 6th"); }
  }
  
  return cums;
}

static Complex[] normCums(Complex[] inps, int amt, boolean sample) {
  Complex[] cums = cums(inps, amt, sample);
  
  if(cums.length>3) {
    Complex factor = cums[2].inv();
    Complex stdInv = factor.sqrt();
    for(int n=3;n<cums.length;n++) {
      factor.muleq(stdInv);
      cums[n].muleq(factor);
    }
  }
  
  return cums;
}

static Complex[] linReg(Complex[] x, Complex[] y) {
  double inv = 1d/x.length;
  Complex xbar=Cpx.zero(), ybar=Cpx.zero(), sxx=Cpx.zero(), sxy=Cpx.zero(), syy=Cpx.zero();
  for(int i=0;i<x.length;i++) {
    xbar.addeq(x[i]); ybar.addeq(y[i]);
    sxx.addeq(x[i].sq()); sxy.addeq(x[i].mul(y[i])); syy.addeq(y[i].sq());
  }
  xbar.muleq(inv); ybar.muleq(inv);
  sxx.muleq(inv).subeq(xbar.sq());
  sxy.muleq(inv).subeq(xbar.mul(ybar));
  syy.muleq(inv).subeq(ybar.sq());
  
  Complex m = sxy.div(sxx);
  Complex b = ybar.sub(m.mul(xbar));
  Complex r2 = sxy.sq().div(sxx.mul(syy));
  
  return new Complex[] {m, b, r2};
}

static class ComplexComparator implements Comparator<Complex> {
  @Override public int compare(Complex a, Complex b) {
    int order = Double.compare(a.re, b.re);
    return order==0 ? Double.compare(a.im,b.im) : order;
  }
}

static Complex range(Complex[] vals) {
  Complex min = new Complex(Mafs.INF,Mafs.INF), max = new Complex(-Mafs.INF,-Mafs.INF);
  ComplexComparator comp = new ComplexComparator();
  for(Complex val : vals) {
    if(comp.compare(val,min)<0) { min.set(val); }
    if(comp.compare(val,max)>0) { max.set(val); }
  }
  return max.sub(min);
}

static Complex median(Complex[] vals) {
  Arrays.sort(vals, new ComplexComparator());
  int len = vals.length;
  if((len&1)==1) { return vals[len>>1]; }
  return vals[len>>1].add(vals[(len>>1)-1]).muleq(0.5d);
}

static Complex quantile(double area, Complex[] vals) throws CalculationException {
  if(area<0 || area>1) { throw new CalculationException("Cannot evaluate quantile with area unbounded by [0,1]"); }
  Arrays.sort(vals, new ComplexComparator());
  if(area==0) { return vals[0]; } if(area==1) { return vals[vals.length-1]; }
  double pivot = vals.length*area;
  int ind1 = (int)Math.floor(pivot), ind2 = (int)Math.ceil(pivot)-1;
  if(ind1==ind2) { return vals[ind1]; }
  else { return vals[ind1].add(vals[ind2]).muleq(0.5d); }
}



static double factHalf(int inp) { // (n/2)!
  if((inp&1)==0) { return Mafs.factorial(inp>>1); }
  if(inp>0) {
    double prod = 1;
    for(int i=3;i<=inp;i+=2) {
      prod *= 0.5*i;
    }
    return Mafs.ROOTPI2*prod;
  }
  else {
    double prod = 1;
    for(int i=1;i>inp;i-=2) {
      prod*=0.5*i;
    }
    return Mafs.ROOTPI2/prod;
  }
}



static Complex normPDF(Complex x, Complex mu, Complex sigma) {
  return x.sub(mu).diveq(sigma).sq().muleq(-0.5).exp().diveq(sigma.mul(2*Mafs.ROOT2*Mafs.ROOTPI2));
}

static Complex normCDF(Complex x, Complex mu, Complex sigma) {
  Complex z = x.sub(mu).diveq(sigma);
  return Cpx2.cumulative_distribution(z);
}

static Complex qNorm(Complex a, Complex mu, Complex sigma) {
  return mu.sub(Cpx3.invErfc(a.mul(2)).muleq(sigma).muleq(Mafs.ROOT2));
}

static double unifPDF(double inp, double left, double right) {
  return inp>=left && inp<right ? 1/(right-left) : 0;
}

static double unifCDF(double inp, double left, double right) {
  return inp<left ? 0 : inp>=right ? 1 : (inp-left)/(right-left);
}

static double qUnif(double inp, double left, double right) {
  return inp<=0 || inp>=1 ? Double.NaN : inp*(right-left)+left;
}

static double discUnifPMF(double inp, long left, long right) {
  return inp==(long)inp && inp>=left && inp<=right ? 1d/(right-left+1) : 0;
}

static double discUnifCDF(double inp, long left, long right) {
  return inp<left ? 0 : inp>=right ? 1 : Math.floor(inp-left+1)/(right-left+1);
}

static double qDiscUnif(double inp, long left, long right) {
  return inp==0 ? Double.NEGATIVE_INFINITY : inp<0 || inp>1 ? Double.NaN : left+Math.ceil(inp*(right-left+1)-1);
}

static double nCrInt(int n, int r) {
  if(r<0 || r>n) { return 0; }
  double ncr = 1d;
  r = Math.min(r, n-r);
  for(int k=1;k<=r;k++) {
    ncr*=(n-k+1d)/k;
  }
  return ncr;
}

static double binomPMF(int k, int n, double p) {
  return nCrInt(n,k)*Mafs.pow(p,k)*Mafs.pow(1-p,n-k);
}

static double binomCDF(int k, int n, double p) {
  if((k<<1) > n) { return 1-binomCDF(n-k-1, n, 1-p); } //apply reflection formula
  
  if(k<0) { return 0; } //special case out of bounds (is reflected to other bound)
  if(p==0) { return k>=0 ? 1 : 0; } //special cases p=0 and p=1
  if(p==1) { return k>=n ? 1 : 0; }
  
  double sum = 0;
  //for(int i=0;i<=k;i++) { sum += binomPMF(i,n,p); }
  double pmf = Mafs.pow(1-p,n), ratio = p/(1-p);
  for(int i=0;i<=k;i++) {
    sum += pmf;
    if(i!=k) { pmf*=ratio*(n-i)/(i+1d); }
  }
  
  return sum;
}

static double qBinom(double inp, int n, double p, boolean lower) { //this evaluates the binomial quartile w/out optimization, but with a check as to if the multivalued points return the top or bottom value
  if(inp<0 || inp>1) { return Double.NaN; }
  if(inp==0) { return lower ? Double.NEGATIVE_INFINITY : 0; }
  if(inp==1) { return lower ? n : Double.POSITIVE_INFINITY; }
  if(p==0) { return 0; } //in the case of p=0, all the mass is concentrated at x=0
  if(p==1) { return n; } //in the case of p=1, all the mass is concentrated at x=n
  
  double sum = 0;
  double pmf = Mafs.pow(1-p,n), ratio = p/(1-p);
  for(int i=0;i<=n;i++) { //loop through values
    sum += pmf;
    if(sum > inp || lower && sum == inp) { return i; } //the moment the CDF surpasses our area, return the index
    if(i!=n) { pmf*=ratio*(n-i)/(i+1d); }
  }
  return n;
}

static double qBinom(double inp, int n, double p) { //this evaluates binomial quartile w/ optimization
  if(p>0.5 || p==0.5 && inp>0.5*n) {
    return qBinom(1-inp, n, 1-p, false);
  }
  return qBinom(inp, n, p, true);
}

static int randBinom(int n, double p) {
  int sum = 0;
  for(int i=0;i<n;i++) {
    if(Math.random() <= p) { ++sum; }
  }
  return sum;
}

static double poisPMF(int inp, double l) {
  return Math.exp(-l)*Mafs.pow(l,inp)/Mafs.factorial(inp);
}

static double poisCDF(int inp, double l) {
  double sum = 0; //the sum
  double term = Math.exp(-l); //the term we add each time
  for(int i=0;i<=inp;i++) {
    sum += term;
    if(i!=inp) { term *= l/(i+1); }
  }
  return sum;
}

static double expPDF(double inp, double l) {
  return inp>=0 ? l*Math.exp(-l*inp) : 0;
}

static double expCDF(double inp, double l) {
  return inp>=0 ? 1-Math.exp(-l*inp) : 0;
}

static double qExp(double inp, double l) {
  return inp<0 || inp>1 ? Double.NaN : -Math.log(1-inp)/l;
}

static double randExp(double l) {
  return -Math.log(1-Math.random())/l;
}

static double qPois(double inp, double l) { //TODO deal with when the input is high
  if(inp<0 || inp>1) { return Double.NaN; }
  if(inp==0) { return Double.NEGATIVE_INFINITY; }
  if(l==0)   { return 0; }
  if(inp==1) { return Double.POSITIVE_INFINITY; }
  
  double sum = 0;
  double term = Math.exp(-l);
  for(int i=0;true;i++) { //loop through values
    sum += term;
    if(sum >= inp) { return i; } //the moment the CDF surpasses our area, return the index
    term *= l/(i+1);
  }
}

static int randPois(double l) {
  if(l==0) { return 0; }
  
  double L = Math.exp(-l);
  double prod = Math.random();
  int k = 0;
  
  while(prod > L) {
    ++k;
    prod *= Math.random();
  }
  
  return k;
}

static double gammaPDF(double inp, double alpha, double l) {
  if(inp<0) { return 0; }
  return Math.pow(inp*l,alpha-1)*inp*Math.exp(-l*inp)/Cpx2.gamma(new Complex(alpha)).re;
}

static double gammaCDF(double inp, double alpha, double l) {
  throw new RuntimeException("Incomplete gamma function not yet implemented");
}

static double qGamma(double a, double alpha, double l) {
  throw new RuntimeException("Incomplete gamma function not yet implemented");
}

static double randGamma(double alpha, double l) {
  throw new RuntimeException("I couldn't figure out how to randomize gamma, sorry");
}

static double invGammaPDF(double inp, double alpha, double l) {
  if(inp<=0) { return 0; }
  double recip = 1d/inp;
  return gammaPDF(recip, alpha, l)*recip*recip;
}

static double invGammaCDF(double inp, double alpha, double l) {
  return 1-gammaCDF(1d/inp, alpha, l);
}

static double qInvGamma(double a, double alpha, double l) {
  return 1d/qGamma(a,alpha,l);
}

static double randInvGamma(double alpha, double l) { return 1d/randGamma(alpha, l); }



static double chi2PDF(double inp, int df) {
  if(df==0) { return inp==0 ? Mafs.INF : 0; }
  if(inp<0) { return 0; }
  inp*=0.5;
  
  double pow = 0.5*Mafs.pow(inp,(df>>1)-1);
  if((df&1)==1) { pow *= Math.sqrt(inp); }
  pow *= Math.exp(-inp)/factHalf(df-2);
  
  return pow;
}

/*
An important algorithm for the rest of this:
To calculate s = Σ[k=a,b] F(k)/G(k), given that F(k+1)/F(k)=f(k) and G(k+1)/G(k)=g(k):

F = F(a)
S = F
for(int k=a;k<b;k++) {
  F *= f(k)
  S = S*g(k) + F
}
s = S/G(b)
*/

static double chi2CDF(double inp, int df) {
  if(inp<0) { return 0; }
  if(df==0) { return inp==0 ? 0.5 : inp>0 ? 1 : 0; }
  
  double F = 1, S = 1;
  for(int i=df-2;i>1;i-=2) {
    F *= 0.5*i;
    S = S*0.5*inp + F;
  }
  S *= Math.exp(-0.5*inp);
  if((df&1)==1) {
    double root = Math.sqrt(0.5*inp);
    double erf = Cpx2.erf(new Complex(root)).re;
    return df==1 ? erf : erf - S*root/(F*Cpx.ROOTPI2);
  }
  else {
    return 1 - S/F;
  }
}

static double qChi2(double a, int df) {
  //throw new RuntimeException("Quantile for χ and χ² are not yet implemented");
  if(a<0 || a>1) { return Double.NaN; }
  if(df==0) { return a==0 ? Double.NEGATIVE_INFINITY : 0; }
  if(df==1) { return 2*Mafs.sq(Cpx3.invErf(new Complex(a)).re); }
  if(df==2) { return -2*Math.log(1-a); }
  
  double inv;
  if(a<0.75) {
    inv = 2*Math.pow(a*factHalf(df), 2d/df);
  }
  else {
    inv = -2*Math.log((1-a)*factHalf(df-2));
  }
  
  for(int i=0;i<10;i++) {
    double inv0 = inv;
    double f0 = chi2CDF(inv,df)-a;
    double f1 = chi2PDF(inv,df);
    double f2 = 0.5*f1*((df-2)/inv-1);
    inv -= f0*f1/(f1*f1-0.5*f0*f2);
    if(inv==inv0) { break; }
  }
  
  return inv;
}

static double randChi2(int df) {
  //here, we just add up the squares of df squared N(0,1)'s. However, since N(0,1)^2+N(0,1)^2 ~ exp(lambda=1/2), we can make our work a bit easier
  double rand = randErlang(df>>1, 0.5); //add up a bunch of exponential distributions
  if((df&1)==1) { rand += Mafs.sq(random.nextGaussian()); } //and, if df is odd, we add one more squared Gaussian
  return rand;
}

static double chiPDF(double inp, int df) {
  return inp<=0 ? 0 : 0.5*inp*chi2PDF(inp*inp, df);
}

static double chiCDF(double inp, int df) { return chi2CDF(inp*inp, df); }

static double qChi(double a, int df) { return Math.sqrt(qChi2(a,df)); }

static double randChi(int df) { return Math.sqrt(randChi2(df)); }

static double erlangPDF(double inp, int df, double l) {
  return 2*l*chi2PDF(2*l*inp, df<<1);
}

static double erlangCDF(double inp, int df, double l) {
  return chi2CDF(2*l*inp, df<<1);
}

static double qErlang(double a, int df, double l) {
  return qChi2(a, df<<1)/(2*l);
}

static double randErlang(int df, double l) {
  double prod = 1;
  for(int i=0;i<df;i++) {
    prod *= (1-Math.random());
  }
  
  return -Math.log(prod)/l;
}

static double tPDF(double inp, double df) {
  double gamma1 = Cpx2.loggamma(new Complex(0.5*(df+1))).re;
  double gamma2 = Cpx2.loggamma(new Complex(0.5*df)).re;
  double logTerm = Math.log(1+inp*inp/df);
  return Math.exp(gamma1-gamma2-0.5*(df+1)*logTerm)/Math.sqrt(Math.PI*df);
}

static double tCDF(double inp, int df) {
  if(df==0) { return inp==0 ? 0.5 : inp>0 ? 1 : 0; }
  if(df==1) { return Math.atan(inp)/Math.PI+0.5; }
  
  inp/=Math.sqrt(df);
  double B = 1+inp*inp;
  
  double F = 1, S = 1;
  for(int k=0;k<df/2-1;k++) {
    F *= (0.5*df-1-k)*B;
    S = S*(0.5*df-1.5-k) + F;
  }
  S *= inp;
  
  if((df&1)==0) {
    S /= (F*2*Math.sqrt(B));
  }
  else {
    S /= (F*B*Math.PI);
    S += Math.atan(inp)/Math.PI;
  }
  
  return S + 0.5;
}

static double qT(double a, int df) {
  if(a<0 || a>1) { return Double.NaN; }
  if(df==1) { return Math.tan(Math.PI*(a-0.5)); }
  if(df==2) { return (2*a-1)/Math.sqrt(2*a*(1-a)); }
  double q;
  double factor = 2*Mafs.ROOTPI2*factHalf(df-2)/factHalf(df-1);
  if(a<0.25) { q = -Math.pow(factor*Math.pow(df,1-0.5*df)*a, -1d/df); }
  else if(a<0.75) { q = factor*(a-0.5)*Math.sqrt(df); }
  else { q = Math.pow(factor*Math.pow(df,1-0.5*df)*(1-a), -1d/df); }
  
  for(int i=0;i<10;i++) {
    double q0 = q;
    double f0 = tCDF(q,df)-a;
    double f1 = tPDF(q,df);
    double f2 = -(df+1)*q*f1/(df+q*q);
    q -= f0*f1/(f1*f1-0.5*f0*f2);
    if(q==q0) { break; }
  }
  
  return q;
}

static double randT(int df) {
  return random.nextGaussian()*Math.sqrt(df/randChi2(df));
}


static double cauchyPDF(double inp, double x0, double g) {
  return g/(Math.PI*(g*g+Mafs.sq(inp-x0)));
}

static double cauchyCDF(double inp, double x0, double g) {
  return Math.atan((inp-x0)/g)/Math.PI + 0.5;
}

static double qCauchy(double a, double x0, double g) {
  return x0 + g*Math.tan(Math.PI*(a-0.5));
}

static double randCauchy(double x0, double g) { return qCauchy(Math.random(),x0,g); }


static double geomPMF(int fail, double p) {
  return fail<0 ? 0 : Mafs.pow(1-p,fail)*p;
}

static double geomCDF(int k, double p) {
  return k<0 ? 0 : 1-Mafs.pow(1-p,k+1);
}

static double qGeom(double a, double p) {
  if(a<0 || a>1) { return Double.NaN; }
  if(a==0) { return Double.NEGATIVE_INFINITY; }
  if(a==1) { return Double.POSITIVE_INFINITY; }
  
  return Math.floor(Math.log1p(-a)/Math.log1p(-p));
}

static int randGeom(double p) {
  return (int)Math.floor(Math.log1p(-Math.random())/Math.log1p(p));
}


static double negBinomPMF(int fail, int pass, double p) {
  if(pass==0) { return fail==0 ? 1 : 0; }
  
  return nCrInt(pass+fail-1,fail)*Mafs.pow(1-p,fail)*Mafs.pow(p,pass);
}

static double negBinomCDF(int fail, int pass, double p) {
  if(pass==0) { return fail>0 ? 1 : 0; }
  
  double sum = 0;
  for(int k=0;k<=fail;k++) { sum += negBinomPMF(k, pass, p); }
  
  return sum;
}

static double qNegBinom(double a, int pass, double p) {
  if(a<0 || a>1) { return Double.NaN; }
  if(a==0) { return Double.NEGATIVE_INFINITY; }
  if(a==1) { return Double.POSITIVE_INFINITY; }
  
  double sum = 0;
  int k; for(k=0;sum<a;k++) {
    sum += negBinomPMF(k, pass, p);
  }
  
  return k-1;
}

static double randNegBinom(int pass, double p) { return qNegBinom(Math.random(), pass, p); }

static Complex logNormPDF(Complex inp, Complex mu, Complex sigma) {
  return normPDF(inp.log(), mu, sigma).div(inp);
}

static Complex logNormCDF(Complex inp, Complex mu, Complex sigma) {
  return normCDF(inp.log(), mu, sigma);
}

static Complex qLogNorm(Complex a, Complex mu, Complex sigma) {
  return qNorm(a, mu, sigma).exp();
}

static Complex randLogNorm(Complex mu, Complex sigma) {
  return sigma.mul(random.nextGaussian()).addeq(mu).exp();
}

static double laplacePDF(double inp, double mu, double b) {
  double bInv = 1d/b;
  return 0.5*bInv*Math.exp(-Math.abs(inp-mu)*bInv);
}

static double laplaceCDF(double inp, double mu, double b) {
  double exp = 0.5*Math.exp(-Math.abs(inp-mu)/b);
  return inp>=mu ? 1-exp : exp;
}

static double qLaplace(double a, double mu, double b) {
  double log = b*Math.log(2*Math.min(a,1-a));
  return a<=0.5 ? mu+log : mu-log;
}

static double randLaplace(double mu, double b) {
  boolean bool = random.nextBoolean();
  double rand = b*Math.log(1-Math.random());
  return bool ? mu+rand : mu-rand;
}
