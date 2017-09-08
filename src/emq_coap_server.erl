%%--------------------------------------------------------------------
%% Copyright (c) 2016-2017 EMQ Enterprise, Inc. (http://emqtt.io)
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%--------------------------------------------------------------------

-module(emq_coap_server).

-include("emq_coap.hrl").

-export([start/0, start/1, stop/0]).

-define(LOG(Level, Format, Args),
    lager:Level("CoAP: " ++ Format, Args)).

start() ->
    start(application:get_env(?APP, port, 5683)).

start(Port) ->
    application:start(gen_coap),
    coap_server_registry:add_handler([<<"mqtt">>], emq_coap_resource, undefined),
    coap_server_registry:add_handler([<<"ps">>], emq_coap_ps_resource, undefined),

    start_udp(Port, erlang:system_info(schedulers)*2),

    CertFile = application:get_env(?APP, certfile, ""),
    KeyFile = application:get_env(?APP, keyfile, ""),
    case (filelib:is_regular(CertFile) andalso filelib:is_regular(KeyFile)) of
        true ->
            coap_server:start_dtls(coap_dtls_socket, [{certfile, CertFile}, {keyfile, KeyFile}]);
        false ->
            ?LOG(error, "certfile ~p or keyfile ~p are not valid, turn off coap DTLS", [CertFile, KeyFile])
    end,

    % TODO: start topic process by a supervisor
    emq_coap_ps_topics:start().

stop() ->
    application:stop(gen_coap).


start_udp(_Port, 0) ->
    ok;
start_udp(Port, Count) ->
    Name = "coap_udp_socket_" ++ integer_to_list(Count),
    Atom = case catch list_to_existing_atom(Name) of
               {'EXIT', _} -> list_to_atom(Name);
               ExistAtom   -> ExistAtom
           end,
    coap_server:start_udp(Atom, Port),
    start_udp(Port, Count - 1).


logm(Format, Args) ->
    lager:error(Format, Args).


