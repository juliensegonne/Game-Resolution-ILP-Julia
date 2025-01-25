# This file contains methods to generate a data set of instances (i.e., sudoku grids)
include("resolution_jeu2.jl")
include("../../sudoku1.0/src/io.jl")
using Statistics
using Random
"""
Generate an n*n grid with a given density

Argument
- n: size of the grid
- density: percentage in [0, 1] of initial values in the grid
"""
function generateInstance(n::Int64, density::Float64)
    grid = Matrix{Int}(undef, n, n)
    #On génère [1 2 3...;n 1 2...;n-1 n 1...;...]
    for i in 1:n
        for j in 1:n
            grid[i, j] = mod(j + i - 2, n) + 1
        end
    end
    #on échange des jonnes entre elles pour générer de l'aléatoire
    for _ in 1:(2*n)
        j1 = rand(1:n)
        j2 = rand(1:n)
        grid[:, [j1, j2]] = grid[:, [j2, j1]] # Échange les deux jonnes
    end
    #on échange des lignes entre elles pour générer de l'aléatoire
    for _ in 1:(2*n)
        i1 = rand(1:n)
        i2 = rand(1:n)
        grid[[i1, i2], :] = grid[[i2, i1], :] # Échange les deux lignes
    end
    #On enlève un certain nombre de cases de la grille si elles respectent les conditions
    while count(x -> x != 0, grid) >= n * n * density
        cell_suppressed = false
        i,j=1,1
        while !cell_suppressed
            i = rand(1:n)
            j = rand(1:n)
            if can_be_suppressed(grid,i,j) && grid[i,j]!=0
                cell_suppressed=true
            end
        end
        grid[i, j] = 0
    end
    println(grid)
    #on remet des nombres aléatoires là où il y avait des 0
    for i in 1:n,j in 1:n
        if grid[i,j]==0
            grid[i,j]=rand(1:n)
        end
    end
    return grid
end

function can_be_suppressed(grid, i, j)
    # Vérifier si la case a des voisins nuls
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

    # Vérifier si la suppression de la case (i, j) crée une diagonale de zéros allant d'un bord à l'autre de la grille
    if grid[i, j] == 0
        # Vérifier la diagonale vers le haut à gauche
        x, y = i, j
        diag_empty=true
        while x > 1 && y > 1
            if grid[x, y] != 0
                diag_empty=false
            end
            x -= 1
            y -= 1
        end
        while x <= size(grid, 1) && y <= size(grid, 2)
            if grid[x, y] != 0
                diag_empty=false
            end
            x += 1
            y += 1
        end
        if diag_empty
            return false
        end
        
        # Vérifier la diagonale vers le haut à droite
        x, y = i, j
        while x > 1 && y < size(grid, 2)
            if grid[x, y] != 0
                diag_empty=false
            end
            x -= 1
            y += 1
        end
        while x <= size(grid, 1) && y >= 1
            if grid[x, y] != 0
                diag_empty=false
            end
            x += 1
            y -= 1
        end
        if diag_empty
            return false
        end
    end
    return true
end
"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generateDataSet()
    density = 0.9
    # For each grid size considered
    for size in [4, 5, 6, 8, 10]
        # Generate 10 instances
        for instance in 1:10

            fileName = "../data/instance_t" * string(size) * "_" * string(instance) * ".txt"

            if !isfile(fileName)
                println("-- Generating file " * fileName)
                saveInstance(generateInstance(size, density), fileName)
            end
        end
    end
end
