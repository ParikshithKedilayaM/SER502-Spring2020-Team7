%:- use_rendering(svgtree).
endLine --> [;].
equal --> [=].
var --> [var].
begin --> [begin].
end --> [end].

digit(X) --> [X], {number(X)} .
identifier(t_id(X)) --> [X],{atom(X), X\=true, X\=false}.
anystring(t_string(X)) --> [X],{atom(X)}.

program(t_program(X)) --> block(X).
block(t_block(X,Y)) --> begin, declrList(X),commandList(Y),end.

/*
* Declaration Parsing
*/
declrList(t_declrList(X,Y)) --> declR(X), endLine,declrList(Y).
declrList(t_declrList(X)) --> declR(X), endLine.
declR(t_assign_id(X,Y)) --> var, identifier(X),[:,=],expr(Y).
declR(X) --> var, identifierList(X).
declR(t_init_list(X)) --> [list], identifier(X).
identifierList(t_identifierList(X,Y)) --> identifier(X),[','], identifierList(Y).
identifierList(X) --> identifier(X).


/*
* Commands Parsing
*/
commandList(t_commandList(X,Y)) --> commandI(X),endLine,commandList(Y).
commandList(t_commandList(X)) --> commandI(X),endLine.
commandI(X) --> display(X).
commandI(X) --> commandInitialize(X).
commandI(X) --> ifEval(X).
commandI(X) --> forEval(X).
commandI(X) --> whileEval(X).
commandI(X) --> ternaryEval(X).
commandI(X) --> list_push(X).
commandI(X) --> list_pop(X).
commandI(X) --> list_isEmpty(X).

commandInitialize(t_commandInitialize(X,Y)) --> identifier(X),[:,=],expr(Y).
commandInitialize(t_commandInitialize(X,Y)) --> identifier(X),[+,+],{Y=t_add(X,1)}.
commandInitialize(t_commandInitialize(X,Y)) --> identifier(X),[-,-],{Y=t_sub(X,1)}.


list_push(t_list_push_first(X,Y)) --> identifier(X),[-,>],[pushFirst],['('],expr(Y),[')'].
list_push(t_list_push_last(X,Y)) --> identifier(X),[-,>],[pushLast],['('],expr(Y),[')'].



list_pop(t_list_pop_first(X)) --> identifier(X),[-,>],[popFirst],['('],[')'].
list_pop(t_list_pop_first_assign(X,Y)) --> identifier(Y), [:,=], identifier(X),[-,>],[popFirst],['('],[')'].


list_pop(t_list_pop_last(X)) --> identifier(X),[-,>],[popLast],['('],[')'].
list_pop(t_list_pop_last_assign(X,Y)) --> identifier(Y), [:,=], identifier(X),[-,>],[popLast],['('],[')'].


list_isEmpty(t_list_isempty(X)) --> identifier(X),[-,>],[isEmpty],['('],[')'].
list_isEmpty(t_list_isempty_assign(X,Y)) -->identifier(Y),[:,=], identifier(X),[-,>],[isEmpty],['('],[')'].



ifEval(t_ifteEval(X,Y,Z)) -->[if],['('],boolean(X),[')'],[then],commandList(Y), [else],
    commandList(Z), [endif].
ifEval(t_ifEval(X,Y)) -->[if],['('],boolean(X),[')'],[then],commandList(Y), [endif].

ternaryEval(t_ternary(W,X,Y,Z)) --> identifier(W) ,[:,=], boolean(X),[?],expr(Y),[:],expr(Z).

forEval(t_traditionalforEval(X,Y,Z,T)) --> [for],['('],commandInitialize(X),endLine,boolean(Y),
    endLine,commandInitialize(Z),[')'],[do],commandList(T),[endfor].
forEval(t_advancedforEval(X,Y,Z,T)) --> [for],identifier(X),[in],[range],['('],digit(Y), [to],digit(Z),[')'],
                                        [do],commandList(T), [endfor].

