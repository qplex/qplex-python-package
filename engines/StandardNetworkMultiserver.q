public PmfArray{Z,L} internalState;
public int time;

IntArray numberOfServers;
PmfArray numberOfExternalArrivalsPmfs;
PmfArray serviceDurationPmfs;
RealMatrix routingProbabilities;

PmfArray{Z,L} markInternalState;
int markTime;
IntArray markNumberOfServers;
PmfArray markNumberOfExternalArrivalsPmfs;
PmfArray markServiceDurationPmfs;
RealMatrix markRoutingProbabilities;

void init(int numberOfNodes) {
    if (numberOfNodes <= 0) {
        fail "Invalid number of nodes. The number of nodes must be strictly positive.";
    }

    internalState = createPmfArray(numberOfNodes);
    time = 0;
    numberOfServers = createIntArray(numberOfNodes);
    numberOfExternalArrivalsPmfs = createPmfArray(numberOfNodes);
    serviceDurationPmfs = createPmfArray(numberOfNodes);
    for (nodeIndex = 0 to numberOfNodes-1) {
        serviceDurationPmfs[nodeIndex] = {1: 1.0};
    }
    routingProbabilities = createRealMatrix(numberOfNodes, numberOfNodes);

    markInternalState = createPmfArray(numberOfNodes);
    markNumberOfServers = createIntArray(numberOfNodes);
    markNumberOfExternalArrivalsPmfs = createPmfArray(numberOfNodes);
    markServiceDurationPmfs = createPmfArray(numberOfNodes);
    for (nodeIndex = 0 to numberOfNodes-1) {
        markServiceDurationPmfs[nodeIndex] = {1: 1.0};
    }
    markRoutingProbabilities = createRealMatrix(numberOfNodes, numberOfNodes);
}

Pmf convolution(Pmf p1, Pmf p2) {
    x ~ p1;
    y ~ p2;
    return x + y;
}

Pmf flow(int sourceNodeIndex, int destinationNodeIndex) {
    z ~ internalState[sourceNodeIndex]{Z};
    d ~ binomial(min(z,numberOfServers[sourceNodeIndex]), internalState[sourceNodeIndex]{L|Z=z}[1] );
    phi ~ binomial(d, routingProbabilities[sourceNodeIndex][destinationNodeIndex]);
    return phi;
}

Pmf relabel(int nodeIndex, int z) {
    ell ~ internalState[nodeIndex]{L|Z=z};
    if (ell == 1) {
        skip;
    }
    return ell-1;
}

Pmf{Z} partialQplexMapAtNode(int nodeIndex, Pmf internalFlowIn) {
    z ~ internalState[nodeIndex]{Z};
    d ~ binomial(min(z,numberOfServers[nodeIndex]), internalState[nodeIndex]{L|Z=z}[1] );
    phi ~ binomial(d, routingProbabilities[nodeIndex][nodeIndex]);
    a ~ convolution(numberOfExternalArrivalsPmfs[nodeIndex], internalFlowIn);
    return z - d + phi + a;
}

Pmf{Z,L} qplexMapAtNode(int nodeIndex, Pmf internalFlowIn, int leftTail, int rightTail) {
    z ~ internalState[nodeIndex]{Z};
    d ~ binomial(min(z,numberOfServers[nodeIndex]), internalState[nodeIndex]{L|Z=z}[1] );
    phi ~ binomial(d, routingProbabilities[nodeIndex][nodeIndex]);
    a ~ convolution(numberOfExternalArrivalsPmfs[nodeIndex], internalFlowIn);
    int zprime = z - d + phi + a;
    if ((zprime < leftTail) || (zprime > rightTail)) {skip;}

    if (zprime == 0  || numberOfServers[nodeIndex] == 0) {
        ellprime ~ serviceDurationPmfs[nodeIndex];
        return zprime, ellprime;
    }
    entityIsOld ~ bernoulli( (min(z,numberOfServers[nodeIndex])-d) / min(zprime,numberOfServers[nodeIndex]) );
    if (entityIsOld == 1) {
        ellprime ~ relabel(nodeIndex, z);
        return zprime, ellprime;
    } else {
        ellprime ~ serviceDurationPmfs[nodeIndex];
        return zprime, ellprime;
    }
}

Pmf{Z,L} observationMapRangeAtNode(int nodeIndex, int z0, int z1) {
    z, ell ~ internalState[nodeIndex];
    if (z < z0 || z >= z1) {
        skip;
    }
    return z, ell;
}

Pmf{Z,L} resetMapAtNode(int nodeIndex, int z0) {
    ell ~ serviceDurationPmfs[nodeIndex];
    return z0, ell;
}

