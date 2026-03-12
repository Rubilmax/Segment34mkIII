include .env

MONKEYC := java -XX:ReservedCodeCacheSize=256m -XX:-TieredCompilation -jar "$(SDK_HOME)/bin/monkeybrains.jar"
JUNGLE := monkey.jungle

.PHONY: iq sim clean

iq: Segment34Plus.iq

Segment34Plus.iq: $(shell find source resources* disp-resources size-resources -type f 2>/dev/null) manifest.xml $(JUNGLE)
	$(MONKEYC) -o $@ -f $(JUNGLE) -y $(KEY) -e -w -r

sim: bin/Segment34Plus-fenix847mm.prg

bin/Segment34Plus-fenix847mm.prg: $(shell find source resources* disp-resources size-resources -type f 2>/dev/null) manifest.xml $(JUNGLE)
	@mkdir -p bin
	$(MONKEYC) -o $@ -f $(JUNGLE) -y $(KEY) -d fenix847mm -w

clean:
	rm -rf bin Segment34Plus.iq
