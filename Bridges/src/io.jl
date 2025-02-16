# This file contains functions related to reading, writing and displaying a grid and experimental results

using JuMP
using Plots
import GR

"""
Read an instance from an input file

- Argument:
inputFile: path of the input file
"""
function readInputFile(inputFile::String)

    # Open the input file
    datafile = open(inputFile)

    data = readlines(datafile)
    close(datafile)
    
    n = length(split(data[1], ","))
    t = Matrix{Int64}(undef, n, n)
    lineNb = 1

    # For each line of the input file
    for line in data

        lineSplit = split(line, ",")

        if size(lineSplit, 1) == n
            for colNb in 1:n

                if lineSplit[colNb] != " "
                    t[lineNb, colNb] = parse(Int64, lineSplit[colNb])
                else
                    t[lineNb, colNb] = 0
                end
            end
        end 
        
        lineNb += 1
    end

    return t

end

function displayGrid(t::Matrix{Int64})

    n = size(t, 1)
    blockSize = round.(Int, sqrt(n))
    
    # Display the upper border of the grid
    println("-"^(3*n+blockSize)) 
    
    # For each cell (l, c)
    for l in 1:n
        print("|")
        for c in 1:n
            
            if t[l, c] == 0
                print("  ")
            else
                print(" ",t[l, c])
            end
            print(" ")
        end
        print("|\n")
        if l!=n
            print("|")
            for c in 1:n
                print("   ")
            end
            print("|\n")
        end

    end
    println("-"^(3*n+blockSize)) 
end

function displaySolution(x::Array{VariableRef,5},t::Matrix{Int64},Voisins::Vector{Vector{Tuple{Vector{Any}, Vector{Any}}}})
    n = size(t, 1)
    blockSize = round.(Int, sqrt(n))
    
    # Display the upper border of the grid
    println("-"^(3*n+blockSize+1)) 
    
    # For each cell (l, c)
    for l in 1:n
        print("| ")
        c=1
        while c<=n
            if t[l, c] == 0
                print(" ")
            else
                print(t[l, c])
            end
            if any(Voisins[l][c][2][i] > c && l == Voisins[l][c][1][i] for i in 1:length(Voisins[l][c][2]))
                for i in 1:length(Voisins[l][c][2])
                    c_=Voisins[l][c][2][i]
                    if c_>c && l==Voisins[l][c][1][i]
                        if value(x[l,c,l,c_,1]) == 1.0
                            for a in 1:c_-c
                                print("  ")
                            end
                            for a in 1:c_-c-1
                                print(" ")
                            end
                        elseif value(x[l,c,l,c_,2]) == 1.0
                            for a in 1:c_-c
                                print("--")
                            end
                            for a in 1:c_-c-1
                                print("-")
                            end
                        elseif value(x[l,c,l,c_,3]) == 1.0
                            for a in 1:c_-c
                                print("==")
                            end
                            for a in 1:c_-c-1
                                print("=")
                            end
                        end
                        c=c_
                        break
                    end
                end
            else 
                print("  ")
                c=c+1
            end
        end
        print("|\n")
        if l!=n
            print("| ")
            for c in 1:n
                b=0
                for l_m in 1:l 
                    for l_M in l+1:n 
                        for i in 1:length(Voisins[l_m][c][1])
                            if l_M==Voisins[l_m][c][1][i]
                                if value(x[l_m,c,l_M,c,2])==1.0
                                    print("| ")
                                    b=1
                                elseif value(x[l_m,c,l_M,c,3])==1.0
                                    print("||")
                                    b=1
                                end
                            end
                        end
                    end
                end
                if b==0
                    print("  ")
                end
                print(" ")
            end
            print("|\n")
        end

    end
    println("-"^(3*n+blockSize+1)) 
end

