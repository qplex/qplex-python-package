public Pmf numberOfArrivalsPmf;
public Pmf serviceDurationPmf;
public int numberOfServers;
public Pmf{Z,L} internalState;
public int time;

Pmf markNumberOfArrivalsPmf;
Pmf markServiceDurationPmf;
int markNumberOfServers;
Pmf{Z,L} markInternalState;
int markTime;

void init() {
    serviceDurationPmf = {1: 1.0};
}

Pmf relabel(int z) {
    ell ~ internalState{L|Z=z};
    if (ell == 1) {
        skip;
    }
    return ell-1;
}

Pmf{Z} partialQplexMap() {
    z ~ internalState{Z};
    d ~ binomial(min(z,numberOfServers), internalState{L|Z=z}[1] );
    a ~ numberOfArrivalsPmf;
    return z - d + a;
}

Pmf{Z,L} qplexMap(int leftTail, int rightTail) {
    z ~ internalState{Z};
    d ~ binomial(min(z,numberOfServers), internalState{L|Z=z}[1] );
    a ~ numberOfArrivalsPmf;
    int zprime = z - d + a;
    if ((zprime < leftTail) || (zprime > rightTail)) {skip;}

    if (zprime == 0 || numberOfServers == 0) {
        ellprime ~ serviceDurationPmf;
        return zprime, ellprime;
    }
    entityIsOld ~ bernoulli( (min(z,numberOfServers)-d) / min(zprime,numberOfServers) );
    if (entityIsOld == 1) {
        ellprime ~ relabel(z);
        return zprime, ellprime;
    } else {
        ellprime ~ serviceDurationPmf;
        return zprime, ellprime;
    }
}

Pmf{Z,L} observationMapRange(int z0, int z1) {
    z, ell ~ internalState;
    if (z < z0 || z >= z1) {
        skip;
    }
    return z, ell;
}

Pmf{Z,L} resetMap(int z0) {
    ell ~ serviceDurationPmf;
    return z0, ell;
}

public void step() {
    if (numberOfServers < 0) {
        fail "Invalid number of servers. The number of servers must be nonnegative.";
    }
    if (serviceDurationPmf.minValue == 0) {
        fail "Invalid service duration pmf. Service durations must be strictly positive.";
    }

    real tolerance = 1e-8;
    Pmf{Z} p = partialQplexMap();
    int leftTail = computeLeftTail(p, tolerance/2);
    int rightTail = computeRightTail(p, tolerance/2);
    internalState = qplexMap(leftTail, rightTail);
    time = time + 1;
}

public void applyObservationRange(int startOfRange, int endOfRange) {
    internalState = observationMapRange(startOfRange, endOfRange);
}

public void applyObservationValue(int observedNumberOfEntitiesInSystem) {
    internalState = observationMapRange(observedNumberOfEntitiesInSystem, observedNumberOfEntitiesInSystem+1);
}

public void mark() {
    markNumberOfArrivalsPmf = numberOfArrivalsPmf;
    markServiceDurationPmf = serviceDurationPmf;
    markNumberOfServers = numberOfServers;
    markInternalState = internalState;
    markTime = time;
}

public void restore() {
    numberOfArrivalsPmf = markNumberOfArrivalsPmf;
    serviceDurationPmf = markServiceDurationPmf;
    numberOfServers = markNumberOfServers;
    internalState = markInternalState;
    time = markTime;
}

public Pmf getNumberOfEntitiesInSystemPmf() {
    return internalState{Z};
}

public void resetWithNumberOfEntitiesInSystem(int numberOfEntitiesInSystem) {
    if (numberOfEntitiesInSystem < 0) {
        fail "Invalid number of entities. The number of entities must be nonnegative.";
    }
    if (serviceDurationPmf.minValue == 0) {
        fail "Invalid service duration pmf. Service durations must be strictly positive.";
    }
    internalState = resetMap(numberOfEntitiesInSystem);
}

