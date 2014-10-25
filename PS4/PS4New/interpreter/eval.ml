open Ast

type builtin = value list -> environment -> value

and procedure =
  | ProcBuiltin of builtin
  | ProcLambda of variable list * environment * expression list

and value =
  | ValDatum of datum
  | ValProcedure of procedure

and binding = value ref Environment.binding
and environment = value ref Environment.environment

(* Exceptions*)
exception Error of string 

(* Parses a datum into an expression. *)
let rec read_expression (input : datum) : expression =


  (* Helper functions for read_expression.*)
  let rec cons_to_exp_list (dat : datum) : expression list =
    match dat with 
    | Cons (car,Nil) -> [read_expression car]
    | Cons (car,cdr) -> (read_expression car)::(cons_to_exp_list cdr)
    | _ -> [read_expression dat]
  in

  let rec cons_to_var_list (dat : datum) : variable list =
    match dat with 
    | Nil -> []
    | Atom (Identifier id) -> [Identifier.variable_of_identifier id]
    | Cons (car,cdr) -> 
        (cons_to_var_list car) @ (cons_to_var_list cdr)
    | _ -> raise (Error "cons_to_var_list, this should be a variable")
  in

  let rec let_binding_helper (dat : datum) : let_binding list = 
    match dat with
    | Cons ( Cons (Atom (Identifier id), cdr'), Nil) 
        when Identifier.is_valid_variable id -> 
        [((Identifier.variable_of_identifier id),(read_expression cdr'))]

    | Cons ( Cons (Atom (Identifier id),cdr'), cdr) 
        when Identifier.is_valid_variable id -> 
        ((Identifier.variable_of_identifier id),(read_expression cdr'))::
        (let_binding_helper cdr)

    | _ -> raise (Error "let_binding_helper warning, datum must be let binding")
in

  match input with
  | Nil -> raise (Error "Nil matched in read_expression")

  (* Self evaluating matches*)
  | Atom (Identifier id) when Identifier.is_valid_variable id ->
    ExprVariable (Identifier.variable_of_identifier id)

  | Atom (Identifier id) -> ExprVariable (Identifier.variable_of_identifier id)
  | Atom (Boolean b) -> ExprSelfEvaluating (SEBoolean b)
  | Atom (Integer i) -> ExprSelfEvaluating (SEInteger i)

  (* Cons(keyword, cdr) matches*)
  | Cons (Atom (Identifier id),cdr) when Identifier.string_of_identifier id = 
      "quote" -> ExprQuote cdr

  | Cons (Atom (Identifier id),(Cons (a, (Cons (b, c))))) when 
      Identifier.string_of_identifier id = "if" ->
      ExprIf ((read_expression a), (read_expression b), (read_expression c))

  | Cons (Atom (Identifier id),Cons (car',cdr')) when 
      Identifier.string_of_identifier id = 
      "lambda" -> ExprLambda ((cons_to_var_list car'),(cons_to_exp_list cdr'))

  | Cons (Atom (Identifier id), Cons (Atom (Identifier var),cdr)) 
      when Identifier.string_of_identifier id = 
      "set!" -> ExprAssignment 
      ((Identifier.variable_of_identifier var),(read_expression cdr)) 

  | Cons (Atom (Identifier id), Cons(b1, cdr')) when 
      Identifier.string_of_identifier id = 
      "let" -> ExprLet ((let_binding_helper b1),(cons_to_exp_list cdr')) 

  | Cons (Atom (Identifier id), Cons(b1, cdr')) when 
      Identifier.string_of_identifier id = 
      "let*" -> ExprLetStar ((let_binding_helper b1),(cons_to_exp_list cdr')) 

  | Cons (Atom (Identifier id), Cons(b1, cdr')) when 
      Identifier.string_of_identifier id = 
      "letrec" -> ExprLetRec ((let_binding_helper b1),(cons_to_exp_list cdr')) 

  (* Cons recursive calls*)
  | Cons (car, Nil) -> read_expression car
  | Cons (car, cdr) -> ExprProcCall (read_expression car, cons_to_exp_list cdr)



(* Parses a datum into a toplevel input. *)
let read_toplevel (input : datum) : toplevel =
  (*match input with
  | _ -> failwith "Sing the Rowing Song!"
  | Cons (Atom (Identifier id),cdr) when Identifier.string_of_identifier id = 
      "define" -> ExprAssignment (read_expression cdr) *)
failwith "ethan is great"

(* This function returns an initial environment with any built-in
   bound variables. *)
let rec initial_environment () : environment =
  failwith "You know!"

(* Evaluates an expression down to a value in a given environment. *)
(* You may want to add helper functions to make this function more
   readable, because it will get pretty long!  A good rule of thumb
   would be a helper function for each pattern in the match
   statement. *)
and eval (expression : expression) (env : environment) : value =
  match expression with
  | ExprSelfEvaluating _
  | ExprVariable _        ->
     failwith "'Oh I sure love to row my boat with my...oar."
  | ExprQuote _           ->
     failwith "Rowing!"
  | ExprLambda (_, _)
  | ExprProcCall _        ->
     failwith "Sing along with me as I row my boat!'"
  | ExprIf (_, _, _) ->
     failwith "But I love you!"
  | ExprAssignment (_, _) ->
     failwith "Say something funny, Rower!"
  | ExprLet (_, _)
  | ExprLetStar (_, _)
  | ExprLetRec (_, _)     ->
     failwith "Ahahaha!  That is classic Rower."

(* Evaluates a toplevel input down to a value and an output environment in a
   given environment. *)
let eval_toplevel (toplevel : toplevel) (env : environment) :
      value * environment =
  match toplevel with
  | ToplevelExpression expression -> (eval expression env, env)
  | ToplevelDefinition (_, _)     ->
     failwith "I couldn't have done it without the Rower!"

let rec string_of_value value =
  let rec string_of_datum datum =
    match datum with
    | Atom (Boolean b) -> if b then "#t" else "#f"
    | Atom (Integer n) -> string_of_int n
    | Atom (Identifier id) -> Identifier.string_of_identifier id
    | Nil -> "()"
    | Cons (car, cdr) -> string_of_cons car cdr

  and string_of_cons car cdr =
    let rec strings_of_cons cdr =
      match cdr with
      | Nil -> []
      | Cons (car, cdr) -> (string_of_datum car) :: (strings_of_cons cdr)
      | _ -> ["."; string_of_datum cdr;] in
    let string_list = (string_of_datum car) :: (strings_of_cons cdr) in
    "(" ^ (String.concat " " string_list) ^ ")" in
  
  match value with
  | ValDatum (datum) -> string_of_datum datum
  | ValProcedure (ProcBuiltin p) -> "#<builtin>"
  | ValProcedure (ProcLambda (_, _, _)) -> "#<lambda>"