function performanceDiagram()

    resultFolder = "../res/"
    
    # Maximal number of files in a subfolder
    maxSize = 0

    # Number of subfolders
    subfolderCount = 0

    folderName = Array{String, 1}()

    # For each file in the result folder
    for file in readdir(resultFolder)

        path = resultFolder * file
        
        # If it is a subfolder
        if isdir(path)
            
            folderName = vcat(folderName, file)
             
            subfolderCount += 1
            folderSize = size(readdir(path), 1)

            if maxSize < folderSize
                maxSize = folderSize
            end
        end
    end

    # Array that will contain the resolution times (one line for each subfolder)
    results = Array{Float64}(undef, subfolderCount, maxSize)

    for i in 1:subfolderCount
        for j in 1:maxSize
            results[i, j] = Inf
        end
    end

    folderCount = 0
    maxSolveTime = 0
    totalTime=0

    # For each subfolder
    for file in readdir(resultFolder)
            
        path = resultFolder * file
        
        if isdir(path)

            folderCount += 1
            fileCount = 0

            # For each text file in the subfolder
            for resultFile in filter(x->occursin(".txt", x), readdir(path))

                fileCount += 1
                # include(path * "/" * resultFile)
                solveTime = -1.0  # Valeur par défaut si solveTime n'est pas trouvé
                open(path * "/" * resultFile, "r") do file
                    for line in eachline(file)
                        if contains(line, "solveTime")
                            solveTime = parse(Float64, split(line)[end])
                            break
                        end
                        if contains(line, "isOptimal")
                            isOptimal = parse(Float64, split(line)[end])
                            break
                        end
                    end
                end
                
                if isOptimal
                    results[folderCount, fileCount] = solveTime
                    
                    totalTime=totalTime+solveTime
                    if solveTime > maxSolveTime
                        maxSolveTime = solveTime
                    end 
                end 
            end 
        end
    end 
    println("Max solve time: ", maxSolveTime)
    println("Total solve time: ", totalTime)
end 

function saveInstance(t::Matrix{Int64}, outputFile::String)

    n = size(t, 1)

    # Open the output file
    writer = open(outputFile, "w")

    # For each cell (l, c) of the grid
    for l in 1:n
        for c in 1:n

            # Write its value
            if t[l, c] == 0
                print(writer, " ")
            else
                print(writer, t[l, c])
            end

            if c != n
                print(writer, ",")
            else
                println(writer, "")
            end
        end
    end

    close(writer)
    
end 

function writesolution(fout::IOStream, t::Array{Int64, 4})
    n = size(t, 1)
    for l in 1:n
        for c in 1:n
            for l_ in 1:n
                for c_ in 1:n
                    if t[l, c, l_, c_] != 0 && (l<l_ || c<c_)
                        println(fout, "(", l, ",", c, ") <-> (", l_, ",", c_, ") = ", t[l, c, l_, c_])
                    end
                end
            end
        end 
    end
end

function writeSolution(fout::IOStream, x::Array{VariableRef,5})

    # Convert the solution from x[l,c,l_,c_,k] variables into t[l,c,l_,c_] variables
    n = size(x, 1)
    t = zeros(Int, n, n, n, n)
    
    for l in 1:n
        for c in 1:n
            for l_ in 1:n
                for c_ in 1:n
                    for k in 1:3
                        if JuMP.value(x[l, c, l_,c_,k]) > TOL
                            t[l, c, l_, c_] = k-1
                        end
                    end
                end
            end
        end 
    end

    # Write the solution
    writesolution(fout, t)

end