whileEval(t_whileEval(X,Y)) --> [while],['('],boolean(X),[')'],[do],commandList(Y),[endwhile].


:-table expr/3, term/3 ,boolean/3, eval_bool/4, boolean1/3, boolean2/3, boolean3/3, boolean4/3.

/*
* Boolean Parsing
*/
boolean(t_booleanExprCond(X,or,Z)) --> boolean(X),[or],boolean1(Z).
boolean(X) -->boolean1(X).

boolean1(t_booleanExprCond(X,and,Z)) --> boolean1(X), [and], boolean2(Z).
boolean1(X) --> boolean2(X).

boolean2(t_booleanNegate(X)) --> [!],boolean3(X).
boolean2(t_booleanExprNotEquals(X,Y)) --> boolean2(X),[!],equal,boolean3(Y).
boolean2(X)-->boolean3(X).

boolean3(t_booleanExprCond(X,Y,Z)) --> boolean3(X),conditional(Y),boolean4(Z).
boolean3(X) --> boolean4(X).
boolean3(X) -->['('], boolean(X),[')'].

boolean4(X) --> expr(X).

conditional(>) --> [>].
conditional(<) --> [<].
conditional(>=) --> [>,=].
conditional(<=) --> [<,=].
conditional(==) --> [=,=].

booleanI(true) --> [true].
booleanI(false) --> [false].

/*
* Expression Parsing
*/
expr(t_sub(X,Y)) --> expr(X), [-], term(Y).
expr(t_add(X,Y)) --> expr(X), [+], term(Y).
expr(X) --> term(X) .

term(t_mul(X,Y)) --> term(X), [*], factor(Y).
term(t_div(X,Y)) --> term(X), [/], factor(Y).
term(X) --> factor(X).

factor(X) --> ['('],expr(X),[')'].
factor(X) --> digit(X).
factor(X) --> identifier(X).
factor(X) --> booleanI(X).
factor(X) -->['"'], anystring(X),['"'].

display(t_display(X)) --> [print],['('],expr(X),[')'].


/*--------------------------------------Program Evaluation--------------------------------------*/
eval_booleanI(true).
eval_booleanI(false).

eval_program(t_program(X),FinalEnv) :- eval_block(X,[],FinalEnv).
eval_block(t_block(X,Y), EnvIn, EnvOut) :- eval_declrList(X,EnvIn, Env1), eval_commandList(Y, Env1, EnvOut).
eval_declrList(t_declrList(X,Y),EnvIn, EnvOut) :- eval_declR(X,EnvIn, Env1), eval_declrList(Y, Env1, EnvOut).
eval_declrList(t_declrList(X),EnvIn, EnvOut):- eval_declR(X,EnvIn, EnvOut).

eval_declR(t_assign_id(t_id(X),Y),EnvIn, EnvOut) :-eval_expr(Y,EnvIn,EnvOut1,Val), update(X,Val,EnvOut1,EnvOut).

eval_declR(t_identifierList(X,Y), EnvIn, EnvOut) :- eval_declR(X, EnvIn, Env1), eval_declR(Y,Env1,EnvOut).
eval_declR(t_id(X), EnvIn, EnvOut) :- update(X,0,EnvIn,EnvOut).
eval_declR(t_init_list(t_id(X)),EnvIn,EnvOut) :- update(X,([]),EnvIn,EnvOut).

eval_commandList(t_commandList(X,Y),EnvIn, EnvOut) :- eval_commandI(X,EnvIn, Env1), eval_commandList(Y, Env1, EnvOut).
eval_commandList(t_commandList(X),EnvIn, EnvOut) :- eval_commandI(X,EnvIn, EnvOut).
eval_commandI(t_commandInitialize(X,Y),EnvIn,EnvOut) :- eval_id(X,EnvIn,EnvIn,_Val1),eval_Identity(X,Id),
    eval_expr(Y, EnvIn, Env1, Val) ,update(Id,Val,Env1, EnvOut).

