# QPLEX Python Package

<p align="center">
<img src="https://qplex.org/assets/images/qplex_landscape.png" height="150">
</p>

QPLEX is a computational methodology for modeling and analyzing a broad class of nonstationary stochastic systems with large state spaces.
QPLEX calculations are deterministic and approximate. For an overview of the QPLEX methodology, see the [QPLEX book](https://qplex.org/book). 

This repository contains source for the **QPLEX Python Package**, a collection of software tools that perform calculations for a number of standard stochastic models supported by the QPLEX methodology. These represent a very small subset of models supported by the QPLEX methodology. It is possible to extend the package with the [Q Development Kit](https://github.com/qplex/qdk).


## Main features

You can use the QPLEX Python Package to perform the following types of analysis:

* Calculate the *transient* distributions of the number of entities
  in a multiserver queue.  A plot of the distributions produced by the package is shown below. 

    <p align="center">
    <img src="https://qplex.org/assets/images/pmfs_over_time.gif" height="300">
    </p>

* Calculate the *transient* distributions of the number of entities
  at each node of a network of multiserver queues with probabilistic routing.  

* Find the minimum number of servers in a multiserver queueing system required to meet
  a service level requirement.  

* Given an observed value of the number of entities in a multiserver queueing system, predict the 
  distribution of the number of entities at some future time.  If the likelihood that
  too many entities will be in the system at that time, predict how this likelihood will change
  as a result of increasing the number of servers.

* Calculate the *posterior* probabilities of demand scenarios given observed values of 
  the number of entities at each node of a network of multiserver queues with probabilistic routing.  


## Documentation

The official documentation is avaiable [here](https://qplex.org/documentation/). 

## How to get it

Using the QPLEX Python Package requires Python 3. 
Binary installers for the latest released version are available at the [Python Package Index (PyPI)](https://pypi.org/project/qplex/).
Install the QPLEX Python Package as follows:

    pip3 install qplex

If you get this error message:

    ERROR: Could not build wheels for qplex, which is required to install pyproject.toml-based projects

then a pre-built binary package is unavailable for your environment and you first need to install a C++ compiler.  We recommend Xcode (Mac), MSVC (Windows), and GCC (Linux).

## Building from the source

The QPLEX Python Package is written in the [Q language](https://github.com/qplex/qdk), which we created for developing and extending this package.
Building the QPLEX Python Package from the Q source 
requires Ant, a C++ compiler, Java (JRE 1.8 or later), Python 3, and the Python packages Setuptools and Wheel.
