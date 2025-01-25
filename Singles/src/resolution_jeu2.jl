# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX
using JuMP
using MathOptInterface
include("io.jl")

# Matrices pour exemple rapide

A = [1 3 2 4 5;4 2 4 1 1;5 4 1 2 1;4 1 3 1 2;2 1 3 3 2]

B = [5 1 4 5 6 6;3 4 6 5 2 3;3 4 2 4 5 5;2 5 6 6 4 1;2 2 5 1 6 4;4 3 2 2 5 3]

C = [4 3 2 7 2 6 6 5;1 2 6 1 3 2 5 7;5 2 7 3 3 5 2 4;5 1 4 7 7 8 6 8;1 5 8 6 8 7 2 1;6 7 8 1 2 4 4 8;7 8 3 5 8 1 4 2;2 8 6 4 2 3 6 6]


"""
Solve an instance with CPLEX
"""
function cplexSolve(A::Matrix{Int64})

    n = size(A,1)

    # Create the model
    m = Model(CPLEX.Optimizer)

    # x[i, j, k] = 1 if cell (i, j) has value k
    @variable(m, x[1:n, 1:n, 0:n], Bin)

    # k=0 représente les cases noircies

    # chaque case a une valeur de k associée (pas de case vide sans k)
    @constraint(m, [i in 1:n, j in 1:n], x[i,j, A[i, j]] + x[i,j,0]==1)

    # Each line l has one cell with value k
    @constraint(m, [k in 1:n, l in 1:n], sum(x[l, j, k] for j in 1:n) <= 1)

    # Each column c has one cell with value k
    @constraint(m, [k in 1:n, c in 1:n], sum(x[i, c, k] for i in 1:n) <= 1)

    # Il n'y a pas de cases noires adjacentes
    @constraint(m,[i in 1:n-1, j in 1:n], x[i,j,0]+x[i+1,j,0] <= 1)
    @constraint(m,[i in 1:n, j in 1:n-1], x[i,j,0]+x[i,j+1,0] <= 1)

    # Les diagonales de cases noires sont interdites (séparation en 2 ensembles)
    @constraint(m,[j in 0:n-2], sum(x[i+j,i,0] for i in 1:n-j) <= n-j-1)
    @constraint(m,[j in 1:n-2], sum(x[i,i+j,0] for i in 1:n-j) <= n-j-1)

    @constraint(m,[j in 0:n-2], sum(x[i,n-i+1-j,0] for i in 1:n-j) <= n-j-1)
    @constraint(m,[j in 1:n-2], sum(x[i+j,n-i+1,0] for i in 1:n-j) <= n-j-1)
    
    # Les cases blanches isolées sont interdites
    # On gère les bords en premier
    for j in 2:n-1
        @constraint(m, x[1,j-1,0]+x[1,j+1,0]+x[2,j,0] <= 2)
        @constraint(m, x[n,j-1,0]+x[n,j+1,0]+x[n-1,j,0] <= 2)
    end
    for i in 2:n-1
        @constraint(m, x[i-1,1,0]+x[i+1,1,0]+x[i,2,0] <= 2)
        @constraint(m, x[i-1,n,0]+x[i+1,n,0]+x[i,n-1,0] <= 2)
    end

    #Puis les losanges du centre de la grille
    for i in 2:n-1
        for j in 2:n-1
            @constraint(m, [i in 2:n-1, j in 2:n-1], x[i+1,j,0]+x[i,j+1,0]+x[i-1,j,0]+x[i,j-1,0] <= 3)
        end
    end

    # Fonction objectif constante
    @objective(m, Max, 0)


    # Start a chronometer
    start = time()

    set_time_limit_sec(m, 60.0)

    # Solve the model
    optimize!(m)
    displaySolution(x)
    print("\n")
    return primal_status(m) == MOI.FEASIBLE_POINT, x, time() - start
end


"""
Heuristically solve an instance
"""
function heuristicSolve(grid::Matrix{Int64})
    n = size(grid, 1)
    masked_grid = copy(grid)
    
    # Calculer la fréquence de chaque chiffre dans la grille
    frequency = calculate_frequency(grid)
    
    # Sélectionner les chiffres les plus fréquents à masquer en priorité
    numbers_to_mask = [x for x in 1:9 if frequency[x] > 0]
    sorted_numbers_to_mask = sort(numbers_to_mask, by=x->frequency[x], rev=true)
    
    #Parcours les coins de la grille
    for i in [1,n], j in [1,n]
        num = grid[i, j]
        if num != 0
            # Vérifier s'il existe un voisin avec le même chiffre sur la même ligne et la même colonne
            if any(masked_grid[i, k] == num && k != j for k in 1:n) && any(masked_grid[k, j] == num && k != i for k in 1:n)
                masked_grid[i, j] = 0
            end
        end
    end

    # Parcourir chaque point de la grille par ordre de fréquence
    for num in sorted_numbers_to_mask
        for i in 1:n, j in 1:n
            if grid[i, j] == num
                # Vérifier s'il existe un voisin avec le même chiffre sur la même ligne et la même colonne
                if any(masked_grid[i, k] == num && k != j for k in 1:n) && any(masked_grid[k, j] == num && k != i for k in 1:n)
                    if can_mask_cell(masked_grid, i, j)
                        masked_grid[i, j] = 0
                    end
                end
            end
        end
    end
    for num in sorted_numbers_to_mask
        for i in 1:n, j in 1:n
            if grid[i, j] == num
                # Vérifier s'il est possible de masquer le point
                if can_mask_cell(masked_grid, i, j)
                    masked_grid[i, j] = 0
                end
            end
        end
    end
    return masked_grid
