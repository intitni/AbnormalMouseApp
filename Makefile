NEED_LICENSE ?= false

bootstrap: needlicense
	pod install

needlicense:
	@if [ $(NEED_LICENSE) == true ]; then \
		cp LicenseWrapper/Package_NeedLicense.swift LicenseWrapper/Package.swift; \
	else \
		cp LicenseWrapper/Package_NoLicense.swift LicenseWrapper/Package.swift;\
	fi

.PHONY: needlicense