#####################################
#State###############################
#####################################
immutable State{K<:BraKet} <: Dirac
  label::Vector
  kind::Type{K}
end

State(label::Vector) = State(label, Ket)
State{K<:BraKet}(label, kind::Type{K}=Ket) = State([label], kind)
State{K<:BraKet}(label...; kind::Type{K}=Ket) = State([label...], kind)


#####################################
#State Representation################
#####################################
type StateRep{K<:BraKet} <: Dirac
	state::State{K}
	coeffs::Array{Complex{Float64}}
	basis::AbstractBasis{K}
	function StateRep(s::State{K}, coeffs::Array{Complex{Float64}}, basis::AbstractBasis{K})
		if length(basis)==length(coeffs)
			new(s, coeffs, basis)
		elseif length(basis)>length(coeffs)
			error("coefficients unspecified for $(length(basis)-length(coeffs)) basis states")
		else
			error("basis states unspecified for $(length(coeffs)-length(basis)) coefficients")
		end	
	end	
end

StateRep{N<:Number}(s::State, coeffs::Vector{N}, basis::AbstractBasis) = StateRep(s, convert(Array{Complex{Float64}},coeffs), basis)
StateRep{N<:Number}(s::State{Ket}, coeffs::Vector{N}, basis::AbstractBasis) = StateRep{Ket}(s, convert(Array{Complex{Float64}},coeffs), basis)
StateRep{N<:Number}(s::State{Bra}, coeffs::Vector{N}, basis::AbstractBasis) = error("Dimensions of coefficient array does not match type $K")
function StateRep{N<:Number, K<:BraKet}(s::State{K}, coeffs::Array{N}, basis::AbstractBasis)
	if size(coeffs)[2]==1 && K==Ket
		StateRep{Ket}(s, convert(Array{Complex{Float64}},vec(coeffs)), basis)
	elseif K==Bra
		StateRep{Bra}(s, convert(Array{Complex{Float64}},coeffs), basis)
	else
		error("Dimensions of coefficient array does not match type $K")
	end
end

StateRep{N<:Number}(label, coeffs::Vector{N}, basis::AbstractBasis) = StateRep{Ket}(State(label, Ket), convert(Vector{Complex{Float64}},coeffs), basis)
function StateRep{N<:Number}(label, coeffs::Array{N}, basis::AbstractBasis)
	if size(coeffs)[2]==1
		StateRep{Ket}(State(label, Ket), convert(Array{Complex{Float64}},vec(coeffs)), basis)
	else
		StateRep{Bra}(State(label, Bra), label, convert(Array{Complex{Float64}},coeffs), basis)
	end
end

#####################################
#Functions###########################
#####################################

#imported############################
size(s::State) = size(s.label)

ndims(s::State) = 1

isequal(a::State,b::State) = a.label==b.label && a.kind==b.kind

hash(a::State) = hash(a.label)+hash(a.kind)