"""
Create a latex file which contains an array with the results of the ../res folder.
Each subfolder of the ../res folder contains the results of a resolution method.

Arguments
- outputFile: path of the output file

Prerequisites:
- Each subfolder must contain text files
- Each text file correspond to the resolution of one instance
- Each text file contains a variable "solveTime" and a variable "isOptimal"
"""
function resultsArray(outputFile::String)
    
    resultFolder = "../res/"
    dataFolder = "../data/"
    
    # Maximal number of files in a subfolder
    maxSize = 0

    # Number of subfolders
    subfolderCount = 0

    # Open the latex output file
    fout = open(outputFile, "w")

    # Print the latex file output
    println(fout, raw"""\documentclass{article}

\usepackage[french]{babel}
\usepackage [utf8] {inputenc} % utf-8 / latin1 
\usepackage{multicol}

\setlength{\hoffset}{-18pt}
\setlength{\oddsidemargin}{0pt} % Marge gauche sur pages impaires
\setlength{\evensidemargin}{9pt} % Marge gauche sur pages paires
\setlength{\marginparwidth}{54pt} % Largeur de note dans la marge
\setlength{\textwidth}{481pt} % Largeur de la zone de texte (17cm)
\setlength{\voffset}{-18pt} % Bon pour DOS
\setlength{\marginparsep}{7pt} % Séparation de la marge
\setlength{\topmargin}{0pt} % Pas de marge en haut
\setlength{\headheight}{13pt} % Haut de page
\setlength{\headsep}{10pt} % Entre le haut de page et le texte
\setlength{\footskip}{27pt} % Bas de page + séparation
\setlength{\textheight}{668pt} % Hauteur de la zone de texte (25cm)

\begin{document}""")

    header = raw"""
\begin{center}
\renewcommand{\arraystretch}{1.4} 
 \begin{tabular}{l"""

    # Name of the subfolder of the result folder (i.e, the resolution methods used)
    folderName = Array{String, 1}()

    # List of all the instances solved by at least one resolution method
    solvedInstances = Array{String, 1}()

    # For each file in the result folder
    for file in readdir(resultFolder)

        path = resultFolder * file
        
        # If it is a subfolder
        if isdir(path)

            # Add its name to the folder list
            folderName = vcat(folderName, file)
             
            subfolderCount += 1
            folderSize = size(readdir(path), 1)

            # Add all its files in the solvedInstances array
            for file2 in filter(x->occursin(".txt", x), readdir(path))
                solvedInstances = vcat(solvedInstances, file2)
            end 

            if maxSize < folderSize
                maxSize = folderSize
            end
        end
    end

    # Only keep one string for each instance solved
    unique(solvedInstances)

    # For each resolution method, add two columns in the array
    for folder in folderName
        header *= "rr"
    end

    header *= "}\n\t\\hline\n"

    # Create the header line which contains the methods name
    for folder in folderName
        header *= " & \\multicolumn{2}{c}{\\textbf{" * folder * "}}"
    end

    header *= "\\\\\n\\textbf{Instance} "

    # Create the second header line with the content of the result columns
    for folder in folderName
        header *= " & \\textbf{Temps (s)} & \\textbf{Optimal ?} "
    end

    header *= "\\\\\\hline\n"

    footer = raw"""\hline\end{tabular}
\end{center}

"""
    println(fout, header)

    # On each page an array will contain at most maxInstancePerPage lines with results
    maxInstancePerPage = 20
    id = 1

    # For each solved files
    for solvedInstance in solvedInstances

        # If we do not start a new array on a new page
        if rem(id, maxInstancePerPage) == 0
            println(fout, footer, "\\newpage")
            println(fout, header)
        end 

        # Replace the potential underscores '_' in file names
        print(fout, replace(solvedInstance, "_" => "\\_"))

        # For each resolution method
        for method in folderName

            path = resultFolder * method * "/" * solvedInstance

            # If the instance has been solved by this method
            if isfile(path)
                # include(path)
                solve_time = -1.0  # Valeur par défaut si solveTime n'est pas trouvé
                open(path, "r") do file
                    for line in eachline(file)
                        if contains(line, "solveTime")
                            solve_time = parse(Float64, split(line)[end])
                            break
                        end
                    end
                end
                println(fout, " & ", round(solve_time, digits=3), " & ")

                if isOptimal
                    println(fout, "\$\\times\$")
                end 
                
            # If the instance has not been solved by this method
            else
                println(fout, " & - & - ")
            end
        end

        println(fout, "\\\\")

        id += 1
    end

    # Print the end of the latex file
    println(fout, footer)

    println(fout, "\\end{document}")

    close(fout)
    
end 
