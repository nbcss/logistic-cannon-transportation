.DELETE_ON_ERROR:
SHELL := bash
PYTHON ?= python

SUB_TARGETS := launcher-base launcher-head receiver-base

.DEFAULT: all
.PHONY: all $(SUB_TARGETS)
all: $(SUB_TARGETS)


launcher-base: entity/launcher/launcher-base.png entity/launcher/launcher-base-shadow.png

entity/launcher/launcher-base.png: $(shell echo render/launcher-base-{0..3}.png)
	$(PYTHON) tile_crop_sprites.py --columns 4 --output $(@:.png=) $+

entity/launcher/launcher-base-shadow.png: $(shell echo render/launcher-base-shadow-{0..3}.png)
	$(PYTHON) tile_crop_sprites.py --columns 4 --output $(@:.png=) $+


launcher-head: $(shell echo entity/launcher/launcher-raising{,-shadow}-{0..3}.png)

raising_sequence = \
	$(foreach j,$(shell seq 0 63), \
		$(shell seq -f "%03.0f" $(j) 64 $$(( $(j) + 255 ))) \
	)
remove_suffix = $(shell echo $(1) | sed -E s/-[0-9]+$$//)

$(shell echo entity/launcher/launcher-raising-{0..3}.png) &: $(addprefix render/launcher-head-,$(addsuffix .png,$(raising_sequence)))
	$(PYTHON) tile_crop_sprites.py --columns 4 --rows-per-output 16 --output $(call remove_suffix,$(@:.png=)) $+

$(shell echo entity/launcher/launcher-raising-shadow-{0..3}.png) &: $(addprefix render/launcher-head-shadow-,$(addsuffix .png,$(raising_sequence)))
	$(PYTHON) tile_crop_sprites.py --columns 4 --rows-per-output 16 --output $(call remove_suffix,$(@:.png=)) $+


launcher-head: entity/launcher/launcher-folded.png entity/launcher/launcher-folded-shadow.png

entity/launcher/launcher-folded.png: $(shell echo render/launcher-head-{000..063}.png)
	$(PYTHON) tile_crop_sprites.py --columns 8 --output $(@:.png=) $+

entity/launcher/launcher-folded-shadow.png: $(shell echo render/launcher-head-shadow-{000..063}.png)
	$(PYTHON) tile_crop_sprites.py --columns 8 --output $(@:.png=) $+


receiver-base: entity/receiver/receiver-base.png entity/receiver/receiver-base-shadow.png

entity/receiver/receiver-base.png: render/receiver-base.png
	$(PYTHON) tile_crop_sprites.py --columns 1 --output $(@:.png=) $+

entity/receiver/receiver-base-shadow.png: render/receiver-base-shadow.png
	$(PYTHON) tile_crop_sprites.py --columns 1 --output $(@:.png=) $+