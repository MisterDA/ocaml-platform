linux:
	mkdir -p dist
	docker build -f build.dockerfile -t oplat .
	docker run \
		--mount type=bind,source="$(CURDIR)/dist",target=/mnt \
		oplat:latest \
		"tar" "czf" "/mnt/ocaml-platform-x86_64-linux.tar.gz" ".local" ".opam"
	docker build -f test.dockerfile -t oplat-test .
	# docker run \
	# 	--mount type=bind,source="$(CURDIR)/dist",target=/mnt \
	# 	oplat-test:latest \
	# 	"./installer.sh" "/mnt/ocaml-platform-x86_64-linux.tar.gz"

clean:
	rm -rf dist

.PHONY: linux clean