public void step() {
    real tolerance = 1e-8;
    int numberOfNodes = numberOfServers.length;
    PmfArray flowIn = createPmfArray(numberOfNodes);

    for (sourceNodeIndex = 0 to numberOfNodes-1) {
        real sourceSum = 0.0;
        for (destinationNodeIndex = 0 to numberOfNodes-1) {
            sourceSum = sourceSum + routingProbabilities[sourceNodeIndex][destinationNodeIndex];
        }
        if (sourceSum > 1.0) {
            fail "Invalid routing probabilities. Sum of destination probabilities exceeds 1.";
        }
    }

    for (sourceNodeIndex = 0 to numberOfNodes-1) {
        for (destinationNodeIndex = 0 to sourceNodeIndex-1) {
            flowIn[destinationNodeIndex] = convolution(flowIn[destinationNodeIndex], flow(sourceNodeIndex, destinationNodeIndex));
        }
        for (destinationNodeIndex = sourceNodeIndex+1 to numberOfNodes-1) {
            flowIn[destinationNodeIndex] = convolution(flowIn[destinationNodeIndex], flow(sourceNodeIndex, destinationNodeIndex));
        }
    }
    for (nodeIndex = 0 to numberOfNodes-1) {
        Pmf{Z} p = partialQplexMapAtNode(nodeIndex, flowIn[nodeIndex]);
        int leftTail = computeLeftTail(p, tolerance/2);
        int rightTail = computeRightTail(p, tolerance/2);
        internalState[nodeIndex] = qplexMapAtNode(nodeIndex, flowIn[nodeIndex], leftTail, rightTail);
    }
    time = time + 1;
}

public void applyObservationRangeAtNode(int nodeIndex, int startOfRange, int endOfRange) {
    internalState[nodeIndex] = observationMapRangeAtNode(nodeIndex, startOfRange, endOfRange);
}

public void applyObservationValueAtNode(int nodeIndex, int observedNumberOfEntitiesInSystem) {
    internalState[nodeIndex] = observationMapRangeAtNode(nodeIndex, observedNumberOfEntitiesInSystem, observedNumberOfEntitiesInSystem+1);
}

public void mark() {
    markTime = time;
    for (nodeIndex = 0 to numberOfServers.length-1) {
        markInternalState[nodeIndex] = internalState[nodeIndex];
        markNumberOfServers[nodeIndex] = numberOfServers[nodeIndex];
        markNumberOfExternalArrivalsPmfs[nodeIndex] = numberOfExternalArrivalsPmfs[nodeIndex];
        markServiceDurationPmfs[nodeIndex] = serviceDurationPmfs[nodeIndex];
        for (nodeIndexDest = 0 to numberOfServers.length-1) {
            markRoutingProbabilities[nodeIndex][nodeIndexDest] = routingProbabilities[nodeIndex][nodeIndexDest];
        }
    }
}

public void restore() {
    time = markTime;
    for (nodeIndex = 0 to numberOfServers.length-1) {
        internalState[nodeIndex] = markInternalState[nodeIndex];
        numberOfServers[nodeIndex] = markNumberOfServers[nodeIndex];
        numberOfExternalArrivalsPmfs[nodeIndex] = markNumberOfExternalArrivalsPmfs[nodeIndex];
        serviceDurationPmfs[nodeIndex] = markServiceDurationPmfs[nodeIndex];
        for (nodeIndexDest = 0 to numberOfServers.length-1) {
            routingProbabilities[nodeIndex][nodeIndexDest] = markRoutingProbabilities[nodeIndex][nodeIndexDest];
        }
    }
}

public Pmf getNumberOfEntitiesAtNodePmf(int nodeIndex) {
    return internalState[nodeIndex]{Z};
}

public Pmf getNumberOfExternalArrivalsAtNodePmf(int nodeIndex) {
    return numberOfExternalArrivalsPmfs[nodeIndex];
}

public int getNumberOfNodes() {
    return numberOfServers.length;
}

public int getNumberOfServersAtNode(int nodeIndex) {
    return numberOfServers[nodeIndex];
}

public real getRoutingProbability(int sourceNodeIndex, int destinationNodeIndex) {
    return routingProbabilities[sourceNodeIndex][destinationNodeIndex];
}

public Pmf getServiceDurationAtNodePmf(int nodeIndex) {
    return serviceDurationPmfs[nodeIndex];
}

public void setNumberOfExternalArrivalsAtNodePmf(int nodeIndex, Pmf numberOfExternalArrivalsPmf) {
    numberOfExternalArrivalsPmfs[nodeIndex] = numberOfExternalArrivalsPmf;
}

public void setNumberOfServersAtNode(int nodeIndex, int n) {
    if (n < 0) {
        fail "Invalid number of servers. The number of servers must be nonnegative.";
    }
    numberOfServers[nodeIndex] = n;
}

public void setRoutingProbability(int sourceNodeIndex, int destinationNodeIndex, real probability) {
    if (probability < 0.0 || probability > 1.0) {
        fail "Invalid probability. Probabilities must be between 0 and 1.";
    }
    routingProbabilities[sourceNodeIndex][destinationNodeIndex] = probability;
}

public void setServiceDurationAtNodePmf(int nodeIndex, Pmf serviceDurationPmf) {
    if (serviceDurationPmf.minValue == 0) {
        fail "Invalid service duration pmf. Service durations must be strictly positive.";
    }
    serviceDurationPmfs[nodeIndex] = serviceDurationPmf;
}

public void resetNodeWithNumberOfEntities(int nodeIndex, int numberOfEntitiesAtNode) { 
    if (numberOfEntitiesAtNode < 0) {
         fail "Invalid number of entities. The number of entities must be nonnegative.";
    }
    internalState[nodeIndex] = resetMapAtNode(nodeIndex, numberOfEntitiesAtNode);
}

