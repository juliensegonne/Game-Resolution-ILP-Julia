# Project: Integer Linear Programming for Puzzle Games

## Description

This project focuses on solving two distinct puzzle games, **Bridges** and **Singles**, using integer linear programming (ILP) techniques. Both games require mathematical modeling and computational methods to find feasible and optimal solutions while respecting the given constraints.

The project includes:
1. Formal problem modeling.
2. Computational implementation using ILP solvers.
3. Analysis of solution methods and performance evaluation.

---

## Game 1: Bridges

### Game Overview
In Bridges, players must connect a set of nodes on a grid using 1 or 2 bridges per connection. Bridges must be placed horizontally or vertically, without crossing each other, and each node must have a specific number of bridges attached.

### Problem Modeling
- Objective function: **None** (feasibility problem).
- Constraints:
  - The number of bridges matches the node’s requirement.
  - Bridges between nodes are symmetric.
  - No more than two bridges can connect two nodes.
  - Bridges cannot cross each other.

### Implementation
1. **Instance Creation**:
   - Generate a grid with random nodes and connections based on the desired density.
   - Ensure no overlapping or crossing of bridges.
   
2. **Instance Resolution**:
   - Use the **CPLEX solver** to validate feasibility by satisfying all constraints.
   - Return solution feasibility, decision variable values, and runtime.

3. **Graphical Display**:
   - Visualize both unresolved and resolved grids in the console for better interpretation.

### Results
- Performance analysis indicates that grid size impacts solving time more significantly than density.
- Solutions are always feasible up to a grid size of 21x21 with moderate density. Larger grids may require specialized techniques for instance generation.

---

## Game 2: Singles

### Game Overview
Singles is a grid puzzle where numbers must be masked to ensure:
1. Each number appears at most once per row and column.
2. Masked cells are not adjacent.
3. Remaining visible cells form a connected component.

### Problem Modeling
- Objective function: **None** (feasibility problem).
- Constraints:
  - Numbers are unique per row and column.
  - No two masked cells are adjacent.
  - All visible cells must be connected.

### Implementation
1. **Instance Creation**:
   - Generate a randomized grid with a single occurrence of each number per row and column.
   - Randomly mask cells while maintaining connectivity and density requirements.

2. **Instance Resolution**:
   - Use the **CPLEX solver** to enforce all constraints.
   - Return feasibility, decision variables, and runtime.

3. **Heuristic Method**:
   - Prioritize masking frequently occurring numbers.
   - Start masking from corners to prevent isolated cells.

4. **Graphical Display**:
   - Provide a clean, minimal console visualization of both unresolved and resolved grids.

### Results
- The heuristic method shows limitations on larger grids.
- ILP consistently finds feasible solutions up to 10x10 grids, with runtime increasing for larger instances.

---

## Tools and Requirements

- **ILP Solver**: CPLEX.
- **Programming Language**: Julia.

---

## Structure of Deliverables

- **Code**: Includes scripts for instance generation, ILP modeling, and result visualization.
- **Report**: Detailed explanation of methods, results, and analysis.

---

## Authors
- **Baptiste Montagnes**
- **Julien Segonne**

---
