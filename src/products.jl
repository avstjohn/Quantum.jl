immutable OuterProduct{N<:Number} <: Dirac
	ket::AbstractState{Ket}
	bra::AbstractState{Bra}
end

*(o::OuterProduct, s::AbstractState{Ket}) = DiracVector([(o.bra*s)], statetobasis(o.ket))
*(o::OuterProduct, s::AbstractState{Bra}) = OuterProduct(o.ket, o.bra*s)
*(s::AbstractState{Bra}, o::OuterProduct) = DiracVector([(s*o.ket)], statetobasis(o.bra))
*(s::AbstractState{Ket}, o::OuterProduct) = OuterProduct(s*o.ket, o.bra)

ctranspose(o::OuterProduct) = OuterProduct(o.bra', o.ket')

show(io::IO, o::OuterProduct) = print(io, "$(repr(o.ket))$(repr(o.bra))");

##########################################################################

immutable InnerProduct <: AbstractScalar
	bra::AbstractState{Bra}
	ket::AbstractState{Ket}
end

conj(i::InnerProduct) = InnerProduct(i.ket', i.bra')
show(io::IO, i::InnerProduct) = print(io, "$(repr(i.bra)) $(repr(i.ket)[2:end])");

##########################################################################

typealias DiracCoeff Union(Number, AbstractScalar)

*{C<:DiracCoeff}(c::C, s::AbstractState) = DiracVector([c], statetobasis(s))
*{C<:DiracCoeff}(s::AbstractState, c::C) = *(c,s)

##########################################################################

immutable ScalarExpr <: AbstractScalar
	ex::Expr
end

qexpr(s::ScalarExpr) = s.ex
qexpr(x) = x

function ^(d::DiracCoeff, n::Integer)
	if n==1
		return d
	elseif n==0
		return 1
	else
		ScalarExpr(:($(qexpr(d))^$(qexpr(n))))
	end
end

function ^(a::DiracCoeff, b::DiracCoeff)
	if b==1
		return a
	elseif b==0
		return 1
	else
		ScalarExpr(:($(qexpr(a))^$(qexpr(b))))
	end
end

function *(a::DiracCoeff, b::DiracCoeff)
	if a==1
		return b
	elseif b==1
		return a
	elseif a==0 || b==0
		return 0
	else
		ScalarExpr(:($(qexpr(a))*$(qexpr(b))))
	end
end

function +(a::DiracCoeff, b::DiracCoeff)
	if a==0
		return b
	elseif b==0
		return a
	else
		ScalarExpr(:($(qexpr(a))+$(qexpr(b))))
	end
end

function -(a::DiracCoeff, b::DiracCoeff)
	if a==0
		return b
	elseif b==0
		return a
	else
		ScalarExpr(:($(qexpr(a))-$(qexpr(b))))
	end
end

-(d::DiracCoeff) = ScalarExpr(:(-$(qexpr(d))))
-(s::ScalarExpr) = length(s.ex.args)==2 && s.ex.args[1]==:- ? ScalarExpr(s.ex.args[2]) :  ScalarExpr(:(-$(qexpr(s))))


function /(a::DiracCoeff, b::DiracCoeff)
	if a==0
		return b
	elseif b==0
		error("Zero in denominator")
	elseif a==b
		return 1
	else
		ScalarExpr(:($(qexpr(a))/$(qexpr(b))))
	end
end

conj(s::ScalarExpr)	= length(s.ex.args)==2 && s.ex.args[1]==:conj ? ScalarExpr(s.ex.args[2]) :  ScalarExpr(:(conj($(qexpr(s)))))

qeval(f::Function, s::ScalarExpr) = eval(qreduce(f, s.ex))

function qreduce(f::Function, ex::Expr)
	ex = copy(ex)
	for i=1:length(ex.args)
		if typeof(ex.args[i])==InnerProduct
			ex.args[i] = f(ex.args[i].bra, ex.args[i].ket)
		elseif typeof(ex.args[i])==Expr
			ex.args[i] = qreduce(f, ex.args[i])
		end
	end
	return ex
end