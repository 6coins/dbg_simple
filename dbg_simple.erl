-module(dbg_simple).

-export([start/0,
        tpl/1,
         tpl/3, 
         tpl/4,
         p/1, 
         p/2,
         stop/0]).

-include_lib("stdlib/include/ms_transform.hrl").

%%%===================================================================
%%% Api functions
%%%==================================================================

%% @doc 通过脚本启动
%% @spec start() -> ok
start() ->
    {ok, [Config]} = file:consult("./config.config"),                                                  % 读取配置文件
    Remote_node = proplists:get_value(remote_node, Config),                                     % 得到远程节点
    Remote_node_cookie = proplists:get_value(remote_node_cookie, Config),                       % 得到远程节点cookie
    {Module, Function,Arity} = proplists:get_value(module_function_arity, Config),              % 追踪的模块,函数,参数个数
    true = erlang:set_cookie(node(), Remote_node_cookie),                                       % 把本地节点cooki设置的和远程节点一样才能追踪
    ok = tpl(Remote_node, Module, Function, Arity),                                             % 设置追踪项
    io:format("~n=>start trace !!~n=>trace node is ~p~n=>trace function is ~p:~p/~p~n~n",       % 打印提示信息
              [Remote_node, Module, Function, Arity]),
    ok.

%% @doc 追踪远程节点函数调用(一定要和远程节点使用同样名字类型, 同样的cookie)
%% @spec tpl(Module, Function, Arity)-> ok
%% @spec tpl(Node, Module, Function, Arity)-> ok
%% @spec tpl([Node, Module, Function, Arity])-> ok
%%      Node = atom()               节点(形如nodename@host)
%%      Module = atom() | '_'       模块
%%      Function = atom() | '_'     函数
%%      Arity = integer() |'_'      参数个数(如果'_'则追踪时不区分参数个数)
%% @end
tpl(Module, Function, Arity)->
    tpl(node(), Module, Function, Arity).

tpl(Node, Module, Function, Arity)-> 
    dbg:stop_clear(),                                     % 清除以前追踪的函数
    {ok, _pid} = dbg:tracer(process,{fun msg_handle/2, 0}),         % 设置消息处理函数
    {ok, _Nodename} = dbg:n(Node),                                  % 设置追踪的节点
    {ok, _MatchDesc} = dbg:tpl(Module, Function, Arity, p_and_return_MS()),     % 设置追踪的函数                     
    ok.

tpl([Node, Module, Function, Arity])-> 
    tpl(Node, Module, Function, Arity).

%% @doc 追踪节点进程收发消息
%% @spec p(Pid)-> ok.
%% @spec p(Node, Pid)-> ok.     
%%      Node = atom()               远程节点名(形如nodename@host)
%%      Pid = pid()                 进程id
%% @end
p(Pid)->
    p(node(), Pid).

p(Node,Pid)->
    dbg:stop_clear(),                                     % 清除以前追踪的函数
    {ok, _pid} = dbg:tracer(process,{fun msg_handle/2, 0}),         % 设置消息处理函数
    {ok, _Nodename} = dbg:n(Node),                                  % 设置追踪的节点
    dbg:p(Pid,all),                                                 % 设置追踪的进程id
    ok.

%% @doc 停止追踪
%% @spec stop()-> ok.
stop() -> 
    dbg:stop_clear(),
    ok.

%%%===================================================================
%%% Internal functions
%%%===================================================================

%% @doc 消息处理函数
msg_handle(_Msg={_trace,_Pid,call,{Mod,Func,Args}},_)->
    print_call(Mod,Func,Args),
    0;
msg_handle(_Msg={_trace_ts,_Pid,call,{Mod,Func,Args},_Time},_)->
    print_call(Mod,Func,Args),
    0;
msg_handle(_Msg={_trace,_Pid,return_from,{Mod,Func,ArgCount},ReturnData},_)->
    print_return(Mod,Func,ArgCount,ReturnData),
    0;
msg_handle(_Msg={_trace_ts,_Pid,return_from,{Mod,Func,ArgCount},ReturnData,_Time},_)->
    print_return(Mod,Func,ArgCount,ReturnData),
    0;
msg_handle(Msg,_)->
    io:format("~p~n", [Msg]),
    0.

%% @doc 打印调用信息
print_call(Mod,Func,Args)->
    io:format("call-----------------------~n"),
    io:format("~p:~p~n", [Mod,Func]),
    io:format("args->~p~n", [Args]),
    io:format("~n").

%% @doc 打印返回信息
print_return(Mod,Func,ArgCount,ReturnData)->
    io:format("return_from-----------------~n"),
    io:format("~p:~p/~p~n", [Mod,Func,ArgCount]),
    io:format("return->~p~n", [ReturnData]),
    io:format("~n").

%% @doc 
p_and_return_MS()->
    dbg:p(all,call),
    _MS=dbg:fun2ms(fun(_) -> return_trace() end).

%%%===================================================================
%%% test functions
%%%
%%% 1.启动远程节点
%%%     erl -setcookie cookie_value -sname remote_node
%%%
%%% 2.启动本地节点, 编译模块
%%%     erl -setcookie cookie_value -sname local_node
%%%     c(dbg_simple).
%%%
%%% 3.在本地节点设置要跟踪的远程节点和函数
%%%     dbg_simple:tpl('remote_node@EMP4', io, format, 1).
%%%
%%% 4.在远程节点执行被追踪的函数
%%%     io:format("111").
%%%
%%% 3.在本地节点输入追踪到的内容
%%%     call-----------------------
%%%     io:format
%%%     args->["111"]
%%%
%%%     return_from-----------------
%%%     io:format/1
%%%     return->ok
%%%
%%%==================================================================


