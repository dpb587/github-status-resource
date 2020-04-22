SHELL=/bin/bash

root_mkfile := $(abspath $(lastword $(MAKEFILE_LIST)))
root_dir := $(dir $(root_mkfile))

.PHONY: resource-dev
resource-dev:
	@docker run \
		-v $(root_dir):/resource \
		--rm -i -t dpb587/github-status-resource:master \
		/bin/ash

.PHONY: test
test:
	@docker run \
		-v $(root_dir):/resource \
		--rm -i -t dpb587/github-status-resource:master \
		/resource/test/all.sh
