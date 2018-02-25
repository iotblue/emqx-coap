PROJECT = emqx_coap
PROJECT_DESCRIPTION = CoAP Gateway
PROJECT_VERSION = 3.0

DEPS = lager gen_coap clique
dep_lager    = git https://github.com/basho/lager
dep_gen_coap = git https://github.com/emqtt/gen_coap
dep_clique   = git https://github.com/emqtt/clique

BUILD_DEPS = emqx cuttlefish
dep_emqx = git https://github.com/emqtt/emqttd emqx30
dep_cuttlefish = git https://github.com/emqtt/cuttlefish

TEST_DEPS = er_coap_client
dep_er_coap_client = git https://github.com/grutabow/er_coap_client

ERLC_OPTS += +debug_info
ERLC_OPTS += +'{parse_transform, lager_transform}'
TEST_ERLC_OPTS += +'{parse_transform, lager_transform}'

include erlang.mk

app.config::
	./deps/cuttlefish/cuttlefish -l info -e etc/ -c etc/emqx_coap.conf -i priv/emqx_coap.schema -d data
