# This file contains methods to generate a data set of instances (i.e., sudoku grids)
include("io.jl")

"""
Generate an n*n grid with a given density

Argument
- n: size of the grid
- density: percentage in [0, 1] of initial values in the grid
"""

function generateInstance(n::Int64, density::Float64)
    generated=false
    t = zeros(Int, n, n)
    while !generated
        loop=0

        # Initialize an empty matrix
        t = zeros(Int, n, n)
        occupied_cells=zeros(Int,n,n)

        # Place the initial edges connected by a bridge
        initialized=false
        while initialized==false
            i1, j1 = ceil.(Int, n * rand()), ceil.(Int, n * rand())
            i2, j2 = ceil.(Int, n * rand()), ceil.(Int, n * rand())
            if (i1==i2 || j1==j2) && ((i1,j1)!=(i2,j2))
                weight=ceil.(Int, 2* rand())
                t[i1, j1] = weight
                t[i2, j2] = weight
                initialized=true
                for i in min(i1,i2):max(i1,i2)
                    for j in min(j1,j2):max(j1,j2)
                        occupied_cells[i,j]=1
                    end
                end
            end
        end
        # Keep track of the total number of edges
        total_edges = 2

        # Continue adding edges until reaching the desired density
        while total_edges < n * n * density && loop <1000
            loop=loop+1

            # Randomly select a vertex to connect
            i_new, j_new = ceil.(Int, n * rand()), ceil.(Int, n * rand())

            # Check if the selected vertex is already connected
            if t[i_new, j_new] != 0
                continue
            end

            # Check if the selected vertex can be connected to existing edges
            weight = ceil.(Int, 2 * rand())
            (i_neighbor, j_neighbor) = canConnect(t, i_new, j_new)
            if (i_neighbor, j_neighbor) != (-1, -1)
                # Check if the new bridge overlaps or crosses existing bridges
                if isBridgeValid(t, i_new, j_new, i_neighbor+sign(i_new - i_neighbor), j_neighbor+sign(j_new - j_neighbor),occupied_cells)
                    # Connect the new vertex
                    t[i_new, j_new] = weight
                    t[i_neighbor, j_neighbor] += weight
                    total_edges += 1
                    for i in min(i_new,i_neighbor):max(i_neighbor,i_new)
                        for j in min(j_neighbor,j_new):max(j_neighbor,j_new)
                            occupied_cells[i,j]=1
                        end
                    end
                end
            end
        end
        if loop<999
            generated=true
        end
    end
    return t
end

function canConnect(t::Matrix{Int}, i::Int, j::Int)
    # Check if the selected vertex (i, j) can be connected to existing edges
    # Check if there is a neighboring vertex already connected
    for i_neighbor in 1:size(t, 1)
        for j_neighbor in 1:size(t, 1)
            if t[i_neighbor,j_neighbor]!=0 && (i==i_neighbor || j==j_neighbor)
                return (i_neighbor,j_neighbor)
            end
        end
    end

    return (-1, -1)
end

function isBridgeValid(t::Matrix{Int}, i1::Int, j1::Int, i2::Int, j2::Int,occupied_cells::Matrix{Int})
    for i in min(i1,i2):max(i1,i2)
        for j in min(j1,j2):max(j1,j2)
            if occupied_cells[i,j]==1
                return false
            end
        end
    end
    return true
end



"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generateDataSet()

    # For each grid size considered
    for size in [20,21,22,23]

        # For each grid density considered
        for density in [0.2]

            # Generate 10 instances
            for instance in 1:1

                fileName = "../data/instance_t" * string(size) * "_d" * string(density) * "_" * string(instance) * ".txt"

                if !isfile(fileName)
                    println("-- Generating file " * fileName)
                    saveInstance(generateInstance(size, density), fileName)
                end 
            end
        end
    end
end



