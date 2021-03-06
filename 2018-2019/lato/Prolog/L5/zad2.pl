is_var(X) :-
    atom(X),
    \+ is_const(X).

is_const(pi).
is_const(e).
is_const(C) :-
    number(C).

vars(Var, [Var]) :-
    is_var(Var),
    !.
vars(C, []) :-
    is_const(C),
    !.
vars(T, Vars) :-
    T =.. [_, Operand],
    !,
    vars(Operand, Vars).
vars(T, Vars) :-
    T =.. [_, Lhs, Rhs],
    vars(Lhs, LVars),
    vars(Rhs, RVars),
    append(LVars, RVars, LRVars),
    sort(LRVars, Vars).

find_var(Var, [[Var, Val] | _], Val) :-
    !.
find_var(Var, [_ | Vars], Val) :-
    find_var(Var, Vars, Val).

subst(C, _, Val) :-
    is_const(C),
    Val is C,
    !.
subst(Var, Vars, Val) :-
    is_var(Var),
    !,
    find_var(Var, Vars, Val).
subst(ctg(X), Vars, Val) :-
    !,
    subst(cos(X)/sin(X), Vars, Val).
subst(T, Vars, Result) :-
    T =.. [Operator, Operand],
    !,
    subst(Operand, Vars, OperandSubst),
    Result =.. [Operator, OperandSubst].
subst(T, Vars, Result) :-
    T =.. [Operator, Lhs, Rhs],
    subst(Lhs, Vars, LhsSubst),
    subst(Rhs, Vars, RhsSubst),
    Result =.. [Operator, LhsSubst, RhsSubst].

eval(Expr, Env, Val) :-
    subst(Expr, Env, Substituted),
    Val is Substituted.

diff(X, X, 1) :-
    is_var(X),
    !.
diff(X, _, X) :-
    is_var(X),
    !.
diff(N, _, 0) :-
    is_const(N),
    !.
diff(X+Y, Var, Derivative) :-
    diff(X, Var, DX),
    diff(Y, Var, DY),
    Derivative = DX + DY.
diff(X-Y, Var, Derivative) :-
    diff(X, Var, DX),
    diff(Y, Var, DY),
    Derivative = DX - DY.
diff(X*Y, Var, Derivative) :-
    diff(X, Var, DX),
    diff(Y, Var, DY),
    Derivative = DX * Y + X * DY.
diff(X/Y, Var, Derivative) :-
    diff(X, Var, DX),
    diff(Y, Var, DY),
    Derivative = DX * Y - X * DY/ (DY ** 2).
diff(X**C, Var, Derivative) :-
    is_const(C),
    !,
    CLess is C - 1,
    diff(X, Var, DX),
    Derivative = C * (X ** CLess) * DX.
diff(X**Y, Var, Derivative) :-
    diff(X, Var, DX),
    diff(Y, Var, DY),
    Derivative = X**Y * (DX*Y/X + DY * log(X)).
diff(sqrt(X), Var, Derivative) :-
    diff(X**(0.5), Var, Derivative).
diff(sin(X), Var, Derivative) :-
    diff(X, Var, DX),
    Derivative = DX * cos(X).
diff(cos(X), Var, Derivative) :-
    diff(X, Var, DX),
    Derivative = -1 * DX * sin(X).
diff(tan(X), Var, Derivative) :-
    diff(X, Var, DX),
    Derivative = DX * 1 / (cos(X) ** 2).
diff(ctg(X), Var, Derivative) :-
    diff(X, Var, DX),
    Derivative = DX * -1 / (sin(X) ** 2).
diff(log(X), Var, Derivative) :-
    diff(X, Var, DX),
    Derivative = DX / X.
diff(log10(X), Var, Derivative) :-
    diff(X, Var, DX),
    Derivative = DX / (X * log(10)).
diff(exp(X), Var, Derivative) :-
    diff(X, Var, DX),
    Derivative = DX * exp(X).

simplify(_*0, 0) :-
    !.
simplify(0*_, 0) :-
    !.
simplify(X*1, X) :-
    !.
simplify(1*X, X) :-
    !.
simplify(Var, Var) :-
    is_var(Var),
    !.
simplify(T, Val) :-
    vars(T, []),
    !,
    eval(T, [], Val).
simplify(C, C) :-
    is_const(C),
    !.
simplify(T, Simplified) :-
    T =.. [Operator, Operand],
    simplify(Operand, SimplifiedOp),
    Simplified =.. [Operator, SimplifiedOp],
    !.
simplify(X+X, Simplified) :-
    simplify(1*X+1*X, Simplified),
    !.
simplify(A*X+X, Simplified) :-
    simplify(A*X+1*X, Simplified),
    !.
simplify(X+A*X, Simplified):-
    simplify(1*X+A*X, Simplified),
    !.
simplify(A*X+B*X, Simplified) :-
    !,
    simplify(X, SimplifiedX),
    simplify(A+B, SimplifiedAB),
    Simplified = SimplifiedAB * SimplifiedX,
    !.
simplify(T, Simplified) :-
    T =.. [Operator, Lhs, Rhs],
    simplify(Lhs, SLhs),
    simplify(Rhs, SRhs),
    Simplified =.. [Operator, SLhs, SRhs],
    !.
simplify(X, X).