eval_commandI(t_display(X),EnvIn,EnvOut) :- eval_expr(X, EnvIn,EnvOut, Val),write(Val),nl.

% Evaluation Logic for IF loop and If-then-else-----------------------------------------------------------------------
eval_commandI(t_ifEval(X,Y),EnvIn,EnvOut):- eval_bool(X,EnvIn,EnvOut1,true),
                                             eval_commandList(Y,EnvOut1,EnvOut).
eval_commandI(t_ifEval(X,_Y),EnvIn,EnvOut):- eval_bool(X,EnvIn,EnvOut,false).
eval_commandI(t_ifteEval(X,Y,_Z),EnvIn,EnvOut):- eval_bool(X,EnvIn,EnvOut1,true),
                                                 eval_commandList(Y,EnvOut1,EnvOut).
eval_commandI(t_ifteEval(X,_Y,Z),EnvIn,EnvOut):- eval_bool(X,EnvIn,EnvOut1,false),
                                                 eval_commandList(Z,EnvOut1,EnvOut).
%----------------------------------------------------------------------------------------------------------------------




% Evaluation Logic for WHILE Loop--------------------------------------------------------------------------------------
eval_commandI(t_whileEval(B,C),EnvIn,EnvOut):-eval_bool(B,EnvIn,EnvIn,true),
                                           eval_commandList(C,EnvIn,Env2),
                                           eval_commandI(t_whileEval(B,C),Env2,EnvOut).
eval_commandI(t_whileEval(B,_C),Env,Env):-eval_bool(B,Env,Env,false).

%----------------------------------------------------------------------------------------------------------------------

% Evaluation Logic for FOR Loop---------------------------------------------------------------------------

eval_commandI(t_traditionalforEval(X,Y,Z,T),EnvIn,EnvOut) :- eval_commandIFor(X,EnvIn, EnvOut1),
                                                             eval_for(Y,Z,T, EnvOut1, EnvOut).
eval_commandI(t_advancedforEval(t_id(X),Y,Z,T),EnvIn,EnvOut) :- Y < Z,update(X,Y,EnvIn, EnvOut1),
                                                          eval_advforinc(X,Z,T, EnvOut1, EnvOut).

eval_commandI(t_advancedforEval(t_id(X),Y,Z,T),EnvIn,EnvOut) :- Y > Z,update(X,Y,EnvIn, EnvOut1),
                                                          eval_advfordec(X,Z,T, EnvOut1, EnvOut).

eval_commandI(t_ternary(t_id(W),X,Y,_),EnvIn,EnvOut):- eval_bool(X,EnvIn,EnvOut1,true),
    eval_expr(Y,EnvOut1,EnvOut2,Val),
    update(W,Val,EnvOut2,EnvOut).
eval_commandI(t_ternary(t_id(W),X,_,Z),EnvIn,EnvOut):- eval_bool(X,EnvIn,EnvOut1,false),
    eval_expr(Z,EnvOut1,EnvOut2,Val),
    update(W,Val,EnvOut2,EnvOut).


eval_commandI(t_list_push_first(t_id(X),Y),EnvIn,EnvOut) :-eval_expr(Y,EnvIn,EnvOut1,Val),
    lookup(X,EnvOut1,ListOut), push_first(Val,ListOut,Val1),
    update(X,Val1,EnvOut1,EnvOut).

eval_commandI(t_list_push_last(t_id(X),Y),EnvIn,EnvOut) :-eval_expr(Y,EnvIn,EnvOut1,Val),
    lookup(X,EnvOut1,ListOut), push_last(Val,ListOut,Val1),
    update(X,Val1,EnvOut1,EnvOut).

eval_commandI(t_list_pop_first(t_id(X)),EnvIn,EnvOut) :-lookup(X,EnvIn,Val), pop_first(Val,Val1,_),
    update(X,Val1,EnvIn,EnvOut).

