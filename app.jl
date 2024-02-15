module App
# set up Genie development environment
using GenieFramework
using Graphs
using SimpleWeightedGraphs,GraphPlot
using DelimitedFiles
@genietools

lines = readdlm("gb128_dist.txt")
content = lines[1:end,1:end]
content = round.(Int64,content)

g=SimpleWeightedDiGraph(content)

function traverse_graph(
    J::AbstractArray, 
    start_node::Int, end_node::Int
)
path = Int[start_node]
cost = 0.0
W = SimpleWeightedGraphs.weights(g)

# TODO: step1, initialize v
v = start_node  # CHANGE ME
num = 0
while v != end_node && num < SimpleWeightedGraphs.nv(g)  # prevent infinite loop
    num +=1
    F_v = Graphs.neighbors(g, v)

    # TODO: step 2, compute costs for all n in F_v
    costs = [W[v, n] + J[n] for n in F_v]  # CHANGE ME

    n = F_v[argmin(costs)]

    # TODO: how should we update cost of just the one edge!?
    cost += W[v, n] # CHANGE ME

    push!(path, n)

    # TODO: step 3 -- update v
    v = n  # CHANGE MEa
end
path, cost
end
cost(W, J, n, v) = W[v, n] + J[n]
function compute_J(dest_node::Int)
    N = SimpleWeightedGraphs.nv(g)
    # step 1. start with zeros
    i = 0
    Ji = zeros(N)

    # allocating memory/creating the array we will 
    # fill in for J_{i+1}
    next_J = zeros(N)

    # get the weight matrix from the graph G
    W = SimpleWeightedGraphs.weights(g)

    done = false
    while !done
        i += 1
        for v in 1:N
            if v == dest_node
                next_J[v] = 0
                continue
            end
            F_v = Graphs.neighbors(g, v)
            costs = [cost(W, Ji, n, v) for n in F_v]
            next_J[v] = minimum(costs)
        end
        done = all(next_J .≈ Ji)
        copy!(Ji, next_J)
    end
    Ji
end
function shortest_path(start_node::Int, end_node::Int)
    J = compute_J(end_node)
    traverse_graph(J, start_node, end_node)
end


function remove_hash_lines(input_file::AbstractString)
    # Open the input file in read mode
    open(input_file, "r") do file
        # Read all the lines from the file
        lines = readlines(file)
        
        # Initialize an empty list to store the filtered lines
        filtered_lines = Vector{String}()
        
        # Iterate over each line
        for line in lines
            # Check if the line starts with a hash symbol
            if !startswith(line, '#')
                # If the line doesn't start with a hash, append it to the filtered lines list
                push!(filtered_lines, line)
            end
        end
        
        return filtered_lines
    end
end

# Usage
filtered_lines = remove_hash_lines("sgb128_name.txt")
#filtered_lines


split_lists = Vector{Vector{String}}()
    
for line in filtered_lines
    # Split the line based on comma (',') and strip whitespace from each element
    split_elements = [strip(element) for element in split(line, ',')]
    
    # Append the split elements to the list of lists
    push!(split_lists, split_elements)
end
#split_lists
map_board=Dict(zip(split_lists,1:length(split_lists)))
map_board_rev=Dict()
for i in eachindex(map_board)
    println(i,"=>",map_board[i])
    map_board_rev[map_board[i]]=i
end
function checkNode(start,end1,inbetween)
    l = shortest_path(start,end1)[1] 
    res = setdiff(Set(inbetween),Set(l))
    collect(res)
 end