ctranspose(s::State) = State(s.label, !s.kind)
ctranspose(s::StateRep) = StateRep(s.state', s.coeffs', s.basis')

getindex(s::State, x) = s.label[x]
getindex(s::StateRep, x) = s.coeffs[x]

setindex!(s::StateRep, y, x) = setindex!(s.coeffs, y, x)
setindex!(s::State, y, x) = setindex!(s.label, y, x)

endof(s::State) = endof(s.label)
endof(s::StateRep) = length(s.coeffs)

repr(s::State{Bra}, extra="") = isempty(s.label) ? "$lang #undef$extra |" : "$lang $(repr(s.label)[2:end-1])$extra |"
repr(s::State{Ket}, extra="") = isempty(s.label) ? "| #undef$extra $rang" : "| $(repr(s.label)[2:end-1])$extra $rang"
repr(s::StateRep) = repr(s.state, " ; $(label(s.basis))")

.*(n::Number, s::StateRep) = n*s
.*(s::StateRep, n::Number) = s*n 
.+(s::StateRep, n::Number) = copy(s, s.coeffs.+n)
.+(n::Number, s::StateRep) = copy(s, n.+s.coeffs)
.-(s::StateRep, n::Number) = copy(s, s.coeffs.-n)
.-(n::Number, s::StateRep) = copy(s, n.-s.coeffs)
./(s::StateRep, n::Number) = s/n
./(n::Number, s::StateRep) = copy(s, n./s.coeffs)
.^(n::Number, s::StateRep) = copy(s, n.^s.coeffs)
.^(s::StateRep, n::Number) = copy(s, s.coeffs.^n)

/(s::StateRep, n::Number) = copy(s, s.coeffs/n)

*(n::Number, s::StateRep) = copy(s, n*s.coeffs) 
*(s::StateRep, n::Number) = copy(s, s.coeffs*n) 
*(arr::Array, s::StateRep) = copy(s, arr*s.coeffs)
*(s::StateRep, arr::Array) = copy(s, s.coeffs*arr)
*(a::StateRep{Bra}, b::StateRep{Ket}) = (a.coeffs*b.coeffs)[1]
*(a::StateRep{Ket}, b::StateRep{Ket}) = StateRep(a.state*b.state, kron(a.coeffs, b.coeffs), a.basis*b.basis)
*(a::StateRep{Bra}, b::StateRep{Bra}) = StateRep(a.state*b.state, kron(a.coeffs, b.coeffs), a.basis*b.basis)
*(a::StateRep{Ket}, b::StateRep{Bra}) = Operator(a.coeffs*b.coeffs, a.basis, b.basis)
*(sr::StateRep{Bra}, s::State{Ket}) = get(sr, s')
*(s::State{Bra}, sr::StateRep{Ket}) = get(sr, s')
*{K<:BraKet}(s1::State{K}, s2::State{K}) = tensor(s1, s2)
*(s1::State{Bra}, s2::State{Ket}) = s1.label==s2.label ? 1 : 0 

copy(s::StateRep, coeffs=copy(s.coeffs)) = StateRep(s.state, coeffs, s.basis)
find(s::StateRep) = find(s.coeffs)
length(s::StateRep) = length(s.coeffs)
function get(s::StateRep, label, notfound) 
	ind = get(s.basis, label, 0)
	if ind==0
		return notfound
	else
		return s[ind]
	end
end
get(s::StateRep, skey::State, notfound) =  get(s, skey.label, notfound)
norm(s::StateRep) = norm(s.coeffs)

function map!(f::Function, s::StateRep)
	s.coeffs = map!(f, s.coeffs)
	return s
end 

map(f::Function, s::StateRep) = map!(f, copy(s))

function show(io::IO, s::State)
	print(io, repr(s))
end
function show(io::IO, s::StateRep)
	println("$(typeof(s)) $(repr(s)):")
	if any(s.coeffs.!=0)
		filled = find(s.coeffs)
		table = cell(length(filled), 2)	
		if length(filled)>=52
			for i=1:25
				table[i,1]= s.coeffs[filled[i]]
				table[i,2]= s.basis[filled[i]]
			end
			table[26:(length(filled)-25),:] = 0 # prevents access to undefined reference
			for i=(length(filled)-25):length(filled)
				table[i,1]= s.coeffs[filled[i]]
				table[i,2]= s.basis[filled[i]]
			end
		else
			for i=1:length(filled)
				table[i,1]= s.coeffs[filled[i]]
				table[i,2]= s.basis[filled[i]]
			end
		end
		temp_io = IOBuffer()
		if kind(s)==Ket
			show(temp_io, table)
		else
			show(temp_io, [transpose(table[:,2]), transpose(table[:,1])])
		end
		io_str = takebuf_string(temp_io)
		io_str = io_str[searchindex(io_str, "\n")+1:end]
		print(io_str)
	else
		print("(all coefficients are zero)")
	end
end

#exported############################
kind(s::State) = s.kind
kind(s::StateRep) = s.state.kind

function statevec{K<:BraKet}(v::Vector, kind::Type{K}=Ket)
	svec = Array(State{kind}, length(v))
	for i=1:length(v)
		svec[i] = State(v[i], kind)
	end
	return svec
end
function statevec{K<:BraKet}(arr::Array, kind::Type{K}=Ket)
	svec = Array(State{kind}, size(arr,1))
	for i=1:size(arr, 1)
		svec[i] = State(vec(arr[i,:]), kind)
	end
	return svec
end

tensor() = nothing
tensor{K<:BraKet}(s::State{K}...) = State(vcat([i.label for i in s]...), K)
tensor{S<:State}(state_arrs::Array{S}...) = statejoin(crossjoin(state_arrs...))

statejoin{S<:State}(v::Vector{S}) = tensor(v...)
statejoin{S<:State}(v::Vector{S}...) = broadcast(tensor, v...)
function statejoin{S<:State}(state_arr::Array{S}) 
	result = statejoin(state_arr[:,1], state_arr[:,2])
	for i=3:size(state_arr, 2)
		result = statejoin(result, state_arr[:,i])
	end
	return result
end

separate(s::State) = statevec(s.label)
separate{S<:State}(v::Vector{S}) = hcat(map(separate, v)...).'

state(s::StateRep) = s.state

function normalize!(s::StateRep) 
	s.coeffs=(1/norm(s))*s.coeffs
	return s
end
normalize(s::StateRep) = normalize!(copy(s))

function mapmatch!(f_coeffs::Function, f_states::Function, s::StateRep)
	matched_states = filter(f_states, s.basis)	
	for i=1:length(matched_states)
		s[get(s.basis, matched_states[i], nothing)] = apply(f_coeffs, get(s, matched_states[i], nothing))
	end
	return s
end
mapmatch(f_coeffs::Function, f_states::Function, s::StateRep) = mapmatch!(f_coeffs, f_states, copy(s))

filterstates(f::Function, s::StateRep) = mapmatch((x)->0, f, s)
filterstates!(f::Function, s::StateRep) = mapmatch!((x)->0, f, s)
filtercoeffs(f::Function, s::StateRep) = filtercoeffs!(f, copy(s))
filtercoeffs!(f::Function, s::StateRep) = map!(x->apply(f, x) ? x : 0, s)