eval_commandI(t_list_pop_first_assign(t_id(X),t_id(Y)),EnvIn,EnvOut) :- lookup(X,EnvIn,Val), pop_first(Val,Val1,Val2),
      lookup(Y,EnvIn,_), update(X,Val1,EnvIn,EnvOut1),
    update(Y,Val2, EnvOut1,EnvOut).


eval_commandI(t_list_pop_last(t_id(X)),EnvIn,EnvOut) :-lookup(X,EnvIn,Val), pop_last(Val,Val1,_),
    update(X,Val1,EnvIn,EnvOut).

eval_commandI(t_list_pop_last_assign(t_id(X),t_id(Y)),EnvIn,EnvOut) :- lookup(X,EnvIn,Val), pop_last(Val,Val1,Val2),
      lookup(Y,EnvIn,_), update(X,Val1,EnvIn,EnvOut1),
    update(Y,Val2, EnvOut1,EnvOut).





eval_commandI(t_list_isempty(t_id(X)),EnvIn,EnvIn) :- lookup(X,EnvIn,Val), length(Val,Val1),Val1 is 0.

eval_commandI(t_list_isempty_assign(t_id(X),t_id(Y)),EnvIn,EnvOut) :- lookup(X,EnvIn,Val), length(Val,Val1),Val1 is 0,
    update(Y,true,EnvIn,EnvOut).

eval_commandI(t_list_isempty_assign(t_id(X),t_id(Y)),EnvIn,EnvOut) :- lookup(X,EnvIn,Val), length(Val,Val1),Val1 > 0,
    update(Y,false,EnvIn,EnvOut).



eval_commandIFor(t_commandInitialize(t_id(X),Y),EnvIn,EnvOut) :-eval_expr(Y, EnvIn, Env1, Val),
                                                                update(X,Val,Env1, EnvOut).





push_first(X,[],[X]).
push_first(X,L,[X|L]):- L \=[].

push_last(X,[],[X]).
push_last(X,L,R):- L \=[], append(L,[X],R).

pop_first([X],[],X).
pop_first([H|T],T,H) :- length([H|T], L) , L \= 1.

pop_last([X],[],X).
pop_last(L,T,R) :- reverse(L, L1), pop_first(L1,L2,R), reverse(L2,T).



eval_for(Y,Z,T,EnvIn,EnvOut):- eval_bool(Y,EnvIn,EnvOut2,true),
      eval_commandList(T,EnvOut2,EnvOut3),
      eval_commandI(Z,EnvOut3, EnvOut4),
              eval_for(Y,Z,T,EnvOut4,EnvOut).



eval_for(Y,_,_,EnvIn,EnvOut):- eval_bool(Y,EnvIn,EnvOut,false).

% Evaluation for Advanced FOR loop -----------------------------------------------------------------------------------

eval_advforinc(X,Z,T,EnvIn,EnvOut):- lookup(X,EnvIn,K),eval_bool(t_booleanExprCond(K,<,Z),EnvIn,EnvOut2,true),
    eval_commandList(T,EnvOut2,EnvOut3),
    lookup(X,EnvOut3,Val), Val1 is Val + 1,
    update(X,Val1,EnvOut3,EnvOut4),
    eval_advforinc(X,Z,T,EnvOut4,EnvOut).

eval_advforinc(X,Z,_,EnvIn,EnvOut):- lookup(X,EnvIn,K),eval_bool(t_booleanExprCond(K,<,Z),EnvIn,EnvOut,false).

eval_advfordec(X,Z,T,EnvIn,EnvOut):- lookup(X,EnvIn,K),eval_bool(t_booleanExprCond(K,>,Z),EnvIn,EnvOut2,true),
    eval_commandList(T,EnvOut2,EnvOut3),
    lookup(X,EnvOut3,Val), Val1 is Val - 1,
    update(X,Val1,EnvOut3,EnvOut4),
    eval_advfordec(X,Z,T,EnvOut4,EnvOut).