#finding number of trucks
#if number of intermediate locations >2
function number_of_trucks1(start,end1,inBetween=[])
    if length(inBetween)==0
        l1=shortest_path(start,end1)
        println("Path is ",l1[1])
        println("Cost is ",l1[2])
        println("1 truck is enough")
        return l1,([""],1)
    end
    #checking any inbetween node is in shortest path between start and end
    c=checkNode(start,end1,inBetween)
    if length(c)==0
        l1=shortest_path(start,end1)
        println("Path is ",l1[1])
        println("Cost is ",l1[2])
        println("1 truck is enough")
        return l1,([""],1)
    end
    if length(c)==1 && length(inBetween)==1
        cost1 = [0,0,0]
        cost1[1]=Int(shortest_path(start,end1)[2])
        l1 = shortest_path(start,inBetween[1])
        c1 = checkNode(start,inBetween[1],[end1])
        if length(c1)==0
            println("Path is ",l1[1])
            println("Cost is ",l1[2])
            println("1 truck is enough")
            return l1,([""],1)
        end
        cost1[2]=Int(l1[2])
        cost1[3]=Int(shortest_path(end1,inBetween[1])[2])
        if cost1[2]+cost1[3] < cost1[1]+cost1[2]
            println("Path is ",l1[1]," and ",shortest_path(inBetween[1],end1)[1])
            println("Cost is ",cost1[2]+cost1[3])
            println("1 truck is enough")
            return l1,shortest_path(inBetween[1],end1),([""],1)
        else
            println("Path is ",shortest_path(start,end1)[1]," and ",l1[1])
            println("Cost is ",cost1[1]+cost1[2])
            println("2 trucks needed")
            return shortest_path(start,end1),l1
        end
    # else if length(inBetween)>1
    #     l=[]
    #     for i in inBetween
    #         push!(l,shortest_path(G,start,i))
    #     end
        
    end
end
function make1Darray(trucks)
    x11=[]
    for i in 1:length(trucks)-1
        for j in trucks[i][1]
            push!(x11,j)
        end
    end
    x11
end
function getWeightsArray(x11)
    r11=[]
    push!(r11,0)
    for i in 2:length(x11)
        if x11[i-1]==x11[i]
            push!(r11,0)
            continue
        end
        push!(r11,content[x11[i-1],x11[i]])
    end
    r11
end

# add your data analysis code

# add reactive code to make the UI interactive
@app begin
    # reactive variables are tagged with @in and @out
    @in city1   =  [""]
    @in city2   =  [""]
    @in intCity =  [""]
    l=copy(keys(map_board))
    l=collect(l)
    push!(l,[""])
    #insert!(l, 1, [""])
    @out oCity  =  l
    @out plot1 = PlotData[]
    @out plot2 = PlotData[]
    @out plot3 = PlotData[]
    @out tag1  = "Legends"
    @out tag2  = "Legends"
    @out tag3  = "Legends"
    @out p1mile = "Dist"
    @out p2mile = "Dist"
    @out p3mile = "Dist"    
    val = keys(map_board)
    @show l
    @show typeof(val)
    @onchange city1,city2,intCity begin
        @show city1
        @show city2
        @show intCity
        @show l
        path1 = shortest_path(map_board[city1],map_board[city2])
        path2 = ""
        if !(intCity==[""])
            path2 = shortest_path(map_board[city1],map_board[intCity])
        end
        trucks = number_of_trucks1(map_board[city1],map_board[city2],[map_board[intCity]])
        paths = make1Darray(trucks)
        wts = getWeightsArray(paths)
        wts1 = getWeightsArray(path1[1])
        @show paths
        @show intCity
        @show trucks
        @show [map_board[intCity]]
        p1=path1[1]
        wts1=Int.(wts1)
        plot1 = [PlotData( x = p1, y = wts1)]
        if path2==""
            plot2 = [PlotData(x=[0,0,0],y=[0,0,0])]
            plot3 = [PlotData( x = p1, y = wts1)]
        else
            wts2 = getWeightsArray(path2[1])
            wts2=Int.(wts2)
            p2=path2[1]
            plot2 = [PlotData( x = p2, y = wts2)]
            p2m = path2[2]
            p2mile = "Start and Intermediary city miles : $p2m miles and path is $(path2[1])"
            wts = Int.(wts)
            d1=Dict()
            for i in p2
                d1[i]=map_board_rev[i]
            end
            tag2 = "Legends : $d1"
            if trucks[length(trucks)][2]>2
                plot3 = [PlotData(x=[0,0,0],y=[0,0,0])]
                p3mile = "Both Start and end, start and intermediary are optimal and 2 trucks are needed"
            else
                plot3 = [PlotData( x = paths, y = wts)]
                p3m = sum(wts)
                p3mile = "Optimal city miles : $p3m miles and 1 truck is enough and path is $paths"
                d2=Dict()
                for i in paths
                    d2[i]=map_board_rev[i]
                end
                tag3 = "Legends : $d2"
            end
        end
        d=Dict()
        for i in p1
            d[i]=map_board_rev[i]
        end
        tag1 = "Legends : $d"
        p1m = path1[2]
        p1mile = "Start and Destination miles : $p1m miles and path is $(path1[1])"
        
    end
    
end

# register a new route and the page that will be
# loaded on access
@page("/", "app.jl.html")
end