end

 # Définir une fonction pour calculer la fréquence de chaque chiffre dans la grille
 function calculate_frequency(grid::Matrix{Int64})
    frequency = [0 for _ in 1:9]
    for i in 1:size(grid, 1), j in 1:size(grid, 2)
        for k in 1:9
            if grid[i, j]==k
                frequency[k] += 1
            end
        end
    end
    return frequency
end

# Fonction pour vérifier si une case peut être masquée sans violer les contraintes
function can_mask_cell(grid, i, j)
    # Vérifier si la case a des voisins masqués
    for i_ in max(1,i-1):min(size(grid,1),i+1)
        #Il faut vérifier que i_ est différent de i
        if i_!=i
            if grid[i_, j] == 0
                return false
            end
        end
    end
    for j_ in max(1,j-1):min(size(grid,2),j+1)
        #Il faut vérifier que j_ est différent de j
        if j_!=j
            if grid[i, j_] == 0
                return false
            end
        end
    end
    
    # Vérifier si la ligne a déjà un voisin du même chiffre
    num = grid[i, j]
    for i_ in 1:size(grid,1)
        #Il faut vérifier que i_ est différent de i
        if i_!=i
            if grid[i_, j] == num
                return true
            end
        end
    end
    # Vérifier si la colonne a déjà un voisin du même chiffre
    for j_ in 1:size(grid,2)
        #Il faut vérifier que j_ est différent de j
        if j_!=j
            if grid[i, j_] == num
                return true
            end
        end
    end
    return false
end

"""
Solve all the instances contained in "../data" through CPLEX and heuristics

The results are written in "../res/cplex" and "../res/heuristic"

Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
"""
function solveDataSet()

    dataFolder = "../data/"
    resFolder = "../res/"

    # Array which contains the name of the resolution methods
    resolutionMethod = ["cplex"]
    #resolutionMethod = ["cplex", "heuristique"]

    # Array which contains the result folder of each resolution method
    resolutionFolder = resFolder .* resolutionMethod

    # Create each result folder if it does not exist
    for folder in resolutionFolder
        if !isdir(folder)
            mkdir(folder)
        end
    end
            
    global isOptimal = false
    global solveTime = -1

    # For each instance
    # (for each file in folder dataFolder which ends by ".txt")
    for file in filter(x->occursin(".txt", x), readdir(dataFolder))  
        
        println("-- Resolution of ", file)
        println("Attempting to read file:", dataFolder * file)
        t=read_matrix_from_file(dataFolder * file)

        # For each resolution method
        for methodId in 1:size(resolutionMethod, 1)
            
            outputFile = resolutionFolder[methodId] * "/" * file

            # If the instance has not already been solved by this method
            if !isfile(outputFile)
                
                fout = open(outputFile, "w")  

                resolutionTime = -1
                isOptimal = false
                
                # If the method is cplex
                if resolutionMethod[methodId] == "cplex"
                    
                    # Solve it and get the results
                    isOptimal, x, resolutionTime = cplexSolve(t)
                    
                    # If a solution is found, write it
                    if isOptimal
                        displaySolution(x)
                    end

                # If the method is one of the heuristics
                else
                    
                    isSolved = false

                    # Start a chronometer 
                    startingTime = time()
                    
                    # While the grid is not solved and less than 100 seconds are elapsed
                    while !isOptimal && resolutionTime < 100
                        
                        print(".")

                        # Solve it and get the results
                        isOptimal, resolutionTime = heuristicSolve()

                        # Stop the chronometer
                        resolutionTime = time() - startingTime
                        
                    end

                    # Write the solution (if any)
                    if isOptimal
                        writeSolution(fout, solution)
                    end 
                end

                println(fout, "solveTime = ", resolutionTime) 
                println(fout, "isOptimal = ", isOptimal)
                close(fout)
            end


            # Display the results obtained with the method on the current instance
            include(outputFile)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end         
    end 
end
