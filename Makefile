OBO=http://purl.obolibrary.org/obo
all: all.tsv all_run_all all_run_exact all_run_exrel all_summary all_diff

ONTS = go cl chebi so pr


all.tsv:
	./bin/annxml2tsv.pl craft-1.0/xml/{chebi,cl,go_bpmf,go_cc,pr,so}/*xml > $@

all_gzip: $(patsubst %,gzip-%,$(ONTS))
all_ungzip: $(patsubst %,ungzip-%,$(ONTS))

mirror/cl.obo:
	wget $(OBO)/cl/cl-basic.obo -O $@
mirror/go.obo:
	wget $(OBO)/go/go-basic.obo -O $@
mirror/%.obo:
	wget --no-check-certificate $(OBO)/$*.obo -O $@
.PRECIOUS: mirror/%.obo

gzip-%: target/%-syns.yaml target/%-syns.json
	gzip $^
ungzip-%: target/%-syns.yaml.gz target/%-syns.json.gz
	gzip -dc target/$*-syns.yaml.gz > target/$*-syns.yaml
	gzip -dc target/$*-syns.json.gz > target/$*-syns.json

target/%-syns.yaml: mirror/%.obo
	extract-obo-syns.pl  $< > $@
.PRECIOUS: target/%-syns.yaml
target/%-syns.json: target/%-syns.yaml
	yaml2json.pl $< > $@
.PRECIOUS: target/%-syns.json

target/%.gz: target/%
	gzip $<

all_run_all: $(patsubst %,run-all-%.tsv,$(ONTS))
all_run_exact: $(patsubst %,run-exact-%.tsv,$(ONTS))
all_run_exrel: $(patsubst %,run-exrel-%.tsv,$(ONTS))

all_summary: $(patsubst %,summary-%.txt,$(ONTS))

all_diff: $(patsubst %,diff-%.txt,$(ONTS))

diff-%.txt: run-all-%.tsv run-exact-%.tsv
	diff $^ > $@ || echo


run-all-%.tsv: target/%-syns.json all.tsv
	./src/eval-synonym-strategy.py -i $* -s all -t all.tsv $< > $@.tmp && mv $@.tmp $@
.PRECIOUS: run-all-%.tsv

run-exact-%.tsv: target/%-syns.json all.tsv
	./src/eval-synonym-strategy.py -i $* -s exact -t all.tsv $< > $@.tmp && mv $@.tmp $@
.PRECIOUS: run-exact-%.tsv

run-exrel-%.tsv: target/%-syns.json all.tsv
	./src/eval-synonym-strategy.py -i $* -s exrel -t all.tsv $< > $@.tmp && mv $@.tmp $@
.PRECIOUS: run-exrel-%.tsv

summary-%.txt: run-all-%.tsv run-exact-%.tsv run-exrel-%.tsv
	grep  ^### $^  > $@
#	grep -v ^# $< | cut -f1 | count-occ.pl > $@
