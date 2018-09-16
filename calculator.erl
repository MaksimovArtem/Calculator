-module(calculator).
-export([calc/1,rpn/1]).

calc(String) ->
	Priority = #{"(" => 0,
				 "+" => 1, "-" => 1,
				 "*" => 2, "/" => 2,
				 "^" => 3},	
	calculate(string:tokens(String," "),[],[],Priority).

calculate([],List1,List2,_Priority) ->
	{ListRPN,_StackRPN} = get_operations(List2,List1),
	ListAnswer = make_string(lists:reverse(ListRPN),""),
	rpn(ListAnswer);

calculate([H1|T],RPN_list,Operations_stack,Priority) ->
	{H,[]} = case string:to_float(H1) of
		{error,badarg} ->
			{H1,[]};
		{error,no_float} ->
			case string:to_integer(H1) of
				{error,no_integer} ->
					{H1,[]};
				{Int,Smth} ->
					{Int,Smth}
			end;
		{Float,[]} ->
			{Float,[]}
		end,

	case is_number(H) of
		true ->
			List2 = [H|RPN_list],
			calculate(T,List2,Operations_stack,Priority);
		false ->
			case length(Operations_stack) of
				0 ->
					Stack2 = [H|Operations_stack],
					calculate(T,RPN_list,Stack2,Priority);
				_ ->
					if  H =:= "(" ->
							Stack2 = [H|Operations_stack],
							calculate(T,RPN_list,Stack2,Priority);
						H =:= ")" ->
							{List2,Stack3} = get_operations(Operations_stack, RPN_list),
							calculate(T,List2, Stack3,Priority);
						true ->
							case maps:get(H,Priority) > maps:get(lists:last(lists:reverse(Operations_stack)),Priority) of
								true ->
									calculate(T,RPN_list,[H|Operations_stack],Priority);
								false ->
									{List2,Stack3} = get_operations_priority(Operations_stack,RPN_list,Priority),
									Stack4 = [H|Stack3],
									calculate(T,List2,Stack4,Priority)
							end
					end
			end
	end.

get_operations([], List) ->
	{List,[]};
get_operations([H|T], List_output_reversed)->
	case H =:= "(" of
		true ->
			{List_output_reversed, T};
		false ->
			List2 = [H|List_output_reversed],
			get_operations(T,List2)
	end.

get_operations_priority([],List,_Priority) ->
	{List,[]};
get_operations_priority([H|T],List_output_reversed,Priority)->
	Operations_stack = [H|T],
	case maps:get(H,Priority) =< maps:get(lists:last(lists:reverse(Operations_stack)),Priority) of
		true->
			List2 = [H|List_output_reversed],
			get_operations_priority(T,List2,Priority);
		false->
			{List_output_reversed,T}
	end.

make_string([],String) ->
	String;
make_string([H|T],String) ->
	case is_list(H) of
		true ->
			String2 = String ++ H ++ " ",
			make_string(T,String2);
		false ->
			case is_integer(H) of
				true ->
					String2 = String ++ integer_to_list(H)++ " ",
					make_string(T,String2);
				false ->
					String2 = String ++ float_to_list(H) ++ " ",
					make_string(T,String2)
			end
	end.

rpn(L) when is_list(L) ->
    [Res] = lists:foldl(fun rpn/2, [], string:tokens(L, " ")),
    Res.

rpn("+", [N1,N2|S]) -> [N2+N1|S];
rpn("-", [N1,N2|S]) -> [N2-N1|S];
rpn("*", [N1,N2|S]) -> [N2*N1|S];
rpn("/", [N1,N2|S]) -> [N2/N1|S];
rpn("^", [N1,N2|S]) -> [math:pow(N2,N1)|S];
rpn("ln", [N|S])    -> [math:log(N)|S];
rpn("log10", [N|S]) -> [math:log10(N)|S];
rpn(X, Stack) -> [read(X)|Stack].

read(N) ->
    case string:to_float(N) of
        {error,no_float} -> 
        	list_to_integer(N);
        {F,_} -> F
    end.

