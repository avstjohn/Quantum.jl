Quantum Mechanics in Julia
===================

Julia is an up-and-coming language for scientific computing that promises a
high-level of abstraction without the performance sacrifice such abstraction
usually entails. The capabilities of this new language provide an optimized
codebase for tackling various problems in physics, which are often
simultaneously conceptually difficult and computationally intensive.

Many similar technologies - Mathematica, MATLab, NumPy, to name a few - have
garnered support from the quantum physics community due to the wide variety of
third-party physics libraries available. There are usually at least one or two
projects for a given language that are dedicated to implementing quantum
mechanics operations using Dirac notation in a manner that is idiomatic to the
language.

If Julia is to properly compete with these other languages, it should have
such a library available.

Enter my capstone project: Quantum.jl.

In addition to providing the basic functionality that many Dirac algebra
implementations provide, my capstone will provide a system for storing,
manipulating, and analyzing subspaces of the Hilbert space. In other words,
users should be able to define their own bases, and define operators and
states in terms of those bases.

Objectives
==========

###Design and implement a library in Julia that can perform the following tasks:
	- basis, state, and operator instantiation
	- basic arithmetic operations 
	- application of selection rules to extract subspaces
	- convert state vector to density matrix
	- take trace/partial trace of matrices (entanglement calculations)
	- parameterization of matrices/matrix elements
	- basis conversion for both operators and state vectors
	- compute expectation values of the form <v|M|v>
	- compute transition matrices of the form <u|M|v>
	- binary operations on states/operators (e.g. inner/outer product)
	- a fully realized tensor product structure for bases
	- commutation relations of operators
	- In-place operations (e.g. conjugate transpose)

###I also have a small list of optional goals which I would like to attempt, but may not have time for in a single semester:
	- HDF5 support
	- design a system for data visualization of common state properties/operations
	- package Quantum.jl as an open-source library that other Julia users can utilize