eval_advfordec(X,Z,_,EnvIn,EnvOut):- lookup(X,EnvIn,K),eval_bool(t_booleanExprCond(K,>,Z),EnvIn,EnvOut,false).



% Boolean Evaluation Logic---------------------------------------------------------------------------------------------
not(true,false).
not(false,true).

equal(Val1,Val2,true):-Val1=Val2.
equal(Val1,Val2,false):- Val1\=Val2.

greaterThan(Val1,Val2,true) :- Val1 > Val2.
greaterThan(Val1,Val2,false) :- Val1 =< Val2.

lessThan(Val1,Val2,true) :- Val1 < Val2.
lessThan(Val1,Val2,false) :- Val1 >= Val2.


greaterThanorEqual(Val1,Val2,true) :- Val1 >= Val2.
greaterThanorEqual(Val1,Val2,false) :- Val1 < Val2.

lessThanorEqual(Val1,Val2,true) :- Val1 =< Val2.
lessThanorEqual(Val1,Val2,false) :- Val1 > Val2.

equalForAnd(true,true,true).
equalForAnd(true,false,false).
equalForAnd(false,_,false).

eval_bool(true,Env,Env,true).
eval_bool(false,Env,Env,false).


eval_bool(t_booleanExprCond(X,and,Y),EnvIn,EnvOut,Val):- eval_bool(X,EnvIn,Env1,Val1),
      eval_bool(Y,Env1,EnvOut,Val2),
      equalForAnd(Val1,Val2,Val).

eval_bool(t_booleanExprCond(X,or,_Y),EnvIn,EnvOut,true):- eval_bool(X,EnvIn,EnvOut,true).

eval_bool(t_booleanExprCond(X,or,Y),EnvIn,EnvOut,true):- eval_bool(X,EnvIn,Env1,false),
    eval_bool(Y,Env1,EnvOut,true).

eval_bool(t_booleanExprCond(X,or,Y),EnvIn,EnvOut,false):- eval_bool(X,EnvIn,Env1,false),
    eval_bool(Y,Env1,EnvOut,false).

eval_bool(t_booleanNegate(B),EnvIn,EnvOut,Val):-eval_bool(B,EnvIn,EnvOut,Val1),
                                                not(Val1,Val).
eval_bool(t_booleanNegate(B),EnvIn,EnvOut,Val):-eval_id(B,EnvIn,EnvOut,Val1),
                                                not(Val1,Val).

eval_bool(t_booleanExprCond(E1,==,E2),Env,NewEnv,Val):-eval_expr(E1,Env,Env1,Val1),
                                                      eval_expr(E2,Env1,NewEnv,Val2),
                                                      equal(Val1,Val2,Val).
eval_bool(t_booleanExprNotEquals(E1,E2),Env,NewEnv,Val):-eval_expr(E1,Env,Env1,Val1),
                                                      eval_expr(E2,Env1,NewEnv,Val2),
                                                      equal(Val1,Val2,Val3), not(Val3,Val).

eval_bool(t_booleanExprCond(E1,<,E2),Env,NewEnv,Val):-eval_expr(E1,Env,Env1,Val1),
                                                         eval_expr(E2,Env1,NewEnv,Val2),
                                                         lessThan(Val1,Val2,Val).

eval_bool(t_booleanExprCond(E1,>,E2),Env,NewEnv,Val):-eval_expr(E1,Env,Env1,Val1),
                                                         eval_expr(E2,Env1,NewEnv,Val2),
                                                         greaterThan(Val1,Val2,Val).

eval_bool(t_booleanExprCond(E1,=<,E2),Env,NewEnv,Val):-eval_expr(E1,Env,Env1,Val1),
                                                         eval_expr(E2,Env1,NewEnv,Val2),
                                                         lessThanorEqual(Val1,Val2,Val).

