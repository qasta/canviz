# $Id$

AWK=awk
FIND=find
SED=sed
SORT=sort
TAIL=tail
XARGS=xargs
DOT=$(shell which dot)
GRAPHVIZ_PREFIX=$(shell dirname $(shell dirname $(DOT)))
GRAPHVIZ_SRC:=$(shell $(FIND) . -type d -name 'graphviz-*' | $(TAIL) -n 1 | $(SED) s%^\./%%)
GRAPHVIZ_LAYOUTS=circo dot fdp neato twopi
GRAPHVIZ_FIRST_LAYOUT=$(firstword $(GRAPHVIZ_LAYOUTS))
EXAMPLE_GRAPHS_SRC_DIR:=$(GRAPHVIZ_PREFIX)/share/graphviz/graphs
#EXAMPLE_GRAPHS_SRC_DIR:=$(GRAPHVIZ_SRC)/rtest/graphs
EXAMPLE_GRAPHS_SRC:=$(shell $(FIND) $(EXAMPLE_GRAPHS_SRC_DIR) -type f -name '*.dot' -or -name '*.gv')
EXAMPLE_GRAPHS_DIR=./graphs
EXAMPLE_GRAPH_IMAGES_DIR=$(EXAMPLE_GRAPHS_DIR)/images
EXAMPLE_GRAPHS=$(patsubst $(EXAMPLE_GRAPHS_SRC_DIR)/%,$(EXAMPLE_GRAPHS_DIR)/$(GRAPHVIZ_FIRST_LAYOUT)/%.txt,$(EXAMPLE_GRAPHS_SRC))

.PHONY: all examples examples-images colorschemes clean

all: examples

colorschemes: x11colors.js brewercolors.js

examples: $(EXAMPLE_GRAPHS_DIR)/graphlist.js $(EXAMPLE_GRAPHS_DIR)/layoutlist.js $(EXAMPLE_GRAPHS) examples-images

$(EXAMPLE_GRAPHS_DIR):
	mkdir $(EXAMPLE_GRAPHS_DIR)

$(EXAMPLE_GRAPH_IMAGES_DIR):
	mkdir $(EXAMPLE_GRAPH_IMAGES_DIR)

$(EXAMPLE_GRAPHS_DIR)/graphlist.js: graphlist.awk $(EXAMPLE_GRAPHS_DIR)
	@echo "Generating $@"
	@echo $(patsubst $(EXAMPLE_GRAPHS_SRC_DIR)/%,%,$(EXAMPLE_GRAPHS_SRC)) | $(AWK) -f graphlist.awk > $@;

$(EXAMPLE_GRAPHS_DIR)/layoutlist.js: layoutlist.awk $(EXAMPLE_GRAPHS_DIR)
	@echo "Generating $@"
	@echo $(GRAPHVIZ_LAYOUTS) | $(AWK) -f layoutlist.awk > $@;

$(EXAMPLE_GRAPHS_DIR)/$(GRAPHVIZ_FIRST_LAYOUT)/%.dot.txt: $(EXAMPLE_GRAPHS_SRC_DIR)/%.dot $(EXAMPLE_GRAPHS_DIR)
	$(render-example-graph)

$(EXAMPLE_GRAPHS_DIR)/$(GRAPHVIZ_FIRST_LAYOUT)/%.gv.txt: $(EXAMPLE_GRAPHS_SRC_DIR)/%.gv $(EXAMPLE_GRAPHS_DIR)
	$(render-example-graph)

define render-example-graph
@echo "Rendering $(subst /$(GRAPHVIZ_FIRST_LAYOUT)/,/*/,$@)"
@./render_example_graph.sh $(EXAMPLE_GRAPHS_SRC_DIR) $(patsubst $(EXAMPLE_GRAPHS_SRC_DIR)/%,%,$<) $(EXAMPLE_GRAPHS_DIR) $(GRAPHVIZ_PREFIX) $(GRAPHVIZ_LAYOUTS)
endef

examples-images: $(EXAMPLE_GRAPH_IMAGES_DIR)
	$(FIND) $(EXAMPLE_GRAPHS_SRC_DIR) -type f -name '*.gif' -or -name '*.jpg' -or -name '*.png' -print0 | $(XARGS) -0 -t -n 1 -J % cp % $(EXAMPLE_GRAPH_IMAGES_DIR)


x11colors.js: gvcolors.awk $(GRAPHVIZ_SRC)/lib/common/color_names
	$(AWK) -f gvcolors.awk < $(GRAPHVIZ_SRC)/lib/common/color_names > $@

brewercolors.js: gvcolors.awk $(GRAPHVIZ_SRC)/lib/common/brewer_lib
	$(AWK) -f gvcolors.awk < $(GRAPHVIZ_SRC)/lib/common/brewer_lib > $@

/lib/common/color_names /lib/common/brewer_lib:
	@echo 'Unpack the Graphviz source in this directory first.' 1>&2
	@exit 1

clean:
	-rm -rf $(EXAMPLE_GRAPHS_DIR)
