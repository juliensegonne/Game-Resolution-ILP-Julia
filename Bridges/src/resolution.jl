# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX
using MathOptInterface
include("io.jl")


include("generation.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX
"""
function cplexSolve(t::Matrix{Int64})
    n = size(t, 1)

    # Create the model
    m = Model(CPLEX.Optimizer)

    # x[i,j,,i_,j_,k]= 1 si les points (i,j) et (i_,j_) sont reliés par k=0,1,2 arêtes
    @variable(m, x[1:n, 1:n,1:n,1:n, 1:3], Bin)

    # Set the fixed value in the grid
    Voisins= [[([], []) for _ in 1:n] for _ in 1:n]
    for l in 1:n
        for c in 1:n
            #si il n'y a pas de sommet, on fixe la valeur des ponts reliant (l,c) à tout autre sommet à 0
            if t[l,c]==0
                for l_ in 1:n
                    for c_ in 1:n
                        @constraint(m, x[l,c,l_,c_,1] == 1)
                    end
                end
            end

            if t[l,c]!=0
                #empeche un point d'être relié à lui même
                @constraint(m, x[l,c,l,c,1] == 1)
                
                #on parcours les points en dessous de (l,c)
                voisin=0
                for l_ in l:n
                    if l_!=l
                        if t[l_,c]!=0 && voisin!=0 #si (l_,c) n'est pas un voisin de (l,c)
                            @constraint(m, x[l,c,l_,c,1] == 1)# il n'y a pas de pont possible
                        elseif t[l_,c]!=0 && voisin==0 #si (l_,c) est un voisin de (l,c)
                            voisin=voisin+1
                            push!(Voisins[l][c][1],l_)
                            push!(Voisins[l][c][2],c)
                            push!(Voisins[l_][c][1],l)
                            push!(Voisins[l_][c][2],c)
                        elseif t[l_,c]==0#s'il y a un sommet entre (l,c) et (l_,c)
                            @constraint(m, x[l,c,l_,c,1] == 1)
                        end
                    end
                end
                #on parcours les points à droite de (l,c) et on fait pareil que au-dessus
                voisin=0
                for c_ in c:n
                    if c_!=c
                        if t[l,c_]!=0 && voisin!=0
                            @constraint(m, x[l,c,l,c_,1] == 1)
                        elseif t[l,c_]!=0 && voisin==0
                            voisin=voisin+1
                            push!(Voisins[l][c][1],l)
                            push!(Voisins[l][c][2],c_)
                            push!(Voisins[l][c_][1],l)
                            push!(Voisins[l][c_][2],c)
                        elseif t[l,c_]==0
                            @constraint(m, x[l,c,l,c_,1] == 1)
                        end
                    end
                end
            end
        end
    end

    #Il y a autant de ponts reliant (a,b) à (c,d) que de (c,d) à (a,b)
    for a in 1:n, b in 1:n, c in 1:n, d in 1:n, k in 1:3
        @constraint(m, x[a,b,c,d,k] == x[c,d,a,b,k])
    end

    #Somme des ponts des voisins de (l,c) égale à t[l,c]
    @constraint(m, [l in 1:n, c in 1:n], sum((k-1) * x[l, c, Voisins[l][c][1][i], Voisins[l][c][2][i], k] for i in 1:size(Voisins[l][c][1], 1), k in 1:3) == t[l, c])
    
    @objective(m,Max,0)
    # Start a chronometer
    start = time()

    # Solve the model
    optimize!(m)

    displaySolution(x,t,Voisins)

    # Return:
    # 1 - true if an optimum is found
    # 2 - the grid
    # 3 - the resolution time
    # return JuMP.primal_status(m) == MathOptInterface.FEASIBLE_POINT,x ,time() - start
    
end

# """
# Heuristically solve an instance
# """
# function heuristicSolve()

#     # TODO
#     println("In file resolution.jl, in method heuristicSolve(), TODO: fix input and output, define the model")
    
# end 

# """
# Solve all the instances contained in "../data" through CPLEX and heuristics

# The results are written in "../res/cplex" and "../res/heuristic"

# Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
# """
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
        t = readInputFile(dataFolder * file)

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
                    isOptimal, x, solveTime = cplexSolve(t)
                    
                    # If a solution is found, write it
                    if isOptimal
                        writeSolution(fout, x)
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

                println(fout, "solveTime = ", solveTime) 
                println(fout, "isOptimal = ", isOptimal)
                close(fout)
            end


            # Display the results obtained with the method on the current instance
            # include(outputFile)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end         
    end 
end