eval_bool(t_booleanExprCond(E1,<=,E2),Env,NewEnv,Val):-eval_expr(E1,Env,Env1,Val1),
                                                         eval_expr(E2,Env1,NewEnv,Val2),
                                                         lessThanorEqual(Val1,Val2,Val).


eval_bool(t_booleanExprCond(E1,=>,E2),Env,NewEnv,Val):-eval_expr(E1,Env,Env1,Val1),
                                                         eval_expr(E2,Env1,NewEnv,Val2),
                                                         greaterThanorEqual(Val1,Val2,Val).

eval_bool(t_booleanExprCond(E1,>=,E2),Env,NewEnv,Val):-eval_expr(E1,Env,Env1,Val1),
                                                         eval_expr(E2,Env1,NewEnv,Val2),
                                                         greaterThanorEqual(Val1,Val2,Val).
%----------------------------------------------------------------------------------------------------------------------
%Evaluate expression when t_add tree node is encountered

%eval_expr_str(X,EnvIn,EnvOut,Val):-eval_id(X,EnvIn,EnvOut,Val).

eval_expr(t_add(X,Y),EnvIn, EnvOut, Val) :-
    eval_expr(X,EnvIn,EnvOut1,Val1),eval_expr(Y,EnvOut1,EnvOut,Val2),
    number(Val1),number(Val2),Val is Val1 + Val2.


%Evaluate expression when t_sub tree node is encountered
eval_expr(t_sub(X,Y),EnvIn, EnvOut, Val) :- eval_expr(X,EnvIn,EnvOut1,Val1),
    eval_expr(Y,EnvOut1,EnvOut,Val2),
    number(Val1),number(Val2),Val is Val1 - Val2.

%Evaluate expression when t_mul tree node is encountered
eval_expr(t_mul(X,Y),EnvIn,EnvOut, Val) :- eval_expr(X,EnvIn,EnvOut1,Val1),
    eval_expr(Y,EnvOut1,EnvOut,Val2),
    number(Val1),number(Val2),Val is Val1 * Val2.

%Evaluate expression when t_div tree node is encountered
eval_expr(t_div(X,Y),EnvIn,EnvOut, Val) :- eval_expr(X,EnvIn,EnvOut1,Val1),
    eval_expr(Y,EnvOut1,EnvOut,Val2),
    number(Val1),number(Val2),Val is Val1 / Val2.


eval_expr(t_add(X,Y),EnvIn, EnvOut, Val) :-
    eval_expr(X,EnvIn,EnvOut1,Val1),eval_expr(Y,EnvOut1,EnvOut,Val2),
    atom(Val1),atom(Val2),concat(Val1,Val2,Val).

eval_expr(t_id_expr_equality(X,Y),EnvIn,EnvOut,Result):-eval_expr(Y,EnvIn,EnvOut1,Result),
                                                        update(X,Result,EnvOut1,EnvOut).
eval_expr(X,Env,Env,X) :- number(X).
eval_expr(X,Env,Env,Val):- eval_string(X,Env,Env,Val).
eval_expr(X,EnvIn,EnvOut,Result) :- eval_id(X,EnvIn,EnvOut,Result).
eval_expr(X,EnvIn,EnvOut,Result) :- eval_bool(X,EnvIn,EnvOut,Result).
eval_id(t_id(X),EnvIn,EnvIn,Result):- lookup(X,EnvIn,Result).
eval_id(t_id(X),EnvIn,EnvIn,Result):- \+lookup(X,EnvIn,Result),write("VARIABLE ") ,  write(X), write(" NOT INITIALIZED"),nl, fail.
eval_string(t_string(X),Env, Env, Val):- Val = X.
eval_Identity(t_id(X),X).


lookup(Id,[(Id,Val)|_],Val).
lookup(Id,[_|T],Val):- lookup(Id,T,Val).

update(Id,Val,[],[(Id,Val)]).
update(Id,Val,[(Id,_)|T],[(Id,Val)|T]).
update(Id,Val,[H|T],[H|R]):-H \=(Id,_),update(Id,Val,T,R).