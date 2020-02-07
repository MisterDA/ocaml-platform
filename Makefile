linux:
# Build OCaml Platform
	docker build -f linux/build.dockerfile -t oplat .
	docker run oplat tar cz .opam .local/bin/opam > oplat.tar.gz
# Test OCaml Platform
	docker build -f linux/test.dockerfile -t oplat-test .
	docker run oplat-test sh -c 'eval $(opam env) && opam --version && opam list'

.PHONY: linux
