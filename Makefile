NEED_LICENSE ?= false

bootstrap: needlicense
	pod install

needlicense:
	@if [ $(NEED_LICENSE) == true ]; then \
		cp AppDependencies/Package_NeedLicense.swift AppDependencies/Package.swift; \
	else \
		cp AppDependencies/Package_NoLicense.swift AppDependencies/Package.swift;\
	fi

.PHONY: needlicense